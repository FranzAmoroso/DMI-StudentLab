import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/quiz_model.dart';

import '../social/social_models.dart';
import 'auth_session.dart';


class ApiService {
  final String baseUrl =
      'https://dmi-student-lab.vercel.app';


  static const int maxMaterialFileSize =
      250 * 1024 * 1024;


  Future<List<String>> getArguments(
    String department,
    String course,
    String sub,
  ) async {
    final Uri url =
        Uri.parse(
      '$baseUrl/arguments',
    );

    try {
      final response =
          await http.post(
        url,
        headers:
            _jsonHeaders,
        body:
            jsonEncode({
          'department':
              department,
          'course':
              course,
          'sub':
              sub,
        }),
      );

      if (response.statusCode ==
          200) {
        final dynamic body =
            jsonDecode(
          response.body,
        );

        if (body is! List) {
          throw Exception(
            'Risposta non valida dal server.',
          );
        }

        return body
            .map<String>(
              (item) =>
                  item.toString(),
            )
            .toList();
      }

      throw Exception(
        'Errore caricamento argomenti: '
        '${response.statusCode} - '
        '${response.body}',
      );
    } catch (e) {
      throw Exception(
        'Errore connessione argomenti: $e',
      );
    }
  }


  Future<int> getQuestionCount(
    String department,
    String course,
    String sub,
    List<String> arguments,
  ) async {
    final Uri url =
        Uri.parse(
      '$baseUrl/question_count',
    );

    try {
      final response =
          await http.post(
        url,
        headers:
            _jsonHeaders,
        body:
            jsonEncode({
          'department':
              department,
          'course':
              course,
          'sub':
              sub,
          'arguments':
              arguments,
        }),
      );

      if (response.statusCode ==
          200) {
        final dynamic body =
            jsonDecode(
          response.body,
        );

        if (body is int) {
          return body;
        }

        if (body
                is Map<String, dynamic> &&
            body['count'] is int) {
          return body['count']
              as int;
        }

        throw Exception(
          'Risposta non valida per il conteggio.',
        );
      }

      throw Exception(
        'Errore conteggio domande: '
        '${response.statusCode} - '
        '${response.body}',
      );
    } catch (e) {
      throw Exception(
        'Errore connessione conteggio: $e',
      );
    }
  }


  Future<List<QuizModel>>
      shuffle_filter(
    String department,
    String course,
    String sub,
    List<String> selectedArguments,
    int numberOfQuestions,
  ) async {
    final Uri url =
        Uri.parse(
      '$baseUrl/shuffle_filter',
    );

    try {
      final response =
          await http.post(
        url,
        headers:
            _jsonHeaders,
        body:
            jsonEncode({
          'department':
              department,
          'course':
              course,
          'sub':
              sub,
          'arguments':
              selectedArguments,
          'number_of_questions':
              numberOfQuestions,
        }),
      );

      if (response.statusCode ==
          200) {
        final dynamic body =
            jsonDecode(
          response.body,
        );

        if (body is! List) {
          throw Exception(
            'Risposta quiz non valida.',
          );
        }

        return body
            .map<QuizModel>(
              (item) =>
                  QuizModel.fromJson(
                item,
              ),
            )
            .toList();
      }

      throw Exception(
        'Impossibile caricare le domande: '
        '${response.statusCode} - '
        '${response.body}',
      );
    } catch (e) {
      throw Exception(
        'Errore caricamento quiz: $e',
      );
    }
  }


  Future<bool> validate_quest(
    String idQuestion,
    String idChoice,
    String department,
    String sub,
  ) async {
    final Uri url =
        Uri.parse(
      '$baseUrl/validate_answer',
    );

    try {
      final response =
          await http.post(
        url,
        headers:
            _jsonHeaders,
        body:
            jsonEncode({
          'idQuestion':
              idQuestion,
          'idChoice':
              idChoice,
          'department':
              department,
          'sub':
              sub,
        }),
      );

      if (response.statusCode ==
          200) {
        return jsonDecode(
              response.body,
            ) ==
            true;
      }

      throw Exception(
        'Errore validate: '
        '${response.statusCode} - '
        '${response.body}',
      );
    } catch (e) {
      throw Exception(
        'Errore connessione validazione: $e',
      );
    }
  }


