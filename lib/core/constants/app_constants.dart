// App-wide constants for the Habit Tracker application

class AppConstants {
  // App Info
  static const String appName = 'Habit Tracker';
  static const String appVersion = '1.0.0';

  // Database
  static const String databaseName = 'habit_tracker.db';
  static const int databaseVersion = 1;

  // Table Names
  static const String habitsTable = 'habits';
  static const String habitLogsTable = 'habit_logs';
  static const String categoriesTable = 'categories';
  static const String streaksTable = 'streaks';
  static const String settingsTable = 'settings';

  // Default Categories
  static const List<Map<String, dynamic>> defaultCategories = [
    {'name': 'Health', 'color': 0xFF4CAF50, 'icon': 'favorite'},
    {'name': 'Fitness', 'color': 0xFFFF5722, 'icon': 'fitness_center'},
    {'name': 'Learning', 'color': 0xFF2196F3, 'icon': 'school'},
    {'name': 'Work', 'color': 0xFF9C27B0, 'icon': 'work'},
    {'name': 'Mindfulness', 'color': 0xFF00BCD4, 'icon': 'self_improvement'},
    {'name': 'Finance', 'color': 0xFF4CAF50, 'icon': 'attach_money'},
    {'name': 'Social', 'color': 0xFFE91E63, 'icon': 'people'},
    {'name': 'Other', 'color': 0xFF607D8B, 'icon': 'category'},
  ];

  // Frequency Types
  static const String frequencyDaily = 'daily';
  static const String frequencyWeekly = 'weekly';
  static const String frequencyCustom = 'custom';

  // Settings Keys
  static const String settingDarkMode = 'dark_mode';
  static const String settingNotifications = 'notifications_enabled';
  static const String settingHapticFeedback = 'haptic_feedback';
  static const String settingFirstDayOfWeek = 'first_day_of_week';
  static const String settingStreakFreeze = 'streak_freeze_enabled';

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Notification Channel
  static const String notificationChannelId = 'habit_reminders';
  static const String notificationChannelName = 'Habit Reminders';
  static const String notificationChannelDescription =
      'Reminders for your daily habits';
}

// Habit Icons available for selection
class HabitIcons {
  static const List<String> icons = [
    'favorite',
    'fitness_center',
    'school',
    'work',
    'self_improvement',
    'attach_money',
    'people',
    'category',
    'water_drop',
    'bedtime',
    'restaurant',
    'directions_run',
    'menu_book',
    'code',
    'brush',
    'music_note',
    'camera_alt',
    'local_cafe',
    'nature',
    'pets',
    'sports_soccer',
    'psychology',
    'savings',
    'phone',
    'mail',
    'cleaning_services',
    'medication',
    'smoking_rooms',
    'no_drinks',
    'emoji_emotions',
  ];
}

// Habit Colors available for selection
class HabitColors {
  static const List<int> colors = [
    0xFF4CAF50, // Green
    0xFFFF5722, // Deep Orange
    0xFF2196F3, // Blue
    0xFF9C27B0, // Purple
    0xFF00BCD4, // Cyan
    0xFFE91E63, // Pink
    0xFFFF9800, // Orange
    0xFF795548, // Brown
    0xFF607D8B, // Blue Grey
    0xFF3F51B5, // Indigo
    0xFFCDDC39, // Lime
    0xFFF44336, // Red
    0xFF009688, // Teal
    0xFFFFEB3B, // Yellow
    0xFF673AB7, // Deep Purple
  ];
}
