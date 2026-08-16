import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'database_migrations.dart';
import 'database_tables.dart';


class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance =
      AppDatabase._();

  static Database? _database;

  static const int _databaseVersion =
      3;


  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database =
        await _initDatabase();

    return _database!;
  }


  Future<Database> _initDatabase() async {
    final String databasePath =
        await getDatabasesPath();

    final String path =
        join(
      databasePath,
      'studentlab.db',
    );

    return openDatabase(
      path,

      version:
          _databaseVersion,

      onCreate:
          _onCreate,

      onUpgrade:
          DatabaseMigrations.onUpgrade,

      onConfigure:
          _onConfigure,
    );
  }


  // ===========================================================================
  // CONFIGURE
  // ===========================================================================

  Future<void> _onConfigure(
    Database db,
  ) async {
    await db.execute(
      'PRAGMA foreign_keys = ON',
    );
  }


  // ===========================================================================
  // CREATE
  // ===========================================================================

  Future<void> _onCreate(
    Database db,
    int version,
  ) async {

    // -------------------------------------------------------------------------
    // DOWNLOADED MATERIALS
    // -------------------------------------------------------------------------

    await db.execute(
      '''
      CREATE TABLE ${DatabaseTables.downloadedMaterials} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        user_id INTEGER NOT NULL,
        material_id INTEGER NOT NULL,
        group_id INTEGER NOT NULL,

        original_name TEXT NOT NULL,
        local_path TEXT NOT NULL,

        mime_type TEXT,
        size INTEGER,

        downloaded_at TEXT NOT NULL,

        UNIQUE(user_id, material_id)
      )
      ''',
    );


    // -------------------------------------------------------------------------
    // PENDING UPLOADS
    // -------------------------------------------------------------------------

    await db.execute(
      '''
      CREATE TABLE ${DatabaseTables.pendingUploads} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        user_id INTEGER NOT NULL,
        group_id INTEGER NOT NULL,

        local_path TEXT NOT NULL,
        original_name TEXT NOT NULL,

        mime_type TEXT,
        size INTEGER,

        status TEXT NOT NULL DEFAULT 'pending',

        created_at TEXT NOT NULL,
        uploaded_at TEXT,

        server_material_id INTEGER,
        error_message TEXT,

        retry_count INTEGER NOT NULL DEFAULT 0,
        last_attempt_at TEXT
      )
      ''',
    );


    // -------------------------------------------------------------------------
    // MATERIAL CACHE
    // -------------------------------------------------------------------------

    await db.execute(
      '''
      CREATE TABLE ${DatabaseTables.materialCache} (
        material_id INTEGER NOT NULL,

        user_id INTEGER NOT NULL,
        group_id INTEGER NOT NULL,

        uploaded_by INTEGER,

        original_name TEXT NOT NULL,

        mime_type TEXT,
        size INTEGER,

        created_at TEXT,
        synced_at TEXT NOT NULL,

        PRIMARY KEY(
          user_id,
          material_id
        )
      )
      ''',
    );


    // -------------------------------------------------------------------------
    // INDEX
    // -------------------------------------------------------------------------

    await db.execute(
      '''
      CREATE INDEX idx_downloaded_materials_user
      ON ${DatabaseTables.downloadedMaterials}(
        user_id
      )
      ''',
    );

    await db.execute(
      '''
      CREATE INDEX idx_downloaded_materials_group
      ON ${DatabaseTables.downloadedMaterials}(
        group_id
      )
      ''',
    );

    await db.execute(
      '''
      CREATE INDEX idx_pending_uploads_user_status
      ON ${DatabaseTables.pendingUploads}(
        user_id,
        status
      )
      ''',
    );

    await db.execute(
      '''
      CREATE INDEX idx_pending_uploads_group
      ON ${DatabaseTables.pendingUploads}(
        group_id
      )
      ''',
    );

    await db.execute(
      '''
      CREATE INDEX idx_material_cache_user_group
      ON ${DatabaseTables.materialCache}(
        user_id,
        group_id
      )
      ''',
    );
  }



  Future<void> close() async {
    final Database? db =
        _database;

    if (db == null) {
      return;
    }

    await db.close();

    _database =
        null;
  }
}