  Future<List<String>> getSubjects(
    String department,
    String course,
  ) async {
    final Uri url =
        Uri.parse(
      '$baseUrl/subjects',
    );

    try {
      final response =
          await http.post(
        url,
        headers:
            _jsonHeaders,
        body:
            jsonEncode({
          'department':
              department,
          'course':
              course,
        }),
      );

      if (response.statusCode ==
          200) {
        final List<dynamic> body =
            jsonDecode(
          response.body,
        );

        return body
            .map(
              (item) =>
                  item.toString(),
            )
            .toList();
      }

      throw Exception(
        'Errore caricamento materie: '
        '${response.body}',
      );
    } catch (e) {
      throw Exception(
        'Errore connessione materie: $e',
      );
    }
  }


  Future<SocialUser> createUser({
    required String firstName,
    required String lastName,
    required String email,
    required String department,
    required String course,
    String? description,
    String role = 'student',
    bool available = true,
    bool willingToTeach = false,
  }) async {
    final Uri url =
        Uri.parse(
      '$baseUrl/create_user',
    );

    final http.Response response =
        await http.post(
      url,
      headers:
          _jsonHeaders,
      body:
          jsonEncode({
        'first_name':
            firstName,
        'last_name':
            lastName,
        'email':
            email,
        'department':
            department,
        'course':
            course,
        'description':
            description,
        'role':
            role,
        'available':
            available,
        'willing_to_teach':
            willingToTeach,
      }),
    );

    final Map<String, dynamic> data =
        _decodeMapResponse(
      response,
      'Errore creazione utente',
    );

    return SocialUser.fromJson(
      data,
    );
  }


  Future<List<SocialUser>>
      getSocialUsers() async {
    final Uri url =
        Uri.parse(
      '$baseUrl/users',
    );

    final response =
        await http.get(
      url,
      headers:
          _jsonHeaders,
    );

    final List<Map<String, dynamic>>
        data =
        _decodeListResponse(
      response,
      'Errore caricamento utenti',
    );

    return data
        .map(
          SocialUser.fromJson,
        )
        .toList();
  }


  Future<SocialUser> getSocialUser(
    int userId,
  ) async {
    final Uri url =
        Uri.parse(
      '$baseUrl/user/$userId',
    );

    final http.Response response =
        await http.get(
      url,
      headers:
          _jsonHeaders,
    );

    final Map<String, dynamic> data =
        _decodeMapResponse(
      response,
      'Errore caricamento utente',
    );

    return SocialUser.fromJson(
      data,
    );
  }


  Future<SocialUser>
      updateSocialUser({
    required int userId,
    String? firstName,
    String? lastName,
    String? email,
    String? department,
    String? course,
    String? description,
    String? role,
    bool? available,
    bool? willingToTeach,
    bool? isActive,
  }) async {
    final Map<String, dynamic>
        body =
        {};

    if (firstName != null) {
      body['first_name'] =
          firstName;
    }

    if (lastName != null) {
      body['last_name'] =
          lastName;
    }

    if (email != null) {
      body['email'] =
          email;
    }

    if (department != null) {
      body['department'] =
          department;
    }

    if (course != null) {
      body['course'] =
          course;
    }

    if (description != null) {
      body['description'] =
          description;
    }

    if (role != null) {
      body['role'] =
          role;
    }

    if (available != null) {
      body['available'] =
          available;
    }

    if (willingToTeach != null) {
      body['willing_to_teach'] =
          willingToTeach;
    }

    if (isActive != null) {
      body['is_active'] =
          isActive;
    }

    final Uri url =
        Uri.parse(
      '$baseUrl/update_user/$userId',
    );

    final response =
        await http.patch(
      url,
      headers:
          _jsonHeaders,
      body:
          jsonEncode(
        body,
      ),
    );

    final data =
        _decodeMapResponse(
      response,
      'Errore aggiornamento utente',
    );

    return SocialUser.fromJson(
      data,
    );
  }


