import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/exercise_record.dart';

abstract class WorkoutState {
  const WorkoutState();
}

class WorkoutInitial extends WorkoutState {
  const WorkoutInitial();
}

class WorkoutActive extends WorkoutState {
  final ActivityType activityType;
  final String workoutName;
  final DateTime startTime;
  final int durationSeconds;
  final List<ExerciseRecord> exercises;
  final int currentRestSeconds;
  final bool isRestTimerActive;

  const WorkoutActive({
    required this.activityType,
    required this.workoutName,
    required this.startTime,
    this.durationSeconds = 0,
    this.exercises = const [],
    this.currentRestSeconds = 0,
    this.isRestTimerActive = false,
  });

  /// Total volume moved (kg)
  double get totalVolumeKg {
    return exercises.fold(0.0, (acc, ex) => acc + ex.totalVolumeKg);
  }

  /// Total completed sets
  int get totalCompletedSets {
    int count = 0;
    for (final ex in exercises) {
      count += ex.sets.where((s) => s.isCompleted).length;
    }
    return count;
  }

  /// Formatted duration mm:ss or HH:mm:ss
  String get formattedDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  WorkoutActive copyWith({
    ActivityType? activityType,
    String? workoutName,
    DateTime? startTime,
    int? durationSeconds,
    List<ExerciseRecord>? exercises,
    int? currentRestSeconds,
    bool? isRestTimerActive,
  }) {
    return WorkoutActive(
      activityType: activityType ?? this.activityType,
      workoutName: workoutName ?? this.workoutName,
      startTime: startTime ?? this.startTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      exercises: exercises ?? this.exercises,
      currentRestSeconds: currentRestSeconds ?? this.currentRestSeconds,
      isRestTimerActive: isRestTimerActive ?? this.isRestTimerActive,
    );
  }
}

class WorkoutSavedSuccess extends WorkoutState {
  final String message;
  const WorkoutSavedSuccess(this.message);
}

class WorkoutError extends WorkoutState {
  final String errorMessage;
  const WorkoutError(this.errorMessage);
}
