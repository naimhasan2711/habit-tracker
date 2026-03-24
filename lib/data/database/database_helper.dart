import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_constants.dart';
import '../models/models.dart';
import '../../services/database_service.dart';

class DatabaseHelper {
  final DatabaseService _databaseService = DatabaseService();

  // ==================== CATEGORIES ====================

  /// Get all categories
  Future<List<Category>> getCategories() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps =
        await db.query(AppConstants.categoriesTable);
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  /// Get category by ID
  Future<Category?> getCategoryById(String id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.categoriesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Category.fromMap(maps.first);
  }

  /// Insert category
  Future<void> insertCategory(Category category) async {
    final db = await _databaseService.database;
    await db.insert(
      AppConstants.categoriesTable,
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update category
  Future<void> updateCategory(Category category) async {
    final db = await _databaseService.database;
    await db.update(
      AppConstants.categoriesTable,
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  /// Delete category
  Future<void> deleteCategory(String id) async {
    final db = await _databaseService.database;
    await db.delete(
      AppConstants.categoriesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== HABITS ====================

  /// Get all habits
  Future<List<Habit>> getHabits({bool includeArchived = false}) async {
    final db = await _databaseService.database;
    String? whereClause = includeArchived ? null : 'archived = 0';
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.habitsTable,
      where: whereClause,
      orderBy: 'sort_order ASC, created_at DESC',
    );
    return List.generate(maps.length, (i) => Habit.fromMap(maps[i]));
  }

  /// Get active habits for a specific date
  Future<List<Habit>> getActiveHabitsForDate(DateTime date) async {
    final habits = await getHabits(includeArchived: false);
    return habits.where((habit) => habit.isActiveOnDay(date)).toList();
  }

  /// Get habit by ID
  Future<Habit?> getHabitById(String id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.habitsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Habit.fromMap(maps.first);
  }

  /// Get habits by category
  Future<List<Habit>> getHabitsByCategory(String categoryId,
      {bool includeArchived = false}) async {
    final db = await _databaseService.database;
    String whereClause = 'category_id = ?';
    if (!includeArchived) {
      whereClause += ' AND archived = 0';
    }
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.habitsTable,
      where: whereClause,
      whereArgs: [categoryId],
      orderBy: 'sort_order ASC, created_at DESC',
    );
    return List.generate(maps.length, (i) => Habit.fromMap(maps[i]));
  }

  /// Insert habit
  Future<void> insertHabit(Habit habit) async {
    final db = await _databaseService.database;
    await db.insert(
      AppConstants.habitsTable,
      habit.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Create streak entry for the habit
    final streak = Streak(
      id: _databaseService.generateId(),
      habitId: habit.id,
    );
    await insertStreak(streak);
  }

  /// Update habit
  Future<void> updateHabit(Habit habit) async {
    final db = await _databaseService.database;
    await db.update(
      AppConstants.habitsTable,
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  /// Delete habit
  Future<void> deleteHabit(String id) async {
    final db = await _databaseService.database;
    await db.delete(
      AppConstants.habitsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Archive habit
  Future<void> archiveHabit(String id, bool archive) async {
    final db = await _databaseService.database;
    await db.update(
      AppConstants.habitsTable,
      {'archived': archive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update habit sort order
  Future<void> updateHabitSortOrder(String id, int sortOrder) async {
    final db = await _databaseService.database;
    await db.update(
      AppConstants.habitsTable,
      {'sort_order': sortOrder},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== HABIT LOGS ====================

  /// Get all logs for a habit
  Future<List<HabitLog>> getLogsForHabit(String habitId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.habitLogsTable,
      where: 'habit_id = ?',
      whereArgs: [habitId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => HabitLog.fromMap(maps[i]));
  }

  /// Get logs for a specific date
  Future<List<HabitLog>> getLogsForDate(DateTime date) async {
    final db = await _databaseService.database;
    final dateStr = date.toIso8601String().split('T')[0];
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.habitLogsTable,
      where: 'date = ?',
      whereArgs: [dateStr],
    );
    return List.generate(maps.length, (i) => HabitLog.fromMap(maps[i]));
  }

  /// Get log for a specific habit and date
  Future<HabitLog?> getLogForHabitAndDate(String habitId, DateTime date) async {
    final db = await _databaseService.database;
    final dateStr = date.toIso8601String().split('T')[0];
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.habitLogsTable,
      where: 'habit_id = ? AND date = ?',
      whereArgs: [habitId, dateStr],
    );
    if (maps.isEmpty) return null;
    return HabitLog.fromMap(maps.first);
  }

  /// Get logs in date range
  Future<List<HabitLog>> getLogsInDateRange(
      DateTime start, DateTime end) async {
    final db = await _databaseService.database;
    final startStr = start.toIso8601String().split('T')[0];
    final endStr = end.toIso8601String().split('T')[0];
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.habitLogsTable,
      where: 'date >= ? AND date <= ?',
      whereArgs: [startStr, endStr],
    );
    return List.generate(maps.length, (i) => HabitLog.fromMap(maps[i]));
  }

  /// Get logs for habit in date range
  Future<List<HabitLog>> getHabitLogsInDateRange(
      String habitId, DateTime start, DateTime end) async {
    final db = await _databaseService.database;
    final startStr = start.toIso8601String().split('T')[0];
    final endStr = end.toIso8601String().split('T')[0];
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.habitLogsTable,
      where: 'habit_id = ? AND date >= ? AND date <= ?',
      whereArgs: [habitId, startStr, endStr],
      orderBy: 'date ASC',
    );
    return List.generate(maps.length, (i) => HabitLog.fromMap(maps[i]));
  }

  /// Insert or update habit log
  Future<void> upsertHabitLog(HabitLog log) async {
    final db = await _databaseService.database;
    await db.insert(
      AppConstants.habitLogsTable,
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Delete habit log
  Future<void> deleteHabitLog(String id) async {
    final db = await _databaseService.database;
    await db.delete(
      AppConstants.habitLogsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get completed logs count for habit
  Future<int> getCompletedLogsCount(String habitId) async {
    final db = await _databaseService.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM ${AppConstants.habitLogsTable}
      WHERE habit_id = ? AND completed = 1
    ''', [habitId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ==================== STREAKS ====================

  /// Get streak for a habit
  Future<Streak?> getStreakForHabit(String habitId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.streaksTable,
      where: 'habit_id = ?',
      whereArgs: [habitId],
    );
    if (maps.isEmpty) return null;
    return Streak.fromMap(maps.first);
  }

  /// Get all streaks
  Future<List<Streak>> getAllStreaks() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps =
        await db.query(AppConstants.streaksTable);
    return List.generate(maps.length, (i) => Streak.fromMap(maps[i]));
  }

  /// Insert streak
  Future<void> insertStreak(Streak streak) async {
    final db = await _databaseService.database;
    await db.insert(
      AppConstants.streaksTable,
      streak.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update streak
  Future<void> updateStreak(Streak streak) async {
    final db = await _databaseService.database;
    await db.update(
      AppConstants.streaksTable,
      streak.toMap(),
      where: 'habit_id = ?',
      whereArgs: [streak.habitId],
    );
  }

  // ==================== SETTINGS ====================

  /// Get setting value
  Future<String?> getSetting(String key) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.settingsTable,
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isEmpty) return null;
    return maps.first['value'] as String;
  }

  /// Set setting value
  Future<void> setSetting(String key, String value) async {
    final db = await _databaseService.database;
    await db.insert(
      AppConstants.settingsTable,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all settings
  Future<Map<String, String>> getAllSettings() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps =
        await db.query(AppConstants.settingsTable);
    return Map.fromEntries(
      maps.map((m) => MapEntry(m['key'] as String, m['value'] as String)),
    );
  }

  // ==================== ANALYTICS ====================

  /// Get completion rate for a habit
  Future<double> getCompletionRate(String habitId, {int days = 30}) async {
    final db = await _databaseService.database;
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    final startStr = startDate.toIso8601String().split('T')[0];
    final endStr = endDate.toIso8601String().split('T')[0];

    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN completed = 1 THEN 1 ELSE 0 END) as completed
      FROM ${AppConstants.habitLogsTable}
      WHERE habit_id = ? AND date >= ? AND date <= ?
    ''', [habitId, startStr, endStr]);

    if (result.isEmpty) return 0.0;
    final total = result.first['total'] as int? ?? 0;
    final completed = result.first['completed'] as int? ?? 0;
    return total > 0 ? (completed / total) * 100 : 0.0;
  }

  /// Get overall completion rate
  Future<double> getOverallCompletionRate({int days = 30}) async {
    final db = await _databaseService.database;
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    final startStr = startDate.toIso8601String().split('T')[0];
    final endStr = endDate.toIso8601String().split('T')[0];

    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN completed = 1 THEN 1 ELSE 0 END) as completed
      FROM ${AppConstants.habitLogsTable}
      WHERE date >= ? AND date <= ?
    ''', [startStr, endStr]);

    if (result.isEmpty) return 0.0;
    final total = result.first['total'] as int? ?? 0;
    final completed = result.first['completed'] as int? ?? 0;
    return total > 0 ? (completed / total) * 100 : 0.0;
  }

  /// Get daily completion stats for chart
  Future<List<Map<String, dynamic>>> getDailyCompletionStats(
      {int days = 7}) async {
    final db = await _databaseService.database;
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days - 1));
    final startStr = startDate.toIso8601String().split('T')[0];
    final endStr = endDate.toIso8601String().split('T')[0];

    final result = await db.rawQuery('''
      SELECT 
        date,
        COUNT(*) as total,
        SUM(CASE WHEN completed = 1 THEN 1 ELSE 0 END) as completed
      FROM ${AppConstants.habitLogsTable}
      WHERE date >= ? AND date <= ?
      GROUP BY date
      ORDER BY date ASC
    ''', [startStr, endStr]);

    return result;
  }
}