  Future<List<SocialSubject>>
      getSocialSubjects(
    String department,
    String course,
  ) async {
    final Uri url =
        Uri.parse(
      '$baseUrl/social_subjects/$department/$course',
    );

    final response =
        await http.get(
      url,
      headers:
          _jsonHeaders,
    );

    final List<Map<String, dynamic>>
        data =
        _decodeListResponse(
      response,
      'Errore caricamento materie Social',
    );

    return data
        .map(
          SocialSubject.fromJson,
        )
        .toList();
  }


  Future<Map<String, dynamic>>
      addUserSubject({
    required int userId,
    required int subjectId,
    int? grade,
    String? note,
    bool canHelp = false,
  }) async {
    final Uri url =
        Uri.parse(
      '$baseUrl/add_user_subject/$userId',
    );

    final response =
        await http.post(
      url,
      headers:
          _jsonHeaders,
      body:
          jsonEncode({
        'subject_id':
            subjectId,
        'grade':
            grade,
        'note':
            note,
        'can_help':
            canHelp,
      }),
    );

    return _decodeMapResponse(
      response,
      'Errore aggiunta materia',
    );
  }


  Future<void>
      removeUserSubject({
    required int userId,
    required int subjectId,
  }) async {
    final Uri url =
        Uri.parse(
      '$baseUrl/remove_user_subject/$userId/$subjectId',
    );

    final response =
        await http.delete(
      url,
      headers:
          _jsonHeaders,
    );

    _checkSuccess(
      response,
      'Errore rimozione materia',
    );
  }


  Future<Map<String, dynamic>>
      createGroup({
    required String name,
    required String description,
    required int subjectId,
    required String department,
    required String course,
    required bool isPrivate,
    required int createdBy,
  }) async {
    final Uri url =
        Uri.parse(
      '$baseUrl/create_group',
    );

    final http.Response response =
        await http.post(
      url,
      headers:
          _jsonHeaders,
      body:
          jsonEncode({
        'name':
            name,
        'description':
            description,
        'subject_id':
            subjectId,
        'department':
            department,
        'course':
            course,
        'is_private':
            isPrivate,
        'created_by':
            createdBy,
      }),
    );

    return _decodeMapResponse(
      response,
      'Errore creazione gruppo',
    );
  }


  Future<List<Map<String, dynamic>>>
      getGroups() async {
    final Uri url =
        Uri.parse(
      '$baseUrl/groups',
    );

    final response =
        await http.get(
      url,
      headers:
          _jsonHeaders,
    );

    return _decodeListResponse(
      response,
      'Errore caricamento gruppi',
    );
  }


  Future<Map<String, dynamic>>
      getGroup(
    int groupId,
  ) async {
    final Uri url =
        Uri.parse(
      '$baseUrl/group/$groupId',
    );

    final response =
        await http.get(
      url,
      headers:
          _jsonHeaders,
    );

    return _decodeMapResponse(
      response,
      'Errore caricamento gruppo',
    );
  }


  Future<List<Map<String, dynamic>>>
      getUserGroups(
    int userId,
  ) async {
    final Uri url =
        Uri.parse(
      '$baseUrl/user_groups/$userId',
    );

    final response =
        await http.get(
      url,
      headers:
          _jsonHeaders,
    );

    return _decodeListResponse(
      response,
      'Errore caricamento gruppi utente',
    );
  }


  Future<Map<String, dynamic>>
      addGroupMember({
    required int groupId,
    required int userId,
    String role = 'member',
  }) async {
    final Uri url =
        Uri.parse(
      '$baseUrl/add_group_member/$groupId',
    );

    final response =
        await http.post(
      url,
      headers:
          _jsonHeaders,
      body:
          jsonEncode({
        'user_id':
            userId,
        'role':
            role,
      }),
    );

    return _decodeMapResponse(
      response,
      'Errore aggiunta membro',
    );
  }


  Future<void>
      removeGroupMember({
    required int groupId,
    required int userId,
  }) async {
    final Uri url =
        Uri.parse(
      '$baseUrl/remove_group_member/$groupId/$userId',
    );

    final response =
        await http.delete(
      url,
      headers:
          _jsonHeaders,
    );

    _checkSuccess(
      response,
      'Errore rimozione membro',
    );
  }


