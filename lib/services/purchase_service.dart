import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'firestore_user.dart';

/// ═══════════════════════════════════════════════════════════════
/// PURCHASE SERVICE v1.0.1 - CRASH-PROOF EDITION
/// ═══════════════════════════════════════════════════════════════
/// Ultra-safe IAP handling with complete null safety,
/// graceful degradation, and zero crash scenarios.
/// ═══════════════════════════════════════════════════════════════

class PurchaseService {
  static const String premiumProductId = "flortiq_premium";
  static InAppPurchase? _iapInstance;
  
  // Active subscription tracker - prevents memory leaks
  static StreamSubscription<List<PurchaseDetails>>? _activeSubscription;
  
  // Prevents multiple simultaneous purchase attempts
  static bool _isPurchasing = false;

  /// Safely get IAP instance with null checks
  static InAppPurchase? get _iap {
    try {
      _iapInstance ??= InAppPurchase.instance;
      return _iapInstance;
    } catch (e) {
      debugPrint("❌ IAP instance creation failed: $e");
      return null;
    }
  }

  /// Load premium product details
  /// Returns null if product not available or store not accessible
  /// NEVER crashes - returns null on any error
  static Future<ProductDetails?> _loadPremiumProduct() async {
    try {
      // Platform check
      if (!Platform.isAndroid && !Platform.isIOS) {
        debugPrint("⚠️ IAP not supported on this platform");
        return null;
      }

      // Get IAP instance safely
      final iap = _iap;
      if (iap == null) {
        debugPrint("❌ IAP instance unavailable");
        return null;
      }

      // Check store availability with timeout
      final available = await iap.isAvailable().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint("⏱️ Store availability check timed out");
          return false;
        },
      );

      if (!available) {
        debugPrint("⚠️ Store not available");
        return null;
      }

