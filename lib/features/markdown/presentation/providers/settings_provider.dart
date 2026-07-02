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
      debugPrint('Starting restoreDatabase process...');
      
      FilePickerResult? result;
      try {
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          withData: true, 
          allowMultiple: false,
        );
      } catch (e) {
        debugPrint('FilePicker.pickFiles exception: $e');
        state = false;
        return 'error';
      }

      if (result == null || result.files.isEmpty) {
        debugPrint('File picker cancelled or no file selected.');
        state = false;
        return null;
      }

      final platformFile = result.files.first;
      final bytes = platformFile.bytes;
      final selectedPath = platformFile.path;
      
      debugPrint('File selected: ${platformFile.name}, Path: $selectedPath, Bytes available: ${bytes != null}');

      if (bytes == null && selectedPath == null) {
        debugPrint('Error: Both path and bytes are null.');
        state = false;
        return 'error';
      }

      final tempDir = await getTemporaryDirectory();
      final tempPath = join(tempDir.path, 'restore_check_${DateTime.now().millisecondsSinceEpoch}.db');
      final tempFile = File(tempPath);

      try {
        if (bytes != null) {
          await tempFile.writeAsBytes(bytes, flush: true);
        } else if (selectedPath != null) {
          final originalFile = File(selectedPath);
          if (await originalFile.exists()) {
            await originalFile.copy(tempPath);
          } else {
            debugPrint('Error: selectedPath provided but file does not exist at that path.');
            state = false;
            return 'error';
          }
        }
      } catch (e) {
        debugPrint('Error writing to temp file: $e');
        state = false;
        return 'error';
      }

      Database? testDb;
      try {
        testDb = await openDatabase(tempPath, readOnly: true);
        final tables = await testDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table'"
        );
        final tableNames = tables.map((row) => row['name'] as String).toList();
        await testDb.close();

        debugPrint('Validation: Found tables: $tableNames');

        final requiredTables = ['markdown_files', 'audit_logs'];
        final hasMinimumTables = requiredTables.every((t) => tableNames.contains(t));
        
        if (!hasMinimumTables) {
          debugPrint('Restore failed: Minimum required tables not found in the selected file.');
          if (await tempFile.exists()) await tempFile.delete();
          state = false;
          return 'invalid_format';
        }
      } catch (e) {
        debugPrint('Database validation failed (probably not a valid SQLite file): $e');
        try {
          await testDb?.close();
        } catch (_) {}
        if (await tempFile.exists()) await tempFile.delete();
        state = false;
        return 'invalid_format';
      }

      final dbPath = await getDatabasesPath();
      final destinationPath = join(dbPath, 'mdstudio_secure.db');

      try {
        debugPrint('Closing existing database connection...');
        await DatabaseHelper.instance.close();

        debugPrint('Replacing database file at $destinationPath');
        final destFile = File(destinationPath);
        
        if (await destFile.exists()) {
          await destFile.delete();
        }
        
        await tempFile.copy(destinationPath);
        
        if (await tempFile.exists()) await tempFile.delete();

        debugPrint('Re-opening database connection...');
        await DatabaseHelper.instance.database;
        
        _ref.read(markdownFileProvider.notifier).loadAll();

        debugPrint('Restore successful!');
        state = false;
        return 'success';
      } catch (e) {
        debugPrint('Error during file replacement or database re-init: $e');
        state = false;
        return 'error';
      }
    } catch (e) {
      debugPrint('Restore process failed with an unexpected exception: $e');
      state = false;
      return 'error';
    }
  }

  Future<String?> backupDatabaseToCloud(String userId) async {
    if (kIsWeb) return 'error';
    if (userId.isEmpty) {
      debugPrint('Cloud Backup: Error - userId is empty.');
      return 'error';
    }
    
    state = true;
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'mdstudio_secure.db');
      final file = File(path);

      if (await file.exists()) {
        debugPrint('Cloud Backup: Starting upload for user $userId');
        final bytes = await file.readAsBytes();

        final storage = FirebaseStorage.instance;
        debugPrint('Cloud Backup: Using bucket: ${storage.bucket}');

        final storageRef = storage
            .ref()
            .child('backups')
            .child(userId)
            .child('mdstudio_backup.db');
        
        debugPrint('Cloud Backup: Uploading to path: ${storageRef.fullPath}');
        
        final uploadTask = storageRef.putData(
          bytes,
          SettableMetadata(
            contentType: 'application/x-sqlite3',
            customMetadata: {'userId': userId, 'timestamp': DateTime.now().toIso8601String()},
          ),
        );

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          debugPrint('Cloud Backup: Progress: ${snapshot.bytesTransferred}/${snapshot.totalBytes}');
        }, onError: (e) {
          debugPrint('Cloud Backup: Upload Task Error: $e');
        });

        await uploadTask;
        
        debugPrint('Cloud Backup: Upload successful.');
        state = false;
        return 'success';
      }
      debugPrint('Cloud Backup: Local database file not found at $path');
      state = false;
      return 'not_found';
    } catch (e) {
      debugPrint('Cloud Backup error: $e');
      if (e.toString().contains('object-not-found') || e.toString().contains('not-found')) {
        debugPrint('Cloud Backup: Bucket not found or not initialized in Firebase Console.');
        state = false;
        return 'bucket_not_found';
      }
      state = false;
      return 'error';
    }
  }

  Future<String?> restoreDatabaseFromCloud(String userId) async {
    if (kIsWeb) return 'error';
    state = true;
    try {
      debugPrint('Starting Cloud Restore process for user: $userId');
      
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('backups')
          .child(userId)
          .child('mdstudio_backup.db');

      debugPrint('Cloud Restore: Checking for file at ${storageRef.fullPath}');

      final tempDir = await getTemporaryDirectory();
      final tempPath = join(tempDir.path, 'cloud_restore_temp_${DateTime.now().millisecondsSinceEpoch}.db');
      final tempFile = File(tempPath);

      debugPrint('Cloud Restore: Downloading backup file from cloud...');
      try {
        await storageRef.writeToFile(tempFile);
      } on FirebaseException catch (e) {
        debugPrint('Firebase download error: ${e.code} - ${e.message}');
        if (e.code == 'object-not-found' || e.code == 'not-found') {
          state = false;
          return 'no_backup';
        }
        rethrow;
      }

      Database? testDb;
      try {
        debugPrint('Cloud Restore: Validating cloud backup database...');
        testDb = await openDatabase(tempPath, readOnly: true);
        final tables = await testDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table'"
        );
        final tableNames = tables.map((row) => row['name'] as String).toList();
        await testDb.close();

        debugPrint('Cloud Restore: Validation: Found tables: $tableNames');

        final requiredTables = ['markdown_files', 'audit_logs'];
        final hasMinimumTables = requiredTables.every((t) => tableNames.contains(t));
        
        if (!hasMinimumTables) {
          debugPrint('Cloud Restore: Validation failed: Required tables missing.');
          if (await tempFile.exists()) await tempFile.delete();
          state = false;
          return 'invalid_format';
        }
      } catch (e) {
        debugPrint('Cloud Restore: database validation error: $e');
        try {
          await testDb?.close();
        } catch (_) {}
        if (await tempFile.exists()) await tempFile.delete();
        state = false;
        return 'invalid_format';
      }

      final dbPath = await getDatabasesPath();
      final destinationPath = join(dbPath, 'mdstudio_secure.db');

      debugPrint('Cloud Restore: Closing local database connection...');
      await DatabaseHelper.instance.close();

      debugPrint('Cloud Restore: Replacing local database with cloud backup...');
      final destFile = File(destinationPath);
      if (await destFile.exists()) {
        await destFile.delete();
      }
      
      final bytes = await tempFile.readAsBytes();
      await destFile.writeAsBytes(bytes, flush: true);
      
      if (await tempFile.exists()) await tempFile.delete();

      debugPrint('Cloud Restore: Re-opening database...');
      await DatabaseHelper.instance.database;
      _ref.read(markdownFileProvider.notifier).loadAll();

      debugPrint('Cloud Restore: Cloud restore successful!');
      state = false;
      return 'success';
    } catch (e) {
      debugPrint('Cloud Restore: process failed with exception: $e');
      state = false;
      return 'error';
    }
  }
}
