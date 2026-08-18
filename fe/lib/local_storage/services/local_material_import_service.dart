import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/downloaded_material_local.dart';
import '../repositories/downloaded_material_repository.dart';
import 'local_storage_identity.dart';

class LocalMaterialImportService {
  final DownloadedMaterialRepository _repository;

  LocalMaterialImportService({
    DownloadedMaterialRepository? repository,
  }) : _repository =
            repository ??
                DownloadedMaterialRepository();

  Future<DownloadedMaterialLocal> importMaterial({
    int? userId,
    required String sourcePath,
    required String university,
    required String department,
    required String course,
    required String subjectName,
    String? originalName,
  }) async {
    final int resolvedUserId =
        LocalStorageIdentity.resolve(
      userId:
          userId,
    );

    final File source =
        File(
      sourcePath,
    );

    if (!await source.exists()) {
      throw const FileSystemException(
        'File non disponibile.',
      );
    }

    final int size =
        await source.length();

    if (size <= 0) {
      throw const FileSystemException(
        'File vuoto.',
      );
    }

    final String resolvedName =
        originalName != null &&
                originalName.trim().isNotEmpty
            ? originalName.trim()
            : p.basename(
                sourcePath,
              );

    final List<DownloadedMaterialLocal> existing =
        await _repository.getByUser(
      resolvedUserId,
    );

    final String canonicalUniversity =
        _canonicalValue(
      university,
      existing.map(
        (
          DownloadedMaterialLocal material,
        ) =>
            material.displayUniversity,
      ),
    );

    final String canonicalDepartment =
        _canonicalValue(
      department,
      existing
          .where(
            (
              DownloadedMaterialLocal material,
            ) =>
                _sameText(
              material.displayUniversity,
              canonicalUniversity,
            ),
          )
          .map(
            (
              DownloadedMaterialLocal material,
            ) =>
                material.displayDepartment,
          ),
    );

    final String canonicalCourse =
        _canonicalValue(
      course,
      existing
          .where(
            (
              DownloadedMaterialLocal material,
            ) =>
                _sameText(
                  material.displayUniversity,
                  canonicalUniversity,
                ) &&
                _sameText(
                  material.displayDepartment,
                  canonicalDepartment,
                ),
          )
          .map(
            (
              DownloadedMaterialLocal material,
            ) =>
                material.displayCourse,
          ),
    );

    final String canonicalSubject =
        _canonicalValue(
      subjectName,
      existing
          .where(
            (
              DownloadedMaterialLocal material,
            ) =>
                _sameText(
                  material.displayUniversity,
                  canonicalUniversity,
                ) &&
                _sameText(
                  material.displayDepartment,
                  canonicalDepartment,
                ) &&
                _sameText(
                  material.displayCourse,
                  canonicalCourse,
                ),
          )
          .map(
            (
              DownloadedMaterialLocal material,
            ) =>
                material.displaySubjectName,
          ),
    );

    final Directory root =
        await getApplicationDocumentsDirectory();

    final Directory directory =
        Directory(
      p.join(
        root.path,
        'studentlab',
        'users',
        resolvedUserId.toString(),
        'library',
        'imported',
      ),
    );

    if (!await directory.exists()) {
      await directory.create(
        recursive:
            true,
      );
    }

    final String safeName =
        _sanitizeFileName(
      resolvedName,
    );

    final String uniqueName =
        '${DateTime.now().microsecondsSinceEpoch}_$safeName';

    final String localPath =
        p.join(
      directory.path,
      uniqueName,
    );

    final File copied =
        await source.copy(
      localPath,
    );

    int materialId =
        -DateTime.now()
            .microsecondsSinceEpoch;

    while (
      await _repository.getMaterial(
            userId:
                resolvedUserId,
            materialId:
                materialId,
          ) !=
          null
    ) {
      materialId--;
    }

    final DownloadedMaterialLocal material =
        DownloadedMaterialLocal(
      userId:
          resolvedUserId,
      materialId:
          materialId,
      groupId:
          0,
      university:
          canonicalUniversity,
      department:
          canonicalDepartment,
      course:
          canonicalCourse,
      subjectId:
          null,
      subjectName:
          canonicalSubject,
      originalName:
          resolvedName,
      localPath:
          copied.path,
      mimeType:
          _mimeType(
        resolvedName,
      ),
      size:
          size,
      downloadedAt:
          DateTime.now(),
    );

    await _repository.save(
      material,
    );

    return material;
  }

  String _canonicalValue(
    String value,
    Iterable<String> existing,
  ) {
    final String trimmed =
        _cleanText(
      value,
    );

    if (trimmed.isEmpty) {
      throw ArgumentError(
        'Campo obbligatorio.',
      );
    }

    for (final String candidate in existing) {
      if (
        _sameText(
          candidate,
          trimmed,
        )
      ) {
        return _cleanText(
          candidate,
        );
      }
    }

    return trimmed;
  }

  bool _sameText(
    String a,
    String b,
  ) {
    return _normalizeText(
          a,
        ) ==
        _normalizeText(
          b,
        );
  }

  String _normalizeText(
    String value,
  ) {
    return _cleanText(
      value,
    ).toLowerCase();
  }

  String _cleanText(
    String value,
  ) {
    return value
        .trim()
        .replaceAll(
          RegExp(
            r'\s+',
          ),
          ' ',
        );
  }

  String _sanitizeFileName(
    String fileName,
  ) {
    String value =
        fileName.trim();

    if (value.isEmpty) {
      value =
          'materiale';
    }

    return value.replaceAll(
      RegExp(
        r'[\\/:\*?"<>|]',
      ),
      '_',
    );
  }

  String _mimeType(
    String fileName,
  ) {
    final String lower =
        fileName.toLowerCase();

    if (lower.endsWith('.pdf')) {
      return 'application/pdf';
    }

    if (lower.endsWith('.txt')) {
      return 'text/plain';
    }

    if (lower.endsWith('.zip')) {
      return 'application/zip';
    }

    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }

    if (lower.endsWith('.pptx')) {
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    }

    if (lower.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }

    if (lower.endsWith('.csv')) {
      return 'text/csv';
    }

    if (lower.endsWith('.png')) {
      return 'image/png';
    }

    if (
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg')
    ) {
      return 'image/jpeg';
    }

    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }

    return 'application/octet-stream';
  }
}