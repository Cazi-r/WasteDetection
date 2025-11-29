import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keyFirstLaunch = 'first_launch';
  static const String _keyThemeMode = 'theme_mode';

  static SharedPreferences? _prefs;

  // Initialize SharedPreferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // First launch check
  static bool isFirstLaunch() {
    return _prefs?.getBool(_keyFirstLaunch) ?? true;
  }

  static Future<void> setFirstLaunchComplete() async {
    await _prefs?.setBool(_keyFirstLaunch, false);
  }

  // Theme mode (optional for future)
  static bool isDarkMode() {
    return _prefs?.getBool(_keyThemeMode) ?? false;
  }

  static Future<void> setThemeMode(bool isDark) async {
    await _prefs?.setBool(_keyThemeMode, isDark);
  }

  // Reset (for settings screen)
  static Future<void> resetOnboarding() async {
    await _prefs?.setBool(_keyFirstLaunch, true);
  }
}
