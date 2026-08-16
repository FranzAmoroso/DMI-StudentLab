import '../../services/api_service.dart';

import '../models/material_cache_local.dart';

import '../repositories/material_cache_repository.dart';


// =============================================================================
// MATERIAL CACHE SOURCE
// =============================================================================

enum MaterialCacheSource {
  backend,
  cache,
}


// =============================================================================
// MATERIAL CACHE RESULT
// =============================================================================

class MaterialCacheResult {
  final List<MaterialCacheLocal> materials;

  final MaterialCacheSource source;

  final bool isOffline;

  final DateTime? syncedAt;

  final String? error;


  const MaterialCacheResult({
    required this.materials,

    required this.source,

    required this.isOffline,

    this.syncedAt,

    this.error,
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


  bool get isEmpty {
    return materials.isEmpty;
  }


  bool get hasData {
    return materials.isNotEmpty;
  }


  bool get hasError {
    return error != null &&
        error!.isNotEmpty;
  }
}


// =============================================================================
// MATERIAL CACHE SERVICE
// =============================================================================

class MaterialCacheService {
  final ApiService _apiService;

  final MaterialCacheRepository
      _repository;


  MaterialCacheService({
    ApiService? apiService,

    MaterialCacheRepository? repository,
  })  : _apiService =
            apiService ??
                ApiService(),

        _repository =
            repository ??
                MaterialCacheRepository();


  // ===========================================================================
  // LOAD GROUP MATERIALS
  // ===========================================================================
  //
  // Strategia:
  //
  // BACKEND DISPONIBILE
  //
  // GET /group_materials/{groupId}
  //            ↓
  // aggiorna SQLite
  //            ↓
  // restituisce dati backend
  //
  //
  // BACKEND NON DISPONIBILE
  //
  // richiesta fallisce
  //       ↓
  // SQLite
  //       ↓
  // restituisce ultima cache conosciuta
  //
  // ===========================================================================

  Future<MaterialCacheResult>
      loadGroupMaterials({
    required int userId,

    required int groupId,
  }) async {
    try {
      final List<Map<String, dynamic>>
          backendMaterials =
          await _apiService
              .getGroupMaterials(
        groupId,
      );


      final DateTime syncTime =
          DateTime.now();


      final List<MaterialCacheLocal>
          materials =
          _convertBackendMaterials(
        backendMaterials:
            backendMaterials,

        userId:
            userId,

        groupId:
            groupId,

        syncTime:
            syncTime,
      );


      await _repository
          .replaceGroupCache(
        userId:
            userId,

        groupId:
            groupId,

        materials:
            materials,
      );


      return MaterialCacheResult(
        materials:
            materials,

        source:
            MaterialCacheSource.backend,

        isOffline:
            false,

        syncedAt:
            syncTime,
      );
    } catch (e) {
      final List<MaterialCacheLocal>
          cached =
          await _repository
              .getByGroup(
        userId:
            userId,

        groupId:
            groupId,
      );


      final DateTime? lastSync =
          await _repository
              .getLastSync(
        userId:
            userId,

        groupId:
            groupId,
      );


      return MaterialCacheResult(
        materials:
            cached,

        source:
            MaterialCacheSource.cache,

        isOffline:
            true,

        syncedAt:
            lastSync,

        error:
            e.toString(),
      );
    }
  }


  // ===========================================================================
  // REFRESH
  // ===========================================================================
  //
  // Questa funzione NON usa fallback.
  //
  // Se il backend fallisce viene lanciata
  // direttamente l'eccezione.
  //
  // Utile per:
  //
  // - pull to refresh
  // - refresh manuale
  // - sincronizzazione esplicita
  //
  // ===========================================================================

  Future<List<MaterialCacheLocal>>
      refreshGroupMaterials({
    required int userId,

    required int groupId,
  }) async {
    final List<Map<String, dynamic>>
        backendMaterials =
        await _apiService
            .getGroupMaterials(
      groupId,
    );


    final DateTime syncTime =
        DateTime.now();


    final List<MaterialCacheLocal>
        materials =
        _convertBackendMaterials(
      backendMaterials:
          backendMaterials,

      userId:
          userId,

      groupId:
          groupId,

      syncTime:
          syncTime,
    );


    await _repository
        .replaceGroupCache(
      userId:
          userId,

      groupId:
          groupId,

      materials:
          materials,
    );


    return materials;
  }


  // ===========================================================================
  // SOLO CACHE DEL GRUPPO
  // ===========================================================================

  Future<List<MaterialCacheLocal>>
      getCachedGroupMaterials({
    required int userId,

    required int groupId,
  }) {
    return _repository
        .getByGroup(
      userId:
          userId,

      groupId:
          groupId,
    );
  }


  // ===========================================================================
  // SINGOLO MATERIALE
  // ===========================================================================

  Future<MaterialCacheLocal?>
      getCachedMaterial({
    required int userId,

    required int materialId,
  }) {
    return _repository
        .getByMaterialId(
      userId:
          userId,

      materialId:
          materialId,
    );
  }


  // ===========================================================================
  // ESISTE IN CACHE
  // ===========================================================================

  Future<bool> exists({
    required int userId,

    required int materialId,
  }) {
    return _repository.exists(
      userId:
          userId,

      materialId:
          materialId,
    );
  }


  // ===========================================================================
  // SAVE MATERIAL
  // ===========================================================================

  Future<void> saveMaterial(
    MaterialCacheLocal material,
  ) {
    return _repository.save(
      material,
    );
  }


  // ===========================================================================
  // REMOVE MATERIAL
  // ===========================================================================

  Future<void> removeMaterial({
    required int userId,

    required int materialId,
  }) {
    return _repository.delete(
      userId:
          userId,

      materialId:
          materialId,
    );
  }


  // ===========================================================================
  // LAST SYNC
  // ===========================================================================

  Future<DateTime?> getLastSync({
    required int userId,

    required int groupId,
  }) {
    return _repository
        .getLastSync(
      userId:
          userId,

      groupId:
          groupId,
    );
  }


  // ===========================================================================
  // COUNT
  // ===========================================================================

  Future<int> countCachedMaterials({
    required int userId,

    required int groupId,
  }) {
    return _repository
        .countByGroup(
      userId:
          userId,

      groupId:
          groupId,
    );
  }


  // ===========================================================================
  // CLEAR GROUP CACHE
  // ===========================================================================

  Future<void> clearGroup({
    required int userId,

    required int groupId,
  }) {
    return _repository
        .deleteGroupCache(
      userId:
          userId,

      groupId:
          groupId,
    );
  }


  // ===========================================================================
  // CLEAR USER CACHE
  // ===========================================================================

  Future<void> clearUser(
    int userId,
  ) {
    return _repository
        .deleteUserCache(
      userId,
    );
  }


  // ===========================================================================
  // CLEAR ALL
  // ===========================================================================

  Future<void> clearAll() {
    return _repository
        .clearAll();
  }


  // ===========================================================================
  // BACKEND -> LOCAL CACHE
  // ===========================================================================

  List<MaterialCacheLocal>
      _convertBackendMaterials({
    required List<Map<String, dynamic>>
        backendMaterials,

    required int userId,

    required int groupId,

    required DateTime syncTime,
  }) {
    final List<MaterialCacheLocal>
        materials =
        [];


    for (final Map<String, dynamic> data
        in backendMaterials) {
      final int? materialId =
          _toNullableInt(
        data['id'],
      );


      // Un materiale senza id server
      // non può essere memorizzato correttamente.
      if (materialId == null) {
        continue;
      }


      final String originalName =
          data['original_name']
                  ?.toString() ??
              'material_$materialId';


      materials.add(
        MaterialCacheLocal(
          materialId:
              materialId,

          userId:
              userId,

          groupId:
              _toNullableInt(
                    data['group_id'],
                  ) ??
                  groupId,

          uploadedBy:
              _toNullableInt(
            data['uploaded_by'],
          ),

          originalName:
              originalName,

          mimeType:
              data['mime_type']
                  ?.toString(),

          size:
              _toNullableInt(
            data['size'],
          ),

          createdAt:
              _toNullableDateTime(
            data['created_at'],
          ),

          syncedAt:
              syncTime,
        ),
      );
    }


    return materials;
  }


  // ===========================================================================
  // INT
  // ===========================================================================

  static int? _toNullableInt(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }


    if (value is int) {
      return value;
    }


    if (value is num) {
      return value.toInt();
    }


    return int.tryParse(
      value.toString(),
    );
  }


  // ===========================================================================
  // DATETIME
  // ===========================================================================

  static DateTime? _toNullableDateTime(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }


    if (value is DateTime) {
      return value;
    }


    final String valueString =
        value.toString();


    if (valueString.isEmpty) {
      return null;
    }


    return DateTime.tryParse(
      valueString,
    );
  }
}