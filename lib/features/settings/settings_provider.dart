import 'package:flutter/material.dart';
import '../../data/repositories/repositories.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsRepository _settingsRepository = SettingsRepository();

  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _hapticFeedback = true;
  int _firstDayOfWeek = DateTime.monday;
  bool _streakFreezeEnabled = false;
  bool _isLoading = false;

  // Getters
  bool get isDarkMode => _isDarkMode;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get hapticFeedback => _hapticFeedback;
  int get firstDayOfWeek => _firstDayOfWeek;
  bool get streakFreezeEnabled => _streakFreezeEnabled;
  bool get isLoading => _isLoading;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  /// Initialize settings
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isDarkMode = await _settingsRepository.getDarkMode();
      _notificationsEnabled =
          await _settingsRepository.getNotificationsEnabled();
      _hapticFeedback = await _settingsRepository.getHapticFeedback();
      _firstDayOfWeek = await _settingsRepository.getFirstDayOfWeek();
      _streakFreezeEnabled = await _settingsRepository.getStreakFreezeEnabled();
    } catch (e) {
      // Use defaults on error
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Toggle dark mode
  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    await _settingsRepository.setDarkMode(value);
  }

  /// Toggle notifications
  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    notifyListeners();
    await _settingsRepository.setNotificationsEnabled(value);
  }

  /// Toggle haptic feedback
  Future<void> setHapticFeedback(bool value) async {
    _hapticFeedback = value;
    notifyListeners();
    await _settingsRepository.setHapticFeedback(value);
  }

  /// Set first day of week
  Future<void> setFirstDayOfWeek(int day) async {
    _firstDayOfWeek = day;
    notifyListeners();
    await _settingsRepository.setFirstDayOfWeek(day);
  }

  /// Toggle streak freeze
  Future<void> setStreakFreezeEnabled(bool value) async {
    _streakFreezeEnabled = value;
    notifyListeners();
    await _settingsRepository.setStreakFreezeEnabled(value);
  }
}
