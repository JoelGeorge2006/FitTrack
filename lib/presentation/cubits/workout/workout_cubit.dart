import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/activity_session.dart';
import '../../../domain/entities/exercise_record.dart';
import '../../../domain/entities/exercise_set.dart';
import '../../../domain/repositories/activity_repository.dart';
import '../../../domain/strategies/calorie_calculator_strategy.dart';
import 'workout_state.dart';

/// Cubit managing manual indoor workout recording and dynamic exercise set tracking
class WorkoutCubit extends Cubit<WorkoutState> {
  final ActivityRepository _activityRepository;
  Timer? _sessionTimer;
  Timer? _restCountdownTimer;
  String? _activeSessionId;
  String _currentUserId = 'user_default';
  double _userWeightKg = AppConstants.defaultWeightKg;

  WorkoutCubit({required ActivityRepository activityRepository})
      : _activityRepository = activityRepository,
        super(const WorkoutInitial());

  void setAthleteContext({required String userId, required double weightKg}) {
    _currentUserId = userId;
    _userWeightKg = weightKg;
  }

  /// Start a new Gym / Strength Training session
  void startGymWorkout({
    String workoutName = 'Strength & Hypertrophy',
    ActivityType type = ActivityType.gymWorkout,
  }) {
    _activeSessionId = 'gym_${DateTime.now().millisecondsSinceEpoch}';

    // Start with popular starter exercises
    final defaultExercises = [
      ExerciseRecord(
        id: 'ex_${DateTime.now().microsecondsSinceEpoch}_1',
        sessionId: _activeSessionId!,
        exerciseName: 'Barbell Bench Press',
        targetMuscleGroup: 'Chest',
        sets: [
          ExerciseSet(
            id: 'set_${DateTime.now().microsecondsSinceEpoch}_1',
            exerciseRecordId: 'ex_${DateTime.now().microsecondsSinceEpoch}_1',
            setNumber: 1,
            reps: 10,
            weightKg: 60.0,
            isCompleted: false,
          ),
          ExerciseSet(
            id: 'set_${DateTime.now().microsecondsSinceEpoch}_2',
            exerciseRecordId: 'ex_${DateTime.now().microsecondsSinceEpoch}_1',
            setNumber: 2,
            reps: 10,
            weightKg: 60.0,
            isCompleted: false,
          ),
        ],
      ),
    ];

    emit(WorkoutActive(
      activityType: type,
      workoutName: workoutName,
      startTime: DateTime.now(),
      exercises: defaultExercises,
    ));

    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final s = state;
      if (s is WorkoutActive) {
        emit(s.copyWith(durationSeconds: s.durationSeconds + 1));
      }
    });
  }

  /// Add a new exercise to the active workout
  void addExercise(String exerciseName, {String? targetMuscleGroup}) {
    final s = state;
    if (s is! WorkoutActive) return;

    final exId = 'ex_${DateTime.now().microsecondsSinceEpoch}';
    final newExercise = ExerciseRecord(
      id: exId,
      sessionId: _activeSessionId ?? 'temp',
      exerciseName: exerciseName,
      targetMuscleGroup: targetMuscleGroup,
      sets: [
        ExerciseSet(
          id: 'set_${DateTime.now().microsecondsSinceEpoch}',
          exerciseRecordId: exId,
          setNumber: 1,
          reps: 10,
          weightKg: 40.0,
          isCompleted: false,
        ),
      ],
    );

    final updated = List<ExerciseRecord>.from(s.exercises)..add(newExercise);
    emit(s.copyWith(exercises: updated));
  }

  /// Add a new set to a specific exercise
  void addSetToExercise(String exerciseId) {
    final s = state;
    if (s is! WorkoutActive) return;

    final updated = s.exercises.map((ex) {
      if (ex.id == exerciseId) {
        final lastWeight = ex.sets.isNotEmpty ? ex.sets.last.weightKg : 40.0;
        final lastReps = ex.sets.isNotEmpty ? ex.sets.last.reps : 10;
        final newSet = ExerciseSet(
          id: 'set_${DateTime.now().microsecondsSinceEpoch}',
          exerciseRecordId: exerciseId,
          setNumber: ex.sets.length + 1,
          reps: lastReps,
          weightKg: lastWeight,
          isCompleted: false,
        );
        return ex.copyWith(sets: List<ExerciseSet>.from(ex.sets)..add(newSet));
      }
      return ex;
    }).toList();

    emit(s.copyWith(exercises: updated));
  }

  /// Update set reps and weight
  void updateSet({
    required String exerciseId,
    required String setId,
    int? reps,
    double? weightKg,
    bool? isCompleted,
  }) {
    final s = state;
    if (s is! WorkoutActive) return;

    final updated = s.exercises.map((ex) {
      if (ex.id == exerciseId) {
        final updatedSets = ex.sets.map((set) {
          if (set.id == setId) {
            return set.copyWith(
              reps: reps ?? set.reps,
              weightKg: weightKg ?? set.weightKg,
              isCompleted: isCompleted ?? set.isCompleted,
            );
          }
          return set;
        }).toList();
        return ex.copyWith(sets: updatedSets);
      }
      return ex;
    }).toList();

    emit(s.copyWith(exercises: updated));
  }

  /// Remove a set from an exercise
  void removeSet(String exerciseId, String setId) {
    final s = state;
    if (s is! WorkoutActive) return;

    final updated = s.exercises.map((ex) {
      if (ex.id == exerciseId) {
        final filteredSets = ex.sets.where((st) => st.id != setId).toList();
        // Re-index set numbers
        final renumberedSets = <ExerciseSet>[];
        for (int i = 0; i < filteredSets.length; i++) {
          renumberedSets.add(filteredSets[i].copyWith(setNumber: i + 1));
        }
        return ex.copyWith(sets: renumberedSets);
      }
      return ex;
    }).toList();

    emit(s.copyWith(exercises: updated));
  }

  /// Remove an exercise entirely
  void removeExercise(String exerciseId) {
    final s = state;
    if (s is! WorkoutActive) return;

    final updated = s.exercises.where((ex) => ex.id != exerciseId).toList();
    emit(s.copyWith(exercises: updated));
  }

  /// Start a rest timer countdown (e.g. 60 or 90 seconds)
  void startRestTimer(int seconds) {
    final s = state;
    if (s is! WorkoutActive) return;

    _restCountdownTimer?.cancel();
    emit(s.copyWith(currentRestSeconds: seconds, isRestTimerActive: true));

    _restCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final current = state;
      if (current is WorkoutActive) {
        if (current.currentRestSeconds <= 1) {
          timer.cancel();
          emit(current.copyWith(currentRestSeconds: 0, isRestTimerActive: false));
        } else {
          emit(current.copyWith(currentRestSeconds: current.currentRestSeconds - 1));
        }
      } else {
        timer.cancel();
      }
    });
  }

  void cancelRestTimer() {
    _restCountdownTimer?.cancel();
    final s = state;
    if (s is WorkoutActive) {
      emit(s.copyWith(currentRestSeconds: 0, isRestTimerActive: false));
    }
  }

  /// Save completed Gym session to SQLite
  Future<void> finishAndSaveGymWorkout({String? notes}) async {
    final s = state;
    if (s is! WorkoutActive) return;

    _sessionTimer?.cancel();
    _restCountdownTimer?.cancel();

    final calculator = CalorieCalculatorFactory.getStrategy(s.activityType);
    final calories = calculator.calculateCalories(
      weightKg: _userWeightKg,
      durationSeconds: s.durationSeconds,
    );

    final session = GymWorkoutSession(
      id: _activeSessionId ?? 'gym_${DateTime.now().millisecondsSinceEpoch}',
      userId: _currentUserId,
      activityType: s.activityType,
      startTime: s.startTime,
      endTime: DateTime.now(),
      durationSeconds: s.durationSeconds,
      caloriesBurned: calories,
      notes: notes,
      workoutName: s.workoutName,
      exercises: s.exercises,
    );

    try {
      await _activityRepository.saveGymSession(session);
      emit(const WorkoutSavedSuccess('Gym workout saved successfully!'));
    } catch (e) {
      emit(WorkoutError('Failed to save workout: ${e.toString()}'));
    }
  }

  /// Save manual timed workout (HIIT, Yoga, Swimming, Martial Arts)
  Future<void> saveManualTimedWorkout({
    required ActivityType activityType,
    required int durationMinutes,
    required String intensityLevel,
    int rounds = 0,
    int laps = 0,
    double poolLengthMeters = 25.0,
    String? strokeType,
    String? notes,
  }) async {
    final durationSeconds = durationMinutes * 60;
    final calculator = CalorieCalculatorFactory.getStrategy(activityType);
    final calories = calculator.calculateCalories(
      weightKg: _userWeightKg,
      durationSeconds: durationSeconds,
    );

    final session = TimedWorkoutSession(
      id: 'timed_${DateTime.now().millisecondsSinceEpoch}',
      userId: _currentUserId,
      activityType: activityType,
      startTime: DateTime.now().subtract(Duration(minutes: durationMinutes)),
      endTime: DateTime.now(),
      durationSeconds: durationSeconds,
      caloriesBurned: calories,
      notes: notes,
      intensityLevel: intensityLevel,
      rounds: rounds,
      laps: laps,
      poolLengthMeters: poolLengthMeters,
      strokeType: strokeType,
    );

    try {
      await _activityRepository.saveTimedSession(session);
      emit(const WorkoutSavedSuccess('Workout logged successfully!'));
    } catch (e) {
      emit(WorkoutError('Failed to log workout: ${e.toString()}'));
    }
  }

  void reset() {
    _sessionTimer?.cancel();
    _restCountdownTimer?.cancel();
    emit(const WorkoutInitial());
  }

  @override
  Future<void> close() {
    _sessionTimer?.cancel();
    _restCountdownTimer?.cancel();
    return super.close();
  }
}
