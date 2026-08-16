import '../models/material_cache_local.dart';
import '../models/pending_upload_local.dart';

import 'material_cache_service.dart';
import 'pending_upload_service.dart';


// =============================================================================
// MATERIAL SYNC SERVICE
// =============================================================================

class MaterialSyncService {
  final MaterialCacheService
      _cacheService;

  final PendingUploadService
      _pendingUploadService;


  MaterialSyncService({
    MaterialCacheService? cacheService,

    PendingUploadService?
        pendingUploadService,
  })  : _cacheService =
            cacheService ??
                MaterialCacheService(),

        _pendingUploadService =
            pendingUploadService ??
                PendingUploadService();


  // ===========================================================================
  // SINCRONIZZA GRUPPO
  // ===========================================================================
  //
  // Flusso:
  //
  // 1. ripristina upload interrotti
  // 2. prova gli upload pending / failed
  // 3. aggiorna i materiali del gruppo dal backend
  // 4. se backend non disponibile usa la cache
  //
  // ===========================================================================

  Future<GroupMaterialSyncResult>
      syncGroup({
    required int userId,

    required int groupId,
  }) async {
    final List<PendingUploadLocal>
        uploadResults =
        [];


    String? uploadError;


    // -------------------------------------------------------------------------
    // 1. RESET UPLOAD INTERROTTI
    // -------------------------------------------------------------------------

    try {
      await _pendingUploadService
          .resetInterruptedUploads(
        userId,
      );
    } catch (e) {
      uploadError =
          e.toString();
    }


    // -------------------------------------------------------------------------
    // 2. UPLOAD PENDING DEL GRUPPO
    // -------------------------------------------------------------------------

    try {
      final List<PendingUploadLocal>
          waiting =
          await _pendingUploadService
              .getByGroup(
        userId:
            userId,

        groupId:
            groupId,
      );


      for (final PendingUploadLocal upload
          in waiting) {
        if (!upload.isPending &&
            !upload.isFailed) {
          continue;
        }


        final PendingUploadLocal result =
            await _pendingUploadService
                .upload(
          upload,
        );


        uploadResults.add(
          result,
        );
      }
    } catch (e) {
      uploadError =
          e.toString();
    }


    // -------------------------------------------------------------------------
    // 3. MATERIAL CACHE
    // -------------------------------------------------------------------------

    final MaterialCacheResult
        cacheResult =
        await _cacheService
            .loadGroupMaterials(
      userId:
          userId,

      groupId:
          groupId,
    );


    // -------------------------------------------------------------------------
    // 4. RISULTATO
    // -------------------------------------------------------------------------

    return GroupMaterialSyncResult(
      userId:
          userId,

      groupId:
          groupId,

      materials:
          cacheResult.materials,

      uploads:
          uploadResults,

      source:
          cacheResult.source,

      isOffline:
          cacheResult.isOffline,

      syncedAt:
          cacheResult.syncedAt,

      cacheError:
          cacheResult.error,

      uploadError:
          uploadError,
    );
  }


  // ===========================================================================
  // SINCRONIZZA SOLO UPLOAD UTENTE
  // ===========================================================================

  Future<UserUploadSyncResult>
      syncUploads(
    int userId,
  ) async {
    await _pendingUploadService
        .resetInterruptedUploads(
      userId,
    );


    final List<PendingUploadLocal>
        results =
        await _pendingUploadService
            .syncWaiting(
      userId,
    );


    int uploaded =
        0;

    int failed =
        0;


    for (final PendingUploadLocal upload
        in results) {
      if (upload.isUploaded) {
        uploaded++;
      }

      if (upload.isFailed) {
        failed++;
      }
    }


    return UserUploadSyncResult(
      userId:
          userId,

      uploads:
          results,

      uploadedCount:
          uploaded,

      failedCount:
          failed,
    );
  }


  // ===========================================================================
  // REFRESH FORZATO GRUPPO
  // ===========================================================================
  //
  // Nessun fallback alla cache.
  //
  // Se il backend non risponde,
  // viene propagata l'eccezione.
  // ===========================================================================

  Future<List<MaterialCacheLocal>>
      forceRefreshGroup({
    required int userId,

    required int groupId,
  }) {
    return _cacheService
        .refreshGroupMaterials(
      userId:
          userId,

      groupId:
          groupId,
    );
  }


  // ===========================================================================
  // SOLO DATI LOCALI
  // ===========================================================================

  Future<GroupLocalMaterialState>
      getLocalGroupState({
    required int userId,

    required int groupId,
  }) async {
    final List<MaterialCacheLocal>
        cachedMaterials =
        await _cacheService
            .getCachedGroupMaterials(
      userId:
          userId,

      groupId:
          groupId,
    );


    final List<PendingUploadLocal>
        uploads =
        await _pendingUploadService
            .getByGroup(
      userId:
          userId,

      groupId:
          groupId,
    );


    final DateTime? lastSync =
        await _cacheService
            .getLastSync(
      userId:
          userId,

      groupId:
          groupId,
    );


    return GroupLocalMaterialState(
      userId:
          userId,

      groupId:
          groupId,

      materials:
          cachedMaterials,

      uploads:
          uploads,

      lastSync:
          lastSync,
    );
  }


