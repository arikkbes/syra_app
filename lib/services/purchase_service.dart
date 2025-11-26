import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'firestore_user.dart';

/// ═══════════════════════════════════════════════════════════════
/// PURCHASE SERVICE v1.0.2 - CRASH-PROOF STABLE RELEASE
/// ═══════════════════════════════════════════════════════════════
/// Ultra-safe IAP handling with:
/// - NULL-safe product loading
/// - NO SIGSEGV / NO EXC_BAD_ACCESS
/// - Timeout-safe async flows
/// - Safe completion for all purchase scenarios
/// ═══════════════════════════════════════════════════════════════

class PurchaseService {
  static const String premiumProductId = "flortiq_premium";

  static InAppPurchase? _iapInstance;
  static StreamSubscription<List<PurchaseDetails>>? _activeSubscription;
  static bool _isPurchasing = false;

  /// Safely get IAP instance
  static InAppPurchase? get _iap {
    try {
      _iapInstance ??= InAppPurchase.instance;
      return _iapInstance;
    } catch (e) {
      debugPrint("❌ IAP instance creation failed: $e");
      return null;
    }
  }

  /// Safely load premium product
  static Future<ProductDetails?> _loadPremiumProduct() async {
    try {
      if (!Platform.isAndroid && !Platform.isIOS) {
        debugPrint("⚠️ IAP unsupported platform");
        return null;
      }

      final iap = _iap;
      if (iap == null) {
        debugPrint("❌ IAP instance null");
        return null;
      }

      final available = await iap.isAvailable().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint("⏱️ Store availability timeout");
          return false;
        },
      );

      if (!available) {
        debugPrint("⚠️ Store not available");
        return null;
      }

      ProductDetailsResponse response;
      try {
        response = await iap.queryProductDetails({premiumProductId}).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            return ProductDetailsResponse(
              productDetails: [],
              notFoundIDs: [premiumProductId],
            );
          },
        );
      } catch (e) {
        debugPrint("❌ Product query exception: $e");
        return null;
      }

      if (response.error != null) {
        debugPrint("❌ Product query error: ${response.error}");
        return null;
      }

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint("⚠️ Product not found: ${response.notFoundIDs}");
        return null;
      }

      if (response.productDetails.isEmpty) {
        debugPrint("⚠️ Empty product list");
        return null;
      }

      final product = response.productDetails.first;

      if (product.id != premiumProductId) {
        debugPrint("⚠️ Wrong product ID returned");
        return null;
      }

      debugPrint("✅ Product loaded: ${product.title}");
      return product;
    } catch (e, st) {
      debugPrint("❌ _loadPremiumProduct fatal error: $e");
      debugPrint("$st");
      return null;
    }
  }

  /// Main purchase function
  static Future<bool> buyPremium() async {
    if (_isPurchasing) {
      debugPrint("⚠️ Purchase already in progress");
      return false;
    }

    try {
      _isPurchasing = true;

      if (!Platform.isAndroid && !Platform.isIOS) return false;

      final iap = _iap;
      if (iap == null) return false;

      final product = await _loadPremiumProduct();
      if (product == null) {
        debugPrint("❌ Product unavailable");
        return false;
      }

      late PurchaseParam purchaseParam;
      try {
        purchaseParam = PurchaseParam(productDetails: product);
      } catch (e) {
        debugPrint("❌ PurchaseParam error: $e");
        return false;
      }

      final completer = Completer<bool>();

      StreamSubscription<List<PurchaseDetails>>? subscription;
      try {
        subscription = iap.purchaseStream.listen(
          (purchases) async {
            try {
              if (purchases.isEmpty) return;

              for (final purchase in purchases) {
                if (purchase.productID != premiumProductId) continue;

                switch (purchase.status) {
                  case PurchaseStatus.purchased:
                  case PurchaseStatus.restored:
                    try {
                      if (purchase.pendingCompletePurchase) {
                        await iap.completePurchase(purchase).timeout(
                          const Duration(seconds: 30),
                          onTimeout: () {
                            debugPrint("⏱️ completePurchase timeout");
                          },
                        );
                      }

                      await FirestoreUser.upgradeToPremium().timeout(
                        const Duration(seconds: 30),
                        onTimeout: () {
                          debugPrint("⏱️ Firestore premium upgrade timeout");
                        },
                      );

                      if (!completer.isCompleted) completer.complete(true);
                    } catch (e) {
                      debugPrint("❌ Purchase completion error: $e");
                      if (!completer.isCompleted) completer.complete(true);
                    }
                    break;

                  case PurchaseStatus.error:
                    if (!completer.isCompleted) completer.complete(false);
                    break;

                  case PurchaseStatus.canceled:
                    if (!completer.isCompleted) completer.complete(false);
                    break;

                  default:
                    break;
                }
              }
            } catch (e) {
              debugPrint("❌ Purchase stream error: $e");
              if (!completer.isCompleted) completer.complete(false);
            }
          },
          onError: (err) {
            debugPrint("❌ purchaseStream err: $err");
            if (!completer.isCompleted) completer.complete(false);
          },
        );

        _activeSubscription = subscription;
      } catch (e) {
        debugPrint("❌ Stream subscription failure: $e");
        return false;
      }

      // Initiate purchase
      try {
        await iap.buyNonConsumable(purchaseParam: purchaseParam).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint("⏱️ purchase initiation timeout");
            return false;
          },
        );
      } catch (e) {
        debugPrint("❌ buyNonConsumable error: $e");
        if (!completer.isCompleted) completer.complete(false);
      }

      final result = await completer.future.timeout(
        const Duration(seconds: 90),
        onTimeout: () {
          debugPrint("⏱️ purchase confirmation timeout");
          return false;
        },
      );

      await _safelyCancelSubscription(subscription);
      return result;
    } catch (e, st) {
      debugPrint("❌ buyPremium fatal: $e");
      debugPrint("$st");
      return false;
    } finally {
      _isPurchasing = false;
    }
  }

  /// Restore previous purchases
  static Future<bool> restorePurchases() async {
    try {
      if (!Platform.isAndroid && !Platform.isIOS) return false;

      final iap = _iap;
      if (iap == null) return false;

      final available = await iap.isAvailable().timeout(
            const Duration(seconds: 10),
            onTimeout: () => false,
          );

      if (!available) return false;

      await iap.restorePurchases().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint("⏱️ Restore timeout");
          return false;
        },
      );

      return true;
    } catch (e, st) {
      debugPrint("❌ restore fatal: $e");
      debugPrint("$st");
      return false;
    }
  }

  static Future<ProductDetails?> getPremiumProduct() async {
    return _loadPremiumProduct();
  }

  static Future<List<ProductDetails>> getProducts() async {
    try {
      final prod = await getPremiumProduct();
      return prod == null ? [] : [prod];
    } catch (e) {
      debugPrint("❌ getProducts error: $e");
      return [];
    }
  }

  static Future<bool> isStoreAvailable() async {
    try {
      final iap = _iap;
      if (iap == null) return false;

      return await iap.isAvailable().timeout(
            const Duration(seconds: 10),
            onTimeout: () => false,
          );
    } catch (e) {
      return false;
    }
  }

  static Future<void> _safelyCancelSubscription(
      StreamSubscription<List<PurchaseDetails>>? subscription) async {
    try {
      await subscription?.cancel();
      if (_activeSubscription == subscription) _activeSubscription = null;
    } catch (_) {}
  }

  static Future<void> dispose() async {
    await _safelyCancelSubscription(_activeSubscription);
    _isPurchasing = false;
    _iapInstance = null;
  }
}
