import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/activity_repository.dart';
import 'dashboard_state.dart';

/// Cubit managing aggregated database metrics, charts data, and rule-based fitness insights
class DashboardCubit extends Cubit<DashboardState> {
  final ActivityRepository _activityRepository;

  DashboardCubit({required ActivityRepository activityRepository})
      : _activityRepository = activityRepository,
        super(const DashboardLoading());

  Future<void> loadDashboardData({User? user}) async {
    emit(const DashboardLoading());
    try {
      final userId = user?.id;

      // 1. Fetch Aggregated totals strictly from local SQLite database
      final aggMap = await _activityRepository.getAggregatedStats(userId: userId);
      final totalWorkouts = (aggMap['total_workouts'] as num?)?.toInt() ?? 0;
      final totalDurationSeconds = (aggMap['total_duration_seconds'] as num?)?.toInt() ?? 0;
      final totalCalories = (aggMap['total_calories'] as num?)?.toDouble() ?? 0.0;
      final totalDistanceMeters = (aggMap['total_distance_meters'] as num?)?.toDouble() ?? 0.0;

      // 2. Fetch Sessions list
      final allSessions = await _activityRepository.getAllSessions(userId: userId);

      // 3. Fetch Weekly & Monthly trends
      final weeklyTrends = await _activityRepository.getWeeklyActivityTrends(userId: userId);
      final monthlyTrends = await _activityRepository.getMonthlyActivityTrends(userId: userId);

      // 4. Derive transparent rule-based fitness recommendations based on goal & data
      final insights = _generateRuleBasedInsights(
        goal: user?.targetGoal ?? FitnessGoal.generalFitness,
        totalWorkouts: totalWorkouts,
        totalDurationSeconds: totalDurationSeconds,
        totalCalories: totalCalories,
        totalDistanceMeters: totalDistanceMeters,
      );

      emit(DashboardLoaded(
        totalWorkouts: totalWorkouts,
        totalDurationSeconds: totalDurationSeconds,
        totalCalories: totalCalories,
        totalDistanceMeters: totalDistanceMeters,
        recentSessions: allSessions,
        weeklyTrends: weeklyTrends,
        monthlyTrends: monthlyTrends,
        ruleBasedInsights: insights,
      ));
    } catch (e) {
      emit(DashboardError('Failed to load fitness dashboard: ${e.toString()}'));
    }
  }

  /// Transparent rule-based fitness insights calculation
  List<String> _generateRuleBasedInsights({
    required FitnessGoal goal,
    required int totalWorkouts,
    required int totalDurationSeconds,
    required double totalCalories,
    required double totalDistanceMeters,
  }) {
    final insights = <String>[];
    final activeMinutes = totalDurationSeconds ~/ 60;
    final distanceKm = totalDistanceMeters / 1000.0;

    if (totalWorkouts == 0) {
      insights.add('Welcome to FitTrack! Log your first outdoor run or gym workout to initiate your progress metrics.');
      return insights;
    }

    // Goal specific recommendations
    switch (goal) {
      case FitnessGoal.weightLoss:
        if (totalCalories >= 2000) {
          insights.add('Great progress! You have burned over ${totalCalories.toStringAsFixed(0)} kcal, maintaining a solid caloric deficit.');
        } else {
          final remaining = 2000 - totalCalories;
          insights.add('Target: Burn ${remaining.toStringAsFixed(0)} more kcal to achieve the recommended 2,000 kcal weekly energy deficit.');
        }
        if (distanceKm > 10) {
          insights.add('Cardio milestone: Over ${distanceKm.toStringAsFixed(1)} km covered. Outdoor GPS training accelerates metabolic rate.');
        }
        break;

      case FitnessGoal.muscleGain:
        if (totalWorkouts >= 3) {
          insights.add('Consistency achieved: $totalWorkouts sessions logged. Ensure 48 hours of recovery between the same muscle groups.');
        } else {
          insights.add('Hypertrophy tip: Target 3-4 structured strength sessions per week with progressive overload on main compound lifts.');
        }
        insights.add('Protein & recovery reminder: Adequate post-workout nutrition is essential for muscle protein synthesis.');
        break;

      case FitnessGoal.generalFitness:
        if (activeMinutes >= 150) {
          insights.add('Milestone unlocked! You achieved ${activeMinutes}m active time, meeting the WHO recommended 150 min weekly activity standard.');
        } else {
          final needed = 150 - activeMinutes;
          insights.add('Weekly goal: ${needed}m more active time needed to reach the recommended 150 minutes of cardiovascular exercise.');
        }
        break;
    }

    if (totalWorkouts >= 5) {
      insights.add('Consistency Streak: $totalWorkouts total workouts completed. Habit formation milestone achieved!');
    }

    return insights;
  }
}
