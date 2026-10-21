import '../../../domain/entities/activity_session.dart';

abstract class DashboardState {
  const DashboardState();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final int totalWorkouts;
  final int totalDurationSeconds;
  final double totalCalories;
  final double totalDistanceMeters;
  final List<ActivitySession> recentSessions;
  final List<Map<String, dynamic>> weeklyTrends;
  final List<Map<String, dynamic>> monthlyTrends;
  final List<String> ruleBasedInsights;

  const DashboardLoaded({
    required this.totalWorkouts,
    required this.totalDurationSeconds,
    required this.totalCalories,
    required this.totalDistanceMeters,
    required this.recentSessions,
    required this.weeklyTrends,
    required this.monthlyTrends,
    required this.ruleBasedInsights,
  });

  /// Total distance in kilometers
  double get totalDistanceKm => totalDistanceMeters / 1000.0;

  /// Total duration formatted (e.g. "4h 25m" or "45m")
  String get formattedTotalTime {
    final hours = totalDurationSeconds ~/ 3600;
    final minutes = (totalDurationSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  bool get isEmpty => totalWorkouts == 0;
}

class DashboardError extends DashboardState {
  final String errorMessage;
  const DashboardError(this.errorMessage);
}