  // ===========================================================================
  // PENDING COUNT
  // ===========================================================================

  Future<int> countWaitingUploads(
    int userId,
  ) {
    return _pendingUploadService
        .countWaiting(
      userId,
    );
  }


  // ===========================================================================
  // RETRY SINGOLO UPLOAD
  // ===========================================================================

  Future<PendingUploadLocal?>
      retryUpload(
    int uploadId,
  ) {
    return _pendingUploadService
        .retry(
      uploadId,
    );
  }


  // ===========================================================================
  // ELIMINA UPLOAD LOCALE
  // ===========================================================================

  Future<void> removeUpload(
    int uploadId,
  ) {
    return _pendingUploadService
        .remove(
      uploadId,
    );
  }


  // ===========================================================================
  // PULISCI STORICO UPLOAD COMPLETATI
  // ===========================================================================

  Future<int> clearUploadedHistory(
    int userId,
  ) {
    return _pendingUploadService
        .clearUploaded(
      userId,
    );
  }


  // ===========================================================================
  // CLEAR CACHE GRUPPO
  // ===========================================================================

  Future<void> clearGroupCache({
    required int userId,

    required int groupId,
  }) {
    return _cacheService.clearGroup(
      userId:
          userId,

      groupId:
          groupId,
    );
  }


  // ===========================================================================
  // CLEAR CACHE UTENTE
  // ===========================================================================

  Future<void> clearUserCache(
    int userId,
  ) {
    return _cacheService
        .clearUser(
      userId,
    );
  }
}


// =============================================================================
// GROUP MATERIAL SYNC RESULT
// =============================================================================

class GroupMaterialSyncResult {
  final int userId;

  final int groupId;

  final List<MaterialCacheLocal>
      materials;

  final List<PendingUploadLocal>
      uploads;

  final MaterialCacheSource
      source;

  final bool isOffline;

  final DateTime? syncedAt;

  final String? cacheError;

  final String? uploadError;


  const GroupMaterialSyncResult({
    required this.userId,

    required this.groupId,

    required this.materials,

    required this.uploads,

    required this.source,

    required this.isOffline,

    this.syncedAt,

    this.cacheError,

    this.uploadError,
  });


  // ===========================================================================
  // HELPERS
  // ===========================================================================

  bool get fromBackend {
    return source ==
        MaterialCacheSource.backend;
  }


  bool get fromCache {
    return source ==
        MaterialCacheSource.cache;
  }


  bool get hasMaterials {
    return materials.isNotEmpty;
  }


  bool get hasUploads {
    return uploads.isNotEmpty;
  }


  bool get hasCacheError {
    return cacheError != null &&
        cacheError!.isNotEmpty;
  }


  bool get hasUploadError {
    return uploadError != null &&
        uploadError!.isNotEmpty;
  }


  bool get hasErrors {
    return hasCacheError ||
        hasUploadError;
  }


  int get uploadedCount {
    return uploads
        .where(
          (
            upload,
          ) =>
              upload.isUploaded,
        )
        .length;
  }


  int get failedUploadCount {
    return uploads
        .where(
          (
            upload,
          ) =>
              upload.isFailed,
        )
        .length;
  }
}


// =============================================================================
// USER UPLOAD SYNC RESULT
// =============================================================================

class UserUploadSyncResult {
  final int userId;

  final List<PendingUploadLocal>
      uploads;

  final int uploadedCount;

  final int failedCount;


  const UserUploadSyncResult({
    required this.userId,

    required this.uploads,

    required this.uploadedCount,

    required this.failedCount,
  });


  bool get hasUploads {
    return uploads.isNotEmpty;
  }


  bool get allSucceeded {
    return uploads.isNotEmpty &&
        failedCount ==
            0;
  }


  bool get hasFailures {
    return failedCount >
        0;
  }
}


// =============================================================================
// GROUP LOCAL MATERIAL STATE
// =============================================================================

class GroupLocalMaterialState {
  final int userId;

  final int groupId;

  final List<MaterialCacheLocal>
      materials;

  final List<PendingUploadLocal>
      uploads;

  final DateTime? lastSync;


  const GroupLocalMaterialState({
    required this.userId,

    required this.groupId,

    required this.materials,

    required this.uploads,

    this.lastSync,
  });


  // ===========================================================================
  // HELPERS
  // ===========================================================================

  bool get hasCachedMaterials {
    return materials.isNotEmpty;
  }


  bool get hasUploads {
    return uploads.isNotEmpty;
  }


  bool get hasPendingUploads {
    return uploads.any(
      (
        upload,
      ) =>
          upload.isPending ||
          upload.isUploading,
    );
  }


  bool get hasFailedUploads {
    return uploads.any(
      (
        upload,
      ) =>
          upload.isFailed,
    );
  }


  int get pendingUploadCount {
    return uploads
        .where(
          (
            upload,
          ) =>
              upload.isPending ||
              upload.isUploading,
        )
        .length;
  }


  int get failedUploadCount {
    return uploads
        .where(
          (
            upload,
          ) =>
              upload.isFailed,
        )
        .length;
  }
}