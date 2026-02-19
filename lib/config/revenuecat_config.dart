/// RevenueCat sabitleri — tek kaynak (Single Source of Truth).
/// Tüm API key, entitlement ve product ID referansları buradan alınır.
library;

class RevenueCatConfig {
  RevenueCatConfig._();

  // API keys
  static const String apiKeyIOS = 'appl_hMJcdDsttoFBDubneOgHjcfOUgx';
  static const String apiKeyAndroid = 'goog_hnrifbAxGYJhdLqHnGHyhHHTArG';

  // Entitlement ID'leri (RC Dashboard ile birebir eşleşmeli)
  static const String entitlementCore = 'core';
  static const String entitlementPlus = 'plus';

  // Product ID'leri (App Store Connect / Google Play Console ile eşleşmeli)
  static const String coreProductId = 'com.ariksoftware.syra.core_monthly';
}
