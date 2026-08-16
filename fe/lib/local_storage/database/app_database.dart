import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'database_migrations.dart';
import 'database_tables.dart';


// =============================================================================
// APP DATABASE
// =============================================================================

class AppDatabase {
  AppDatabase._();


  // ===========================================================================
  // SINGLETON
  // ===========================================================================

  static final AppDatabase instance =
      AppDatabase._();


  static Database? _database;


  // ===========================================================================
  // VERSION
  // ===========================================================================

  static const int _databaseVersion =
      4;


  // ===========================================================================
  // DATABASE
  // ===========================================================================

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }


    _database =
        await _initDatabase();


    return _database!;
  }


  // ===========================================================================
  // INIT
  // ===========================================================================

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

    // =========================================================================
    // DOWNLOADED MATERIALS
    // =========================================================================
    //
    // Registra le copie locali dei materiali.
    //
    // user_id:
    //
    // - ID reale per utente autenticato
    // - 0 per Guest
    //
    // subject_id / subject_name / course / department:
    //
    // permettono di costruire automaticamente
    // la libreria Materiale raggruppata per materia.
    //
    // =========================================================================

    await db.execute(
      '''
      CREATE TABLE ${DatabaseTables.downloadedMaterials} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        user_id INTEGER NOT NULL,

        material_id INTEGER NOT NULL,

        group_id INTEGER NOT NULL,

        subject_id INTEGER,

        subject_name TEXT,

        course TEXT,

        department TEXT,

        original_name TEXT NOT NULL,

        local_path TEXT NOT NULL,

        mime_type TEXT,

        size INTEGER,

        downloaded_at TEXT NOT NULL,

        UNIQUE(
          user_id,
          material_id
        )
      )
      ''',
    );


    // =========================================================================
    // PENDING UPLOADS
    // =========================================================================

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


    // =========================================================================
    // MATERIAL CACHE
    // =========================================================================

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


    // =========================================================================
    // INDEX - DOWNLOADED MATERIALS USER
    // =========================================================================

    await db.execute(
      '''
      CREATE INDEX idx_downloaded_materials_user
      ON ${DatabaseTables.downloadedMaterials}(
        user_id
      )
      ''',
    );


    // =========================================================================
    // INDEX - DOWNLOADED MATERIALS GROUP
    // =========================================================================

    await db.execute(
      '''
      CREATE INDEX idx_downloaded_materials_group
      ON ${DatabaseTables.downloadedMaterials}(
        group_id
      )
      ''',
    );


    // =========================================================================
    // INDEX - DOWNLOADED MATERIALS SUBJECT
    // =========================================================================
    //
    // StudentMaterialPage utilizzerà spesso:
    //
    // WHERE user_id = ?
    // AND subject_id = ?
    //
    // =========================================================================

    await db.execute(
      '''
      CREATE INDEX idx_downloaded_materials_user_subject
      ON ${DatabaseTables.downloadedMaterials}(
        user_id,
        subject_id
      )
      ''',
    );


    // =========================================================================
    // INDEX - PENDING UPLOADS USER STATUS
    // =========================================================================

    await db.execute(
      '''
      CREATE INDEX idx_pending_uploads_user_status
      ON ${DatabaseTables.pendingUploads}(
        user_id,
        status
      )
      ''',
    );


    // =========================================================================
    // INDEX - PENDING UPLOADS GROUP
    // =========================================================================

    await db.execute(
      '''
      CREATE INDEX idx_pending_uploads_group
      ON ${DatabaseTables.pendingUploads}(
        group_id
      )
      ''',
    );


    // =========================================================================
    // INDEX - MATERIAL CACHE
    // =========================================================================

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


  // ===========================================================================
  // CLOSE
  // ===========================================================================

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