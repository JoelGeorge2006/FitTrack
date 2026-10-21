import 'exercise_set.dart';

/// Entity representing an exercise performed during a workout session
class ExerciseRecord {
  final String id;
  final String sessionId;
  final String exerciseName;
  final String? targetMuscleGroup;
  final List<ExerciseSet> sets;

  const ExerciseRecord({
    required this.id,
    required this.sessionId,
    required this.exerciseName,
    this.targetMuscleGroup,
    this.sets = const [],
  });

  /// Total workout volume for this exercise
  double get totalVolumeKg {
    return sets.fold(0.0, (acc, set) => acc + set.volumeKg);
  }

  /// Total reps completed
  int get totalReps {
    return sets.fold(0, (acc, set) => acc + set.reps);
  }

  /// Heaviest weight lifted across sets
  double get maxWeightKg {
    if (sets.isEmpty) return 0.0;
    return sets.map((s) => s.weightKg).reduce((a, b) => a > b ? a : b);
  }

  ExerciseRecord copyWith({
    String? id,
    String? sessionId,
    String? exerciseName,
    String? targetMuscleGroup,
    List<ExerciseSet>? sets,
  }) {
    return ExerciseRecord(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      exerciseName: exerciseName ?? this.exerciseName,
      targetMuscleGroup: targetMuscleGroup ?? this.targetMuscleGroup,
      sets: sets ?? this.sets,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'exercise_name': exerciseName,
      'target_muscle_group': targetMuscleGroup,
    };
  }

  factory ExerciseRecord.fromMap(Map<String, dynamic> map, {List<ExerciseSet> sets = const []}) {
    return ExerciseRecord(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      exerciseName: map['exercise_name'] as String,
      targetMuscleGroup: map['target_muscle_group'] as String?,
      sets: sets,
    );
  }
}
