import 'dart:io';

import '../../services/api_service.dart';

import '../models/downloaded_material_local.dart';

import '../repositories/downloaded_material_repository.dart';

import 'local_file_service.dart';
import 'local_storage_identity.dart';


class MaterialDownloadService {
  final ApiService _apiService;

  final DownloadedMaterialRepository
      _repository;

  final LocalFileService
      _fileService;


  MaterialDownloadService({
    ApiService? apiService,

    DownloadedMaterialRepository?
        repository,

    LocalFileService? fileService,
  })  : _apiService =
            apiService ??
                ApiService(),

        _repository =
            repository ??
                DownloadedMaterialRepository(),

        _fileService =
            fileService ??
                LocalFileService();


  int get currentLocalUserId {
    return LocalStorageIdentity
        .currentLocalUserId;
  }


  Future<DownloadedMaterialLocal>
      download({
    int? userId,

    required int materialId,

    required int groupId,

    String? university,

    String? department,

    String? course,

    int? subjectId,

    String? subjectName,

    required String originalName,

    String? mimeType,

    int? size,
  }) async {
    final int resolvedUserId =
        LocalStorageIdentity.resolve(
      userId:
          userId,
    );

    final DownloadedMaterialLocal?
        existing =
        await _repository.getMaterial(
      userId:
          resolvedUserId,

      materialId:
          materialId,
    );

    if (existing != null) {
      final bool fileExists =
          await _fileService.exists(
        existing.localPath,
      );

      if (fileExists) {
        final DownloadedMaterialLocal
            updated =
            existing.copyWith(
          university:
              university,

          department:
              department,

          course:
              course,

          subjectId:
              subjectId,

          subjectName:
              subjectName,

          mimeType:
              mimeType,

          size:
              size,
        );

        await _repository.save(
          updated,
        );

        return updated;
      }

      await _repository.delete(
        userId:
            resolvedUserId,

        materialId:
            materialId,
      );
    }

    final bytes =
        await _apiService
            .downloadGroupMaterial(
      materialId,
    );

    final String localPath =
        await _fileService
            .saveDownloadedMaterial(
      userId:
          resolvedUserId,

      groupId:
          groupId,

      fileName:
          originalName,

      bytes:
          bytes,
    );

    final DownloadedMaterialLocal material =
        DownloadedMaterialLocal(
      userId:
          resolvedUserId,

      materialId:
          materialId,

      groupId:
          groupId,

      university:
          university,

      department:
          department,

      course:
          course,

      subjectId:
          subjectId,

      subjectName:
          subjectName,

      originalName:
          originalName,

      localPath:
          localPath,

      mimeType:
          mimeType,

      size:
          size ??
              bytes.length,

      downloadedAt:
          DateTime.now(),
    );

    await _repository.save(
      material,
    );

    return material;
  }


  Future<DownloadedMaterialLocal>
      getOrDownload({
    int? userId,

    required int materialId,

    required int groupId,

    String? university,

    String? department,

    String? course,

    int? subjectId,

    String? subjectName,

    required String originalName,

    String? mimeType,

    int? size,
  }) async {
    final DownloadedMaterialLocal?
        existing =
        await getLocalMaterial(
      userId:
          userId,

      materialId:
          materialId,
    );

    if (existing != null) {
      final DownloadedMaterialLocal
          updated =
          existing.copyWith(
        university:
            university,

        department:
            department,

        course:
            course,

        subjectId:
            subjectId,

        subjectName:
            subjectName,

        mimeType:
            mimeType,

        size:
            size,
      );

      await _repository.save(
        updated,
      );

      return updated;
    }

    return download(
      userId:
          userId,

      materialId:
          materialId,

      groupId:
          groupId,

      university:
          university,

      department:
          department,

      course:
          course,

      subjectId:
          subjectId,

      subjectName:
          subjectName,

      originalName:
          originalName,

      mimeType:
          mimeType,

      size:
          size,
    );
  }


  Future<bool> isDownloaded({
    int? userId,

    required int materialId,
  }) async {
    final int resolvedUserId =
        LocalStorageIdentity.resolve(
      userId:
          userId,
    );

    final DownloadedMaterialLocal?
        material =
        await _repository.getMaterial(
      userId:
          resolvedUserId,

      materialId:
          materialId,
    );

    if (material == null) {
      return false;
    }

    final bool exists =
        await _fileService.exists(
      material.localPath,
    );

    if (!exists) {
      await _repository.delete(
        userId:
            resolvedUserId,

        materialId:
            materialId,
      );

      return false;
    }

    return true;
  }


