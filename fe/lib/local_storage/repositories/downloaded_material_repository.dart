import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../database/database_tables.dart';

import '../models/downloaded_material_local.dart';


// =============================================================================
// DOWNLOADED MATERIAL REPOSITORY
// =============================================================================

class DownloadedMaterialRepository {
  final AppDatabase _database =
      AppDatabase.instance;


  // ===========================================================================
  // SAVE
  // ===========================================================================

  Future<void> save(
    DownloadedMaterialLocal material,
  ) async {
    final Database db =
        await _database.database;


    await db.insert(
      DatabaseTables.downloadedMaterials,

      material.toMap(),

      conflictAlgorithm:
          ConflictAlgorithm.replace,
    );
  }


  // ===========================================================================
  // IS DOWNLOADED
  // ===========================================================================

  Future<bool> isDownloaded({
    required int userId,
    required int materialId,
  }) async {
    final Database db =
        await _database.database;


    final List<Map<String, dynamic>>
        result =
        await db.query(
      DatabaseTables.downloadedMaterials,

      columns: [
        'id',
      ],

      where:
          'user_id = ? '
          'AND material_id = ?',

      whereArgs: [
        userId,
        materialId,
      ],

      limit:
          1,
    );


    return result.isNotEmpty;
  }


  // ===========================================================================
  // GET MATERIAL
  // ===========================================================================

  Future<DownloadedMaterialLocal?>
      getMaterial({
    required int userId,
    required int materialId,
  }) async {
    final Database db =
        await _database.database;


    final List<Map<String, dynamic>>
        result =
        await db.query(
      DatabaseTables.downloadedMaterials,

      where:
          'user_id = ? '
          'AND material_id = ?',

      whereArgs: [
        userId,
        materialId,
      ],

      limit:
          1,
    );


    if (result.isEmpty) {
      return null;
    }


    return DownloadedMaterialLocal
        .fromMap(
      result.first,
    );
  }


  // ===========================================================================
  // GET BY USER
  // ===========================================================================

  Future<List<DownloadedMaterialLocal>>
      getByUser(
    int userId,
  ) async {
    final Database db =
        await _database.database;


    final List<Map<String, dynamic>>
        result =
        await db.query(
      DatabaseTables.downloadedMaterials,

      where:
          'user_id = ?',

      whereArgs: [
        userId,
      ],

      orderBy:
          'downloaded_at DESC',
    );


    return result
        .map(
          DownloadedMaterialLocal.fromMap,
        )
        .toList();
  }


  // ===========================================================================
  // GET BY GROUP
  // ===========================================================================

  Future<List<DownloadedMaterialLocal>>
      getByGroup({
    required int userId,
    required int groupId,
  }) async {
    final Database db =
        await _database.database;


    final List<Map<String, dynamic>>
        result =
        await db.query(
      DatabaseTables.downloadedMaterials,

      where:
          'user_id = ? '
          'AND group_id = ?',

      whereArgs: [
        userId,
        groupId,
      ],

      orderBy:
          'downloaded_at DESC',
    );


    return result
        .map(
          DownloadedMaterialLocal.fromMap,
        )
        .toList();
  }


  // ===========================================================================
  // GET BY SUBJECT
  // ===========================================================================

  Future<List<DownloadedMaterialLocal>>
      getBySubject({
    required int userId,
    required int subjectId,
  }) async {
    final Database db =
        await _database.database;


    final List<Map<String, dynamic>>
        result =
        await db.query(
      DatabaseTables.downloadedMaterials,

      where:
          'user_id = ? '
          'AND subject_id = ?',

      whereArgs: [
        userId,
        subjectId,
      ],

      orderBy:
          'downloaded_at DESC',
    );


    return result
        .map(
          DownloadedMaterialLocal.fromMap,
        )
        .toList();
  }


  // ===========================================================================
  // GET BY SUBJECT NAME
  // ===========================================================================
  //
  // Fallback utile soprattutto per eventuali vecchi dati
  // oppure materiali per cui subjectId non fosse disponibile.
  //
  // ===========================================================================

  Future<List<DownloadedMaterialLocal>>
      getBySubjectName({
    required int userId,
    required String subjectName,
  }) async {
    final Database db =
        await _database.database;


    final List<Map<String, dynamic>>
        result =
        await db.query(
      DatabaseTables.downloadedMaterials,

      where:
          'user_id = ? '
          'AND subject_name = ?',

      whereArgs: [
        userId,
        subjectName,
      ],

      orderBy:
          'downloaded_at DESC',
    );


    return result
        .map(
          DownloadedMaterialLocal.fromMap,
        )
        .toList();
  }


