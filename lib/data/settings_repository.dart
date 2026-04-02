import 'package:shared_preferences/shared_preferences.dart';
import 'storage_keys.dart';

class SettingsRepository {
  Future<bool> loadIsDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(StorageKeys.isDarkMode) ?? false;
  }

  Future<void> saveIsDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.isDarkMode, isDark);
  }

  Future<bool> loadOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(StorageKeys.onboardingSeen) ?? false;
  }

  Future<void> saveOnboardingSeen(bool seen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.onboardingSeen, seen);
  }

  Future<void> clearAllDataExceptTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(StorageKeys.isDarkMode);
    await prefs.clear();
    if (isDark != null) {
      await prefs.setBool(StorageKeys.isDarkMode, isDark);
    }
  }
}
