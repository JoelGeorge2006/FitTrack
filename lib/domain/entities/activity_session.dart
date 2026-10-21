import '../../core/constants/app_constants.dart';
import 'exercise_record.dart';
import 'gps_point.dart';

/// Abstract Base Class representing any fitness session in FitTrack.
/// Demonstrates OOAD Abstraction, Encapsulation, and Polymorphism.
abstract class ActivitySession {
  final String id;
  final String userId;
  final ActivityType activityType;
  final DateTime startTime;
  final DateTime endTime;
  final int durationSeconds;
  final double caloriesBurned;
  final String? notes;

  const ActivitySession({
    required this.id,
    required this.userId,
    required this.activityType,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    required this.caloriesBurned,
    this.notes,
  });

  /// Formatted duration string: HH:mm:ss or mm:ss
  String get formattedDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Polymorphic summary string representation of the session performance
  String get performanceSummary;

  /// Base database map representation
  Map<String, dynamic> toBaseMap() {
    return {
      'id': id,
      'user_id': userId,
      'activity_type': activityType.name,
      'category': activityType.category.name,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'duration_seconds': durationSeconds,
      'calories_burned': caloriesBurned,
      'notes': notes,
    };
  }
}

/// Concrete Subclass for Outdoor GPS Activities (Running, Jogging, Cycling, Trekking)
class OutdoorTrackedSession extends ActivitySession {
  final double distanceMeters;
  final double averageSpeedKmh;
  final double maxSpeedKmh;
  final double averagePaceMinPerKm;
  final List<GpsPoint> routePoints;

  const OutdoorTrackedSession({
    required super.id,
    required super.userId,
    required super.activityType,
    required super.startTime,
    required super.endTime,
    required super.durationSeconds,
    required super.caloriesBurned,
    super.notes,
    required this.distanceMeters,
    required this.averageSpeedKmh,
    required this.maxSpeedKmh,
    required this.averagePaceMinPerKm,
    this.routePoints = const [],
  });

  /// Distance in kilometers formatted
  double get distanceKm => distanceMeters / 1000.0;

  /// Formatted pace string: mm:ss /km
  String get formattedPace {
    if (averagePaceMinPerKm.isInfinite || averagePaceMinPerKm.isNaN || averagePaceMinPerKm <= 0) {
      return "--'--\" /km";
    }
    final minutes = averagePaceMinPerKm.floor();
    final seconds = ((averagePaceMinPerKm - minutes) * 60).round();
    return "${minutes.toString().padLeft(2, '0')}'${seconds.toString().padLeft(2, '0')}\" /km";
  }

  @override
  String get performanceSummary =>
      '${distanceKm.toStringAsFixed(2)} km  •  $formattedPace  •  ${caloriesBurned.toStringAsFixed(0)} kcal';

  Map<String, dynamic> toMap() {
    final map = toBaseMap();
    map.addAll({
      'distance_meters': distanceMeters,
      'average_speed_kmh': averageSpeedKmh,
      'max_speed_kmh': maxSpeedKmh,
      'average_pace_min_per_km': averagePaceMinPerKm,
    });
    return map;
  }

  factory OutdoorTrackedSession.fromMap(
    Map<String, dynamic> map, {
    List<GpsPoint> routePoints = const [],
  }) {
    return OutdoorTrackedSession(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      activityType: ActivityType.fromString(map['activity_type'] as String?),
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: DateTime.parse(map['end_time'] as String),
      durationSeconds: map['duration_seconds'] as int,
      caloriesBurned: (map['calories_burned'] as num).toDouble(),
      notes: map['notes'] as String?,
      distanceMeters: (map['distance_meters'] as num?)?.toDouble() ?? 0.0,
      averageSpeedKmh: (map['average_speed_kmh'] as num?)?.toDouble() ?? 0.0,
      maxSpeedKmh: (map['max_speed_kmh'] as num?)?.toDouble() ?? 0.0,
      averagePaceMinPerKm: (map['average_pace_min_per_km'] as num?)?.toDouble() ?? 0.0,
      routePoints: routePoints,
    );
  }
}

