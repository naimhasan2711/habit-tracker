import 'package:flutter/material.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
import '../../services/notification_service.dart';

class HabitProvider extends ChangeNotifier {
  final HabitRepository _habitRepository = HabitRepository();
  final NotificationService _notificationService = NotificationService();

  List<Habit> _habits = [];
  List<Habit> _archivedHabits = [];
  Map<String, bool> _todayCompletionStatus = {};
  Map<String, Streak> _streaks = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Habit> get habits => _habits;
  List<Habit> get archivedHabits => _archivedHabits;
  Map<String, bool> get todayCompletionStatus => _todayCompletionStatus;
  Map<String, Streak> get streaks => _streaks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get active habits count
  int get activeHabitsCount => _habits.length;

  /// Get completed habits count for today
  int get completedTodayCount =>
      _todayCompletionStatus.values.where((c) => c).length;

  /// Get today's completion percentage
  double get todayCompletionPercentage {
    if (_habits.isEmpty) return 0;
    final todayHabits =
        _habits.where((h) => h.isActiveOnDay(DateTime.now())).length;
    if (todayHabits == 0) return 0;
    return (completedTodayCount / todayHabits) * 100;
  }

  /// Initialize provider - load data
  Future<void> initialize() async {
    await loadHabits();
    await loadTodayStatus();
    await loadStreaks();

    // Reschedule all notifications on app startup
    // This ensures notifications persist after app restart or device reboot
    await _rescheduleAllNotifications();
  }

  /// Reschedule notifications for all habits with reminders
  Future<void> _rescheduleAllNotifications() async {
    final habitsWithReminders =
        _habits.where((h) => h.reminderTime != null).toList();
    if (habitsWithReminders.isNotEmpty) {
      await _notificationService
          .rescheduleAllNotifications(habitsWithReminders);
    }
  }