  // ===========================================================================
  // GET UNIQUE SUBJECTS
  // ===========================================================================
  //
  // Questo metodo sarà particolarmente importante per StudentMaterialPage.
  //
  // Restituisce un materiale rappresentativo per ogni materia presente
  // nella libreria locale.
  //
  // La UI potrà usarlo per creare:
  //
  // Programmazione 1
  // 4 materiali
  //
  // Algebra
  // 2 materiali
  //
  // ===========================================================================

  Future<List<DownloadedMaterialLocal>>
      getDownloadedSubjects(
    int userId,
  ) async {
    final List<DownloadedMaterialLocal>
        materials =
        await getByUser(
      userId,
    );


    final Map<String,
            DownloadedMaterialLocal>
        uniqueSubjects =
        {};


    for (final DownloadedMaterialLocal
        material in materials) {

      // Preferiamo subjectId quando disponibile.
      final String key;


      if (material.subjectId !=
          null) {
        key =
            'id:${material.subjectId}';
      } else {
        final String name =
            material.subjectName
                    ?.trim()
                    .toLowerCase() ??
                '';


        if (name.isEmpty) {
          continue;
        }


        key =
            'name:$name';
      }


      uniqueSubjects.putIfAbsent(
        key,
        () =>
            material,
      );
    }


    return uniqueSubjects.values
        .toList();
  }


  // ===========================================================================
  // COUNT BY SUBJECT
  // ===========================================================================

  Future<int> countBySubject({
    required int userId,
    int? subjectId,
    String? subjectName,
  }) async {
    final Database db =
        await _database.database;


    if (subjectId !=
        null) {
      final List<Map<String, Object?>>
          result =
          await db.rawQuery(
        '''
        SELECT COUNT(*) AS count
        FROM ${DatabaseTables.downloadedMaterials}
        WHERE user_id = ?
        AND subject_id = ?
        ''',

        [
          userId,
          subjectId,
        ],
      );


      return _extractCount(
        result,
      );
    }


    if (subjectName !=
            null &&
        subjectName.trim().isNotEmpty) {
      final List<Map<String, Object?>>
          result =
          await db.rawQuery(
        '''
        SELECT COUNT(*) AS count
        FROM ${DatabaseTables.downloadedMaterials}
        WHERE user_id = ?
        AND subject_name = ?
        ''',

        [
          userId,
          subjectName,
        ],
      );


      return _extractCount(
        result,
      );
    }


    return 0;
  }


  // ===========================================================================
  // COUNT USER DOWNLOADS
  // ===========================================================================

  Future<int> countByUser(
    int userId,
  ) async {
    final Database db =
        await _database.database;


    final List<Map<String, Object?>>
        result =
        await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM ${DatabaseTables.downloadedMaterials}
      WHERE user_id = ?
      ''',

      [
        userId,
      ],
    );


    return _extractCount(
      result,
    );
  }


  // ===========================================================================
  // DELETE MATERIAL
  // ===========================================================================

  Future<void> delete({
    required int userId,
    required int materialId,
  }) async {
    final Database db =
        await _database.database;


    await db.delete(
      DatabaseTables.downloadedMaterials,

      where:
          'user_id = ? '
          'AND material_id = ?',

      whereArgs: [
        userId,
        materialId,
      ],
    );
  }


  // ===========================================================================
  // DELETE SUBJECT
  // ===========================================================================
  //
  // Cancella i RECORD SQLite.
  //
  // ATTENZIONE:
  // i file fisici devono essere cancellati dal MaterialDownloadService
  // prima di richiamare questa funzione.
  //
  // ===========================================================================

  Future<int> deleteSubject({
    required int userId,
    required int subjectId,
  }) async {
    final Database db =
        await _database.database;


    return db.delete(
      DatabaseTables.downloadedMaterials,

      where:
          'user_id = ? '
          'AND subject_id = ?',

      whereArgs: [
        userId,
        subjectId,
      ],
    );
  }


  // ===========================================================================
  // DELETE USER
  // ===========================================================================

  Future<int> deleteByUser(
    int userId,
  ) async {
    final Database db =
        await _database.database;


    return db.delete(
      DatabaseTables.downloadedMaterials,

      where:
          'user_id = ?',

      whereArgs: [
        userId,
      ],
    );
  }


  // ===========================================================================
  // EXTRACT COUNT
  // ===========================================================================

  static int _extractCount(
    List<Map<String, Object?>> result,
  ) {
    if (result.isEmpty) {
      return 0;
    }


    final dynamic value =
        result.first['count'];


    if (value is int) {
      return value;
    }


    if (value is num) {
      return value.toInt();
    }


    return int.tryParse(
          value?.toString() ??
              '',
        ) ??
        0;
  }
}