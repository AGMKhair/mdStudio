class FileHistory {
  final int? id;
  final int fileId;
  final String oldContent;
  final String newContent;
  final String actionType;
  final int? createdBy;
  final DateTime createdAt;

  FileHistory({
    this.id,
    required this.fileId,
    required this.oldContent,
    required this.newContent,
    required this.actionType,
    this.createdBy,
    required this.createdAt,
  });

  FileHistory copyWith({
    int? id,
    int? fileId,
    String? oldContent,
    String? newContent,
    String? actionType,
    int? createdBy,
    DateTime? createdAt,
  }) {
    return FileHistory(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      oldContent: oldContent ?? this.oldContent,
      newContent: newContent ?? this.newContent,
      actionType: actionType ?? this.actionType,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
