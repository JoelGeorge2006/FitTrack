/// Value Object representing a single coordinate captured during outdoor tracking
class GpsPoint {
  final String id;
  final String sessionId;
  final double latitude;
  final double longitude;
  final double altitude;
  final double speedMps; // meters per second
  final DateTime timestamp;

  const GpsPoint({
    required this.id,
    required this.sessionId,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.speedMps,
    required this.timestamp,
  });

  /// Speed in kilometers per hour
  double get speedKmh => speedMps * 3.6;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'speed_mps': speedMps,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory GpsPoint.fromMap(Map<String, dynamic> map) {
    return GpsPoint(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      altitude: (map['altitude'] as num?)?.toDouble() ?? 0.0,
      speedMps: (map['speed_mps'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}