  Future<DownloadedMaterialLocal?>
      getLocalMaterial({
    int? userId,

    required int materialId,
  }) async {
    final int resolvedUserId =
        LocalStorageIdentity.resolve(
      userId:
          userId,
    );

    final DownloadedMaterialLocal?
        material =
        await _repository.getMaterial(
      userId:
          resolvedUserId,

      materialId:
          materialId,
    );

    if (material == null) {
      return null;
    }

    final bool exists =
        await _fileService.exists(
      material.localPath,
    );

    if (!exists) {
      await _repository.delete(
        userId:
            resolvedUserId,

        materialId:
            materialId,
      );

      return null;
    }

    return material;
  }


  Future<File?> getFile({
    int? userId,

    required int materialId,
  }) async {
    final DownloadedMaterialLocal?
        material =
        await getLocalMaterial(
      userId:
          userId,

      materialId:
          materialId,
    );

    if (material == null) {
      return null;
    }

    return File(
      material.localPath,
    );
  }


  Future<List<DownloadedMaterialLocal>>
      getDownloadedMaterials({
    int? userId,
  }) async {
    final int resolvedUserId =
        LocalStorageIdentity.resolve(
      userId:
          userId,
    );

    final List<DownloadedMaterialLocal>
        materials =
        await _repository.getByUser(
      resolvedUserId,
    );

    return _removeMissingFiles(
      resolvedUserId,
      materials,
    );
  }


  Future<List<String>>
      getUniversities({
    int? userId,
  }) async {
    final int resolvedUserId =
        LocalStorageIdentity.resolve(
      userId:
          userId,
    );

    return _repository.getUniversities(
      resolvedUserId,
    );
  }


  Future<List<String>>
      getDepartments({
    int? userId,

    required String university,
  }) async {
    final int resolvedUserId =
        LocalStorageIdentity.resolve(
      userId:
          userId,
    );

    return _repository.getDepartments(
      userId:
          resolvedUserId,

      university:
          university,
    );
  }


  Future<List<String>>
      getCourses({
    int? userId,

    required String university,

    required String department,
  }) async {
    final int resolvedUserId =
        LocalStorageIdentity.resolve(
      userId:
          userId,
    );

    return _repository.getCourses(
      userId:
          resolvedUserId,

      university:
          university,

      department:
          department,
    );
  }


  Future<List<DownloadedMaterialLocal>>
      getSubjects({
    int? userId,

    required String university,

    required String department,

    required String course,
  }) async {
    final int resolvedUserId =
        LocalStorageIdentity.resolve(
      userId:
          userId,
    );

    final List<DownloadedMaterialLocal>
        subjects =
        await _repository.getSubjects(
      userId:
          resolvedUserId,

      university:
          university,

      department:
          department,

      course:
          course,
    );

    final List<DownloadedMaterialLocal>
        valid =
        [];

    for (
      final DownloadedMaterialLocal subject
      in subjects
    ) {
      final List<DownloadedMaterialLocal>
          materials =
          await getDownloadedMaterialsByHierarchy(
        userId:
            resolvedUserId,

        university:
            university,

        department:
            department,

        course:
            course,

        subjectId:
            subject.subjectId,

        subjectName:
            subject.subjectName,
      );

      if (materials.isNotEmpty) {
        valid.add(
          subject,
        );
      }
    }

    return valid;
  }


  Future<List<DownloadedMaterialLocal>>
      getDownloadedMaterialsByHierarchy({
    int? userId,

    required String university,

    required String department,

    required String course,

    int? subjectId,

    String? subjectName,
  }) async {
    final int resolvedUserId =
        LocalStorageIdentity.resolve(
      userId:
          userId,
    );

    final List<DownloadedMaterialLocal>
        materials =
        await _repository
            .getMaterialsByHierarchy(
      userId:
          resolvedUserId,

      university:
          university,

      department:
          department,

      course:
          course,

      subjectId:
          subjectId,

      subjectName:
          subjectName,
    );

    return _removeMissingFiles(
      resolvedUserId,
      materials,
    );
  }


