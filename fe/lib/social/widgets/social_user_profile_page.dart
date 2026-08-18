import 'package:flutter/material.dart';

import '../../theme/nightTheme.dart';

import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/auth_session.dart';

import '../social_models.dart';

import '../message/message_page.dart';

import '../reviews/user_reviews_section.dart';

import 'academic_paths_page.dart';

import 'teacher_assignment_page.dart';

class SocialUserProfilePage extends StatefulWidget {
  final SocialUser user;

  const SocialUserProfilePage({
    super.key,
    required this.user,
  });

  @override
  State<SocialUserProfilePage> createState() =>
      _SocialUserProfilePageState();
}

class _SocialUserProfilePageState
    extends State<SocialUserProfilePage> {
  final AuthSession _session =
      AuthSession.instance;

  final AuthService _authService =
      AuthService();

  final ApiService _apiService =
      ApiService();

  late SocialUser _user;

  bool _refreshingProfile =
      false;

  @override
  void initState() {
    super.initState();

    _user =
        widget.user;
  }

  bool get _isAuthenticated {
    return _session.isAuthenticated;
  }

  bool get _isOwnProfile {
    return _session.currentUserId ==
        _user.id;
  }

  bool get _isTeacher {
    return _user.type ==
        SocialUserType.teacher;
  }

  List<SocialSubject> get _helpSubjects {
    return _user.subjects
        .where(
          (
            SocialSubject subject,
          ) =>
              subject.canHelp,
        )
        .toList();
  }

  List<SocialSubject>
      get _privateLessonSubjects {
    return _user.subjects
        .where(
          (
            SocialSubject subject,
          ) =>
              subject
                  .canGivePrivateLessons,
        )
        .toList();
  }


  List<SocialAcademicTitle>
      get _academicTitlesForDisplay {
    if (_isOwnProfile) {
      return _user.academicTitles;
    }

    return _user.academicTitles
        .where(
          (
            SocialAcademicTitle title,
          ) =>
              title.isVerified,
        )
        .toList();
  }

  List<SocialAcademicPath>
      get _legacyGraduatedTitlesForDisplay {
    if (_user.academicTitles.isNotEmpty) {
      return const [];
    }

    return _user.academicPaths
        .where(
          (
            SocialAcademicPath path,
          ) =>
              path.status ==
                  AcademicPathStatus.graduated &&
              (
                _isOwnProfile ||
                path.isVerified
              ),
        )
        .toList();
  }

  List<SocialAcademicPath>
      get _academicPathsForDisplay {
    return _user.academicPaths
        .where(
          (
            SocialAcademicPath path,
          ) {
            if (
              path.status ==
                  AcademicPathStatus.graduated
            ) {
              return false;
            }

            if (_isOwnProfile) {
              return true;
            }

            return path.isVerified;
          },
        )
        .toList();
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
            Text(
          _user.name,

          maxLines:
              1,

          overflow:
              TextOverflow.ellipsis,
        ),

        actions: [
          if (_isOwnProfile)
            PopupMenuButton<String>(
              tooltip:
                  'Opzioni profilo',

              color:
                  AppColors.eleganceDeepNavy,

              icon:
                  const Icon(
                Icons.more_vert_rounded,
              ),

              onSelected:
                  _handleOwnProfileMenu,

              itemBuilder:
                  (
                BuildContext context,
              ) =>
                      const [
                PopupMenuItem<String>(
                  value:
                      'report_error',

                  child:
                      _ProfileMenuItem(
                    icon:
                        Icons
                            .bug_report_outlined,

                    label:
                        'Segnala un errore',
                  ),
                ),

                PopupMenuItem<String>(
                  value:
                      'delete_account',

                  child:
                      _ProfileMenuItem(
                    icon:
                        Icons
                            .delete_forever_outlined,

                    label:
                        'Elimina account',

                    danger:
                        true,
                  ),
                ),

                PopupMenuDivider(),

                PopupMenuItem<String>(
                  value:
                      'logout',

                  child:
                      _ProfileMenuItem(
                    icon:
                        Icons.logout_rounded,

                    label:
                        'Esci',

                    danger:
                        true,
                  ),
                ),
              ],
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
                  800,
            ),

            child:
                ListView(
              padding:
                  const EdgeInsets.all(
                20,
              ),

              children: [
                _buildProfileHeader(),

                const SizedBox(
                  height:
                      16,
                ),

                if (!_isOwnProfile)
                  _buildActions(),

                if (!_isOwnProfile)
                  const SizedBox(
                    height:
                        18,
                  ),

                _buildAbout(),

                const SizedBox(
                  height:
                      16,
                ),

                _buildAcademicTitles(),

                const SizedBox(
                  height:
                      16,
                ),

                _buildAcademicPaths(),

                const SizedBox(
                  height:
                      16,
                ),

                if (_isTeacher) ...[
                  _buildTeacherAssignments(),

                  const SizedBox(
                    height:
                        16,
                  ),
                ],

                _buildSubjects(),

                if (_helpSubjects.isNotEmpty) ...[
                  const SizedBox(
                    height:
                        16,
                  ),

                  _buildHelpSubjects(),
                ],

                if (
                  _privateLessonSubjects
                      .isNotEmpty
                ) ...[
                  const SizedBox(
                    height:
                        16,
                  ),

                  _buildPrivateLessonSubjects(),
                ],

                const SizedBox(
                  height:
                      16,
                ),

                _buildAvailability(),

                const SizedBox(
                  height:
                      16,
                ),

                _buildReviews(),

                if (
                  !_isOwnProfile &&
                  _isAuthenticated
                ) ...[
                  const SizedBox(
                    height:
                        20,
                  ),

                  _buildReportProfile(),
                ],

                const SizedBox(
                  height:
                      24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportProfile() {
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
          16,
        ),

        border:
            Border.all(
          color:
              Colors.redAccent
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
          const Row(
            children: [
              Icon(
                Icons
                    .flag_outlined,

                color:
                    Colors.redAccent,

                size:
                    18,
              ),

              SizedBox(
                width:
                    8,
              ),

              Text(
                'Hai notato un problema?',

                style:
                    TextStyle(
                  color:
                      AppColors.pureWhite,

                  fontSize:
                      13,

                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(
            height:
                7,
          ),

          Text(
            'Puoi segnalare questo profilo se contiene informazioni inappropriate, false o viola le regole della community.',

            style:
                TextStyle(
              color:
                  AppColors.pureWhite
                      .withOpacity(
                0.46,
              ),

              fontSize:
                  10,

              height:
                  1.4,
            ),
          ),

          const SizedBox(
            height:
                13,
          ),

          SizedBox(
            width:
                double.infinity,

            child:
                OutlinedButton.icon(
              onPressed:
                  _reportProfile,

              icon:
                  const Icon(
                Icons.flag_outlined,

                size:
                    17,
              ),

              label:
                  const Text(
                'Segnala profilo',
              ),

              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    Colors.redAccent,

                side:
                    BorderSide(
                  color:
                      Colors.redAccent
                          .withOpacity(
                    0.35,
                  ),
                ),

                padding:
                    const EdgeInsets.symmetric(
                  vertical:
                      12,
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

  Widget _buildTeacherAssignments() {
    final List<TeacherAssignment>
        assignments =
        _isOwnProfile
            ? _user.teacherAssignments
            : _user.teacherAssignments
                .where(
                  (
                    TeacherAssignment
                        assignment,
                  ) =>
                      assignment.isVerified &&
                      assignment.isCurrent,
                )
                .toList();

    return _SectionCard(
      title:
          'Insegnamenti',

      icon:
          Icons
              .cast_for_education_outlined,

      trailing:
          _isOwnProfile
              ? TextButton.icon(
                  onPressed:
                      _openTeacherAssignments,

                  icon:
                      const Icon(
                    Icons.edit_outlined,

                    size:
                        15,
                  ),

                  label:
                      const Text(
                    'Gestisci',
                  ),

                  style:
                      TextButton.styleFrom(
                    foregroundColor:
                        AppColors.materialSky,
                  ),
                )
              : null,

      child:
          assignments.isEmpty
              ? Text(
                  _isOwnProfile
                      ? 'Nessun insegnamento associato.'
                      : 'Nessun insegnamento verificato.',

                  style:
                      TextStyle(
                    color:
                        AppColors.pureWhite
                            .withOpacity(
                      0.40,
                    ),

                    fontSize:
                        11,
                  ),
                )
              : Column(
                  children:
                      assignments
                          .map(
                            _buildTeacherAssignment,
                          )
                          .toList(),
                ),
    );
  }

  Widget _buildTeacherAssignment(
    TeacherAssignment assignment,
  ) {
    final SubjectOffering? offering =
        assignment.offering;

    final List<String> details =
        [];

    if (
      offering != null &&
      offering.module
          .trim()
          .isNotEmpty
    ) {
      details.add(
        offering.module,
      );
    }

    if (
      offering != null &&
      offering.channel
          .trim()
          .isNotEmpty
    ) {
      details.add(
        'Canale ${offering.channel}',
      );
    }

    if (
      offering != null &&
      offering.academicYear
          .trim()
          .isNotEmpty
    ) {
      details.add(
        offering.academicYear,
      );
    }

    return Container(
      width:
          double.infinity,

      margin:
          const EdgeInsets.only(
        bottom:
            9,
      ),

      padding:
          const EdgeInsets.all(
        12,
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
              AppColors.teacherIndigo
                  .withOpacity(
            0.15,
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
              const Icon(
                Icons.school_outlined,

                color:
                    AppColors.skyBlue,

                size:
                    17,
              ),

              const SizedBox(
                width:
                    8,
              ),

              Expanded(
                child:
                    Text(
                  assignment.subject.name,

                  style:
                      const TextStyle(
                    color:
                        AppColors.pureWhite,

                    fontSize:
                        12,

                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),

              if (
                assignment.isVerified
              )
                const _StatusBadge(
                  label:
                      'Verificato',

                  icon:
                      Icons.verified_rounded,

                  color:
                      Colors.greenAccent,
                )
              else if (
                assignment.isPending
              )
                const _StatusBadge(
                  label:
                      'In verifica',

                  icon:
                      Icons.schedule_rounded,

                  color:
                      Colors.amber,
                )
              else if (
                assignment.isRejected
              )
                const _StatusBadge(
                  label:
                      'Rifiutato',

                  icon:
                      Icons.cancel_outlined,

                  color:
                      Colors.redAccent,
                ),
            ],
          ),

          if (details.isNotEmpty) ...[
            const SizedBox(
              height:
                  9,
            ),

            Wrap(
              spacing:
                  6,

              runSpacing:
                  6,

              children:
                  details
                      .map(
                        (
                          String detail,
                        ) =>
                            _SmallBadge(
                          label:
                              detail,

                          icon:
                              Icons
                                  .account_tree_outlined,
                        ),
                      )
                      .toList(),
            ),
          ],

          if (_isOwnProfile) ...[
            const SizedBox(
              height:
                  8,
            ),

            Row(
              children: [
                Icon(
                  assignment.isCurrent
                      ? Icons
                          .check_circle_outline_rounded
                      : Icons
                          .history_rounded,

                  color:
                      assignment.isCurrent
                          ? Colors.greenAccent
                          : AppColors
                              .pureWhite
                              .withOpacity(
                            0.35,
                          ),

                  size:
                      13,
                ),

                const SizedBox(
                  width:
                      5,
                ),

                Text(
                  assignment.isCurrent
                      ? 'Insegnamento attuale'
                      : 'Insegnamento passato',

                  style:
                      TextStyle(
                    color:
                        AppColors.pureWhite
                            .withOpacity(
                      0.45,
                    ),

                    fontSize:
                        9,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final SocialAcademicPath?
        primaryPath =
        _user.primaryAcademicPath;

    final SocialAcademicPath?
        currentPath =
        _user.currentAcademicPath;

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
              (
                _isTeacher
                    ? AppColors.teacherIndigo
                    : AppColors.socialBlue
              ).withOpacity(
            0.25,
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
                    72,

                height:
                    72,

                alignment:
                    Alignment.center,

                decoration:
                    BoxDecoration(
                  color:
                      _isTeacher
                          ? AppColors.teacherIndigo
                          : AppColors.studentBlue,

                  borderRadius:
                      BorderRadius.circular(
                    22,
                  ),
                ),

                child:
                    Text(
                  _user.name.isNotEmpty
                      ? _user.name[0]
                          .toUpperCase()
                      : '?',

                  style:
                      const TextStyle(
                    color:
                        AppColors.pureWhite,

                    fontSize:
                        27,

                    fontWeight:
                        FontWeight.bold,
                  ),
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
                      _user.name,

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

                    Wrap(
                      spacing:
                          6,

                      runSpacing:
                          6,

                      crossAxisAlignment:
                          WrapCrossAlignment
                              .center,

                      children: [
                        _RoleBadge(
                          isTeacher:
                              _isTeacher,
                        ),

                        if (
                          _isTeacher &&
                          _user
                              .isVerifiedTeacher
                        )
                          const _StatusBadge(
                            label:
                                'Docente verificato',

                            icon:
                                Icons
                                    .verified_rounded,

                            color:
                                Colors.greenAccent,
                          ),

                        if (
                          _isTeacher &&
                          _user
                              .isTeacherPending
                        )
                          const _StatusBadge(
                            label:
                                'Verifica docente in corso',

                            icon:
                                Icons
                                    .schedule_rounded,

                            color:
                                Colors.amber,
                          ),
                      ],
                    ),

                    const SizedBox(
                      height:
                          7,
                    ),

                    Text(
                      _user.email,

                      maxLines:
                          1,

                      overflow:
                          TextOverflow.ellipsis,

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
                  ],
                ),
              ),

              _AvailabilityBadge(
                available:
                    _user.available,
              ),
            ],
          ),

          if (
            primaryPath != null ||
            currentPath != null
          ) ...[
            const SizedBox(
              height:
                  20,
            ),

            Divider(
              height:
                  1,

              color:
                  AppColors.pureWhite
                      .withOpacity(
                0.07,
              ),
            ),

            const SizedBox(
              height:
                  16,
            ),

            if (primaryPath != null)
              _buildPrimaryAcademicSummary(
                primaryPath,
              )
            else if (currentPath != null)
              _buildPrimaryAcademicSummary(
                currentPath,
              ),
          ] else ...[
            const SizedBox(
              height:
                  20,
            ),

            Divider(
              height:
                  1,

              color:
                  AppColors.pureWhite
                      .withOpacity(
                0.07,
              ),
            ),

            const SizedBox(
              height:
                  16,
            ),

            _InfoRow(
              icon:
                  Icons
                      .account_balance_outlined,

              label:
                  'Dipartimento',

              value:
                  _user.department.isEmpty
                      ? 'Non specificato'
                      : _user.department,
            ),

            const SizedBox(
              height:
                  12,
            ),

            _InfoRow(
              icon:
                  Icons.school_outlined,

              label:
                  'Corso',

              value:
                  _user.course.isEmpty
                      ? 'Non specificato'
                      : _user.course,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrimaryAcademicSummary(
    SocialAcademicPath path,
  ) {
    return Column(
      children: [
        if (path.university.isNotEmpty)
          _InfoRow(
            icon:
                Icons
                    .account_balance_outlined,

            label:
                'Ateneo',

            value:
                path.university,
          ),

        if (path.university.isNotEmpty)
          const SizedBox(
            height:
                12,
          ),

        _InfoRow(
          icon:
              Icons.business_outlined,

          label:
              'Dipartimento',

          value:
              path.department.isEmpty
                  ? 'Non specificato'
                  : path.department,
        ),

        const SizedBox(
          height:
              12,
        ),

        _InfoRow(
          icon:
              Icons.school_outlined,

          label:
              'Corso',

          value:
              _academicPathTitle(
            path,
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child:
              ElevatedButton.icon(
            onPressed:
                _openMessages,

            icon:
                const Icon(
              Icons
                  .chat_bubble_outline_rounded,
            ),

            label:
                const Text(
              'Contatta',
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
                  13,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(
          width:
              10,
        ),

        Expanded(
          child:
              OutlinedButton.icon(
            onPressed:
                _requestConnection,

            icon:
                const Icon(
              Icons
                  .person_add_alt_1_rounded,
            ),

            label:
                const Text(
              'Collegati',
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
                  0.28,
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
    );
  }

  Widget _buildAbout() {
    return _SectionCard(
      title:
          'Profilo',

      icon:
          Icons.person_outline_rounded,

      child:
          Text(
        _user.description.isEmpty
            ? 'Questo utente non ha ancora aggiunto una descrizione.'
            : _user.description,

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
              1.5,
        ),
      ),
    );
  }

  Widget _buildAcademicTitles() {
    final List<SocialAcademicTitle>
        titles =
        _academicTitlesForDisplay;

    final List<SocialAcademicPath>
        legacyTitles =
        _legacyGraduatedTitlesForDisplay;

    return _SectionCard(
      title:
          'Titoli conseguiti',

      icon:
          Icons.workspace_premium_outlined,

      child:
          titles.isEmpty &&
                  legacyTitles.isEmpty
              ? Text(
                  _isOwnProfile
                      ? 'Nessun titolo accademico aggiunto.'
                      : 'Nessun titolo accademico verificato.',

                  style:
                      TextStyle(
                    color:
                        AppColors.pureWhite
                            .withOpacity(
                      0.40,
                    ),

                    fontSize:
                        11,
                  ),
                )
              : Column(
                  children: [
                    ...titles.map(
                      _buildAcademicTitle,
                    ),

                    ...legacyTitles.map(
                      _buildLegacyAcademicTitle,
                    ),
                  ],
                ),
    );
  }

  Widget _buildAcademicTitle(
    SocialAcademicTitle title,
  ) {
    return Container(
      width:
          double.infinity,

      margin:
          const EdgeInsets.only(
        bottom:
            10,
      ),

      padding:
          const EdgeInsets.all(
        13,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.brandNightBlue,

        borderRadius:
            BorderRadius.circular(
          13,
        ),

        border:
            Border.all(
          color:
              title.isPrimary
                  ? Colors.amber
                      .withOpacity(
                    0.24,
                  )
                  : Colors.amber
                      .withOpacity(
                    0.10,
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
              const Icon(
                Icons.workspace_premium_outlined,

                color:
                    Colors.amber,

                size:
                    18,
              ),

              const SizedBox(
                width:
                    8,
              ),

              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      title.titleTypeLabel,

                      style:
                          const TextStyle(
                        color:
                            AppColors.pureWhite,

                        fontSize:
                            12,

                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    if (
                      title.course
                          .trim()
                          .isNotEmpty
                    ) ...[
                      const SizedBox(
                        height:
                            3,
                      ),

                      Text(
                        title.course,

                        style:
                            TextStyle(
                          color:
                              AppColors.pureWhite
                                  .withOpacity(
                            0.58,
                          ),

                          fontSize:
                              10,
                        ),
                      ),
                    ],

                    if (
                      title.university
                          .trim()
                          .isNotEmpty
                    ) ...[
                      const SizedBox(
                        height:
                            3,
                      ),

                      Text(
                        title.university,

                        style:
                            TextStyle(
                          color:
                              AppColors.pureWhite
                                  .withOpacity(
                            0.40,
                          ),

                          fontSize:
                              9,
                        ),
                      ),
                    ],

                    if (
                      title.department
                          .trim()
                          .isNotEmpty
                    ) ...[
                      const SizedBox(
                        height:
                            2,
                      ),

                      Text(
                        title.department,

                        style:
                            TextStyle(
                          color:
                              AppColors.pureWhite
                                  .withOpacity(
                            0.34,
                          ),

                          fontSize:
                              9,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (title.isPrimary)
                const _SmallBadge(
                  label:
                      'Principale',

                  icon:
                      Icons.star_outline_rounded,
                ),
            ],
          ),

          const SizedBox(
            height:
                10,
          ),

          Wrap(
            spacing:
                6,

            runSpacing:
                6,

            children: [
              _AcademicTitleVerificationBadge(
                title:
                    title,
              ),

              if (
                title.graduationYear !=
                    null
              )
                _SmallBadge(
                  label:
                      'Conseguito ${title.graduationYear}',

                  icon:
                      Icons.calendar_month_outlined,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegacyAcademicTitle(
    SocialAcademicPath path,
  ) {
    return Container(
      width:
          double.infinity,

      margin:
          const EdgeInsets.only(
        bottom:
            10,
      ),

      padding:
          const EdgeInsets.all(
        13,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.brandNightBlue,

        borderRadius:
            BorderRadius.circular(
          13,
        ),

        border:
            Border.all(
          color:
              path.isPrimary
                  ? Colors.amber
                      .withOpacity(
                    0.24,
                  )
                  : Colors.amber
                      .withOpacity(
                    0.10,
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
              const Icon(
                Icons.workspace_premium_outlined,

                color:
                    Colors.amber,

                size:
                    18,
              ),

              const SizedBox(
                width:
                    8,
              ),

              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      path.degreeType
                              .trim()
                              .isEmpty
                          ? 'Titolo accademico'
                          : academicPathTypeLabel(
                              path.degreeType,
                            ),

                      style:
                          const TextStyle(
                        color:
                            AppColors.pureWhite,

                        fontSize:
                            12,

                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    if (
                      path.course
                          .trim()
                          .isNotEmpty
                    ) ...[
                      const SizedBox(
                        height:
                            3,
                      ),

                      Text(
                        path.course,

                        style:
                            TextStyle(
                          color:
                              AppColors.pureWhite
                                  .withOpacity(
                            0.58,
                          ),

                          fontSize:
                              10,
                        ),
                      ),
                    ],

                    if (
                      path.university
                          .trim()
                          .isNotEmpty
                    ) ...[
                      const SizedBox(
                        height:
                            3,
                      ),

                      Text(
                        path.university,

                        style:
                            TextStyle(
                          color:
                              AppColors.pureWhite
                                  .withOpacity(
                            0.40,
                          ),

                          fontSize:
                              9,
                        ),
                      ),
                    ],

                    if (
                      path.department
                          .trim()
                          .isNotEmpty
                    ) ...[
                      const SizedBox(
                        height:
                            2,
                      ),

                      Text(
                        path.department,

                        style:
                            TextStyle(
                          color:
                              AppColors.pureWhite
                                  .withOpacity(
                            0.34,
                          ),

                          fontSize:
                              9,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (path.isPrimary)
                const _SmallBadge(
                  label:
                      'Principale',

                  icon:
                      Icons.star_outline_rounded,
                ),
            ],
          ),

          const SizedBox(
            height:
                10,
          ),

          Wrap(
            spacing:
                6,

            runSpacing:
                6,

            children: [
              _DegreeVerificationBadge(
                path:
                    path,
              ),

              if (
                path.graduationYear !=
                    null
              )
                _SmallBadge(
                  label:
                      'Conseguito ${path.graduationYear}',

                  icon:
                      Icons.calendar_month_outlined,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicPaths() {
    final List<SocialAcademicPath>
        paths =
        _academicPathsForDisplay;

    return _SectionCard(
      title:
          'Percorsi accademici',

      icon:
          Icons
              .account_balance_outlined,

      trailing:
          _isOwnProfile
              ? TextButton.icon(
                  onPressed:
                      _refreshingProfile
                          ? null
                          : _openAcademicPaths,

                  icon:
                      const Icon(
                    Icons.edit_outlined,

                    size:
                        15,
                  ),

                  label:
                      const Text(
                    'Gestisci',
                  ),

                  style:
                      TextButton.styleFrom(
                    foregroundColor:
                        AppColors.materialSky,

                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal:
                          8,

                      vertical:
                          4,
                    ),
                  ),
                )
              : null,

      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          if (_refreshingProfile)
            const Padding(
              padding:
                  EdgeInsets.only(
                bottom:
                    12,
              ),

              child:
                  LinearProgressIndicator(),
            ),

          if (paths.isEmpty)
            Text(
              _isOwnProfile
                  ? 'Nessun percorso accademico aggiunto.'
                  : 'Nessun percorso accademico pubblico.',

              style:
                  TextStyle(
                color:
                    AppColors.pureWhite
                        .withOpacity(
                  0.40,
                ),

                fontSize:
                    11,
              ),
            )
          else
            ...paths.map(
              _buildAcademicPath,
            ),

          if (_isOwnProfile) ...[
            const SizedBox(
              height:
                  10,
            ),

            SizedBox(
              width:
                  double.infinity,

              child:
                  OutlinedButton.icon(
                onPressed:
                    _refreshingProfile
                        ? null
                        : _openAcademicPaths,

                icon:
                    const Icon(
                  Icons.add_rounded,

                  size:
                      17,
                ),

                label:
                    const Text(
                  'Aggiungi o gestisci percorsi',
                ),

                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      AppColors.skyBlue,

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
                        12,
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
        ],
      ),
    );
  }

  Widget _buildAcademicPath(
    SocialAcademicPath path,
  ) {
    return Container(
      width:
          double.infinity,

      margin:
          const EdgeInsets.only(
        bottom:
            10,
      ),

      padding:
          const EdgeInsets.all(
        13,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.brandNightBlue,

        borderRadius:
            BorderRadius.circular(
          13,
        ),

        border:
            Border.all(
          color:
              path.isPrimary
                  ? AppColors.skyBlue
                      .withOpacity(
                    0.22,
                  )
                  : AppColors.pureWhite
                      .withOpacity(
                    0.04,
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
              const Icon(
                Icons.school_outlined,

                color:
                    AppColors.skyBlue,

                size:
                    18,
              ),

              const SizedBox(
                width:
                    8,
              ),

              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      _academicPathTitle(
                        path,
                      ),

                      style:
                          const TextStyle(
                        color:
                            AppColors.pureWhite,

                        fontSize:
                            12,

                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    if (
                      path.university
                          .isNotEmpty
                    ) ...[
                      const SizedBox(
                        height:
                            3,
                      ),

                      Text(
                        path.university,

                        style:
                            TextStyle(
                          color:
                              AppColors.pureWhite
                                  .withOpacity(
                            0.43,
                          ),

                          fontSize:
                              9,
                        ),
                      ),
                    ],

                    if (
                      path.department
                          .isNotEmpty
                    ) ...[
                      const SizedBox(
                        height:
                            2,
                      ),

                      Text(
                        path.department,

                        style:
                            TextStyle(
                          color:
                              AppColors.pureWhite
                                  .withOpacity(
                            0.35,
                          ),

                          fontSize:
                              9,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (path.isPrimary)
                const _SmallBadge(
                  label:
                      'Principale',

                  icon:
                      Icons
                          .star_outline_rounded,
                ),
            ],
          ),

          const SizedBox(
            height:
                10,
          ),

          Wrap(
            spacing:
                6,

            runSpacing:
                6,

            children: [
              _AcademicStatusBadge(
                path:
                    path,
              ),

              if (path.isCurrent)
                const _SmallBadge(
                  label:
                      'Corrente',

                  icon:
                      Icons
                          .play_circle_outline_rounded,
                ),

              if (
                path.status ==
                    AcademicPathStatus
                        .graduated
              )
                _DegreeVerificationBadge(
                  path:
                      path,
                ),

              if (
                path.startYear !=
                    null
              )
                _SmallBadge(
                  label:
                      'Dal ${path.startYear}',

                  icon:
                      Icons
                          .calendar_month_outlined,
                ),

              if (
                path.graduationYear !=
                    null
              )
                _SmallBadge(
                  label:
                      'Laurea ${path.graduationYear}',

                  icon:
                      Icons
                          .workspace_premium_outlined,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjects() {
    return _SectionCard(
      title:
          'Materie',

      icon:
          Icons.menu_book_outlined,

      child:
          _user.subjects.isEmpty
              ? Text(
                  'Nessuna materia aggiunta.',

                  style:
                      TextStyle(
                    color:
                        AppColors.pureWhite
                            .withOpacity(
                      0.40,
                    ),

                    fontSize:
                        11,
                  ),
                )
              : Column(
                  children:
                      _user.subjects
                          .map(
                            _buildSubject,
                          )
                          .toList(),
                ),
    );
  }

  Widget _buildHelpSubjects() {
    return _SectionCard(
      title:
          'Può aiutarti in',

      icon:
          Icons
              .volunteer_activism_outlined,

      child:
          Column(
        children:
            _helpSubjects
                .map(
                  (
                    SocialSubject subject,
                  ) =>
                      _buildOfferedSubject(
                    subject:
                        subject,

                    type:
                        _OfferedSubjectType.help,
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildPrivateLessonSubjects() {
    return _SectionCard(
      title:
          'Lezioni private in',

      icon:
          Icons
              .cast_for_education_outlined,

      child:
          Column(
        children:
            _privateLessonSubjects
                .map(
                  (
                    SocialSubject subject,
                  ) =>
                      _buildOfferedSubject(
                    subject:
                        subject,

                    type:
                        _OfferedSubjectType
                            .privateLesson,
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildOfferedSubject({
    required SocialSubject subject,
    required _OfferedSubjectType type,
  }) {
    return Container(
      width:
          double.infinity,

      margin:
          const EdgeInsets.only(
        bottom:
            8,
      ),

      padding:
          const EdgeInsets.symmetric(
        horizontal:
            12,

        vertical:
            10,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.brandNightBlue,

        borderRadius:
            BorderRadius.circular(
          11,
        ),
      ),

      child:
          Row(
        children: [
          Icon(
            type ==
                    _OfferedSubjectType
                        .help
                ? Icons
                    .volunteer_activism_outlined
                : Icons
                    .cast_for_education_outlined,

            color:
                AppColors.materialSky,

            size:
                16,
          ),

          const SizedBox(
            width:
                8,
          ),

          Expanded(
            child:
                Text(
              subject.name,

              style:
                  const TextStyle(
                color:
                    AppColors.pureWhite,

                fontSize:
                    11,

                fontWeight:
                    FontWeight.w500,
              ),
            ),
          ),

          if (
            subject.isGradeVerified &&
            subject.grade != null
          )
            _SmallBadge(
              label:
                  '${subject.grade}/30',

              icon:
                  Icons.verified_rounded,
            ),
        ],
      ),
    );
  }

  Widget _buildSubject(
    SocialSubject subject,
  ) {
    return Container(
      width:
          double.infinity,

      margin:
          const EdgeInsets.only(
        bottom:
            9,
      ),

      padding:
          const EdgeInsets.all(
        12,
      ),

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
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              const Icon(
                Icons.menu_book_outlined,

                color:
                    AppColors.skyBlue,

                size:
                    16,
              ),

              const SizedBox(
                width:
                    7,
              ),

              Expanded(
                child:
                    Text(
                  subject.name,

                  style:
                      const TextStyle(
                    color:
                        AppColors.pureWhite,

                    fontSize:
                        12,

                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),

              if (
                subject.grade !=
                    null
              )
                _GradeBadge(
                  subject:
                      subject,
                ),
            ],
          ),

          if (
            subject.canHelp ||
            subject
                .canGivePrivateLessons
          ) ...[
            const SizedBox(
              height:
                  8,
            ),

            Wrap(
              spacing:
                  6,

              runSpacing:
                  6,

              children: [
                if (subject.canHelp)
                  const _SmallBadge(
                    label:
                        'Aiuto',

                    icon:
                        Icons
                            .volunteer_activism_outlined,
                  ),

                if (
                  subject
                      .canGivePrivateLessons
                )
                  const _SmallBadge(
                    label:
                        'Lezioni private',

                    icon:
                        Icons
                            .cast_for_education_outlined,
                  ),
              ],
            ),
          ],

          if (
            subject.note
                .isNotEmpty
          ) ...[
            const SizedBox(
              height:
                  8,
            ),

            Text(
              subject.note,

              style:
                  TextStyle(
                color:
                    AppColors.pureWhite
                        .withOpacity(
                  0.46,
                ),

                fontSize:
                    10,

                height:
                    1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvailability() {
    return _SectionCard(
      title:
          'Disponibilità',

      icon:
          Icons.schedule_outlined,

      child:
          Column(
        children: [
          _AvailabilityRow(
            icon:
                Icons.circle,

            title:
                'Disponibilità generale',

            value:
                _user.available
                    ? 'Disponibile'
                    : 'Non disponibile',

            active:
                _user.available,
          ),

          const SizedBox(
            height:
                12,
          ),

          _AvailabilityRow(
            icon:
                Icons
                    .volunteer_activism_outlined,

            title:
                'Aiuto allo studio',

            value:
                _user.availableForHelp
                    ? 'Disponibile ad aiutare'
                    : 'Non disponibile ad aiutare',

            active:
                _user.availableForHelp,
          ),

          const SizedBox(
            height:
                12,
          ),

          _AvailabilityRow(
            icon:
                Icons
                    .cast_for_education_outlined,

            title:
                'Lezioni private',

            value:
                _user
                        .availableForPrivateLessons
                    ? 'Disponibile per lezioni private'
                    : 'Non disponibile per lezioni private',

            active:
                _user
                    .availableForPrivateLessons,
          ),
        ],
      ),
    );
  }

  Widget _buildReviews() {
    return UserReviewsSection(
      user:
          _user,
    );
  }

  String _academicPathTitle(
    SocialAcademicPath path,
  ) {
    final String course =
        path.course.trim();

    final String degree =
        path.degreeType.trim();

    if (
      course.isNotEmpty &&
      degree.isNotEmpty
    ) {
      return '$course · ${academicPathTypeLabel(degree)}';
    }

    if (course.isNotEmpty) {
      return course;
    }

    if (degree.isNotEmpty) {
      return degree;
    }

    return 'Percorso accademico';
  }

  Future<void>
      _openAcademicPaths() async {
    if (!_isOwnProfile) {
      return;
    }

    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (_) =>
                const AcademicPathsPage(),
      ),
    );

    if (!mounted) {
      return;
    }

    await _refreshProfile();
  }

  Future<void>
      _openTeacherAssignments() async {
    if (
      !_isOwnProfile ||
      !_isTeacher
    ) {
      return;
    }

    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (_) =>
                const TeacherAssignmentsPage(),
      ),
    );

    if (!mounted) {
      return;
    }

    await _refreshProfile();
  }

  Future<void>
      _refreshProfile() async {
    if (
      !_isOwnProfile ||
      _refreshingProfile
    ) {
      return;
    }

    setState(() {
      _refreshingProfile =
          true;
    });

    try {
      final SocialUser updatedUser =
          await _apiService
              .getCurrentUser();

      if (!mounted) {
        return;
      }

      setState(() {
        _user =
            updatedUser;
      });

      _session.updateUser(
        updatedUser,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _cleanError(
          e,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _refreshingProfile =
              false;
        });
      }
    }
  }

  Future<void> _openMessages() async {
    if (!_isAuthenticated) {
      _showAuthenticationRequired();

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
      _requestConnection() async {
    if (!_isAuthenticated) {
      _showAuthenticationRequired();

      return;
    }

    _showMessage(
      'Il sistema di collegamenti verrà attivato con il modulo connessioni.',
    );
  }

  void _handleOwnProfileMenu(
    String value,
  ) {
    switch (value) {
      case 'report_error':
        _reportError();

        return;

      case 'delete_account':
        _confirmDeleteAccount();

        return;

      case 'logout':
        _confirmLogout();

        return;
    }
  }

  Future<void> _reportProfile() async {
    if (!_isAuthenticated) {
      _showAuthenticationRequired();

      return;
    }

    final TextEditingController
        controller =
        TextEditingController();

    String reason =
        'Profilo falso o informazioni errate';

    final bool? submitted =
        await showDialog<bool>(
      context:
          context,

      builder:
          (
        BuildContext dialogContext,
      ) {
        return StatefulBuilder(
          builder:
              (
            BuildContext context,
            StateSetter setDialogState,
          ) {
            return AlertDialog(
              backgroundColor:
                  AppColors
                      .eleganceDeepNavy,

              title:
                  const Text(
                'Segnala profilo',

                style:
                    TextStyle(
                  color:
                      AppColors.pureWhite,
                ),
              ),

              content:
                  SingleChildScrollView(
                child:
                    Column(
                  mainAxisSize:
                      MainAxisSize.min,

                  children: [
                    DropdownButtonFormField<
                        String>(
                      value:
                          reason,

                      isExpanded:
                          true,

                      dropdownColor:
                          AppColors
                              .eleganceDeepNavy,

                      decoration:
                          const InputDecoration(
                        labelText:
                            'Motivo',
                      ),

                      items:
                          const [
                        DropdownMenuItem(
                          value:
                              'Profilo falso o informazioni errate',

                          child:
                              Text(
                            'Profilo falso o informazioni errate',
                          ),
                        ),

                        DropdownMenuItem(
                          value:
                              'Comportamento inappropriato',

                          child:
                              Text(
                            'Comportamento inappropriato',
                          ),
                        ),

                        DropdownMenuItem(
                          value:
                              'Spam o pubblicità',

                          child:
                              Text(
                            'Spam o pubblicità',
                          ),
                        ),

                        DropdownMenuItem(
                          value:
                              'Contenuto offensivo',

                          child:
                              Text(
                            'Contenuto offensivo',
                          ),
                        ),

                        DropdownMenuItem(
                          value:
                              'Altro',

                          child:
                              Text(
                            'Altro',
                          ),
                        ),
                      ],

                      onChanged:
                          (
                        String? value,
                      ) {
                        if (value ==
                            null) {
                          return;
                        }

                        setDialogState(
                          () {
                            reason =
                                value;
                          },
                        );
                      },
                    ),

                    const SizedBox(
                      height:
                          14,
                    ),

                    TextField(
                      controller:
                          controller,

                      maxLines:
                          4,

                      style:
                          const TextStyle(
                        color:
                            AppColors
                                .pureWhite,
                      ),

                      decoration:
                          const InputDecoration(
                        labelText:
                            'Descrizione',

                        hintText:
                            'Descrivi il problema...',
                      ),
                    ),
                  ],
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

                ElevatedButton(
                  onPressed:
                      () {
                    Navigator.pop(
                      dialogContext,
                      true,
                    );
                  },

                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        Colors.redAccent,

                    foregroundColor:
                        Colors.white,
                  ),

                  child:
                      const Text(
                    'Invia segnalazione',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (
      submitted != true ||
      !mounted
    ) {
      return;
    }

    _showMessage(
      'La segnalazione verrà collegata al sistema di moderazione.',
    );
  }

  Future<void> _reportError() async {
    final TextEditingController
        controller =
        TextEditingController();

    final bool? submitted =
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
            'Segnala un errore',

            style:
                TextStyle(
              color:
                  AppColors.pureWhite,
            ),
          ),

          content:
              Column(
            mainAxisSize:
                MainAxisSize.min,

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                'Segnala un problema relativo al tuo profilo, ai dati accademici, alle materie o alle verifiche.',

                style:
                    TextStyle(
                  color:
                      AppColors.pureWhite
                          .withOpacity(
                    0.55,
                  ),

                  fontSize:
                      11,

                  height:
                      1.4,
                ),
              ),

              const SizedBox(
                height:
                    14,
              ),

              TextField(
                controller:
                    controller,

                maxLines:
                    5,

                style:
                    const TextStyle(
                  color:
                      AppColors.pureWhite,
                ),

                decoration:
                    const InputDecoration(
                  labelText:
                      'Descrizione errore',

                  hintText:
                      'Descrivi cosa non è corretto...',
                ),
              ),
            ],
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

            ElevatedButton(
              onPressed:
                  controller.text
                          .trim()
                          .isEmpty
                      ? null
                      : () {
                          Navigator.pop(
                            dialogContext,
                            true,
                          );
                        },

              child:
                  const Text(
                'Invia',
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (
      submitted != true ||
      !mounted
    ) {
      return;
    }

    _showMessage(
      'La segnalazione errore verrà collegata al sistema di supporto.',
    );
  }

  Future<void>
      _confirmDeleteAccount() async {
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
            'Elimina account',

            style:
                TextStyle(
              color:
                  Colors.redAccent,
            ),
          ),

          content:
              Text(
            'L\'eliminazione dell\'account è permanente. '
            'Prima di procedere dovremo inoltre verificare eventuali gruppi di cui sei proprietario.',

            style:
                TextStyle(
              color:
                  AppColors.pureWhite
                      .withOpacity(
                0.62,
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
                'Continua',

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

    if (
      confirmed != true ||
      !mounted
    ) {
      return;
    }

    _showMessage(
      'La procedura di eliminazione account verrà collegata al backend dopo la gestione del trasferimento dei gruppi.',
    );
  }

  Future<void> _confirmLogout() async {
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
            'Esci da StudentLab',

            style:
                TextStyle(
              color:
                  AppColors.pureWhite,
            ),
          ),

          content:
              Text(
            'Vuoi disconnetterti dal tuo account?',

            style:
                TextStyle(
              color:
                  AppColors.pureWhite
                      .withOpacity(
                0.60,
              ),
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

  Future<void> _logout() async {
    try {
      await _authService.logout();

      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
      ).pop();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _cleanError(e),
      );
    }
  }

  void _showAuthenticationRequired() {
    _showMessage(
      'Accedi a StudentLab per utilizzare questa funzione.',
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

  String _cleanError(
    Object error,
  ) {
    final String message =
        error
            .toString()
            .toLowerCase();

    if (
      message.contains('401') ||
      message.contains('unauthorized')
    ) {
      return 'La sessione non è più valida. Accedi nuovamente a StudentLab.';
    }

    if (
      message.contains('403') ||
      message.contains('forbidden')
    ) {
      return 'Non hai i permessi necessari per questa operazione.';
    }

    if (
      message.contains('404') ||
      message.contains('not found')
    ) {
      return 'Il contenuto richiesto non è più disponibile.';
    }

    if (
      message.contains('socket') ||
      message.contains('network') ||
      message.contains('connection') ||
      message.contains('timeout') ||
      message.contains('host lookup')
    ) {
      return 'Non è stato possibile contattare StudentLab. Controlla la connessione e riprova.';
    }

    if (
      message.contains('409') ||
      message.contains('conflict')
    ) {
      return 'Non è stato possibile completare l’operazione perché i dati risultano già aggiornati o presenti.';
    }

    if (
      message.contains('422') ||
      message.contains('validation') ||
      message.contains('invalid')
    ) {
      return 'Alcune informazioni non risultano valide. Controlla i dati e riprova.';
    }

    if (
      message.contains('429') ||
      message.contains('too many') ||
      message.contains('rate limit')
    ) {
      return 'Sono state effettuate troppe richieste in poco tempo. Riprova tra qualche momento.';
    }

    if (
      message.contains('500') ||
      message.contains('502') ||
      message.contains('503') ||
      message.contains('504')
    ) {
      return 'StudentLab è temporaneamente non disponibile. Riprova tra qualche momento.';
    }

    return 'Non è stato possibile completare l’operazione. Riprova.';
  }
}

enum _OfferedSubjectType {
  help,
  privateLesson,
}

class _SectionCard
    extends StatelessWidget {
  final String title;

  final IconData icon;

  final Widget child;

  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
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
            0.10,
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
              Icon(
                icon,

                color:
                    AppColors.skyBlue,

                size:
                    19,
              ),

              const SizedBox(
                width:
                    8,
              ),

              Expanded(
                child:
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
              ),

              if (trailing != null)
                trailing!,
            ],
          ),

          const SizedBox(
            height:
                14,
          ),

          child,
        ],
      ),
    );
  }
}

class _InfoRow
    extends StatelessWidget {
  final IconData icon;

  final String label;

  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
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
              9,
        ),

        Expanded(
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
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
                      11,
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
    return Row(
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Icon(
          Icons.circle,
          color:
              available
                  ? Colors.greenAccent
                  : Colors.white30,
          size:
              8,
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
                available
                    ? Colors.greenAccent
                    : Colors.white38,
            fontSize:
                9,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AvailabilityRow
    extends StatelessWidget {
  final IconData icon;

  final String title;

  final String value;

  final bool active;

  const _AvailabilityRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.active,
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
              active
                  ? Colors.greenAccent
                  : Colors.white30,

          size:
              15,
        ),

        const SizedBox(
          width:
              9,
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
                      AppColors.pureWhite,

                  fontSize:
                      11,

                  fontWeight:
                      FontWeight.w500,
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
                    0.42,
                  ),

                  fontSize:
                      9,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SmallBadge
    extends StatelessWidget {
  final String label;

  final IconData icon;

  const _SmallBadge({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            7,

        vertical:
            4,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.skyBlue
                .withOpacity(
          0.10,
        ),

        borderRadius:
            BorderRadius.circular(
          8,
        ),
      ),

      child:
          Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          Icon(
            icon,

            color:
                AppColors.materialSky,

            size:
                11,
          ),

          const SizedBox(
            width:
                4,
          ),

          Text(
            label,

            style:
                const TextStyle(
              color:
                  AppColors.materialSky,

              fontSize:
                  8,

              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge
    extends StatelessWidget {
  final bool isTeacher;

  const _RoleBadge({
    required this.isTeacher,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            7,

        vertical:
            5,
      ),

      decoration:
          BoxDecoration(
        color:
            (
              isTeacher
                  ? AppColors.teacherIndigo
                  : AppColors.studentBlue
            ).withOpacity(
          0.12,
        ),

        borderRadius:
            BorderRadius.circular(
          8,
        ),
      ),

      child:
          Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          Icon(
            isTeacher
                ? Icons
                    .cast_for_education_outlined
                : Icons.school_outlined,

            color:
                isTeacher
                    ? AppColors.teacherIndigo
                    : AppColors.studentBlue,

            size:
                13,
          ),

          const SizedBox(
            width:
                4,
          ),

          Text(
            isTeacher
                ? 'Insegnante'
                : 'Studente',

            style:
                TextStyle(
              color:
                  isTeacher
                      ? AppColors.teacherIndigo
                      : AppColors.studentBlue,

              fontSize:
                  9,

              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge
    extends StatelessWidget {
  final String label;

  final IconData icon;

  final Color color;

  const _StatusBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            7,

        vertical:
            5,
      ),

      decoration:
          BoxDecoration(
        color:
            color.withOpacity(
          0.10,
        ),

        borderRadius:
            BorderRadius.circular(
          8,
        ),
      ),

      child:
          Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          Icon(
            icon,

            color:
                color,

            size:
                12,
          ),

          const SizedBox(
            width:
                4,
          ),

          Text(
            label,

            style:
                TextStyle(
              color:
                  color,

              fontSize:
                  8,

              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AcademicStatusBadge
    extends StatelessWidget {
  final SocialAcademicPath path;

  const _AcademicStatusBadge({
    required this.path,
  });

  String get label {
    switch (path.status) {
      case AcademicPathStatus.enrolled:
        return 'Studente';

      case AcademicPathStatus.graduated:
        return 'Laureato';

      case AcademicPathStatus.suspended:
        return 'Percorso sospeso';

      case AcademicPathStatus.withdrawn:
        return 'Percorso interrotto';

      case AcademicPathStatus.transferred:
        return 'Trasferito';
    }
  }

  IconData get icon {
    switch (path.status) {
      case AcademicPathStatus.enrolled:
        return Icons.school_outlined;

      case AcademicPathStatus.graduated:
        return Icons
            .workspace_premium_outlined;

      case AcademicPathStatus.suspended:
        return Icons
            .pause_circle_outline_rounded;

      case AcademicPathStatus.withdrawn:
        return Icons
            .remove_circle_outline;

      case AcademicPathStatus.transferred:
        return Icons.swap_horiz_rounded;
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return _SmallBadge(
      label:
          label,

      icon:
          icon,
    );
  }
}

class _AcademicTitleVerificationBadge
    extends StatelessWidget {
  final SocialAcademicTitle title;

  const _AcademicTitleVerificationBadge({
    required this.title,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    switch (
      title.verificationStatus
    ) {
      case AcademicTitleVerificationStatus
            .verified:
        return const _StatusBadge(
          label:
              'Titolo verificato',

          icon:
              Icons.verified_rounded,

          color:
              Colors.greenAccent,
        );

      case AcademicTitleVerificationStatus
            .pending:
        return const _StatusBadge(
          label:
              'Verifica titolo in corso',

          icon:
              Icons.schedule_rounded,

          color:
              Colors.amber,
        );

      case AcademicTitleVerificationStatus
            .rejected:
        return const _StatusBadge(
          label:
              'Titolo non verificato',

          icon:
              Icons.cancel_outlined,

          color:
              Colors.redAccent,
        );

      case AcademicTitleVerificationStatus
            .notRequired:
        return const SizedBox
            .shrink();
    }
  }
}

class _DegreeVerificationBadge
    extends StatelessWidget {
  final SocialAcademicPath path;

  const _DegreeVerificationBadge({
    required this.path,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    switch (
      path.verificationStatus
    ) {
      case AcademicPathVerificationStatus
            .verified:
        return const _StatusBadge(
          label:
              'Laurea verificata',

          icon:
              Icons.verified_rounded,

          color:
              Colors.greenAccent,
        );

      case AcademicPathVerificationStatus
            .pending:
        return const _StatusBadge(
          label:
              'Verifica laurea in corso',

          icon:
              Icons.schedule_rounded,

          color:
              Colors.amber,
        );

      case AcademicPathVerificationStatus
            .rejected:
        return const _StatusBadge(
          label:
              'Laurea non verificata',

          icon:
              Icons.cancel_outlined,

          color:
              Colors.redAccent,
        );

      case AcademicPathVerificationStatus
            .notRequired:
        return const SizedBox
            .shrink();
    }
  }
}

class _GradeBadge
    extends StatelessWidget {
  final SocialSubject subject;

  const _GradeBadge({
    required this.subject,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final int? grade =
        subject.grade;

    if (grade == null) {
      return const SizedBox.shrink();
    }

    switch (
      subject
          .gradeVerificationStatus
    ) {
      case GradeVerificationStatus
            .verified:
        return _StatusBadge(
          label:
              '$grade/30',

          icon:
              Icons.verified_rounded,

          color:
              Colors.greenAccent,
        );

      case GradeVerificationStatus
            .pending:
        return _StatusBadge(
          label:
              '$grade/30',

          icon:
              Icons.schedule_rounded,

          color:
              Colors.amber,
        );

      case GradeVerificationStatus
            .rejected:
        return _StatusBadge(
          label:
              '$grade/30',

          icon:
              Icons.cancel_outlined,

          color:
              Colors.redAccent,
        );

      case GradeVerificationStatus.none:
        return _SmallBadge(
          label:
              '$grade/30',

          icon:
              Icons
                  .workspace_premium_outlined,
        );
    }
  }
}

class _ProfileMenuItem
    extends StatelessWidget {
  final IconData icon;

  final String label;

  final bool danger;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    this.danger = false,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final Color color =
        danger
            ? Colors.redAccent
            : AppColors.pureWhite;

    return Row(
      children: [
        Icon(
          icon,

          color:
              color,

          size:
              18,
        ),

        const SizedBox(
          width:
              9,
        ),

        Text(
          label,

          style:
              TextStyle(
            color:
                color,
          ),
        ),
      ],
    );
  }
}