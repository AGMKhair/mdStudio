import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repository_impl/local_security_repository.dart';
import '../../domain/repositories/security_repository.dart';
import 'markdown_file_provider.dart';

final securityRepositoryProvider = Provider<SecurityRepository>((ref) {
  return LocalSecurityRepository();
});

class SecurityState {
  final bool isBiometricsAvailable;
  final bool isAuthenticating;

  SecurityState({
    required this.isBiometricsAvailable,
    required this.isAuthenticating,
  });

  SecurityState copyWith({
    bool? isBiometricsAvailable,
    bool? isAuthenticating,
  }) {
    return SecurityState(
      isBiometricsAvailable: isBiometricsAvailable ?? this.isBiometricsAvailable,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
    );
  }
}

final securityProvider = StateNotifierProvider<SecurityNotifier, SecurityState>((ref) {
  final repository = ref.watch(securityRepositoryProvider);
  return SecurityNotifier(repository, ref);
});

class SecurityNotifier extends StateNotifier<SecurityState> {
  final SecurityRepository _repository;
  final Ref _ref;

  SecurityNotifier(this._repository, this._ref)
      : super(SecurityState(
          isBiometricsAvailable: false,
          isAuthenticating: false,
        )) {
    checkBiometrics();
  }

  Future<void> checkBiometrics() async {
    final available = await _repository.isBiometricsAvailable();
    state = state.copyWith(isBiometricsAvailable: available);
  }

  Future<bool> authenticateBiometrics(String reason) async {
    state = state.copyWith(isAuthenticating: true);
    try {
      final success = await _repository.authenticateBiometrically(reason);
      state = state.copyWith(isAuthenticating: false);
      return success;
    } catch (_) {
      state = state.copyWith(isAuthenticating: false);
      return false;
    }
  }

  Future<void> lockFileWithPassword(int fileId, String password) async {
    final hash = _repository.hashPassword(password);
    await _repository.saveSecureKey('file_lock_hash_$fileId', hash);
    await _ref.read(markdownFileProvider.notifier).updateLockStatus(fileId, true, 'password');
  }

  Future<void> lockFileWithBiometrics(int fileId) async {
    await _ref.read(markdownFileProvider.notifier).updateLockStatus(fileId, true, 'biometric');
  }

  Future<bool> unlockFileWithPassword(int fileId, String password) async {
    final storedHash = await _repository.getSecureKey('file_lock_hash_$fileId');
    if (storedHash == null) return false;
    
    final inputHash = _repository.hashPassword(password);
    return storedHash == inputHash;
  }

  Future<void> removeFileLock(int fileId) async {
    await _repository.deleteSecureKey('file_lock_hash_$fileId');
    await _ref.read(markdownFileProvider.notifier).updateLockStatus(fileId, false, null);
  }

  Future<void> lockFolderWithPassword(int folderId, String password) async {
    final hash = _repository.hashPassword(password);
    await _repository.saveSecureKey('folder_lock_hash_$folderId', hash);
    await _ref.read(markdownFileProvider.notifier).updateFolderLockStatus(folderId, true, 'password');
  }

  Future<void> lockFolderWithBiometrics(int folderId) async {
    await _ref.read(markdownFileProvider.notifier).updateFolderLockStatus(folderId, true, 'biometric');
  }

  Future<bool> unlockFolderWithPassword(int folderId, String password) async {
    final storedHash = await _repository.getSecureKey('folder_lock_hash_$folderId');
    if (storedHash == null) return false;
    
    final inputHash = _repository.hashPassword(password);
    return storedHash == inputHash;
  }

  Future<void> removeFolderLock(int folderId) async {
    await _repository.deleteSecureKey('folder_lock_hash_$folderId');
    await _ref.read(markdownFileProvider.notifier).updateFolderLockStatus(folderId, false, null);
  }
}
