import '../entities/exercise_record.dart';
import '../entities/exercise_set.dart';

/// Abstract Repository for Workout Exercises and Sets
abstract class WorkoutRepository {
  Future<void> saveExerciseRecord(ExerciseRecord record);
  Future<void> saveExerciseSets(List<ExerciseSet> sets);
  Future<List<ExerciseRecord>> getExercisesForSession(String sessionId);
  Future<void> deleteExercise(String exerciseId);
}
