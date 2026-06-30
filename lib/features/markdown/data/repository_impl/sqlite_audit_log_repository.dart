import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/entities/audit_log.dart';
import '../../domain/repositories/audit_log_repository.dart';
import '../models/audit_log_model.dart';

class SQLiteAuditLogRepository implements AuditLogRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<List<AuditLog>> getLogs() async {
    final db = await _dbHelper.database;
    final result = await db.query('audit_logs', orderBy: 'created_at DESC');
    return result.map((map) => AuditLogModel.fromMap(map)).toList();
  }

  @override
  Future<void> logActivity({
    int? userId,
    int? fileId,
    required String action,
    required String description,
  }) async {
    final db = await _dbHelper.database;
    final deviceInfo = _getDeviceString();
    final model = AuditLogModel(
      userId: userId,
      fileId: fileId,
      action: action,
      description: description,
      deviceInfo: deviceInfo,
      createdAt: DateTime.now(),
    );
    await db.insert('audit_logs', model.toMap());
  }

  String _getDeviceString() {
    if (kIsWeb) return 'Web Browser';
    try {
      if (Platform.isAndroid) return 'Android Device';
      if (Platform.isIOS) return 'iOS Device';
      if (Platform.isMacOS) return 'macOS Workstation';
      if (Platform.isWindows) return 'Windows Workstation';
      if (Platform.isLinux) return 'Linux Workstation';
    } catch (_) {}
    return 'Unknown Device';
  }
}
