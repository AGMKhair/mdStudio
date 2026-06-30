import '../entities/markdown_file.dart';

abstract class MarkdownRepository {
  Future<List<MarkdownFile>> getFiles();
  Future<MarkdownFile?> getFileById(int id);
  Future<MarkdownFile?> getFileByUuid(String uuid);
  Future<MarkdownFile> saveFile(MarkdownFile file);
  Future<void> updateFile(MarkdownFile file);
  Future<void> deleteFile(int id);
  Future<List<MarkdownFile>> searchFiles(String query);
  Future<List<MarkdownFile>> getFilesByFolder(int? folderId);
  Future<Map<String, dynamic>> getStatistics();
}
