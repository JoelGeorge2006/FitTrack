import '../../core/constants/app_constants.dart';

/// User entity representing the authenticated athlete profile
class User {
  final String id;
  final String name;
  final String email;
  final double heightCm;
  final double weightKg;
  final FitnessGoal targetGoal;
  final String? profileImagePath;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.heightCm,
    required this.weightKg,
    required this.targetGoal,
    this.profileImagePath,
    required this.createdAt,
  });

  /// Calculate Body Mass Index (BMI = kg / m^2)
  double get bmi {
    if (heightCm <= 0) return 0.0;
    final heightM = heightCm / 100.0;
    return weightKg / (heightM * heightM);
  }

  /// BMI Category description
  String get bmiCategory {
    final val = bmi;
    if (val < 18.5) return 'Underweight';
    if (val < 25.0) return 'Normal weight';
    if (val < 30.0) return 'Overweight';
    return 'Obese';
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    double? heightCm,
    double? weightKg,
    FitnessGoal? targetGoal,
    String? profileImagePath,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      targetGoal: targetGoal ?? this.targetGoal,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'target_goal': targetGoal.name,
      'profile_image_path': profileImagePath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      heightCm: (map['height_cm'] as num?)?.toDouble() ?? 175.0,
      weightKg: (map['weight_kg'] as num?)?.toDouble() ?? 70.0,
      targetGoal: FitnessGoal.fromString(map['target_goal'] as String?),
      profileImagePath: map['profile_image_path'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
