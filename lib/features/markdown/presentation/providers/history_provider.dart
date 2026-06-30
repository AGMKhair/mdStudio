import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repository_impl/sqlite_history_repository.dart';
import '../../domain/entities/file_history.dart';
import '../../domain/repositories/history_repository.dart';
import '../../domain/repositories/audit_log_repository.dart';
import 'markdown_file_provider.dart';
import 'editor_provider.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return SQLiteHistoryRepository();
});

final historyProvider = StateNotifierProvider.family<HistoryNotifier, List<FileHistory>, int>((ref, fileId) {
  final historyRepo = ref.watch(historyRepositoryProvider);
  final auditRepo = ref.watch(auditLogRepositoryProvider);
  return HistoryNotifier(historyRepo, auditRepo, fileId, ref);
});

class HistoryNotifier extends StateNotifier<List<FileHistory>> {
  final HistoryRepository _historyRepo;
  final AuditLogRepository _auditRepo;
  final int _fileId;
  final Ref _ref;

  HistoryNotifier(this._historyRepo, this._auditRepo, this._fileId, this._ref) : super([]) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    final list = await _historyRepo.getHistoryForFile(_fileId);
    state = list;
  }

  Future<bool> restoreVersion(FileHistory history) async {
    try {
      final fileRepo = _ref.read(markdownRepositoryProvider);
      final currentFile = await fileRepo.getFileById(_fileId);
      if (currentFile == null) return false;

      // 1. Log previous content into history stack as a restore snapshot
      final newHistory = FileHistory(
        fileId: _fileId,
        oldContent: currentFile.content,
        newContent: history.oldContent,
        actionType: 'Restored Version',
        createdAt: DateTime.now(),
      );
      await _historyRepo.saveHistory(newHistory);

      // 2. Update current file content in database
      final updatedFile = currentFile.copyWith(
        content: history.oldContent,
        updatedAt: DateTime.now(),
      );
      await fileRepo.updateFile(updatedFile);

      // 3. Log audit action
      await _auditRepo.logActivity(
        fileId: _fileId,
        action: 'Restored file',
        description: 'Restored "${currentFile.title}" to version saved on ${history.createdAt}',
      );

      // 4. Update state across app
      _ref.read(markdownFileProvider.notifier).loadAll();
      _ref.read(editorProvider.notifier).openFile(updatedFile);
      await loadHistory();

      return true;
    } catch (_) {
      return false;
    }
  }
}
