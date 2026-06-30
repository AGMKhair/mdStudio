import '../../../../core/database/database_helper.dart';
import '../../domain/entities/folder.dart';
import '../../domain/repositories/folder_repository.dart';
import '../models/folder_model.dart';

class SQLiteFolderRepository implements FolderRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<List<Folder>> getFolders() async {
    final db = await _dbHelper.database;
    final result = await db.query('folders', orderBy: 'name ASC');
    return result.map((map) => FolderModel.fromMap(map)).toList();
  }

  @override
  Future<Folder?> getFolderById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query('folders', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return FolderModel.fromMap(result.first);
    }
    return null;
  }

  @override
  Future<Folder> saveFolder(Folder folder) async {
    final db = await _dbHelper.database;
    final model = FolderModel(
      id: folder.id,
      name: folder.name,
      parentId: folder.parentId,
      createdAt: folder.createdAt,
      isLocked: folder.isLocked,
      lockType: folder.lockType,
      passwordHash: folder.passwordHash,
    );
    final id = await db.insert('folders', model.toMap());
    return folder.copyWith(id: id);
  }

  @override
  Future<void> updateFolder(Folder folder) async {
    final db = await _dbHelper.database;
    final model = FolderModel(
      id: folder.id,
      name: folder.name,
      parentId: folder.parentId,
      createdAt: folder.createdAt,
      isLocked: folder.isLocked,
      lockType: folder.lockType,
      passwordHash: folder.passwordHash,
    );
    await db.update(
      'folders',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }

  @override
  Future<void> deleteFolder(int id) async {
    final db = await _dbHelper.database;
    await db.delete('folders', where: 'id = ?', whereArgs: [id]);
  }
}