  Future<Map<String, dynamic>>
      updateGroupMemberRole({
    required int groupId,
    required int userId,
    required String role,
  }) async {
    final Uri url =
        Uri.parse(
      '$baseUrl/update_group_member_role/$groupId/$userId',
    );

    final response =
        await http.patch(
      url,
      headers:
          _jsonHeaders,
      body:
          jsonEncode({
        'role':
            role,
      }),
    );

    return _decodeMapResponse(
      response,
      'Errore modifica ruolo membro',
    );
  }


  Future<Map<String, dynamic>>
      updateGroup({
    required int groupId,
    String? name,
    String? description,
    int? subjectId,
    String? department,
    String? course,
    bool? isPrivate,
  }) async {
    final Map<String, dynamic>
        body =
        {};

    if (name != null) {
      body['name'] =
          name;
    }

    if (description != null) {
      body['description'] =
          description;
    }

    if (subjectId != null) {
      body['subject_id'] =
          subjectId;
    }

    if (department != null) {
      body['department'] =
          department;
    }

    if (course != null) {
      body['course'] =
          course;
    }

    if (isPrivate != null) {
      body['is_private'] =
          isPrivate;
    }

    final Uri url =
        Uri.parse(
      '$baseUrl/update_group/$groupId',
    );

    final response =
        await http.patch(
      url,
      headers:
          _jsonHeaders,
      body:
          jsonEncode(
        body,
      ),
    );

    return _decodeMapResponse(
      response,
      'Errore aggiornamento gruppo',
    );
  }


  Future<void> deleteGroup(
    int groupId,
  ) async {
    final Uri url =
        Uri.parse(
      '$baseUrl/delete_group/$groupId',
    );

    final response =
        await http.delete(
      url,
      headers:
          _jsonHeaders,
    );

    _checkSuccess(
      response,
      'Errore eliminazione gruppo',
    );
  }


  Future<Map<String, dynamic>>
      requestJoinGroup({
    required int groupId,
    required int userId,
  }) async {
    final Uri url =
        Uri.parse(
      '$baseUrl/request_join_group/$groupId',
    );

    final response =
        await http.post(
      url,
      headers:
          _jsonHeaders,
      body:
          jsonEncode({
        'user_id':
            userId,
      }),
    );

    return _decodeMapResponse(
      response,
      'Errore partecipazione gruppo',
    );
  }


  Future<List<Map<String, dynamic>>>
      getGroupRequests(
    int groupId,
  ) async {
    final Uri url =
        Uri.parse(
      '$baseUrl/group_requests/$groupId',
    );

    final response =
        await http.get(
      url,
      headers:
          _jsonHeaders,
    );

    return _decodeListResponse(
      response,
      'Errore caricamento richieste gruppo',
    );
  }


  Future<Map<String, dynamic>>
      acceptGroupRequest(
    int requestId,
  ) async {
    final Uri url =
        Uri.parse(
      '$baseUrl/accept_group_request/$requestId',
    );

    final response =
        await http.post(
      url,
      headers:
          _jsonHeaders,
    );

    return _decodeMapResponse(
      response,
      'Errore accettazione richiesta',
    );
  }


  Future<Map<String, dynamic>>
      rejectGroupRequest(
    int requestId,
  ) async {
    final Uri url =
        Uri.parse(
      '$baseUrl/reject_group_request/$requestId',
    );

    final response =
        await http.post(
      url,
      headers:
          _jsonHeaders,
    );

    return _decodeMapResponse(
      response,
      'Errore rifiuto richiesta',
    );
  }


