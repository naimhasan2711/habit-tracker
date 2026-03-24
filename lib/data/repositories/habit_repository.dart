import '../database/database_helper.dart';
import '../models/models.dart';
import '../../services/database_service.dart';

class HabitRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final DatabaseService _dbService = DatabaseService();

  // ==================== HABIT OPERATIONS ====================

  /// Get all habits
  Future<List<Habit>> getHabits({bool includeArchived = false}) {
    return _dbHelper.getHabits(includeArchived: includeArchived);
  }

  /// Get active habits for today
  Future<List<Habit>> getActiveHabitsForDate(DateTime date) {
    return _dbHelper.getActiveHabitsForDate(date);
  }

  /// Get habit by ID
  Future<Habit?> getHabitById(String id) {
    return _dbHelper.getHabitById(id);
  }

  /// Get habits by category
  Future<List<Habit>> getHabitsByCategory(String categoryId,
      {bool includeArchived = false}) {
    return _dbHelper.getHabitsByCategory(categoryId,
        includeArchived: includeArchived);
  }

  /// Create new habit
  Future<Habit> createHabit({
    required String name,
    String? description,
    required String icon,
    required int color,
    String? categoryId,
    String frequency = 'daily',
    List<int>? customDays,
    String? reminderTime,
  }) async {
    final habit = Habit(
      id: _dbService.generateId(),
      name: name,
      description: description,
      icon: icon,
      color: color,
      categoryId: categoryId,
      frequency: frequency,
      customDays: customDays,
      reminderTime: reminderTime,
      createdAt: DateTime.now(),
    );
    await _dbHelper.insertHabit(habit);
    return habit;
  }

  /// Update habit
  Future<void> updateHabit(Habit habit) {
    return _dbHelper.updateHabit(habit);
  }

  /// Delete habit
  Future<void> deleteHabit(String id) {
    return _dbHelper.deleteHabit(id);
  }

  /// Archive/Unarchive habit
  Future<void> archiveHabit(String id, bool archive) {
    return _dbHelper.archiveHabit(id, archive);
  }

  /// Update habit sort order
  Future<void> updateHabitSortOrder(String id, int sortOrder) {
    return _dbHelper.updateHabitSortOrder(id, sortOrder);
  }

  /// Reorder habits
  Future<void> reorderHabits(List<Habit> habits) async {
    for (int i = 0; i < habits.length; i++) {
      await _dbHelper.updateHabitSortOrder(habits[i].id, i);
    }
  }

  // ==================== HABIT LOG OPERATIONS ====================

  /// Get log for habit and date
  Future<HabitLog?> getLogForHabitAndDate(String habitId, DateTime date) {
    return _dbHelper.getLogForHabitAndDate(habitId, date);
  }

  /// Get logs for a specific date
  Future<List<HabitLog>> getLogsForDate(DateTime date) {
    return _dbHelper.getLogsForDate(date);
  }

  /// Get logs in date range
  Future<List<HabitLog>> getLogsInDateRange(DateTime start, DateTime end) {
    return _dbHelper.getLogsInDateRange(start, end);
  }

  /// Get logs for habit in date range
  Future<List<HabitLog>> getHabitLogsInDateRange(
      String habitId, DateTime start, DateTime end) {
    return _dbHelper.getHabitLogsInDateRange(habitId, start, end);
  }

  /// Toggle habit completion
  Future<HabitLog> toggleHabitCompletion(String habitId, DateTime date,
      {bool? completed}) async {
    final existingLog = await _dbHelper.getLogForHabitAndDate(habitId, date);
    final isCompleted = completed ?? !(existingLog?.completed ?? false);

    final log = HabitLog(
      id: existingLog?.id ?? _dbService.generateId(),
      habitId: habitId,
      date: DateTime(date.year, date.month, date.day),
      completed: isCompleted,
      completedAt: isCompleted ? DateTime.now() : null,
    );

    await _dbHelper.upsertHabitLog(log);

    // Update streak
    await _updateStreak(habitId, date, isCompleted);

    return log;
  }

  /// Get completion status for habits on a date
  Future<Map<String, bool>> getCompletionStatusForDate(DateTime date) async {
    final logs = await _dbHelper.getLogsForDate(date);
    return Map.fromEntries(
        logs.map((log) => MapEntry(log.habitId, log.completed)));
  }

  // ==================== STREAK OPERATIONS ====================

  /// Get streak for habit
  Future<Streak?> getStreakForHabit(String habitId) {
    return _dbHelper.getStreakForHabit(habitId);
  }

  /// Get all streaks
  Future<List<Streak>> getAllStreaks() {
    return _dbHelper.getAllStreaks();
  }

  /// Update streak when habit is completed/uncompleted
  Future<void> _updateStreak(
      String habitId, DateTime date, bool completed) async {
    final streak = await _dbHelper.getStreakForHabit(habitId);
    if (streak == null) return;

    final logDate = DateTime(date.year, date.month, date.day);

    if (completed) {
      int newCurrentStreak = streak.currentStreak;

      if (streak.lastCompletedDate == null) {
        // First completion
        newCurrentStreak = 1;
      } else {
        final lastDate = DateTime(
          streak.lastCompletedDate!.year,
          streak.lastCompletedDate!.month,
          streak.lastCompletedDate!.day,
        );
        final daysDifference = logDate.difference(lastDate).inDays;

        if (daysDifference == 0) {
          // Same day, no change
        } else if (daysDifference == 1) {
          // Consecutive day
          newCurrentStreak = streak.currentStreak + 1;
        } else if (daysDifference == 2 && streak.freezeUsed == false) {
          // Streak freeze can save one day
          newCurrentStreak = streak.currentStreak + 1;
        } else {
          // Streak broken
          newCurrentStreak = 1;
        }
      }

      final newLongestStreak = newCurrentStreak > streak.longestStreak
          ? newCurrentStreak
          : streak.longestStreak;

      await _dbHelper.updateStreak(streak.copyWith(
        currentStreak: newCurrentStreak,
        longestStreak: newLongestStreak,
        lastCompletedDate: logDate,
      ));
    } else {
      // Uncompleted - check if we need to adjust streak
      if (streak.lastCompletedDate != null) {
        final lastDate = DateTime(
          streak.lastCompletedDate!.year,
          streak.lastCompletedDate!.month,
          streak.lastCompletedDate!.day,
        );

        if (lastDate == logDate) {
          // Uncompleting today's completion
          // Find the previous completion to recalculate streak
          final logs = await _dbHelper.getLogsForHabit(habitId);
          final completedLogs = logs
              .where((l) => l.completed && l.date != logDate)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          if (completedLogs.isNotEmpty) {
            await _dbHelper.updateStreak(streak.copyWith(
              currentStreak:
                  streak.currentStreak > 0 ? streak.currentStreak - 1 : 0,
              lastCompletedDate: completedLogs.first.date,
            ));
          } else {
            await _dbHelper.updateStreak(streak.copyWith(
              currentStreak: 0,
              lastCompletedDate: null,
            ));
          }
        }
      }
    }
  }

  // ==================== ANALYTICS ====================

  /// Get completion rate for a habit
  Future<double> getCompletionRate(String habitId, {int days = 30}) {
    return _dbHelper.getCompletionRate(habitId, days: days);
  }

  /// Get overall completion rate
  Future<double> getOverallCompletionRate({int days = 30}) {
    return _dbHelper.getOverallCompletionRate(days: days);
  }

  /// Get daily completion stats
  Future<List<Map<String, dynamic>>> getDailyCompletionStats({int days = 7}) {
    return _dbHelper.getDailyCompletionStats(days: days);
  }

  /// Get completed logs count
  Future<int> getCompletedLogsCount(String habitId) {
    return _dbHelper.getCompletedLogsCount(habitId);
  }
}
