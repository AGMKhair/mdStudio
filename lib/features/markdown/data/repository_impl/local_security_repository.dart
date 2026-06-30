import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/repositories/security_repository.dart';

class LocalSecurityRepository implements SecurityRepository {
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<bool> isBiometricsAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> authenticateBiometrically(String reason) async {
    try {
      final availableBiometrics = await _auth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        // Fallback or alert if no biometrics are enrolled on the hardware
        return false;
      }
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> saveSecureKey(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  @override
  Future<String?> getSecureKey(String key) async {
    return await _storage.read(key: key);
  }

  @override
  Future<void> deleteSecureKey(String key) async {
    await _storage.delete(key: key);
  }

  @override
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
