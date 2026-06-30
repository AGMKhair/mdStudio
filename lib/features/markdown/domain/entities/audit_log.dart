class AuditLog {
  final int? id;
  final int? userId;
  final int? fileId;
  final String action;
  final String description;
  final String deviceInfo;
  final DateTime createdAt;

  AuditLog({
    this.id,
    this.userId,
    this.fileId,
    required this.action,
    required this.description,
    required this.deviceInfo,
    required this.createdAt,
  });

  AuditLog copyWith({
    int? id,
    int? userId,
    int? fileId,
    String? action,
    String? description,
    String? deviceInfo,
    DateTime? createdAt,
  }) {
    return AuditLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fileId: fileId ?? this.fileId,
      action: action ?? this.action,
      description: description ?? this.description,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
