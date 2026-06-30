class Folder {
  final int? id;
  final String name;
  final int? parentId;
  final DateTime createdAt;
  final bool isLocked;
  final String? lockType;
  final String? passwordHash;

  Folder({
    this.id,
    required this.name,
    this.parentId,
    required this.createdAt,
    this.isLocked = false,
    this.lockType,
    this.passwordHash,
  });

  Folder copyWith({
    int? id,
    String? name,
    int? parentId,
    DateTime? createdAt,
    bool? isLocked,
    String? lockType,
    String? passwordHash,
  }) {
    return Folder(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt ?? this.createdAt,
      isLocked: isLocked ?? this.isLocked,
      lockType: lockType ?? this.lockType,
      passwordHash: passwordHash ?? this.passwordHash,
    );
  }
}
