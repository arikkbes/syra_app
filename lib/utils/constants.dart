// ═══════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════
class AppConstants {
  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  static const String appVersion = "1.0.1";
  static const String appName = "SYRA";

  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  static const int freeDailyMessageLimit = 10;
  static const int premiumDailyMessageLimit = 999;

  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  static const double defaultBorderRadius = 16.0;
  static const double defaultPadding = 16.0;
  static const double defaultMargin = 16.0;

  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration normalAnimation = Duration(milliseconds: 250);
  static const Duration slowAnimation = Duration(milliseconds: 400);

  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  static const Duration apiTimeout = Duration(seconds: 30);

  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  static const String usersCollection = 'users';
  static const String chatSessionsCollection = 'chat_sessions';
  static const String messagesCollection = 'messages';
}
