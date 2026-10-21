import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_constants.dart';

/// SQLite Database Open Helper Singleton managing schemas and relational integrity
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }

  /// Enable SQLite foreign key constraints
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Users Table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        height_cm REAL NOT NULL,
        weight_kg REAL NOT NULL,
        target_goal TEXT NOT NULL,
        profile_image_path TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 2. Activity Sessions Table (Polymorphic base + specialized columns)
    await db.execute('''
      CREATE TABLE activity_sessions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        activity_type TEXT NOT NULL,
        category TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL,
        calories_burned REAL NOT NULL,
        notes TEXT,
        
        -- Outdoor Tracking Specific
        distance_meters REAL DEFAULT 0.0,
        average_speed_kmh REAL DEFAULT 0.0,
        max_speed_kmh REAL DEFAULT 0.0,
        average_pace_min_per_km REAL DEFAULT 0.0,
        
        -- Gym Specific
        workout_name TEXT,
        
        -- Timed/Swimming Specific
        intensity_level TEXT,
        rounds INTEGER DEFAULT 0,
        laps INTEGER DEFAULT 0,
        pool_length_meters REAL DEFAULT 25.0,
        stroke_type TEXT,

        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // 3. GPS Track Points Table (Outdoor route coordinates)
    await db.execute('''
      CREATE TABLE gps_points (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        altitude REAL DEFAULT 0.0,
        speed_mps REAL DEFAULT 0.0,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES activity_sessions (id) ON DELETE CASCADE
      )
    ''');

    // 4. Workout Exercises Table (Gym exercise logs)
    await db.execute('''
      CREATE TABLE workout_exercises (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        exercise_name TEXT NOT NULL,
        target_muscle_group TEXT,
        FOREIGN KEY (session_id) REFERENCES activity_sessions (id) ON DELETE CASCADE
      )
    ''');

    // 5. Exercise Sets Table (Individual sets per exercise)
    await db.execute('''
      CREATE TABLE exercise_sets (
        id TEXT PRIMARY KEY,
        exercise_record_id TEXT NOT NULL,
        set_number INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        weight_kg REAL NOT NULL,
        is_completed INTEGER DEFAULT 0,
        FOREIGN KEY (exercise_record_id) REFERENCES workout_exercises (id) ON DELETE CASCADE
      )
    ''');

    // Indices for optimized lookup performance
    await db.execute('CREATE INDEX idx_sessions_user ON activity_sessions(user_id);');
    await db.execute('CREATE INDEX idx_sessions_start ON activity_sessions(start_time);');
    await db.execute('CREATE INDEX idx_gps_session ON gps_points(session_id);');
    await db.execute('CREATE INDEX idx_exercises_session ON workout_exercises(session_id);');
    await db.execute('CREATE INDEX idx_sets_exercise ON exercise_sets(exercise_record_id);');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