  // ===========================================================================
  // GROUP MATERIALS
  // ===========================================================================

Future<Map<String, dynamic>>
    addGroupMaterial({
  required int groupId,
  required int uploadedBy,
  required String filePath,
}) async {
  final File file =
      File(
    filePath,
  );

  if (!await file.exists()) {
    throw Exception(
      'Il file selezionato non esiste.',
    );
  }


  // =========================================================================
  // FILE SIZE
  // =========================================================================

  final int size =
      await file.length();

  if (size <= 0) {
    throw Exception(
      'Il file è vuoto.',
    );
  }

  if (size >
      maxMaterialFileSize) {
    throw Exception(
      'Il file supera la dimensione '
      'massima consentita di 250 MB.',
    );
  }


  // =========================================================================
  // FILE INFO
  // =========================================================================

  final String originalName =
      _fileNameFromPath(
    filePath,
  );

  final String mimeType =
      _materialMimeType(
    originalName,
  );


  // =========================================================================
  // 1. RICHIESTA SIGNED URL
  //
  // Flutter invia soltanto metadata.
  //
  // blob-upload.ts:
  // - controlla i dati
  // - chiama FastAPI
  // - verifica gruppo/utente
  // - genera pathname
  // - genera presigned PUT URL
  //
  // Il file NON viene ancora inviato.
  // =========================================================================

  final Uri blobAuthorizationUrl =
      Uri.parse(
    '$baseUrl/api/blob-upload',
  );

  final http.Response
      blobAuthorizationResponse =
      await http.post(
    blobAuthorizationUrl,

    headers:
        _jsonHeaders,

    body:
        jsonEncode({
      'group_id':
          groupId,

      'uploaded_by':
          uploadedBy,

      'original_name':
          originalName,

      'mime_type':
          mimeType,

      'size':
          size,
    }),
  );


  final Map<String, dynamic>
      blobAuthorization =
      _decodeMapResponse(
    blobAuthorizationResponse,
    'Errore autorizzazione Vercel Blob',
  );


  // =========================================================================
  // PATHNAME
  // =========================================================================

  final String? pathname =
      blobAuthorization[
        'pathname'
      ]
          ?.toString();

  if (pathname == null ||
      pathname.isEmpty) {
    throw Exception(
      'Il server non ha restituito '
      'un pathname valido.',
    );
  }


  // =========================================================================
  // PRESIGNED URL
  // =========================================================================

  final String? presignedUrl =
      (
        blobAuthorization[
          'presigned_url'
        ] ??
        blobAuthorization[
          'presignedUrl'
        ]
      )
          ?.toString();

  if (presignedUrl == null ||
      presignedUrl.isEmpty) {
    throw Exception(
      'Il server non ha restituito '
      'un URL di upload valido.',
    );
  }


  // =========================================================================
  // 2. UPLOAD DIRETTO
  //
  // Flutter
  //      |
  //      | file 100 - 250 MB
  //      v
  // Vercel Blob
  //
  // FastAPI NON riceve il file.
  //
  // openRead() permette di inviare il file in streaming.
  // Non facciamo readAsBytes() perché potrebbe occupare centinaia
  // di MB di RAM.
  // =========================================================================

  final Uri uploadUrl =
      Uri.parse(
    presignedUrl,
  );


  final http.StreamedRequest
      uploadRequest =
      http.StreamedRequest(
    'PUT',
    uploadUrl,
  );


  uploadRequest.headers[
    'Content-Type'
  ] = mimeType;


  uploadRequest.contentLength =
      size;


  final Stream<List<int>>
      fileStream =
      file.openRead();


  final Future<void>
      pipeFuture =
      fileStream.pipe(
    uploadRequest.sink,
  );


  final http.StreamedResponse
      uploadResponse =
      await uploadRequest.send();


  await pipeFuture;


  final String uploadBody =
      await uploadResponse.stream
          .bytesToString();


  if (
    uploadResponse.statusCode <
        200 ||
    uploadResponse.statusCode >=
        300
  ) {
    throw Exception(
      'Errore upload Vercel Blob: '
      '${uploadResponse.statusCode}'
      '${uploadBody.isNotEmpty ? ' - $uploadBody' : ''}',
    );
  }


  // =========================================================================
  // 3. REGISTRAZIONE DEL MATERIALE
  //
  // A questo punto:
  //
  // Vercel Blob ✅
  //
  // manca soltanto il record Neon.
  // =========================================================================

  final Uri completeUrl =
      Uri.parse(
    '$baseUrl/'
    'group_material_complete/'
    '$groupId',
  );


  final http.Response
      completeResponse =
      await http.post(
    completeUrl,

    headers:
        _jsonHeaders,

    body:
        jsonEncode({
      'uploaded_by':
          uploadedBy,

      'original_name':
          originalName,

      'stored_name':
          pathname,

      'file_path':
          pathname,

      'mime_type':
          mimeType,

      'size':
          size,
    }),
  );


  return _decodeMapResponse(
    completeResponse,
    'Errore registrazione materiale',
  );
}

