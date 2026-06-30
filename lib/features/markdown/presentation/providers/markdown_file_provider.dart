import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/repository_impl/sqlite_markdown_repository.dart';
import '../../data/repository_impl/sqlite_folder_repository.dart';
import '../../data/repository_impl/sqlite_audit_log_repository.dart';
import '../../domain/entities/markdown_file.dart';
import '../../domain/entities/folder.dart';
import '../../domain/repositories/markdown_repository.dart';
import '../../domain/repositories/folder_repository.dart';
import '../../domain/repositories/audit_log_repository.dart';

final markdownRepositoryProvider = Provider<MarkdownRepository>((ref) {
  return SQLiteMarkdownRepository();
});

final folderRepositoryProvider = Provider<FolderRepository>((ref) {
  return SQLiteFolderRepository();
});

final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  return SQLiteAuditLogRepository();
});

enum ExplorerFilter { all, folders, locked, unlocked }

class MarkdownFileState {
  final List<MarkdownFile> allFiles; // All files globally loaded (excluding locked folders)
  final List<MarkdownFile> files;    // Filtered by currentFolderId
  final List<Folder> folders;
  final int? currentFolderId;
  final ExplorerFilter filter;
  final Map<String, dynamic> statistics;
  final bool isLoading;

  MarkdownFileState({
    required this.allFiles,
    required this.files,
    required this.folders,
    this.currentFolderId,
    this.filter = ExplorerFilter.all,
    required this.statistics,
    required this.isLoading,
  });

