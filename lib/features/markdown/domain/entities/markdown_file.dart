class MarkdownFile {
  final int? id;
  final String uuid;
  final String title;
  final String fileName;
  final String content;
  final int? folderId;
  final bool isLocked;
  final String? lockType;
  final int? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastOpenedAt;

  MarkdownFile({
    this.id,
    required this.uuid,
    required this.title,
    required this.fileName,
    required this.content,
    this.folderId,
    required this.isLocked,
    this.lockType,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.lastOpenedAt,
  });

  MarkdownFile copyWith({
    int? id,
    String? uuid,
    String? title,
    String? fileName,
    String? content,
    int? folderId,
    bool? isLocked,
    String? lockType,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastOpenedAt,
  }) {
    return MarkdownFile(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      title: title ?? this.title,
      fileName: fileName ?? this.fileName,
      content: content ?? this.content,
      folderId: folderId ?? this.folderId,
      isLocked: isLocked ?? this.isLocked,
      lockType: lockType ?? this.lockType,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    );
  }
}
