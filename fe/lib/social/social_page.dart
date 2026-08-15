import 'package:flutter/material.dart';

import '../theme/nightTheme.dart';

import '../services/api_service.dart';

import 'social_models.dart';

import 'message/message_page.dart';

import 'groups/models/study_group.dart';

import 'groups/study_group_detail_page.dart';

import 'widgets/social_intro.dart';

import 'widgets/student_help_card.dart';

import 'widgets/teacher_help_card.dart';

import 'groups/create_group_page.dart';


// =============================================================================
// CONFIGURAZIONE TEMPORANEA UTENTE
// =============================================================================
//
// Verrà sostituita da AuthService / sessione autenticata.
//

const int _currentUserId = 1;


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


class _SocialPageState
    extends State<SocialPage> {

  bool isRegistered = true;

  int _currentIndex = 0;


  @override
  Widget build(
    BuildContext context,
  ) {
    if (!isRegistered) {
      return _GuestSocialPage(
        onLogin: () {
          _showMessage(
            context,
            'Accesso / registrazione: da collegare.',
          );
        },
      );
    }


    return Scaffold(
      backgroundColor:
          AppColors.darkElegance,

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
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
  // NAVIGAZIONE SOCIAL
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
                    HitTestBehavior
                        .opaque,

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
                      const EdgeInsets
                          .all(
                    4,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        selected
                            ? AppColors
                                .skyBlue
                                .withOpacity(
                                0.16,
                              )
                            : Colors
                                .transparent,

                    borderRadius:
                        BorderRadius
                            .circular(
                      12,
                    ),
                  ),

                  child:
                      Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,

                    children: [
                      Icon(
                        selected
                            ? section
                                .selectedIcon
                            : section
                                .icon,

                        size:
                            19,

                        color:
                            selected
                                ? AppColors
                                    .materialSky
                                : AppColors
                                    .pureWhite
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
                                  ? AppColors
                                      .pureWhite
                                  : AppColors
                                      .pureWhite
                                      .withOpacity(
                                      0.45,
                                    ),

                          fontSize:
                              11,

                          fontWeight:
                              selected
                                  ? FontWeight
                                      .w600
                                  : FontWeight
                                      .normal,
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


  static void _showMessage(
    BuildContext context,
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
// SOCIAL GUEST
// =============================================================================

class _GuestSocialPage
    extends StatefulWidget {

  final VoidCallback onLogin;


  const _GuestSocialPage({
    required this.onLogin,
  });


  @override
  State<_GuestSocialPage>
      createState() =>
          _GuestSocialPageState();
}


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


  @override
  void initState() {
    super.initState();

    _loadUsers();
  }


  // ===========================================================================
  // BACKEND
  // ===========================================================================

  Future<void> _loadUsers() async {
    setState(() {
      _loading =
          true;

      _error =
          null;
    });


    try {
      final users =
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
                widget.onLogin,
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
                        const EdgeInsets
                            .all(
                      20,
                    ),

                    children: [
                      const SocialIntro(),

                      const SizedBox(
                        height:
                            24,
                      ),

                      _buildGuestBanner(),

                      const SizedBox(
                        height:
                            24,
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
  // BANNER GUEST
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
                  AppColors
                      .brandNightBlue,

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
                  'Puoi conoscere studenti e insegnanti di StudentLab. '
                  'Registrandoti potrai creare il tuo profilo, inviare messaggi '
                  'e utilizzare tutte le funzionalità Social.',

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
  // STUDENTI / INSEGNANTI
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
                  : AppColors
                      .eleganceMidnight,

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
                      ? AppColors
                          .materialSky
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
                        ? AppColors
                            .pureWhite
                        : AppColors
                            .pureWhite
                            .withOpacity(
                            0.55,
                          ),

                fontSize:
                    12,

                fontWeight:
                    selected
                        ? FontWeight.w600
                        : FontWeight
                            .normal,
              ),
            ),
          ],
        ),
      ),
    );
  }


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


    if (_error != null) {
      return _ErrorCard(
        message:
            _error!,

        onRetry:
            _loadUsers,
      );
    }


    final users =
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
          user,
        ) {
          return Padding(
            padding:
                const EdgeInsets.only(
              bottom:
                  14,
            ),

            child:
                user.type ==
                        SocialUserType
                            .student
                    ? StudentHelpCard(
                        student:
                            user,
                      )
                    : TeacherHelpCard(
                        teacher:
                            user,
                      ),
          );
        },
      ).toList(),
    );
  }
}