  Future<List<Map<String, dynamic>>>
      getGroupMaterials(
    int groupId,
  ) async {
    final Uri url =
        Uri.parse(
      '$baseUrl/group_materials/$groupId',
    );

    final response =
        await http.get(
      url,
      headers:
          _jsonHeaders,
    );

    return _decodeListResponse(
      response,
      'Errore caricamento materiali',
    );
  }


  Future<Uint8List>
      downloadGroupMaterial(
    int materialId,
  ) async {
    final Uri url =
        Uri.parse(
      '$baseUrl/group_material/$materialId',
    );

    final response =
        await http.get(
      url,
      headers:
          _jsonHeaders,
    );

    if (response.statusCode >=
            200 &&
        response.statusCode <
            300) {
      return response.bodyBytes;
    }

    throw Exception(
      'Errore download materiale: '
      '${response.statusCode} - '
      '${response.body}',
    );
  }


  Future<void>
      removeGroupMaterial(
    int materialId,
  ) async {
    final int? userId =
        AuthSession
            .instance
            .currentUserId;

    if (userId == null) {
      throw Exception(
        'Utente non autenticato.',
      );
    }

    final Uri url =
        Uri.parse(
      '$baseUrl/remove_group_material/'
      '$materialId',
    ).replace(
      queryParameters: {
        'user_id':
            userId.toString(),
      },
    );

    final response =
        await http.delete(
      url,
      headers:
          _jsonHeaders,
    );

    _checkSuccess(
      response,
      'Errore eliminazione materiale',
    );
  }


  Future<List<SocialUser>>
      getGroupParticipants(
    int groupId,
  ) async {
    final Uri url =
        Uri.parse(
      '$baseUrl/group/$groupId',
    );

    final response =
        await http.get(
      url,
      headers:
          _jsonHeaders,
    );

    final Map<String, dynamic> group =
        _decodeMapResponse(
      response,
      'Errore caricamento gruppo',
    );

    final dynamic membersData =
        group['members'];

    if (membersData is! List) {
      return [];
    }

    final List<SocialUser> participants =
        [];

    for (final dynamic member
        in membersData) {
      if (member is! Map) {
        continue;
      }

      final Map<String, dynamic>
          memberData =
          Map<String, dynamic>.from(
        member,
      );

      final int? userId =
          _toInt(
        memberData['user_id'],
      );

      if (userId == null) {
        continue;
      }

      try {
        final SocialUser user =
            await getSocialUser(
          userId,
        );

        participants.add(
          user,
        );
      } catch (_) {}
    }

    return participants;
  }


