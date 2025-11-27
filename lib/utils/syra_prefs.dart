import 'package:shared_preferences/shared_preferences.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA PREFS - Safe SharedPreferences Wrapper
/// ═══════════════════════════════════════════════════════════════
/// This wrapper ensures all SharedPreferences operations are null-safe
/// and won't crash the app if the plugin fails to initialize.
/// All methods return safe default values instead of throwing errors.
class SyraPrefs {
  static SharedPreferences? _instance;

  /// Initialize SharedPreferences safely
  /// Call this AFTER the first frame is built, not in main()
  static Future<void> initialize() async {
    try {
      _instance = await SharedPreferences.getInstance();
    } catch (e) {
      // If SharedPreferences fails, we continue without it
      // The app will work with default values
      _instance = null;
    }
  }

  /// Get instance (may be null if initialization failed)
  static SharedPreferences? get instance => _instance;

  /// Check if initialized
  static bool get isInitialized => _instance != null;

  // ═══════════════════════════════════════════════════════════════
  // SAFE GETTERS - Always return default values, never crash
  // ═══════════════════════════════════════════════════════════════

  static String getString(String key, {String defaultValue = ''}) {
    try {
      return _instance?.getString(key) ?? defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  static int getInt(String key, {int defaultValue = 0}) {
    try {
      return _instance?.getInt(key) ?? defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  static bool getBool(String key, {bool defaultValue = false}) {
    try {
      return _instance?.getBool(key) ?? defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  static double getDouble(String key, {double defaultValue = 0.0}) {
    try {
      return _instance?.getDouble(key) ?? defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  static List<String> getStringList(String key,
      {List<String> defaultValue = const []}) {
    try {
      return _instance?.getStringList(key) ?? defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SAFE SETTERS - Never crash, just log errors
  // ═══════════════════════════════════════════════════════════════

  static Future<bool> setString(String key, String value) async {
    try {
      return await _instance?.setString(key, value) ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> setInt(String key, int value) async {
    try {
      return await _instance?.setInt(key, value) ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> setBool(String key, bool value) async {
    try {
      return await _instance?.setBool(key, value) ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> setDouble(String key, double value) async {
    try {
      return await _instance?.setDouble(key, value) ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> setStringList(String key, List<String> value) async {
    try {
      return await _instance?.setStringList(key, value) ?? false;
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ═══════════════════════════════════════════════════════════════

  static Future<bool> remove(String key) async {
    try {
      return await _instance?.remove(key) ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> clear() async {
    try {
      return await _instance?.clear() ?? false;
    } catch (e) {
      return false;
    }
  }

  static bool containsKey(String key) {
    try {
      return _instance?.containsKey(key) ?? false;
    } catch (e) {
      return false;
    }
  }

  static Set<String> getKeys() {
    try {
      return _instance?.getKeys() ?? {};
    } catch (e) {
      return {};
    }
  }
}
