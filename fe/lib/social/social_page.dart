import 'package:flutter/material.dart';

import '../theme/nightTheme.dart';

import '../services/api_service.dart';
import '../services/auth_session.dart';

import 'social_models.dart';

import 'auth/login_page.dart';

import 'message/message_page.dart';

import 'groups/models/study_group.dart';
import 'groups/study_group_detail_page.dart';
import 'groups/create_group_page.dart';
import 'groups/public_groups_page.dart';

import 'widgets/social_intro.dart';
import 'widgets/student_help_card.dart';
import 'widgets/teacher_help_card.dart';

// Questi due file li costruiremo dopo.
import 'widgets/social_user_profile_page.dart';
import 'widgets/edit_social_profile_page.dart';


// =============================================================================
// SOCIAL PAGE
// =============================================================================

class SocialPage extends StatefulWidget {
  const SocialPage({
    super.key,
  });


  @override
  State<SocialPage> createState() =>
      _SocialPageState();
}


// =============================================================================
// SOCIAL PAGE STATE
// =============================================================================

class _SocialPageState
    extends State<SocialPage> {

  final AuthSession _session =
      AuthSession.instance;


  int _currentIndex =
      0;


  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    _session.addListener(
      _onSessionChanged,
    );
  }


  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    _session.removeListener(
      _onSessionChanged,
    );

    super.dispose();
  }


  // ===========================================================================
  // SESSION CHANGED
  // ===========================================================================

  void _onSessionChanged() {
    if (!mounted) {
      return;
    }


    setState(() {
      if (!_session.isAuthenticated) {
        _currentIndex =
            0;
      }
    });
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


    setState(() {
      _currentIndex =
          0;
    });
  }


  // ===========================================================================
  // PROFILE CREATED
  // ===========================================================================

  void _onProfileCreated(
    SocialUser user,
  ) {
    // AuthService.register() ha già aggiornato AuthSession.

    if (!mounted) {
      return;
    }


    setState(() {
      _currentIndex =
          0;
    });
  }


  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    // =========================================================================
    // GUEST
    // =========================================================================

    if (_session.isGuest) {
      return _GuestSocialPage(
        onLogin:
            _openLogin,

        onProfileCreated:
            _onProfileCreated,
      );
    }


    // =========================================================================
    // AUTHENTICATED
    // =========================================================================

    return Scaffold(
      backgroundColor:
          AppColors.darkElegance,

      body:
          SafeArea(
        child:
            Column(
          children: [
            Expanded(
              child:
                  IndexedStack(
                index:
                    _currentIndex,

                children: const [
                  _SocialProfilePage(),

                  _SocialUsersPage(),

                  _SocialGroupsPage(),
                ],
              ),
            ),

            _buildSocialSections(),
          ],
        ),
      ),
    );
  }


  // ===========================================================================
  // SOCIAL NAVIGATION
  // ===========================================================================

  Widget _buildSocialSections() {
    const sections = [
      (
        icon:
            Icons.person_outline_rounded,

        selectedIcon:
            Icons.person_rounded,

        label:
            'Profilo',
      ),

      (
        icon:
            Icons.people_outline_rounded,

        selectedIcon:
            Icons.people_rounded,

        label:
            'Utenti',
      ),

      (
        icon:
            Icons.groups_outlined,

        selectedIcon:
            Icons.groups_rounded,

        label:
            'Gruppi',
      ),
    ];


    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        12,
      ),

      height:
          52,

      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          16,
        ),

        border:
            Border.all(
          color:
              AppColors.skyBlue
                  .withOpacity(
            0.12,
          ),
        ),
      ),

      child:
          Row(
        children:
            List.generate(
          sections.length,
          (
            index,
          ) {
            final bool selected =
                _currentIndex ==
                    index;


            final section =
                sections[index];


            return Expanded(
              child:
                  GestureDetector(
                behavior:
                    HitTestBehavior.opaque,

                onTap:
                    () {
                  setState(() {
                    _currentIndex =
                        index;
                  });
                },

                child:
                    AnimatedContainer(
                  duration:
                      const Duration(
                    milliseconds:
                        180,
                  ),

                  margin:
                      const EdgeInsets.all(
                    4,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        selected
                            ? AppColors.skyBlue
                                .withOpacity(
                                0.16,
                              )
                            : Colors.transparent,

                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),

                  child:
                      Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,

                    children: [
                      Icon(
                        selected
                            ? section.selectedIcon
                            : section.icon,

                        size:
                            19,

                        color:
                            selected
                                ? AppColors.materialSky
                                : AppColors.pureWhite
                                    .withOpacity(
                                    0.45,
                                  ),
                      ),

                      const SizedBox(
                        width:
                            7,
                      ),

                      Text(
                        section.label,

                        style:
                            TextStyle(
                          color:
                              selected
                                  ? AppColors.pureWhite
                                  : AppColors.pureWhite
                                      .withOpacity(
                                      0.45,
                                    ),

                          fontSize:
                              11,

                          fontWeight:
                              selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


// =============================================================================
// GUEST SOCIAL PAGE
// =============================================================================

class _GuestSocialPage
    extends StatefulWidget {

  final Future<void> Function()
      onLogin;

  final ValueChanged<SocialUser>
      onProfileCreated;


  const _GuestSocialPage({
    required this.onLogin,
    required this.onProfileCreated,
  });


  @override
  State<_GuestSocialPage>
      createState() =>
          _GuestSocialPageState();
}


// =============================================================================
// GUEST STATE
// =============================================================================

class _GuestSocialPageState
    extends State<_GuestSocialPage> {

  final ApiService _apiService =
      ApiService();


  SocialUserType _selectedType =
      SocialUserType.student;


  List<SocialUser> _users =
      [];


  bool _loading =
      true;


  String? _error;


  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    _loadUsers();
  }


  // ===========================================================================
  // LOAD USERS
  // ===========================================================================

  Future<void> _loadUsers() async {
    if (mounted) {
      setState(() {
        _loading =
            true;

        _error =
            null;
      });
    }


    try {
      final List<SocialUser> users =
          await _apiService
              .getSocialUsers();


      if (!mounted) {
        return;
      }


      setState(() {
        _users =
            users;

        _loading =
            false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }


      setState(() {
        _error =
            e.toString();

        _loading =
            false;
      });
    }
  }


  // ===========================================================================
  // OPEN GROUPS
  // ===========================================================================

  Future<void> _openGroups() async {
    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (_) =>
                const PublicGroupsPage(),
      ),
    );
  }


  // ===========================================================================
  // OPEN USER
  // ===========================================================================

  Future<void> _openUser(
    SocialUser user,
  ) async {
    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (_) =>
                SocialUserProfilePage(
          user:
              user,
        ),
      ),
    );
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

      appBar:
          AppBar(
        backgroundColor:
            AppColors.brandNightBlue,

        foregroundColor:
            AppColors.pureWhite,

        elevation:
            0,

        title:
            const Text(
          'StudentLab Social',

          style:
              TextStyle(
            fontSize:
                20,

            fontWeight:
                FontWeight.w500,
          ),
        ),

        actions: [
          IconButton(
            tooltip:
                'Accedi',

            icon:
                const Icon(
              Icons.login_rounded,
            ),

            onPressed:
                () {
              widget.onLogin();
            },
          ),
        ],
      ),

      body:
          SafeArea(
        child:
            Center(
          child:
              LayoutBuilder(
            builder:
                (
              context,
              constraints,
            ) {
              final double width =
                  constraints.maxWidth >
                          850
                      ? 850
                      : constraints
                          .maxWidth;


              return SizedBox(
                width:
                    width,

                child:
                    RefreshIndicator(
                  onRefresh:
                      _loadUsers,

                  child:
                      ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),

                    padding:
                        const EdgeInsets.all(
                      20,
                    ),

                    children: [
                      // =======================================================
                      // SIGN UP
                      // =======================================================

                      SocialIntro(
                        onProfileCreated:
                            (
                          SocialUser user,
                        ) {
                          widget.onProfileCreated(
                            user,
                          );
                        },
                      ),

                      const SizedBox(
                        height:
                            24,
                      ),


                      // =======================================================
                      // COMMUNITY INFO
                      // =======================================================

                      _buildGuestBanner(),

                      const SizedBox(
                        height:
                            16,
                      ),


                      // =======================================================
                      // GROUPS
                      // =======================================================

                      _buildGroupsCard(),

                      const SizedBox(
                        height:
                            28,
                      ),


                      // =======================================================
                      // PEOPLE
                      // =======================================================

                      Row(
                        children: [
                          const Icon(
                            Icons.people_outline_rounded,

                            color:
                                AppColors.skyBlue,

                            size:
                                20,
                          ),

                          const SizedBox(
                            width:
                                8,
                          ),

                          const Text(
                            'Persone',

                            style:
                                TextStyle(
                              color:
                                  AppColors.pureWhite,

                              fontSize:
                                  18,

                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height:
                            6,
                      ),

                      Text(
                        'Scopri studenti e insegnanti della community.',

                        style:
                            TextStyle(
                          color:
                              AppColors.pureWhite
                                  .withOpacity(
                            0.48,
                          ),

                          fontSize:
                              11,
                        ),
                      ),

                      const SizedBox(
                        height:
                            16,
                      ),

                      _buildSelector(),

                      const SizedBox(
                        height:
                            22,
                      ),

                      _buildUsers(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }


  // ===========================================================================
  // GUEST BANNER
  // ===========================================================================

  Widget _buildGuestBanner() {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        16,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.eleganceMidnight,

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        border:
            Border.all(
          color:
              AppColors.skyBlue
                  .withOpacity(
            0.12,
          ),
        ),
      ),

      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Container(
            width:
                46,

            height:
                46,

            decoration:
                BoxDecoration(
              color:
                  AppColors.brandNightBlue,

              borderRadius:
                  BorderRadius.circular(
                13,
              ),
            ),

            child:
                const Icon(
              Icons.explore_outlined,

              color:
                  AppColors.skyBlue,

              size:
                  24,
            ),
          ),

          const SizedBox(
            width:
                13,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                const Text(
                  'Esplora la community',

                  style:
                      TextStyle(
                    color:
                        AppColors.pureWhite,

                    fontSize:
                        14,

                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height:
                      5,
                ),

                Text(
                  'Puoi conoscere studenti e insegnanti, '
                  'esplorare i gruppi e scoprire materiale '
                  'condiviso dalla community. Registrandoti '
                  'potrai partecipare direttamente alle attività Social.',

                  style:
                      TextStyle(
                    color:
                        AppColors.pureWhite
                            .withOpacity(
                      0.50,
                    ),

                    fontSize:
                        11,

                    height:
                        1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // ===========================================================================
  // GROUPS CARD
  // ===========================================================================

  Widget _buildGroupsCard() {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        17,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.eleganceMidnight,

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        border:
            Border.all(
          color:
              AppColors.skyBlue
                  .withOpacity(
            0.12,
          ),
        ),
      ),

      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Container(
                width:
                    46,

                height:
                    46,

                decoration:
                    BoxDecoration(
                  color:
                      AppColors.brandNightBlue,

                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),

                child:
                    const Icon(
                  Icons.groups_2_outlined,

                  color:
                      AppColors.skyBlue,

                  size:
                      25,
                ),
              ),

              const SizedBox(
                width:
                    13,
              ),

              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    const Text(
                      'Gruppi',

                      style:
                          TextStyle(
                        color:
                            AppColors.pureWhite,

                        fontSize:
                            15,

                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(
                      height:
                          6,
                    ),

                    Text(
                      'Nei gruppi puoi trovare studenti che seguono '
                      'le tue stesse materie, condividere appunti, '
                      'dispense, PDF, slide e materiale delle lezioni '
                      'e organizzarti con la community per studiare.',

                      style:
                          TextStyle(
                        color:
                            AppColors.pureWhite
                                .withOpacity(
                          0.52,
                        ),

                        fontSize:
                            11,

                        height:
                            1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height:
                15,
          ),

          const Wrap(
            spacing:
                8,

            runSpacing:
                8,

            children: [
              _GuestGroupFeatureChip(
                icon:
                    Icons.folder_copy_outlined,

                label:
                    'Materiale',
              ),

              _GuestGroupFeatureChip(
                icon:
                    Icons.menu_book_outlined,

                label:
                    'Materie',
              ),

              _GuestGroupFeatureChip(
                icon:
                    Icons.school_outlined,

                label:
                    'Lezioni',
              ),

              _GuestGroupFeatureChip(
                icon:
                    Icons.people_outline_rounded,

                label:
                    'Community',
              ),
            ],
          ),

          const SizedBox(
            height:
                16,
          ),

          SizedBox(
            width:
                double.infinity,

            child:
                ElevatedButton.icon(
              onPressed:
                  _openGroups,

              icon:
                  const Icon(
                Icons.search_rounded,
              ),

              label:
                  const Text(
                'Esplora i gruppi',
              ),

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.socialBlue,

                foregroundColor:
                    AppColors.pureWhite,

                padding:
                    const EdgeInsets.symmetric(
                  vertical:
                      13,
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ===========================================================================
  // SELECTOR
  // ===========================================================================

  Widget _buildSelector() {
    return Row(
      children: [
        Expanded(
          child:
              _selectorButton(
            title:
                'Studenti',

            icon:
                Icons.school_outlined,

            type:
                SocialUserType.student,
          ),
        ),

        const SizedBox(
          width:
              10,
        ),

        Expanded(
          child:
              _selectorButton(
            title:
                'Insegnanti',

            icon:
                Icons.person_outline_rounded,

            type:
                SocialUserType.teacher,
          ),
        ),
      ],
    );
  }


  Widget _selectorButton({
    required String title,
    required IconData icon,
    required SocialUserType type,
  }) {
    final bool selected =
        _selectedType ==
            type;


    return GestureDetector(
      onTap:
          () {
        setState(() {
          _selectedType =
              type;
        });
      },

      child:
          AnimatedContainer(
        duration:
            const Duration(
          milliseconds:
              180,
        ),

        padding:
            const EdgeInsets.symmetric(
          vertical:
              14,
        ),

        decoration:
            BoxDecoration(
          color:
              selected
                  ? AppColors.skyBlue
                      .withOpacity(
                      0.16,
                    )
                  : AppColors.eleganceMidnight,

          borderRadius:
              BorderRadius.circular(
            14,
          ),

          border:
              Border.all(
            color:
                selected
                    ? AppColors.skyBlue
                        .withOpacity(
                        0.35,
                      )
                    : AppColors.skyBlue
                        .withOpacity(
                        0.10,
                      ),
          ),
        ),

        child:
            Row(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Icon(
              icon,

              color:
                  selected
                      ? AppColors.materialSky
                      : AppColors.pureWhite
                          .withOpacity(
                          0.50,
                        ),

              size:
                  19,
            ),

            const SizedBox(
              width:
                  7,
            ),

            Text(
              title,

              style:
                  TextStyle(
                color:
                    selected
                        ? AppColors.pureWhite
                        : AppColors.pureWhite
                            .withOpacity(
                            0.55,
                          ),

                fontSize:
                    12,

                fontWeight:
                    selected
                        ? FontWeight.w600
                        : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ===========================================================================
  // USERS
  // ===========================================================================

  Widget _buildUsers() {
    if (_loading) {
      return const Padding(
        padding:
            EdgeInsets.symmetric(
          vertical:
              40,
        ),

        child:
            Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }


    if (_error !=
        null) {
      return _ErrorCard(
        message:
            _error!,

        onRetry:
            _loadUsers,
      );
    }


    final List<SocialUser> users =
        _users
            .where(
              (
                user,
              ) =>
                  user.type ==
                  _selectedType,
            )
            .toList();


    if (users.isEmpty) {
      return const _EmptyCard(
        icon:
            Icons.people_outline_rounded,

        title:
            'Nessun utente',

        message:
            'Non sono ancora presenti utenti di questo tipo.',
      );
    }


    return Column(
      children:
          users.map(
        (
          SocialUser user,
        ) {
          return Padding(
            padding:
                const EdgeInsets.only(
              bottom:
                  14,
            ),

            child:
                InkWell(
              onTap:
                  () {
                _openUser(
                  user,
                );
              },

              borderRadius:
                  BorderRadius.circular(
                18,
              ),

              child:
                  user.type ==
                          SocialUserType.student
                      ? StudentHelpCard(
                          student:
                              user,
                        )
                      : TeacherHelpCard(
                          teacher:
                              user,
                        ),
            ),
          );
        },
      ).toList(),
    );
  }
}


// =============================================================================
// PROFILE PAGE
// =============================================================================

class _SocialProfilePage
    extends StatefulWidget {

  const _SocialProfilePage();


  @override
  State<_SocialProfilePage>
      createState() =>
          _SocialProfilePageState();
}


// =============================================================================
// PROFILE STATE
// =============================================================================

class _SocialProfilePageState
    extends State<_SocialProfilePage> {

  final ApiService _apiService =
      ApiService();


  final AuthSession _session =
      AuthSession.instance;


  SocialUser? _user;


  List<StudyGroup> _groups =
      [];


  bool _loading =
      true;


  String? _error;


  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    _loadProfile();
  }


  // ===========================================================================
  // LOAD PROFILE
  // ===========================================================================

  Future<void> _loadProfile() async {
    final int? currentUserId =
        _session.currentUserId;


    if (currentUserId ==
        null) {
      setState(() {
        _error =
            'Utente non autenticato.';

        _loading =
            false;
      });

      return;
    }


    setState(() {
      _loading =
          true;

      _error =
          null;
    });


    try {
      final SocialUser user =
          await _apiService
              .getCurrentUser();


      final List<StudyGroup> groups =
          await _loadGroupsFromBackend(
        apiService:
            _apiService,

        currentUserId:
            currentUserId,

        onlyUserGroups:
            true,
      );


      if (!mounted) {
        return;
      }


      _session.updateUser(
        user,
      );


      setState(() {
        _user =
            user;

        _groups =
            groups;

        _loading =
            false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }


      setState(() {
        _error =
            e.toString();

        _loading =
            false;
      });
    }
  }


  // ===========================================================================
  // MESSAGES
  // ===========================================================================

  void _openMessages() {
    Navigator.of(
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
  // EDIT PROFILE
  // ===========================================================================

  Future<void> _editProfile() async {
    final SocialUser? user =
        _user;


    if (user ==
        null) {
      return;
    }


    final SocialUser? updatedUser =
        await Navigator.of(
      context,
    ).push<SocialUser>(
      MaterialPageRoute(
        builder:
            (_) =>
                EditSocialProfilePage(
          user:
              user,
        ),
      ),
    );


    if (!mounted ||
        updatedUser ==
            null) {
      return;
    }


    _session.updateUser(
      updatedUser,
    );


    setState(() {
      _user =
          updatedUser;
    });
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

      appBar:
          AppBar(
        backgroundColor:
            AppColors.brandNightBlue,

        foregroundColor:
            AppColors.pureWhite,

        elevation:
            0,

        title:
            const Text(
          'Profilo',
        ),

        actions: [
          IconButton(
            tooltip:
                'Messaggi',

            icon:
                const Icon(
              Icons.chat_bubble_outline_rounded,
            ),

            onPressed:
                _openMessages,
          ),
        ],
      ),

      body:
          SafeArea(
        child:
            Center(
          child:
              ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth:
                  850,
            ),

            child:
                _buildBody(),
          ),
        ),
      ),
    );
  }


  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }


    if (_error !=
        null) {
      return ListView(
        padding:
            const EdgeInsets.all(
          20,
        ),

        children: [
          _ErrorCard(
            message:
                _error!,

            onRetry:
                _loadProfile,
          ),
        ],
      );
    }


    final SocialUser user =
        _user!;


    return RefreshIndicator(
      onRefresh:
          _loadProfile,

      child:
          ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        padding:
            const EdgeInsets.all(
          20,
        ),

        children: [
          _buildProfileCard(
            user,
          ),

          const SizedBox(
            height:
                18,
          ),

          _buildStatistics(),

          const SizedBox(
            height:
                28,
          ),

          _buildMyGroups(
            user,
          ),

          const SizedBox(
            height:
                20,
          ),
        ],
      ),
    );
  }


  // ===========================================================================
  // PROFILE CARD
  // ===========================================================================

  Widget _buildProfileCard(
    SocialUser user,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(
        20,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.eleganceMidnight,

        borderRadius:
            BorderRadius.circular(
          22,
        ),

        border:
            Border.all(
          color:
              AppColors.skyBlue
                  .withOpacity(
            0.16,
          ),
        ),
      ),

      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Container(
                width:
                    70,

                height:
                    70,

                decoration:
                    BoxDecoration(
                  color:
                      AppColors.brandNightBlue,

                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),

                child:
                    const Icon(
                  Icons.person_rounded,

                  color:
                      AppColors.skyBlue,

                  size:
                      38,
                ),
              ),

              const SizedBox(
                width:
                    15,
              ),

              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      user.name,

                      style:
                          const TextStyle(
                        color:
                            AppColors.pureWhite,

                        fontSize:
                            21,

                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height:
                          5,
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
                            13,

                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(
                      height:
                          5,
                    ),

                    Text(
                      user.email,

                      style:
                          const TextStyle(
                        color:
                            Colors.white70,

                        fontSize:
                            11,
                      ),
                    ),
                  ],
                ),
              ),

              _AvailabilityBadge(
                available:
                    user.available,
              ),
            ],
          ),

          const SizedBox(
            height:
                22,
          ),

          _ProfileInfoRow(
            icon:
                Icons.school_outlined,

            title:
                'Corso',

            value:
                user.course,
          ),

          const SizedBox(
            height:
                12,
          ),

          _ProfileInfoRow(
            icon:
                Icons.account_balance_outlined,

            title:
                'Dipartimento',

            value:
                user.department,
          ),

          const SizedBox(
            height:
                20,
          ),

          const Text(
            'Materie',

            style:
                TextStyle(
              color:
                  AppColors.pureWhite,

              fontSize:
                  15,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height:
                10,
          ),

          if (user.subjects.isEmpty)
            Text(
              'Nessuna materia associata.',

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
            )
          else
            Wrap(
              spacing:
                  8,

              runSpacing:
                  8,

              children:
                  user.subjects
                      .map(
                        (
                          subject,
                        ) =>
                            _SubjectChip(
                          label:
                              subject.name,
                        ),
                      )
                      .toList(),
            ),

          const SizedBox(
            height:
                20,
          ),

          const Text(
            'Descrizione',

            style:
                TextStyle(
              color:
                  AppColors.pureWhite,

              fontSize:
                  15,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height:
                8,
          ),

          Text(
            user.description.isEmpty
                ? 'Nessuna descrizione.'
                : user.description,

            style:
                TextStyle(
              color:
                  AppColors.pureWhite
                      .withOpacity(
                0.58,
              ),

              fontSize:
                  12,

              height:
                  1.45,
            ),
          ),

          if (user.willingToTeach) ...[
            const SizedBox(
              height:
                  16,
            ),

            const _ProfileCapability(
              icon:
                  Icons.volunteer_activism_outlined,

              label:
                  'Disponibile ad aiutare',
            ),
          ],

          const SizedBox(
            height:
                20,
          ),

          SizedBox(
            width:
                double.infinity,

            child:
                OutlinedButton.icon(
              onPressed:
                  _editProfile,

              icon:
                  const Icon(
                Icons.edit_outlined,
              ),

              label:
                  const Text(
                'Modifica profilo',
              ),

              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    AppColors.materialSky,

                side:
                    BorderSide(
                  color:
                      AppColors.skyBlue
                          .withOpacity(
                    0.25,
                  ),
                ),

                padding:
                    const EdgeInsets.symmetric(
                  vertical:
                      13,
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ===========================================================================
  // STATISTICS
  // ===========================================================================

  Widget _buildStatistics() {
    final int materialCount =
        _groups.fold<int>(
      0,
      (
        total,
        group,
      ) =>
          total +
          group.materialCount,
    );


    return Row(
      children: [
        Expanded(
          child:
              _StatisticCard(
            icon:
                Icons.groups_rounded,

            value:
                '${_groups.length}',

            label:
                'Gruppi',
          ),
        ),

        const SizedBox(
          width:
              10,
        ),

        Expanded(
          child:
              _StatisticCard(
            icon:
                Icons.folder_rounded,

            value:
                '$materialCount',

            label:
                'Materiali',
          ),
        ),

        const SizedBox(
          width:
              10,
        ),

        const Expanded(
          child:
              _StatisticCard(
            icon:
                Icons.people_alt_rounded,

            value:
                '—',

            label:
                'Connessioni',
          ),
        ),
      ],
    );
  }


  // ===========================================================================
  // MY GROUPS
  // ===========================================================================

  Widget _buildMyGroups(
    SocialUser currentUser,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        const Text(
          'I miei gruppi',

          style:
              TextStyle(
            color:
                AppColors.pureWhite,

            fontSize:
                20,

            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(
          height:
              5,
        ),

        Text(
          'Una panoramica dei gruppi a cui partecipi.',

          style:
              TextStyle(
            color:
                AppColors.pureWhite
                    .withOpacity(
              0.50,
            ),

            fontSize:
                12,
          ),
        ),

        const SizedBox(
          height:
              14,
        ),

        if (_groups.isEmpty)
          const _EmptyCard(
            icon:
                Icons.groups_outlined,

            title:
                'Nessun gruppo',

            message:
                'Non partecipi ancora a nessun gruppo.',
          )
        else
          LayoutBuilder(
            builder:
                (
              context,
              constraints,
            ) {
              int columns =
                  2;


              if (constraints.maxWidth <
                  420) {
                columns =
                    1;
              } else if (constraints.maxWidth >=
                  700) {
                columns =
                    3;
              }


              return GridView.builder(
                shrinkWrap:
                    true,

                physics:
                    const NeverScrollableScrollPhysics(),

                itemCount:
                    _groups.length,

                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      columns,

                  crossAxisSpacing:
                      12,

                  mainAxisSpacing:
                      12,

                  mainAxisExtent:
                      175,
                ),

                itemBuilder:
                    (
                  context,
                  index,
                ) {
                  final StudyGroup group =
                      _groups[index];


                  return _MiniGroupCard(
                    group:
                        group,

                    onTap:
                        () {
                      Navigator.of(
                        context,
                      ).push(
                        MaterialPageRoute(
                          builder:
                              (_) =>
                                  StudyGroupDetailPage(
                            group:
                                group,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
      ],
    );
  }
}


// =============================================================================
// USERS PAGE
// =============================================================================

class _SocialUsersPage
    extends StatefulWidget {

  const _SocialUsersPage();


  @override
  State<_SocialUsersPage>
      createState() =>
          _SocialUsersPageState();
}


// =============================================================================
// USERS STATE
// =============================================================================

class _SocialUsersPageState
    extends State<_SocialUsersPage> {

  final ApiService _apiService =
      ApiService();


  final TextEditingController
      _searchController =
      TextEditingController();


  List<SocialUser> _users =
      [];


  int _selectedFilter =
      0;


  bool _loading =
      true;


  String? _error;


  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    _loadUsers();
  }


  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }


  // ===========================================================================
  // LOAD USERS
  // ===========================================================================

  Future<void> _loadUsers() async {
    setState(() {
      _loading =
          true;

      _error =
          null;
    });


    try {
      final List<SocialUser> users =
          await _apiService
              .getSocialUsers();


      if (!mounted) {
        return;
      }


      final int? currentUserId =
          AuthSession.instance
              .currentUserId;


      setState(() {
        _users =
            users
                .where(
                  (
                    user,
                  ) =>
                      user.id !=
                      currentUserId,
                )
                .toList();

        _loading =
            false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }


      setState(() {
        _error =
            e.toString();

        _loading =
            false;
      });
    }
  }


  // ===========================================================================
  // FILTERED USERS
  // ===========================================================================

  List<SocialUser> get _filteredUsers {
    final String query =
        _searchController.text
            .trim()
            .toLowerCase();


    return _users.where(
      (
        SocialUser user,
      ) {
        if (_selectedFilter ==
                1 &&
            user.type !=
                SocialUserType.student) {
          return false;
        }


        if (_selectedFilter ==
                2 &&
            user.type !=
                SocialUserType.teacher) {
          return false;
        }


        if (_selectedFilter ==
                3 &&
            !user.available) {
          return false;
        }


        if (query.isEmpty) {
          return true;
        }


        final String subjects =
            user.subjects
                .map(
                  (
                    subject,
                  ) =>
                      subject.name,
                )
                .join(
                  ' ',
                );


        final String searchable = [
          user.name,
          user.department,
          user.course,
          subjects,
          user.description,
        ].join(
          ' ',
        ).toLowerCase();


        return searchable.contains(
          query,
        );
      },
    ).toList();
  }


  // ===========================================================================
  // OPEN USER
  // ===========================================================================

  Future<void> _openUser(
    SocialUser user,
  ) async {
    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (_) =>
                SocialUserProfilePage(
          user:
              user,
        ),
      ),
    );
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

      appBar:
          AppBar(
        backgroundColor:
            AppColors.brandNightBlue,

        foregroundColor:
            AppColors.pureWhite,

        title:
            const Text(
          'Utenti',
        ),

        actions: [
          IconButton(
            tooltip:
                'Aggiorna',

            onPressed:
                _loadUsers,

            icon:
                const Icon(
              Icons.refresh_rounded,
            ),
          ),

          IconButton(
            tooltip:
                'Messaggi',

            onPressed:
                () {
              Navigator.of(
                context,
              ).push(
                MaterialPageRoute(
                  builder:
                      (_) =>
                          const MessagesPage(),
                ),
              );
            },

            icon:
                const Icon(
              Icons.chat_bubble_outline_rounded,
            ),
          ),
        ],
      ),

      body:
          SafeArea(
        child:
            Center(
          child:
              ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth:
                  850,
            ),

            child:
                RefreshIndicator(
              onRefresh:
                  _loadUsers,

              child:
                  ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),

                padding:
                    const EdgeInsets.all(
                  20,
                ),

                children: [
                  const Text(
                    'Community',

                    style:
                        TextStyle(
                      color:
                          AppColors.pureWhite,

                      fontSize:
                          25,

                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height:
                        5,
                  ),

                  Text(
                    'Trova studenti e insegnanti, scopri le loro '
                    'materie e apri il profilo per entrare in contatto.',

                    style:
                        TextStyle(
                      color:
                          AppColors.pureWhite
                              .withOpacity(
                        0.52,
                      ),

                      fontSize:
                          12,

                      height:
                          1.4,
                    ),
                  ),

                  const SizedBox(
                    height:
                        18,
                  ),

                  _buildSearch(),

                  const SizedBox(
                    height:
                        12,
                  ),

                  _buildFilters(),

                  const SizedBox(
                    height:
                        24,
                  ),

                  _buildUserList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  // ===========================================================================
  // SEARCH
  // ===========================================================================

  Widget _buildSearch() {
    return TextField(
      controller:
          _searchController,

      onChanged:
          (_) {
        setState(() {});
      },

      style:
          const TextStyle(
        color:
            AppColors.pureWhite,
      ),

      decoration:
          InputDecoration(
        hintText:
            'Cerca nome, corso, materia...',

        hintStyle:
            const TextStyle(
          color:
              Colors.white38,
        ),

        prefixIcon:
            const Icon(
          Icons.search_rounded,

          color:
              AppColors.skyBlue,
        ),

        filled:
            true,

        fillColor:
            AppColors.eleganceMidnight,

        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),

          borderSide:
              BorderSide.none,
        ),
      ),
    );
  }


  // ===========================================================================
  // FILTERS
  // ===========================================================================

  Widget _buildFilters() {
    const labels = [
      'Tutti',
      'Studenti',
      'Insegnanti',
      'Disponibili',
    ];


    return SingleChildScrollView(
      scrollDirection:
          Axis.horizontal,

      child:
          Row(
        children:
            List.generate(
          labels.length,
          (
            index,
          ) {
            return Padding(
              padding:
                  const EdgeInsets.only(
                right:
                    8,
              ),

              child:
                  ChoiceChip(
                selected:
                    _selectedFilter ==
                        index,

                label:
                    Text(
                  labels[index],
                ),

                onSelected:
                    (_) {
                  setState(() {
                    _selectedFilter =
                        index;
                  });
                },
              ),
            );
          },
        ),
      ),
    );
  }


  // ===========================================================================
  // USER LIST
  // ===========================================================================

  Widget _buildUserList() {
    if (_loading) {
      return const Padding(
        padding:
            EdgeInsets.symmetric(
          vertical:
              50,
        ),

        child:
            Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }


    if (_error !=
        null) {
      return _ErrorCard(
        message:
            _error!,

        onRetry:
            _loadUsers,
      );
    }


    final List<SocialUser> users =
        _filteredUsers;


    if (users.isEmpty) {
      return const _EmptyCard(
        icon:
            Icons.person_search_outlined,

        title:
            'Nessun utente',

        message:
            'Nessun profilo corrisponde alla ricerca.',
      );
    }


    return Column(
      children:
          users.map(
        (
          SocialUser user,
        ) {
          return Padding(
            padding:
                const EdgeInsets.only(
              bottom:
                  14,
            ),

            child:
                InkWell(
              onTap:
                  () {
                _openUser(
                  user,
                );
              },

              borderRadius:
                  BorderRadius.circular(
                18,
              ),

              child:
                  user.type ==
                          SocialUserType.student
                      ? StudentHelpCard(
                          student:
                              user,
                        )
                      : TeacherHelpCard(
                          teacher:
                              user,
                        ),
            ),
          );
        },
      ).toList(),
    );
  }
}


// =============================================================================
// GROUPS PAGE
// =============================================================================

class _SocialGroupsPage
    extends StatefulWidget {

  const _SocialGroupsPage();


  @override
  State<_SocialGroupsPage>
      createState() =>
          _SocialGroupsPageState();
}


// =============================================================================
// GROUPS STATE
// =============================================================================

class _SocialGroupsPageState
    extends State<_SocialGroupsPage> {

  final ApiService _apiService =
      ApiService();


  List<StudyGroup> _groups =
      [];


  bool _loading =
      true;


  String? _error;


  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    _loadGroups();
  }


  // ===========================================================================
  // LOAD
  // ===========================================================================

  Future<void> _loadGroups() async {
    final int? currentUserId =
        AuthSession.instance
            .currentUserId;


    if (currentUserId ==
        null) {
      return;
    }


    setState(() {
      _loading =
          true;

      _error =
          null;
    });


    try {
      final List<StudyGroup> groups =
          await _loadGroupsFromBackend(
        apiService:
            _apiService,

        currentUserId:
            currentUserId,

        onlyUserGroups:
            false,
      );


      if (!mounted) {
        return;
      }


      setState(() {
        _groups =
            groups;

        _loading =
            false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }


      setState(() {
        _error =
            e.toString();

        _loading =
            false;
      });
    }
  }


  // ===========================================================================
  // CREATE
  // ===========================================================================

  Future<void> _createGroup() async {
    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (_) =>
                const CreateGroupPage(),
      ),
    );


    if (mounted) {
      _loadGroups();
    }
  }


  // ===========================================================================
  // EXPLORE
  // ===========================================================================

  Future<void> _exploreGroups() async {
    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (_) =>
                const PublicGroupsPage(),
      ),
    );


    if (mounted) {
      _loadGroups();
    }
  }


  // ===========================================================================
  // OPEN GROUP
  // ===========================================================================

  Future<void> _openGroup(
    StudyGroup group,
  ) async {
    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (_) =>
                StudyGroupDetailPage(
          group:
              group,
        ),
      ),
    );


    if (mounted) {
      _loadGroups();
    }
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

      appBar:
          AppBar(
        backgroundColor:
            AppColors.brandNightBlue,

        foregroundColor:
            AppColors.pureWhite,

        title:
            const Text(
          'Gruppi',
        ),

        actions: [
          IconButton(
            tooltip:
                'Aggiorna',

            onPressed:
                _loadGroups,

            icon:
                const Icon(
              Icons.refresh_rounded,
            ),
          ),

          IconButton(
            tooltip:
                'Messaggi',

            onPressed:
                () {
              Navigator.of(
                context,
              ).push(
                MaterialPageRoute(
                  builder:
                      (_) =>
                          const MessagesPage(),
                ),
              );
            },

            icon:
                const Icon(
              Icons.chat_bubble_outline_rounded,
            ),
          ),
        ],
      ),

      body:
          SafeArea(
        child:
            Center(
          child:
              ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth:
                  1000,
            ),

            child:
                RefreshIndicator(
              onRefresh:
                  _loadGroups,

              child:
                  ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),

                padding:
                    const EdgeInsets.all(
                  20,
                ),

                children: [
                  const Text(
                    'Gruppi',

                    style:
                        TextStyle(
                      color:
                          AppColors.pureWhite,

                      fontSize:
                          25,

                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height:
                        5,
                  ),

                  Text(
                    'Accedi ai gruppi, scopri nuove community '
                    'e condividi materiale con altri studenti.',

                    style:
                        TextStyle(
                      color:
                          AppColors.pureWhite
                              .withOpacity(
                        0.52,
                      ),

                      fontSize:
                          12,

                      height:
                          1.4,
                    ),
                  ),

                  const SizedBox(
                    height:
                        22,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child:
                            OutlinedButton.icon(
                          onPressed:
                              _createGroup,

                          icon:
                              const Icon(
                            Icons.add_circle_outline_rounded,
                          ),

                          label:
                              const Text(
                            'Crea gruppo',
                          ),
                        ),
                      ),

                      const SizedBox(
                        width:
                            10,
                      ),

                      Expanded(
                        child:
                            ElevatedButton.icon(
                          onPressed:
                              _exploreGroups,

                          icon:
                              const Icon(
                            Icons.search_rounded,
                          ),

                          label:
                              const Text(
                            'Esplora gruppi',
                          ),

                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                AppColors.socialBlue,

                            foregroundColor:
                                AppColors.pureWhite,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height:
                        26,
                  ),

                  _buildGroups(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  // ===========================================================================
  // GROUP GRID
  // ===========================================================================

  Widget _buildGroups() {
    if (_loading) {
      return const Padding(
        padding:
            EdgeInsets.symmetric(
          vertical:
              50,
        ),

        child:
            Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }


    if (_error !=
        null) {
      return _ErrorCard(
        message:
            _error!,

        onRetry:
            _loadGroups,
      );
    }


    if (_groups.isEmpty) {
      return const _EmptyCard(
        icon:
            Icons.groups_outlined,

        title:
            'Nessun gruppo',

        message:
            'Non sono ancora presenti gruppi.',
      );
    }


    return LayoutBuilder(
      builder:
          (
        context,
        constraints,
      ) {
        int columns =
            2;


        if (constraints.maxWidth <
            450) {
          columns =
              1;
        } else if (constraints.maxWidth >=
            750) {
          columns =
              3;
        }


        return GridView.builder(
          shrinkWrap:
              true,

          physics:
              const NeverScrollableScrollPhysics(),

          itemCount:
              _groups.length,

          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:
                columns,

            crossAxisSpacing:
                12,

            mainAxisSpacing:
                12,

            mainAxisExtent:
                185,
          ),

          itemBuilder:
              (
            context,
            index,
          ) {
            final StudyGroup group =
                _groups[index];


            return _MiniGroupCard(
              group:
                  group,

              onTap:
                  () {
                _openGroup(
                  group,
                );
              },
            );
          },
        );
      },
    );
  }
}


// =============================================================================
// MINI GROUP CARD
// =============================================================================

class _MiniGroupCard
    extends StatelessWidget {

  final StudyGroup group;

  final VoidCallback onTap;


  const _MiniGroupCard({
    required this.group,
    required this.onTap,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color:
          Colors.transparent,

      child:
          InkWell(
        onTap:
            onTap,

        borderRadius:
            BorderRadius.circular(
          17,
        ),

        child:
            Container(
          padding:
              const EdgeInsets.all(
            14,
          ),

          decoration:
              BoxDecoration(
            color:
                AppColors.eleganceMidnight,

            borderRadius:
                BorderRadius.circular(
              17,
            ),

            border:
                Border.all(
              color:
                  AppColors.skyBlue
                      .withOpacity(
                0.12,
              ),
            ),
          ),

          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Row(
                children: [
                  Container(
                    width:
                        40,

                    height:
                        40,

                    decoration:
                        BoxDecoration(
                      color:
                          AppColors.brandNightBlue,

                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),

                    child:
                        const Icon(
                      Icons.groups_rounded,

                      color:
                          AppColors.skyBlue,

                      size:
                          21,
                    ),
                  ),

                  const Spacer(),

                  const Icon(
                    Icons.chevron_right_rounded,

                    color:
                        Colors.white38,
                  ),
                ],
              ),

              const SizedBox(
                height:
                    10,
              ),

              Text(
                group.name,

                maxLines:
                    2,

                overflow:
                    TextOverflow.ellipsis,

                style:
                    const TextStyle(
                  color:
                      AppColors.pureWhite,

                  fontSize:
                      13,

                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height:
                    5,
              ),

              Text(
                group.subject,

                maxLines:
                    1,

                overflow:
                    TextOverflow.ellipsis,

                style:
                    const TextStyle(
                  color:
                      AppColors.materialSky,

                  fontSize:
                      9,
                ),
              ),

              const Spacer(),

              _MiniGroupInfo(
                icon:
                    Icons.people_outline_rounded,

                text:
                    '${group.memberCount} partecipanti',
              ),

              const SizedBox(
                height:
                    5,
              ),

              _MiniGroupInfo(
                icon:
                    Icons.folder_outlined,

                text:
                    '${group.materialCount} materiali',
              ),

              if (group.isOwner) ...[
                const SizedBox(
                  height:
                      7,
                ),

                const Text(
                  'PROPRIETARIO',

                  style:
                      TextStyle(
                    color:
                        AppColors.materialSky,

                    fontSize:
                        8,

                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


// =============================================================================
// HELPERS
// =============================================================================

class _GuestGroupFeatureChip
    extends StatelessWidget {

  final IconData icon;

  final String label;


  const _GuestGroupFeatureChip({
    required this.icon,
    required this.label,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            9,

        vertical:
            6,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.brandNightBlue,

        borderRadius:
            BorderRadius.circular(
          9,
        ),

        border:
            Border.all(
          color:
              AppColors.skyBlue
                  .withOpacity(
            0.10,
          ),
        ),
      ),

      child:
          Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          Icon(
            icon,

            size:
                14,

            color:
                AppColors.materialSky,
          ),

          const SizedBox(
            width:
                5,
          ),

          Text(
            label,

            style:
                const TextStyle(
              color:
                  AppColors.materialSky,

              fontSize:
                  9,

              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}


class _ProfileInfoRow
    extends StatelessWidget {

  final IconData icon;

  final String title;

  final String value;


  const _ProfileInfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Icon(
          icon,

          color:
              AppColors.materialSky,

          size:
              20,
        ),

        const SizedBox(
          width:
              10,
        ),

        Expanded(
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                title,

                style:
                    const TextStyle(
                  color:
                      Colors.white38,

                  fontSize:
                      10,
                ),
              ),

              const SizedBox(
                height:
                    2,
              ),

              Text(
                value,

                style:
                    const TextStyle(
                  color:
                      Colors.white70,

                  fontSize:
                      12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


class _AvailabilityBadge
    extends StatelessWidget {

  final bool available;


  const _AvailabilityBadge({
    required this.available,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            8,

        vertical:
            6,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.brandNightBlue,

        borderRadius:
            BorderRadius.circular(
          9,
        ),
      ),

      child:
          Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          Icon(
            Icons.circle,

            size:
                7,

            color:
                available
                    ? Colors.greenAccent
                    : Colors.white30,
          ),

          const SizedBox(
            width:
                5,
          ),

          Text(
            available
                ? 'Disponibile'
                : 'Non disponibile',

            style:
                const TextStyle(
              color:
                  AppColors.pureWhite,

              fontSize:
                  9,
            ),
          ),
        ],
      ),
    );
  }
}


class _ProfileCapability
    extends StatelessWidget {

  final IconData icon;

  final String label;


  const _ProfileCapability({
    required this.icon,
    required this.label,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Icon(
          icon,

          color:
              AppColors.materialSky,

          size:
              18,
        ),

        const SizedBox(
          width:
              7,
        ),

        Text(
          label,

          style:
              const TextStyle(
            color:
                Colors.white70,

            fontSize:
                11,
          ),
        ),
      ],
    );
  }
}


class _SubjectChip
    extends StatelessWidget {

  final String label;


  const _SubjectChip({
    required this.label,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            11,

        vertical:
            7,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.brandNightBlue,

        borderRadius:
            BorderRadius.circular(
          10,
        ),
      ),

      child:
          Text(
        label,

        style:
            const TextStyle(
          color:
              Colors.white70,

          fontSize:
              11,
        ),
      ),
    );
  }
}


class _StatisticCard
    extends StatelessWidget {

  final IconData icon;

  final String value;

  final String label;


  const _StatisticCard({
    required this.icon,
    required this.value,
    required this.label,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical:
            14,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.eleganceMidnight,

        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),

      child:
          Column(
        children: [
          Icon(
            icon,

            color:
                AppColors.skyBlue,

            size:
                20,
          ),

          const SizedBox(
            height:
                6,
          ),

          Text(
            value,

            style:
                const TextStyle(
              color:
                  AppColors.pureWhite,

              fontSize:
                  17,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          Text(
            label,

            style:
                const TextStyle(
              color:
                  Colors.white38,

              fontSize:
                  9,
            ),
          ),
        ],
      ),
    );
  }
}


class _MiniGroupInfo
    extends StatelessWidget {

  final IconData icon;

  final String text;


  const _MiniGroupInfo({
    required this.icon,
    required this.text,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Icon(
          icon,

          color:
              Colors.white38,

          size:
              13,
        ),

        const SizedBox(
          width:
              4,
        ),

        Expanded(
          child:
              Text(
            text,

            maxLines:
                1,

            overflow:
                TextOverflow.ellipsis,

            style:
                const TextStyle(
              color:
                  Colors.white54,

              fontSize:
                  9,
            ),
          ),
        ),
      ],
    );
  }
}


// =============================================================================
// ERROR CARD
// =============================================================================

class _ErrorCard
    extends StatelessWidget {

  final String message;

  final Future<void> Function()
      onRetry;


  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(
        20,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.eleganceMidnight,

        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),

      child:
          Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,

            color:
                Colors.redAccent,

            size:
                35,
          ),

          const SizedBox(
            height:
                10,
          ),

          Text(
            message,

            textAlign:
                TextAlign.center,

            style:
                const TextStyle(
              color:
                  Colors.white60,

              fontSize:
                  11,
            ),
          ),

          const SizedBox(
            height:
                14,
          ),

          OutlinedButton.icon(
            onPressed:
                () {
              onRetry();
            },

            icon:
                const Icon(
              Icons.refresh_rounded,
            ),

            label:
                const Text(
              'Riprova',
            ),
          ),
        ],
      ),
    );
  }
}


// =============================================================================
// EMPTY CARD
// =============================================================================

class _EmptyCard
    extends StatelessWidget {

  final IconData icon;

  final String title;

  final String message;


  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.message,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        25,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.eleganceMidnight,

        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),

      child:
          Column(
        children: [
          Icon(
            icon,

            color:
                Colors.white30,

            size:
                40,
          ),

          const SizedBox(
            height:
                10,
          ),

          Text(
            title,

            style:
                const TextStyle(
              color:
                  AppColors.pureWhite,

              fontSize:
                  14,

              fontWeight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(
            height:
                5,
          ),

          Text(
            message,

            textAlign:
                TextAlign.center,

            style:
                const TextStyle(
              color:
                  Colors.white54,

              fontSize:
                  11,
            ),
          ),
        ],
      ),
    );
  }
}


// =============================================================================
// LOAD GROUPS FROM BACKEND
// =============================================================================

Future<List<StudyGroup>>
    _loadGroupsFromBackend({
  required ApiService apiService,
  required int currentUserId,
  required bool onlyUserGroups,
}) async {

  final List<Map<String, dynamic>>
      rawGroups =
      onlyUserGroups
          ? await apiService
              .getUserGroups(
              currentUserId,
            )
          : await apiService
              .getGroups();


  final List<StudyGroup> result =
      [];


  for (final Map<String, dynamic>
      rawGroup in rawGroups) {

    final Map<String, dynamic> merged =
        Map<String, dynamic>.from(
      rawGroup,
    );


    final dynamic rawId =
        rawGroup['id'];


    final int? groupId =
        rawId is int
            ? rawId
            : int.tryParse(
                rawId
                        ?.toString() ??
                    '',
              );


    if (groupId !=
        null) {
      try {
        final Map<String, dynamic>
            detail =
            await apiService.getGroup(
          groupId,
        );


        merged.addAll(
          detail,
        );
      } catch (_) {}


      try {
        final materials =
            await apiService
                .getGroupMaterials(
          groupId,
        );


        merged['material_count'] =
            materials.length;
      } catch (_) {}
    }


    result.add(
      StudyGroup.fromJson(
        merged,

        currentUserId:
            currentUserId,
      ),
    );
  }


  return result;
}