  Future<String> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String department,
    required String course,
    required String description,
    required String role,
    required bool available,
    required bool willingToTeach,
  }) async {
    final Uri url =
        Uri.parse(
      '$baseUrl/register',
    );

    final http.Response response =
        await http.post(
      url,
      headers:
          _jsonHeaders,
      body:
          jsonEncode({
        'first_name':
            firstName,
        'last_name':
            lastName,
        'email':
            email,
        'password':
            password,
        'department':
            department,
        'course':
            course,
        'description':
            description,
        'role':
            role,
        'available':
            available,
        'willing_to_teach':
            willingToTeach,
      }),
    );

    final Map<String, dynamic> data =
        _decodeMapResponse(
      response,
      'Errore registrazione',
    );

    final String? token =
        data['access_token']
            ?.toString();

    if (token == null ||
        token.isEmpty) {
      throw Exception(
        'Token di accesso non restituito dal server.',
      );
    }

    return token;
  }


  Future<String> login({
    required String email,
    required String password,
  }) async {
    final Uri url =
        Uri.parse(
      '$baseUrl/login',
    );

    final http.Response response =
        await http.post(
      url,
      headers:
          _jsonHeaders,
      body:
          jsonEncode({
        'email':
            email,
        'password':
            password,
      }),
    );

    final Map<String, dynamic> data =
        _decodeMapResponse(
      response,
      'Errore accesso',
    );

    final String? token =
        data['access_token']
            ?.toString();

    if (token == null ||
        token.isEmpty) {
      throw Exception(
        'Token di accesso non restituito dal server.',
      );
    }

    return token;
  }


  Future<SocialUser> getCurrentUser({
    String? token,
  }) async {
    final String? accessToken =
        token ??
            AuthSession
                .instance
                .accessToken;

    if (accessToken == null ||
        accessToken.isEmpty) {
      throw Exception(
        'Nessun token di autenticazione disponibile.',
      );
    }

    final Uri url =
        Uri.parse(
      '$baseUrl/me',
    );

    final http.Response response =
        await http.get(
      url,
      headers: {
        'Accept':
            'application/json',
        'Authorization':
            'Bearer $accessToken',
      },
    );

    final Map<String, dynamic> data =
        _decodeMapResponse(
      response,
      'Errore caricamento utente corrente',
    );

    return SocialUser.fromJson(
      data,
    );
  }


  String _fileNameFromPath(
    String filePath,
  ) {
    final String normalized =
        filePath.replaceAll(
      '\\',
      '/',
    );

    final List<String> parts =
        normalized.split(
      '/',
    );

    if (parts.isEmpty) {
      return 'file';
    }

    final String name =
        parts.last;

    if (name.isEmpty) {
      return 'file';
    }

    return name;
  }


  String _materialMimeType(
    String fileName,
  ) {
    final String lower =
        fileName.toLowerCase();

    if (lower.endsWith(
      '.pdf',
    )) {
      return 'application/pdf';
    }

    if (lower.endsWith(
      '.txt',
    )) {
      return 'text/plain';
    }

    if (lower.endsWith(
      '.zip',
    )) {
      return 'application/zip';
    }

    if (lower.endsWith(
      '.docx',
    )) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }

    if (lower.endsWith(
      '.pptx',
    )) {
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    }

    throw Exception(
      'Tipo di file non supportato.',
    );
  }


  Map<String, String>
      get _jsonHeaders {
    final String? token =
        AuthSession
            .instance
            .accessToken;

    return {
      'Content-Type':
          'application/json',

      'Accept':
          'application/json',

      if (token != null &&
          token.isNotEmpty)
        'Authorization':
            'Bearer $token',
    };
  }


  Map<String, dynamic>
      _decodeMapResponse(
    http.Response response,
    String errorMessage,
  ) {
    if (response.statusCode >=
            200 &&
        response.statusCode <
            300) {
      if (response.body.isEmpty) {
        return {};
      }

      final dynamic decoded =
          jsonDecode(
        response.body,
      );

      if (decoded
          is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return Map<String, dynamic>
            .from(
          decoded,
        );
      }

      throw Exception(
        '$errorMessage: '
        'risposta JSON non valida.',
      );
    }

    throw Exception(
      '$errorMessage: '
      '${response.statusCode} - '
      '${response.body}',
    );
  }


  List<Map<String, dynamic>>
      _decodeListResponse(
    http.Response response,
    String errorMessage,
  ) {
    if (response.statusCode >=
            200 &&
        response.statusCode <
            300) {
      if (response.body.isEmpty) {
        return [];
      }

      final dynamic decoded =
          jsonDecode(
        response.body,
      );

      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map(
              (
                item,
              ) =>
                  Map<String, dynamic>
                      .from(
                item,
              ),
            )
            .toList();
      }

      throw Exception(
        '$errorMessage: '
        'risposta JSON non valida.',
      );
    }

    throw Exception(
      '$errorMessage: '
      '${response.statusCode} - '
      '${response.body}',
    );
  }


  void _checkSuccess(
    http.Response response,
    String errorMessage,
  ) {
    if (response.statusCode >=
            200 &&
        response.statusCode <
            300) {
      return;
    }

    throw Exception(
      '$errorMessage: '
      '${response.statusCode} - '
      '${response.body}',
    );
  }


  int? _toInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ??
          '',
    );
  }
}