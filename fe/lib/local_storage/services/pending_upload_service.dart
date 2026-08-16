import 'dart:io';
import 'dart:typed_data';

import '../../services/api_service.dart';

import '../models/pending_upload_local.dart';

import '../repositories/pending_upload_repository.dart';

import 'local_file_service.dart';


// =============================================================================
// PENDING UPLOAD SERVICE
// =============================================================================

class PendingUploadService {
  final ApiService _apiService;

  final PendingUploadRepository _repository;

  final LocalFileService _fileService;


  PendingUploadService({
    ApiService? apiService,
    PendingUploadRepository? repository,
    LocalFileService? fileService,
  })  : _apiService =
            apiService ?? ApiService(),
        _repository =
            repository ?? PendingUploadRepository(),
        _fileService =
            fileService ?? LocalFileService();


  // ===========================================================================
  // CREA DA FILE
  // ===========================================================================

  Future<PendingUploadLocal> createFromFile({
    required int userId,
    required int groupId,
    required String sourcePath,
    required String originalName,
    String? mimeType,
    int? size,
  }) async {
    final String localPath =
        await _fileService.copyToPendingUpload(
      userId: userId,
      groupId: groupId,
      sourcePath: sourcePath,
      preferredFileName: originalName,
    );


    final int? actualSize =
        size ??
        await _fileService.getFileSize(
          localPath,
        );


    final PendingUploadLocal upload =
        PendingUploadLocal(
      userId: userId,
      groupId: groupId,

      localPath: localPath,

      originalName: originalName,

      mimeType: mimeType,

      size: actualSize,

      status:
          PendingUploadStatus.pending,

      createdAt:
          DateTime.now(),

      retryCount: 0,
    );


    final int id =
        await _repository.insert(
      upload,
    );


    return upload.copyWith(
      id: id,
    );
  }


  // ===========================================================================
  // CREA DA BYTES
  // ===========================================================================

  Future<PendingUploadLocal> createFromBytes({
    required int userId,
    required int groupId,
    required String originalName,
    required Uint8List bytes,
    String? mimeType,
  }) async {
    final String localPath =
        await _fileService.savePendingUploadBytes(
      userId: userId,
      groupId: groupId,
      fileName: originalName,
      bytes: bytes,
    );


    final PendingUploadLocal upload =
        PendingUploadLocal(
      userId: userId,
      groupId: groupId,

      localPath: localPath,

      originalName: originalName,

      mimeType: mimeType,

      size: bytes.length,

      status:
          PendingUploadStatus.pending,

      createdAt:
          DateTime.now(),

      retryCount: 0,
    );


    final int id =
        await _repository.insert(
      upload,
    );


    return upload.copyWith(
      id: id,
    );
  }


  // ===========================================================================
  // UPLOAD SINGOLO
  // ===========================================================================

  Future<PendingUploadLocal> upload(
    PendingUploadLocal upload,
  ) async {
    if (upload.id == null) {
      throw ArgumentError(
        'Upload locale senza id.',
      );
    }


    final bool exists =
        await _fileService.exists(
      upload.localPath,
    );


    // -------------------------------------------------------------------------
    // FILE LOCALE NON PIÙ PRESENTE
    // -------------------------------------------------------------------------

    if (!exists) {
      final PendingUploadLocal failed =
          upload.copyWith(
        status:
            PendingUploadStatus.failed,

        errorMessage:
            'Il file locale non esiste più.',

        retryCount:
            upload.retryCount + 1,

        lastAttemptAt:
            DateTime.now(),
      );


      await _repository.update(
        failed,
      );


      return failed;
    }


    // -------------------------------------------------------------------------
    // PASSA A UPLOADING
    // -------------------------------------------------------------------------

    final PendingUploadLocal uploading =
        upload.copyWith(
      status:
          PendingUploadStatus.uploading,

      retryCount:
          upload.retryCount + 1,

      lastAttemptAt:
          DateTime.now(),

      clearErrorMessage:
          true,
    );


    await _repository.update(
      uploading,
    );


    try {
      // -----------------------------------------------------------------------
      // API
      // -----------------------------------------------------------------------

      final Map<String, dynamic> result =
          await _apiService.addGroupMaterial(
        groupId:
            uploading.groupId,

        uploadedBy:
            uploading.userId,

        filePath:
            uploading.localPath,
      );


      final int serverMaterialId =
          _extractServerMaterialId(
        result,
      );


      // -----------------------------------------------------------------------
      // SUCCESS
      // -----------------------------------------------------------------------

      final PendingUploadLocal uploaded =
          uploading.copyWith(
        status:
            PendingUploadStatus.uploaded,

        uploadedAt:
            DateTime.now(),

        serverMaterialId:
            serverMaterialId,

        clearErrorMessage:
            true,
      );


      await _repository.update(
        uploaded,
      );


      return uploaded;
    } catch (e) {
      // -----------------------------------------------------------------------
      // FAILED
      // -----------------------------------------------------------------------

      final PendingUploadLocal failed =
          uploading.copyWith(
        status:
            PendingUploadStatus.failed,

        errorMessage:
            e.toString(),
      );


      await _repository.update(
        failed,
      );


      return failed;
    }
  }