  /// Load all habits
  Future<void> loadHabits() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _habits = await _habitRepository.getHabits(includeArchived: false);
      _archivedHabits =
          (await _habitRepository.getHabits(includeArchived: true))
              .where((h) => h.archived)
              .toList();
    } catch (e) {
      _error = 'Failed to load habits: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load today's completion status
  Future<void> loadTodayStatus() async {
    try {
      _todayCompletionStatus =
          await _habitRepository.getCompletionStatusForDate(DateTime.now());
    } catch (e) {
      _error = 'Failed to load status: $e';
    }
    notifyListeners();
  }

  /// Load all streaks
  Future<void> loadStreaks() async {
    try {
      final streaksList = await _habitRepository.getAllStreaks();
      _streaks =
          Map.fromEntries(streaksList.map((s) => MapEntry(s.habitId, s)));
    } catch (e) {
      _error = 'Failed to load streaks: $e';
    }
    notifyListeners();
  }

  /// Get active habits for a specific date
  Future<List<Habit>> getActiveHabitsForDate(DateTime date) async {
    return _habitRepository.getActiveHabitsForDate(date);
  }

  /// Get completion status for a specific date
  Future<Map<String, bool>> getCompletionStatusForDate(DateTime date) async {
    return _habitRepository.getCompletionStatusForDate(date);
  }

  /// Create a new habit
  Future<Habit?> createHabit({
    required String name,
    String? description,
    required String icon,
    required int color,
    String? categoryId,
    String frequency = 'daily',
    List<int>? customDays,
    String? reminderTime,
  }) async {
    try {
      final habit = await _habitRepository.createHabit(
        name: name,
        description: description,
        icon: icon,
        color: color,
        categoryId: categoryId,
        frequency: frequency,
        customDays: customDays,
        reminderTime: reminderTime,
      );

      _habits.add(habit);

      // Schedule notification if reminder is set (non-blocking)
      if (reminderTime != null) {
        try {
          await _notificationService.scheduleHabitReminder(habit);
        } catch (e) {
          // Notification scheduling failed, but habit creation succeeded
          // This is non-critical, so we just log and continue
          debugPrint('Failed to schedule notification: $e');
        }
      }

      notifyListeners();
      return habit;
    } catch (e) {
      _error = 'Failed to create habit: $e';
      notifyListeners();
      return null;
    }
  }

  /// Update a habit
  Future<bool> updateHabit(Habit habit) async {
    try {
      await _habitRepository.updateHabit(habit);

      final index = _habits.indexWhere((h) => h.id == habit.id);
      if (index != -1) {
        _habits[index] = habit;
      }

      // Update notification
      if (habit.reminderTime != null && !habit.archived) {
        await _notificationService.scheduleHabitReminder(habit);
      } else {
        await _notificationService.cancelHabitReminder(habit.id);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update habit: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete a habit
  Future<bool> deleteHabit(String id) async {
    try {
      await _habitRepository.deleteHabit(id);
      _habits.removeWhere((h) => h.id == id);
      _archivedHabits.removeWhere((h) => h.id == id);
      _todayCompletionStatus.remove(id);
      _streaks.remove(id);

      // Cancel notification
      await _notificationService.cancelHabitReminder(id);

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete habit: $e';
      notifyListeners();
      return false;
    }
  }

  /// Archive/Unarchive a habit
  Future<bool> archiveHabit(String id, bool archive) async {
    try {
      await _habitRepository.archiveHabit(id, archive);

      if (archive) {
        final habit = _habits.firstWhere((h) => h.id == id);
        _habits.removeWhere((h) => h.id == id);
        _archivedHabits.add(habit.copyWith(archived: true));
        await _notificationService.cancelHabitReminder(id);
      } else {
        final habit = _archivedHabits.firstWhere((h) => h.id == id);
        _archivedHabits.removeWhere((h) => h.id == id);
        _habits.add(habit.copyWith(archived: false));
        if (habit.reminderTime != null) {
          await _notificationService
              .scheduleHabitReminder(habit.copyWith(archived: false));
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to archive habit: $e';
      notifyListeners();
      return false;
    }
  }

  /// Toggle habit completion for today
  Future<bool> toggleHabitCompletion(String habitId, {DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final isToday = _isToday(targetDate);

    try {
      final log =
          await _habitRepository.toggleHabitCompletion(habitId, targetDate);

      if (isToday) {
        _todayCompletionStatus[habitId] = log.completed;
      }

      // Reload streak for this habit
      final streak = await _habitRepository.getStreakForHabit(habitId);
      if (streak != null) {
        _streaks[habitId] = streak;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to toggle completion: $e';
      notifyListeners();
      return false;
    }
  }

  /// Set habit completion status
  Future<bool> setHabitCompletion(String habitId, bool completed,
      {DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final isToday = _isToday(targetDate);

    try {
      final log = await _habitRepository
          .toggleHabitCompletion(habitId, targetDate, completed: completed);

      if (isToday) {
        _todayCompletionStatus[habitId] = log.completed;
      }

      // Reload streak for this habit
      final streak = await _habitRepository.getStreakForHabit(habitId);
      if (streak != null) {
        _streaks[habitId] = streak;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to set completion: $e';
      notifyListeners();
      return false;
    }
  }

  /// Reorder habits
  Future<void> reorderHabits(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final habit = _habits.removeAt(oldIndex);
    _habits.insert(newIndex, habit);

    notifyListeners();

    await _habitRepository.reorderHabits(_habits);
  }

  /// Get streak for a habit
  Streak? getStreak(String habitId) => _streaks[habitId];

  /// Check if habit is completed for today
  bool isCompletedToday(String habitId) =>
      _todayCompletionStatus[habitId] ?? false;

  /// Get habit by ID
  Habit? getHabitById(String id) {
    try {
      return _habits.firstWhere((h) => h.id == id);
    } catch (e) {
      try {
        return _archivedHabits.firstWhere((h) => h.id == id);
      } catch (e) {
        return null;
      }
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Check if date is today
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
