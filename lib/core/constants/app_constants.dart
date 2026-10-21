/// Core application constants and shared configuration
class AppConstants {
  static const String appName = 'FitTrack';
  static const String appTagline = 'Smart Fitness Tracker';
  static const String dbName = 'fittrack.db';
  static const int dbVersion = 1;

  // Session keys
  static const String keyLoggedInUserId = 'logged_in_user_id';
  static const String keyIsLoggedIn = 'is_logged_in';

  // Default User metrics for initial demo
  static const double defaultWeightKg = 70.0;
  static const double defaultHeightCm = 175.0;

  // Standard MAP tile URL template (OpenStreetMap raster tiles, free & offline cacheable)
  static const String osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String osmUserAgent = 'com.fittrack.app';
}

/// User fitness goals defined in requirements
enum FitnessGoal {
  weightLoss('Weight Loss', 'Burn calories & reduce body fat percentage'),
  muscleGain('Muscle Gain', 'Build strength, hypertrophy & lean muscle mass'),
  generalFitness('General Fitness', 'Improve cardiovascular health & overall wellness');

  final String displayName;
  final String description;
  const FitnessGoal(this.displayName, this.description);

  static FitnessGoal fromString(String? value) {
    return FitnessGoal.values.firstWhere(
      (e) => e.name == value || e.displayName == value,
      orElse: () => FitnessGoal.generalFitness,
    );
  }
}

/// Category separation for Live GPS vs Manual Logging
enum ActivityCategory {
  outdoorGps,
  indoorManual,
}

/// All supported fitness activities
enum ActivityType {
  // Outdoor / GPS activities
  running('Running', 'Outdoor GPS', ActivityCategory.outdoorGps, 9.8),
  jogging('Jogging', 'Outdoor GPS', ActivityCategory.outdoorGps, 7.0),
  cycling('Cycling', 'Outdoor GPS', ActivityCategory.outdoorGps, 7.5),
  trekking('Trekking', 'Outdoor GPS', ActivityCategory.outdoorGps, 6.0),

  // Indoor / Manual logging activities
  gymWorkout('Gym Workout', 'Strength & Sets', ActivityCategory.indoorManual, 6.0),
  strengthTraining('Strength Training', 'Hypertrophy', ActivityCategory.indoorManual, 6.0),
  hiit('HIIT', 'High Intensity', ActivityCategory.indoorManual, 8.5),
  yoga('Yoga', 'Flexibility & Flow', ActivityCategory.indoorManual, 3.0),
  martialArts('Martial Arts', 'Combat Conditioning', ActivityCategory.indoorManual, 7.8),
  swimming('Swimming', 'Pool Laps', ActivityCategory.indoorManual, 7.0);

  final String displayName;
  final String subtitle;
  final ActivityCategory category;
  final double defaultMet; // Metabolic Equivalent of Task

  const ActivityType(this.displayName, this.subtitle, this.category, this.defaultMet);

  bool get isOutdoor => category == ActivityCategory.outdoorGps;
  bool get isIndoor => category == ActivityCategory.indoorManual;

  static ActivityType fromString(String? value) {
    return ActivityType.values.firstWhere(
      (e) => e.name == value || e.displayName == value,
      orElse: () => ActivityType.running,
    );
  }
}
