import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../database/database_tables.dart';

import '../models/pending_upload_local.dart';


class PendingUploadRepository {
  final AppDatabase _database =
      AppDatabase.instance;


  // ===========================================================================
  // INSERT
  // ===========================================================================

  Future<int> insert(
    PendingUploadLocal upload,
  ) async {
    final Database db =
        await _database.database;

    return db.insert(
      DatabaseTables.pendingUploads,
      upload.toMap(),
    );
  }


  // ===========================================================================
  // UPDATE COMPLETO
  // ===========================================================================

  Future<void> update(
    PendingUploadLocal upload,
  ) async {
    if (upload.id == null) {
      throw ArgumentError(
        'Impossibile aggiornare un upload senza id.',
      );
    }

    final Database db =
        await _database.database;

    await db.update(
      DatabaseTables.pendingUploads,
      upload.toMap(),

      where:
          'id = ?',

      whereArgs: [
        upload.id,
      ],
    );
  }


  // ===========================================================================
  // GET BY ID
  // ===========================================================================

  Future<PendingUploadLocal?>
      getById(
    int id,
  ) async {
    final Database db =
        await _database.database;

    final List<Map<String, dynamic>> result =
        await db.query(
      DatabaseTables.pendingUploads,

      where:
          'id = ?',

      whereArgs: [
        id,
      ],

      limit:
          1,
    );

    if (result.isEmpty) {
      return null;
    }

    return PendingUploadLocal.fromMap(
      result.first,
    );
  }


  // ===========================================================================
  // TUTTI GLI UPLOAD DI UN UTENTE
  // ===========================================================================

  Future<List<PendingUploadLocal>>
      getByUser(
    int userId,
  ) async {
    final Database db =
        await _database.database;

    final List<Map<String, dynamic>> result =
        await db.query(
      DatabaseTables.pendingUploads,

      where:
          'user_id = ?',

      whereArgs: [
        userId,
      ],

      orderBy:
          'created_at DESC',
    );

    return result
        .map(
          PendingUploadLocal.fromMap,
        )
        .toList();
  }


  // ===========================================================================
  // UPLOAD DI UN GRUPPO
  // ===========================================================================

  Future<List<PendingUploadLocal>>
      getByGroup({
    required int userId,
    required int groupId,
  }) async {
    final Database db =
        await _database.database;

    final List<Map<String, dynamic>> result =
        await db.query(
      DatabaseTables.pendingUploads,

      where:
          'user_id = ? AND group_id = ?',

      whereArgs: [
        userId,
        groupId,
      ],

      orderBy:
          'created_at DESC',
    );

    return result
        .map(
          PendingUploadLocal.fromMap,
        )
        .toList();
  }


  // ===========================================================================
  // PER STATO
  // ===========================================================================

  Future<List<PendingUploadLocal>>
      getByStatus({
    required int userId,
    required PendingUploadStatus status,
  }) async {
    final Database db =
        await _database.database;

    final List<Map<String, dynamic>> result =
        await db.query(
      DatabaseTables.pendingUploads,

      where:
          'user_id = ? AND status = ?',

      whereArgs: [
        userId,
        status.name,
      ],

      orderBy:
          'created_at ASC',
    );

    return result
        .map(
          PendingUploadLocal.fromMap,
        )
        .toList();
  }


  // ===========================================================================
  // PENDING
  // ===========================================================================

  Future<List<PendingUploadLocal>>
      getPending(
    int userId,
  ) {
    return getByStatus(
      userId:
          userId,

      status:
          PendingUploadStatus.pending,
    );
  }


  // ===========================================================================
  // FAILED
  // ===========================================================================

  Future<List<PendingUploadLocal>>
      getFailed(
    int userId,
  ) {
    return getByStatus(
      userId:
          userId,

      status:
          PendingUploadStatus.failed,
    );
  }


  // ===========================================================================
  // PENDING + FAILED
  // ===========================================================================

  Future<List<PendingUploadLocal>>
      getWaitingForSync(
    int userId,
  ) async {
    final Database db =
        await _database.database;

    final List<Map<String, dynamic>> result =
        await db.query(
      DatabaseTables.pendingUploads,

      where:
          '''
          user_id = ?
          AND status IN (?, ?)
          ''',

      whereArgs: [
        userId,
        PendingUploadStatus.pending.name,
        PendingUploadStatus.failed.name,
      ],

      orderBy:
          'created_at ASC',
    );

    return result
        .map(
          PendingUploadLocal.fromMap,
        )
        .toList();
  }


