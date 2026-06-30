import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/markdown_file.dart';
import '../../domain/entities/file_history.dart';
import 'markdown_file_provider.dart';
import 'history_provider.dart';

class EditorState {
  final MarkdownFile? activeFile;
  final String currentContent;
  final bool isSaving;
  final bool isPreviewSplit;
  final List<String> undoStack;
  final List<String> redoStack;

  EditorState({
    this.activeFile,
    required this.currentContent,
    required this.isSaving,
    required this.isPreviewSplit,
    required this.undoStack,
    required this.redoStack,
  });

  EditorState copyWith({
    MarkdownFile? Function()? activeFile,
    String? currentContent,
    bool? isSaving,
    bool? isPreviewSplit,
    List<String>? undoStack,
    List<String>? redoStack,
  }) {
    return EditorState(
      activeFile: activeFile != null ? activeFile() : this.activeFile,
      currentContent: currentContent ?? this.currentContent,
      isSaving: isSaving ?? this.isSaving,
      isPreviewSplit: isPreviewSplit ?? this.isPreviewSplit,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
    );
  }
}

final editorProvider = StateNotifierProvider<EditorNotifier, EditorState>((ref) {
  return EditorNotifier(ref);
});

class EditorNotifier extends StateNotifier<EditorState> {
  final Ref _ref;
  Timer? _autoSaveTimer;

  EditorNotifier(this._ref)
      : super(EditorState(
          activeFile: null,
          currentContent: '',
          isSaving: false,
          isPreviewSplit: true,
          undoStack: [],
          redoStack: [],
        ));

  void openFile(MarkdownFile file) {
    _autoSaveTimer?.cancel();
    state = EditorState(
      activeFile: file,
      currentContent: file.content,
      isSaving: false,
      isPreviewSplit: state.isPreviewSplit,
      undoStack: [file.content],
      redoStack: [],
    );

    // Track last opened file audit log
    _ref.read(markdownFileProvider.notifier).logFileOpened(file.id!, file.title);

    // Start auto save timer (saves every 5 seconds)
    _startAutoSaveTimer();
  }

  void closeFile() {
    _autoSaveTimer?.cancel();
    // Do a final save if there's an active file and unsaved changes
    if (state.activeFile != null) {
      saveCurrentContent();
    }
    state = EditorState(
      activeFile: null,
      currentContent: '',
      isSaving: false,
      isPreviewSplit: state.isPreviewSplit,
      undoStack: [],
      redoStack: [],
    );
  }

  void updateContent(String text) {
    if (text == state.currentContent) return;

    final newUndoStack = List<String>.from(state.undoStack);
    if (newUndoStack.isEmpty || newUndoStack.last != state.currentContent) {
      newUndoStack.add(state.currentContent);
      if (newUndoStack.length > 50) {
        newUndoStack.removeAt(0); // Limit size
      }
    }

    state = state.copyWith(
      currentContent: text,
      undoStack: newUndoStack,
      redoStack: [], // Clear redo stack on new edit
    );
  }

  void undo(TextEditingController controller) {
    if (state.undoStack.isEmpty) return;
    
    final previousContent = state.undoStack.last;
    final newUndoStack = List<String>.from(state.undoStack)..removeLast();
    final newRedoStack = List<String>.from(state.redoStack)..add(state.currentContent);

    state = state.copyWith(
      currentContent: previousContent,
      undoStack: newUndoStack,
      redoStack: newRedoStack,
    );

    controller.value = controller.value.copyWith(
      text: previousContent,
      selection: TextSelection.collapsed(offset: previousContent.length),
    );
  }

  void redo(TextEditingController controller) {
    if (state.redoStack.isEmpty) return;

    final nextContent = state.redoStack.last;
    final newRedoStack = List<String>.from(state.redoStack)..removeLast();
    final newUndoStack = List<String>.from(state.undoStack)..add(state.currentContent);

    state = state.copyWith(
      currentContent: nextContent,
      undoStack: newUndoStack,
      redoStack: newRedoStack,
    );

    controller.value = controller.value.copyWith(
      text: nextContent,
      selection: TextSelection.collapsed(offset: nextContent.length),
    );
  }

  void togglePreviewSplit() {
    state = state.copyWith(isPreviewSplit: !state.isPreviewSplit);
  }

  void _startAutoSaveTimer() {
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (state.activeFile != null && state.currentContent != state.activeFile!.content) {
        saveCurrentContent();
      }
    });
  }

  Future<void> saveCurrentContent() async {
    final file = state.activeFile;
    if (file == null) return;

    final contentToSave = state.currentContent;
    if (contentToSave == file.content) return; // Nothing to save

    state = state.copyWith(isSaving: true);

    try {
      final fileRepo = _ref.read(markdownRepositoryProvider);
      final historyRepo = _ref.read(historyRepositoryProvider);
      final auditRepo = _ref.read(auditLogRepositoryProvider);

      // 1. Fetch current file state in DB to determine if content actually changed
      final latestDbFile = await fileRepo.getFileById(file.id!);
      
      if (latestDbFile != null && latestDbFile.content != contentToSave) {
        // 2. Create history record
        final history = FileHistory(
          fileId: file.id!,
          oldContent: latestDbFile.content,
          newContent: contentToSave,
          actionType: 'Updated File Content',
          createdAt: DateTime.now(),
        );
        await historyRepo.saveHistory(history);

        // 3. Log edit audit activity
        await auditRepo.logActivity(
          fileId: file.id!,
          action: 'Updated file',
          description: 'Saved changes to "${file.title}" (${contentToSave.length} chars)',
        );
      }

      // 4. Update file in sqlite
      final updatedFile = file.copyWith(
        content: contentToSave,
        updatedAt: DateTime.now(),
      );
      await fileRepo.updateFile(updatedFile);

      // Update state and refresh list provider
      state = state.copyWith(
        activeFile: () => updatedFile,
        isSaving: false,
      );
      
      _ref.read(markdownFileProvider.notifier).loadAll();
      _ref.read(historyProvider(file.id!).notifier).loadHistory();

    } catch (_) {
      state = state.copyWith(isSaving: false);
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}
