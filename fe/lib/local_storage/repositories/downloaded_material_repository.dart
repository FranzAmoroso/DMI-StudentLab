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
        subjectName.trim(),
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


  Future<List<String>>
      getUniversities(
    int userId,
  ) async {
    final Database db =
        await _database.database;

    final List<Map<String, Object?>>
        result =
        await db.rawQuery(
      '''
      SELECT DISTINCT
        TRIM(university) AS value
      FROM ${DatabaseTables.downloadedMaterials}
      WHERE user_id = ?
      AND university IS NOT NULL
      AND TRIM(university) <> ''
      ORDER BY value COLLATE NOCASE ASC
      ''',
      [
        userId,
      ],
    );

    return _extractStrings(
      result,
    );
  }


  Future<List<String>>
      getDepartments({
    required int userId,
    required String university,
  }) async {
    final Database db =
        await _database.database;

    final List<Map<String, Object?>>
        result =
        await db.rawQuery(
      '''
      SELECT DISTINCT
        TRIM(department) AS value
      FROM ${DatabaseTables.downloadedMaterials}
      WHERE user_id = ?
      AND university = ?
      AND department IS NOT NULL
      AND TRIM(department) <> ''
      ORDER BY value COLLATE NOCASE ASC
      ''',
      [
        userId,
        university.trim(),
      ],
    );

    return _extractStrings(
      result,
    );
  }


  Future<List<String>>
      getCourses({
    required int userId,
    required String university,
    required String department,
  }) async {
    final Database db =
        await _database.database;

    final List<Map<String, Object?>>
        result =
        await db.rawQuery(
      '''
      SELECT DISTINCT
        TRIM(course) AS value
      FROM ${DatabaseTables.downloadedMaterials}
      WHERE user_id = ?
      AND university = ?
      AND department = ?
      AND course IS NOT NULL
      AND TRIM(course) <> ''
      ORDER BY value COLLATE NOCASE ASC
      ''',
      [
        userId,
        university.trim(),
        department.trim(),
      ],
    );

    return _extractStrings(
      result,
    );
  }


  Future<List<DownloadedMaterialLocal>>
      getSubjects({
    required int userId,
    required String university,
    required String department,
    required String course,
  }) async {
    final Database db =
        await _database.database;

    final List<Map<String, dynamic>>
        result =
        await db.query(
      DatabaseTables.downloadedMaterials,
      where:
          'user_id = ? '
          'AND university = ? '
          'AND department = ? '
          'AND course = ?',
      whereArgs: [
        userId,
        university.trim(),
        department.trim(),
        course.trim(),
      ],
      orderBy:
          'subject_name COLLATE NOCASE ASC, '
          'downloaded_at DESC',
    );

    final Map<String, DownloadedMaterialLocal>
        subjects =
        {};

    for (
      final Map<String, dynamic> row
      in result
    ) {
      final DownloadedMaterialLocal material =
          DownloadedMaterialLocal.fromMap(
        row,
      );

      final String key;

      if (material.subjectId != null) {
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

      subjects.putIfAbsent(
        key,
        () =>
            material,
      );
    }

    return subjects.values
        .toList();
  }


  Future<List<DownloadedMaterialLocal>>
      getMaterialsByHierarchy({
    required int userId,
    required String university,
    required String department,
    required String course,
    int? subjectId,
    String? subjectName,
  }) async {
    final Database db =
        await _database.database;

    String where =
        'user_id = ? '
        'AND university = ? '
        'AND department = ? '
        'AND course = ?';

    final List<Object?> whereArgs = [
      userId,
      university.trim(),
      department.trim(),
      course.trim(),
    ];

    if (subjectId != null) {
      where +=
          ' AND subject_id = ?';

      whereArgs.add(
        subjectId,
      );
    } else if (
      subjectName != null &&
      subjectName.trim().isNotEmpty
    ) {
      where +=
          ' AND subject_name = ?';

      whereArgs.add(
        subjectName.trim(),
      );
    }

    final List<Map<String, dynamic>>
        result =
        await db.query(
      DatabaseTables.downloadedMaterials,
      where:
          where,
      whereArgs:
          whereArgs,
      orderBy:
          'downloaded_at DESC',
    );

    return result
        .map(
          DownloadedMaterialLocal.fromMap,
        )
        .toList();
  }


  Future<List<DownloadedMaterialLocal>>
      getDownloadedSubjects(
    int userId,
  ) async {
    final List<DownloadedMaterialLocal>
        materials =
        await getByUser(
      userId,
    );

    final Map<String, DownloadedMaterialLocal>
        uniqueSubjects =
        {};

    for (
      final DownloadedMaterialLocal material
      in materials
    ) {
      final String key;

      if (material.subjectId != null) {
        key =
            '${material.university}|'
            '${material.department}|'
            '${material.course}|'
            '${material.subjectId}';
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
            '${material.university}|'
            '${material.department}|'
            '${material.course}|'
            '$name';
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


  Future<int> countByUniversity({
    required int userId,
    required String university,
  }) async {
    final Database db =
        await _database.database;

    final List<Map<String, Object?>>
        result =
        await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM ${DatabaseTables.downloadedMaterials}
      WHERE user_id = ?
      AND university = ?
      ''',
      [
        userId,
        university.trim(),
      ],
    );

    return _extractCount(
      result,
    );
  }


  Future<int> countByDepartment({
    required int userId,
    required String university,
    required String department,
  }) async {
    final Database db =
        await _database.database;

    final List<Map<String, Object?>>
        result =
        await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM ${DatabaseTables.downloadedMaterials}
      WHERE user_id = ?
      AND university = ?
      AND department = ?
      ''',
      [
        userId,
        university.trim(),
        department.trim(),
      ],
    );

    return _extractCount(
      result,
    );
  }


  Future<int> countByCourse({
    required int userId,
    required String university,
    required String department,
    required String course,
  }) async {
    final Database db =
        await _database.database;

    final List<Map<String, Object?>>
        result =
        await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM ${DatabaseTables.downloadedMaterials}
      WHERE user_id = ?
      AND university = ?
      AND department = ?
      AND course = ?
      ''',
      [
        userId,
        university.trim(),
        department.trim(),
        course.trim(),
      ],
    );

    return _extractCount(
      result,
    );
  }


  Future<int> countBySubject({
    required int userId,
    int? subjectId,
    String? subjectName,
    String? university,
    String? department,
    String? course,
  }) async {
    final Database db =
        await _database.database;

    String where =
        'user_id = ?';

    final List<Object?> args = [
      userId,
    ];

    if (
      university != null &&
      university.trim().isNotEmpty
    ) {
      where +=
          ' AND university = ?';

      args.add(
        university.trim(),
      );
    }

    if (
      department != null &&
      department.trim().isNotEmpty
    ) {
      where +=
          ' AND department = ?';

      args.add(
        department.trim(),
      );
    }

    if (
      course != null &&
      course.trim().isNotEmpty
    ) {
      where +=
          ' AND course = ?';

      args.add(
        course.trim(),
      );
    }

    if (subjectId != null) {
      where +=
          ' AND subject_id = ?';

      args.add(
        subjectId,
      );
    } else if (
      subjectName != null &&
      subjectName.trim().isNotEmpty
    ) {
      where +=
          ' AND subject_name = ?';

      args.add(
        subjectName.trim(),
      );
    } else {
      return 0;
    }

    final List<Map<String, Object?>>
        result =
        await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM ${DatabaseTables.downloadedMaterials}
      WHERE $where
      ''',
      args,
    );

    return _extractCount(
      result,
    );
  }


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


  static List<String> _extractStrings(
    List<Map<String, Object?>> result,
  ) {
    return result
        .map(
          (
            Map<String, Object?> row,
          ) =>
              row['value']
                  ?.toString()
                  .trim() ??
              '',
        )
        .where(
          (
            String value,
          ) =>
              value.isNotEmpty,
        )
        .toList();
  }


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