  // ===========================================================================
  // CAMBIO STATO
  // ===========================================================================

  Future<void> updateStatus({
    required int id,
    required PendingUploadStatus status,
    String? errorMessage,
  }) async {
    final Database db =
        await _database.database;

    final Map<String, dynamic> values = {
      'status':
          status.name,
    };

    if (errorMessage != null) {
      values['error_message'] =
          errorMessage;
    } else if (
        status !=
            PendingUploadStatus.failed) {
      values['error_message'] =
          null;
    }

    await db.update(
      DatabaseTables.pendingUploads,

      values,

      where:
          'id = ?',

      whereArgs: [
        id,
      ],
    );
  }


  // ===========================================================================
  // MARK UPLOADING
  // ===========================================================================

  Future<void> markUploading(
    int id,
  ) {
    return updateStatus(
      id:
          id,

      status:
          PendingUploadStatus.uploading,
    );
  }


  // ===========================================================================
  // MARK FAILED
  // ===========================================================================

  Future<void> markFailed({
    required int id,
    required String errorMessage,
  }) {
    return updateStatus(
      id:
          id,

      status:
          PendingUploadStatus.failed,

      errorMessage:
          errorMessage,
    );
  }


  // ===========================================================================
  // MARK UPLOADED
  // ===========================================================================

  Future<void> markUploaded({
    required int id,
    required int serverMaterialId,
  }) async {
    final Database db =
        await _database.database;

    await db.update(
      DatabaseTables.pendingUploads,

      {
        'status':
            PendingUploadStatus
                .uploaded
                .name,

        'uploaded_at':
            DateTime.now()
                .toIso8601String(),

        'server_material_id':
            serverMaterialId,

        'error_message':
            null,
      },

      where:
          'id = ?',

      whereArgs: [
        id,
      ],
    );
  }


  // ===========================================================================
  // RETRY
  // ===========================================================================

  Future<void> retry(
    int id,
  ) async {
    final Database db =
        await _database.database;

    await db.update(
      DatabaseTables.pendingUploads,

      {
        'status':
            PendingUploadStatus
                .pending
                .name,

        'error_message':
            null,

        'uploaded_at':
            null,

        'server_material_id':
            null,
      },

      where:
          'id = ?',

      whereArgs: [
        id,
      ],
    );
  }


  // ===========================================================================
  // DELETE
  // ===========================================================================

  Future<void> delete(
    int id,
  ) async {
    final Database db =
        await _database.database;

    await db.delete(
      DatabaseTables.pendingUploads,

      where:
          'id = ?',

      whereArgs: [
        id,
      ],
    );
  }


  // ===========================================================================
  // DELETE UPLOADED
  // ===========================================================================

  Future<int> deleteUploaded(
    int userId,
  ) async {
    final Database db =
        await _database.database;

    return db.delete(
      DatabaseTables.pendingUploads,

      where:
          'user_id = ? AND status = ?',

      whereArgs: [
        userId,
        PendingUploadStatus
            .uploaded
            .name,
      ],
    );
  }


  // ===========================================================================
  // COUNT WAITING
  // ===========================================================================

  Future<int> countWaiting(
    int userId,
  ) async {
    final Database db =
        await _database.database;

    final List<Map<String, dynamic>> result =
        await db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM ${DatabaseTables.pendingUploads}
      WHERE user_id = ?
      AND status IN (?, ?)
      ''',

      [
        userId,
        PendingUploadStatus.pending.name,
        PendingUploadStatus.failed.name,
      ],
    );

    if (result.isEmpty) {
      return 0;
    }

    final dynamic value =
        result.first['total'];

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }


  // ===========================================================================
  // RESET UPLOADING
  // ===========================================================================
  //
  // Se l'app viene chiusa durante un upload,
  // al riavvio può rimanere status = uploading.
  //
  // Lo riportiamo a pending per permettere
  // un nuovo tentativo.
  // ===========================================================================

  Future<void> resetInterruptedUploads(
    int userId,
  ) async {
    final Database db =
        await _database.database;

    await db.update(
      DatabaseTables.pendingUploads,

      {
        'status':
            PendingUploadStatus
                .pending
                .name,

        'error_message':
            null,
      },

      where:
          'user_id = ? AND status = ?',

      whereArgs: [
        userId,
        PendingUploadStatus
            .uploading
            .name,
      ],
    );
  }
}