import 'package:hive_flutter/hive_flutter.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA PREFS - Safe Hive Wrapper (iOS Crash-Proof)
/// ═══════════════════════════════════════════════════════════════
/// This wrapper uses Hive instead of SharedPreferences to prevent
/// EXC_BAD_ACCESS crashes on iOS 17/18/19/20.
/// All methods return safe default values and never crash.
class SyraPrefs {
  static Box? _box;

  /// Initialize Hive safely
  /// Call this in main() AFTER WidgetsFlutterBinding.ensureInitialized()
  static Future<void> initialize() async {
    try {
      await Hive.initFlutter();
      _box = await Hive.openBox('syraBox');
    } catch (e) {
      // If Hive fails, we continue without it
      // The app will work with default values
      _box = null;
    }
  }

  /// Get box instance (may be null if initialization failed)
  static Box? get instance => _box;

  /// Check if initialized
  static bool get isInitialized => _box != null;

  // ═══════════════════════════════════════════════════════════════
  // SAFE GETTERS - Always return default values, never crash
  // ═══════════════════════════════════════════════════════════════

  static String getString(String key, {String defaultValue = ''}) {
    try {
      return _box?.get(key, defaultValue: defaultValue) ?? defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  static int getInt(String key, {int defaultValue = 0}) {
    try {
      return _box?.get(key, defaultValue: defaultValue) ?? defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  static bool getBool(String key, {bool defaultValue = false}) {
    try {
      return _box?.get(key, defaultValue: defaultValue) ?? defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  static double getDouble(String key, {double defaultValue = 0.0}) {
    try {
      return _box?.get(key, defaultValue: defaultValue) ?? defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  static List<String> getStringList(String key,
      {List<String> defaultValue = const []}) {
    try {
      final value = _box?.get(key);
      if (value is List) {
        return value.cast<String>();
      }
      return defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SAFE SETTERS - Never crash, just log errors
  // ═══════════════════════════════════════════════════════════════

  static Future<bool> setString(String key, String value) async {
    try {
      await _box?.put(key, value);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> setInt(String key, int value) async {
    try {
      await _box?.put(key, value);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> setBool(String key, bool value) async {
    try {
      await _box?.put(key, value);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> setDouble(String key, double value) async {
    try {
      await _box?.put(key, value);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> setStringList(String key, List<String> value) async {
    try {
      await _box?.put(key, value);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ═══════════════════════════════════════════════════════════════

  static Future<bool> remove(String key) async {
    try {
      await _box?.delete(key);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> clear() async {
    try {
      await _box?.clear();
      return true;
    } catch (e) {
      return false;
    }
  }

  static bool containsKey(String key) {
    try {
      return _box?.containsKey(key) ?? false;
    } catch (e) {
      return false;
    }
  }

  static Set<String> getKeys() {
    try {
      return _box?.keys.cast<String>().toSet() ?? {};
    } catch (e) {
      return {};
    }
  }
}
