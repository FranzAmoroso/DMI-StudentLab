import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'package:fe/services/api_service.dart';
import 'package:fe/services/auth_session.dart';
import 'package:fe/services/user_facing_error.dart';

import 'transfer_upload_api.dart';

/// Caricamento diretto su Google Drive, senza Blob e senza limite di dimensione (v31).
///
/// 1. il server crea su Drive una sessione di caricamento per quel solo file;
/// 2. l'app invia i byte direttamente a Google, a pezzi da 8 MB;
/// 3. il server verifica il file (cartella, dimensione, impronta SHA-256) e, se
///    richiesto, lo mette subito nella bozza della struttura.
///
/// Un invio interrotto non lascia file a metà: su Drive il file esiste solo a fine invio.
class DriveDirectUpload {
  static const int _chunk = 32 * 256 * 1024; // 8 MB, multiplo di 256 KB come vuole Google

  /// Se il browser blocca l'invio diretto (impostazioni di rete), per il resto della
  /// sessione si usa il trasferimento classico (fino a 50 MB).
  static bool _directBlocked = false;

  String get _base => ApiService().baseUrl.replaceAll(RegExp(r'/+$'), '');

  Map<String, String> get _headers {
    final token = AuthSession.instance.accessToken;
    if (token == null || token.trim().isEmpty) {
      throw const UserFacingError('La sessione è scaduta. Accedi di nuovo e riprova.');
    }
    return {'Authorization': 'Bearer ${token.trim()}', 'Content-Type': 'application/json'};
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body, String fallback) async {
    final response = await http
        .post(Uri.parse('$_base$path'), headers: _headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 90));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw UserFacingError(friendlyHttpMessage(response, fallback), status: response.statusCode);
    }
    try {
      return Map<String, dynamic>.from(jsonDecode(utf8.decode(response.bodyBytes)) as Map);
    } catch (_) {
      throw UserFacingError('$fallback. Risposta inattesa dal server: riprova tra poco.');
    }
  }

  /// Invia un file su Drive in [pathSegments] (dalla cartella StudentLab in giù).
  ///
  /// Con [stage] ({subject_id, path_segments, audience_type}) il file entra subito
  /// nella bozza della struttura. Restituisce {mode: 'direct'|'transfer', file_id?, staged?, job?}.
  Future<Map<String, dynamic>> upload({
    required String filename,
    required Uint8List bytes,
    required List<String> pathSegments,
    Map<String, dynamic>? stage,
    void Function(double progress)? onProgress,
  }) async {
    if (bytes.isEmpty) throw const UserFacingError('Il file è vuoto.');
    final mime = TransferUploadApi.mimeFor(filename);
    final digest = sha256.convert(bytes).toString();
    if (!_directBlocked) {
      // Un errore del server (es. nome non valido) si mostra così com'è: niente ripiego.
      final session = await _post('/admin/material-storage/drive/direct-upload/session', {
        'filename': filename, 'mime_type': mime, 'size': bytes.length,
        'sha256': digest, 'path_segments': pathSegments,
      }, 'Caricamento su Drive non preparato');
      final url = '${session['upload_url']}';
      final fileId = await _sendChunks(Uri.parse(url), bytes, mime, onProgress);
      if (fileId != null) {
        final done = await _post('/admin/material-storage/drive/direct-upload/complete', {
          'file_id': fileId, 'size': bytes.length, 'sha256': digest, if (stage != null) 'stage': stage,
        }, 'Verifica del file su Drive non riuscita');
        return {'mode': 'direct', ...done};
      }
      _directBlocked = true;
    }
    // Ripiego: trasferimento classico tramite Blob (fino a 50 MB).
    final job = await TransferUploadApi().upload(
      filename: filename, bytes: bytes, destination: 'drive', pathSegments: pathSegments);
    return {'mode': 'transfer', 'job': job};
  }

  /// Restituisce l'id del file su Drive, oppure null se il browser non riesce
  /// proprio a raggiungere Google (in quel caso si usa il ripiego).
  Future<String?> _sendChunks(Uri url, Uint8List bytes, String mime, void Function(double)? onProgress) async {
    final total = bytes.length;
    var offset = 0;
    var retries = 0;
    var anyResponse = false;
    while (true) {
      final end = (offset + _chunk < total ? offset + _chunk : total);
      http.Response response;
      try {
        response = await http.put(url, headers: {
          'Content-Type': mime,
          'Content-Range': 'bytes $offset-${end - 1}/$total',
        }, body: bytes.sublist(offset, end)).timeout(const Duration(minutes: 5));
        anyResponse = true;
      } catch (_) {
        if (!anyResponse) return null; // bloccato fin dall'inizio: ripiego
        if (++retries > 3) {
          throw const UserFacingError('Caricamento interrotto. Controlla la connessione e riprova.');
        }
        final resumed = await _status(url, total);
        if (resumed == null) {
          throw const UserFacingError('Caricamento interrotto. Controlla la connessione e riprova.');
        }
        offset = resumed;
        continue;
      }
      if (response.statusCode == 200 || response.statusCode == 201) {
        onProgress?.call(1);
        try {
          return '${(jsonDecode(response.body) as Map)['id']}';
        } catch (_) {
          throw const UserFacingError('Drive non ha confermato il file. Riprova.');
        }
      }
      if (response.statusCode == 308) {
        offset = _nextOffset(response.headers['range']) ?? end;
        onProgress?.call(offset / total);
        retries = 0;
        continue;
      }
      if (response.statusCode >= 500 && ++retries <= 3) {
        offset = await _status(url, total) ?? offset;
        continue;
      }
      if (response.statusCode == 403 || response.statusCode == 429) {
        throw const UserFacingError('Lo spazio o il limite di Google Drive è esaurito. Riprova più tardi.');
      }
      throw const UserFacingError('Drive ha rifiutato il caricamento. Riprova; se continua, controlla il registro diagnostico.');
    }
  }

  /// Chiede a Google quanti byte ha già ricevuto.
  Future<int?> _status(Uri url, int total) async {
    try {
      final r = await http.put(url, headers: {'Content-Range': 'bytes */$total'})
          .timeout(const Duration(seconds: 40));
      if (r.statusCode == 308) return _nextOffset(r.headers['range']) ?? 0;
    } catch (_) {/* nessuna risposta */}
    return null;
  }

  int? _nextOffset(String? range) {
    final m = RegExp(r'bytes=0-(\d+)').firstMatch(range ?? '');
    return m == null ? null : int.parse(m.group(1)!) + 1;
  }
}