// =============================================================================
// PROFILO
// =============================================================================

class _SocialProfilePage
    extends StatefulWidget {

  const _SocialProfilePage();


  @override
  State<_SocialProfilePage>
      createState() =>
          _SocialProfilePageState();
}


class _SocialProfilePageState
    extends State<_SocialProfilePage> {

  final ApiService _apiService =
      ApiService();


  SocialUser? _user;


  List<StudyGroup> _groups =
      [];


  bool _loading =
      true;


  String? _error;


  @override
  void initState() {
    super.initState();

    _loadProfile();
  }


  // ===========================================================================
  // BACKEND PROFILO
  // ===========================================================================

  Future<void> _loadProfile() async {
    setState(() {
      _loading =
          true;

      _error =
          null;
    });


    try {
      final SocialUser user =
          await _apiService
              .getSocialUser(
        _currentUserId,
      );


      final List<StudyGroup> groups =
          await _loadGroupsFromBackend(
        apiService:
            _apiService,

        currentUserId:
            _currentUserId,

        onlyUserGroups:
            true,
      );


      if (!mounted) {
        return;
      }


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


  void _openMessages(
    BuildContext context,
  ) {
    Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (
          _,
        ) =>
                const MessagesPage(),
      ),
    );
  }


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
                'Messaggi',

            icon:
                const Icon(
              Icons
                  .chat_bubble_outline_rounded,
            ),

            onPressed:
                () {
              _openMessages(
                context,
              );
            },
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


    if (_error != null) {
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

          _buildMyGroups(),

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
      width:
          double.infinity,

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

        boxShadow: [
          BoxShadow(
            color:
                Colors.black
                    .withOpacity(
              0.15,
            ),

            blurRadius:
                10,

            offset:
                const Offset(
              0,
              5,
            ),
          ),
        ],
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
                      AppColors
                          .brandNightBlue,

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

                      maxLines:
                          2,

                      overflow:
                          TextOverflow
                              .ellipsis,

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
                              SocialUserType
                                  .teacher
                          ? 'Insegnante'
                          : 'Studente',

                      style:
                          const TextStyle(
                        color:
                            AppColors
                                .materialSky,

                        fontSize:
                            13,

                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(
                      height:
                          7,
                    ),

                    Text(
                      user.email,

                      maxLines:
                          1,

                      overflow:
                          TextOverflow
                              .ellipsis,

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

              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal:
                      9,

                  vertical:
                      6,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      AppColors
                          .brandNightBlue,

                  borderRadius:
                      BorderRadius.circular(
                    9,
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
                  mainAxisSize:
                      MainAxisSize.min,

                  children: [
                    Icon(
                      Icons.circle,

                      color:
                          user.available
                              ? Colors
                                  .greenAccent
                              : Colors
                                  .white30,

                      size:
                          8,
                    ),

                    const SizedBox(
                      width:
                          5,
                    ),

                    Text(
                      user.available
                          ? 'Disponibile'
                          : 'Non disponibile',

                      style:
                          const TextStyle(
                        color:
                            AppColors.pureWhite,

                        fontSize:
                            10,

                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ],
                ),
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
                Icons
                    .account_balance_outlined,

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
                  15,
            ),

            Row(
              children: [
                const Icon(
                  Icons
                      .volunteer_activism_outlined,

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
                  'Disponibile ad aiutare altri studenti',

                  style:
                      TextStyle(
                    color:
                        AppColors.pureWhite
                            .withOpacity(
                      0.65,
                    ),

                    fontSize:
                        11,
                  ),
                ),
              ],
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
                  () {
                _showMessage(
                  context,

                  'Modifica profilo: da collegare a updateSocialUser.',
                );
              },

              icon:
                  const Icon(
                Icons.edit_outlined,
              ),

              label:
                  const Text(
                'Modifica profilo',
              ),

              style:
                  OutlinedButton
                      .styleFrom(
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
                    const EdgeInsets
                        .symmetric(
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
  // STATISTICHE
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
  // I MIEI GRUPPI
  // ===========================================================================

  Widget _buildMyGroups() {
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
              final double width =
                  constraints.maxWidth;


              int columns =
                  2;


              if (width <
                  420) {
                columns =
                    1;
              } else if (width >=
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
                              (
                            _,
                          ) =>
                                  StudyGroupDetailPage(
                          group: group,
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


  static void _showMessage(
    BuildContext context,
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
// GRUPPI
// =============================================================================

class _SocialGroupsPage
    extends StatefulWidget {

  const _SocialGroupsPage();


  @override
  State<_SocialGroupsPage>
      createState() =>
          _SocialGroupsPageState();
}


class _SocialGroupsPageState
    extends State<_SocialGroupsPage> {

  final ApiService _apiService =
      ApiService();


  List<StudyGroup> _groups =
      [];


  bool _loading =
      true;


  String? _error;


  @override
  void initState() {
    super.initState();

    _loadGroups();
  }


  // ===========================================================================
  // BACKEND
  // ===========================================================================

  Future<void> _loadGroups() async {
    setState(() {
      _loading =
          true;

      _error =
          null;
    });


    try {
      final groups =
          await _loadGroupsFromBackend(
        apiService:
            _apiService,

        currentUserId:
            _currentUserId,

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


  void _openMessages(
    BuildContext context,
  ) {
    Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (
          _,
        ) =>
                const MessagesPage(),
      ),
    );
  }


  void _createGroup(
    BuildContext context,
  ) {
    Navigator.of(
      context,
    )
        .push(
      MaterialPageRoute(
        builder:
            (
          _,
        ) =>
                const CreateGroupPage(),
      ),
    )
        .then(
      (
        _,
      ) {
        _loadGroups();
      },
    );
  }


  void _joinGroup(
    BuildContext context,
  ) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(
        content:
            Text(
          'Seleziona un gruppo dalla lista per partecipare.',
        ),
      ),
    );
  }


  void _openGroup(
    BuildContext context,
    StudyGroup group,
  ) {
    Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (
          _,
        ) =>
            StudyGroupDetailPage(
              group: group,
            ),
      ),
    );
  }


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
          'Gruppi',

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
                'Aggiorna',

            icon:
                const Icon(
              Icons.refresh_rounded,
            ),

            onPressed:
                _loadGroups,
          ),

          IconButton(
            tooltip:
                'Messaggi',

            icon:
                const Icon(
              Icons
                  .chat_bubble_outline_rounded,
            ),

            onPressed:
                () {
              _openMessages(
                context,
              );
            },
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
                    const EdgeInsets
                        .all(
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
                    'Accedi ai gruppi di cui fai parte o scopri nuovi gruppi.',

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

                  _buildGroupActions(
                    context,
                  ),

                  const SizedBox(
                    height:
                        28,
                  ),

                  _buildGroupsGrid(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  // ===========================================================================
  // AZIONI
  // ===========================================================================

  Widget _buildGroupActions(
    BuildContext context,
  ) {
    return Column(
      children: [
        SizedBox(
          width:
              double.infinity,

          child:
              OutlinedButton.icon(
            onPressed:
                () {
              _createGroup(
                context,
              );
            },

            icon:
                const Icon(
              Icons
                  .add_circle_outline_rounded,
            ),

            label:
                const Text(
              'Crea gruppo',
            ),

            style:
                OutlinedButton
                    .styleFrom(
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

              backgroundColor:
                  AppColors
                      .eleganceMidnight,

              padding:
                  const EdgeInsets
                      .symmetric(
                vertical:
                    13,
              ),

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(
          height:
              12,
        ),

        SizedBox(
          width:
              double.infinity,

          child:
              OutlinedButton.icon(
            onPressed:
                () {
              _joinGroup(
                context,
              );
            },

            icon:
                const Icon(
              Icons.group_add_outlined,
            ),

            label:
                const Text(
              'Partecipa a un gruppo',
            ),

            style:
                OutlinedButton
                    .styleFrom(
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

              backgroundColor:
                  AppColors
                      .eleganceMidnight,

              padding:
                  const EdgeInsets
                      .symmetric(
                vertical:
                    13,
              ),

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }


  // ===========================================================================
  // GRIGLIA
  // ===========================================================================

  Widget _buildGroupsGrid() {
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


    if (_error != null) {
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
        final double width =
            constraints.maxWidth;


        int columns;


        if (width <
            360) {
          columns =
              1;
        } else if (width >=
            1000) {
          columns =
              4;
        } else if (width >=
            700) {
          columns =
              3;
        } else {
          columns =
              2;
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
                14,

            mainAxisSpacing:
                14,

            mainAxisExtent:
                columns ==
                        1
                    ? 180
                    : 200,
          ),

          itemBuilder:
              (
            context,
            index,
          ) {
            final StudyGroup group =
                _groups[index];


            return _GroupCard(
              group:
                  group,

              onTap:
                  () {
                _openGroup(
                  context,
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
// GROUP CARD
// =============================================================================

class _GroupCard
    extends StatelessWidget {

  final StudyGroup group;

  final VoidCallback onTap;


  const _GroupCard({
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
          20,
        ),

        child:
            Container(
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal:
                14,

            vertical:
                13,
          ),

          decoration:
              BoxDecoration(
            color:
                AppColors
                    .eleganceMidnight,

            borderRadius:
                BorderRadius.circular(
              20,
            ),

            border:
                Border.all(
              color:
                  AppColors.skyBlue
                      .withOpacity(
                0.13,
              ),
            ),

            boxShadow: [
              BoxShadow(
                color:
                    Colors.black
                        .withOpacity(
                  0.10,
                ),

                blurRadius:
                    8,

                offset:
                    const Offset(
                  0,
                  4,
                ),
              ),
            ],
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
                        42,

                    height:
                        42,

                    decoration:
                        BoxDecoration(
                      color:
                          AppColors
                              .brandNightBlue,

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
                          22,
                    ),
                  ),

                  const Spacer(),

                  if (group.isPrivate) ...[
                    const Icon(
                      Icons
                          .lock_outline_rounded,

                      color:
                          Colors.white38,

                      size:
                          15,
                    ),

                    const SizedBox(
                      width:
                          5,
                    ),
                  ],

                  const Icon(
                    Icons
                        .chevron_right_rounded,

                    color:
                        Colors.white38,

                    size:
                        20,
                  ),
                ],
              ),

              const SizedBox(
                height:
                    9,
              ),

              Text(
                group.name,

                maxLines:
                    2,

                overflow:
                    TextOverflow
                        .ellipsis,

                style:
                    const TextStyle(
                  color:
                      AppColors.pureWhite,

                  fontSize:
                      13,

                  fontWeight:
                      FontWeight.bold,

                  height:
                      1.15,
                ),
              ),

              const SizedBox(
                height:
                    3,
              ),

              Text(
                group.subject.isNotEmpty
                    ? group.subject
                    : group.subjectId !=
                            null
                        ? 'Materia #${group.subjectId}'
                        : 'Materia non specificata',

                maxLines:
                    1,

                overflow:
                    TextOverflow
                        .ellipsis,

                style:
                    TextStyle(
                  color:
                      AppColors.materialSky
                          .withOpacity(
                    0.85,
                  ),

                  fontSize:
                      9,
                ),
              ),

              const Spacer(),

              Row(
                children: [
                  const Icon(
                    Icons
                        .people_outline_rounded,

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
                      '${group.memberCount} partecipanti',

                      maxLines:
                          1,

                      overflow:
                          TextOverflow
                              .ellipsis,

                      style:
                          TextStyle(
                        color:
                            AppColors.pureWhite
                                .withOpacity(
                          0.48,
                        ),

                        fontSize:
                            9,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height:
                    5,
              ),

              Row(
                children: [
                  Icon(
                    Icons.folder_outlined,

                    color:
                        AppColors.materialSky
                            .withOpacity(
                      0.75,
                    ),

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
                      '${group.materialCount} materiali',

                      maxLines:
                          1,

                      overflow:
                          TextOverflow
                              .ellipsis,

                      style:
                          TextStyle(
                        color:
                            AppColors.pureWhite
                                .withOpacity(
                          0.48,
                        ),

                        fontSize:
                            9,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height:
                    6,
              ),

              Text(
                group.isOwner
                    ? 'PROPRIETARIO'
                    : 'PARTECIPANTE',

                maxLines:
                    1,

                overflow:
                    TextOverflow
                        .ellipsis,

                style:
                    TextStyle(
                  color:
                      AppColors.materialSky
                          .withOpacity(
                    0.80,
                  ),

                  fontSize:
                      8,

                  fontWeight:
                      FontWeight.w600,
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
    return LayoutBuilder(
      builder:
          (
        context,
        constraints,
      ) {
        final bool compact =
            constraints.maxWidth <
                150;


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
                  EdgeInsets.all(
                compact
                    ? 11
                    : 14,
              ),

              decoration:
                  BoxDecoration(
                color:
                    AppColors
                        .eleganceMidnight,

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
                            compact
                                ? 35
                                : 40,

                        height:
                            compact
                                ? 35
                                : 40,

                        decoration:
                            BoxDecoration(
                          color:
                              AppColors
                                  .brandNightBlue,

                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),

                        child:
                            Icon(
                          Icons.groups_rounded,

                          color:
                              AppColors.skyBlue,

                          size:
                              compact
                                  ? 18
                                  : 21,
                        ),
                      ),

                      const Spacer(),

                      if (group.isPrivate)
                        Icon(
                          Icons
                              .lock_outline_rounded,

                          color:
                              Colors.white38,

                          size:
                              compact
                                  ? 13
                                  : 15,
                        ),

                      const SizedBox(
                        width:
                            4,
                      ),

                      Icon(
                        Icons
                            .chevron_right_rounded,

                        color:
                            Colors.white38,

                        size:
                            compact
                                ? 18
                                : 20,
                      ),
                    ],
                  ),

                  const SizedBox(
                    height:
                        9,
                  ),

                  Text(
                    group.name,

                    maxLines:
                        2,

                    overflow:
                        TextOverflow
                            .ellipsis,

                    style:
                        TextStyle(
                      color:
                          AppColors.pureWhite,

                      fontSize:
                          compact
                              ? 10
                              : 12,

                      fontWeight:
                          FontWeight.bold,

                      height:
                          1.2,
                    ),
                  ),

                  const SizedBox(
                    height:
                        4,
                  ),

                  Text(
                    '${group.memberCount} partecipanti',

                    maxLines:
                        1,

                    overflow:
                        TextOverflow
                            .ellipsis,

                    style:
                        TextStyle(
                      color:
                          AppColors.pureWhite
                              .withOpacity(
                        0.48,
                      ),

                      fontSize:
                          compact
                              ? 8
                              : 9,
                    ),
                  ),

                  const Spacer(),

                  Text(
                    group.isOwner
                        ? 'PROPRIETARIO'
                        : 'PARTECIPANTE',

                    maxLines:
                        1,

                    overflow:
                        TextOverflow
                            .ellipsis,

                    style:
                        TextStyle(
                      color:
                          AppColors.materialSky
                              .withOpacity(
                        0.80,
                      ),

                      fontSize:
                          compact
                              ? 7
                              : 8,

                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


// =============================================================================
// UTENTI
// =============================================================================

class _SocialUsersPage
    extends StatefulWidget {

  const _SocialUsersPage();


  @override
  State<_SocialUsersPage>
      createState() =>
          _SocialUsersPageState();
}


class _SocialUsersPageState
    extends State<_SocialUsersPage> {

  final ApiService _apiService =
      ApiService();


  final TextEditingController
      _searchController =
      TextEditingController();


  List<SocialUser> _users =
      [];


  bool _loading =
      true;


  String? _error;


  int _selectedFilter =
      0;


  @override
  void initState() {
    super.initState();

    _loadUsers();
  }


  @override
  void dispose() {
    _searchController
        .dispose();

    super.dispose();
  }


  // ===========================================================================
  // BACKEND
  // ===========================================================================

  Future<void> _loadUsers() async {
    setState(() {
      _loading =
          true;

      _error =
          null;
    });


    try {
      final users =
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
  // FILTRI
  // ===========================================================================

  List<SocialUser>
      get _filteredUsers {

    final String query =
        _searchController.text
            .trim()
            .toLowerCase();


    return _users.where(
      (
        user,
      ) {
        bool matchesFilter =
            true;


        if (_selectedFilter ==
            1) {
          matchesFilter =
              user.type ==
              SocialUserType.student;
        }


        if (_selectedFilter ==
            2) {
          matchesFilter =
              user.type ==
              SocialUserType.teacher;
        }


        if (!matchesFilter) {
          return false;
        }


        if (query.isEmpty) {
          return true;
        }


        final String subjectText =
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


        final String searchable =
            [
          user.name,

          user.email,

          user.course,

          user.department,

          subjectText,
        ].join(
          ' ',
        ).toLowerCase();


        return searchable.contains(
          query,
        );
      },
    ).toList();
  }


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
          'Utenti',

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
                'Aggiorna',

            icon:
                const Icon(
              Icons.refresh_rounded,
            ),

            onPressed:
                _loadUsers,
          ),

          IconButton(
            tooltip:
                'Messaggi',

            icon:
                const Icon(
              Icons
                  .chat_bubble_outline_rounded,
            ),

            onPressed:
                () {
              Navigator.of(
                context,
              ).push(
                MaterialPageRoute(
                  builder:
                      (
                    _,
                  ) =>
                          const MessagesPage(),
                ),
              );
            },
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
                    const EdgeInsets
                        .all(
                  20,
                ),

                children: [
                  _buildHeader(),

                  const SizedBox(
                    height:
                        18,
                  ),

                  _buildSearchBar(),

                  const SizedBox(
                    height:
                        12,
                  ),

                  _buildFilters(),

                  const SizedBox(
                    height:
                        28,
                  ),

                  if (_loading)
                    const Padding(
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
                    )
                  else if (_error !=
                      null)
                    _ErrorCard(
                      message:
                          _error!,

                      onRetry:
                          _loadUsers,
                    )
                  else
                    _buildUserResults(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildHeader() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        const Text(
          'Connettiamoci',

          style:
              TextStyle(
            color:
                AppColors.pureWhite,

            fontSize:
                24,

            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(
          height:
              5,
        ),

        Text(
          'Trova studenti e insegnanti con cui studiare, collaborare e condividere conoscenze.',

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
      ],
    );
  }


  Widget _buildSearchBar() {
    return TextField(
      controller:
          _searchController,

      textInputAction:
          TextInputAction.search,

      style:
          const TextStyle(
        color:
            AppColors.pureWhite,
      ),

      decoration:
          InputDecoration(
        hintText:
            'Cerca studenti o insegnanti...',

        hintStyle:
            TextStyle(
          color:
              AppColors.pureWhite
                  .withOpacity(
            0.38,
          ),
        ),

        prefixIcon:
            const Icon(
          Icons.search_rounded,

          color:
              AppColors.materialSky,
        ),

        suffixIcon:
            _searchController.text
                    .isNotEmpty
                ? IconButton(
                    tooltip:
                        'Cancella ricerca',

                    icon:
                        const Icon(
                      Icons.clear_rounded,
                    ),

                    color:
                        Colors.white54,

                    onPressed:
                        () {
                      setState(() {
                        _searchController
                            .clear();
                      });
                    },
                  )
                : null,

        filled:
            true,

        fillColor:
            AppColors.eleganceMidnight,

        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            16,
          ),

          borderSide:
              BorderSide.none,
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            16,
          ),

          borderSide:
              BorderSide(
            color:
                AppColors.skyBlue
                    .withOpacity(
              0.10,
            ),
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            16,
          ),

          borderSide:
              BorderSide(
            color:
                AppColors.skyBlue
                    .withOpacity(
              0.30,
            ),
          ),
        ),
      ),

      onChanged:
          (
        _,
      ) {
        setState(() {});
      },
    );
  }


  Widget _buildFilters() {
    const filters = [
      'Tutti',
      'Studenti',
      'Insegnanti',
    ];


    return SizedBox(
      height:
          42,

      child:
          ListView.builder(
        scrollDirection:
            Axis.horizontal,

        itemCount:
            filters.length,

        itemBuilder:
            (
          context,
          index,
        ) {
          final bool selected =
              _selectedFilter ==
                  index;


          return GestureDetector(
            onTap:
                () {
              setState(() {
                _selectedFilter =
                    index;
              });
            },

            child:
                Container(
              margin:
                  const EdgeInsets.only(
                right:
                    8,
              ),

              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal:
                    15,
              ),

              alignment:
                  Alignment.center,

              decoration:
                  BoxDecoration(
                color:
                    selected
                        ? AppColors.skyBlue
                            .withOpacity(
                            0.15,
                          )
                        : AppColors
                            .eleganceMidnight,

                borderRadius:
                    BorderRadius.circular(
                  12,
                ),

                border:
                    Border.all(
                  color:
                      selected
                          ? AppColors.skyBlue
                              .withOpacity(
                              0.30,
                            )
                          : AppColors.skyBlue
                              .withOpacity(
                              0.10,
                            ),
                ),
              ),

              child:
                  Text(
                filters[index],

                style:
                    TextStyle(
                  color:
                      selected
                          ? AppColors
                              .materialSky
                          : AppColors
                              .pureWhite
                              .withOpacity(
                              0.55,
                            ),

                  fontSize:
                      11,

                  fontWeight:
                      selected
                          ? FontWeight.w600
                          : FontWeight
                              .normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildUserResults() {
    final users =
        _filteredUsers;


    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Text(
          _searchController.text
                  .trim()
                  .isEmpty
              ? 'Persone che potresti conoscere'
              : 'Risultati della ricerca',

          style:
              const TextStyle(
            color:
                AppColors.pureWhite,

            fontSize:
                19,

            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(
          height:
              5,
        ),

        Text(
          users.isEmpty
              ? 'Nessun utente corrisponde alla ricerca.'
              : '${users.length} utenti trovati.',

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
              15,
        ),

        if (users.isEmpty)
          _buildEmptySearch()
        else
          ...users.map(
            (
              user,
            ) {
              final String subjects =
                  user.subjects
                      .map(
                        (
                          subject,
                        ) =>
                            subject.name,
                      )
                      .join(
                        ' · ',
                      );


              return Padding(
                padding:
                    const EdgeInsets.only(
                  bottom:
                      12,
                ),

                child:
                    _UserCard(
                  name:
                      user.name,

                  role:
                      user.type ==
                              SocialUserType
                                  .teacher
                          ? 'Insegnante'
                          : 'Studente',

                  course:
                      user.course,

                  subjects:
                      subjects.isEmpty
                          ? 'Nessuna materia'
                          : subjects,

                  available:
                      user.available,

                  onTap:
                      () {
                    _openUser(
                      user,
                    );
                  },
                ),
              );
            },
          ),
      ],
    );
  }


  Widget _buildEmptySearch() {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.symmetric(
        vertical:
            35,

        horizontal:
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
          Column(
        children: [
          Icon(
            Icons
                .person_search_outlined,

            color:
                AppColors.pureWhite
                    .withOpacity(
              0.25,
            ),

            size:
                45,
          ),

          const SizedBox(
            height:
                12,
          ),

          const Text(
            'Nessun utente trovato',

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
                5,
          ),

          Text(
            'Prova a modificare la ricerca o il filtro.',

            textAlign:
                TextAlign.center,

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
        ],
      ),
    );
  }


  void _openUser(
    SocialUser user,
  ) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
            Text(
          'Profilo di ${user.name}: pagina dettaglio da collegare.',
        ),
      ),
    );
  }
}


// =============================================================================
// USER CARD
// =============================================================================

class _UserCard
    extends StatelessWidget {

  final String name;

  final String role;

  final String course;

  final String subjects;

  final bool available;

  final VoidCallback onTap;


  const _UserCard({
    required this.name,

    required this.role,

    required this.course,

    required this.subjects,

    required this.available,

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
          18,
        ),

        child:
            Container(
          padding:
              const EdgeInsets.all(
            16,
          ),

          decoration:
              BoxDecoration(
            color:
                AppColors
                    .eleganceMidnight,

            borderRadius:
                BorderRadius.circular(
              18,
            ),

            border:
                Border.all(
              color:
                  AppColors.skyBlue
                      .withOpacity(
                0.13,
              ),
            ),

            boxShadow: [
              BoxShadow(
                color:
                    Colors.black
                        .withOpacity(
                  0.10,
                ),

                blurRadius:
                    7,

                offset:
                    const Offset(
                  0,
                  3,
                ),
              ),
            ],
          ),

          child:
              Row(
            children: [
              Container(
                width:
                    54,

                height:
                    54,

                decoration:
                    BoxDecoration(
                  color:
                      AppColors
                          .brandNightBlue,

                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),

                child:
                    const Icon(
                  Icons.person_rounded,

                  color:
                      AppColors.skyBlue,

                  size:
                      28,
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
                    Text(
                      name,

                      style:
                          const TextStyle(
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
                          4,
                    ),

                    Text(
                      '$role · $course',

                      style:
                          TextStyle(
                        color:
                            AppColors.pureWhite
                                .withOpacity(
                          0.52,
                        ),

                        fontSize:
                            11,
                      ),
                    ),

                    const SizedBox(
                      height:
                          6,
                    ),

                    Text(
                      subjects,

                      maxLines:
                          1,

                      overflow:
                          TextOverflow
                              .ellipsis,

                      style:
                          TextStyle(
                        color:
                            AppColors.materialSky
                                .withOpacity(
                          0.85,
                        ),

                        fontSize:
                            10,
                      ),
                    ),

                    const SizedBox(
                      height:
                          7,
                    ),

                    Row(
                      children: [
                        Icon(
                          Icons.circle,

                          color:
                              available
                                  ? Colors
                                      .greenAccent
                                  : Colors
                                      .white30,

                          size:
                              7,
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
                              TextStyle(
                            color:
                                AppColors.pureWhite
                                    .withOpacity(
                              0.45,
                            ),

                            fontSize:
                                10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width:
                    10,
              ),

              const Icon(
                Icons
                    .chevron_right_rounded,

                color:
                    Colors.white38,

                size:
                    25,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// =============================================================================
// PROFILE INFO ROW
// =============================================================================

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
                    TextStyle(
                  color:
                      AppColors.pureWhite
                          .withOpacity(
                    0.40,
                  ),

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
                    TextStyle(
                  color:
                      AppColors.pureWhite
                          .withOpacity(
                    0.78,
                  ),

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


// =============================================================================
// SUBJECT CHIP
// =============================================================================

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
          Text(
        label,

        style:
            TextStyle(
          color:
              AppColors.pureWhite
                  .withOpacity(
            0.80,
          ),

          fontSize:
              11,
        ),
      ),
    );
  }
}


// =============================================================================
// STATISTIC CARD
// =============================================================================

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
            15,

        horizontal:
            8,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.eleganceMidnight,

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
          Column(
        children: [
          Icon(
            icon,

            color:
                AppColors.materialSky,

            size:
                21,
          ),

          const SizedBox(
            height:
                7,
          ),

          Text(
            value,

            style:
                const TextStyle(
              color:
                  AppColors.pureWhite,

              fontSize:
                  19,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height:
                2,
          ),

          Text(
            label,

            style:
                TextStyle(
              color:
                  AppColors.pureWhite
                      .withOpacity(
                0.45,
              ),

              fontSize:
                  10,
            ),
          ),
        ],
      ),
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
      width:
          double.infinity,

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

        border:
            Border.all(
          color:
              Colors.redAccent
                  .withOpacity(
            0.25,
          ),
        ),
      ),

      child:
          Column(
        children: [
          const Icon(
            Icons
                .error_outline_rounded,

            color:
                Colors.redAccent,

            size:
                38,
          ),

          const SizedBox(
            height:
                12,
          ),

          const Text(
            'Errore di connessione',

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
                7,
          ),

          Text(
            message,

            textAlign:
                TextAlign.center,

            maxLines:
                4,

            overflow:
                TextOverflow.ellipsis,

            style:
                TextStyle(
              color:
                  AppColors.pureWhite
                      .withOpacity(
                0.50,
              ),

              fontSize:
                  10,

              height:
                  1.4,
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
        ],
      ),
    );
  }
}


// =============================================================================
// CARICAMENTO GRUPPI DAL BACKEND
// =============================================================================
//
// Per ora arricchiamo ogni gruppo con membri e materiali tramite gli endpoint
// di dettaglio. In futuro conviene far restituire questi conteggi direttamente
// da /groups e /user_groups per evitare richieste aggiuntive.
//

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


  for (final rawGroup
      in rawGroups) {

    Map<String, dynamic>
        merged =
        Map<String, dynamic>.from(
      rawGroup,
    );


    final dynamic rawId =
        rawGroup['id'];


    final int? groupId =
        rawId is int
            ? rawId
            : int.tryParse(
                rawId?.toString() ??
                    '',
              );


    if (groupId != null) {
      try {
        final detail =
            await apiService
                .getGroup(
          groupId,
        );


        merged.addAll(
          detail,
        );
      } catch (_) {
        // Manteniamo comunque il gruppo ricevuto dalla lista.
      }


      try {
        final materials =
            await apiService
                .getGroupMaterials(
          groupId,
        );


        merged['material_count'] =
            materials.length;
      } catch (_) {
        // Il gruppo rimane visualizzabile anche se i materiali non rispondono.
      }
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