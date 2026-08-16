import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../social/social_models.dart';


// =============================================================================
// AUTH SESSION
// =============================================================================

class AuthSession extends ChangeNotifier {
  AuthSession._();


  // ===========================================================================
  // SINGLETON
  // ===========================================================================

  static final AuthSession instance =
      AuthSession._();


  // ===========================================================================
  // SECURE STORAGE
  // ===========================================================================

  static const String _accessTokenKey =
      'studentlab_access_token';


  final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage();


  // ===========================================================================
  // STATE
  // ===========================================================================

  SocialUser? _currentUser;

  String? _accessToken;

  bool _initialized =
      false;


  // ===========================================================================
  // GETTERS
  // ===========================================================================

  SocialUser? get currentUser {
    return _currentUser;
  }


  String? get accessToken {
    return _accessToken;
  }


  bool get isAuthenticated {
    return _currentUser != null &&
        _accessToken != null;
  }


  bool get isGuest {
    return !isAuthenticated;
  }


  bool get initialized {
    return _initialized;
  }


  int? get currentUserId {
    return _currentUser?.id;
  }


  // ===========================================================================
  // LOAD TOKEN
  // ===========================================================================

  Future<String?> loadStoredToken() async {
    final String? token =
        await _secureStorage.read(
      key:
          _accessTokenKey,
    );

    _accessToken =
        token;

    return token;
  }


  // ===========================================================================
  // SET SESSION
  // ===========================================================================

  Future<void> setSession({
    required String accessToken,
    required SocialUser user,
  }) async {
    _accessToken =
        accessToken;

    _currentUser =
        user;


    await _secureStorage.write(
      key:
          _accessTokenKey,

      value:
          accessToken,
    );


    _initialized =
        true;


    notifyListeners();
  }


  // ===========================================================================
  // RESTORED SESSION
  // ===========================================================================

  void setRestoredSession({
    required String accessToken,
    required SocialUser user,
  }) {
    _accessToken =
        accessToken;

    _currentUser =
        user;

    _initialized =
        true;

    notifyListeners();
  }


  // ===========================================================================
  // USER UPDATE
  // ===========================================================================

  void updateUser(
    SocialUser user,
  ) {
    _currentUser =
        user;

    notifyListeners();
  }


  // ===========================================================================
  // MARK INITIALIZED
  // ===========================================================================

  void markInitialized() {
    _initialized =
        true;

    notifyListeners();
  }


  // ===========================================================================
  // CLEAR
  // ===========================================================================

  Future<void> clear() async {
    _currentUser =
        null;

    _accessToken =
        null;

    await _secureStorage.delete(
      key:
          _accessTokenKey,
    );

    _initialized =
        true;

    notifyListeners();
  }
}