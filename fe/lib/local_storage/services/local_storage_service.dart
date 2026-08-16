import 'dart:io';

import '../database/app_database.dart';

import '../repositories/downloaded_material_repository.dart';
import '../repositories/material_cache_repository.dart';
import '../repositories/pending_upload_repository.dart';

import 'local_file_service.dart';


// =============================================================================
// LOCAL STORAGE SERVICE
// =============================================================================

class LocalStorageService {
  final AppDatabase _database;

  final DownloadedMaterialRepository
      _downloadedRepository;

  final PendingUploadRepository
      _pendingUploadRepository;

  final MaterialCacheRepository
      _materialCacheRepository;

  final LocalFileService
      _fileService;


  LocalStorageService({
    AppDatabase? database,

    DownloadedMaterialRepository?
        downloadedRepository,

    PendingUploadRepository?
        pendingUploadRepository,

    MaterialCacheRepository?
        materialCacheRepository,

    LocalFileService?
        fileService,
  })  : _database =
            database ??
                AppDatabase.instance,

        _downloadedRepository =
            downloadedRepository ??
                DownloadedMaterialRepository(),

        _pendingUploadRepository =
            pendingUploadRepository ??
                PendingUploadRepository(),

        _materialCacheRepository =
            materialCacheRepository ??
                MaterialCacheRepository(),

        _fileService =
            fileService ??
                LocalFileService();


  // ===========================================================================
  // INITIALIZE
  // ===========================================================================
  //
  // Forza l'apertura del database.
  //
  // Inoltre ripristina eventuali upload rimasti
  // nello stato "uploading" dopo una chiusura improvvisa dell'app.
  // ===========================================================================

  Future<void> initialize({
    int? userId,
  }) async {
    await _database.database;

    if (userId != null) {
      await _pendingUploadRepository
          .resetInterruptedUploads(
        userId,
      );
    }
  }


  // ===========================================================================
  // PREPARA SESSIONE UTENTE
  // ===========================================================================
  //
  // Da richiamare dopo login oppure dopo il ripristino
  // della sessione tramite token.
  // ===========================================================================

  Future<void> prepareUserSession(
    int userId,
  ) async {
    await initialize(
      userId:
          userId,
    );

    await cleanupMissingDownloadedFiles(
      userId,
    );

    await cleanupMissingPendingUploadFiles(
      userId,
    );
  }


  // ===========================================================================
  // CLEANUP DOWNLOAD MANCANTI
  // ===========================================================================
  //
  // Se SQLite contiene un record di download,
  // ma il file è stato eliminato dal filesystem,
  // rimuoviamo il record obsoleto.
  // ===========================================================================

  Future<int> cleanupMissingDownloadedFiles(
    int userId,
  ) async {
    final materials =
        await _downloadedRepository
            .getByUser(
      userId,
    );

    int removed =
        0;

    for (final material
        in materials) {
      final bool exists =
          await _fileService.exists(
        material.localPath,
      );

      if (exists) {
        continue;
      }

      await _downloadedRepository.delete(
        userId:
            userId,

        materialId:
            material.materialId,
      );

      removed++;
    }

    return removed;
  }


  // ===========================================================================
  // CLEANUP PENDING UPLOAD MANCANTI
  // ===========================================================================
  //
  // Un upload pending/failed non è più valido
  // se il file locale non esiste più.
  //
  // In questo caso rimuoviamo il record SQLite.
  // ===========================================================================

  Future<int> cleanupMissingPendingUploadFiles(
    int userId,
  ) async {
    final uploads =
        await _pendingUploadRepository
            .getByUser(
      userId,
    );

    int removed =
        0;

    for (final upload
        in uploads) {
      if (upload.isUploaded) {
        continue;
      }

      final File file =
          File(
        upload.localPath,
      );

      final bool exists =
          await file.exists();

      if (exists) {
        continue;
      }

      if (upload.id != null) {
        await _pendingUploadRepository.delete(
          upload.id!,
        );

        removed++;
      }
    }

    return removed;
  }