  // ===========================================================================
  // RETRY
  // ===========================================================================

  Future<PendingUploadLocal?> retry(
    int uploadId,
  ) async {
    final PendingUploadLocal? existing =
        await _repository.getById(
      uploadId,
    );


    if (existing == null) {
      return null;
    }


    final PendingUploadLocal pending =
        existing.copyWith(
      status:
          PendingUploadStatus.pending,

      clearErrorMessage:
          true,

      clearUploadedAt:
          true,

      clearServerMaterialId:
          true,
    );


    await _repository.update(
      pending,
    );


    return upload(
      pending,
    );
  }


  // ===========================================================================
  // SINCRONIZZA TUTTI I PENDING
  // ===========================================================================

  Future<List<PendingUploadLocal>> syncWaiting(
    int userId,
  ) async {
    await _repository.resetInterruptedUploads(
      userId,
    );


    final List<PendingUploadLocal> waiting =
        await _repository.getWaitingForSync(
      userId,
    );


    final List<PendingUploadLocal> results =
        [];


    for (final PendingUploadLocal item
        in waiting) {
      final PendingUploadLocal result =
          await upload(
        item,
      );

      results.add(
        result,
      );
    }


    return results;
  }


  // ===========================================================================
  // GET BY ID
  // ===========================================================================

  Future<PendingUploadLocal?> getById(
    int uploadId,
  ) {
    return _repository.getById(
      uploadId,
    );
  }


  // ===========================================================================
  // GET BY USER
  // ===========================================================================

  Future<List<PendingUploadLocal>> getByUser(
    int userId,
  ) {
    return _repository.getByUser(
      userId,
    );
  }


  // ===========================================================================
  // GET BY GROUP
  // ===========================================================================

  Future<List<PendingUploadLocal>> getByGroup({
    required int userId,
    required int groupId,
  }) {
    return _repository.getByGroup(
      userId: userId,
      groupId: groupId,
    );
  }


  // ===========================================================================
  // GET WAITING
  // ===========================================================================

  Future<List<PendingUploadLocal>> getWaiting(
    int userId,
  ) {
    return _repository.getWaitingForSync(
      userId,
    );
  }


  // ===========================================================================
  // GET FAILED
  // ===========================================================================

  Future<List<PendingUploadLocal>> getFailed(
    int userId,
  ) {
    return _repository.getFailed(
      userId,
    );
  }


  // ===========================================================================
  // COUNT WAITING
  // ===========================================================================

  Future<int> countWaiting(
    int userId,
  ) {
    return _repository.countWaiting(
      userId,
    );
  }


  // ===========================================================================
  // REMOVE
  // ===========================================================================

  Future<void> remove(
    int uploadId,
  ) async {
    final PendingUploadLocal? upload =
        await _repository.getById(
      uploadId,
    );


    if (upload == null) {
      return;
    }


    await _fileService.delete(
      upload.localPath,
    );


    await _repository.delete(
      uploadId,
    );
  }


  // ===========================================================================
  // CLEAR UPLOADED
  // ===========================================================================

  Future<int> clearUploaded(
    int userId,
  ) async {
    final List<PendingUploadLocal> uploads =
        await _repository.getByUser(
      userId,
    );


    for (final PendingUploadLocal upload
        in uploads) {
      if (!upload.isUploaded) {
        continue;
      }


      await _fileService.delete(
        upload.localPath,
      );
    }


    return _repository.deleteUploaded(
      userId,
    );
  }


  // ===========================================================================
  // RESET UPLOAD INTERROTTI
  // ===========================================================================

  Future<void> resetInterruptedUploads(
    int userId,
  ) {
    return _repository.resetInterruptedUploads(
      userId,
    );
  }


  // ===========================================================================
  // FILE EXISTS
  // ===========================================================================

  Future<bool> fileExists(
    PendingUploadLocal upload,
  ) {
    return _fileService.exists(
      upload.localPath,
    );
  }


  // ===========================================================================
  // GET FILE
  // ===========================================================================

  Future<File?> getFile(
    PendingUploadLocal upload,
  ) async {
    final bool exists =
        await _fileService.exists(
      upload.localPath,
    );


    if (!exists) {
      return null;
    }


    return File(
      upload.localPath,
    );
  }


  // ===========================================================================
  // SERVER MATERIAL ID
  // ===========================================================================

  int _extractServerMaterialId(
    Map<String, dynamic> result,
  ) {
    final dynamic value =
        result['id'];


    if (value is int) {
      return value;
    }


    if (value is num) {
      return value.toInt();
    }


    final int? parsed =
        int.tryParse(
      value?.toString() ?? '',
    );


    if (parsed != null) {
      return parsed;
    }


    throw StateError(
      'Upload completato ma il backend '
      'non ha restituito un id materiale valido.',
    );
  }
}