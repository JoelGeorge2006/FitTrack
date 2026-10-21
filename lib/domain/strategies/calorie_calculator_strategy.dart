import '../../core/constants/app_constants.dart';

/// Strategy Interface for Calorie Calculation (OOAD Strategy Pattern)
abstract class CalorieCalculatorStrategy {
  /// Calculate estimated calories burned
  /// [weightKg]: Athlete's body weight in kg
  /// [durationSeconds]: Elapsed active time in seconds
  /// [extraMetric]: Optional metric like average speed (km/h) or intensity multiplier
  double calculateCalories({
    required double weightKg,
    required int durationSeconds,
    double extraMetric = 0.0,
  });
}

/// Strategy for Outdoor Running with dynamic speed adjustment
class RunningCalorieCalculatorStrategy implements CalorieCalculatorStrategy {
  @override
  double calculateCalories({
    required double weightKg,
    required int durationSeconds,
    double extraMetric = 0.0, // Speed in km/h
  }) {
    final hours = durationSeconds / 3600.0;
    // Base MET dynamically adjusted by running speed
    double met = 9.8;
    if (extraMetric > 0) {
      if (extraMetric < 8.0) {
        met = 7.5; // Jogging pace
      } else if (extraMetric < 10.0) {
        met = 9.8; // ~10 km/h
      } else if (extraMetric < 12.0) {
        met = 11.5; // ~12 km/h
      } else {
        met = 13.0; // Fast sprint / race pace
      }
    }
    return met * weightKg * hours;
  }
}

/// Strategy for Outdoor Cycling
class CyclingCalorieCalculatorStrategy implements CalorieCalculatorStrategy {
  @override
  double calculateCalories({
    required double weightKg,
    required int durationSeconds,
    double extraMetric = 0.0, // Speed in km/h
  }) {
    final hours = durationSeconds / 3600.0;
    double met = 7.5;
    if (extraMetric > 20.0) {
      met = 9.0;
    } else if (extraMetric > 25.0) {
      met = 11.0;
    }
    return met * weightKg * hours;
  }
}

/// Strategy for Gym & Strength Training
class GymCalorieCalculatorStrategy implements CalorieCalculatorStrategy {
  @override
  double calculateCalories({
    required double weightKg,
    required int durationSeconds,
    double extraMetric = 0.0, // Volume or intensity
  }) {
    final hours = durationSeconds / 3600.0;
    const double met = 6.0;
    return met * weightKg * hours;
  }
}

/// Strategy for High-Intensity Interval Training (HIIT)
class HiitCalorieCalculatorStrategy implements CalorieCalculatorStrategy {
  @override
  double calculateCalories({
    required double weightKg,
    required int durationSeconds,
    double extraMetric = 0.0,
  }) {
    final hours = durationSeconds / 3600.0;
    const double met = 8.5;
    return met * weightKg * hours;
  }
}

/// Strategy for Yoga & Flexibility Flow
class YogaCalorieCalculatorStrategy implements CalorieCalculatorStrategy {
  @override
  double calculateCalories({
    required double weightKg,
    required int durationSeconds,
    double extraMetric = 0.0,
  }) {
    final hours = durationSeconds / 3600.0;
    const double met = 3.0;
    return met * weightKg * hours;
  }
}

/// Strategy for Martial Arts
class MartialArtsCalorieCalculatorStrategy implements CalorieCalculatorStrategy {
  @override
  double calculateCalories({
    required double weightKg,
    required int durationSeconds,
    double extraMetric = 0.0,
  }) {
    final hours = durationSeconds / 3600.0;
    const double met = 7.8;
    return met * weightKg * hours;
  }
}

/// Strategy for Swimming
class SwimmingCalorieCalculatorStrategy implements CalorieCalculatorStrategy {
  @override
  double calculateCalories({
    required double weightKg,
    required int durationSeconds,
    double extraMetric = 0.0,
  }) {
    final hours = durationSeconds / 3600.0;
    const double met = 7.0;
    return met * weightKg * hours;
  }
}

/// Factory pattern to return the appropriate strategy based on activity type
class CalorieCalculatorFactory {
  static CalorieCalculatorStrategy getStrategy(ActivityType type) {
    switch (type) {
      case ActivityType.running:
      case ActivityType.jogging:
      case ActivityType.trekking:
        return RunningCalorieCalculatorStrategy();
      case ActivityType.cycling:
        return CyclingCalorieCalculatorStrategy();
      case ActivityType.gymWorkout:
      case ActivityType.strengthTraining:
        return GymCalorieCalculatorStrategy();
      case ActivityType.hiit:
        return HiitCalorieCalculatorStrategy();
      case ActivityType.yoga:
        return YogaCalorieCalculatorStrategy();
      case ActivityType.martialArts:
        return MartialArtsCalorieCalculatorStrategy();
      case ActivityType.swimming:
        return SwimmingCalorieCalculatorStrategy();
    }
  }
}
