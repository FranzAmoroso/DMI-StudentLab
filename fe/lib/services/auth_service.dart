import '../local_storage/local_storage.dart';

import '../social/social_models.dart';

import 'api_service.dart';
import 'auth_session.dart';


// =============================================================================
// AUTH SERVICE
// =============================================================================

class AuthService {
  final ApiService _apiService;

  final AuthSession _session;

  final LocalStorageService
      _localStorage;


  AuthService({
    ApiService? apiService,

    AuthSession? session,

    LocalStorageService? localStorage,
  })  : _apiService =
            apiService ??
                ApiService(),

        _session =
            session ??
                AuthSession.instance,

        _localStorage =
            localStorage ??
                LocalStorageService();


  // ===========================================================================
  // REGISTER
  // ===========================================================================

  Future<SocialUser> register(
    SocialProfileDraft draft,
  ) async {
    final String accessToken =
        await _apiService.register(
      firstName:
          draft.firstName,

      lastName:
          draft.lastName,

      email:
          draft.email,

      password:
          draft.password,

      department:
          draft.department,

      course:
          draft.course,

      description:
          draft.description,

      role:
          draft.role,

      available:
          draft.available,

      willingToTeach:
          draft.willingToTeach,
    );


    final SocialUser user =
        await _apiService.getCurrentUser(
      token:
          accessToken,
    );


    await _session.setSession(
      accessToken:
          accessToken,

      user:
          user,
    );


    await _localStorage
        .prepareUserSession(
      user.id,
    );


    // =======================================================================
    // MATERIE
    // =======================================================================
    //
    // Dopo la registrazione associamo le materie
    // selezionate nel form.
    // =======================================================================

    for (final SocialSubject subject
        in draft.subjects) {
      await _apiService.addUserSubject(
        userId:
            user.id,

        subjectId:
            subject.id,

        grade:
            subject.grade,

        note:
            subject.note,

        canHelp:
            subject.canHelp,
      );
    }


    // Ricarichiamo l'utente perché ora
    // contiene anche le materie.
    final SocialUser completeUser =
        await _apiService.getCurrentUser();


    _session.updateUser(
      completeUser,
    );


    return completeUser;
  }


  // ===========================================================================
  // LOGIN
  // ===========================================================================

  Future<SocialUser> login({
    required String email,

    required String password,
  }) async {
    final String accessToken =
        await _apiService.login(
      email:
          email,

      password:
          password,
    );


    final SocialUser user =
        await _apiService.getCurrentUser(
      token:
          accessToken,
    );


    await _session.setSession(
      accessToken:
          accessToken,

      user:
          user,
    );


    await _localStorage
        .prepareUserSession(
      user.id,
    );


    return user;
  }


  // ===========================================================================
  // RESTORE SESSION
  // ===========================================================================

  Future<SocialUser?> restoreSession() async {
    final String? token =
        await _session
            .loadStoredToken();


    if (token == null ||
        token.isEmpty) {
      _session.markInitialized();

      return null;
    }


    try {
      final SocialUser user =
          await _apiService
              .getCurrentUser(
        token:
            token,
      );


      _session.setRestoredSession(
        accessToken:
            token,

        user:
            user,
      );


      await _localStorage
          .prepareUserSession(
        user.id,
      );


      return user;
    } catch (_) {
      // Token scaduto / non valido.
      await _session.clear();

      return null;
    }
  }


  // ===========================================================================
  // REFRESH CURRENT USER
  // ===========================================================================

  Future<SocialUser?> refreshCurrentUser() async {
    if (!_session.isAuthenticated) {
      return null;
    }


    final SocialUser user =
        await _apiService
            .getCurrentUser();


    _session.updateUser(
      user,
    );


    return user;
  }


  // ===========================================================================
  // LOGOUT
  // ===========================================================================

  Future<void> logout() async {
    final int? userId =
        _session.currentUserId;


    if (userId != null) {
      await _localStorage
          .onLogout(
        userId,
      );
    }


    await _session.clear();
  }
}