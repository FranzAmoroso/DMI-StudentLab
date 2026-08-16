import 'dart:io';

import '../../services/api_service.dart';

import '../models/downloaded_material_local.dart';

import '../repositories/downloaded_material_repository.dart';

import 'local_file_service.dart';


class MaterialDownloadService {
  final ApiService _apiService;

  final DownloadedMaterialRepository
      _repository;

  final LocalFileService
      _fileService;


  MaterialDownloadService({
    ApiService? apiService,
    DownloadedMaterialRepository? repository,
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
  // DOWNLOAD
  // ===========================================================================

  Future<DownloadedMaterialLocal>
      download({
    required int userId,

    required int materialId,

    required int groupId,

    required String originalName,

    required String? mimeType,

    required int? size,
  }) async {

    // -------------------------------------------------------------------------
    // 1. CONTROLLA SE ESISTE GIÀ
    // -------------------------------------------------------------------------

    final DownloadedMaterialLocal?
        existing =
        await _repository.getMaterial(
      userId:
          userId,

      materialId:
          materialId,
    );


    if (existing != null) {

      final bool fileExists =
          await _fileService.exists(
        existing.localPath,
      );


      if (fileExists) {
        return existing;
      }


      // SQLite dice che esiste,
      // ma il file fisico è stato eliminato.
      await _repository.delete(
        userId:
            userId,

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
    // 3. SALVA FILE NEL FILESYSTEM
    // -------------------------------------------------------------------------

    final String localPath =
        await _fileService
            .saveDownloadedMaterial(
      userId:
          userId,

      groupId:
          groupId,

      fileName:
          originalName,

      bytes:
          bytes,
    );


    // -------------------------------------------------------------------------
    // 4. SALVA METADATI IN SQLITE
    // -------------------------------------------------------------------------

    final DownloadedMaterialLocal material =
        DownloadedMaterialLocal(
      userId:
          userId,

      materialId:
          materialId,

      groupId:
          groupId,

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


  // ===========================================================================
  // È SCARICATO?
  // ===========================================================================

  Future<bool> isDownloaded({
    required int userId,
    required int materialId,
  }) async {

    final DownloadedMaterialLocal?
        material =
        await _repository.getMaterial(
      userId:
          userId,

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
            userId,

        materialId:
            materialId,
      );

      return false;
    }


    return true;
  }


  // ===========================================================================
  // RECUPERA FILE LOCALE
  // ===========================================================================

  Future<DownloadedMaterialLocal?>
      getLocalMaterial({
    required int userId,
    required int materialId,
  }) async {

    final DownloadedMaterialLocal?
        material =
        await _repository.getMaterial(
      userId:
          userId,

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
            userId,

        materialId:
            materialId,
      );

      return null;
    }


    return material;
  }


  // ===========================================================================
  // FILE
  // ===========================================================================

  Future<File?> getFile({
    required int userId,
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


  // ===========================================================================
  // ELIMINA DOWNLOAD LOCALE
  // ===========================================================================

  Future<void> removeDownload({
    required int userId,
    required int materialId,
  }) async {

    final DownloadedMaterialLocal?
        material =
        await _repository.getMaterial(
      userId:
          userId,

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
          userId,

      materialId:
          materialId,
    );
  }


  // ===========================================================================
  // DOWNLOAD DELL'UTENTE
  // ===========================================================================

  Future<List<DownloadedMaterialLocal>>
      getDownloadedMaterials(
    int userId,
  ) async {

    final List<DownloadedMaterialLocal>
        materials =
        await _repository.getByUser(
      userId,
    );


    final List<DownloadedMaterialLocal>
        validMaterials =
        [];


    for (final material
        in materials) {

      final bool exists =
          await _fileService.exists(
        material.localPath,
      );


      if (exists) {

        validMaterials.add(
          material,
        );

      } else {

        await _repository.delete(
          userId:
              userId,

          materialId:
              material.materialId,
        );
      }
    }


    return validMaterials;
  }
}