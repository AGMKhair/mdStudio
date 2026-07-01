import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mdstudio_secure.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final String path;
    if (kIsWeb) {
      path = filePath;
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, filePath);
    }

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE subscriptions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          plan_type TEXT NOT NULL,
          purchase_date TEXT NOT NULL,
          expiry_date TEXT NOT NULL,
          is_active INTEGER DEFAULT 1
        )
      ''');
    }
  }

  Future _onConfigure(Database db) async {
    // Enable foreign keys constraints
    await db.execute('PRAGMA foreign_keys = ON');

    // Dynamically alter existing folders table to prevent runtime schema mismatch
    try {
      final List<Map<String, dynamic>> tableInfo = await db.rawQuery('PRAGMA table_info(folders)');
      final existingColumns = tableInfo.map((c) => c['name'] as String).toSet();

      if (!existingColumns.contains('is_locked')) {
        await db.execute('ALTER TABLE folders ADD COLUMN is_locked INTEGER DEFAULT 0');
      }
      if (!existingColumns.contains('lock_type')) {
        await db.execute('ALTER TABLE folders ADD COLUMN lock_type TEXT');
      }
      if (!existingColumns.contains('password_hash')) {
        await db.execute('ALTER TABLE folders ADD COLUMN password_hash TEXT');
      }
    } catch (_) {}
  }

  Future _createDB(Database db, int version) async {
    // 1. Users Table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        biometric_enabled INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 2. Folders Table
    await db.execute('''
      CREATE TABLE folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        parent_id INTEGER,
        created_at TEXT NOT NULL,
        is_locked INTEGER DEFAULT 0,
        lock_type TEXT,
        password_hash TEXT,
        FOREIGN KEY (parent_id) REFERENCES folders (id) ON DELETE CASCADE
      )
    ''');

    // 3. Markdown Files Table
    await db.execute('''
      CREATE TABLE markdown_files (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT UNIQUE NOT NULL,
        title TEXT NOT NULL,
        file_name TEXT NOT NULL,
        content TEXT NOT NULL,
        folder_id INTEGER,
        is_locked INTEGER DEFAULT 0,
        lock_type TEXT,
        created_by INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_opened_at TEXT NOT NULL,
        FOREIGN KEY (folder_id) REFERENCES folders (id) ON DELETE SET NULL,
        FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE SET NULL
      )
    ''');

    // 4. File History Table
    await db.execute('''
      CREATE TABLE file_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        file_id INTEGER NOT NULL,
        old_content TEXT NOT NULL,
        new_content TEXT NOT NULL,
        action_type TEXT NOT NULL,
        created_by INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (file_id) REFERENCES markdown_files (id) ON DELETE CASCADE,
        FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE SET NULL
      )
    ''');

    // 5. Audit Logs Table
    await db.execute('''
      CREATE TABLE audit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        file_id INTEGER,
        action TEXT NOT NULL,
        description TEXT NOT NULL,
        device_info TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE SET NULL,
        FOREIGN KEY (file_id) REFERENCES markdown_files (id) ON DELETE SET NULL
      )
    ''');

    // 6. File Permissions Table
    await db.execute('''
      CREATE TABLE file_permissions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        file_id INTEGER UNIQUE NOT NULL,
        password_enabled INTEGER DEFAULT 0,
        biometric_enabled INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (file_id) REFERENCES markdown_files (id) ON DELETE CASCADE
      )
    ''');

    // 7. Subscriptions Table
    await db.execute('''
      CREATE TABLE subscriptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_type TEXT NOT NULL,
        purchase_date TEXT NOT NULL,
        expiry_date TEXT NOT NULL,
        is_active INTEGER DEFAULT 1
      )
    ''');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
