import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/core/constants/app_constants.dart';
import 'package:fittrack/domain/entities/user.dart';
import 'package:fittrack/domain/strategies/calorie_calculator_strategy.dart';

void main() {
  group('OOAD Strategy Pattern - CalorieCalculator Tests', () {
    final user = User(
      id: 'test-user-1',
      name: 'Joel',
      email: 'joel@fittrack.com',
      heightCm: 175.0,
      weightKg: 70.0,
      targetGoal: FitnessGoal.weightLoss,
      createdAt: DateTime.now(),
    );

    test('RunningCalorieCalculatorStrategy computes MET * weight * time correctly', () {
      final runningCalc = RunningCalorieCalculatorStrategy();
      // 30 mins = 0.5 hours. Calories = 9.8 * 70 * 0.5 = 343.0
      final calories = runningCalc.calculateCalories(
        weightKg: user.weightKg,
        durationSeconds: 1800,
        extraMetric: 10.0,
      );
      expect(calories, closeTo(402.5, 0.5));
    });

    test('CyclingCalorieCalculatorStrategy computes MET * weight * time correctly', () {
      final cyclingCalc = CyclingCalorieCalculatorStrategy();
      // 60 mins = 1.0 hours. Calories = 7.5 * 70 * 1.0 = 525.0
      final calories = cyclingCalc.calculateCalories(
        weightKg: user.weightKg,
        durationSeconds: 3600,
        extraMetric: 18.0,
      );
      expect(calories, closeTo(525.0, 1.0));
    });

    test('CalorieCalculatorFactory resolves correct strategy', () {
      final running = CalorieCalculatorFactory.getStrategy(ActivityType.running);
      final gym = CalorieCalculatorFactory.getStrategy(ActivityType.gymWorkout);
      final yoga = CalorieCalculatorFactory.getStrategy(ActivityType.yoga);

      expect(running, isA<RunningCalorieCalculatorStrategy>());
      expect(gym, isA<GymCalorieCalculatorStrategy>());
      expect(yoga, isA<YogaCalorieCalculatorStrategy>());
    });

    test('User entity calculates BMI correctly', () {
      // BMI = 70 / (1.75 * 1.75) = 22.86
      expect(user.bmi, closeTo(22.86, 0.1));
      expect(user.bmiCategory, equals('Normal weight'));
    });
  });
}
