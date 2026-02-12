import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// ═══════════════════════════════════════════════════════════════
/// REVENUECAT PURCHASE SERVICE v3.0 - LAZY INITIALIZATION
/// ═══════════════════════════════════════════════════════════════
/// iOS 26.1+ Crash-Proof Design:
/// - RevenueCat is NOT initialized on app startup
/// - RevenueCat is initialized ONLY when user opens Premium screen
/// - Safe lazy initialization with proper error handling
/// ═══════════════════════════════════════════════════════════════

class PurchaseService {
  static const String _revenueCatApiKeyIOS = "appl_hMJcdDsttoFBDubneOgHjcfOUgx";
  static const String _revenueCatApiKeyAndroid =
      "goog_hnrifbAxGYJhdLqHnGHyhHHTArG";

  static const String entitlementIdentifier = "premium";
  static const String productId = "com.ariksoftware.syra.premium_monthly";

  static bool _isInitialized = false;
  static bool _isPurchasing = false;
  static bool _isInitializing = false;

  /// ═══════════════════════════════════════════════════════════════
  /// LAZY INITIALIZE - Call this BEFORE any RevenueCat operation
  /// ═══════════════════════════════════════════════════════════════
  /// This is the ONLY way to initialize RevenueCat.
  /// Call it when user taps "Go Premium" button.
  /// ═══════════════════════════════════════════════════════════════
  static Future<bool> ensureInitialized() async {
    if (_isInitialized) {
      debugPrint("✅ [PurchaseService] Already initialized");
      return true;
    }

    if (_isInitializing) {
      debugPrint("⏳ [PurchaseService] Initialization in progress, waiting...");
      int attempts = 0;
      while (_isInitializing && attempts < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      return _isInitialized;
    }

    _isInitializing = true;

    try {
      debugPrint("🔧 [PurchaseService] Starting lazy initialization...");

      late PurchasesConfiguration configuration;

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        configuration = PurchasesConfiguration(_revenueCatApiKeyIOS);
        debugPrint("🍎 [PurchaseService] Configuring for iOS");
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        configuration = PurchasesConfiguration(_revenueCatApiKeyAndroid);
        debugPrint("🤖 [PurchaseService] Configuring for Android");
      } else {
        debugPrint("⚠️ [PurchaseService] Platform not supported");
        _isInitialized = true;
        _isInitializing = false;
        return false;
      }

      await Purchases.configure(configuration);

      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }

      _isInitialized = true;
      _isInitializing = false;
      debugPrint("✅ [PurchaseService] Initialization complete!");
      return true;
    } catch (e, stackTrace) {
      debugPrint("❌ [PurchaseService] Init error: $e");
      debugPrint("Stack: $stackTrace");
      _isInitialized = false;
      _isInitializing = false;
      return false;
    }
  }

  /// ═══════════════════════════════════════════════════════════════
  /// CHECK PREMIUM STATUS
  /// ═══════════════════════════════════════════════════════════════
  static Future<bool> hasPremium() async {
    if (!await ensureInitialized()) {
      debugPrint("⚠️ [PurchaseService] Cannot check premium - init failed");
      return false;
    }

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final hasEntitlement =
          customerInfo.entitlements.all[entitlementIdentifier]?.isActive ??
          false;
      debugPrint("💎 [PurchaseService] Premium status: $hasEntitlement");
      return hasEntitlement;
    } catch (e) {
      debugPrint("❌ [PurchaseService] Error checking premium: $e");
      return false;
    }
  }

  /// ═══════════════════════════════════════════════════════════════
  /// GET AVAILABLE PRODUCTS
  /// ═══════════════════════════════════════════════════════════════
  static Future<List<StoreProduct>> getProducts() async {
    if (!await ensureInitialized()) {
      debugPrint("⚠️ [PurchaseService] Cannot get products - init failed");
      return [];
    }

    try {
      final offerings = await Purchases.getOfferings();

      if (offerings.current == null) {
        debugPrint("⚠️ [PurchaseService] No current offering found");
        return [];
      }

      final packages = offerings.current!.availablePackages;
      if (packages.isEmpty) {
        debugPrint("⚠️ [PurchaseService] No packages available");
        return [];
      }

      final products = packages.map((package) => package.storeProduct).toList();
      debugPrint("✅ [PurchaseService] Found ${products.length} product(s)");
      return products;
    } catch (e) {
      debugPrint("❌ [PurchaseService] Error loading products: $e");
      return [];
    }
  }

  /// ═══════════════════════════════════════════════════════════════
  /// GET SINGLE PREMIUM PRODUCT
  /// ═══════════════════════════════════════════════════════════════
  static Future<StoreProduct?> getPremiumProduct() async {
    try {
      final products = await getProducts();
      if (products.isEmpty) return null;

      final specificProduct = products
          .where((p) => p.identifier == productId)
          .firstOrNull;
      if (specificProduct != null) {
        return specificProduct;
      }

      return products.first;
    } catch (e) {
      debugPrint("❌ [PurchaseService] Error getting premium product: $e");
      return null;
    }
  }

  /// ═══════════════════════════════════════════════════════════════
  /// PURCHASE PREMIUM SUBSCRIPTION
  /// ═══════════════════════════════════════════════════════════════
  static Future<bool> buyPremium() async {
    if (!await ensureInitialized()) {
      debugPrint("⚠️ [PurchaseService] Cannot purchase - init failed");
      return false;
    }

    if (_isPurchasing) {
      debugPrint("⚠️ [PurchaseService] Purchase already in progress");
      return false;
    }

    try {
      _isPurchasing = true;

      final offerings = await Purchases.getOfferings();

      if (offerings.current == null ||
          offerings.current!.availablePackages.isEmpty) {
        debugPrint("❌ [PurchaseService] No offerings available");
        return false;
      }

      final package = offerings.current!.availablePackages.first;

      debugPrint(
        "🛒 [PurchaseService] Purchasing: ${package.storeProduct.identifier}",
      );

      final customerInfo = await Purchases.purchasePackage(package);

      final hasEntitlement =
          customerInfo.entitlements.all[entitlementIdentifier]?.isActive ??
          false;

      if (hasEntitlement) {
        debugPrint("✅ [PurchaseService] Purchase successful!");
        // TODO(server-sync): Plan/isPremium is now server-managed.
        // Do not write user plan directly from client.

        return true;
      } else {
        debugPrint(
          "⚠️ [PurchaseService] Purchase completed but entitlement not active",
        );
        return false;
      }
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint("ℹ️ [PurchaseService] User cancelled purchase");
      } else {
        debugPrint("❌ [PurchaseService] Purchase error: ${e.name}");
      }
      return false;
    } catch (e) {
      debugPrint("❌ [PurchaseService] Purchase failed: $e");
      return false;
    } finally {
      _isPurchasing = false;
    }
  }

  /// ═══════════════════════════════════════════════════════════════
  /// RESTORE PREVIOUS PURCHASES
  /// ═══════════════════════════════════════════════════════════════
  static Future<bool> restorePurchases() async {
    if (!await ensureInitialized()) {
      debugPrint("⚠️ [PurchaseService] Cannot restore - init failed");
      return false;
    }

    try {
      debugPrint("🔄 [PurchaseService] Restoring purchases...");

      final customerInfo = await Purchases.restorePurchases();

      final hasEntitlement =
          customerInfo.entitlements.all[entitlementIdentifier]?.isActive ??
          false;

      if (hasEntitlement) {
        debugPrint("✅ [PurchaseService] Purchases restored successfully");
        // TODO(server-sync): Plan/isPremium is now server-managed.
        // Do not write user plan directly from client.

        return true;
      } else {
        debugPrint("ℹ️ [PurchaseService] No active purchases to restore");
        return false;
      }
    } catch (e) {
      debugPrint("❌ [PurchaseService] Restore failed: $e");
      return false;
    }
  }

  /// ═══════════════════════════════════════════════════════════════
  /// IDENTIFY USER (Optional - call after login)
  /// ═══════════════════════════════════════════════════════════════
  static Future<void> identifyUser(String userId) async {
    if (!await ensureInitialized()) {
      debugPrint("⚠️ [PurchaseService] Cannot identify user - init failed");
      return;
    }

    try {
      await Purchases.logIn(userId);
      debugPrint("✅ [PurchaseService] User identified: $userId");
    } catch (e) {
      debugPrint("⚠️ [PurchaseService] User identification error: $e");
    }
  }

  /// ═══════════════════════════════════════════════════════════════
  /// LOGOUT FROM REVENUECAT
  /// ═══════════════════════════════════════════════════════════════
  static Future<void> logout() async {
    if (!_isInitialized) {
      debugPrint("ℹ️ [PurchaseService] Not initialized, skipping logout");
      return;
    }

    try {
      await Purchases.logOut();
      debugPrint("✅ [PurchaseService] User logged out from RevenueCat");
    } catch (e) {
      debugPrint("⚠️ [PurchaseService] Logout error: $e");
    }
  }

  /// Open store subscription management page.
  static Future<bool> openSubscriptionManagement() async {
    if (!await ensureInitialized()) {
      debugPrint("⚠️ [PurchaseService] Cannot open management - init failed");
      return false;
    }

    try {
      final dynamic purchasesDynamic = Purchases;
      await purchasesDynamic.showManageSubscriptions();
      return true;
    } catch (e) {
      debugPrint(
        "⚠️ [PurchaseService] showManageSubscriptions not available: $e",
      );
      return false;
    }
  }

  /// ═══════════════════════════════════════════════════════════════
  /// DISPOSE (Cleanup)
  /// ═══════════════════════════════════════════════════════════════
  static Future<void> dispose() async {
    _isPurchasing = false;
    _isInitialized = false;
    _isInitializing = false;
    debugPrint("✅ [PurchaseService] Disposed");
  }
}
