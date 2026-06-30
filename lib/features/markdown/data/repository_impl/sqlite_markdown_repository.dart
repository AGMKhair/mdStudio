import '../../../../core/database/database_helper.dart';
import '../../domain/entities/markdown_file.dart';
import '../../domain/repositories/markdown_repository.dart';
import '../models/markdown_file_model.dart';

class SQLiteMarkdownRepository implements MarkdownRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<List<MarkdownFile>> getFiles() async {
    final db = await _dbHelper.database;
    final result = await db.query('markdown_files', orderBy: 'last_opened_at DESC');
    return result.map((map) => MarkdownFileModel.fromMap(map)).toList();
  }

  @override
  Future<MarkdownFile?> getFileById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query('markdown_files', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return MarkdownFileModel.fromMap(result.first);
    }
    return null;
  }

  @override
  Future<MarkdownFile?> getFileByUuid(String uuid) async {
    final db = await _dbHelper.database;
    final result = await db.query('markdown_files', where: 'uuid = ?', whereArgs: [uuid]);
    if (result.isNotEmpty) {
      return MarkdownFileModel.fromMap(result.first);
    }
    return null;
  }

  @override
  Future<MarkdownFile> saveFile(MarkdownFile file) async {
    final db = await _dbHelper.database;
    final model = MarkdownFileModel.fromEntity(file);
    final id = await db.insert('markdown_files', model.toMap());
    return file.copyWith(id: id);
  }

  @override
  Future<void> updateFile(MarkdownFile file) async {
    final db = await _dbHelper.database;
    final model = MarkdownFileModel.fromEntity(file);
    await db.update(
      'markdown_files',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [file.id],
    );
  }

  @override
  Future<void> deleteFile(int id) async {
    final db = await _dbHelper.database;
    await db.delete('markdown_files', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<MarkdownFile>> searchFiles(String query) async {
    final db = await _dbHelper.database;
    final lowercaseQuery = '%${query.toLowerCase()}%';
    final result = await db.rawQuery('''
      SELECT * FROM markdown_files 
      WHERE LOWER(title) LIKE ? OR LOWER(content) LIKE ? OR LOWER(file_name) LIKE ?
      ORDER BY last_opened_at DESC
    ''', [lowercaseQuery, lowercaseQuery, lowercaseQuery]);
    
    return result.map((map) => MarkdownFileModel.fromMap(map)).toList();
  }

  @override
  Future<List<MarkdownFile>> getFilesByFolder(int? folderId) async {
    final db = await _dbHelper.database;
    final result = folderId == null 
      ? await db.query('markdown_files', where: 'folder_id IS NULL', orderBy: 'last_opened_at DESC')
      : await db.query('markdown_files', where: 'folder_id = ?', whereArgs: [folderId], orderBy: 'last_opened_at DESC');
    return result.map((map) => MarkdownFileModel.fromMap(map)).toList();
  }

  @override
  Future<Map<String, dynamic>> getStatistics() async {
    final db = await _dbHelper.database;
    
    // Total files count
    final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM markdown_files');
    final totalFiles = countResult.first['count'] as int? ?? 0;

    // Locked files count
    final lockedResult = await db.rawQuery('SELECT COUNT(*) as count FROM markdown_files WHERE is_locked = 1');
    final lockedFiles = lockedResult.first['count'] as int? ?? 0;

    // Total edits (from history records)
    final editsResult = await db.rawQuery('SELECT COUNT(*) as count FROM file_history');
    final totalEdits = editsResult.first['count'] as int? ?? 0;

    // Total words count
    final contents = await db.query('markdown_files', columns: ['content']);
    int totalWords = 0;
    for (var row in contents) {
      final text = row['content'] as String? ?? '';
      if (text.trim().isNotEmpty) {
        totalWords += text.trim().split(RegExp(r'\s+')).length;
      }
    }

    // Last activity
    final lastLog = await db.query('audit_logs', orderBy: 'created_at DESC', limit: 1);
    String lastActivity = 'No recent activity';
    if (lastLog.isNotEmpty) {
      lastActivity = '${lastLog.first['action']}: ${lastLog.first['description']}';
    }

    return {
      'totalFiles': totalFiles,
      'lockedFiles': lockedFiles,
      'totalEdits': totalEdits,
      'totalWords': totalWords,
      'lastActivity': lastActivity,
    };
  }
}
