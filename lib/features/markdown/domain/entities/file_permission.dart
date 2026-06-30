class FilePermission {
  final int? id;
  final int fileId;
  final bool passwordEnabled;
  final bool biometricEnabled;
  final DateTime createdAt;

  FilePermission({
    this.id,
    required this.fileId,
    required this.passwordEnabled,
    required this.biometricEnabled,
    required this.createdAt,
  });

  FilePermission copyWith({
    int? id,
    int? fileId,
    bool? passwordEnabled,
    bool? biometricEnabled,
    DateTime? createdAt,
  }) {
    return FilePermission(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      passwordEnabled: passwordEnabled ?? this.passwordEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
