import '../../../../core/database/database_helper.dart';
import '../../domain/entities/file_history.dart';
import '../../domain/repositories/history_repository.dart';
import '../models/file_history_model.dart';

class SQLiteHistoryRepository implements HistoryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<List<FileHistory>> getHistoryForFile(int fileId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'file_history',
      where: 'file_id = ?',
      whereArgs: [fileId],
      orderBy: 'created_at DESC',
    );
    return result.map((map) => FileHistoryModel.fromMap(map)).toList();
  }

  @override
  Future<FileHistory> saveHistory(FileHistory history) async {
    final db = await _dbHelper.database;
    final model = FileHistoryModel(
      id: history.id,
      fileId: history.fileId,
      oldContent: history.oldContent,
      newContent: history.newContent,
      actionType: history.actionType,
      createdBy: history.createdBy,
      createdAt: history.createdAt,
    );
    final id = await db.insert('file_history', model.toMap());
    return history.copyWith(id: id);
  }

  @override
  Future<void> deleteHistoryForFile(int fileId) async {
    final db = await _dbHelper.database;
    await db.delete('file_history', where: 'file_id = ?', whereArgs: [fileId]);
  }
}
