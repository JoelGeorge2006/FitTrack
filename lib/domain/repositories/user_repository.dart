import '../entities/user.dart';

/// Abstract Repository for User Profile and Session Management
abstract class UserRepository {
  Future<User?> getCurrentUser();
  Future<void> saveUser(User user);
  Future<void> updateUser(User user);
  Future<void> deleteUser(String userId);
  Future<User?> authenticateDemoUser({required String email, required String password, String? name});
  Future<void> clearSession();
  Future<bool> hasActiveSession();
}
