import '../entities/user.dart';

abstract class UserRepository {
  Future<User?> login(String email, String password);
  Future<User> register(String name, String email, String password);
  Future<void> updateBiometrics(int userId, bool enabled);
  Future<User?> getUserById(int id);
  Future<bool> hasUsers();
}
