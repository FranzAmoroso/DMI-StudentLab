import 'package:flutter/material.dart';

import 'package:fe/layers/homeLayer.dart';

import 'package:fe/theme/nightTheme.dart';

import 'package:fe/services/auth_service.dart';
import 'package:fe/services/auth_session.dart';

import 'package:fe/social/social_models.dart';
import 'package:fe/social/social_page.dart';

import 'package:fe/social/auth/login_page.dart';

import 'package:fe/social/widgets/social_profile_type.dart';

import 'package:fe/social/message/message_page.dart';


// =============================================================================
// HOME PAGE
// =============================================================================

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });


  @override
  State<HomePage> createState() =>
      _HomePageState();
}


// =============================================================================
// HOME PAGE STATE
// =============================================================================

class _HomePageState
    extends State<HomePage> {

  final AuthSession _authSession =
      AuthSession.instance;


  final AuthService _authService =
      AuthService();


  bool _restoringSession =
      true;


  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();


    // =========================================================================
    // ASCOLTA CAMBIAMENTI AUTH
    // =========================================================================

    _authSession.addListener(
      _onAuthChanged,
    );


    // =========================================================================
    // RIPRISTINO SESSIONE
    // =========================================================================

    _restoreSession();
  }


  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    _authSession.removeListener(
      _onAuthChanged,
    );

    super.dispose();
  }


  // ===========================================================================
  // AUTH CHANGED
  // ===========================================================================

  void _onAuthChanged() {
    if (!mounted) {
      return;
    }


    setState(() {});
  }


  // ===========================================================================
  // RESTORE SESSION
  // ===========================================================================

  Future<void> _restoreSession() async {
    try {
      await _authService.restoreSession();
    } catch (_) {
      // AuthService gestisce già:
      // - token assente
      // - token scaduto
      // - token non valido
      //
      // In questi casi l'app rimane Guest.
    } finally {
      if (!mounted) {
        return;
      }


      setState(() {
        _restoringSession =
            false;
      });
    }
  }


  // ===========================================================================
  // GETTERS AUTH
  // ===========================================================================

  bool get _isAuthenticated {
    return _authSession.isAuthenticated;
  }


  SocialUser? get _currentUser {
    return _authSession.currentUser;
  }


  // ===========================================================================
  // NOME UTENTE
  // ===========================================================================

  String get _displayName {
    final SocialUser? user =
        _currentUser;


    if (user == null) {
      return 'Utente';
    }


    if (user.firstName.isNotEmpty) {
      return user.firstName;
    }


    if (user.name.isNotEmpty) {
      return user.name;
    }


    return 'Utente';
  }


  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          AppColors.darkElegance,


      // =========================================================================
      // APP BAR
      // =========================================================================

      appBar:
          AppBar(
        backgroundColor:
            AppColors.eleganceMidnight,

        foregroundColor:
            AppColors.pearlWhite,

        elevation:
            AppColors
                .nightAppBarTheme
                .elevation,

        centerTitle:
            false,


        // =======================================================================
        // LOGO
        // =======================================================================

        leading:
            Padding(
          padding:
              const EdgeInsets.all(
            11,
          ),

          child:
              Image.asset(
            'assets/icons/favicon.png',

            width:
                30,

            height:
                30,

            fit:
                BoxFit.contain,
          ),
        ),


        // =======================================================================
        // AZIONI
        // =======================================================================

        actions: [
          if (_restoringSession)
            const Padding(
              padding:
                  EdgeInsets.only(
                right:
                    18,
              ),

              child:
                  Center(
                child:
                    SizedBox(
                  width:
                      20,

                  height:
                      20,

                  child:
                      CircularProgressIndicator(
                    strokeWidth:
                        2,
                  ),
                ),
              ),
            )

          // =====================================================================
          // AUTENTICATO
          // =====================================================================

          else if (_isAuthenticated) ...[
            // -------------------------------------------------------------------
            // MESSAGGI
            // -------------------------------------------------------------------

            _NavbarIconButton(
              tooltip:
                  'Messaggi',

              icon:
                  Icons
                      .chat_bubble_outline_rounded,

              onPressed:
                  () {
                _openMessages();
              },
            ),

            const SizedBox(
              width:
                  7,
            ),


            // -------------------------------------------------------------------
            // USER MENU
            // -------------------------------------------------------------------

            _UserButton(
              name:
                  _displayName,

              onPressed:
                  () {
                _showUserMenu();
              },
            ),

            const SizedBox(
              width:
                  12,
            ),
          ]

          // =====================================================================
          // GUEST
          // =====================================================================

          else ...[
            _AuthButton(
              text:
                  'Accedi',

              filled:
                  false,

              onPressed:
                  () {
                _openLogin();
              },
            ),

            const SizedBox(
              width:
                  8,
            ),

            _AuthButton(
              text:
                  'Sign Up',

              filled:
                  true,

              onPressed:
                  () {
                _openSignUp();
              },
            ),

            const SizedBox(
              width:
                  12,
            ),
          ],
        ],
      ),


      // =========================================================================
      // HOME
      // =========================================================================

      body:
          HomeLayer(
        isAuthenticated:
            _isAuthenticated,
      ),
    );
  }


  // ===========================================================================
  // LOGIN
  // ===========================================================================

  Future<void> _openLogin() async {
    final SocialUser? user =
        await Navigator.of(
      context,
    ).push<SocialUser>(
      MaterialPageRoute(
        builder:
            (_) =>
                const LoginPage(),
      ),
    );


    if (!mounted ||
        user == null) {
      return;
    }


    // AuthService.login() ha già:
    //
    // - salvato JWT
    // - recuperato /me
    // - aggiornato AuthSession
    // - preparato LocalStorage
    //
    // AuthSession notifica automaticamente
    // questa Home tramite _onAuthChanged().

    _showMessage(
      'Accesso effettuato. Benvenuto ${user.firstName}.',
    );
  }


  // ===========================================================================
  // SIGN UP
  // ===========================================================================

  Future<void> _openSignUp() async {
    final SocialUser? user =
        await Navigator.of(
      context,
    ).push<SocialUser>(
      MaterialPageRoute(
        builder:
            (_) =>
                const SocialProfileType(),
      ),
    );


    if (!mounted ||
        user == null) {
      return;
    }


    // Anche in questo caso AuthService.register()
    // ha già creato e salvato la sessione.

    _showMessage(
      'Registrazione completata. Benvenuto ${user.firstName}.',
    );
  }


  // ===========================================================================
  // MESSAGGI
  // ===========================================================================

  Future<void> _openMessages() async {
    if (!_isAuthenticated) {
      return;
    }


    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (_) =>
                const MessagesPage(),
      ),
    );
  }


  // ===========================================================================
  // PROFILO / SOCIAL
  // ===========================================================================

  Future<void> _openProfile() async {
    if (!_isAuthenticated) {
      return;
    }


    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (_) =>
                const SocialPage(),
      ),
    );
  }


  // ===========================================================================
  // LOGOUT
  // ===========================================================================

  Future<void> _logout() async {
    try {
      await _authService.logout();


      if (!mounted) {
        return;
      }


      _showMessage(
        'Disconnessione completata.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }


      _showMessage(
        'Errore durante la disconnessione: $e',
      );
    }
  }


  // ===========================================================================
  // CONFERMA LOGOUT
  // ===========================================================================

  Future<void> _confirmLogout() async {
    final bool? confirmed =
        await showDialog<bool>(
      context:
          context,

      builder:
          (
        dialogContext,
      ) {
        return AlertDialog(
          backgroundColor:
              AppColors.eleganceDeepNavy,

          title:
              const Text(
            'Disconnetti account',

            style:
                TextStyle(
              color:
                  AppColors.pureWhite,
            ),
          ),

          content:
              Text(
            'Vuoi davvero uscire dal tuo account StudentLab? '
            'I file scaricati offline non verranno eliminati.',

            style:
                TextStyle(
              color:
                  AppColors.pureWhite
                      .withOpacity(
                0.65,
              ),

              height:
                  1.4,
            ),
          ),

          actions: [
            TextButton(
              onPressed:
                  () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },

              child:
                  const Text(
                'Annulla',
              ),
            ),

            TextButton(
              onPressed:
                  () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },

              child:
                  const Text(
                'Esci',

                style:
                    TextStyle(
                  color:
                      Colors.redAccent,
                ),
              ),
            ),
          ],
        );
      },
    );


    if (confirmed !=
        true) {
      return;
    }


    await _logout();
  }


  // ===========================================================================
  // MENU UTENTE
  // ===========================================================================

  void _showUserMenu() {
    final SocialUser? user =
        _currentUser;


    if (user == null) {
      return;
    }


    showModalBottomSheet(
      context:
          context,

      backgroundColor:
          AppColors.eleganceDeepNavy,

      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top:
              Radius.circular(
            20,
          ),
        ),
      ),

      builder:
          (
        sheetContext,
      ) {
        return SafeArea(
          child:
              Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              const SizedBox(
                height:
                    8,
              ),


              // ===============================================================
              // HEADER UTENTE
              // ===============================================================

              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  18,
                  12,
                  18,
                  14,
                ),

                child:
                    Row(
                  children: [
                    CircleAvatar(
                      radius:
                          24,

                      backgroundColor:
                          AppColors.skyBlue,

                      child:
                          Text(
                        user.name.isNotEmpty
                            ? user.name[0]
                                .toUpperCase()
                            : '?',

                        style:
                            const TextStyle(
                          color:
                              AppColors
                                  .eleganceSoftNight,

                          fontSize:
                              17,

                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(
                      width:
                          12,
                    ),

                    Expanded(
                      child:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          Text(
                            user.name,

                            maxLines:
                                1,

                            overflow:
                                TextOverflow.ellipsis,

                            style:
                                const TextStyle(
                              color:
                                  AppColors.pureWhite,

                              fontSize:
                                  16,

                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),

                          const SizedBox(
                            height:
                                3,
                          ),

                          Text(
                            user.email,

                            maxLines:
                                1,

                            overflow:
                                TextOverflow.ellipsis,

                            style:
                                TextStyle(
                              color:
                                  AppColors.pureWhite
                                      .withOpacity(
                                0.45,
                              ),

                              fontSize:
                                  11,
                            ),
                          ),

                          const SizedBox(
                            height:
                                3,
                          ),

                          Text(
                            user.type ==
                                    SocialUserType.teacher
                                ? 'Insegnante'
                                : 'Studente',

                            style:
                                const TextStyle(
                              color:
                                  AppColors.materialSky,

                              fontSize:
                                  10,

                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),


              Divider(
                height:
                    1,

                color:
                    AppColors.pureWhite
                        .withOpacity(
                  0.08,
                ),
              ),


              // ===============================================================
              // PROFILO
              // ===============================================================

              ListTile(
                leading:
                    const Icon(
                  Icons
                      .person_outline_rounded,

                  color:
                      AppColors.skyBlue,
                ),

                title:
                    const Text(
                  'Profilo',

                  style:
                      TextStyle(
                    color:
                        AppColors.pureWhite,
                  ),
                ),

                subtitle:
                    Text(
                  'Visualizza il tuo profilo Social',

                  style:
                      TextStyle(
                    color:
                        AppColors.pureWhite
                            .withOpacity(
                      0.42,
                    ),

                    fontSize:
                        10,
                  ),
                ),

                trailing:
                    const Icon(
                  Icons
                      .arrow_forward_ios_rounded,

                  color:
                      Colors.white30,

                  size:
                      14,
                ),

                onTap:
                    () {
                  Navigator.pop(
                    sheetContext,
                  );

                  _openProfile();
                },
              ),


              // ===============================================================
              // MESSAGGI
              // ===============================================================

              ListTile(
                leading:
                    const Icon(
                  Icons
                      .chat_bubble_outline_rounded,

                  color:
                      AppColors.skyBlue,
                ),

                title:
                    const Text(
                  'Messaggi',

                  style:
                      TextStyle(
                    color:
                        AppColors.pureWhite,
                  ),
                ),

                trailing:
                    const Icon(
                  Icons
                      .arrow_forward_ios_rounded,

                  color:
                      Colors.white30,

                  size:
                      14,
                ),

                onTap:
                    () {
                  Navigator.pop(
                    sheetContext,
                  );

                  _openMessages();
                },
              ),


              Divider(
                height:
                    1,

                color:
                    AppColors.pureWhite
                        .withOpacity(
                  0.08,
                ),
              ),


              // ===============================================================
              // LOGOUT
              // ===============================================================

              ListTile(
                leading:
                    const Icon(
                  Icons.logout_rounded,

                  color:
                      Colors.redAccent,
                ),

                title:
                    const Text(
                  'Esci',

                  style:
                      TextStyle(
                    color:
                        Colors.redAccent,
                  ),
                ),

                onTap:
                    () {
                  Navigator.pop(
                    sheetContext,
                  );

                  _confirmLogout();
                },
              ),

              const SizedBox(
                height:
                    6,
              ),
            ],
          ),
        );
      },
    );
  }


  // ===========================================================================
  // MESSAGE
  // ===========================================================================

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
            Text(
          message,
        ),
      ),
    );
  }
}


