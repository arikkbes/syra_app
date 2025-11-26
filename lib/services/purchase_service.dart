import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'firestore_user.dart';

/// ═══════════════════════════════════════════════════════════════
/// PURCHASE SERVICE v1.0
/// ═══════════════════════════════════════════════════════════════
/// Handles in-app purchases with proper crash guards.
/// ═══════════════════════════════════════════════════════════════

class PurchaseService {
  static const String premiumProductId = "flortiq_premium";
  static final InAppPurchase _iap = InAppPurchase.instance;

  /// Load premium product details
  /// Returns null if product not available or store not accessible
  static Future<ProductDetails?> _loadPremiumProduct() async {
    try {
      // Check platform
      if (!Platform.isAndroid && !Platform.isIOS) {
        debugPrint("IAP not supported on this platform");
        return null;
      }

      // Check store availability
      final available = await _iap.isAvailable();
      if (!available) {
        debugPrint("Store not available.");
        return null;
      }

      // Query product
      final response = await _iap.queryProductDetails({premiumProductId});

      if (response.error != null) {
        debugPrint("Product query error: ${response.error}");
        return null;
      }

      if (response.productDetails.isEmpty) {
        debugPrint("Product not found: $premiumProductId");
        return null;
      }

      return response.productDetails.first;
    } catch (e) {
      debugPrint("_loadPremiumProduct error: $e");
      return null;
    }
  }

  /// Purchase premium subscription
  /// Returns true if purchase completed successfully
  static Future<bool> buyPremium() async {
    try {
      // Check platform
      if (!Platform.isAndroid && !Platform.isIOS) {
        debugPrint("IAP not supported on this platform (Windows/Linux).");
        return false;
      }

      // Load product
      final product = await _loadPremiumProduct();
      if (product == null) {
        debugPrint("Premium product not found.");
        return false;
      }

      final purchaseParam = PurchaseParam(productDetails: product);
      final completer = Completer<bool>();

      late StreamSubscription<List<PurchaseDetails>> sub;
      sub = _iap.purchaseStream.listen(
        (purchases) async {
          for (final purchase in purchases) {
            if (purchase.productID != premiumProductId) continue;

            switch (purchase.status) {
              case PurchaseStatus.purchased:
              case PurchaseStatus.restored:
                try {
                  if (purchase.pendingCompletePurchase) {
                    await _iap.completePurchase(purchase);
                  }
                  await FirestoreUser.upgradeToPremium();
                } catch (e) {
                  debugPrint("Purchase completion error: $e");
                }

                if (!completer.isCompleted) completer.complete(true);
                break;

              case PurchaseStatus.error:
                debugPrint("Purchase error: ${purchase.error}");
                if (!completer.isCompleted) completer.complete(false);
                break;

              case PurchaseStatus.canceled:
                debugPrint("Purchase canceled");
                if (!completer.isCompleted) completer.complete(false);
                break;

              case PurchaseStatus.pending:
                debugPrint("Purchase pending");
                break;

              default:
                break;
            }
          }
        },
        onError: (Object error) {
          debugPrint("Purchase stream error: $error");
          if (!completer.isCompleted) completer.complete(false);
        },
      );

      // Initiate purchase
      try {
        await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      } catch (e) {
        debugPrint("buyNonConsumable error: $e");
        if (!completer.isCompleted) completer.complete(false);
        await sub.cancel();
        return false;
      }

      // Wait for result with timeout
      final result = await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          debugPrint("Purchase timeout");
          return false;
        },
      );

      await sub.cancel();
      return result;
    } catch (e) {
      debugPrint("buyPremium error: $e");
      return false;
    }
  }

  /// Get premium product details
  static Future<ProductDetails?> getPremiumProduct() async {
    return _loadPremiumProduct();
  }

  /// Get all available products
  static Future<List<ProductDetails>> getProducts() async {
    try {
      final p = await getPremiumProduct();
      if (p == null) return [];
      return [p];
    } catch (e) {
      debugPrint("getProducts error: $e");
      return [];
    }
  }

  /// Check if store is available
  static Future<bool> isStoreAvailable() async {
    try {
      if (!Platform.isAndroid && !Platform.isIOS) {
        return false;
      }
      return await _iap.isAvailable();
    } catch (e) {
      debugPrint("isStoreAvailable error: $e");
      return false;
    }
  }
}
