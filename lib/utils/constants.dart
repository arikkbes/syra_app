// ═══════════════════════════════════════════════════════════════
// APP CONSTANTS
// ═══════════════════════════════════════════════════════════════
// Uygulama genelinde kullanılan sabit değerler
// ═══════════════════════════════════════════════════════════════

class AppConstants {
  // ─────────────────────────────────────────────────────────────
  // VERSION INFO
  // ─────────────────────────────────────────────────────────────
  static const String appVersion = "1.0.1";
  static const String appName = "SYRA";

  // ─────────────────────────────────────────────────────────────
  // PREMIUM LIMITS
  // ─────────────────────────────────────────────────────────────
  static const int freeDailyMessageLimit = 10;
  static const int premiumDailyMessageLimit = 999;

  // ─────────────────────────────────────────────────────────────
  // UI CONSTANTS
  // ─────────────────────────────────────────────────────────────
  static const double defaultBorderRadius = 16.0;
  static const double defaultPadding = 16.0;
  static const double defaultMargin = 16.0;

  // ─────────────────────────────────────────────────────────────
  // ANIMATION DURATIONS
  // ─────────────────────────────────────────────────────────────
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration normalAnimation = Duration(milliseconds: 250);
  static const Duration slowAnimation = Duration(milliseconds: 400);

  // ─────────────────────────────────────────────────────────────
  // API TIMEOUTS
  // ─────────────────────────────────────────────────────────────
  static const Duration apiTimeout = Duration(seconds: 30);

  // ─────────────────────────────────────────────────────────────
  // FIRESTORE COLLECTIONS
  // ─────────────────────────────────────────────────────────────
  static const String usersCollection = 'users';
  static const String chatSessionsCollection = 'chat_sessions';
  static const String messagesCollection = 'messages';
}