  // ===========================================================================
  // CLEAR CACHE MATERIALI
  // ===========================================================================
  //
  // Cancella soltanto i metadati cache.
  //
  // NON elimina i file scaricati.
  // NON elimina gli upload pending.
  // ===========================================================================

  Future<void> clearMaterialCache(
    int userId,
  ) async {
    await _materialCacheRepository
        .deleteUserCache(
      userId,
    );
  }


  // ===========================================================================
  // CLEAR CACHE GRUPPO
  // ===========================================================================

  Future<void> clearGroupMaterialCache({
    required int userId,
    required int groupId,
  }) async {
    await _materialCacheRepository
        .deleteGroupCache(
      userId:
          userId,

      groupId:
          groupId,
    );
  }


  // ===========================================================================
  // REMOVE DOWNLOADED MATERIALS
  // ===========================================================================
  //
  // Cancella sia i file fisici sia i record SQLite.
  // ===========================================================================

  Future<int> removeDownloadedMaterials(
    int userId,
  ) async {
    final materials =
        await _downloadedRepository
            .getByUser(
      userId,
    );

    int removed =
        0;

    for (final material
        in materials) {
      try {
        await _fileService.delete(
          material.localPath,
        );
      } finally {
        await _downloadedRepository.delete(
          userId:
              userId,

          materialId:
              material.materialId,
        );
      }

      removed++;
    }

    return removed;
  }


  // ===========================================================================
  // REMOVE DOWNLOADED MATERIALS BY GROUP
  // ===========================================================================
  //
  // Per ora il repository dei download espone getByUser.
  //
  // Filtriamo qui per groupId.
  // ===========================================================================

  Future<int> removeDownloadedMaterialsByGroup({
    required int userId,
    required int groupId,
  }) async {
    final materials =
        await _downloadedRepository
            .getByUser(
      userId,
    );

    int removed =
        0;

    for (final material
        in materials) {
      if (material.groupId !=
          groupId) {
        continue;
      }

      try {
        await _fileService.delete(
          material.localPath,
        );
      } finally {
        await _downloadedRepository.delete(
          userId:
              userId,

          materialId:
              material.materialId,
        );
      }

      removed++;
    }

    return removed;
  }


  // ===========================================================================
  // REMOVE PENDING UPLOADS
  // ===========================================================================
  //
  // Elimina eventuali copie locali degli upload
  // e rimuove i relativi record SQLite.
  //
  // Per sicurezza NON tocchiamo i record uploaded:
  // potrebbero essere utili come storico di sincronizzazione.
  // ===========================================================================

  Future<int> removePendingUploads(
    int userId,
  ) async {
    final uploads =
        await _pendingUploadRepository
            .getByUser(
      userId,
    );

    int removed =
        0;

    for (final upload
        in uploads) {
      if (upload.isUploaded) {
        continue;
      }

      try {
        await _fileService.delete(
          upload.localPath,
        );
      } finally {
        if (upload.id != null) {
          await _pendingUploadRepository.delete(
            upload.id!,
          );

          removed++;
        }
      }
    }

    return removed;
  }


  // ===========================================================================
  // REMOVE COMPLETED UPLOAD HISTORY
  // ===========================================================================
  //
  // Elimina soltanto i record SQLite degli upload completati.
  // ===========================================================================

  Future<int> clearUploadedHistory(
    int userId,
  ) async {
    return _pendingUploadRepository
        .deleteUploaded(
      userId,
    );
  }


  // ===========================================================================
  // LOGOUT CLEANUP
  // ===========================================================================
  //
  // Scelta intenzionale:
  //
  // - svuotiamo la CACHE;
  // - resettiamo eventuali upload interrotti;
  // - NON cancelliamo automaticamente file scaricati;
  // - NON cancelliamo pending upload;
  //
  // Perché i dati sono separati da user_id e possono essere
  // riutilizzati quando lo stesso utente effettua nuovamente login.
  // ===========================================================================

