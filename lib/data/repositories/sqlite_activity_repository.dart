import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/activity_session.dart';
import '../../domain/entities/gps_point.dart';
import '../../domain/repositories/activity_repository.dart';
import '../database/database_helper.dart';
import 'sqlite_workout_repository.dart';

/// Concrete SQLite Implementation of ActivityRepository
class SqliteActivityRepository implements ActivityRepository {
  final DatabaseHelper _dbHelper;
  final SqliteWorkoutRepository _workoutRepository;

  SqliteActivityRepository({
    DatabaseHelper? dbHelper,
    SqliteWorkoutRepository? workoutRepository,
  })  : _dbHelper = dbHelper ?? DatabaseHelper(),
        _workoutRepository = workoutRepository ?? SqliteWorkoutRepository();

  @override
  Future<void> saveOutdoorSession(OutdoorTrackedSession session) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.insert(
        'activity_sessions',
        session.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Save GPS route points
      for (final pt in session.routePoints) {
        await txn.insert(
          'gps_points',
          pt.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  @override
  Future<void> saveGpsPoints(List<GpsPoint> points) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (final pt in points) {
      batch.insert(
        'gps_points',
        pt.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<GpsPoint>> getGpsPointsForSession(String sessionId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> results = await db.query(
      'gps_points',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );
    return results.map((m) => GpsPoint.fromMap(m)).toList();
  }

  @override
  Future<void> saveGymSession(GymWorkoutSession session) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.insert(
        'activity_sessions',
        session.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Save exercise records
      for (final ex in session.exercises) {
        await txn.insert(
          'workout_exercises',
          ex.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        for (final s in ex.sets) {
          await txn.insert(
            'exercise_sets',
            s.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }

  @override
  Future<void> saveTimedSession(TimedWorkoutSession session) async {
    final db = await _dbHelper.database;
    await db.insert(
      'activity_sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<ActivitySession>> getAllSessions({String? userId}) async {
    final db = await _dbHelper.database;
    String? whereClause;
    List<dynamic>? whereArgs;

    if (userId != null) {
      whereClause = 'user_id = ?';
      whereArgs = [userId];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'activity_sessions',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'start_time DESC',
    );

    final List<ActivitySession> sessions = [];

    for (final map in maps) {
      final actTypeStr = map['activity_type'] as String?;
      final actType = ActivityType.fromString(actTypeStr);
      final sessionId = map['id'] as String;

      if (actType.isOutdoor) {
        final gpsPoints = await getGpsPointsForSession(sessionId);
        sessions.add(OutdoorTrackedSession.fromMap(map, routePoints: gpsPoints));
      } else if (actType == ActivityType.gymWorkout || actType == ActivityType.strengthTraining) {
        final exercises = await _workoutRepository.getExercisesForSession(sessionId);
        sessions.add(GymWorkoutSession.fromMap(map, exercises: exercises));
      } else {
        sessions.add(TimedWorkoutSession.fromMap(map));
      }
    }

    return sessions;
  }

  @override
  Future<ActivitySession?> getSessionById(String sessionId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'activity_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    final map = maps.first;
    final actType = ActivityType.fromString(map['activity_type'] as String?);

    if (actType.isOutdoor) {
      final gpsPoints = await getGpsPointsForSession(sessionId);
      return OutdoorTrackedSession.fromMap(map, routePoints: gpsPoints);
    } else if (actType == ActivityType.gymWorkout || actType == ActivityType.strengthTraining) {
      final exercises = await _workoutRepository.getExercisesForSession(sessionId);
      return GymWorkoutSession.fromMap(map, exercises: exercises);
    } else {
      return TimedWorkoutSession.fromMap(map);
    }
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'activity_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  @override
  Future<Map<String, dynamic>> getAggregatedStats({String? userId}) async {
    final db = await _dbHelper.database;
    String userFilter = userId != null ? 'WHERE user_id = ?' : '';
    List<dynamic> args = userId != null ? [userId] : [];

    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_workouts,
        COALESCE(SUM(duration_seconds), 0) as total_duration_seconds,
        COALESCE(SUM(calories_burned), 0.0) as total_calories,
        COALESCE(SUM(distance_meters), 0.0) as total_distance_meters
      FROM activity_sessions
      $userFilter
    ''', args);

    if (result.isEmpty) {
      return {
        'total_workouts': 0,
        'total_duration_seconds': 0,
        'total_calories': 0.0,
        'total_distance_meters': 0.0,
      };
    }

    return result.first;
  }

  @override
  Future<List<Map<String, dynamic>>> getWeeklyActivityTrends({String? userId}) async {
    final db = await _dbHelper.database;
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
    
    String userFilter = userId != null ? 'AND user_id = ?' : '';
    List<dynamic> args = userId != null ? [sevenDaysAgo, userId] : [sevenDaysAgo];

    final results = await db.rawQuery('''
      SELECT 
        substr(start_time, 1, 10) as date_day,
        COUNT(*) as workout_count,
        SUM(calories_burned) as daily_calories,
        SUM(duration_seconds) as daily_duration_seconds,
        SUM(distance_meters) as daily_distance_meters
      FROM activity_sessions
      WHERE start_time >= ? $userFilter
      GROUP BY date_day
      ORDER BY date_day ASC
    ''', args);

    return results;
  }

  @override
  Future<List<Map<String, dynamic>>> getMonthlyActivityTrends({String? userId}) async {
    final db = await _dbHelper.database;
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();

    String userFilter = userId != null ? 'AND user_id = ?' : '';
    List<dynamic> args = userId != null ? [thirtyDaysAgo, userId] : [thirtyDaysAgo];

    final results = await db.rawQuery('''
      SELECT 
        substr(start_time, 1, 10) as date_day,
        COUNT(*) as workout_count,
        SUM(calories_burned) as daily_calories,
        SUM(duration_seconds) as daily_duration_seconds,
        SUM(distance_meters) as daily_distance_meters
      FROM activity_sessions
      WHERE start_time >= ? $userFilter
      GROUP BY date_day
      ORDER BY date_day ASC
    ''', args);

    return results;
  }
}
