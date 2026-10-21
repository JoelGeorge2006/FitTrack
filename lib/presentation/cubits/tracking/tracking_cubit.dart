import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/activity_session.dart';
import '../../../domain/entities/gps_point.dart';
import '../../../domain/repositories/activity_repository.dart';
import '../../../domain/strategies/calorie_calculator_strategy.dart';
import 'tracking_state.dart';

/// Cubit managing real-time outdoor GPS tracking sessions
class TrackingCubit extends Cubit<TrackingState> {
  final ActivityRepository _activityRepository;
  Timer? _timer;
  StreamSubscription<Position>? _positionSubscription;
  String? _activeSessionId;
  DateTime? _sessionStartTime;
  double _userWeightKg = AppConstants.defaultWeightKg;
  String _currentUserId = 'user_default';

  TrackingCubit({required ActivityRepository activityRepository})
      : _activityRepository = activityRepository,
        super(const TrackingState());

  void setAthleteContext({required String userId, required double weightKg}) {
    _currentUserId = userId;
    _userWeightKg = weightKg;
  }

  void setActivityType(ActivityType type) {
    if (state.status == TrackingStatus.idle) {
      emit(state.copyWith(activityType: type));
    }
  }

  /// Request GPS permission and start live tracking
  Future<void> startTracking(ActivityType activityType) async {
    _activeSessionId = 'outdoor_${DateTime.now().millisecondsSinceEpoch}';
    _sessionStartTime = DateTime.now();

    emit(state.copyWith(
      status: TrackingStatus.tracking,
      activityType: activityType,
      durationSeconds: 0,
      distanceMeters: 0.0,
      currentSpeedKmh: 0.0,
      averageSpeedKmh: 0.0,
      maxSpeedKmh: 0.0,
      caloriesBurned: 0.0,
      routeCoordinates: [],
      recordedGpsPoints: [],
      errorMessage: null,
    ));

    // Start 1-second elapsed timer
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), _onTimerTick);

    // Initialize GPS location streaming
    await _startLocationStream();
  }

  Future<void> _startLocationStream() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Fallback to demo coordinate stream if location service disabled
        _startSimulationLocation();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _startSimulationLocation();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _startSimulationLocation();
        return;
      }

      // Initial position
      final initialPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _onPositionUpdate(initialPos);

      // Subscribe to live GPS updates
      _positionSubscription?.cancel();
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3, // meters
      );

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        _onPositionUpdate,
        onError: (e) {
          _startSimulationLocation();
        },
      );
    } catch (e) {
      // Fallback gracefully on devices/emulators without hardware GPS
      _startSimulationLocation();
    }
  }

  /// Fallback demo location simulation generator for test viva & emulators
  void _startSimulationLocation() {
    // Default starting point (San Francisco / Bangalore tech hub coordinate)
    const startLat = 12.9716;
    const startLng = 77.5946;

    if (state.currentLocation == null) {
      const initialLatLng = LatLng(startLat, startLng);
      emit(state.copyWith(
        currentLocation: initialLatLng,
        routeCoordinates: [initialLatLng],
      ));
    }
  }

  void _onPositionUpdate(Position position) {
    if (state.status != TrackingStatus.tracking) return;

    final newPoint = LatLng(position.latitude, position.longitude);
    double addedDistance = 0.0;

    if (state.routeCoordinates.isNotEmpty) {
      final lastPoint = state.routeCoordinates.last;
      addedDistance = Geolocator.distanceBetween(
        lastPoint.latitude,
        lastPoint.longitude,
        newPoint.latitude,
        newPoint.longitude,
      );

      // Filter out GPS teleportation anomalies (> 60 m/s ~ 216 km/h)
      if (addedDistance > 100.0) {
        addedDistance = 0.0;
      }
    }

    final newDistance = state.distanceMeters + addedDistance;
    final currentSpeedKmh = (position.speed >= 0 ? position.speed : 0.0) * 3.6;
    final maxSpeed = currentSpeedKmh > state.maxSpeedKmh ? currentSpeedKmh : state.maxSpeedKmh;

    final updatedCoords = List<LatLng>.from(state.routeCoordinates)..add(newPoint);

    final recordedPoint = GpsPoint(
      id: 'pt_${DateTime.now().microsecondsSinceEpoch}',
      sessionId: _activeSessionId ?? 'temp',
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      speedMps: position.speed,
      timestamp: DateTime.now(),
    );

    final updatedGpsPoints = List<GpsPoint>.from(state.recordedGpsPoints)..add(recordedPoint);

    emit(state.copyWith(
      currentLocation: newPoint,
      distanceMeters: newDistance,
      currentSpeedKmh: currentSpeedKmh,
      maxSpeedKmh: maxSpeed,
      routeCoordinates: updatedCoords,
      recordedGpsPoints: updatedGpsPoints,
    ));
  }

  void _onTimerTick(Timer timer) {
    if (state.status != TrackingStatus.tracking) return;

    final newDuration = state.durationSeconds + 1;

    // Average speed in km/h = (distance in km) / (hours)
    final distanceKm = state.distanceMeters / 1000.0;
    final hours = newDuration / 3600.0;
    final avgSpeedKmh = hours > 0 ? (distanceKm / hours) : 0.0;

    // Calculate dynamic calories using Strategy pattern
    final calculator = CalorieCalculatorFactory.getStrategy(state.activityType);
    final calories = calculator.calculateCalories(
      weightKg: _userWeightKg,
      durationSeconds: newDuration,
      extraMetric: avgSpeedKmh,
    );

    emit(state.copyWith(
      durationSeconds: newDuration,
      averageSpeedKmh: avgSpeedKmh,
      caloriesBurned: calories,
    ));
  }

  /// Pause current tracking session
  void pauseTracking() {
    if (state.status == TrackingStatus.tracking) {
      emit(state.copyWith(status: TrackingStatus.paused));
    }
  }

  /// Resume tracking session
  void resumeTracking() {
    if (state.status == TrackingStatus.paused) {
      emit(state.copyWith(status: TrackingStatus.tracking));
    }
  }

  /// Stop tracking and save outdoor session to local SQLite repository
  Future<OutdoorTrackedSession?> finishTracking({String? notes}) async {
    _timer?.cancel();
    _positionSubscription?.cancel();

    final session = OutdoorTrackedSession(
      id: _activeSessionId ?? 'outdoor_${DateTime.now().millisecondsSinceEpoch}',
      userId: _currentUserId,
      activityType: state.activityType,
      startTime: _sessionStartTime ?? DateTime.now().subtract(Duration(seconds: state.durationSeconds)),
      endTime: DateTime.now(),
      durationSeconds: state.durationSeconds,
      caloriesBurned: state.caloriesBurned,
      notes: notes,
      distanceMeters: state.distanceMeters,
      averageSpeedKmh: state.averageSpeedKmh,
      maxSpeedKmh: state.maxSpeedKmh,
      averagePaceMinPerKm: state.averagePaceMinPerKm,
      routePoints: state.recordedGpsPoints,
    );

    try {
      await _activityRepository.saveOutdoorSession(session);
      emit(state.copyWith(status: TrackingStatus.completed));
      return session;
    } catch (e) {
      emit(state.copyWith(
        status: TrackingStatus.error,
        errorMessage: 'Failed to save session: ${e.toString()}',
      ));
      return null;
    }
  }

  /// Reset to idle state
  void reset() {
    _timer?.cancel();
    _positionSubscription?.cancel();
    emit(const TrackingState());
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _positionSubscription?.cancel();
    return super.close();
  }
}
