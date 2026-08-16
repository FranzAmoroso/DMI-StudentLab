import 'package:sqflite/sqflite.dart';

import 'database_tables.dart';


// =============================================================================
// DATABASE MIGRATIONS
// =============================================================================

class DatabaseMigrations {
  DatabaseMigrations._();


  // ===========================================================================
  // UPGRADE
  // ===========================================================================

  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {

    // =========================================================================
    // VERSION 2
    // =========================================================================

    if (oldVersion <
        2) {
      await _migrationToVersion2(
        db,
      );
    }


    // =========================================================================
    // VERSION 3
    // =========================================================================

    if (oldVersion <
        3) {
      await _migrationToVersion3(
        db,
      );
    }


    // =========================================================================
    // VERSION 4
    // =========================================================================

    if (oldVersion <
        4) {
      await _migrationToVersion4(
        db,
      );
    }
  }


  // ===========================================================================
  // VERSIONE 2
  // ===========================================================================
  //
  // Retry upload.
  //
  // ===========================================================================

  static Future<void> _migrationToVersion2(
    Database db,
  ) async {
    final bool exists =
        await _columnExists(
      db,

      DatabaseTables.pendingUploads,

      'retry_count',
    );


    if (!exists) {
      await db.execute(
        '''
        ALTER TABLE ${DatabaseTables.pendingUploads}
        ADD COLUMN retry_count INTEGER NOT NULL DEFAULT 0
        ''',
      );
    }
  }


  // ===========================================================================
  // VERSIONE 3
  // ===========================================================================
  //
  // Timestamp ultimo tentativo upload.
  //
  // ===========================================================================

  static Future<void> _migrationToVersion3(
    Database db,
  ) async {
    final bool exists =
        await _columnExists(
      db,

      DatabaseTables.pendingUploads,

      'last_attempt_at',
    );


    if (!exists) {
      await db.execute(
        '''
        ALTER TABLE ${DatabaseTables.pendingUploads}
        ADD COLUMN last_attempt_at TEXT
        ''',
      );
    }
  }


  // ===========================================================================
  // VERSIONE 4
  // ===========================================================================
  //
  // Aggiunge informazioni accademiche ai materiali scaricati.
  //
  // Questi dati servono alla UI per raggruppare automaticamente
  // i download per materia.
  //
  // downloaded_materials
  //
  // + subject_id
  // + subject_name
  // + course
  // + department
  //
  // Tutti i campi sono nullable per mantenere compatibilità
  // con eventuali download creati con le versioni precedenti.
  //
  // ===========================================================================

  static Future<void> _migrationToVersion4(
    Database db,
  ) async {

    // -------------------------------------------------------------------------
    // SUBJECT ID
    // -------------------------------------------------------------------------

    final bool hasSubjectId =
        await _columnExists(
      db,

      DatabaseTables.downloadedMaterials,

      'subject_id',
    );


    if (!hasSubjectId) {
      await db.execute(
        '''
        ALTER TABLE ${DatabaseTables.downloadedMaterials}
        ADD COLUMN subject_id INTEGER
        ''',
      );
    }


    // -------------------------------------------------------------------------
    // SUBJECT NAME
    // -------------------------------------------------------------------------

    final bool hasSubjectName =
        await _columnExists(
      db,

      DatabaseTables.downloadedMaterials,

      'subject_name',
    );


    if (!hasSubjectName) {
      await db.execute(
        '''
        ALTER TABLE ${DatabaseTables.downloadedMaterials}
        ADD COLUMN subject_name TEXT
        ''',
      );
    }


    // -------------------------------------------------------------------------
    // COURSE
    // -------------------------------------------------------------------------

    final bool hasCourse =
        await _columnExists(
      db,

      DatabaseTables.downloadedMaterials,

      'course',
    );


    if (!hasCourse) {
      await db.execute(
        '''
        ALTER TABLE ${DatabaseTables.downloadedMaterials}
        ADD COLUMN course TEXT
        ''',
      );
    }


    // -------------------------------------------------------------------------
    // DEPARTMENT
    // -------------------------------------------------------------------------

    final bool hasDepartment =
        await _columnExists(
      db,

      DatabaseTables.downloadedMaterials,

      'department',
    );


    if (!hasDepartment) {
      await db.execute(
        '''
        ALTER TABLE ${DatabaseTables.downloadedMaterials}
        ADD COLUMN department TEXT
        ''',
      );
    }


    // -------------------------------------------------------------------------
    // INDEX SUBJECT
    // -------------------------------------------------------------------------
    //
    // StudentMaterialPage farà spesso:
    //
    // WHERE user_id = ? AND subject_id = ?
    //
    // quindi aggiungiamo un indice.
    // -------------------------------------------------------------------------

    await db.execute(
      '''
      CREATE INDEX IF NOT EXISTS
      idx_downloaded_materials_user_subject
      ON ${DatabaseTables.downloadedMaterials}
      (
        user_id,
        subject_id
      )
      ''',
    );
  }


  // ===========================================================================
  // COLUMN EXISTS
  // ===========================================================================

  static Future<bool> _columnExists(
    Database db,
    String table,
    String column,
  ) async {
    final List<Map<String, dynamic>>
        result =
        await db.rawQuery(
      '''
      PRAGMA table_info($table)
      ''',
    );


    for (final Map<String, dynamic>
        row in result) {
      final String? name =
          row['name']
              ?.toString();


      if (name ==
          column) {
        return true;
      }
    }


    return false;
  }
}