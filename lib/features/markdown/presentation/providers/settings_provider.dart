import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/database/database_helper.dart';
import 'markdown_file_provider.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, bool>((ref) {
  return SettingsNotifier(ref);
});

class SettingsNotifier extends StateNotifier<bool> {
  final Ref _ref;

  SettingsNotifier(this._ref) : super(false);

  Future<bool> backupDatabase() async {
    if (kIsWeb) return false;
    state = true;
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'mdstudio_secure.db');
      final file = File(path);

      if (await file.exists()) {
        // Use share_plus to export db file to user destination
        final xFile = XFile(file.path, mimeType: 'application/x-sqlite3');
        await Share.shareXFiles([xFile], subject: 'mdStudio Secure Database Backup');
        state = false;
        return true;
      }
      state = false;
      return false;
    } catch (_) {
      state = false;
      return false;
    }
  }

  Future<bool> restoreDatabase() async {
    if (kIsWeb) return false;
    state = true;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        final selectedPath = result.files.single.path!;
        final dbPath = await getDatabasesPath();
        final destinationPath = join(dbPath, 'mdstudio_secure.db');

        // Close current database helper
        await DatabaseHelper.instance.close();

        // Overwrite existing database
        final backupFile = File(selectedPath);
        await backupFile.copy(destinationPath);

        // Force reload database helper connection and trigger main state rebuild
        await DatabaseHelper.instance.database;
        _ref.read(markdownFileProvider.notifier).loadAll();

        state = false;
        return true;
      }
      state = false;
      return false;
    } catch (_) {
      state = false;
      return false;
    }
  }
}
