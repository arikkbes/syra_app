/// ═══════════════════════════════════════════════════════════════
/// APP CONSTANTS - Global Grade
/// ═══════════════════════════════════════════════════════════════

class AppConstants {
  AppConstants._();

  static const String appName = 'SYRA';
  static const String appVersion = '1.0.1';
  static const int buildNumber = 37;
  
  static const String bundleId = 'com.ariksoftware.syra';
  static const String premiumProductId = 'com.ariksoftware.syra.premium_monthly';
  
  static const String revenueCatApiKeyIOS = 'appl_hMJcdDsttoFBDubneOgHjcfOUgx';
  static const String revenueCatApiKeyAndroid = 'goog_hnrifbAxGYJhdLqHnGHyhHHTArG';
  static const String revenueCatEntitlementId = 'premium';

  static const String usersCollection = 'users';
  static const String conversationsCollection = 'conversations';
  static const String messagesCollection = 'messages';
  static const String profileMemoryCollection = 'profile_memory';

  static const int freeDailyMessageLimit = 10;
  static const int premiumDailyMessageLimit = 99999;

  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration chatResponseTimeout = Duration(seconds: 60);

  static const double defaultBorderRadius = 16.0;
  static const double defaultPadding = 16.0;
  static const double defaultMargin = 16.0;

  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration normalAnimation = Duration(milliseconds: 250);
  static const Duration slowAnimation = Duration(milliseconds: 400);

  static const String hiveBoxName = 'syraBox';

  static const String routeLogin = '/login';
  static const String routeSignup = '/signup';
  static const String routeChat = '/chat';
  static const String routePremium = '/premium';
  static const String routePremiumManagement = '/premium-management';
  static const String routeSettings = '/settings';
}