  MarkdownFileState copyWith({
    List<MarkdownFile>? allFiles,
    List<MarkdownFile>? files,
    List<Folder>? folders,
    int? currentFolderId,
    ExplorerFilter? filter,
    bool clearCurrentFolder = false,
    Map<String, dynamic>? statistics,
    bool? isLoading,
  }) {
    return MarkdownFileState(
      allFiles: allFiles ?? this.allFiles,
      files: files ?? this.files,
      folders: folders ?? this.folders,
      currentFolderId: clearCurrentFolder ? null : (currentFolderId ?? this.currentFolderId),
      filter: filter ?? this.filter,
      statistics: statistics ?? this.statistics,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final markdownFileProvider = StateNotifierProvider<MarkdownFileNotifier, MarkdownFileState>((ref) {
  final fileRepo = ref.watch(markdownRepositoryProvider);
  final folderRepo = ref.watch(folderRepositoryProvider);
  final auditRepo = ref.watch(auditLogRepositoryProvider);
  return MarkdownFileNotifier(fileRepo, folderRepo, auditRepo);
});

class MarkdownFileNotifier extends StateNotifier<MarkdownFileState> {
  final MarkdownRepository _fileRepo;
  final FolderRepository _folderRepo;
  final AuditLogRepository _auditRepo;

  MarkdownFileNotifier(this._fileRepo, this._folderRepo, this._auditRepo)
      : super(MarkdownFileState(
          allFiles: [],
          files: [],
          folders: [],
          currentFolderId: null,
          statistics: {
            'totalFiles': 0,
            'lockedFiles': 0,
            'totalEdits': 0,
            'totalWords': 0,
            'lastActivity': 'No recent activity',
          },
          isLoading: true,
        )) {
    loadAll();
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true);
    final allDbFiles = await _fileRepo.getFiles();
    final files = await _fileRepo.getFilesByFolder(state.currentFolderId);
    final folders = await _folderRepo.getFolders();
    final statistics = await _fileRepo.getStatistics();
    
    // Hide files belonging to locked folders from the global overview lists
    final lockedFolderIds = folders.where((f) => f.isLocked).map((f) => f.id).toSet();
    final visibleAllFiles = allDbFiles.where((f) => f.folderId == null || !lockedFolderIds.contains(f.folderId)).toList();

    state = state.copyWith(
      allFiles: visibleAllFiles,
      files: files,
      folders: folders,
      statistics: statistics,
      isLoading: false,
    );
  }

  Future<void> setCurrentFolder(int? folderId) async {
    state = MarkdownFileState(
      allFiles: state.allFiles,
      files: state.files,
      folders: state.folders,
      currentFolderId: folderId,
      statistics: state.statistics,
      isLoading: true,
    );
    final files = await _fileRepo.getFilesByFolder(folderId);
    state = state.copyWith(files: files, isLoading: false);
  }

  Future<MarkdownFile> createFile(String title, String content, {int? folderId}) async {
    final now = DateTime.now();
    final fileName = '${title.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(RegExp(r'\s+'), '_').toLowerCase()}.md';
    
    final newFile = MarkdownFile(
      uuid: const Uuid().v4(),
      title: title,
      fileName: fileName,
      content: content,
      folderId: folderId ?? state.currentFolderId,
      isLocked: false,
      createdAt: now,
      updatedAt: now,
      lastOpenedAt: now,
    );

    final savedFile = await _fileRepo.saveFile(newFile);
    await _auditRepo.logActivity(
      fileId: savedFile.id,
      action: 'Created file',
      description: 'Created markdown file "${savedFile.title}"',
    );

    await loadAll();
    return savedFile;
  }

  Future<void> deleteFile(int id, String title) async {
    await _fileRepo.deleteFile(id);
    await _auditRepo.logActivity(
      action: 'Deleted file',
      description: 'Deleted markdown file "$title"',
    );
    await loadAll();
  }

  Future<void> createFolder(String name) async {
    final folder = Folder(
      name: name,
      parentId: state.currentFolderId,
      createdAt: DateTime.now(),
    );
    await _folderRepo.saveFolder(folder);
    await _auditRepo.logActivity(
      action: 'Created folder',
      description: 'Created folder "$name"',
    );
    await loadAll();
  }

  Future<void> deleteFolder(int id, String name) async {
    await _folderRepo.deleteFolder(id);
    await _auditRepo.logActivity(
      action: 'Deleted folder',
      description: 'Deleted folder "$name" and its contents',
    );
    await loadAll();
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      await loadAll();
      return;
    }
    state = state.copyWith(isLoading: true);
    final searchResults = await _fileRepo.searchFiles(query);
    state = state.copyWith(files: searchResults, isLoading: false);
  }

  Future<void> updateLockStatus(int fileId, bool isLocked, String? lockType) async {
    final file = await _fileRepo.getFileById(fileId);
    if (file != null) {
      final updatedFile = file.copyWith(
        isLocked: isLocked,
        lockType: lockType,
        updatedAt: DateTime.now(),
      );
      await _fileRepo.updateFile(updatedFile);
      await _auditRepo.logActivity(
        fileId: fileId,
        action: isLocked ? 'Locked file' : 'Unlocked file',
        description: isLocked
            ? 'Set $lockType lock on "${file.title}"'
            : 'Removed lock from "${file.title}"',
      );
      await loadAll();
    }
  }

  Future<void> updateFolderLockStatus(int folderId, bool isLocked, String? lockType) async {
    final folder = await _folderRepo.getFolderById(folderId);
    if (folder != null) {
      final updatedFolder = folder.copyWith(
        isLocked: isLocked,
        lockType: lockType,
      );
      await _folderRepo.updateFolder(updatedFolder);
      await _auditRepo.logActivity(
        action: isLocked ? 'Locked folder' : 'Unlocked folder',
        description: isLocked
            ? 'Set $lockType lock on "${folder.name}"'
            : 'Removed lock from "${folder.name}"',
      );
      await loadAll();
    }
  }

  Future<void> logFileOpened(int fileId, String title) async {
    final file = await _fileRepo.getFileById(fileId);
    if (file != null) {
      final updatedFile = file.copyWith(lastOpenedAt: DateTime.now());
      await _fileRepo.updateFile(updatedFile);
      await _auditRepo.logActivity(
        fileId: fileId,
        action: 'Opened file',
        description: 'Opened markdown file "$title"',
      );
    }
  }

  Future<void> renameFile(int fileId, String newTitle) async {
    final file = await _fileRepo.getFileById(fileId);
    if (file != null) {
      final newFileName = '${newTitle.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(RegExp(r'\s+'), '_').toLowerCase()}.md';
      final updatedFile = file.copyWith(
        title: newTitle,
        fileName: newFileName,
        updatedAt: DateTime.now(),
      );
      await _fileRepo.updateFile(updatedFile);
      await _auditRepo.logActivity(
        fileId: fileId,
        action: 'Renamed file',
        description: 'Renamed file from "${file.title}" to "$newTitle"',
      );
      await loadAll();
    }
  }

  Future<void> renameFolder(int folderId, String newName) async {
    final folder = await _folderRepo.getFolderById(folderId);
    if (folder != null) {
      final updatedFolder = folder.copyWith(name: newName);
      await _folderRepo.updateFolder(updatedFolder);
      await _auditRepo.logActivity(
        action: 'Renamed folder',
        description: 'Renamed folder from "${folder.name}" to "$newName"',
      );
      await loadAll();
    }
  }

  void setFilter(ExplorerFilter filter) {
    state = state.copyWith(filter: filter);
  }

  Future<void> moveFile(int fileId, int? targetFolderId) async {
    final file = await _fileRepo.getFileById(fileId);
    if (file != null) {
      final updatedFile = file.copyWith(
        folderId: targetFolderId,
        updatedAt: DateTime.now(),
      );
      await _fileRepo.updateFile(updatedFile);

      String destination = 'root';
      if (targetFolderId != null) {
        final targetFolder = await _folderRepo.getFolderById(targetFolderId);
        destination = targetFolder?.name ?? 'unknown folder';
      }

      await _auditRepo.logActivity(
        fileId: fileId,
        action: 'Moved file',
        description: 'Moved file "${file.title}" to $destination',
      );
      await loadAll();
    }
  }

  Future<void> moveFolder(int folderId, int? targetParentId) async {
    if (folderId == targetParentId) return;

    final folder = await _folderRepo.getFolderById(folderId);
    if (folder != null) {
      final updatedFolder = folder.copyWith(parentId: targetParentId);
      await _folderRepo.updateFolder(updatedFolder);

      String destination = 'root';
      if (targetParentId != null) {
        final targetFolder = await _folderRepo.getFolderById(targetParentId);
        destination = targetFolder?.name ?? 'unknown folder';
      }

      await _auditRepo.logActivity(
        action: 'Moved folder',
        description: 'Moved folder "${folder.name}" to $destination',
      );
      await loadAll();
    }
  }
}
