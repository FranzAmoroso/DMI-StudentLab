import 'dart:io';

import '../../services/api_service.dart';

import '../models/downloaded_material_local.dart';

import '../repositories/downloaded_material_repository.dart';

import 'local_file_service.dart';
import 'local_storage_identity.dart';


// =============================================================================
// MATERIAL DOWNLOAD SERVICE
// =============================================================================

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


  // ===========================================================================
  // CURRENT LOCAL USER
  // ===========================================================================

  int get currentLocalUserId {
    return LocalStorageIdentity
        .currentLocalUserId;
  }


  // ===========================================================================
  // DOWNLOAD
  // ===========================================================================
  //
  // Se il file è già presente:
  //
  // SQLite + filesystem
  //      ↓
  // ritorniamo quello esistente.
  //
  // Nessun duplicato.
  //
  // ===========================================================================

  Future<DownloadedMaterialLocal>
      download({
    int? userId,

    required int materialId,

    required int groupId,

    int? subjectId,

    String? subjectName,

    String? course,

    String? department,

    required String originalName,

    String? mimeType,

    int? size,
  }) async {

    final int resolvedUserId =
        LocalStorageIdentity.resolve(
      userId:
          userId,
    );


    // -------------------------------------------------------------------------
    // 1. CERCA MATERIAL IN SQLITE
    // -------------------------------------------------------------------------

    final DownloadedMaterialLocal?
        existing =
        await _repository.getMaterial(
      userId:
          resolvedUserId,

      materialId:
          materialId,
    );


    if (existing !=
        null) {

      // -----------------------------------------------------------------------
      // CONTROLLA FILE FISICO
      // -----------------------------------------------------------------------

      final bool fileExists =
          await _fileService.exists(
        existing.localPath,
      );


      // -----------------------------------------------------------------------
      // ESISTE GIÀ
      // -----------------------------------------------------------------------

      if (fileExists) {

        // ---------------------------------------------------------------------
        // AGGIORNA EVENTUALI METADATI MANCANTI
        // ---------------------------------------------------------------------
        //
        // Utile per file scaricati prima della migration v4.
        //
        // ---------------------------------------------------------------------

        final DownloadedMaterialLocal
            updated =
            existing.copyWith(
          subjectId:
              subjectId,

          subjectName:
              subjectName,

          course:
              course,

          department:
              department,

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


      // -----------------------------------------------------------------------
      // SQLITE ORFANO
      // -----------------------------------------------------------------------

      await _repository.delete(
        userId:
            resolvedUserId,

        materialId:
            materialId,
      );
    }


    // -------------------------------------------------------------------------
    // 2. DOWNLOAD DAL BACKEND
    // -------------------------------------------------------------------------

    final bytes =
        await _apiService
            .downloadGroupMaterial(
      materialId,
    );


    // -------------------------------------------------------------------------
    // 3. SALVA NEL FILESYSTEM
    // -------------------------------------------------------------------------

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


    // -------------------------------------------------------------------------
    // 4. MODELLO SQLITE
    // -------------------------------------------------------------------------

    final DownloadedMaterialLocal material =
        DownloadedMaterialLocal(
      userId:
          resolvedUserId,

      materialId:
          materialId,

      groupId:
          groupId,

      subjectId:
          subjectId,

      subjectName:
          subjectName,

      course:
          course,

      department:
          department,

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


    // -------------------------------------------------------------------------
    // 5. SQLITE
    // -------------------------------------------------------------------------

    await _repository.save(
      material,
    );


    return material;
  }


  // ===========================================================================
  // GET OR DOWNLOAD
  // ===========================================================================
  //
  // Questo sarà il metodo principale utilizzato dalla UI.
  //
  // È già presente?
  //     ↓
  // ritorna file locale
  //
  // Non è presente?
  //     ↓
  // scarica + filesystem + SQLite
  //
  // ===========================================================================

  Future<DownloadedMaterialLocal>
      getOrDownload({
    int? userId,

    required int materialId,

    required int groupId,

    int? subjectId,

    String? subjectName,

    String? course,

    String? department,

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


    if (existing !=
        null) {

      // -----------------------------------------------------------------------
      // AGGIORNA METADATI
      // -----------------------------------------------------------------------

      final DownloadedMaterialLocal
          updated =
          existing.copyWith(
        subjectId:
            subjectId,

        subjectName:
            subjectName,

        course:
            course,

        department:
            department,

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

      subjectId:
          subjectId,

      subjectName:
          subjectName,

      course:
          course,

      department:
          department,

      originalName:
          originalName,

      mimeType:
          mimeType,

      size:
          size,
    );
  }


  // ===========================================================================
  // È SCARICATO?
  // ===========================================================================

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


    if (material ==
        null) {
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


  // ===========================================================================
  // GET LOCAL MATERIAL
  // ===========================================================================

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


    if (material ==
        null) {
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


  // ===========================================================================
  // GET FILE
  // ===========================================================================

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


    if (material ==
        null) {
      return null;
    }


    return File(
      material.localPath,
    );
  }


  // ===========================================================================
  // DOWNLOADS
  // ===========================================================================

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


    final List<DownloadedMaterialLocal>
        validMaterials =
        [];


    for (final DownloadedMaterialLocal
        material in materials) {

      final bool exists =
          await _fileService.exists(
        material.localPath,
      );


      if (exists) {

        validMaterials.add(
          material,
        );


        continue;
      }


      await _repository.delete(
        userId:
            resolvedUserId,

        materialId:
            material.materialId,
      );
    }


    return validMaterials;
  }


  // ===========================================================================
  // DOWNLOADS BY SUBJECT
  // ===========================================================================

  Future<List<DownloadedMaterialLocal>>
      getDownloadedMaterialsBySubject({
    int? userId,

    int? subjectId,

    String? subjectName,
  }) async {

    final int resolvedUserId =
        LocalStorageIdentity.resolve(
      userId:
          userId,
    );


    if (subjectId !=
        null) {

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


    if (subjectName !=
            null &&
        subjectName.trim().isNotEmpty) {

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


  // ===========================================================================
  // DOWNLOADED SUBJECTS
  // ===========================================================================

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


  // ===========================================================================
  // COUNT BY SUBJECT
  // ===========================================================================

  Future<int> countBySubject({
    int? userId,

    int? subjectId,

    String? subjectName,
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
    );
  }


  // ===========================================================================
  // REMOVE DOWNLOAD
  // ===========================================================================

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


    if (material ==
        null) {
      return;
    }


    // -------------------------------------------------------------------------
    // FILESYSTEM
    // -------------------------------------------------------------------------

    await _fileService.delete(
      material.localPath,
    );


    // -------------------------------------------------------------------------
    // SQLITE
    // -------------------------------------------------------------------------

    await _repository.delete(
      userId:
          resolvedUserId,

      materialId:
          materialId,
    );
  }


  // ===========================================================================
  // REMOVE SUBJECT DOWNLOADS
  // ===========================================================================

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


    for (final DownloadedMaterialLocal
        material in materials) {

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


  // ===========================================================================
  // REMOVE MISSING FILES
  // ===========================================================================

  Future<List<DownloadedMaterialLocal>>
      _removeMissingFiles(
    int userId,

    List<DownloadedMaterialLocal>
        materials,
  ) async {

    final List<DownloadedMaterialLocal>
        valid =
        [];


    for (final DownloadedMaterialLocal
        material in materials) {

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