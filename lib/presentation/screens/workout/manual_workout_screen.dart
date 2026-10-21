import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../cubits/workout/workout_cubit.dart';
import '../../cubits/workout/workout_state.dart';
import '../tracking/live_tracking_screen.dart';
import 'gym_workout_screen.dart';

class ManualWorkoutScreen extends StatefulWidget {
  const ManualWorkoutScreen({super.key});

  @override
  State<ManualWorkoutScreen> createState() => _ManualWorkoutScreenState();
}

class _ManualWorkoutScreenState extends State<ManualWorkoutScreen> {
  int _selectedCategoryTab = 0; // 0: All Activities, 1: Outdoor GPS, 2: Indoor & Gym

  void _onActivitySelected(ActivityType type) {
    if (type.isOutdoor) {
      // Route to Outdoor Live GPS Tracking
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LiveTrackingScreen(initialActivityType: type),
        ),
      );
    } else if (type == ActivityType.gymWorkout || type == ActivityType.strengthTraining) {
      // Route to Gym & Strength Workout Tracker
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GymWorkoutScreen(workoutName: type.displayName),
        ),
      );
    } else {
      // Open Quick Timed Logging Sheet (HIIT, Yoga, Swimming, Martial Arts)
      _showTimedWorkoutModal(type);
    }
  }

  void _showTimedWorkoutModal(ActivityType type) {
    final durationCtrl = TextEditingController(text: '30');
    final roundsCtrl = TextEditingController(text: '4');
    final lapsCtrl = TextEditingController(text: '20');
    final poolLengthCtrl = TextEditingController(text: '25');
    final notesCtrl = TextEditingController();
    String intensity = 'Moderate';
    String strokeType = 'Freestyle';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Log ${type.displayName}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Duration
                  TextField(
                    controller: durationCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Duration (Minutes)',
                      suffixText: 'min',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Intensity Selector
                  const Text('Workout Intensity', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Light', 'Moderate', 'High', 'Maximum'].map((lvl) {
                      final isSelected = intensity == lvl;
                      return ChoiceChip(
                        label: Text(lvl),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceLight,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        onSelected: (val) {
                          if (val) setSheetState(() => intensity = lvl);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Activity Specific Fields
                  if (type == ActivityType.swimming) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: lapsCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: const InputDecoration(labelText: 'Total Laps'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: poolLengthCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: const InputDecoration(labelText: 'Pool Length (m)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: strokeType,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(labelText: 'Stroke Style'),
                      items: ['Freestyle', 'Breaststroke', 'Backstroke', 'Butterfly', 'Mixed']
                          .map((st) => DropdownMenuItem(value: st, child: Text(st)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setSheetState(() => strokeType = val);
                      },
                    ),
                    const SizedBox(height: 16),
                  ] else if (type == ActivityType.hiit || type == ActivityType.martialArts) ...[
                    TextField(
                      controller: roundsCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(labelText: 'Number of Rounds / Sets'),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Notes
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(hintText: 'Notes / Focus points...'),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () async {
                      final duration = int.tryParse(durationCtrl.text) ?? 30;
                      final rounds = int.tryParse(roundsCtrl.text) ?? 0;
                      final laps = int.tryParse(lapsCtrl.text) ?? 0;
                      final poolLength = double.tryParse(poolLengthCtrl.text) ?? 25.0;

                      Navigator.of(ctx).pop();
                      await context.read<WorkoutCubit>().saveManualTimedWorkout(
                            activityType: type,
                            durationMinutes: duration,
                            intensityLevel: intensity,
                            rounds: rounds,
                            laps: laps,
                            poolLengthMeters: poolLength,
                            strokeType: type == ActivityType.swimming ? strokeType : null,
                            notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                          );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${type.displayName} workout logged successfully!'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    child: const Text('Save Workout Log'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredActivities = ActivityType.values.where((act) {
      if (_selectedCategoryTab == 1) return act.isOutdoor;
      if (_selectedCategoryTab == 2) return act.isIndoor;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Workouts & Tracking'),
      ),
      body: BlocListener<WorkoutCubit, WorkoutState>(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category Filter Tab Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Row(
                  children: [
                    _buildTabButton(0, 'All'),
                    _buildTabButton(1, 'Outdoor GPS'),
                    _buildTabButton(2, 'Indoor / Gym'),
                  ],
                ),
              ),
            ),

            // Activities Grid
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredActivities.length,
                itemBuilder: (context, index) {
                  final activity = filteredActivities[index];
                  return _buildActivityCard(activity);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _selectedCategoryTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategoryTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.black : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(ActivityType activity) {
    final iconData = _getActivityIcon(activity);
    final accentColor = _getActivityColor(activity);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(iconData, color: accentColor, size: 24),
        ),
        title: Text(
          activity.displayName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          '${activity.subtitle} • MET ${activity.defaultMet}',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: activity.isOutdoor ? AppColors.primary : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            activity.isOutdoor ? 'Live Track' : 'Log',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: activity.isOutdoor ? Colors.black : AppColors.textPrimary,
            ),
          ),
        ),
        onTap: () => _onActivitySelected(activity),
      ),
    );
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.running:
      case ActivityType.jogging:
        return Icons.directions_run_rounded;
      case ActivityType.cycling:
        return Icons.directions_bike_rounded;
      case ActivityType.trekking:
        return Icons.hiking_rounded;
      case ActivityType.gymWorkout:
      case ActivityType.strengthTraining:
        return Icons.fitness_center_rounded;
      case ActivityType.hiit:
        return Icons.bolt_rounded;
      case ActivityType.yoga:
        return Icons.self_improvement_rounded;
      case ActivityType.martialArts:
        return Icons.sports_mma_rounded;
      case ActivityType.swimming:
        return Icons.pool_rounded;
    }
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.running:
      case ActivityType.jogging:
        return AppColors.primary;
      case ActivityType.cycling:
        return AppColors.cyan;
      case ActivityType.trekking:
        return AppColors.accent;
      case ActivityType.gymWorkout:
      case ActivityType.strengthTraining:
        return AppColors.purple;
      case ActivityType.hiit:
        return AppColors.pink;
      case ActivityType.yoga:
        return AppColors.primaryLight;
      case ActivityType.martialArts:
        return AppColors.error;
      case ActivityType.swimming:
        return AppColors.info;
    }
  }
}
