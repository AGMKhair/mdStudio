import '../../domain/entities/file_history.dart';

class FileHistoryModel extends FileHistory {
  FileHistoryModel({
    super.id,
    required super.fileId,
    required super.oldContent,
    required super.newContent,
    required super.actionType,
    super.createdBy,
    required super.createdAt,
  });

  factory FileHistoryModel.fromMap(Map<String, dynamic> map) {
    return FileHistoryModel(
      id: map['id'] as int?,
      fileId: map['file_id'] as int,
      oldContent: map['old_content'] as String,
      newContent: map['new_content'] as String,
      actionType: map['action_type'] as String,
      createdBy: map['created_by'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'file_id': fileId,
      'old_content': oldContent,
      'new_content': newContent,
      'action_type': actionType,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
