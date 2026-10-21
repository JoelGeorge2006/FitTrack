import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/exercise_record.dart';
import '../../../domain/entities/exercise_set.dart';
import '../../cubits/workout/workout_cubit.dart';
import '../../cubits/workout/workout_state.dart';
import '../../widgets/rest_timer_dialog.dart';

class GymWorkoutScreen extends StatefulWidget {
  final String workoutName;

  const GymWorkoutScreen({
    super.key,
    this.workoutName = 'Strength Training',
  });

  @override
  State<GymWorkoutScreen> createState() => _GymWorkoutScreenState();
}

class _GymWorkoutScreenState extends State<GymWorkoutScreen> {
  final _exerciseNameController = TextEditingController();
  final _muscleGroupController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<WorkoutCubit>().startGymWorkout(workoutName: widget.workoutName);
  }

  @override
  void dispose() {
    _exerciseNameController.dispose();
    _muscleGroupController.dispose();
    super.dispose();
  }

  void _showAddExerciseDialog() {
    _exerciseNameController.clear();
    _muscleGroupController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add Exercise',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _exerciseNameController,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Exercise Name',
                hintText: 'e.g. Incline Dumbbell Press, Squats, Pull-ups',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _muscleGroupController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Muscle Group (Optional)',
                hintText: 'e.g. Chest, Quads, Back',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final name = _exerciseNameController.text.trim();
                if (name.isNotEmpty) {
                  context.read<WorkoutCubit>().addExercise(
                        name,
                        targetMuscleGroup: _muscleGroupController.text.trim().isEmpty
                            ? null
                            : _muscleGroupController.text.trim(),
                      );
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Add to Workout'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFinishDialog() {
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Complete Gym Session',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 2,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Add workout notes (e.g. hit new PR on bench)...',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await context.read<WorkoutCubit>().finishAndSaveGymWorkout(
                      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                    );
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save Workout'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.workoutName),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.check_rounded, color: AppColors.primary),
            label: const Text('Finish', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
            onPressed: _showFinishDialog,
          ),
        ],
      ),
      body: BlocConsumer<WorkoutCubit, WorkoutState>(
        listener: (context, state) {
          if (state is WorkoutSavedSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is! WorkoutActive) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            children: [
              Column(
                children: [
                  // Workout Summary Stats Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      border: Border(bottom: BorderSide(color: AppColors.surfaceBorder)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('DURATION', state.formattedDuration, AppColors.textPrimary),
                        _buildStatItem('TOTAL VOLUME', '${state.totalVolumeKg.toStringAsFixed(0)} kg', AppColors.primary),
                        _buildStatItem('SETS COMPLETED', '${state.totalCompletedSets}', AppColors.accent),
                      ],
                    ),
                  ),

                  // Exercises List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
                      itemCount: state.exercises.length + 1,
                      itemBuilder: (context, index) {
                        if (index == state.exercises.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 24),
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.add_rounded, color: AppColors.primary),
                              label: const Text('Add Exercise', style: TextStyle(color: AppColors.primary)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primary, width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: _showAddExerciseDialog,
                            ),
                          );
                        }

                        final exercise = state.exercises[index];
                        return _buildExerciseCard(context, exercise);
                      },
                    ),
                  ),
                ],
              ),

              // Floating Rest Timer when active
              if (state.isRestTimerActive)
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 24,
                  child: RestTimerDialog(
                    remainingSeconds: state.currentRestSeconds,
                    onCancel: () => context.read<WorkoutCubit>().cancelRestTimer(),
                    onAddSeconds: (secs) =>
                        context.read<WorkoutCubit>().startRestTimer(state.currentRestSeconds + secs),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, letterSpacing: 0.8, color: AppColors.textMuted, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildExerciseCard(BuildContext context, ExerciseRecord exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.exerciseName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      if (exercise.targetMuscleGroup != null)
                        Text(
                          exercise.targetMuscleGroup!,
                          style: const TextStyle(fontSize: 12, color: AppColors.primaryLight),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                  color: AppColors.surface,
                  onSelected: (val) {
                    if (val == 'delete') {
                      context.read<WorkoutCubit>().removeExercise(exercise.id);
                    } else if (val == 'rest') {
                      context.read<WorkoutCubit>().startRestTimer(90);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'rest', child: Text('Start 90s Rest Timer')),
                    const PopupMenuItem(value: 'delete', child: Text('Remove Exercise', style: TextStyle(color: AppColors.error))),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.surfaceBorder),

          // Sets Table Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                SizedBox(width: 36, child: Text('SET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted))),
                Expanded(child: Center(child: Text('WEIGHT (KG)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted)))),
                Expanded(child: Center(child: Text('REPS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted)))),
                SizedBox(width: 44, child: Center(child: Icon(Icons.check_rounded, size: 16, color: AppColors.textMuted))),
              ],
            ),
          ),

          // Sets Rows
          ...exercise.sets.map((set) => _buildSetRow(context, exercise, set)),

          // Add Set Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Set'),
                  onPressed: () => context.read<WorkoutCubit>().addSetToExercise(exercise.id),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.timer_outlined, size: 16),
                  label: const Text('Rest 60s'),
                  onPressed: () => context.read<WorkoutCubit>().startRestTimer(60),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetRow(BuildContext context, ExerciseRecord exercise, ExerciseSet set) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: set.isCompleted ? AppColors.primary.withOpacity(0.06) : Colors.transparent,
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '${set.setNumber}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: set.isCompleted ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
          // Weight editor
          Expanded(
            child: Center(
              child: InkWell(
                onTap: () => _showEditSetNumberDialog(
                  title: 'Weight (kg)',
                  initialValue: set.weightKg.toStringAsFixed(1),
                  onSaved: (val) {
                    final w = double.tryParse(val) ?? set.weightKg;
                    context.read<WorkoutCubit>().updateSet(
                          exerciseId: exercise.id,
                          setId: set.id,
                          weightKg: w,
                        );
                  },
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBorder.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    set.weightKg.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                ),
              ),
            ),
          ),
          // Reps editor
          Expanded(
            child: Center(
              child: InkWell(
                onTap: () => _showEditSetNumberDialog(
                  title: 'Reps',
                  initialValue: '${set.reps}',
                  onSaved: (val) {
                    final r = int.tryParse(val) ?? set.reps;
                    context.read<WorkoutCubit>().updateSet(
                          exerciseId: exercise.id,
                          setId: set.id,
                          reps: r,
                        );
                  },
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBorder.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${set.reps}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                ),
              ),
            ),
          ),
          // Completed checkbox
          SizedBox(
            width: 44,
            child: IconButton(
              icon: Icon(
                set.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: set.isCompleted ? AppColors.primary : AppColors.textSecondary,
                size: 22,
              ),
              onPressed: () {
                final willBeCompleted = !set.isCompleted;
                context.read<WorkoutCubit>().updateSet(
                      exerciseId: exercise.id,
                      setId: set.id,
                      isCompleted: willBeCompleted,
                    );
                if (willBeCompleted) {
                  // Trigger standard 60-second rest countdown automatically
                  context.read<WorkoutCubit>().startRestTimer(60);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showEditSetNumberDialog({
    required String title,
    required String initialValue,
    required void Function(String) onSaved,
  }) {
    final ctrl = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Edit $title', style: const TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onSaved(ctrl.text.trim());
            },
            child: const Text('Save', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
