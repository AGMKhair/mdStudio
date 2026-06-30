import '../entities/file_history.dart';

abstract class HistoryRepository {
  Future<List<FileHistory>> getHistoryForFile(int fileId);
  Future<FileHistory> saveHistory(FileHistory history);
  Future<void> deleteHistoryForFile(int fileId);
}
