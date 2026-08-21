import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'auth_session.dart';

class StudentLabUploadService {
  static const String _baseUrl = 'https://dmi-student-lab.vercel.app';
  static const String _host = 'dmi-student-lab.vercel.app';
  static const int groupMaterialMaxSize = 250 * 1024 * 1024;
  static const int teacherMaterialMaxSize = 250 * 1024 * 1024;
  static const int questionAttachmentMaxSize = 50 * 1024 * 1024;
  static const int materialPublicationMaxSize = 250 * 1024 * 1024;

  Uri _uri(String path) {
    final Uri base = Uri.parse(_baseUrl);
    final String normalizedPath = path.startsWith('/') ? path : '/$path';
    final Uri uri = base.replace(path: normalizedPath);
    if (uri.scheme != 'https' || uri.host != _host) {
      throw StateError('Endpoint di caricamento non autorizzato.');
    }
    return uri;
  }

  Map<String, String> get _jsonHeaders {
    final String? token = AuthSession.instance.accessToken;
    if (token == null || token.trim().isEmpty) {
      throw Exception('Utente non autenticato.');
    }
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${token.trim()}',
    };
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body,
    String fallbackMessage,
  ) async {
    final http.Response response = await http.post(
      _uri(path),
      headers: _jsonHeaders,
      body: jsonEncode(body),
    );
    return _decodeMapResponse(response, fallbackMessage);
  }

  Map<String, dynamic> _decodeMapResponse(
    http.Response response,
    String fallbackMessage,
  ) {
    dynamic decoded;
    if (response.body.trim().isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded == null) {
        return {};
      }
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      throw Exception('$fallbackMessage: risposta non valida.');
    }
    String message = fallbackMessage;
    if (decoded is Map) {
      final dynamic detail = decoded['detail'] ?? decoded['error'];
      if (detail is String && detail.trim().isNotEmpty) {
        message = detail.trim();
      }
    }
    throw Exception(message);
  }

  Future<String> _sha256(File file) async {
    final Digest digest = await sha256.bind(file.openRead()).first;
    return digest.toString().toLowerCase();
  }

  String _fileName(String filePath) {
    final String normalized = filePath.replaceAll('\\', '/');
    final List<String> parts = normalized.split('/');
    final String name = parts.isEmpty ? '' : parts.last.trim();
    if (name.isEmpty || name == '.' || name == '..') {
      throw Exception('Nome del file non valido.');
    }
    return name;
  }

  String _groupMimeType(String fileName) {
    final String lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.txt')) return 'text/plain';
    if (lower.endsWith('.zip')) return 'application/zip';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.pptx')) {
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    }
    throw Exception('Tipo di file non supportato.');
  }

  String _teacherMimeType(String fileName) {
    final String lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.zip')) return 'application/zip';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.pptx')) {
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    }
    if (lower.endsWith('.ppt')) return 'application/vnd.ms-powerpoint';
    if (lower.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    if (lower.endsWith('.xls')) return 'application/vnd.ms-excel';
    if (lower.endsWith('.csv')) return 'text/csv';
    if (lower.endsWith('.txt')) return 'text/plain';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    throw Exception('Tipo di file non supportato.');
  }

  String _questionMimeType(String fileName) {
    final String lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.txt')) return 'text/plain';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.pptx')) {
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    }
    throw Exception('Tipo di allegato non supportato.');
  }

  String _requiredString(
    Map<String, dynamic> data,
    String key,
    String message,
  ) {
    final String? value = data[key]?.toString().trim();
    if (value == null || value.isEmpty) {
      throw Exception(message);
    }
    return value;
  }

  int _requiredPositiveInt(
    Map<String, dynamic> data,
    String key,
    String message,
  ) {
    final dynamic raw = data[key];
    final int? value = raw is int
        ? raw
        : raw is num
        ? raw.toInt()
        : int.tryParse(raw?.toString() ?? '');
    if (value == null || value <= 0) {
      throw Exception(message);
    }
    return value;
  }

  Future<void> _putFile({
    required File file,
    required int size,
    required String mimeType,
    required String presignedUrl,
  }) async {
    final Uri uploadUri = Uri.parse(presignedUrl);
    if (uploadUri.scheme.toLowerCase() != 'https') {
      throw Exception('Connessione di caricamento non valida.');
    }
    final http.StreamedRequest request = http.StreamedRequest('PUT', uploadUri);
    request.headers['Content-Type'] = mimeType;
    request.contentLength = size;
    final Future<void> pipeFuture = file.openRead().pipe(request.sink);
    final http.StreamedResponse response = await request.send();
    await pipeFuture;
    await response.stream.drain<void>();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Non è stato possibile caricare il file.');
    }
  }

  Future<Map<String, dynamic>> _requestBlobUpload({
    required String uploadKind,
    required String pathname,
    required String mimeType,
    required int size,
    required String fileHash,
    required String uploadToken,
    int? groupId,
    int? subjectId,
    String? attachmentId,
  }) async {
    final Map<String, dynamic> body = {
      'upload_kind': uploadKind,
      'pathname': pathname,
      'content_type': mimeType,
      'size': size,
      'file_hash': fileHash,
      'upload_token': uploadToken,
      if (groupId != null) 'group_id': groupId,
      if (subjectId != null) 'subject_id': subjectId,
      if (attachmentId != null) 'attachment_id': attachmentId,
    };
    return _postJson(
      '/api/blob-upload',
      body,
      'Non è stato possibile autorizzare il caricamento.',
    );
  }

  Future<Map<String, dynamic>> uploadGroupMaterial({
    required int groupId,
    required String filePath,
    String? originalName,
    String? mimeType,
  }) async {
    if (groupId <= 0) {
      throw Exception('Gruppo non valido.');
    }
    final File file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Il file selezionato non esiste.');
    }
    final int size = await file.length();
    if (size <= 0) {
      throw Exception('Il file è vuoto.');
    }
    if (size > groupMaterialMaxSize) {
      throw Exception(
        'Il file supera la dimensione massima consentita di 250 MB.',
      );
    }
    final String resolvedOriginalName =
        originalName != null && originalName.trim().isNotEmpty
        ? originalName.trim()
        : _fileName(filePath);
    final String resolvedMimeType =
        mimeType != null && mimeType.trim().isNotEmpty
        ? mimeType.trim().toLowerCase()
        : _groupMimeType(resolvedOriginalName);
    final String fileHash = await _sha256(file);
    final Map<String, dynamic> authorization = await _postJson(
      '/group_material_upload_request/$groupId',
      {
        'original_name': resolvedOriginalName,
        'mime_type': resolvedMimeType,
        'size': size,
        'file_hash': fileHash,
      },
      'Non è stato possibile autorizzare il materiale.',
    );
    if (authorization['allowed'] != true) {
      throw Exception('Il caricamento del materiale non è autorizzato.');
    }
    final String pathname = _requiredString(
      authorization,
      'pathname',
      'Il server non ha restituito un percorso di upload valido.',
    );
    final String uploadToken = _requiredString(
      authorization,
      'upload_token',
      'Il server non ha restituito un’autorizzazione di upload valida.',
    );
    final int maxSize = authorization['max_file_size'] == null
        ? groupMaterialMaxSize
        : _requiredPositiveInt(
            authorization,
            'max_file_size',
            'Dimensione massima restituita dal server non valida.',
          );
    if (size > maxSize) {
      throw Exception('Il file supera la dimensione massima consentita.');
    }
    final Map<String, dynamic> blob = await _requestBlobUpload(
      uploadKind: 'group_material',
      pathname: pathname,
      mimeType: resolvedMimeType,
      size: size,
      fileHash: fileHash,
      uploadToken: uploadToken,
      groupId: groupId,
    );
    final String presignedUrl = _requiredString(
      blob,
      'presigned_url',
      'Il servizio di caricamento non ha restituito un URL valido.',
    );
    await _putFile(
      file: file,
      size: size,
      mimeType: resolvedMimeType,
      presignedUrl: presignedUrl,
    );
    return _postJson(
      '/group_material_complete/$groupId',
      {
        'original_name': resolvedOriginalName,
        'stored_name': pathname,
        'file_path': pathname,
        'mime_type': resolvedMimeType,
        'size': size,
        'file_hash': fileHash,
        'upload_token': uploadToken,
      },
      'Non è stato possibile registrare il materiale.',
    );
  }

  Future<Map<String, dynamic>> uploadTeacherMaterial({
    required int subjectId,
    required String title,
    required String description,
    required String filePath,
    String visibility = 'students',
  }) async {
    if (subjectId <= 0) {
      throw Exception('Materia non valida.');
    }
    final String normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) {
      throw Exception('Titolo del materiale obbligatorio.');
    }
    final String normalizedVisibility = visibility.trim().toLowerCase();
    if (normalizedVisibility != 'students' &&
        normalizedVisibility != 'private') {
      throw Exception('Visibilità materiale non valida.');
    }
    final File file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Il file selezionato non esiste.');
    }
    final int size = await file.length();
    if (size <= 0) {
      throw Exception('Il file è vuoto.');
    }
    if (size > teacherMaterialMaxSize) {
      throw Exception(
        'Il file supera la dimensione massima consentita di 250 MB.',
      );
    }
    final String originalName = _fileName(filePath);
    final String mimeType = _teacherMimeType(originalName);
    final String fileHash = await _sha256(file);
    final Map<String, dynamic> authorization = await _postJson(
      '/teacher/materials/upload-request',
      {
        'subject_id': subjectId,
        'original_name': originalName,
        'mime_type': mimeType,
        'size': size,
        'file_hash': fileHash,
      },
      'Non è stato possibile autorizzare il materiale docente.',
    );
    if (authorization['allowed'] != true) {
      throw Exception(
        'Il caricamento del materiale docente non è autorizzato.',
      );
    }
    final String pathname = _requiredString(
      authorization,
      'pathname',
      'Il backend non ha restituito un pathname valido.',
    );
    final String uploadToken = _requiredString(
      authorization,
      'upload_token',
      'Il backend non ha restituito un’autorizzazione di upload valida.',
    );
    final Map<String, dynamic> blob = await _requestBlobUpload(
      uploadKind: 'teacher_material',
      pathname: pathname,
      mimeType: mimeType,
      size: size,
      fileHash: fileHash,
      uploadToken: uploadToken,
      subjectId: subjectId,
    );
    final String presignedUrl = _requiredString(
      blob,
      'presigned_url',
      'Il servizio di caricamento non ha restituito un URL valido.',
    );
    await _putFile(
      file: file,
      size: size,
      mimeType: mimeType,
      presignedUrl: presignedUrl,
    );
    return _postJson(
      '/teacher/materials/complete',
      {
        'subject_id': subjectId,
        'title': normalizedTitle,
        'description': description.trim(),
        'original_name': originalName,
        'stored_name': pathname,
        'file_path': pathname,
        'mime_type': mimeType,
        'size': size,
        'file_hash': fileHash,
        'visibility': normalizedVisibility,
        'upload_token': uploadToken,
      },
      'Non è stato possibile registrare il materiale docente.',
    );
  }

  Future<Map<String, dynamic>> uploadQuestionAttachment({
    required String department,
    required String course,
    required String subject,
    required String filePath,
    required String questionId,
  }) async {
    final String normalizedDepartment = department.trim();
    final String normalizedCourse = course.trim();
    final String normalizedSubject = subject.trim();
    final String normalizedQuestionId = questionId.trim();
    if (normalizedDepartment.isEmpty ||
        normalizedCourse.isEmpty ||
        normalizedSubject.isEmpty) {
      throw Exception('Dati della materia non validi.');
    }
    if (normalizedQuestionId.isEmpty) {
      throw Exception(
        'La domanda deve essere salvata prima di aggiungere allegati.',
      );
    }
    final File file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Il file selezionato non esiste.');
    }
    final int size = await file.length();
    if (size <= 0) {
      throw Exception('Il file è vuoto.');
    }
    if (size > questionAttachmentMaxSize) {
      throw Exception(
        'L’allegato supera la dimensione massima consentita di 50 MB.',
      );
    }
    final String originalName = _fileName(filePath);
    final String mimeType = _questionMimeType(originalName);
    final String fileHash = await _sha256(file);
    final Map<String, dynamic> authorization = await _postJson(
      '/question-attachments/upload-request',
      {
        'department': normalizedDepartment,
        'course': normalizedCourse,
        'subject': normalizedSubject,
        'question_id': normalizedQuestionId,
        'original_name': originalName,
        'mime_type': mimeType,
        'size': size,
        'file_hash': fileHash,
      },
      'Non è stato possibile autorizzare l’allegato.',
    );
    if (authorization['allowed'] != true) {
      throw Exception('Il caricamento dell’allegato non è autorizzato.');
    }
    final String attachmentId = _requiredString(
      authorization,
      'attachment_id',
      'Il server non ha restituito un identificativo allegato valido.',
    );
    final String pathname = _requiredString(
      authorization,
      'pathname',
      'Il server non ha restituito un percorso di upload valido.',
    );
    final String uploadToken = _requiredString(
      authorization,
      'upload_token',
      'Il server non ha restituito un’autorizzazione di upload valida.',
    );
    final Map<String, dynamic> blob = await _requestBlobUpload(
      uploadKind: 'question_attachment',
      pathname: pathname,
      mimeType: mimeType,
      size: size,
      fileHash: fileHash,
      uploadToken: uploadToken,
      attachmentId: attachmentId,
    );
    final String presignedUrl = _requiredString(
      blob,
      'presigned_url',
      'Il servizio di caricamento non ha restituito un URL valido.',
    );
    await _putFile(
      file: file,
      size: size,
      mimeType: mimeType,
      presignedUrl: presignedUrl,
    );
    return _postJson(
      '/question-attachments/complete',
      {
        'department': normalizedDepartment,
        'course': normalizedCourse,
        'subject': normalizedSubject,
        'attachment_id': attachmentId,
        'original_name': originalName,
        'mime_type': mimeType,
        'pathname': pathname,
        'size': size,
        'file_hash': fileHash,
        'upload_token': uploadToken,
      },
      'Non è stato possibile completare l’allegato.',
    );
  }

  Future<Map<String, dynamic>> uploadMaterialPublication({
    required int subjectId,
    required String title,
    required String description,
    required String filePath,
    Future<void> Function()? onPossibleDuplicate,
  }) async {
    if (subjectId <= 0) {
      throw Exception('Materia non valida.');
    }
    final String normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) {
      throw Exception('Titolo del materiale obbligatorio.');
    }

    final File file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Il file selezionato non esiste.');
    }

    final int size = await file.length();
    if (size <= 0) {
      throw Exception('Il file è vuoto.');
    }
    if (size > materialPublicationMaxSize) {
      throw Exception(
        'Il file supera la dimensione massima consentita di 250 MB.',
      );
    }

    final String originalName = _fileName(filePath);
    final String mimeType = _groupMimeType(originalName);
    final String fileHash = await _sha256(file);

    final Map<String, dynamic> authorization = await _postJson(
      '/material_publication/upload-request',
      {
        'subject_id': subjectId,
        'title': normalizedTitle,
        'description': description.trim(),
        'original_name': originalName,
        'mime_type': mimeType,
        'size': size,
        'file_hash': fileHash,
      },
      'Non è stato possibile autorizzare la condivisione del materiale.',
    );

    if (authorization['allowed'] != true) {
      throw Exception('La condivisione del materiale non è autorizzata.');
    }

    final bool possibleDuplicate = authorization['possible_duplicate'] == true;
    final int? possibleDuplicateMaterialId =
        authorization['possible_duplicate_material_id'] is num
        ? (authorization['possible_duplicate_material_id'] as num).toInt()
        : int.tryParse(
            authorization['possible_duplicate_material_id']?.toString() ?? '',
          );

    if (possibleDuplicate && onPossibleDuplicate != null) {
      await onPossibleDuplicate();
    }

    final String pathname = _requiredString(
      authorization,
      'pathname',
      'Il backend non ha restituito un pathname valido.',
    );
    final String uploadToken = _requiredString(
      authorization,
      'upload_token',
      'Il backend non ha restituito un’autorizzazione di upload valida.',
    );

    final Map<String, dynamic> blob = await _requestBlobUpload(
      uploadKind: 'material_publication',
      pathname: pathname,
      mimeType: mimeType,
      size: size,
      fileHash: fileHash,
      uploadToken: uploadToken,
      subjectId: subjectId,
    );

    final String presignedUrl = _requiredString(
      blob,
      'presigned_url',
      'Il servizio di caricamento non ha restituito un URL valido.',
    );

    await _putFile(
      file: file,
      size: size,
      mimeType: mimeType,
      presignedUrl: presignedUrl,
    );

    final Map<String, dynamic> result = await _postJson(
      '/material_publication/complete',
      {
        'subject_id': subjectId,
        'title': normalizedTitle,
        'description': description.trim(),
        'original_name': originalName,
        'stored_name': pathname,
        'file_path': pathname,
        'mime_type': mimeType,
        'size': size,
        'file_hash': fileHash,
      },
      'Non è stato possibile inviare il materiale in revisione.',
    );

    return {
      ...result,
      'possible_duplicate': possibleDuplicate,
      'possible_duplicate_material_id': possibleDuplicateMaterialId,
    };
  }
}
