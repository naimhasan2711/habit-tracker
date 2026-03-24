import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  final _uuid = const Uuid();

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Create categories table
    await db.execute('''
      CREATE TABLE ${AppConstants.categoriesTable} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        icon TEXT NOT NULL
      )
    ''');

    // Create habits table
    await db.execute('''
      CREATE TABLE ${AppConstants.habitsTable} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL,
        category_id TEXT,
        frequency TEXT NOT NULL DEFAULT 'daily',
        custom_days TEXT,
        reminder_time TEXT,
        created_at TEXT NOT NULL,
        archived INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (category_id) REFERENCES ${AppConstants.categoriesTable} (id)
      )
    ''');

    // Create habit_logs table
    await db.execute('''
      CREATE TABLE ${AppConstants.habitLogsTable} (
        id TEXT PRIMARY KEY,
        habit_id TEXT NOT NULL,
        date TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        completed_at TEXT,
        notes TEXT,
        FOREIGN KEY (habit_id) REFERENCES ${AppConstants.habitsTable} (id) ON DELETE CASCADE
      )
    ''');

    // Create streaks table
    await db.execute('''
      CREATE TABLE ${AppConstants.streaksTable} (
        id TEXT PRIMARY KEY,
        habit_id TEXT NOT NULL UNIQUE,
        current_streak INTEGER NOT NULL DEFAULT 0,
        longest_streak INTEGER NOT NULL DEFAULT 0,
        last_completed_date TEXT,
        freeze_used INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (habit_id) REFERENCES ${AppConstants.habitsTable} (id) ON DELETE CASCADE
      )
    ''');

    // Create settings table
    await db.execute('''
      CREATE TABLE ${AppConstants.settingsTable} (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Create indexes
    await db.execute(
        'CREATE INDEX idx_habit_logs_habit_id ON ${AppConstants.habitLogsTable} (habit_id)');
    await db.execute(
        'CREATE INDEX idx_habit_logs_date ON ${AppConstants.habitLogsTable} (date)');
    await db.execute(
        'CREATE INDEX idx_habits_archived ON ${AppConstants.habitsTable} (archived)');
    await db.execute(
        'CREATE UNIQUE INDEX idx_habit_logs_unique ON ${AppConstants.habitLogsTable} (habit_id, date)');

    // Insert default categories
    await _insertDefaultCategories(db);

    // Insert default settings
    await _insertDefaultSettings(db);
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle migrations here for future versions
  }

  /// Insert default categories
  Future<void> _insertDefaultCategories(Database db) async {
    for (final category in AppConstants.defaultCategories) {
      await db.insert(AppConstants.categoriesTable, {
        'id': _uuid.v4(),
        'name': category['name'],
        'color': category['color'],
        'icon': category['icon'],
      });
    }
  }

  /// Insert default settings
  Future<void> _insertDefaultSettings(Database db) async {
    await db.insert(AppConstants.settingsTable, {
      'key': AppConstants.settingDarkMode,
      'value': 'false',
    });
    await db.insert(AppConstants.settingsTable, {
      'key': AppConstants.settingNotifications,
      'value': 'true',
    });
    await db.insert(AppConstants.settingsTable, {
      'key': AppConstants.settingHapticFeedback,
      'value': 'true',
    });
    await db.insert(AppConstants.settingsTable, {
      'key': AppConstants.settingFirstDayOfWeek,
      'value': '1', // Monday
    });
    await db.insert(AppConstants.settingsTable, {
      'key': AppConstants.settingStreakFreeze,
      'value': 'false',
    });
  }

  /// Generate UUID
  String generateId() => _uuid.v4();

  /// Close the database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Delete the database (for reset)
  Future<void> deleteDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, AppConstants.databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