// =============================================================================
// ICONA NAVBAR
// =============================================================================

class _NavbarIconButton
    extends StatelessWidget {

  final String tooltip;

  final IconData icon;

  final int badge;

  final VoidCallback onPressed;


  const _NavbarIconButton({
    required this.tooltip,

    required this.icon,

    required this.onPressed,

    this.badge = 0,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return Tooltip(
      message:
          tooltip,

      child:
          InkWell(
        onTap:
            onPressed,

        borderRadius:
            BorderRadius.circular(
          12,
        ),

        child:
            SizedBox(
          width:
              42,

          height:
              42,

          child:
              Stack(
            clipBehavior:
                Clip.none,

            children: [
              Center(
                child:
                    Container(
                  width:
                      36,

                  height:
                      36,

                  decoration:
                      BoxDecoration(
                    color:
                        AppColors
                            .brandNightBlue
                            .withOpacity(
                          0.65,
                        ),

                    borderRadius:
                        BorderRadius.circular(
                      11,
                    ),

                    border:
                        Border.all(
                      color:
                          AppColors
                              .skyBlue
                              .withOpacity(
                            0.10,
                          ),
                    ),
                  ),

                  child:
                      Icon(
                    icon,

                    color:
                        AppColors
                            .pureWhite
                            .withOpacity(
                          0.82,
                        ),

                    size:
                        21,
                  ),
                ),
              ),


              if (badge >
                  0)
                Positioned(
                  top:
                      1,

                  right:
                      0,

                  child:
                      Container(
                    constraints:
                        const BoxConstraints(
                      minWidth:
                          17,

                      minHeight:
                          17,
                    ),

                    padding:
                        const EdgeInsets.symmetric(
                      horizontal:
                          4,
                    ),

                    alignment:
                        Alignment.center,

                    decoration:
                        BoxDecoration(
                      color:
                          Colors.redAccent,

                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),

                      border:
                          Border.all(
                        color:
                            AppColors
                                .eleganceMidnight,

                        width:
                            1.5,
                      ),
                    ),

                    child:
                        Text(
                      badge >
                              99
                          ? '99+'
                          : '$badge',

                      style:
                          const TextStyle(
                        color:
                            Colors.white,

                        fontSize:
                            8,

                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


// =============================================================================
// AUTH BUTTON
// =============================================================================

class _AuthButton
    extends StatelessWidget {

  final String text;

  final bool filled;

  final VoidCallback onPressed;


  const _AuthButton({
    required this.text,

    required this.filled,

    required this.onPressed,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return SizedBox(
      height:
          38,

      child:
          OutlinedButton(
        onPressed:
            onPressed,

        style:
            OutlinedButton.styleFrom(
          backgroundColor:
              filled
                  ? AppColors.skyBlue
                  : Colors.transparent,

          side:
              const BorderSide(
            color:
                AppColors.skyBlue,

            width:
                1.2,
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              10,
            ),
          ),

          padding:
              const EdgeInsets.symmetric(
            horizontal:
                14,
          ),

          elevation:
              0,
        ),

        child:
            Text(
          text,

          style:
              TextStyle(
            color:
                filled
                    ? AppColors
                        .eleganceSoftNight
                    : AppColors.skyBlue,

            fontSize:
                13,

            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),
    );
  }
}


// =============================================================================
// USER BUTTON
// =============================================================================

class _UserButton
    extends StatelessWidget {

  final String name;

  final VoidCallback onPressed;


  const _UserButton({
    required this.name,

    required this.onPressed,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return InkWell(
      onTap:
          onPressed,

      borderRadius:
          BorderRadius.circular(
        12,
      ),

      child:
          Container(
        height:
            38,

        padding:
            const EdgeInsets.symmetric(
          horizontal:
              10,
        ),

        decoration:
            BoxDecoration(
          color:
              AppColors.brandNightBlue,

          borderRadius:
              BorderRadius.circular(
            12,
          ),

          border:
              Border.all(
            color:
                AppColors.skyBlue
                    .withOpacity(
              0.25,
            ),
          ),
        ),

        child:
            Row(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            CircleAvatar(
              radius:
                  13,

              backgroundColor:
                  AppColors.skyBlue,

              child:
                  Text(
                name.isNotEmpty
                    ? name[0]
                        .toUpperCase()
                    : '?',

                style:
                    const TextStyle(
                  color:
                      AppColors
                          .eleganceSoftNight,

                  fontSize:
                      12,

                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(
              width:
                  8,
            ),

            Text(
              name,

              maxLines:
                  1,

              overflow:
                  TextOverflow.ellipsis,

              style:
                  const TextStyle(
                color:
                    AppColors.pureWhite,

                fontSize:
                    13,

                fontWeight:
                    FontWeight.w600,
              ),
            ),

            const SizedBox(
              width:
                  4,
            ),

            const Icon(
              Icons
                  .keyboard_arrow_down_rounded,

              color:
                  Colors.white60,

              size:
                  18,
            ),
          ],
        ),
      ),
    );
  }
}