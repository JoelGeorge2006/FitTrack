import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/gps_point.dart';

enum TrackingStatus {
  idle,
  tracking,
  paused,
  completed,
  error,
}

class TrackingState {
  final TrackingStatus status;
  final ActivityType activityType;
  final int durationSeconds;
  final double distanceMeters;
  final double currentSpeedKmh;
  final double averageSpeedKmh;
  final double maxSpeedKmh;
  final double caloriesBurned;
  final List<LatLng> routeCoordinates;
  final List<GpsPoint> recordedGpsPoints;
  final LatLng? currentLocation;
  final String? errorMessage;

  const TrackingState({
    this.status = TrackingStatus.idle,
    this.activityType = ActivityType.running,
    this.durationSeconds = 0,
    this.distanceMeters = 0.0,
    this.currentSpeedKmh = 0.0,
    this.averageSpeedKmh = 0.0,
    this.maxSpeedKmh = 0.0,
    this.caloriesBurned = 0.0,
    this.routeCoordinates = const [],
    this.recordedGpsPoints = const [],
    this.currentLocation,
    this.errorMessage,
  });

  /// Distance in kilometers
  double get distanceKm => distanceMeters / 1000.0;

  /// Current pace in minutes per kilometer
  double get currentPaceMinPerKm {
    if (currentSpeedKmh <= 0.5) return 0.0;
    return 60.0 / currentSpeedKmh;
  }

  /// Average pace in minutes per kilometer
  double get averagePaceMinPerKm {
    if (averageSpeedKmh <= 0.5) return 0.0;
    return 60.0 / averageSpeedKmh;
  }

  /// Formatted duration (HH:mm:ss or mm:ss)
  String get formattedDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Formatted pace string: mm:ss /km
  String get formattedPace {
    final pace = averagePaceMinPerKm;
    if (pace <= 0 || pace.isInfinite || pace.isNaN) {
      return "--'--\" /km";
    }
    final mins = pace.floor();
    final secs = ((pace - mins) * 60).round();
    return "${mins.toString().padLeft(2, '0')}'${secs.toString().padLeft(2, '0')}\" /km";
  }

  TrackingState copyWith({
    TrackingStatus? status,
    ActivityType? activityType,
    int? durationSeconds,
    double? distanceMeters,
    double? currentSpeedKmh,
    double? averageSpeedKmh,
    double? maxSpeedKmh,
    double? caloriesBurned,
    List<LatLng>? routeCoordinates,
    List<GpsPoint>? recordedGpsPoints,
    LatLng? currentLocation,
    String? errorMessage,
  }) {
    return TrackingState(
      status: status ?? this.status,
      activityType: activityType ?? this.activityType,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      averageSpeedKmh: averageSpeedKmh ?? this.averageSpeedKmh,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      routeCoordinates: routeCoordinates ?? this.routeCoordinates,
      recordedGpsPoints: recordedGpsPoints ?? this.recordedGpsPoints,
      currentLocation: currentLocation ?? this.currentLocation,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
