import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../database/database_helper.dart';

/// Concrete SQLite Implementation of UserRepository
class SqliteUserRepository implements UserRepository {
  final DatabaseHelper _dbHelper;

  SqliteUserRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  @override
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(AppConstants.keyLoggedInUserId);
    if (userId == null) return null;

    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return User.fromMap(results.first);
  }

  @override
  Future<void> saveUser(User user) async {
    final db = await _dbHelper.database;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Save session
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyLoggedInUserId, user.id);
    await prefs.setBool(AppConstants.keyIsLoggedIn, true);
  }

  @override
  Future<void> updateUser(User user) async {
    final db = await _dbHelper.database;
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  @override
  Future<void> deleteUser(String userId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
    await clearSession();
  }

  @override
  Future<User?> authenticateDemoUser({
    required String email,
    required String password,
    String? name,
  }) async {
    final db = await _dbHelper.database;

    // Check if user exists by email
    final List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.toLowerCase().trim()],
      limit: 1,
    );

    User user;
    if (results.isNotEmpty) {
      user = User.fromMap(results.first);
    } else {
      // Create new demo user
      final newId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      user = User(
        id: newId,
        name: name ?? (email.contains('@') ? email.split('@').first : 'Fit Athlete'),
        email: email.toLowerCase().trim(),
        heightCm: AppConstants.defaultHeightCm,
        weightKg: AppConstants.defaultWeightKg,
        targetGoal: FitnessGoal.generalFitness,
        createdAt: DateTime.now(),
      );
      await db.insert('users', user.toMap());
    }

    // Persist login session
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyLoggedInUserId, user.id);
    await prefs.setBool(AppConstants.keyIsLoggedIn, true);

    return user;
  }

  @override
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyLoggedInUserId);
    await prefs.setBool(AppConstants.keyIsLoggedIn, false);
  }

  @override
  Future<bool> hasActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;
  }
}
