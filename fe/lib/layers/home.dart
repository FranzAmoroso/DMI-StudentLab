import 'package:flutter/material.dart';

import 'package:fe/layers/homeLayer.dart';
import 'package:fe/theme/nightTheme.dart';

import 'package:fe/social/message/message_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
  });

  // ===========================================================================
  // STATO AUTENTICAZIONE
  // ===========================================================================
  //
  // Temporaneo.
  //
  // true  -> utente autenticato
  // false -> guest
  //
  // In futuro verrà sostituito da:
  //
  // AuthService
  // Token
  // SQLite locale
  // verifica backend
  //
  // ===========================================================================

  static const bool isAuthenticated = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.darkElegance,

      // =========================================================================
      // APP BAR
      // =========================================================================

      appBar: AppBar(
        backgroundColor:
            AppColors.eleganceMidnight,

        foregroundColor:
            AppColors.pearlWhite,

        elevation:
            AppColors.nightAppBarTheme.elevation,

        centerTitle:
            false,

        // =======================================================================
        // LOGO
        // =======================================================================

        leading: IconButton(
          tooltip:
              'Home',

          icon: Image.asset(
            'assets/icons/favicon.png',

            width:
                30,

            height:
                30,
          ),

          onPressed: () {
            // Siamo già nella Home.
          },
        ),

        // =======================================================================
        // AZIONI
        // =======================================================================

        actions: [
          // =====================================================================
          // UTENTE AUTENTICATO
          // =====================================================================

          if (isAuthenticated) ...[
            // -------------------------------------------------------------------
            // NOTIFICHE
            // -------------------------------------------------------------------

            _NavbarIconButton(
              tooltip:
                  'Notifiche',

              icon:
                  Icons.notifications_none_rounded,

              badge:
                  3,

              onPressed: () {
                _openNotifications(
                  context,
                );
              },
            ),

            const SizedBox(
              width:
                  2,
            ),

            // -------------------------------------------------------------------
            // MESSAGGI
            // -------------------------------------------------------------------

            _NavbarIconButton(
              tooltip:
                  'Messaggi',

              icon:
                  Icons.chat_bubble_outline_rounded,

              badge:
                  2,

              onPressed: () {
                _openMessages(
                  context,
                );
              },
            ),

            const SizedBox(
              width:
                  8,
            ),

            // -------------------------------------------------------------------
            // PROFILO
            // -------------------------------------------------------------------

            _UserButton(
              name:
                  'Franz',

              onPressed: () {
                _showUserMenu(
                  context,
                );
              },
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

              onPressed: () {
                _openLogin(
                  context,
                );
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

              onPressed: () {
                _openSignUp(
                  context,
                );
              },
            ),
          ],

          const SizedBox(
            width:
                12,
          ),
        ],
      ),

      // =========================================================================
      // HOME
      // =========================================================================

      body: HomeLayer(
        isAuthenticated:
            isAuthenticated,
      ),
    );
  }

  // ===========================================================================
  // NOTIFICHE
  // ===========================================================================

  static void _openNotifications(
    BuildContext context,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Pagina notifiche: da implementare.',
        ),
      ),
    );
  }

  // ===========================================================================
  // MESSAGGI
  // ===========================================================================

  static void _openMessages(
    BuildContext context,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const MessagesPage(),
      ),
    );
  }

  // ===========================================================================
  // LOGIN
  // ===========================================================================

  static void _openLogin(
    BuildContext context,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Login: da collegare.',
        ),
      ),
    );
  }

  // ===========================================================================
  // SIGN UP
  // ===========================================================================

  static void _openSignUp(
    BuildContext context,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Registrazione: da collegare.',
        ),
      ),
    );
  }

  // ===========================================================================
  // MENU UTENTE
  // ===========================================================================

  static void _showUserMenu(
    BuildContext context,
  ) {
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
              Radius.circular(20),
        ),
      ),

      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              const SizedBox(
                height:
                    8,
              ),

              // -----------------------------------------------------------------
              // PROFILO
              // -----------------------------------------------------------------

              ListTile(
                leading:
                    const Icon(
                  Icons.person_outline_rounded,

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

                onTap: () {
                  Navigator.pop(
                    sheetContext,
                  );

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Profilo: da collegare.',
                      ),
                    ),
                  );
                },
              ),

              // -----------------------------------------------------------------
              // IMPOSTAZIONI
              // -----------------------------------------------------------------

              ListTile(
                leading:
                    const Icon(
                  Icons.settings_outlined,

                  color:
                      AppColors.skyBlue,
                ),

                title:
                    const Text(
                  'Impostazioni',

                  style:
                      TextStyle(
                    color:
                        AppColors.pureWhite,
                  ),
                ),

                onTap: () {
                  Navigator.pop(
                    sheetContext,
                  );
                },
              ),

              // -----------------------------------------------------------------
              // LOGOUT
              // -----------------------------------------------------------------

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

                onTap: () {
                  Navigator.pop(
                    sheetContext,
                  );

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Logout: da implementare.',
                      ),
                    ),
                  );
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
}

// =============================================================================
// ICONA NAVBAR
//
// Utilizzata per notifiche e messaggi.
// Può visualizzare un piccolo badge numerico.
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

      child: InkWell(
        onTap:
            onPressed,

        borderRadius:
            BorderRadius.circular(12),

        child: SizedBox(
          width:
              42,

          height:
              42,

          child: Stack(
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
                        AppColors.brandNightBlue
                            .withOpacity(0.65),

                    borderRadius:
                        BorderRadius.circular(11),

                    border:
                        Border.all(
                      color:
                          AppColors.skyBlue
                              .withOpacity(0.10),
                    ),
                  ),

                  child:
                      Icon(
                    icon,

                    color:
                        AppColors.pureWhite
                            .withOpacity(0.82),

                    size:
                        21,
                  ),
                ),
              ),

              // ===============================================================
              // BADGE
              // ===============================================================

              if (badge > 0)
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
                          BorderRadius.circular(10),

                      border:
                          Border.all(
                        color:
                            AppColors.eleganceMidnight,

                        width:
                            1.5,
                      ),
                    ),

                    child:
                        Text(
                      badge > 99
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
              BorderSide(
            color:
                AppColors.skyBlue,

            width:
                1.2,
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(10),
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
                    ? AppColors.eleganceSoftNight
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
          BorderRadius.circular(12),

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
              BorderRadius.circular(12),

          border:
              Border.all(
            color:
                AppColors.skyBlue
                    .withOpacity(0.25),
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
                    ? name[0].toUpperCase()
                    : '?',

                style:
                    const TextStyle(
                  color:
                      AppColors.eleganceSoftNight,

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
              Icons.keyboard_arrow_down_rounded,

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