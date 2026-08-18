import 'package:sqflite/sqflite.dart';

import 'database_tables.dart';


class DatabaseMigrations {
  DatabaseMigrations._();


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

    if (oldVersion < 4) {
      await _migrationToVersion4(
        db,
      );
    }

    if (oldVersion < 5) {
      await _migrationToVersion5(
        db,
      );
    }
  }


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


  static Future<void> _migrationToVersion4(
    Database db,
  ) async {
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


  static Future<void> _migrationToVersion5(
    Database db,
  ) async {
    final bool hasUniversity =
        await _columnExists(
      db,
      DatabaseTables.downloadedMaterials,
      'university',
    );

    if (!hasUniversity) {
      await db.execute(
        '''
        ALTER TABLE ${DatabaseTables.downloadedMaterials}
        ADD COLUMN university TEXT
        ''',
      );
    }

    await db.execute(
      '''
      CREATE INDEX IF NOT EXISTS
      idx_downloaded_materials_user_university
      ON ${DatabaseTables.downloadedMaterials}
      (
        user_id,
        university
      )
      ''',
    );

    await db.execute(
      '''
      CREATE INDEX IF NOT EXISTS
      idx_downloaded_materials_hierarchy
      ON ${DatabaseTables.downloadedMaterials}
      (
        user_id,
        university,
        department,
        course,
        subject_id
      )
      ''',
    );
  }


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

    for (
      final Map<String, dynamic> row
      in result
    ) {
      final String? name =
          row['name']
              ?.toString();

      if (name == column) {
        return true;
      }
    }

    return false;
  }
}