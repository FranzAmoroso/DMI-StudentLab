import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'package:fe/services/api_service.dart';
import 'package:fe/services/auth_session.dart';
import 'package:fe/services/user_facing_error.dart';

/// Caricamento sicuro verso Drive o MEGA passando dal deposito temporaneo.
///
/// 1. il server prepara il caricamento (nome, dimensione, impronta SHA-256);
/// 2. /api/blob-transfer firma un URL valido 15 minuti solo per quel file;
/// 3. l'app invia il file direttamente al deposito privato (fino a 50 MB,
///    senza il limite di 4,5 MB delle funzioni Vercel);
/// 4. il servizio di trasferimento copia il file e ne verifica l'impronta.
///
/// [student] = true usa le rotte degli studenti (solo verso MEGA).
class TransferUploadApi {
  final bool student;
  TransferUploadApi({this.student = false});

  static const int maxBytes = 50 * 1024 * 1024;

  String get _base => ApiService().baseUrl.replaceAll(RegExp(r'/+$'), '');
  String get _prefix => student ? '/student/temporary-transfers' : '/admin/temporary-transfers';

  Map<String, String> get _headers {
    final token = AuthSession.instance.accessToken;
    if (token == null || token.trim().isEmpty) {
      throw const UserFacingError('La sessione è scaduta. Accedi di nuovo e riprova.');
    }
    return {'Authorization': 'Bearer ${token.trim()}', 'Content-Type': 'application/json'};
  }

  Future<dynamic> _call(String path, {Map<String, dynamic>? body, String fallback = 'Operazione non riuscita'}) async {
    final uri = Uri.parse('$_base$path');
    final response = await (body == null
            ? http.get(uri, headers: _headers)
            : http.post(uri, headers: _headers, body: jsonEncode(body)))
        .timeout(const Duration(seconds: 40));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw UserFacingError(friendlyHttpMessage(response, fallback), status: response.statusCode);
    }
    if (response.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw UserFacingError('$fallback. Risposta inattesa dal server: riprova tra poco.');
    }
  }

  List<Map<String, dynamic>> _rows(dynamic value) =>
      value is List ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];

  Future<List<Map<String, dynamic>>> list() async =>
      _rows(await _call(_prefix, fallback: 'Elenco dei caricamenti non disponibile'));

  /// Solo studenti: {enabled, max_bytes, max_active, extensions}.
  Future<Map<String, dynamic>> studentStatus() async {
    final value = await _call('/student/temporary-transfers/status', fallback: 'Stato non disponibile');
    return value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
  }

  /// Solo admin: file inviati dagli studenti verso MEGA.
  Future<List<Map<String, dynamic>>> studentUploads() async =>
      _rows(await _call('/admin/temporary-transfers/students', fallback: 'Caricamenti degli studenti non disponibili'));

  Future<void> cancel(String id) async => _call('$_prefix/$id/cancel', body: {}, fallback: 'Annullamento non riuscito');
  Future<void> retry(String id) async => _call('$_prefix/$id/retry', body: {}, fallback: 'Nuovo tentativo non riuscito');
  Future<void> confirm(String id) async => _call('$_prefix/$id/ready', body: {}, fallback: 'Verifica non riuscita');

  static String mimeFor(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return const {
          'pdf': 'application/pdf',
          'txt': 'text/plain',
          'md': 'text/markdown',
          'csv': 'text/csv',
          'zip': 'application/zip',
          'png': 'image/png',
          'jpg': 'image/jpeg',
          'jpeg': 'image/jpeg',
          'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
          'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        }[ext] ??
        'application/octet-stream';
  }

  /// Carica un file. Per gli admin: [destination] 'drive' o 'mega' e [pathSegments].
  /// Per gli studenti: [folder] facoltativa (es. nome della materia).
  Future<Map<String, dynamic>> upload({
    required String filename,
    required Uint8List bytes,
    String destination = 'mega',
    List<String> pathSegments = const <String>[],
    String? folder,
  }) async {
    if (bytes.isEmpty) throw const UserFacingError('Il file è vuoto.');
    if (bytes.length > maxBytes) throw const UserFacingError('Il file supera 50 MB.');
    final mime = mimeFor(filename);
    final digest = sha256.convert(bytes).toString();
    final prepared = await _call('$_prefix/prepare',
        body: student
            ? {'filename': filename, 'size': bytes.length, 'sha256': digest, 'mime_type': mime,
               if (folder != null && folder.trim().isNotEmpty) 'folder': folder.trim()}
            : {'filename': filename, 'size': bytes.length, 'sha256': digest, 'mime_type': mime,
               'destination': destination, 'path_segments': pathSegments},
        fallback: 'Caricamento non preparato');
    final job = Map<String, dynamic>.from(prepared as Map);
    final id = '${job['id']}';
    final signed = await http
        .post(Uri.parse('$_base/api/blob-transfer'),
            headers: _headers, body: jsonEncode({'job_id': id, if (student) 'scope': 'student'}))
        .timeout(const Duration(seconds: 40));
    if (signed.statusCode != 200) {
      throw UserFacingError(friendlyHttpMessage(signed, 'Caricamento non autorizzato'));
    }
    Uri url;
    try {
      url = Uri.parse((jsonDecode(signed.body) as Map)['upload_url'] as String);
    } catch (_) {
      throw const UserFacingError('Caricamento non autorizzato. Riprova tra poco.');
    }
    if (url.scheme != 'https') throw const UserFacingError('Destinazione del caricamento non valida.');
    final put = await http
        .put(url, headers: {'Content-Type': mime, 'x-vercel-blob-access': 'private'}, body: bytes)
        .timeout(const Duration(minutes: 10));
    if (put.statusCode < 200 || put.statusCode >= 300) {
      throw const UserFacingError('Caricamento interrotto. Controlla la connessione e riprova.');
    }
    await confirm(id);
    return job;
  }
}
