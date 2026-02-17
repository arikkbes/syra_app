import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

  static const String entitlementCore = "core";
  static const String entitlementPlus = "plus";
  static const String coreProductId = "com.ariksoftware.syra.core_monthly";

  static bool _isInitialized = false;
  static bool _isPurchasing = false;
  static bool _isInitializing = false;
  static String? _lastLoggedInUid;
  static String? _pendingUid;

  static const String unsupportedPlatformMessage =
      "Satın alma bu platformda desteklenmiyor.";

  static bool isPlatformSupported() {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
  }

  static void setPendingUserId(String? uid) {
    _pendingUid = uid;
  }

  /// ═══════════════════════════════════════════════════════════════
  /// LAZY INITIALIZE - Call this BEFORE any RevenueCat operation
  /// ═══════════════════════════════════════════════════════════════
  /// This is the ONLY way to initialize RevenueCat.
  /// Call it when user taps "Go Premium" button.
  /// ═══════════════════════════════════════════════════════════════
  static Future<bool> ensureInitialized() async {
    if (!isPlatformSupported()) {
      debugPrint("⚠️ [PurchaseService] Unsupported platform for purchases");
      return false;
    }

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
        _isInitialized = false;
        _isInitializing = false;
        return false;
      }

      await Purchases.configure(configuration);

      if (_pendingUid != null) {
        try {
          debugPrint(
            "🔐 [PurchaseService] Logging in RevenueCat user: $_pendingUid",
          );
          await Purchases.logIn(_pendingUid!);
          _lastLoggedInUid = _pendingUid;
        } catch (e) {
          debugPrint("⚠️ [PurchaseService] RevenueCat logIn failed: $e");
        }
      }

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
          customerInfo.entitlements.active[entitlementCore] != null ||
          customerInfo.entitlements.active[entitlementPlus] != null;
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
      debugPrint(
        "[RC] currentOffering=${offerings.current?.identifier}, packages=${offerings.current?.availablePackages.length}",
      );

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
          .where((p) => p.identifier == coreProductId)
          .firstOrNull;
      if (specificProduct != null) {
        return specificProduct;
      }

      return products.first;
    } catch (e) {
      debugPrint("❌ [PurchaseService] Error getting core product: $e");
      return null;
    }
  }

  /// ═══════════════════════════════════════════════════════════════
  /// PURCHASE PREMIUM SUBSCRIPTION
  /// ═══════════════════════════════════════════════════════════════
  static Future<PurchaseResult> buyPremium() async {
    if (!isPlatformSupported()) {
      return PurchaseResult.unsupported(unsupportedPlatformMessage);
    }

    if (!await ensureInitialized()) {
      debugPrint("⚠️ [PurchaseService] Cannot purchase - init failed");
      return PurchaseResult.error("Satın alma servisi başlatılamadı.");
    }

    if (_isPurchasing) {
      debugPrint("⚠️ [PurchaseService] Purchase already in progress");
      return PurchaseResult.error("Satın alma zaten devam ediyor.");
    }

    try {
      _isPurchasing = true;

      final offerings = await Purchases.getOfferings();
      debugPrint(
        "[RC] currentOffering=${offerings.current?.identifier}, packages=${offerings.current?.availablePackages.length}",
      );

      if (offerings.current == null ||
          offerings.current!.availablePackages.isEmpty) {
        return PurchaseResult.error("Aktif teklif bulunamadı.");
      }

      final package = offerings.current!.availablePackages
          .where((p) => p.storeProduct.identifier == coreProductId)
          .firstOrNull;
      if (package == null) {
        throw StateError("CORE package not found in current offering");
      }

      debugPrint(
        "🛒 [PurchaseService] Purchasing: ${package.storeProduct.identifier}",
      );

      final customerInfo = await Purchases.purchasePackage(package);

      final hasEntitlement =
          customerInfo.entitlements.active[entitlementCore] != null ||
          customerInfo.entitlements.active[entitlementPlus] != null;
      debugPrint(
        "[RC] activeEntitlements=${customerInfo.entitlements.active.keys}",
      );

      if (hasEntitlement) {
        debugPrint("✅ [PurchaseService] Purchase successful!");
        // TODO(server-sync): Plan/isPremium is now server-managed.
        // Do not write user plan directly from client.

        return PurchaseResult.success();
      } else {
        debugPrint(
          "⚠️ [PurchaseService] Purchase completed but entitlement not active",
        );
        return PurchaseResult.error("Entitlement aktif olmadı.");
      }
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      final msg = e.message ?? e.details?.toString() ?? e.toString();
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint("ℹ️ [Purchase] $code: $msg");
        return PurchaseResult.cancelled(msg);
      }
      debugPrint("❌ [Purchase] $code: $msg");
      return PurchaseResult.error(msg);
    } catch (e) {
      debugPrint("❌ [PurchaseService] Purchase failed: $e");
      return PurchaseResult.error(e.toString());
    } finally {
      _isPurchasing = false;
    }
  }

  /// ═══════════════════════════════════════════════════════════════
  /// RESTORE PREVIOUS PURCHASES
  /// ═══════════════════════════════════════════════════════════════
  static Future<bool> restorePurchases() async {
    if (!isPlatformSupported()) {
      return false;
    }

    if (!await ensureInitialized()) {
      debugPrint("⚠️ [PurchaseService] Cannot restore - init failed");
      return false;
    }

    try {
      debugPrint("🔄 [PurchaseService] Restoring purchases...");

      final customerInfo = await Purchases.restorePurchases();

      final hasEntitlement =
          customerInfo.entitlements.active[entitlementCore] != null ||
          customerInfo.entitlements.active[entitlementPlus] != null;

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
    if (!isPlatformSupported()) return;

    if (_lastLoggedInUid == userId) {
      debugPrint("ℹ️ [PurchaseService] logIn skipped (same uid)");
      return;
    }

    if (!await ensureInitialized()) {
      debugPrint("⚠️ [PurchaseService] Cannot identify user - init failed");
      return;
    }

    try {
      await Purchases.logIn(userId);
      _lastLoggedInUid = userId;
      debugPrint("✅ [PurchaseService] User identified: $userId");
    } catch (e) {
      debugPrint("⚠️ [PurchaseService] User identification error: $e");
    }
  }

  /// ═══════════════════════════════════════════════════════════════
  /// LOGOUT FROM REVENUECAT
  /// ═══════════════════════════════════════════════════════════════
  static Future<void> logout() async {
    if (!isPlatformSupported() || !_isInitialized) {
      debugPrint("ℹ️ [PurchaseService] Not initialized, skipping logout");
      return;
    }

    try {
      await Purchases.logOut();
      _lastLoggedInUid = null;
      _pendingUid = null;
      debugPrint("✅ [PurchaseService] User logged out from RevenueCat");
    } catch (e) {
      debugPrint("⚠️ [PurchaseService] Logout error: $e");
    }
  }

  /// Open store subscription management page.
  static Future<bool> openSubscriptionManagement() async {
    if (!isPlatformSupported()) return false;

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
    _lastLoggedInUid = null;
    _pendingUid = null;
    debugPrint("✅ [PurchaseService] Disposed");
  }
}

enum PurchaseOutcome { success, cancelled, error, unsupported }

class PurchaseResult {
  final PurchaseOutcome outcome;
  final String? message;

  const PurchaseResult._(this.outcome, [this.message]);

  bool get isSuccess => outcome == PurchaseOutcome.success;
  bool get isCancelled => outcome == PurchaseOutcome.cancelled;
  bool get isUnsupported => outcome == PurchaseOutcome.unsupported;

  factory PurchaseResult.success() => const PurchaseResult._(PurchaseOutcome.success);
  factory PurchaseResult.cancelled(String? message) =>
      PurchaseResult._(PurchaseOutcome.cancelled, message);
  factory PurchaseResult.error(String? message) =>
      PurchaseResult._(PurchaseOutcome.error, message);
  factory PurchaseResult.unsupported(String? message) =>
      PurchaseResult._(PurchaseOutcome.unsupported, message);
}
