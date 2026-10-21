import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/user_repository.dart';
import 'auth_state.dart';

/// Cubit managing User Authentication, Session State, and Profile Updates
class AuthCubit extends Cubit<AuthState> {
  final UserRepository _userRepository;

  AuthCubit({required UserRepository userRepository})
      : _userRepository = userRepository,
        super(const AuthInitial());

  /// Check whether user has an active session from previous app run
  Future<void> checkAuthStatus() async {
    emit(const AuthLoading(message: 'Verifying session...'));
    try {
      final user = await _userRepository.getCurrentUser();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(const Unauthenticated());
      }
    } catch (e) {
      emit(const Unauthenticated());
    }
  }

  /// Sign in or authenticate demo user
  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading(message: 'Signing in...'));
    try {
      if (email.trim().isEmpty || !email.contains('@')) {
        emit(const AuthError('Please enter a valid email address.'));
        return;
      }
      if (password.length < 6) {
        emit(const AuthError('Password must be at least 6 characters.'));
        return;
      }

      final user = await _userRepository.authenticateDemoUser(
        email: email,
        password: password,
      );

      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(const AuthError('Invalid credentials. Please try again.'));
      }
    } catch (e) {
      emit(AuthError('Authentication failed: ${e.toString()}'));
    }
  }

  /// Register new user profile with fitness metrics
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required double heightCm,
    required double weightKg,
    required FitnessGoal targetGoal,
  }) async {
    emit(const AuthLoading(message: 'Creating your fitness profile...'));
    try {
      if (name.trim().isEmpty) {
        emit(const AuthError('Please enter your full name.'));
        return;
      }
      if (email.trim().isEmpty || !email.contains('@')) {
        emit(const AuthError('Please enter a valid email address.'));
        return;
      }
      if (password.length < 6) {
        emit(const AuthError('Password must be at least 6 characters.'));
        return;
      }

      final newUser = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: name.trim(),
        email: email.trim().toLowerCase(),
        heightCm: heightCm,
        weightKg: weightKg,
        targetGoal: targetGoal,
        createdAt: DateTime.now(),
      );

      await _userRepository.saveUser(newUser);
      emit(Authenticated(newUser));
    } catch (e) {
      emit(AuthError('Registration failed: ${e.toString()}'));
    }
  }

  /// Update user profile metrics (height, weight, fitness goal)
  Future<void> updateProfile({
    required String name,
    required double heightCm,
    required double weightKg,
    required FitnessGoal targetGoal,
  }) async {
    final currentState = state;
    if (currentState is! Authenticated) return;

    try {
      final updatedUser = currentState.user.copyWith(
        name: name,
        heightCm: heightCm,
        weightKg: weightKg,
        targetGoal: targetGoal,
      );

      await _userRepository.updateUser(updatedUser);
      emit(Authenticated(updatedUser));
    } catch (e) {
      emit(AuthError('Failed to update profile: ${e.toString()}'));
    }
  }

  /// Sign out and clear active session
  Future<void> logout() async {
    emit(const AuthLoading(message: 'Signing out...'));
    await _userRepository.clearSession();
    emit(const Unauthenticated());
  }
}
