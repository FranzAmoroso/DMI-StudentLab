import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/quiz_model.dart';

import '../social/social_models.dart';
import 'auth_session.dart';


// =============================================================================
// API SERVICE
// =============================================================================

class ApiService {
  // ===========================================================================
  // BACKEND
  // ===========================================================================

  final String baseUrl =
      'https://dmi-student-lab.vercel.app';


  /*
   * Temporaneamente il Social utilizza
   * il backend FastAPI locale.
   *
   * Quando PostgreSQL remoto e deployment
   * saranno configurati potremo utilizzare
   * direttamente baseUrl.
   */
  final String socialBaseUrl;


  ApiService({
    this.socialBaseUrl =
        'http://127.0.0.1:8000',
  });


  // ===========================================================================
  // ARGOMENTI QUIZ
  // ===========================================================================

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

        headers: {
          'Content-Type':
              'application/json',
        },

        body: jsonEncode({
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


  // ===========================================================================
  // NUMERO DOMANDE
  // ===========================================================================

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

        headers: {
          'Content-Type':
              'application/json',
        },

        body: jsonEncode({
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


  // ===========================================================================
  // QUIZ
  // ===========================================================================

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

        headers: {
          'Content-Type':
              'application/json',
        },

        body: jsonEncode({
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
                  QuizModel
                      .fromJson(
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


  // ===========================================================================
  // VALIDAZIONE RISPOSTA
  // ===========================================================================

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

        headers: {
          'Content-Type':
              'application/json',
        },

        body: jsonEncode({
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


  // ===========================================================================
  // MATERIE QUIZ
  // ===========================================================================

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

        headers: {
          'Content-Type':
              'application/json',
        },

        body: jsonEncode({
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


  // ===========================================================================
  // SOCIAL - CREA UTENTE
  // ===========================================================================

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
      final Uri url = Uri.parse(
        '$socialBaseUrl/create_user',
      );

      final http.Response response =
          await http.post(
        url,
        headers: _jsonHeaders,
        body: jsonEncode({
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'department': department,
          'course': course,
          'description': description,
          'role': role,
          'available': available,
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


  // ===========================================================================
  // SOCIAL - TUTTI GLI UTENTI
  // ===========================================================================

  Future<List<SocialUser>>
      getSocialUsers() async {
    final Uri url =
        Uri.parse(
      '$socialBaseUrl/users',
    );


    final response =
        await http.get(
      url,
    );


    final List<
            Map<String, dynamic>>
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


  // ===========================================================================
  // SOCIAL - UTENTE PER ID
  // ===========================================================================

    Future<SocialUser> getSocialUser(
      int userId,
    ) async {
      final Uri url = Uri.parse(
        '$socialBaseUrl/user/$userId',
      );

      final http.Response response =
          await http.get(
        url,
        headers: _jsonHeaders,
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


  // ===========================================================================
  // SOCIAL - AGGIORNA UTENTE
  // ===========================================================================

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
        body = {};


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
      '$socialBaseUrl/'
      'update_user/$userId',
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


  // ===========================================================================
  // SOCIAL - MATERIE
  // ===========================================================================

  Future<List<SocialSubject>>
      getSocialSubjects(
    String department,
    String course,
  ) async {
    final Uri url =
        Uri.parse(
      '$socialBaseUrl/'
      'social_subjects/'
      '$department/$course',
    );


    final response =
        await http.get(
      url,
    );


    final List<
            Map<String, dynamic>>
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


  // ===========================================================================
  // SOCIAL - AGGIUNGI MATERIA
  // ===========================================================================

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
      '$socialBaseUrl/'
      'add_user_subject/$userId',
    );


    final response =
        await http.post(
      url,

      headers:
          _jsonHeaders,

      body: jsonEncode({
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


  // ===========================================================================
  // SOCIAL - RIMUOVI MATERIA
  // ===========================================================================

  Future<void>
      removeUserSubject({
    required int userId,

    required int subjectId,
  }) async {
    final Uri url =
        Uri.parse(
      '$socialBaseUrl/'
      'remove_user_subject/'
      '$userId/$subjectId',
    );


    final response =
        await http.delete(
      url,
    );


    _checkSuccess(
      response,

      'Errore rimozione materia',
    );
  }



    Future<Map<String, dynamic>> createGroup({
      required String name,
      required String description,
      required int subjectId,
      required String department,
      required String course,
      required bool isPrivate,
      required int createdBy,
    }) async {
      final Uri url = Uri.parse(
        '$socialBaseUrl/create_group',
      );

      final http.Response response =
          await http.post(
        url,
        headers: _jsonHeaders,
        body: jsonEncode({
          'name': name,
          'description': description,
          'subject_id': subjectId,
          'department': department,
          'course': course,
          'is_private': isPrivate,
          'created_by': createdBy,
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
      '$socialBaseUrl/groups',
    );


    final response =
        await http.get(
      url,
    );


    return _decodeListResponse(
      response,

      'Errore caricamento gruppi',
    );
  }


  // ===========================================================================
  // SOCIAL - GRUPPO
  // ===========================================================================

  Future<Map<String, dynamic>>
      getGroup(
    int groupId,
  ) async {
    final Uri url =
        Uri.parse(
      '$socialBaseUrl/group/$groupId',
    );


    final response =
        await http.get(
      url,
    );


    return _decodeMapResponse(
      response,

      'Errore caricamento gruppo',
    );
  }


  // ===========================================================================
  // SOCIAL - GRUPPI UTENTE
  // ===========================================================================

  Future<List<Map<String, dynamic>>>
      getUserGroups(
    int userId,
  ) async {
    final Uri url =
        Uri.parse(
      '$socialBaseUrl/'
      'user_groups/$userId',
    );


    final response =
        await http.get(
      url,
    );


    return _decodeListResponse(
      response,

      'Errore caricamento gruppi utente',
    );
  }


  // ===========================================================================
  // SOCIAL - AGGIUNGI MEMBRO
  // ===========================================================================

  Future<Map<String, dynamic>>
      addGroupMember({
    required int groupId,

    required int userId,

    String role = 'member',
  }) async {
    final Uri url =
        Uri.parse(
      '$socialBaseUrl/'
      'add_group_member/$groupId',
    );


    final response =
        await http.post(
      url,

      headers:
          _jsonHeaders,

      body: jsonEncode({
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


  // ===========================================================================
  // SOCIAL - RIMUOVI MEMBRO
  // ===========================================================================

  Future<void>
      removeGroupMember({
    required int groupId,

    required int userId,
  }) async {
    final Uri url =
        Uri.parse(
      '$socialBaseUrl/'
      'remove_group_member/'
      '$groupId/$userId',
    );


    final response =
        await http.delete(
      url,
    );


    _checkSuccess(
      response,

      'Errore rimozione membro',
    );
  }


  // ===========================================================================
  // SOCIAL - CAMBIO RUOLO
  // ===========================================================================

  Future<Map<String, dynamic>>
      updateGroupMemberRole({
    required int groupId,

    required int userId,

    required String role,
  }) async {
    final Uri url =
        Uri.parse(
      '$socialBaseUrl/'
      'update_group_member_role/'
      '$groupId/$userId',
    );


    final response =
        await http.patch(
      url,

      headers:
          _jsonHeaders,

      body: jsonEncode({
        'role':
            role,
      }),
    );


    return _decodeMapResponse(
      response,

      'Errore modifica ruolo membro',
    );
  }


  // ===========================================================================
  // SOCIAL - MODIFICA GRUPPO
  // ===========================================================================

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
        body = {};


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
      '$socialBaseUrl/'
      'update_group/$groupId',
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


  // ===========================================================================
  // SOCIAL - ELIMINA GRUPPO
  // ===========================================================================

  Future<void> deleteGroup(
    int groupId,
  ) async {
    final Uri url =
        Uri.parse(
      '$socialBaseUrl/'
      'delete_group/$groupId',
    );


    final response =
        await http.delete(
      url,
    );


    _checkSuccess(
      response,

      'Errore eliminazione gruppo',
    );
  }


  // ===========================================================================
  // SOCIAL - RICHIESTA INGRESSO
  // ===========================================================================

  Future<Map<String, dynamic>>
      requestJoinGroup({
    required int groupId,

    required int userId,
  }) async {
    final Uri url =
        Uri.parse(
      '$socialBaseUrl/'
      'request_join_group/$groupId',
    );


    final response =
        await http.post(
      url,

      headers:
          _jsonHeaders,

      body: jsonEncode({
        'user_id':
            userId,
      }),
    );


    return _decodeMapResponse(
      response,

      'Errore partecipazione gruppo',
    );
  }


  // ===========================================================================
  // SOCIAL - RICHIESTE GRUPPO
  // ===========================================================================

  Future<List<Map<String, dynamic>>>
      getGroupRequests(
    int groupId,
  ) async {
    final Uri url =
        Uri.parse(
      '$socialBaseUrl/'
      'group_requests/$groupId',
    );


    final response =
        await http.get(
      url,
    );


    return _decodeListResponse(
      response,

      'Errore caricamento richieste gruppo',
    );
  }


  // ===========================================================================
  // SOCIAL - ACCETTA RICHIESTA
  // ===========================================================================

  Future<Map<String, dynamic>>
      acceptGroupRequest(
    int requestId,
  ) async {
    final Uri url =
        Uri.parse(
      '$socialBaseUrl/'
      'accept_group_request/'
      '$requestId',
    );


    final response =
        await http.post(
      url,
    );


    return _decodeMapResponse(
      response,

      'Errore accettazione richiesta',
    );
  }


  // ===========================================================================
  // SOCIAL - RIFIUTA RICHIESTA
  // ===========================================================================

  Future<Map<String, dynamic>>
      rejectGroupRequest(
    int requestId,
  ) async {
    final Uri url =
        Uri.parse(
      '$socialBaseUrl/'
      'reject_group_request/'
      '$requestId',
    );


    final response =
        await http.post(
      url,
    );


    return _decodeMapResponse(
      response,

      'Errore rifiuto richiesta',
    );
  }


  // ===========================================================================
  // SOCIAL - UPLOAD MATERIALE
  // ===========================================================================

  Future<Map<String, dynamic>>
      addGroupMaterial({
    required int groupId,

    required int uploadedBy,

    required String filePath,
  }) async {
    final Uri url =
        Uri.parse(
      '$socialBaseUrl/'
      'add_group_material/$groupId',
    );


    final request =
        http.MultipartRequest(
      'POST',
      url,
    );


    request.fields[
            'uploaded_by'] =
        uploadedBy.toString();


    request.files.add(
      await http.MultipartFile
          .fromPath(
        'file',
        filePath,
      ),
    );


    final streamedResponse =
        await request.send();


    final response =
        await http.Response
            .fromStream(
      streamedResponse,
    );


    return _decodeMapResponse(
      response,

      'Errore caricamento materiale',
    );
  }


  // ===========================================================================
  // SOCIAL - MATERIALI GRUPPO
  // ===========================================================================

  Future<List<Map<String, dynamic>>>
      getGroupMaterials(
    int groupId,
  ) async {
    final Uri url =
        Uri.parse(
      '$socialBaseUrl/'
      'group_materials/$groupId',
    );


    final response =
        await http.get(
      url,
    );


    return _decodeListResponse(
      response,

      'Errore caricamento materiali',
    );
  }


  // ===========================================================================
  // SOCIAL - DOWNLOAD MATERIALE
  // ===========================================================================

  Future<Uint8List>
      downloadGroupMaterial(
    int materialId,
  ) async {
    final Uri url =
        Uri.parse(
      '$socialBaseUrl/'
      'group_material/$materialId',
    );


    final response =
        await http.get(
      url,
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


  // ===========================================================================
  // SOCIAL - ELIMINA MATERIALE
  // ===========================================================================

  Future<void>
      removeGroupMaterial(
    int materialId,
  ) async {
    final Uri url =
        Uri.parse(
      '$socialBaseUrl/'
      'remove_group_material/'
      '$materialId',
    );


    final response =
        await http.delete(
      url,
    );


    _checkSuccess(
      response,

      'Errore eliminazione materiale',
    );
  }


  // ===========================================================================
  // HEADERS
  // ===========================================================================

  Map<String, String>
      get _jsonHeaders {
    return {
      'Content-Type':
          'application/json',

      'Accept':
          'application/json',
    };
  }


  // ===========================================================================
  // DECODE MAP
  // ===========================================================================

  Map<String, dynamic>
      _decodeMapResponse(
    http.Response response,
    String errorMessage,
  ) {
    if (response.statusCode >=
            200 &&
        response.statusCode <
            300) {
      if (response.body
          .isEmpty) {
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


  // ===========================================================================
  // DECODE LIST
  // ===========================================================================

  List<Map<String, dynamic>>
      _decodeListResponse(
    http.Response response,
    String errorMessage,
  ) {
    if (response.statusCode >=
            200 &&
        response.statusCode <
            300) {
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


  // ===========================================================================
  // SUCCESS CHECK
  // ===========================================================================

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

  Future<List<SocialUser>>
    getGroupParticipants(
  int groupId,
) async {
  final Uri url = Uri.parse(
    '$socialBaseUrl/group/$groupId',
  );

  final response =
      await http.get(url);

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

    final dynamic rawUserId =
        memberData['user_id'];

    final int? userId =
        rawUserId is int
            ? rawUserId
            : int.tryParse(
                rawUserId
                        ?.toString() ??
                    '',
              );

    if (userId == null) {
      continue;
    }

    final SocialUser user =
        await getSocialUser(
      userId,
    );

    participants.add(
      user,
    );
  }

  return participants;
}

// ===========================================================================
// AUTH - REGISTER
// ===========================================================================

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
    '$socialBaseUrl/register',
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
// ===========================================================================
// AUTH - LOGIN
// ===========================================================================

Future<String> login({
  required String email,
  required String password,
}) async {
  final Uri url =
      Uri.parse(
    '$socialBaseUrl/login',
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
// ===========================================================================
// AUTH - CURRENT USER
// ===========================================================================

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
    '$socialBaseUrl/me',
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
}

