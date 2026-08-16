import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../database/database_tables.dart';

import '../models/material_cache_local.dart';


class MaterialCacheRepository {
  final AppDatabase _database =
      AppDatabase.instance;


  // ===========================================================================
  // SAVE / UPSERT
  // ===========================================================================

  Future<void> save(
    MaterialCacheLocal material,
  ) async {
    final Database db =
        await _database.database;

    await db.insert(
      DatabaseTables.materialCache,

      material.toMap(),

      conflictAlgorithm:
          ConflictAlgorithm.replace,
    );
  }


  // ===========================================================================
  // SAVE MANY
  // ===========================================================================

  Future<void> saveAll(
    List<MaterialCacheLocal> materials,
  ) async {
    if (materials.isEmpty) {
      return;
    }

    final Database db =
        await _database.database;

    final Batch batch =
        db.batch();

    for (final MaterialCacheLocal material
        in materials) {
      batch.insert(
        DatabaseTables.materialCache,

        material.toMap(),

        conflictAlgorithm:
            ConflictAlgorithm.replace,
      );
    }

    await batch.commit(
      noResult: true,
    );
  }


  // ===========================================================================
  // GET BY MATERIAL ID
  // ===========================================================================

  Future<MaterialCacheLocal?>
      getByMaterialId({
    required int userId,
    required int materialId,
  }) async {
    final Database db =
        await _database.database;

    final List<Map<String, dynamic>> result =
        await db.query(
      DatabaseTables.materialCache,

      where:
          'user_id = ? AND material_id = ?',

      whereArgs: [
        userId,
        materialId,
      ],

      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return MaterialCacheLocal.fromMap(
      result.first,
    );
  }


  // ===========================================================================
  // MATERIALI DI UN GRUPPO
  // ===========================================================================

  Future<List<MaterialCacheLocal>>
      getByGroup({
    required int userId,
    required int groupId,
  }) async {
    final Database db =
        await _database.database;

    final List<Map<String, dynamic>> result =
        await db.query(
      DatabaseTables.materialCache,

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
          MaterialCacheLocal.fromMap,
        )
        .toList();
  }


  // ===========================================================================
  // TUTTA LA CACHE DI UN UTENTE
  // ===========================================================================

  Future<List<MaterialCacheLocal>>
      getByUser(
    int userId,
  ) async {
    final Database db =
        await _database.database;

    final List<Map<String, dynamic>> result =
        await db.query(
      DatabaseTables.materialCache,

      where:
          'user_id = ?',

      whereArgs: [
        userId,
      ],

      orderBy:
          'synced_at DESC',
    );

    return result
        .map(
          MaterialCacheLocal.fromMap,
        )
        .toList();
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
      DatabaseTables.materialCache,

      where:
          'user_id = ? AND material_id = ?',

      whereArgs: [
        userId,
        materialId,
      ],
    );
  }


  // ===========================================================================
  // DELETE CACHE DEL GRUPPO
  // ===========================================================================

  Future<void> deleteGroupCache({
    required int userId,
    required int groupId,
  }) async {
    final Database db =
        await _database.database;

    await db.delete(
      DatabaseTables.materialCache,

      where:
          'user_id = ? AND group_id = ?',

      whereArgs: [
        userId,
        groupId,
      ],
    );
  }


  // ===========================================================================
  // DELETE CACHE UTENTE
  // ===========================================================================

  Future<void> deleteUserCache(
    int userId,
  ) async {
    final Database db =
        await _database.database;

    await db.delete(
      DatabaseTables.materialCache,

      where:
          'user_id = ?',

      whereArgs: [
        userId,
      ],
    );
  }


  // ===========================================================================
  // REPLACE GROUP CACHE
  // ===========================================================================
  //
  // Dopo un GET /group_materials/{groupId}
  // sostituiamo la cache locale del gruppo
  // con la risposta più recente del backend.
  // ===========================================================================

  Future<void> replaceGroupCache({
    required int userId,
    required int groupId,
    required List<MaterialCacheLocal> materials,
  }) async {
    final Database db =
        await _database.database;

    await db.transaction(
      (
        Transaction transaction,
      ) async {
        await transaction.delete(
          DatabaseTables.materialCache,

          where:
              'user_id = ? AND group_id = ?',

          whereArgs: [
            userId,
            groupId,
          ],
        );

        for (final MaterialCacheLocal material
            in materials) {
          await transaction.insert(
            DatabaseTables.materialCache,

            material.toMap(),

            conflictAlgorithm:
                ConflictAlgorithm.replace,
          );
        }
      },
    );
  }


  // ===========================================================================
  // COUNT MATERIALI DEL GRUPPO
  // ===========================================================================

  Future<int> countByGroup({
    required int userId,
    required int groupId,
  }) async {
    final Database db =
        await _database.database;

    final List<Map<String, dynamic>> result =
        await db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM ${DatabaseTables.materialCache}
      WHERE user_id = ?
      AND group_id = ?
      ''',

      [
        userId,
        groupId,
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
  // LAST SYNC
  // ===========================================================================

  Future<DateTime?> getLastSync({
    required int userId,
    required int groupId,
  }) async {
    final Database db =
        await _database.database;

    final List<Map<String, dynamic>> result =
        await db.query(
      DatabaseTables.materialCache,

      columns: [
        'synced_at',
      ],

      where:
          'user_id = ? AND group_id = ?',

      whereArgs: [
        userId,
        groupId,
      ],

      orderBy:
          'synced_at DESC',

      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    final dynamic value =
        result.first['synced_at'];

    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }


  // ===========================================================================
  // ESISTE IN CACHE?
  // ===========================================================================

  Future<bool> exists({
    required int userId,
    required int materialId,
  }) async {
    final MaterialCacheLocal? material =
        await getByMaterialId(
      userId: userId,
      materialId: materialId,
    );

    return material != null;
  }


  // ===========================================================================
  // CLEAR TUTTO
  // ===========================================================================

  Future<void> clearAll() async {
    final Database db =
        await _database.database;

    await db.delete(
      DatabaseTables.materialCache,
    );
  }
}