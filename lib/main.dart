import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/notification_service.dart';
import 'features/habits/habit_provider.dart';
import 'features/habits/category_provider.dart';
import 'features/settings/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize notification service
  await NotificationService().initialize();

  // Create providers and initialize them
  final settingsProvider = SettingsProvider();
  final categoryProvider = CategoryProvider();
  final habitProvider = HabitProvider();

  // Initialize data
  await settingsProvider.initialize();
  await categoryProvider.initialize();
  await habitProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: categoryProvider),
        ChangeNotifierProvider.value(value: habitProvider),
      ],
      child: const HabitTrackerApp(),
    ),
  );
}