      // Query product with timeout and comprehensive error handling
      final ProductDetailsResponse response;
      try {
        response = await iap
            .queryProductDetails({premiumProductId})
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () => ProductDetailsResponse(
                productDetails: [],
                notFoundIDs: [premiumProductId],
              ),
            );
      } catch (queryError) {
        debugPrint("❌ Product query exception: $queryError");
        return null;
      }

      // Check for query errors
      if (response.error != null) {
        debugPrint("❌ Product query error: ${response.error}");
        return null;
      }

      // Check notFoundIDs - Apple didn't send this product
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint("⚠️ Product not found by store: ${response.notFoundIDs}");
        return null;
      }

      // Check if product details are empty
      if (response.productDetails.isEmpty) {
        debugPrint("⚠️ Product list empty: $premiumProductId");
        return null;
      }

      // Additional null safety check on first item
      final product = response.productDetails.first;
      if (product.id != premiumProductId) {
        debugPrint("⚠️ Wrong product returned: ${product.id}");
        return null;
      }

      debugPrint("✅ Product loaded successfully: ${product.title}");
      return product;
      
    } catch (e, stackTrace) {
      debugPrint("❌ _loadPremiumProduct fatal error: $e");
      debugPrint("Stack trace: $stackTrace");
      return null;
    }
  }

  /// Purchase premium subscription
  /// Returns true if purchase completed successfully
  /// NEVER crashes - returns false on any error
  static Future<bool> buyPremium() async {
    // Prevent multiple simultaneous purchases
    if (_isPurchasing) {
      debugPrint("⚠️ Purchase already in progress");
      return false;
    }

    try {
      _isPurchasing = true;

      // Platform check
      if (!Platform.isAndroid && !Platform.isIOS) {
        debugPrint("⚠️ IAP not supported on this platform");
        return false;
      }

      // Get IAP instance safely
      final iap = _iap;
      if (iap == null) {
        debugPrint("❌ IAP instance unavailable");
        return false;
      }

      // Load product with all safety checks
      final product = await _loadPremiumProduct();
      if (product == null) {
        debugPrint("❌ Premium product not available");
        return false;
      }

      // Create purchase param
      final PurchaseParam purchaseParam;
      try {
        purchaseParam = PurchaseParam(productDetails: product);
      } catch (e) {
        debugPrint("❌ PurchaseParam creation failed: $e");
        return false;
      }

      final completer = Completer<bool>();
      StreamSubscription<List<PurchaseDetails>>? subscription;

      // Setup purchase stream listener with comprehensive error handling
      try {
        subscription = iap.purchaseStream.listen(
          (purchases) async {
            try {
              // Null safety check
              if (purchases.isEmpty) return;

              for (final purchase in purchases) {
                // Only process our product
                if (purchase.productID != premiumProductId) continue;

                switch (purchase.status) {
                  case PurchaseStatus.purchased:
                  case PurchaseStatus.restored:
                    try {
                      // Complete purchase if pending
                      if (purchase.pendingCompletePurchase) {
                        await iap.completePurchase(purchase).timeout(
                          const Duration(seconds: 30),
                          onTimeout: () {
                            debugPrint("⏱️ Purchase completion timed out");
                          },
                        );
                      }

                      // Upgrade to premium
                      await FirestoreUser.upgradeToPremium().timeout(
                        const Duration(seconds: 30),
                        onTimeout: () {
                          debugPrint("⏱️ Premium upgrade timed out");
                        },
                      );

                      debugPrint("✅ Purchase successful");
                      if (!completer.isCompleted) completer.complete(true);
                    } catch (e) {
                      debugPrint("❌ Purchase completion error: $e");
                      // Still complete as true since payment went through
                      if (!completer.isCompleted) completer.complete(true);
                    }
                    break;

                  case PurchaseStatus.error:
                    debugPrint("❌ Purchase error: ${purchase.error}");
                    if (!completer.isCompleted) completer.complete(false);
                    break;

                  case PurchaseStatus.canceled:
                    debugPrint("ℹ️ Purchase canceled by user");
                    if (!completer.isCompleted) completer.complete(false);
                    break;

                  case PurchaseStatus.pending:
                    debugPrint("⏳ Purchase pending");
                    break;

                  default:
                    break;
                }
              }
            } catch (e) {
              debugPrint("❌ Purchase stream handler error: $e");
              if (!completer.isCompleted) completer.complete(false);
            }
          },
          onError: (Object error) {
            debugPrint("❌ Purchase stream error: $error");
            if (!completer.isCompleted) completer.complete(false);
          },
          cancelOnError: false, // Keep listening even if one purchase fails
        );

        _activeSubscription = subscription;
      } catch (e) {
        debugPrint("❌ Stream subscription failed: $e");
        return false;
      }

      // Initiate purchase with timeout and error handling
      try {
        await iap.buyNonConsumable(purchaseParam: purchaseParam).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint("⏱️ Purchase initiation timed out");
          },
        );
      } catch (e) {
        debugPrint("❌ buyNonConsumable error: $e");
        if (!completer.isCompleted) completer.complete(false);
        await _safelyCancelSubscription(subscription);
        return false;
      }

      // Wait for result with extended timeout
      final result = await completer.future.timeout(
        const Duration(seconds: 90),
        onTimeout: () {
          debugPrint("⏱️ Purchase confirmation timeout");
          return false;
        },
      );

      // Cleanup subscription
      await _safelyCancelSubscription(subscription);

      return result;
      
    } catch (e, stackTrace) {
      debugPrint("❌ buyPremium fatal error: $e");
      debugPrint("Stack trace: $stackTrace");
      return false;
    } finally {
      _isPurchasing = false;
    }
  }

  /// Restore previous purchases
  /// NEVER crashes - returns false on any error
  static Future<bool> restorePurchases() async {
    try {
      // Platform check
      if (!Platform.isAndroid && !Platform.isIOS) {
        debugPrint("⚠️ Restore not supported on this platform");
        return false;
      }

      // Get IAP instance safely
      final iap = _iap;
      if (iap == null) {
        debugPrint("❌ IAP instance unavailable for restore");
        return false;
      }

      // Check store availability
      final available = await iap.isAvailable().timeout(
        const Duration(seconds: 10),
        onTimeout: () => false,
      );

      if (!available) {
        debugPrint("⚠️ Store not available for restore");
        return false;
      }

      // Perform restore with timeout
      await iap.restorePurchases().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint("⏱️ Restore timed out");
        },
      );

      debugPrint("✅ Restore initiated successfully");
      return true;
      
    } catch (e, stackTrace) {
      debugPrint("❌ restorePurchases error: $e");
      debugPrint("Stack trace: $stackTrace");
      return false;
    }
  }

  /// Get premium product details
  /// NEVER crashes - returns null on any error
  static Future<ProductDetails?> getPremiumProduct() async {
    return _loadPremiumProduct();
  }

  /// Get all available products
  /// NEVER crashes - returns empty list on any error
  static Future<List<ProductDetails>> getProducts() async {
    try {
      final product = await getPremiumProduct();
      if (product == null) return [];
      return [product];
    } catch (e) {
      debugPrint("❌ getProducts error: $e");
      return [];
    }
  }

  /// Check if store is available
  /// NEVER crashes - returns false on any error
  static Future<bool> isStoreAvailable() async {
    try {
      if (!Platform.isAndroid && !Platform.isIOS) {
        return false;
      }

      final iap = _iap;
      if (iap == null) {
        return false;
      }

      return await iap.isAvailable().timeout(
        const Duration(seconds: 10),
        onTimeout: () => false,
      );
    } catch (e) {
      debugPrint("❌ isStoreAvailable error: $e");
      return false;
    }
  }

  /// Safely cancel subscription - prevents memory leaks
  static Future<void> _safelyCancelSubscription(
    StreamSubscription<List<PurchaseDetails>>? subscription,
  ) async {
    try {
      await subscription?.cancel();
      if (subscription == _activeSubscription) {
        _activeSubscription = null;
      }
    } catch (e) {
      debugPrint("⚠️ Subscription cancel error: $e");
    }
  }

  /// Cleanup method - call when app is disposing
  static Future<void> dispose() async {
    await _safelyCancelSubscription(_activeSubscription);
    _isPurchasing = false;
    _iapInstance = null;
  }
}
