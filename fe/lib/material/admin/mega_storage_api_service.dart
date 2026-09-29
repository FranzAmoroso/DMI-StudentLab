import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:fe/services/api_service.dart';
import '../../social/admin/admin_material_storage_api_service.dart';
import 'catalog_source.dart';
import 'package:fe/services/auth_session.dart';

/// Servizio MEGA non disponibile o non configurato.
class MegaNotAvailable implements Exception {
  final String message;
  const MegaNotAvailable([this.message = 'MEGA non è ancora collegato a StudentLab.']);
  @override
  String toString() => message;
}

/// Chiamate admin per la sorgente MEGA. Stesse forme dati delle chiamate Drive
/// (AdminMaterialStorageApiService), così la pagina del catalogo le usa allo stesso modo.
///
/// Contratto (tutti solo admin/creator, vedi CATALOGO_MEGA_v25.md):
///   GET  /admin/material-storage/mega/status
///   GET  /admin/material-storage/mega/tree?folder_id=&page_token=
///   GET  /admin/material-storage/mega/file/{id}/preview
///   POST /admin/material-storage/mega/connect      {email, password, second_factor_code, root_folder}
///   POST /admin/material-storage/mega/verify
///   POST /admin/material-storage/mega/disconnect
///   POST /admin/material-storage/catalog/mega-import  (come l'import da Drive, con file_id MEGA)
/// Finché il server non li ha, rispondono 404/501 e qui diventano [MegaNotAvailable]:
/// la pagina mostra "MEGA non collegato", mai dati inventati.
class MegaStorageApiService {
  final String _base;

  MegaStorageApiService() : _base = ApiService().baseUrl;

