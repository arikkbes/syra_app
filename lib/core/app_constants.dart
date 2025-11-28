/// ═══════════════════════════════════════════════════════════════
/// APP CONSTANTS - Global Grade
/// ═══════════════════════════════════════════════════════════════

class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'SYRA';
  static const String appVersion = '1.0.1';
  static const int buildNumber = 37;
  
  // Bundle & Products
  static const String bundleId = 'com.ariksoftware.syra';
  static const String premiumProductId = 'com.ariksoftware.syra.premium_monthly';
  
  // RevenueCat
  static const String revenueCatApiKeyIOS = 'appl_hMJcdDsttoFBDubneOgHjcfOUgx';
  static const String revenueCatApiKeyAndroid = 'goog_hnrifbAxGYJhdLqHnGHyhHHTArG';
  static const String revenueCatEntitlementId = 'premium';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String conversationsCollection = 'conversations';
  static const String messagesCollection = 'messages';
  static const String profileMemoryCollection = 'profile_memory';

  // Limits
  static const int freeDailyMessageLimit = 10;
  static const int premiumDailyMessageLimit = 99999;

  // API
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration chatResponseTimeout = Duration(seconds: 60);

  // UI
  static const double defaultBorderRadius = 16.0;
  static const double defaultPadding = 16.0;
  static const double defaultMargin = 16.0;

  // Animation
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration normalAnimation = Duration(milliseconds: 250);
  static const Duration slowAnimation = Duration(milliseconds: 400);

  // Storage
  static const String hiveBoxName = 'syraBox';

  // Routes
  static const String routeLogin = '/login';
  static const String routeSignup = '/signup';
  static const String routeChat = '/chat';
  static const String routePremium = '/premium';
  static const String routePremiumManagement = '/premium-management';
  static const String routeSettings = '/settings';
}