/// Concrete Subclass for Strength & Gym Workouts
class GymWorkoutSession extends ActivitySession {
  final String workoutName;
  final List<ExerciseRecord> exercises;

  const GymWorkoutSession({
    required super.id,
    required super.userId,
    required super.activityType,
    required super.startTime,
    required super.endTime,
    required super.durationSeconds,
    required super.caloriesBurned,
    super.notes,
    required this.workoutName,
    this.exercises = const [],
  });

  /// Cumulative volume lifted across all exercises
  double get totalVolumeKg {
    return exercises.fold(0.0, (acc, ex) => acc + ex.totalVolumeKg);
  }

  /// Total number of sets completed across all exercises
  int get totalSetsCount {
    return exercises.fold(0, (acc, ex) => acc + ex.sets.length);
  }

  @override
  String get performanceSummary =>
      '${exercises.length} Exercises  •  $totalSetsCount Sets  •  ${totalVolumeKg.toStringAsFixed(0)} kg Volume';

  Map<String, dynamic> toMap() {
    final map = toBaseMap();
    map.addAll({
      'workout_name': workoutName,
    });
    return map;
  }

  factory GymWorkoutSession.fromMap(
    Map<String, dynamic> map, {
    List<ExerciseRecord> exercises = const [],
  }) {
    return GymWorkoutSession(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      activityType: ActivityType.fromString(map['activity_type'] as String?),
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: DateTime.parse(map['end_time'] as String),
      durationSeconds: map['duration_seconds'] as int,
      caloriesBurned: (map['calories_burned'] as num).toDouble(),
      notes: map['notes'] as String?,
      workoutName: map['workout_name'] as String? ?? 'Gym Session',
      exercises: exercises,
    );
  }
}

/// Concrete Subclass for Timed / Lap-based Indoor Workouts (HIIT, Yoga, Martial Arts, Swimming)
class TimedWorkoutSession extends ActivitySession {
  final String intensityLevel; // Low, Medium, High, Extreme
  final int rounds;
  final int laps;
  final double poolLengthMeters;
  final String? strokeType;

  const TimedWorkoutSession({
    required super.id,
    required super.userId,
    required super.activityType,
    required super.startTime,
    required super.endTime,
    required super.durationSeconds,
    required super.caloriesBurned,
    super.notes,
    required this.intensityLevel,
    this.rounds = 0,
    this.laps = 0,
    this.poolLengthMeters = 25.0,
    this.strokeType,
  });

  /// Total swim distance in meters if swimming
  double get swimDistanceMeters => laps * poolLengthMeters;

  @override
  String get performanceSummary {
    if (activityType == ActivityType.swimming) {
      return '$laps Laps (${swimDistanceMeters.toStringAsFixed(0)}m)  •  ${strokeType ?? 'Freestyle'}';
    }
    if (rounds > 0) {
      return '$rounds Rounds  •  $intensityLevel Intensity  •  ${caloriesBurned.toStringAsFixed(0)} kcal';
    }
    return '$intensityLevel Intensity  •  ${caloriesBurned.toStringAsFixed(0)} kcal';
  }

  Map<String, dynamic> toMap() {
    final map = toBaseMap();
    map.addAll({
      'intensity_level': intensityLevel,
      'rounds': rounds,
      'laps': laps,
      'pool_length_meters': poolLengthMeters,
      'stroke_type': strokeType,
    });
    return map;
  }

  factory TimedWorkoutSession.fromMap(Map<String, dynamic> map) {
    return TimedWorkoutSession(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      activityType: ActivityType.fromString(map['activity_type'] as String?),
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: DateTime.parse(map['end_time'] as String),
      durationSeconds: map['duration_seconds'] as int,
      caloriesBurned: (map['calories_burned'] as num).toDouble(),
      notes: map['notes'] as String?,
      intensityLevel: map['intensity_level'] as String? ?? 'Moderate',
      rounds: (map['rounds'] as int?) ?? 0,
      laps: (map['laps'] as int?) ?? 0,
      poolLengthMeters: (map['pool_length_meters'] as num?)?.toDouble() ?? 25.0,
      strokeType: map['stroke_type'] as String?,
    );
  }
}
