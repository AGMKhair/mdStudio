abstract class SecurityRepository {
  Future<bool> isBiometricsAvailable();
  Future<bool> authenticateBiometrically(String reason);
  Future<void> saveSecureKey(String key, String value);
  Future<String?> getSecureKey(String key);
  Future<void> deleteSecureKey(String key);
  String hashPassword(String password);
}