  Future<List<DownloadedMaterialLocal>>
      getDownloadedMaterialsBySubject({
    int? userId,

    int? subjectId,

    String? subjectName,

    String? university,

    String? department,

    String? course,
  }) async {
    final int resolvedUserId =
        LocalStorageIdentity.resolve(
      userId:
          userId,
    );

    if (
      university != null &&
      university.trim().isNotEmpty &&
      department != null &&
      department.trim().isNotEmpty &&
      course != null &&
      course.trim().isNotEmpty
    ) {
      return getDownloadedMaterialsByHierarchy(
        userId:
            resolvedUserId,

        university:
            university,

        department:
            department,

        course:
            course,

        subjectId:
            subjectId,

        subjectName:
            subjectName,
      );
    }

    if (subjectId != null) {
      final List<DownloadedMaterialLocal>
          materials =
          await _repository.getBySubject(
        userId:
            resolvedUserId,

        subjectId:
            subjectId,
      );

      return _removeMissingFiles(
        resolvedUserId,
        materials,
      );
    }

    if (
      subjectName != null &&
      subjectName.trim().isNotEmpty
    ) {
      final List<DownloadedMaterialLocal>
          materials =
          await _repository
              .getBySubjectName(
        userId:
            resolvedUserId,

        subjectName:
            subjectName,
      );

      return _removeMissingFiles(
        resolvedUserId,
        materials,
      );
    }

    return [];
  }


  Future<List<DownloadedMaterialLocal>>
      getDownloadedSubjects({
    int? userId,
  }) async {
    final int resolvedUserId =
        LocalStorageIdentity.resolve(
      userId:
          userId,
    );

    return _repository
        .getDownloadedSubjects(
      resolvedUserId,
    );
  }


  Future<int> countByUniversity({
    int? userId,

    required String university,
  }) async {
    final int resolvedUserId =
        LocalStorageIdentity.resolve(
      userId:
          userId,
    );

    return _repository.countByUniversity(
      userId:
          resolvedUserId,

      university:
          university,
    );
  }


  Future<int> countByDepartment({
    int? userId,

    required String university,

    required String department,
  }) async {
    final int resolvedUserId =
        LocalStorageIdentity.resolve(
      userId:
          userId,
    );

    return _repository.countByDepartment(
      userId:
          resolvedUserId,

      university:
          university,

      department:
          department,
    );
  }


  Future<int> countByCourse({
    int? userId,

    required String university,

    required String department,

    required String course,
  }) async {
    final int resolvedUserId =
        LocalStorageIdentity.resolve(
      userId:
          userId,
    );

    return _repository.countByCourse(
      userId:
          resolvedUserId,

      university:
          university,

      department:
          department,

      course:
          course,
    );
  }


  Future<int> countBySubject({
    int? userId,

    int? subjectId,

    String? subjectName,

    String? university,

    String? department,

    String? course,
  }) async {
    final int resolvedUserId =
        LocalStorageIdentity.resolve(
      userId:
          userId,
    );

    return _repository.countBySubject(
      userId:
          resolvedUserId,

      subjectId:
          subjectId,

      subjectName:
          subjectName,

      university:
          university,

      department:
          department,

      course:
          course,
    );
  }


  Future<int> countDownloadedMaterials({
    int? userId,
  }) async {
    final int resolvedUserId =
        LocalStorageIdentity.resolve(
      userId:
          userId,
    );

    return _repository.countByUser(
      resolvedUserId,
    );
  }


  Future<void> removeDownload({
    int? userId,

    required int materialId,
  }) async {
    final int resolvedUserId =
        LocalStorageIdentity.resolve(
      userId:
          userId,
    );

    final DownloadedMaterialLocal?
        material =
        await _repository.getMaterial(
      userId:
          resolvedUserId,

      materialId:
          materialId,
    );

    if (material == null) {
      return;
    }

    await _fileService.delete(
      material.localPath,
    );

    await _repository.delete(
      userId:
          resolvedUserId,

      materialId:
          materialId,
    );
  }


  Future<int> removeSubjectDownloads({
    int? userId,

    required int subjectId,
  }) async {
    final int resolvedUserId =
        LocalStorageIdentity.resolve(
      userId:
          userId,
    );

    final List<DownloadedMaterialLocal>
        materials =
        await _repository.getBySubject(
      userId:
          resolvedUserId,

      subjectId:
          subjectId,
    );

    int removed =
        0;

    for (
      final DownloadedMaterialLocal material
      in materials
    ) {
      try {
        await _fileService.delete(
          material.localPath,
        );
      } finally {
        await _repository.delete(
          userId:
              resolvedUserId,

          materialId:
              material.materialId,
        );

        removed++;
      }
    }

    return removed;
  }


  Future<List<DownloadedMaterialLocal>>
      _removeMissingFiles(
    int userId,

    List<DownloadedMaterialLocal>
        materials,
  ) async {
    final List<DownloadedMaterialLocal>
        valid =
        [];

    for (
      final DownloadedMaterialLocal material
      in materials
    ) {
      final bool exists =
          await _fileService.exists(
        material.localPath,
      );

      if (exists) {
        valid.add(
          material,
        );

        continue;
      }

      await _repository.delete(
        userId:
            userId,

        materialId:
            material.materialId,
      );
    }

    return valid;
  }
}