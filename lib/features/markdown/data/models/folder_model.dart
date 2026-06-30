import '../../domain/entities/folder.dart';

class FolderModel extends Folder {
  FolderModel({
    super.id,
    required super.name,
    super.parentId,
    required super.createdAt,
    super.isLocked = false,
    super.lockType,
    super.passwordHash,
  });

  factory FolderModel.fromMap(Map<String, dynamic> map) {
    return FolderModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      parentId: map['parent_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      isLocked: (map['is_locked'] as int?) == 1,
      lockType: map['lock_type'] as String?,
      passwordHash: map['password_hash'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'parent_id': parentId,
      'created_at': createdAt.toIso8601String(),
      'is_locked': isLocked ? 1 : 0,
      'lock_type': lockType,
      'password_hash': passwordHash,
    };
  }
}
