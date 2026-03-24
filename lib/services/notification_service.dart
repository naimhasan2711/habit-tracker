import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../core/constants/app_constants.dart';
import '../data/models/models.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combined initialization settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize the plugin
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channel for Android
    await _createNotificationChannel();

    _initialized = true;
  }

  /// Create Android notification channel
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: AppConstants.notificationChannelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap - navigate to habit
    // This can be handled by the app's navigation
  }

  /// Check if exact alarms are permitted (Android 12+)
  Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid) return true;

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return true;

    return await androidPlugin.canScheduleExactNotifications() ?? true;
  }

  /// Request exact alarm permission (Android 12+)
  Future<bool> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return true;

    // Request exact alarm permission
    await androidPlugin.requestExactAlarmsPermission();
    return await canScheduleExactAlarms();
  }

  /// Request notification permissions (Android 13+ and iOS)
  Future<bool> requestPermissions() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    bool? granted;

    if (androidPlugin != null) {
      // Request notification permission (Android 13+)
      granted = await androidPlugin.requestNotificationsPermission();

      // Also request exact alarm permission (Android 12+)
      await requestExactAlarmPermission();
    }

    if (iosPlugin != null) {
      granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    return granted ?? false;
  }

  /// Check if all permissions are granted for scheduling notifications
  Future<bool> hasAllPermissions() async {
    if (Platform.isAndroid) {
      final canScheduleExact = await canScheduleExactAlarms();
      if (!canScheduleExact) return false;
    }
    return true;
  }

  /// Schedule a daily reminder for a habit
  Future<void> scheduleHabitReminder(Habit habit) async {
    if (habit.reminderTime == null || habit.archived) return;

    final timeOfDay = habit.reminderTimeOfDay;
    if (timeOfDay == null) return;

    // Cancel existing notifications for this habit
    await cancelHabitReminder(habit.id);

    // Determine the schedule mode based on permission
    final scheduleMode = await _getScheduleMode();

    // Schedule based on frequency
    switch (habit.frequency) {
      case 'daily':
        await _scheduleDailyNotification(habit, timeOfDay, scheduleMode);
        break;
      case 'weekly':
        await _scheduleWeeklyNotification(
            habit, timeOfDay, DateTime.monday, scheduleMode);
        break;
      case 'custom':
        if (habit.customDays != null) {
          for (final day in habit.customDays!) {
            await _scheduleWeeklyNotification(
                habit, timeOfDay, day, scheduleMode);
          }
        }
        break;
    }
  }

  /// Get the appropriate schedule mode based on permissions
  Future<AndroidScheduleMode> _getScheduleMode() async {
    if (Platform.isAndroid && !await canScheduleExactAlarms()) {
      // Fall back to inexact scheduling if exact alarm permission not granted
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
    return AndroidScheduleMode.exactAllowWhileIdle;
  }

  /// Schedule a daily notification
  Future<void> _scheduleDailyNotification(
      Habit habit, TimeOfDay time, AndroidScheduleMode scheduleMode) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      _generateNotificationId(habit.id, 0),
      'Habit Reminder',
      "Time to complete '${habit.name}'!",
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          channelDescription: AppConstants.notificationChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          color: Color(habit.color),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: scheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      payload: habit.id,
    );
  }

  /// Schedule a weekly notification for a specific day
  Future<void> _scheduleWeeklyNotification(Habit habit, TimeOfDay time,
      int weekday, AndroidScheduleMode scheduleMode) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // Find the next occurrence of the weekday
    while (scheduledDate.weekday != weekday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      _generateNotificationId(habit.id, weekday),
      'Habit Reminder',
      "Time to complete '${habit.name}'!",
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          channelDescription: AppConstants.notificationChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          color: Color(habit.color),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: scheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents:
          DateTimeComponents.dayOfWeekAndTime, // Repeat weekly
      payload: habit.id,
    );
  }

  /// Cancel notifications for a habit
  Future<void> cancelHabitReminder(String habitId) async {
    // Cancel all possible notification IDs for this habit (0-7 for days)
    for (int i = 0; i <= 7; i++) {
      await _notifications.cancel(_generateNotificationId(habitId, i));
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Show instant notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          channelDescription: AppConstants.notificationChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  /// Generate a unique notification ID from habit ID and day
  int _generateNotificationId(String habitId, int day) {
    return habitId.hashCode + day;
  }

  /// Get pending notifications count
  Future<int> getPendingNotificationsCount() async {
    final pending = await _notifications.pendingNotificationRequests();
    return pending.length;
  }

  /// Get list of pending notification requests
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Reschedule all notifications for a list of habits
  /// Call this on app startup to ensure all notifications are properly scheduled
  Future<void> rescheduleAllNotifications(List<Habit> habits) async {
    for (final habit in habits) {
      if (habit.reminderTime != null && !habit.archived) {
        try {
          await scheduleHabitReminder(habit);
        } catch (e) {
          debugPrint(
              'Failed to reschedule notification for habit ${habit.id}: $e');
        }
      }
    }
  }

  /// Check if a habit has pending notifications scheduled
  Future<bool> hasScheduledNotification(String habitId) async {
    final pending = await getPendingNotifications();
    return pending.any((notification) =>
        notification.id == _generateNotificationId(habitId, 0) ||
        pending.any((n) =>
            n.id >= _generateNotificationId(habitId, 1) &&
            n.id <= _generateNotificationId(habitId, 7)));
  }
}
