/// Entity representing an individual set within an exercise
class ExerciseSet {
  final String id;
  final String exerciseRecordId;
  final int setNumber;
  final int reps;
  final double weightKg;
  final bool isCompleted;

  const ExerciseSet({
    required this.id,
    required this.exerciseRecordId,
    required this.setNumber,
    required this.reps,
    required this.weightKg,
    this.isCompleted = false,
  });

  /// Total volume moved in this set (weight * reps)
  double get volumeKg => weightKg * reps;

  ExerciseSet copyWith({
    String? id,
    String? exerciseRecordId,
    int? setNumber,
    int? reps,
    double? weightKg,
    bool? isCompleted,
  }) {
    return ExerciseSet(
      id: id ?? this.id,
      exerciseRecordId: exerciseRecordId ?? this.exerciseRecordId,
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exercise_record_id': exerciseRecordId,
      'set_number': setNumber,
      'reps': reps,
      'weight_kg': weightKg,
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  factory ExerciseSet.fromMap(Map<String, dynamic> map) {
    return ExerciseSet(
      id: map['id'] as String,
      exerciseRecordId: map['exercise_record_id'] as String,
      setNumber: map['set_number'] as int,
      reps: map['reps'] as int,
      weightKg: (map['weight_kg'] as num).toDouble(),
      isCompleted: (map['is_completed'] as int) == 1,
    );
  }
}
