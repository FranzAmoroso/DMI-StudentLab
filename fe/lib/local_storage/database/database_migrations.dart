import 'package:sqflite/sqflite.dart';

import 'database_tables.dart';


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
    if (oldVersion < 2) {
      await _migrationToVersion2(
        db,
      );
    }

    if (oldVersion < 3) {
      await _migrationToVersion3(
        db,
      );
    }
  }


  // ===========================================================================
  // VERSIONE 2
  // ===========================================================================
  //
  // Esempio:
  // aggiungiamo una colonna per tracciare eventuali retry upload.
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
  // Esempio:
  // aggiungiamo timestamp dell'ultimo tentativo.
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
  // COLUMN EXISTS
  // ===========================================================================

  static Future<bool> _columnExists(
    Database db,
    String table,
    String column,
  ) async {
    final List<Map<String, dynamic>> result =
        await db.rawQuery(
      '''
      PRAGMA table_info($table)
      ''',
    );

    for (final row in result) {
      final String? name =
          row['name']?.toString();

      if (name == column) {
        return true;
      }
    }

    return false;
  }
}