  Future<void> onLogout(
    int userId,
  ) async {
    await _materialCacheRepository
        .deleteUserCache(
      userId,
    );

    await _pendingUploadRepository
        .resetInterruptedUploads(
      userId,
    );
  }


  // ===========================================================================
  // CLEAR USER LOCAL DATA
  // ===========================================================================
  //
  // Questa è l'operazione distruttiva.
  //
  // Da usare per:
  // - "Cancella dati offline"
  // - rimozione account dal dispositivo
  // - reset manuale dell'utente
  //
  // Elimina:
  // - download fisici
  // - pending upload fisici
  // - cache
  // - storico upload
  // ===========================================================================

  Future<void> clearUserLocalData(
    int userId,
  ) async {
    await removeDownloadedMaterials(
      userId,
    );

    final uploads =
        await _pendingUploadRepository
            .getByUser(
      userId,
    );

    for (final upload
        in uploads) {
      try {
        await _fileService.delete(
          upload.localPath,
        );
      } finally {
        if (upload.id != null) {
          await _pendingUploadRepository.delete(
            upload.id!,
          );
        }
      }
    }

    await _materialCacheRepository
        .deleteUserCache(
      userId,
    );
  }


  // ===========================================================================
  // STATISTICHE LOCALI
  // ===========================================================================

  Future<LocalStorageStats> getStats(
    int userId,
  ) async {
    final downloads =
        await _downloadedRepository
            .getByUser(
      userId,
    );

    final uploads =
        await _pendingUploadRepository
            .getByUser(
      userId,
    );

    final cachedMaterials =
        await _materialCacheRepository
            .getByUser(
      userId,
    );

    int downloadedBytes =
        0;

    for (final material
        in downloads) {
      downloadedBytes +=
          material.size ??
              0;
    }

    int pendingBytes =
        0;

    int pendingCount =
        0;

    int failedCount =
        0;

    for (final upload
        in uploads) {
      if (upload.isPending ||
          upload.isUploading) {
        pendingCount++;

        pendingBytes +=
            upload.size ??
                0;
      }

      if (upload.isFailed) {
        failedCount++;
      }
    }

    return LocalStorageStats(
      downloadedCount:
          downloads.length,

      downloadedBytes:
          downloadedBytes,

      cachedMaterialCount:
          cachedMaterials.length,

      pendingUploadCount:
          pendingCount,

      pendingUploadBytes:
          pendingBytes,

      failedUploadCount:
          failedCount,
    );
  }


  // ===========================================================================
  // CLOSE
  // ===========================================================================

  Future<void> close() async {
    await _database.close();
  }
}


// =============================================================================
// LOCAL STORAGE STATS
// =============================================================================

class LocalStorageStats {
  final int downloadedCount;

  final int downloadedBytes;

  final int cachedMaterialCount;

  final int pendingUploadCount;

  final int pendingUploadBytes;

  final int failedUploadCount;


  const LocalStorageStats({
    required this.downloadedCount,

    required this.downloadedBytes,

    required this.cachedMaterialCount,

    required this.pendingUploadCount,

    required this.pendingUploadBytes,

    required this.failedUploadCount,
  });


  // ===========================================================================
  // HELPERS
  // ===========================================================================

  bool get hasDownloads {
    return downloadedCount > 0;
  }


  bool get hasPendingUploads {
    return pendingUploadCount > 0;
  }


  bool get hasFailedUploads {
    return failedUploadCount > 0;
  }


  int get totalTrackedItems {
    return downloadedCount +
        cachedMaterialCount +
        pendingUploadCount +
        failedUploadCount;
  }


  double get downloadedMegabytes {
    return downloadedBytes /
        (1024 * 1024);
  }


  double get pendingMegabytes {
    return pendingUploadBytes /
        (1024 * 1024);
  }
}