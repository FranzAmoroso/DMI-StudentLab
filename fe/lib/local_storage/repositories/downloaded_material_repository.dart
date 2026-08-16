import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../database/database_tables.dart';

import '../models/downloaded_material_local.dart';

class DownloadedMaterialRepository {
  final AppDatabase _database =
      AppDatabase.instance;

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

  Future<bool> isDownloaded({
    required int userId,
    required int materialId,
  }) async {
    final Database db =
        await _database.database;

    final List<Map<String, dynamic>> result =
        await db.query(
      DatabaseTables.downloadedMaterials,

      where:
          'user_id = ? AND material_id = ?',

      whereArgs: [
        userId,
        materialId,
      ],

      limit: 1,
    );

    return result.isNotEmpty;
  }

  Future<DownloadedMaterialLocal?>
      getMaterial({
    required int userId,
    required int materialId,
  }) async {
    final Database db =
        await _database.database;

    final List<Map<String, dynamic>> result =
        await db.query(
      DatabaseTables.downloadedMaterials,

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

    return DownloadedMaterialLocal.fromMap(
      result.first,
    );
  }

  Future<List<DownloadedMaterialLocal>>
      getByUser(
    int userId,
  ) async {
    final Database db =
        await _database.database;

    final List<Map<String, dynamic>> result =
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

  Future<void> delete({
    required int userId,
    required int materialId,
  }) async {
    final Database db =
        await _database.database;

    await db.delete(
      DatabaseTables.downloadedMaterials,

      where:
          'user_id = ? AND material_id = ?',

      whereArgs: [
        userId,
        materialId,
      ],
    );
  }
}