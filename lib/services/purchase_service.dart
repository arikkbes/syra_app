import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'firestore_user.dart';

/// ═══════════════════════════════════════════════════════════════
/// REVENUECAT PURCHASE SERVICE v2.0
/// ═══════════════════════════════════════════════════════════════
/// Production-ready RevenueCat integration for SYRA
/// Product: com.ariksoftware.syra.premium_monthly
/// ═══════════════════════════════════════════════════════════════

class PurchaseService {
  static const String _revenueCatApiKeyIOS = "appl_hMJcdDsttoFBDubneOgHjcfOUgx";
  static const String _revenueCatApiKeyAndroid =
      "goog_hnrifbAxGYJhdLqHnGHyhHHTArG";

  static const String entitlementIdentifier = "premium";
  static const String productId = "com.ariksoftware.syra.premium_monthly";

  static bool _isInitialized = false;
  static bool _isPurchasing = false;

  /// Initialize RevenueCat SDK
  /// Call this in main() before runApp()
  static Future<bool> initialize() async {
    if (_isInitialized) {
      debugPrint("✅ RevenueCat already initialized");
      return true;
    }

    try {
      late PurchasesConfiguration configuration;

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        configuration = PurchasesConfiguration(_revenueCatApiKeyIOS);
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        configuration = PurchasesConfiguration(_revenueCatApiKeyAndroid);
      } else {
        debugPrint("⚠️ RevenueCat not supported on this platform");
        _isInitialized = true;
        return false;
      }

      await Purchases.configure(configuration);

      // Set debug logs in debug mode only
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }

      _isInitialized = true;
      debugPrint("✅ RevenueCat initialized successfully");
      return true;
    } catch (e, stackTrace) {
      debugPrint("❌ RevenueCat init error: $e");
      debugPrint("Stack: $stackTrace");
      _isInitialized = true; // Prevent retries
      return false;
    }
  }

  /// Check if user has premium entitlement
  static Future<bool> hasPremium() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final hasEntitlement =
          customerInfo.entitlements.all[entitlementIdentifier]?.isActive ??
              false;
      debugPrint("Premium status: $hasEntitlement");
      return hasEntitlement;
    } catch (e) {
      debugPrint("❌ Error checking premium: $e");
      return false;
    }
  }

  /// Get available products
  static Future<List<StoreProduct>> getProducts() async {
    try {
      final offerings = await Purchases.getOfferings();

      if (offerings.current == null) {
        debugPrint("⚠️ No current offering found");
        return [];
      }

      final packages = offerings.current!.availablePackages;
      if (packages.isEmpty) {
        debugPrint("⚠️ No packages available");
        return [];
      }

      // Return all available products
      final products = packages.map((package) => package.storeProduct).toList();
      debugPrint("✅ Found ${products.length} product(s)");
      return products;
    } catch (e) {
      debugPrint("❌ Error loading products: $e");
      return [];
    }
  }

  /// Get single premium product
  static Future<StoreProduct?> getPremiumProduct() async {
    try {
      final products = await getProducts();
      if (products.isEmpty) return null;

      // Try to find the specific product ID first
      final specificProduct =
          products.where((p) => p.identifier == productId).firstOrNull;
      if (specificProduct != null) {
        return specificProduct;
      }

      // Otherwise return the first product
      return products.first;
    } catch (e) {
      debugPrint("❌ Error getting premium product: $e");
      return null;
    }
  }

  /// Purchase premium subscription
  static Future<bool> buyPremium() async {
    if (_isPurchasing) {
      debugPrint("⚠️ Purchase already in progress");
      return false;
    }

    try {
      _isPurchasing = true;

      // Get offerings
      final offerings = await Purchases.getOfferings();

      if (offerings.current == null ||
          offerings.current!.availablePackages.isEmpty) {
        debugPrint("❌ No offerings available");
        return false;
      }

      // Get the package (first available)
      final package = offerings.current!.availablePackages.first;

      debugPrint("🛒 Purchasing: ${package.storeProduct.identifier}");

      // Make the purchase
      final customerInfo = await Purchases.purchasePackage(package);

      // Check if purchase was successful
      final hasEntitlement =
          customerInfo.entitlements.all[entitlementIdentifier]?.isActive ??
              false;

      if (hasEntitlement) {
        debugPrint("✅ Purchase successful!");

        // Upgrade user in Firestore
        try {
          await FirestoreUser.upgradeToPremium();
          debugPrint("✅ Firestore premium upgrade complete");
        } catch (e) {
          debugPrint("⚠️ Firestore upgrade error: $e");
          // Don't fail the purchase if Firestore fails
        }

        return true;
      } else {
        debugPrint("⚠️ Purchase completed but entitlement not active");
        return false;
      }
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint("ℹ️ User cancelled purchase");
      } else {
        debugPrint("❌ Purchase error: ${e.name}");
      }
      return false;
    } catch (e) {
      debugPrint("❌ Purchase failed: $e");
      return false;
    } finally {
      _isPurchasing = false;
    }
  }

  /// Restore previous purchases
  static Future<bool> restorePurchases() async {
    try {
      debugPrint("🔄 Restoring purchases...");

      final customerInfo = await Purchases.restorePurchases();

      final hasEntitlement =
          customerInfo.entitlements.all[entitlementIdentifier]?.isActive ??
              false;

      if (hasEntitlement) {
        debugPrint("✅ Purchases restored successfully");

        // Update Firestore
        try {
          await FirestoreUser.upgradeToPremium();
          debugPrint("✅ Firestore updated after restore");
        } catch (e) {
          debugPrint("⚠️ Firestore update error: $e");
        }

        return true;
      } else {
        debugPrint("ℹ️ No active purchases to restore");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Restore failed: $e");
      return false;
    }
  }

  /// Check if store is available
  static Future<bool> isStoreAvailable() async {
    try {
      await Purchases.getOfferings();
      return true;
    } catch (e) {
      debugPrint("❌ Store unavailable: $e");
      return false;
    }
  }

  /// Identify user with RevenueCat (optional - call after login)
  static Future<void> identifyUser(String userId) async {
    try {
      await Purchases.logIn(userId);
      debugPrint("✅ User identified: $userId");
    } catch (e) {
      debugPrint("⚠️ User identification error: $e");
    }
  }

  /// Logout from RevenueCat
  static Future<void> logout() async {
    try {
      await Purchases.logOut();
      debugPrint("✅ User logged out from RevenueCat");
    } catch (e) {
      debugPrint("⚠️ Logout error: $e");
    }
  }

  /// Dispose (cleanup)
  static Future<void> dispose() async {
    _isPurchasing = false;
    _isInitialized = false;
    debugPrint("✅ PurchaseService disposed");
  }
}
