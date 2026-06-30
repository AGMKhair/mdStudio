import '../../domain/entities/markdown_file.dart';

class MarkdownFileModel extends MarkdownFile {
  MarkdownFileModel({
    super.id,
    required super.uuid,
    required super.title,
    required super.fileName,
    required super.content,
    super.folderId,
    required super.isLocked,
    super.lockType,
    super.createdBy,
    required super.createdAt,
    required super.updatedAt,
    required super.lastOpenedAt,
  });

  factory MarkdownFileModel.fromMap(Map<String, dynamic> map) {
    return MarkdownFileModel(
      id: map['id'] as int?,
      uuid: map['uuid'] as String,
      title: map['title'] as String,
      fileName: map['file_name'] as String,
      content: map['content'] as String,
      folderId: map['folder_id'] as int?,
      isLocked: (map['is_locked'] as int? ?? 0) == 1,
      lockType: map['lock_type'] as String?,
      createdBy: map['created_by'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      lastOpenedAt: DateTime.parse(map['last_opened_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'uuid': uuid,
      'title': title,
      'file_name': fileName,
      'content': content,
      'folder_id': folderId,
      'is_locked': isLocked ? 1 : 0,
      'lock_type': lockType,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_opened_at': lastOpenedAt.toIso8601String(),
    };
  }

  factory MarkdownFileModel.fromEntity(MarkdownFile entity) {
    return MarkdownFileModel(
      id: entity.id,
      uuid: entity.uuid,
      title: entity.title,
      fileName: entity.fileName,
      content: entity.content,
      folderId: entity.folderId,
      isLocked: entity.isLocked,
      lockType: entity.lockType,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      lastOpenedAt: entity.lastOpenedAt,
    );
  }
}
