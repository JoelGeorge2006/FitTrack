import 'package:sqflite/sqflite.dart';
import '../../domain/entities/exercise_record.dart';
import '../../domain/entities/exercise_set.dart';
import '../../domain/repositories/workout_repository.dart';
import '../database/database_helper.dart';

/// Concrete SQLite Implementation of WorkoutRepository
class SqliteWorkoutRepository implements WorkoutRepository {
  final DatabaseHelper _dbHelper;

  SqliteWorkoutRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  @override
  Future<void> saveExerciseRecord(ExerciseRecord record) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.insert(
        'workout_exercises',
        record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Save related sets
      for (final set in record.sets) {
        await txn.insert(
          'exercise_sets',
          set.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  @override
  Future<void> saveExerciseSets(List<ExerciseSet> sets) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (final set in sets) {
      batch.insert(
        'exercise_sets',
        set.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<ExerciseRecord>> getExercisesForSession(String sessionId) async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> exerciseMaps = await db.query(
      'workout_exercises',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );

    final List<ExerciseRecord> records = [];

    for (final exMap in exerciseMaps) {
      final exId = exMap['id'] as String;
      final List<Map<String, dynamic>> setMaps = await db.query(
        'exercise_sets',
        where: 'exercise_record_id = ?',
        whereArgs: [exId],
        orderBy: 'set_number ASC',
      );

      final sets = setMaps.map((s) => ExerciseSet.fromMap(s)).toList();
      records.add(ExerciseRecord.fromMap(exMap, sets: sets));
    }

    return records;
  }

  @override
  Future<void> deleteExercise(String exerciseId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'workout_exercises',
      where: 'id = ?',
      whereArgs: [exerciseId],
    );
  }
}
