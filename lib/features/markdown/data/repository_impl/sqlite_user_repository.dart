import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../models/user_model.dart';

class SQLiteUserRepository implements UserRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  Future<User?> login(String email, String password) async {
    final db = await _dbHelper.database;
    final hash = _hashPassword(password);
    
    final result = await db.query(
      'users',
      where: 'email = ? AND password_hash = ?',
      whereArgs: [email.trim(), hash],
    );

    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }
    return null;
  }

  @override
  Future<User> register(String name, String email, String password) async {
    final db = await _dbHelper.database;
    final hash = _hashPassword(password);
    final now = DateTime.now();

    final model = UserModel(
      name: name.trim(),
      email: email.trim().toLowerCase(),
      passwordHash: hash,
      biometricEnabled: false,
      createdAt: now,
      updatedAt: now,
    );

    final id = await db.insert('users', model.toMap());
    return model.copyWith(id: id);
  }

  @override
  Future<void> updateBiometrics(int userId, bool enabled) async {
    final db = await _dbHelper.database;
    await db.update(
      'users',
      {'biometric_enabled': enabled ? 1 : 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  @override
  Future<User?> getUserById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }
    return null;
  }

  @override
  Future<bool> hasUsers() async {
    final db = await _dbHelper.database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM users'));
    return count != null && count > 0;
  }
}
