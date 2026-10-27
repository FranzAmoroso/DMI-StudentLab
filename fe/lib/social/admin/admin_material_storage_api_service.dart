import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../services/auth_session.dart';
import '../../services/user_facing_error.dart';

class AdminMaterialStorageApiService {
  static const String _baseUrl =
      'https://dmi-student-lab.vercel.app';

  Map<String, String> get _headers {
    final String? token =
        AuthSession.instance.accessToken;

    if (token == null || token.trim().isEmpty) {
      throw StateError(
        'Sessione amministrativa non disponibile.',
      );
    }

    return <String, String>{
      'Authorization': 'Bearer ${token.trim()}',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Uri _uri(
    String path, {
    Map<String, String>? query,
  }) {
    return Uri.parse('$_baseUrl$path').replace(
      queryParameters:
          query == null || query.isEmpty
              ? null
              : query,
    );
  }

  /// Pubblica un file caricato dall'admin: destinazione 'dispense' o
  /// 'drive_only', percorso, destinatari ed eventuale richiesta da chiudere.
  Future<Map<String, dynamic>> publishAdminUpload({
    required int requestId,
    required String destination,
    required List<String> pathSegments,
    required String audienceType,
    int? audienceId,
    String? title,
    int? answerRequestId,
    String? answerMessage,
    bool allowDriveDuplicate = false,
  }) async {
    final response = await http.post(
      _uri('/admin/material-storage/uploads/$requestId/publish'),
      headers: _headers,
      body: jsonEncode(<String, dynamic>{
        'destination': destination,
        'path_segments': pathSegments,
        'audience_type': audienceType,
        if (audienceId != null) 'audience_id': audienceId,
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        if (answerRequestId != null) 'answer_request_id': answerRequestId,
        if (answerMessage != null && answerMessage.trim().isNotEmpty) 'answer_message': answerMessage.trim(),
        'allow_drive_duplicate': allowDriveDuplicate,
      }),
    );
    return _map(response, 'Pubblicazione non riuscita');
  }

  Future<Map<String, dynamic>> getOverview() async {
    final http.Response response = await http.get(
      _uri('/admin/material-storage/overview'),
      headers: _headers,
    );
    return _map(response, 'Errore caricamento storage');
  }

  Future<Map<String, dynamic>> getDriveStatus() async {
    final response = await http.get(_uri('/admin/material-storage/drive/status'),
      headers: _headers);
    return _map(response, 'Impossibile leggere lo stato di Google Drive');
  }

  Future<Map<String, dynamic>> getDriveTree([String? folderId, String? pageToken]) async {
    final response = await http.get(_uri('/admin/material-storage/drive/tree',
      query: {if (folderId != null) 'folder_id': folderId,
        if (pageToken != null) 'page_token': pageToken}), headers: _headers);
    return _map(response, 'Impossibile leggere i file della cartella Drive');
  }

  Future<List<Map<String, dynamic>>> getDriveImportOptions() async {
    final response = await http.get(_uri('/admin/material-storage/drive/import-options'),
      headers: _headers);
    return _list(response, 'Impossibile caricare le materie del catalogo');
  }

  Future<Map<String, dynamic>> getCatalogSnapshot() async {
    final response = await http.get(_uri('/admin/material-storage/catalog/draft'),
      headers: _headers);
    return _map(response, 'Impossibile leggere la bozza');
  }

  Future<Map<String, dynamic>> stageCatalogFolder({required int subjectId,
      required List<String> pathSegments}) async => _map(await http.post(
        _uri('/admin/material-storage/catalog/folders'), headers: _headers,
        body: jsonEncode({'subject_id': subjectId, 'path_segments': pathSegments})),
      'Impossibile salvare la cartella nella bozza');

  Future<Map<String, dynamic>> stageDriveImport({required String fileId,
      required int subjectId, required List<String> pathSegments,
      required String audienceType, int? audienceId,
      bool allowDuplicate = false}) async => _map(await http.post(
        _uri('/admin/material-storage/catalog/import'), headers: _headers,
        body: jsonEncode({'file_id': fileId, 'subject_id': subjectId,
          'path_segments': pathSegments, 'audience_type': audienceType,
          'audience_id': audienceId, 'allow_duplicate': allowDuplicate})),
      'Impossibile aggiungere il file alla bozza');

  Future<Map<String, dynamic>> stageCatalogFile({required int materialId,
      required int subjectId, required List<String> pathSegments,
      required String visibilityState, required String audienceType,
      int? audienceId}) async {
    final response = await http.put(_uri('/admin/material-storage/catalog/draft/$materialId'),
      headers: _headers, body: jsonEncode({
        'subject_id': subjectId, 'path_segments': pathSegments,
        'visibility_state': visibilityState, 'audience_type': audienceType,
        'audience_id': audienceId,
      }));
    return _map(response, 'Impossibile salvare la bozza');
  }

  Future<Map<String, dynamic>> discardCatalogDraft() async => _map(
      await http.delete(_uri('/admin/material-storage/catalog/draft'), headers: _headers),
      'Impossibile scartare la bozza');

  Future<Map<String, dynamic>> publishCatalogDraft() async => _map(
      await http.post(_uri('/admin/material-storage/catalog/publish'), headers: _headers),
      'Impossibile pubblicare la struttura');

  Future<Map<String, dynamic>> previewCatalog({int? userId}) async => _map(
      await http.get(_uri('/admin/material-storage/catalog/preview', query: {
        if (userId != null) 'user_id': '$userId',
      }), headers: _headers), 'Impossibile caricare l’anteprima');

  Future<Map<String, dynamic>> importDriveFile({required String fileId,
      required int subjectId, required String audienceType, int? audienceId}) async {
    final response = await http.post(_uri('/admin/material-storage/drive/import'),
      headers: _headers, body: jsonEncode({'file_id': fileId,
        'subject_id': subjectId, 'audience_type': audienceType,
        'audience_id': audienceId}));
    return _map(response, 'Impossibile registrare il file nel catalogo');
  }

  Future<Map<String, dynamic>> previewPublicDrive(int materialId,
      {List<String>? path}) async {
    final response = await http.post(
      _uri('/admin/material-storage/public/$materialId/drive-preview'),
      headers: _headers, body: jsonEncode({'path': path}));
    return _map(response, 'Impossibile controllare le cartelle Drive');
  }

  Future<Uint8List> downloadDriveFilePreview(String fileId) async {
    final response = await http.get(_uri(
      '/admin/material-storage/drive/file/${Uri.encodeComponent(fileId)}/preview'),
      headers: _headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw UserFacingError(friendlyHttpMessage(response, 'Anteprima Drive non disponibile'));
    }
    return response.bodyBytes;
  }

  Future<Uint8List> downloadPublicMaterialPreview(int materialId) async {
    final response = await http.get(_uri('/admin/public_materials/$materialId/file'),
      headers: _headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw UserFacingError(friendlyHttpMessage(response, 'File non disponibile'));
    }
    return response.bodyBytes;
  }

  Future<Map<String, dynamic>> copyPublicToDrive(int materialId,
      {List<String>? path, bool allowDuplicate = false}) async {
    final response = await http.post(
      _uri('/admin/material-storage/public/$materialId/drive-copy'),
      headers: _headers,
      body: jsonEncode({'path': path, 'allow_duplicate': allowDuplicate}));
    return _map(response, 'Impossibile copiare il materiale su Google Drive');
  }

  Future<Map<String, dynamic>> deletePublicDriveCopy(int materialId) async {
    final response = await http.delete(
      _uri('/admin/material-storage/public/$materialId/drive-copy',
        query: const {'confirmation': 'ELIMINA'}), headers: _headers);
    return _map(response, 'Impossibile eliminare la copia Drive');
  }

  Future<List<Map<String, dynamic>>> getItems({
    String? source,
    String? status,
  }) async {
    final Map<String, String> query = <String, String>{};

    if (source != null && source.trim().isNotEmpty) {
      query['source'] = source.trim();
    }

    if (status != null && status.trim().isNotEmpty) {
      query['status'] = status.trim();
    }

    final http.Response response = await http.get(
      _uri(
        '/admin/material-storage/items',
        query: query,
      ),
      headers: _headers,
    );

    return _list(response, 'Errore caricamento materiali');
  }

  Future<Map<String, dynamic>> setPublicVisibility({
    required int materialId,
    required String state,
  }) async {
    final response = await http.patch(
      _uri('/admin/material-storage/public/$materialId/visibility'),
      headers: _headers,
      body: jsonEncode(<String, dynamic>{'state': state}),
    );
    return _map(response, 'Impossibile cambiare la visibilità');
  }

  Future<Map<String, dynamic>> setPublicAudience({
    required int materialId, required String audienceType, int? audienceId,
  }) async {
    final response = await http.patch(
      _uri('/admin/material-storage/public/$materialId/audience'),
      headers: _headers,
      body: jsonEncode(<String, dynamic>{
        'audience_type': audienceType,
        'audience_id': audienceId,
      }),
    );
    return _map(response, 'Impossibile modificare i destinatari');
  }

  Future<Map<String, dynamic>> placePublicFile({
    required int materialId,
    required int subjectId,
    required List<String> pathSegments,
  }) async {
    final response = await http.patch(
      _uri('/admin/material-storage/public/$materialId/placement'),
      headers: _headers,
      body: jsonEncode(<String, dynamic>{
        'subject_id': subjectId,
        'path_segments': pathSegments,
      }),
    );
    return _map(response, 'Impossibile modificare il percorso');
  }

  Future<Map<String, dynamic>> movePublicFolder({
    required int sourceSubjectId,
    required List<String> sourcePath,
    required int destinationSubjectId,
    required List<String> destinationPath,
  }) async {
    final response = await http.post(_uri('/admin/material-storage/folders/move'),
      headers: _headers,
      body: jsonEncode(<String, dynamic>{
        'source_subject_id': sourceSubjectId,
        'source_path': sourcePath,
        'destination_subject_id': destinationSubjectId,
        'destination_path': destinationPath,
      }),
    );
    return _map(response, 'Impossibile spostare la cartella');
  }

  Future<Map<String, dynamic>> rename({
    required String source,
    required int materialId,
    required String displayName,
  }) async {
    final http.Response response = await http.patch(
      _uri(
        '/admin/material-storage/'
        '$source/$materialId/display-name',
      ),
      headers: _headers,
      body: jsonEncode(
        <String, dynamic>{
          'display_name': displayName.trim(),
        },
      ),
    );

    return _map(response, 'Errore modifica nome');
  }

  Future<Map<String, dynamic>> retire({
    required String source,
    required int materialId,
    required String reason,
  }) async {
    final http.Response response = await http.post(
      _uri(
        '/admin/material-storage/'
        '$source/$materialId/retire',
      ),
      headers: _headers,
      body: jsonEncode(
        <String, dynamic>{
          'reason': reason.trim(),
        },
      ),
    );

    return _map(response, 'Errore ritiro materiale');
  }

  Future<Map<String, dynamic>> deleteBlob({
    required String source,
    required int materialId,
  }) async {
    final http.Response response = await http.post(
      _uri(
        '/admin/material-storage/'
        '$source/$materialId/delete-blob',
      ),
      headers: _headers,
      body: jsonEncode(
        <String, dynamic>{
          'confirmation': 'ELIMINA',
        },
      ),
    );

    return _map(response, 'Errore eliminazione file');
  }

  Future<Map<String, dynamic>> getCleanupDryRun() async {
    final http.Response response = await http.get(
      _uri('/admin/material-storage/cleanup/dry-run'),
      headers: _headers,
    );
    return _map(response, 'Errore analisi pulizia');
  }

  Future<Map<String, dynamic>> executeCleanup({
    bool rejectedPublications = true,
    bool removedMaterials = true,
    bool orphanBlobs = false,
    bool temporaryTransfers = false,
  }) async {
    final http.Response response = await http.post(
      _uri('/admin/material-storage/cleanup/execute'),
      headers: _headers,
      body: jsonEncode(
        <String, dynamic>{
          'confirmation': 'ELIMINA',
          'rejected_publications': rejectedPublications,
          'removed_materials': removedMaterials,
          'orphan_blobs': orphanBlobs,
          'temporary_transfers': temporaryTransfers,
        },
      ),
    );

    return _map(response, 'Errore pulizia storage');
  }

  Map<String, dynamic> _map(
    http.Response response,
    String fallback,
  ) {
    final dynamic decoded = _decode(response);
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      throw UserFacingError('$fallback. Risposta inattesa dal server: riprova tra poco.');
    }
    throw UserFacingError(friendlyHttpMessage(response, fallback), status: response.statusCode);
  }

  List<Map<String, dynamic>> _list(
    http.Response response,
    String fallback,
  ) {
    final dynamic decoded = _decode(response);
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        decoded is List) {
      return decoded
          .whereType<Map>()
          .map(
            (Map<dynamic, dynamic> value) =>
                Map<String, dynamic>.from(value),
          )
          .toList();
    }
    throw UserFacingError(friendlyHttpMessage(response, fallback), status: response.statusCode);
  }

