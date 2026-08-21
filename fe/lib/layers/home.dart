import 'dart:async';

import 'package:flutter/material.dart';

import 'package:fe/layers/homeLayer.dart';

import 'package:fe/theme/nightTheme.dart';

import 'package:fe/services/api_service.dart';
import 'package:fe/services/auth_service.dart';
import 'package:fe/services/auth_session.dart';

import 'package:fe/social/social_models.dart';
import 'package:fe/social/social_page.dart';

import 'package:fe/social/message/message_page.dart';

import 'package:fe/social/notifications/notifications_page.dart';

import 'package:fe/social/admin/admin_panel_page.dart';

import 'package:fe/social/teacher/teachear_area_page.dart';


class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  State<HomePage> createState() =>
      _HomePageState();
}


class _HomePageState
    extends State<HomePage> {
  final AuthSession _authSession =
      AuthSession.instance;

  final AuthService _authService =
      AuthService();

  final ApiService _apiService =
      ApiService();

  bool _restoringSession =
      true;

  bool _loadingPermissions =
      false;

  bool _loadingNotifications =
      false;

  bool _adminAccess =
      false;

  bool _teacherAccess =
      false;

  int _unreadNotificationCount =
      0;


  @override
  void initState() {
    super.initState();

    _authSession.addListener(
      _onAuthChanged,
    );

    _restoreSession();
  }


  @override
  void dispose() {
    _authSession.removeListener(
      _onAuthChanged,
    );

    super.dispose();
  }


  void _onAuthChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});

    if (!_authSession.isAuthenticated) {
      setState(() {
        _adminAccess =
            false;

        _teacherAccess =
            false;

        _unreadNotificationCount =
            0;
      });

      return;
    }

    unawaited(
      Future.wait([
        _loadPermissions(),
        _loadUnreadNotifications(),
      ]),
    );
  }


  Future<void> _restoreSession() async {
    try {
      await _authService
          .restoreSession();

      if (
        _authSession
            .isAuthenticated
      ) {
        await Future.wait([
          _loadPermissions(),
          _loadUnreadNotifications(),
        ]);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _adminAccess =
              false;

          _teacherAccess =
              false;

          _unreadNotificationCount =
              0;
        });
      }
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


  Future<void>
      _loadPermissions() async {
    if (
      !_authSession
          .isAuthenticated
    ) {
      if (mounted) {
        setState(() {
          _adminAccess =
              false;

          _teacherAccess =
              false;
        });
      }

      return;
    }

    if (_loadingPermissions) {
      return;
    }

    _loadingPermissions =
        true;

    try {
      final List<bool> permissions =
          await Future.wait<bool>([
        _apiService
            .canAccessAdminPanel(),

        _apiService
            .canAccessTeacherArea(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _adminAccess =
            permissions[0];

        _teacherAccess =
            permissions[1];
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _adminAccess =
            false;

        _teacherAccess =
            false;
      });
    } finally {
      _loadingPermissions =
          false;
    }
  }


  Future<void>
      _loadUnreadNotifications() async {
    if (!_isAuthenticated) {
      if (mounted) {
        setState(() {
          _unreadNotificationCount =
              0;
        });
      }

      return;
    }

    if (_loadingNotifications) {
      return;
    }

    _loadingNotifications =
        true;

    try {
      final int count =
          await _apiService
              .getUnreadNotificationCount();

      if (!mounted) {
        return;
      }

      setState(() {
        _unreadNotificationCount =
            count;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _unreadNotificationCount =
            0;
      });
    } finally {
      _loadingNotifications =
          false;
    }
  }


  bool get _isAuthenticated {
    return _authSession
        .isAuthenticated;
  }


  SocialUser? get _currentUser {
    return _authSession
        .currentUser;
  }


  String get _displayName {
    final SocialUser? user =
        _currentUser;

    if (user == null) {
      return 'Utente';
    }

    if (
      user.firstName
          .isNotEmpty
    ) {
      return user.firstName;
    }

    if (user.name.isNotEmpty) {
      return user.name;
    }

    return 'Utente';
  }


  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          AppColors.darkElegance,


appBar: AppBar(
  backgroundColor: AppColors.eleganceMidnight,
  elevation: AppColors.nightAppBarTheme.elevation,
  centerTitle: false,
  leading: Padding(
    padding: const EdgeInsets.all(6),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: Image.asset(
        'assets/icons/favicon.png',
        width: 44,
        height: 44,
        fit: BoxFit.cover,
      ),
    ),
  ),
  actions: [
    if (_restoringSession)
      const Padding(
        padding: EdgeInsets.only(right: 18),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),
      )
    else if (_isAuthenticated) ...[
      _NavbarIconButton(
        tooltip: 'Messaggi',
        icon: Icons.chat_bubble_outline_rounded,
        onPressed: _openMessages,
      ),
      const SizedBox(width: 7),
      _NavbarIconButton(
        tooltip: 'Notifiche',
        icon: Icons.notifications_none_rounded,
        badge: _unreadNotificationCount,
        onPressed: _openNotifications,
      ),
      const SizedBox(width: 7),
      _UserButton(
        name: _displayName,
        onPressed: _showUserMenu,
      ),
      const SizedBox(width: 12),
    ],
  ],
),

      body:
          HomeLayer(),
    );
  }


  Future<void>
      _openMessages() async {
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


  Future<void>
      _openNotifications() async {
    if (!_isAuthenticated) {
      return;
    }

    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (_) =>
                const NotificationsPage(),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadUnreadNotifications();
  }


  Future<void>
      _openProfile() async {
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


  Future<void>
      _openAdminPanel() async {
    if (!_isAuthenticated) {
      return;
    }

    try {
      final bool authorized =
          await _apiService
              .canAccessAdminPanel();

      if (!mounted) {
        return;
      }

      if (!authorized) {
        setState(() {
          _adminAccess =
              false;
        });

        _showMessage(
          'Non hai i permessi per accedere all\'Admin Panel.',
        );

        return;
      }

      await Navigator.of(
        context,
      ).push(
        MaterialPageRoute(
          builder:
              (_) =>
                  const AdminPanelPage(),
        ),
      );

      if (!mounted) {
        return;
      }

      await _loadPermissions();
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Impossibile verificare i permessi amministrativi.',
      );
    }
  }


  Future<void>
      _openTeacherArea() async {
    if (!_isAuthenticated) {
      return;
    }

    try {
      final bool authorized =
          await _apiService
              .canAccessTeacherArea();

      if (!mounted) {
        return;
      }

      if (!authorized) {
        setState(() {
          _teacherAccess =
              false;
        });

        _showMessage(
          'Non hai i permessi per accedere all\'Area Docenti.',
        );

        return;
      }

      await Navigator.of(
        context,
      ).push(
        MaterialPageRoute(
          builder:
              (_) =>
                  const TeacherAreaPage(),
        ),
      );

      if (!mounted) {
        return;
      }

      await _loadPermissions();
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Impossibile verificare i permessi docente.',
      );
    }
  }


  Future<void> _logout() async {
    try {
      await _authService.logout();

      if (!mounted) {
        return;
      }

      setState(() {
        _adminAccess =
            false;

        _teacherAccess =
            false;

        _unreadNotificationCount =
            0;
      });

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


  Future<void>
      _confirmLogout() async {
    final bool? confirmed =
        await showDialog<bool>(
      context:
          context,

      builder:
          (
        BuildContext dialogContext,
      ) {
        return AlertDialog(
          backgroundColor:
              AppColors
                  .eleganceDeepNavy,

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

    if (confirmed != true) {
      return;
    }

    await _logout();
  }


  void _showUserMenu() {
    final SocialUser? user =
        _currentUser;

    if (user == null) {
      return;
    }

    showModalBottomSheet<void>(
      context:
          context,

      backgroundColor:
          AppColors
              .eleganceDeepNavy,

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
        BuildContext sheetContext,
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

              Padding(
                padding:
                    const EdgeInsets
                        .fromLTRB(
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
                            CrossAxisAlignment
                                .start,

                        children: [
                          Text(
                            user.name,

                            maxLines:
                                1,

                            overflow:
                                TextOverflow
                                    .ellipsis,

                            style:
                                const TextStyle(
                              color:
                                  AppColors
                                      .pureWhite,

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
                                TextOverflow
                                    .ellipsis,

                            style:
                                TextStyle(
                              color:
                                  AppColors
                                      .pureWhite
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
                            _adminAccess
                                ? 'Amministratore'
                                : _teacherAccess
                                    ? 'Docente verificato'
                                    : user.type ==
                                            SocialUserType.teacher
                                        ? 'Insegnante'
                                        : 'Studente',

                            style:
                                const TextStyle(
                              color:
                                  AppColors
                                      .materialSky,

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

              ListTile(
                leading:
                    const Icon(
                  Icons
                      .notifications_none_rounded,

                  color:
                      AppColors.skyBlue,
                ),

                title:
                    const Text(
                  'Notifiche',

                  style:
                      TextStyle(
                    color:
                        AppColors.pureWhite,
                  ),
                ),

                trailing:
                    Row(
                  mainAxisSize:
                      MainAxisSize.min,

                  children: [
                    if (
                      _unreadNotificationCount >
                          0
                    )
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal:
                              7,

                          vertical:
                              3,
                        ),

                        decoration:
                            BoxDecoration(
                          color:
                              Colors
                                  .redAccent,

                          borderRadius:
                              BorderRadius
                                  .circular(
                            10,
                          ),
                        ),

                        child:
                            Text(
                          _unreadNotificationCount >
                                  99
                              ? '99+'
                              : '$_unreadNotificationCount',

                          style:
                              const TextStyle(
                            color:
                                Colors.white,

                            fontSize:
                                10,

                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),

                    const SizedBox(
                      width:
                          8,
                    ),

                    const Icon(
                      Icons
                          .arrow_forward_ios_rounded,

                      color:
                          Colors.white30,

                      size:
                          14,
                    ),
                  ],
                ),

                onTap:
                    () {
                  Navigator.pop(
                    sheetContext,
                  );

                  _openNotifications();
                },
              ),

              if (_teacherAccess)
                ListTile(
                  leading:
                      const Icon(
                    Icons
                        .cast_for_education_outlined,

                    color:
                        AppColors
                            .teacherIndigo,
                  ),

                  title:
                      const Text(
                    'Area Docenti',

                    style:
                        TextStyle(
                      color:
                          AppColors.pureWhite,

                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  subtitle:
                      Text(
                    'Materiali e strumenti docente',

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

                    _openTeacherArea();
                  },
                ),

              if (_adminAccess)
                ListTile(
                  leading:
                      const Icon(
                    Icons
                        .admin_panel_settings_outlined,

                    color:
                        Colors.greenAccent,
                  ),

                  title:
                      const Text(
                    'Admin Panel',

                    style:
                        TextStyle(
                      color:
                          AppColors.pureWhite,

                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  subtitle:
                      Text(
                    'Moderazione e gestione StudentLab',

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

                    _openAdminPanel();
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


  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

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