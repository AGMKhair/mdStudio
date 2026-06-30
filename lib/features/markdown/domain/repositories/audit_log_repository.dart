import '../entities/audit_log.dart';

abstract class AuditLogRepository {
  Future<List<AuditLog>> getLogs();
  Future<void> logActivity({
    int? userId,
    int? fileId,
    required String action,
    required String description,
  });
}