  dynamic _decode(http.Response response) {
    if (response.bodyBytes.isEmpty) return <String, dynamic>{};
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // v26: correzioni della struttura, verifica Drive e registro diagnostico
  // ---------------------------------------------------------------------------

  /// Annulla una sola voce della bozza: kind = material | import | folder.
  Future<Map<String, dynamic>> discardCatalogDraftItem(String kind, int id) async => _map(
      await http.delete(_uri('/admin/material-storage/catalog/draft/item/$kind/$id'), headers: _headers),
      'Modifica non annullata');

  /// «Togli dalla struttura»: i file restano su Drive e si possono ripristinare.
  Future<Map<String, dynamic>> removeFromStructure({
    List<int>? materialIds,
    int? subjectId,
    List<String>? pathSegments,
    bool foldersOnly = false,
  }) async =>
      _map(
          await http.post(_uri('/admin/material-storage/catalog/structure/remove'),
              headers: _headers,
              body: jsonEncode(<String, dynamic>{
                if (materialIds != null) 'material_ids': materialIds,
                if (subjectId != null) 'subject_id': subjectId,
                if (pathSegments != null) 'path_segments': pathSegments,
                'folders_only': foldersOnly,
              })),
          'Non è stato possibile togliere dalla struttura');

  Future<Map<String, dynamic>> restoreToStructure(int materialId) async => _map(
      await http.post(_uri('/admin/material-storage/catalog/structure/restore/$materialId'),
          headers: _headers),
      'Ripristino non riuscito');

  /// «Elimina da Drive»: [confirmation] deve essere la parola scritta dall'admin.
  Future<Map<String, dynamic>> deleteFromDrive(List<int> materialIds, String confirmation) async => _map(
      await http.post(_uri('/admin/material-storage/catalog/structure/delete-drive'),
          headers: _headers,
          body: jsonEncode(<String, dynamic>{'material_ids': materialIds, 'confirmation': confirmation})),
      'Eliminazione da Drive non riuscita');

  /// Controlli del collegamento Drive: {ok, checks: [{label, ok, message, suggestion, code}]}.
  Future<Map<String, dynamic>> diagnoseDrive() async => _map(
      await http.get(_uri('/admin/material-storage/drive/diagnose'), headers: _headers)
          .timeout(const Duration(seconds: 60)),
      'Verifica di Drive non riuscita');

  /// Registro diagnostico come testo (da salvare in un file).
  Future<Uint8List> downloadDiagnosticLog({int days = 7}) async {
    final response = await http.get(
        _uri('/admin/material-storage/diagnostics/log', query: <String, String>{'days': '$days'}),
        headers: _headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw UserFacingError(friendlyHttpMessage(response, 'Registro non disponibile'),
          status: response.statusCode);
    }
    return response.bodyBytes;
  }

  Future<Map<String, dynamic>> diagnosticSummary({int days = 7}) async => _map(
      await http.get(_uri('/admin/material-storage/diagnostics/summary', query: <String, String>{'days': '$days'}),
          headers: _headers),
      'Riepilogo non disponibile');

  // ---------------------------------------------------------------------------
  // v27: doppioni e aggiunte in attesa della copia su Drive
  // ---------------------------------------------------------------------------

  /// Gruppi di file identici ancora nella struttura: {groups: [{files: [...]}]}.
  Future<Map<String, dynamic>> listCatalogDuplicates() async => _map(
      await http.get(_uri('/admin/material-storage/catalog/duplicates'), headers: _headers),
      'Elenco dei doppioni non disponibile');

  /// Ricorda dove mettere nella struttura i file che stanno arrivando su Drive.
  /// [kind] = 'transfer' (file dal PC: items = [{job_id, path_segments}])
  /// oppure 'mega' (copia MEGA: megaJobId, basePath, skipFirst).
  Future<Map<String, dynamic>> createCatalogIntent({
    required String kind,
    required int subjectId,
    required String audienceType,
    int? audienceId,
    List<Map<String, dynamic>>? items,
    String? megaJobId,
    List<String>? basePath,
    bool skipFirst = false,
  }) async =>
      _map(
          await http.post(_uri('/admin/material-storage/catalog/intents'),
              headers: _headers,
              body: jsonEncode(<String, dynamic>{
                'kind': kind,
                'subject_id': subjectId,
                'audience_type': audienceType,
                if (audienceId != null) 'audience_id': audienceId,
                if (items != null) 'items': items,
                if (megaJobId != null) 'mega_job_id': megaJobId,
                if (basePath != null) 'base_path': basePath,
                'skip_first': skipFirst,
              })),
          'Non è stato possibile prenotare l’aggiunta alla struttura');

  /// Aggiunge alla bozza i file arrivati su Drive: {staged, waiting, conflicts, skipped}.
  Future<Map<String, dynamic>> processCatalogIntents() async => _map(
      await http.post(_uri('/admin/material-storage/catalog/intents/process'), headers: _headers)
          .timeout(const Duration(seconds: 90)),
      'Controllo dei file in arrivo non riuscito');

  /// v29: file identici nella bozza prima di pubblicare: {groups: [{files: [...]}]}.
  Future<Map<String, dynamic>> checkCatalogDraft() async => _map(
      await http.get(_uri('/admin/material-storage/catalog/draft/check'), headers: _headers)
          .timeout(const Duration(seconds: 90)),
      'Controllo della bozza non riuscito');

  // ---------------------------------------------------------------------------
  // v30: partenza delle Dispense per gli ospiti e materie doppie
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getGuestEntry() async => _map(
      await http.get(_uri('/admin/material-storage/catalog/settings/guest-entry'), headers: _headers),
      'Impostazione non disponibile');

  Future<Map<String, dynamic>> setGuestEntry({
    required String level,
    String? university,
    String? department,
    String? course,
  }) async =>
      _map(
          await http.put(_uri('/admin/material-storage/catalog/settings/guest-entry'),
              headers: _headers,
              body: jsonEncode(<String, dynamic>{
                'level': level,
                'university': university,
                'department': department,
                'course': course,
              })),
          'Impostazione non salvata');

  /// {items: [{duplicate, suggested, options, main_course, other_course, course_code, score}]}
  Future<Map<String, dynamic>> subjectDuplicates() async => _map(
      await http.get(_uri('/admin/material-storage/subjects/duplicates'), headers: _headers)
          .timeout(const Duration(seconds: 90)),
      'Elenco delle materie doppie non disponibile');

  /// [pairs]: [{from_id, into_id}] (into_id null = solo disattiva). Conferma scritta: UNISCI.
  Future<Map<String, dynamic>> mergeSubjects(List<Map<String, dynamic>> pairs, String confirmation) async => _map(
      await http.post(_uri('/admin/material-storage/subjects/merge'),
          headers: _headers, body: jsonEncode(<String, dynamic>{'pairs': pairs, 'confirmation': confirmation}))
          .timeout(const Duration(seconds: 120)),
      'Unione delle materie non riuscita');
}
