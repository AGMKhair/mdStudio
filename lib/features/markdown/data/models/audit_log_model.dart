import '../../domain/entities/audit_log.dart';

class AuditLogModel extends AuditLog {
  AuditLogModel({
    super.id,
    super.userId,
    super.fileId,
    required super.action,
    required super.description,
    required super.deviceInfo,
    required super.createdAt,
  });

  factory AuditLogModel.fromMap(Map<String, dynamic> map) {
    return AuditLogModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int?,
      fileId: map['file_id'] as int?,
      action: map['action'] as String,
      description: map['description'] as String,
      deviceInfo: map['device_info'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'file_id': fileId,
      'action': action,
      'description': description,
      'device_info': deviceInfo,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
