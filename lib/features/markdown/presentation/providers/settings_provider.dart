import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/database_helper.dart';
import 'markdown_file_provider.dart';
import 'package:file_saver/file_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
        final bytes = await file.readAsBytes();
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final fileName = 'mdstudio_backup_$timestamp';

        final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

        if (isMobile) {
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/$fileName.db');
          await tempFile.writeAsBytes(bytes);

          final savedPath = await FileSaver.instance.saveAs(
            name: fileName,
            filePath: tempFile.path,
            fileExtension: 'db',
            mimeType: MimeType.other,
          );
          state = false;
          return savedPath != null && savedPath.isNotEmpty;
        } else {
          final outputFile = await FilePicker.platform.saveFile(
            dialogTitle: 'Select where to save the database backup:',
            fileName: '$fileName.db',
          );

          if (outputFile != null) {
            final savedFile = File(outputFile);
            await savedFile.writeAsBytes(bytes);
            state = false;
            return true;
          }
        }
      }
      state = false;
      return false;
    } catch (_) {
      state = false;
      return false;
    }
  }

  Future<String?> restoreDatabase() async {
    if (kIsWeb) return 'error';
    state = true;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db', 'sqlite', 'sqlite3'],
      );

      if (result != null && result.files.single.path != null) {
        final selectedPath = result.files.single.path!;

        // 1. Extension check: must end with .db, .sqlite, .sqlite3, etc.
        final lowerPath = selectedPath.toLowerCase();
        if (!lowerPath.endsWith('.db') && !lowerPath.endsWith('.sqlite') && !lowerPath.endsWith('.sqlite3')) {
          state = false;
          return 'invalid_format';
        }

        // 2. Database validation check: open database in read-only and verify tables
        Database? testDb;
        try {
          testDb = await openDatabase(selectedPath, readOnly: true);
          final tables = await testDb.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table'"
          );
          final tableNames = tables.map((row) => row['name'] as String).toList();
          await testDb.close();

          final requiredTables = [
            'users',
            'folders',
            'markdown_files',
            'file_history',
            'audit_logs',
            'file_permissions',
            'subscriptions'
          ];
          final hasAllRequired = requiredTables.every((t) => tableNames.contains(t));
          if (!hasAllRequired) {
            state = false;
            return 'invalid_format';
          }
        } catch (_) {
          try {
            await testDb?.close();
          } catch (_) {}
          state = false;
          return 'invalid_format';
        }

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
        return 'success';
      }
      state = false;
      return null;
    } catch (_) {
      state = false;
      return 'error';
    }
  }

  Future<String?> backupDatabaseToCloud(String userId) async {
    if (kIsWeb) return 'error';
    state = true;
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'mdstudio_secure.db');
      final file = File(path);

      if (await file.exists()) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('backups')
            .child(userId)
            .child('mdstudio_backup.db');
        
        await storageRef.putFile(file);
        state = false;
        return 'success';
      }
      state = false;
      return 'not_found';
    } catch (_) {
      state = false;
      return 'error';
    }
  }

  Future<String?> restoreDatabaseFromCloud(String userId) async {
    if (kIsWeb) return 'error';
    state = true;
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('backups')
          .child(userId)
          .child('mdstudio_backup.db');

      final dbPath = await getDatabasesPath();
      final tempPath = join(dbPath, 'mdstudio_secure_temp.db');
      final tempFile = File(tempPath);

      // Download backup from Firebase Storage to a temporary file
      await storageRef.writeToFile(tempFile);

      // Database validation check: open database in read-only and verify tables
      Database? testDb;
      try {
        testDb = await openDatabase(tempPath, readOnly: true);
        final tables = await testDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table'"
        );
        final tableNames = tables.map((row) => row['name'] as String).toList();
        await testDb.close();

        final requiredTables = [
          'users',
          'folders',
          'markdown_files',
          'file_history',
          'audit_logs',
          'file_permissions',
          'subscriptions'
        ];
        final hasAllRequired = requiredTables.every((t) => tableNames.contains(t));
        if (!hasAllRequired) {
          if (await tempFile.exists()) await tempFile.delete();
          state = false;
          return 'invalid_format';
        }
      } catch (_) {
        try {
          await testDb?.close();
        } catch (_) {}
        if (await tempFile.exists()) await tempFile.delete();
        state = false;
        return 'invalid_format';
      }

      final destinationPath = join(dbPath, 'mdstudio_secure.db');

      // Close current database helper
      await DatabaseHelper.instance.close();

      // Overwrite existing database
      await tempFile.copy(destinationPath);
      if (await tempFile.exists()) await tempFile.delete();

      // Force reload database helper connection and trigger main state rebuild
      await DatabaseHelper.instance.database;
      _ref.read(markdownFileProvider.notifier).loadAll();

      state = false;
      return 'success';
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        state = false;
        return 'no_backup';
      }
      state = false;
      return 'error';
    } catch (_) {
      state = false;
      return 'error';
    }
  }
}