  Map<String, String> get _headers {
    final String? token = AuthSession.instance.accessToken;
    if (token == null || token.trim().isEmpty) {
      throw StateError('Sessione amministrativa non disponibile.');
    }
    return <String, String>{
      'Authorization': 'Bearer ${token.trim()}',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$_base$path').replace(queryParameters: query == null || query.isEmpty ? null : query);

  Uri _fileUri(String id, String action) {
    final Uri base = Uri.parse(_base);
    return base.replace(pathSegments: <String>[
      ...base.pathSegments.where((String s) => s.isNotEmpty),
      'admin', 'material-storage', 'mega', 'file', id, action,
    ]);
  }

  dynamic _decode(http.Response response, String fallback) {
    if (response.statusCode == 501) throw const MegaNotAvailable();
    dynamic decoded;
    if (response.body.trim().isNotEmpty) {
      try {
        decoded = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        decoded = null;
      }
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return decoded;
    // "Not Found" di FastAPI = la rotta non esiste: il server non ha ancora il servizio MEGA.
    // Un altro 404 (es. cartella MEGA eliminata) è un errore normale.
    if (response.statusCode == 404 && (decoded == null || (decoded is Map && decoded['detail'] == 'Not Found'))) {
      throw const MegaNotAvailable();
    }
    if (decoded is Map && decoded['detail'] is String && (decoded['detail'] as String).trim().isNotEmpty) {
      final String detail = (decoded['detail'] as String).trim();
      if (response.statusCode == 503) throw MegaNotAvailable(detail);
      throw Exception(detail);
    }
    if (response.statusCode == 401 || response.statusCode == 403) throw Exception('Serve un account admin.');
    throw Exception(fallback);
  }

  Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  /// {configured, account, root_folder, used_bytes, limit_bytes, transfer_used_bytes,
  ///  transfer_limit_bytes, permissions: {read, write, delete}, public_links, checked_at}
  Future<Map<String, dynamic>> status() async =>
      _map(_decode(await http.get(_uri('/admin/material-storage/mega/status'), headers: _headers),
          'Impossibile leggere lo stato di MEGA'));

  /// Stessa forma di getDriveTree: {items: [{id, name, is_folder, size, mime_type, indexed}], next_page_token}
  Future<Map<String, dynamic>> getTree([String? folderId, String? pageToken]) async => _map(_decode(
      await http.get(
          _uri('/admin/material-storage/mega/tree', <String, String>{
            if (folderId != null) 'folder_id': folderId,
            if (pageToken != null) 'page_token': pageToken,
          }),
          headers: _headers),
      'Impossibile leggere i file della cartella MEGA'));

  Future<Uint8List> downloadPreview(String fileId) async {
    final http.Response response = await http.get(_fileUri(fileId, 'preview'), headers: _headers);
    if (response.statusCode == 501) throw const MegaNotAvailable();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Anteprima MEGA non disponibile');
    }
    return response.bodyBytes;
  }

  /// Collega l'account. La password e il codice 2FA servono solo per aprire la sessione:
  /// il server conserva la sessione cifrata, non la password.
  /// Risposta: {configured, account, checks: [{label, ok, warning, detail}]}
  Future<Map<String, dynamic>> connect({
    required String email,
    required String password,
    String? secondFactorCode,
    String rootFolder = '/StudentLab',
  }) async =>
      _map(_decode(
          await http.post(_uri('/admin/material-storage/mega/connect'),
              headers: _headers,
              body: jsonEncode(<String, dynamic>{
                'email': email.trim(),
                'password': password,
                if (secondFactorCode != null && secondFactorCode.trim().isNotEmpty)
                  'second_factor_code': secondFactorCode.trim(),
                'root_folder': rootFolder.trim(),
              })),
          'Collegamento a MEGA non riuscito'));

  /// Ripete le verifiche (lettura, scrittura con cartella di prova, cancellazione, quota, link pubblici).
  Future<Map<String, dynamic>> verify() async =>
      _map(_decode(await http.post(_uri('/admin/material-storage/mega/verify'), headers: _headers),
          'Verifica dei permessi MEGA non riuscita'));

  Future<void> disconnect() async =>
      _decode(await http.post(_uri('/admin/material-storage/mega/disconnect'), headers: _headers),
          'Scollegamento non riuscito');

  Future<Map<String, dynamic>> connectPublic(String link) async => _map(_decode(
      await http.post(_uri('/admin/material-storage/mega/connect'), headers: _headers,
          body: jsonEncode({'public_url': link.trim()})), 'Collegamento della cartella MEGA non riuscito'));

  Future<Map<String, dynamic>> copyToDrive(String fileId, List<String> path, {String? sourceId}) async => _map(_decode(
      await http.post(_uri('/admin/material-storage/mega/copy-drive'), headers: _headers,
          body: jsonEncode({'file_id': fileId, 'path_segments': path, if (sourceId != null) 'source_id': sourceId})),
      'Copia non avviata'));

  Future<List<Map<String, dynamic>>> jobs() async {
    final data = _map(_decode(await http.get(_uri('/admin/material-storage/mega/jobs'), headers: _headers), 'Copie non disponibili'));
    return (data['items'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
  Future<Map<String, dynamic>> stageCompleted(String id) async => _map(_decode(
      await http.post(_uri('/admin/material-storage/mega/jobs/${Uri.encodeComponent(id)}/stage'), headers: _headers), 'File non registrato'));
  Future<void> retryJob(String id) async => _decode(
      await http.post(_uri('/admin/material-storage/mega/jobs/${Uri.encodeComponent(id)}/retry'), headers: _headers), 'Nuovo tentativo non avviato');

  /// Avvia una copia MEGA → Drive da completare nella pagina Copie, poi registra la bozza.
  Future<Map<String, dynamic>> stageImport({
    required String fileId,
    required int subjectId,
    required List<String> pathSegments,
    required String audienceType,
    int? audienceId,
    bool allowDuplicate = false,
  }) async =>
      _map(_decode(
          await http.post(_uri('/admin/material-storage/catalog/mega-import'),
              headers: _headers,
              body: jsonEncode(<String, dynamic>{
                'file_id': fileId,
                'subject_id': subjectId,
                'path_segments': pathSegments,
                'audience_type': audienceType,
                'audience_id': audienceId,
                'allow_duplicate': allowDuplicate,
              })),
          'File non aggiunto alla bozza'));
}

/// Anteprima di un file dalla sua sorgente (Drive o MEGA), per showDriveFilePreview.
Future<Uint8List> downloadSourcePreview(AdminMaterialStorageApiService drive, MegaStorageApiService mega,
        CatalogSource source, String fileId) =>
    source == CatalogSource.drive ? drive.downloadDriveFilePreview(fileId) : mega.downloadPreview(fileId);
