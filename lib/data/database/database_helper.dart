import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../../core/constants/app_constants.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();
  static bool _factoryInitialized = false;
  Database? _database;

  static Future<void> initializeFactory() async {
    if (_factoryInitialized) {
      return;
    }

    if (kIsWeb) {
      // Running without web worker avoids startup failures when worker loading is restricted.
      databaseFactory = databaseFactoryFfiWebNoWebWorker;
    } else {
      switch (defaultTargetPlatform) {
        case TargetPlatform.windows:
        case TargetPlatform.linux:
          sqfliteFfiInit();
          databaseFactory = databaseFactoryFfi;
        case TargetPlatform.android:
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
        case TargetPlatform.fuchsia:
          break;
      }
    }

    _factoryInitialized = true;
  }

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    await initializeFactory();
    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final databasesPath = await getDatabasesPath();
    final databasePath = path.join(databasesPath, AppConstants.databaseName);

    return openDatabase(
      databasePath,
      version: AppConstants.databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        // Tables are created in dependency order because SQLite validates foreign keys.
        await db.execute('''
          CREATE TABLE ${AppConstants.usersTable}(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            salt TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE ${AppConstants.taskGroupsTable}(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            description TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY(user_id) REFERENCES ${AppConstants.usersTable}(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE ${AppConstants.tasksTable}(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            group_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            is_completed INTEGER NOT NULL DEFAULT 0,
            position INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY(group_id) REFERENCES ${AppConstants.taskGroupsTable}(id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }
}
