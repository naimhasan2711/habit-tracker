import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'settings_provider.dart';
import '../../services/notification_service.dart';
import '../../services/database_service.dart';
import '../../data/repositories/repositories.dart';
import '../../data/models/models.dart';
import '../../core/constants/app_constants.dart';
import '../habits/habit_provider.dart';
import '../habits/category_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsProvider = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Appearance Section
          _SectionHeader(title: 'Appearance'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme'),
            value: settingsProvider.isDarkMode,
            onChanged: (value) => settingsProvider.setDarkMode(value),
          ),
          const Divider(),

          // Preferences Section
          _SectionHeader(title: 'Preferences'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            subtitle: const Text('Enable habit reminders'),
            value: settingsProvider.notificationsEnabled,
            onChanged: (value) async {
              if (value) {
                final granted =
                    await NotificationService().requestPermissions();
                if (granted) {
                  settingsProvider.setNotificationsEnabled(true);
                }
              } else {
                settingsProvider.setNotificationsEnabled(false);
              }
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.vibration),
            title: const Text('Haptic Feedback'),
            subtitle: const Text('Vibrate on interactions'),
            value: settingsProvider.hapticFeedback,
            onChanged: (value) => settingsProvider.setHapticFeedback(value),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.ac_unit),
            title: const Text('Streak Freeze'),
            subtitle: const Text('Allow one day grace period'),
            value: settingsProvider.streakFreezeEnabled,
            onChanged: (value) =>
                settingsProvider.setStreakFreezeEnabled(value),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('First Day of Week'),
            subtitle: Text(_getDayName(settingsProvider.firstDayOfWeek)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showFirstDayPicker(context, settingsProvider),
          ),
          const Divider(),

          // Data Section
          _SectionHeader(title: 'Data'),
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: const Text('Export Data'),
            subtitle: const Text('Save habits as JSON file'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _exportData(context),
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Import Data'),
            subtitle: const Text('Restore from JSON file'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _importData(context),
          ),
          ListTile(
            leading: Icon(Icons.delete_forever, color: Colors.red.shade400),
            title: Text(
              'Reset All Data',
              style: TextStyle(color: Colors.red.shade400),
            ),
            subtitle: const Text('Delete all habits and settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _resetData(context),
          ),
          const Divider(),

          // About Section
          _SectionHeader(title: 'About'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('App Version'),
            subtitle: const Text(AppConstants.appVersion),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy'),
            subtitle: const Text('All data stored locally on device'),
          ),
          const SizedBox(height: 32),

          // Footer
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 48,
                  color: theme.colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  AppConstants.appName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Build better habits',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  String _getDayName(int day) {
    const days = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[day];
  }

  void _showFirstDayPicker(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('First Day of Week'),
        children: [
          for (int i = 1; i <= 7; i++)
            RadioListTile<int>(
              title: Text(_getDayName(i)),
              value: i,
              groupValue: provider.firstDayOfWeek,
              onChanged: (value) {
                if (value != null) {
                  provider.setFirstDayOfWeek(value);
                  Navigator.pop(context);
                }
              },
            ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      final habitProvider = context.read<HabitProvider>();
      final categoryProvider = context.read<CategoryProvider>();

      final exportData = {
        'version': AppConstants.appVersion,
        'exportDate': DateTime.now().toIso8601String(),
        'categories':
            categoryProvider.categories.map((c) => c.toJson()).toList(),
        'habits': habitProvider.habits.map((h) => h.toJson()).toList(),
        'archivedHabits':
            habitProvider.archivedHabits.map((h) => h.toJson()).toList(),
        'streaks': habitProvider.streaks.values.map((s) => s.toJson()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/habit_tracker_export.json');
      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Habit Tracker Export',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data exported successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data'),
        content: const Text(
          'This will merge imported data with existing data. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Import categories
      if (data['categories'] != null) {
        final categoryRepo = CategoryRepository();
        for (final categoryJson in data['categories'] as List) {
          final category = Category.fromJson(categoryJson);
          await categoryRepo.createCategory(
            name: category.name,
            color: category.color,
            icon: category.icon,
          );
        }
      }

      // Import habits
      if (data['habits'] != null) {
        final habitProvider = context.read<HabitProvider>();
        for (final habitJson in data['habits'] as List) {
          final habit = Habit.fromJson(habitJson);
          await habitProvider.createHabit(
            name: habit.name,
            description: habit.description,
            icon: habit.icon,
            color: habit.color,
            categoryId: habit.categoryId,
            frequency: habit.frequency,
            customDays: habit.customDays,
            reminderTime: habit.reminderTime,
          );
        }
      }

      // Reload data
      await context.read<HabitProvider>().initialize();
      await context.read<CategoryProvider>().initialize();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data imported successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _resetData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Data'),
        content: const Text(
          'This will permanently delete all your habits, progress, and settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await DatabaseService().deleteDatabase();

      // Reinitialize providers
      await context.read<HabitProvider>().initialize();
      await context.read<CategoryProvider>().initialize();
      await context.read<SettingsProvider>().initialize();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data has been reset'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reset failed: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}
