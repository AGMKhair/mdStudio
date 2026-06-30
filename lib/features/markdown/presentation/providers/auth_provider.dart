import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repository_impl/sqlite_user_repository.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return SQLiteUserRepository();
});

final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return AuthNotifier(repository);
});

class AuthNotifier extends StateNotifier<User?> {
  final UserRepository _repository;

  AuthNotifier(this._repository) : super(null);

  Future<bool> login(String email, String password) async {
    final user = await _repository.login(email, password);
    if (user != null) {
      state = user;
      return true;
    }
    return false;
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      final user = await _repository.register(name, email, password);
      state = user;
      return true;
    } catch (_) {
      return false;
    }
  }

  void logout() {
    state = null;
  }

  Future<void> toggleBiometrics(bool enabled) async {
    final user = state;
    if (user != null && user.id != null) {
      await _repository.updateBiometrics(user.id!, enabled);
      state = user.copyWith(biometricEnabled: enabled);
    }
  }

  Future<bool> hasUsers() async {
    return await _repository.hasUsers();
  }

  Future<bool> loginBiometrically() async {
    final firstUser = await _repository.getUserById(1);
    if (firstUser != null) {
      state = firstUser;
      return true;
    }
    return false;
  }
}
