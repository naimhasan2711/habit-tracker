import '../database/database_helper.dart';
import '../../core/constants/app_constants.dart';

class SettingsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Get dark mode setting
  Future<bool> getDarkMode() async {
    final value = await _dbHelper.getSetting(AppConstants.settingDarkMode);
    return value == 'true';
  }

  /// Set dark mode
  Future<void> setDarkMode(bool enabled) {
    return _dbHelper.setSetting(
        AppConstants.settingDarkMode, enabled.toString());
  }

  /// Get notifications enabled setting
  Future<bool> getNotificationsEnabled() async {
    final value = await _dbHelper.getSetting(AppConstants.settingNotifications);
    return value != 'false'; // Default to true
  }

  /// Set notifications enabled
  Future<void> setNotificationsEnabled(bool enabled) {
    return _dbHelper.setSetting(
        AppConstants.settingNotifications, enabled.toString());
  }

  /// Get haptic feedback setting
  Future<bool> getHapticFeedback() async {
    final value =
        await _dbHelper.getSetting(AppConstants.settingHapticFeedback);
    return value != 'false'; // Default to true
  }

  /// Set haptic feedback
  Future<void> setHapticFeedback(bool enabled) {
    return _dbHelper.setSetting(
        AppConstants.settingHapticFeedback, enabled.toString());
  }

  /// Get first day of week (1 = Monday, 7 = Sunday)
  Future<int> getFirstDayOfWeek() async {
    final value =
        await _dbHelper.getSetting(AppConstants.settingFirstDayOfWeek);
    return int.tryParse(value ?? '1') ?? 1;
  }

  /// Set first day of week
  Future<void> setFirstDayOfWeek(int day) {
    return _dbHelper.setSetting(
        AppConstants.settingFirstDayOfWeek, day.toString());
  }

  /// Get streak freeze enabled setting
  Future<bool> getStreakFreezeEnabled() async {
    final value = await _dbHelper.getSetting(AppConstants.settingStreakFreeze);
    return value == 'true';
  }

  /// Set streak freeze enabled
  Future<void> setStreakFreezeEnabled(bool enabled) {
    return _dbHelper.setSetting(
        AppConstants.settingStreakFreeze, enabled.toString());
  }

  /// Get all settings
  Future<Map<String, String>> getAllSettings() {
    return _dbHelper.getAllSettings();
  }
}
