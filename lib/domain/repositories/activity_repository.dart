import '../entities/activity_session.dart';
import '../entities/gps_point.dart';

/// Abstract Repository for Activity Tracking and Historical Sessions
abstract class ActivityRepository {
  Future<void> saveOutdoorSession(OutdoorTrackedSession session);
  Future<void> saveGpsPoints(List<GpsPoint> points);
  Future<List<GpsPoint>> getGpsPointsForSession(String sessionId);

  Future<void> saveGymSession(GymWorkoutSession session);
  Future<void> saveTimedSession(TimedWorkoutSession session);

  Future<List<ActivitySession>> getAllSessions({String? userId});
  Future<ActivitySession?> getSessionById(String sessionId);
  Future<void> deleteSession(String sessionId);

  // Aggregation queries for Dashboard and Analytics
  Future<Map<String, dynamic>> getAggregatedStats({String? userId});
  Future<List<Map<String, dynamic>>> getWeeklyActivityTrends({String? userId});
  Future<List<Map<String, dynamic>>> getMonthlyActivityTrends({String? userId});
}
