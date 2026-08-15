import 'package:flutter/material.dart';

import '../../theme/nightTheme.dart';

import '../../services/api_service.dart';

import '../social_models.dart';

import 'models/study_group.dart';

import 'study_group_detail_page.dart';

import 'create_group_page.dart';


// =============================================================================
// UTENTE TEMPORANEO
// =============================================================================
//
// In futuro arriverà da AuthService / sessione.
//

const int _currentUserId = 1;


// =============================================================================
// STUDENT GROUPS PAGE
// =============================================================================

class StudentGroupsPage
    extends StatefulWidget {

  const StudentGroupsPage({
    super.key,
  });


  @override
  State<StudentGroupsPage> createState() =>
      _StudentGroupsPageState();
}


// =============================================================================
// STATE
// =============================================================================

class _StudentGroupsPageState
    extends State<StudentGroupsPage> {

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
  // CARICAMENTO GRUPPI
  // ===========================================================================

  Future<void> _loadGroups() async {
    setState(() {
      _loading =
          true;

      _error =
          null;
    });


    try {
      List<Map<String, dynamic>>
          rawGroups;


      // =========================================================================
      // PRIMO TENTATIVO
      // =========================================================================
      //
      // Endpoint specifico dell'utente.
      //

      try {
        rawGroups =
            await _apiService
                .getUserGroups(
          _currentUserId,
        );
      } catch (_) {

        // =======================================================================
        // FALLBACK
        // =======================================================================
        //
        // Finché /user_groups/{user_id} non è completamente stabile,
        // recuperiamo tutti i gruppi e verifichiamo i membri tramite /group/{id}.
        //

        rawGroups =
            await _loadUserGroupsFallback();
      }


      final List<StudyGroup>
          groups =
          [];


      for (final rawGroup
          in rawGroups) {

        final StudyGroup? group =
            await _buildStudyGroup(
          rawGroup,
        );


        if (group != null) {
          groups.add(
            group,
          );
        }
      }


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
        _loading =
            false;

        _error =
            e.toString();
      });
    }
  }


  // ===========================================================================
  // FALLBACK GRUPPI UTENTE
  // ===========================================================================

  Future<List<Map<String, dynamic>>>
      _loadUserGroupsFallback() async {

    final List<Map<String, dynamic>>
        allGroups =
        await _apiService.getGroups();


    final List<Map<String, dynamic>>
        userGroups =
        [];


    for (final rawGroup
        in allGroups) {

      final int? groupId =
          _toInt(
        rawGroup['id'],
      );


      if (groupId == null) {
        continue;
      }


      try {
        final Map<String, dynamic>
            detail =
            await _apiService.getGroup(
          groupId,
        );


        final dynamic membersData =
            detail['members'];


        if (membersData is! List) {
          continue;
        }


        final bool isMember =
            membersData.any(
          (
            dynamic member,
          ) {
            if (member is! Map) {
              return false;
            }


            final Map<String, dynamic>
                memberData =
                Map<String, dynamic>.from(
              member,
            );


            return _toInt(
                  memberData['user_id'],
                ) ==
                _currentUserId;
          },
        );


        if (!isMember) {
          continue;
        }


        final Map<String, dynamic>
            merged =
            Map<String, dynamic>.from(
          rawGroup,
        );


        merged.addAll(
          detail,
        );


        userGroups.add(
          merged,
        );
      } catch (_) {
        // Se un singolo gruppo non può essere letto,
        // non blocchiamo l'intera pagina.
      }
    }


    return userGroups;
  }


  // ===========================================================================
  // CREA STUDY GROUP DAL BACKEND
  // ===========================================================================

  Future<StudyGroup?> _buildStudyGroup(
    Map<String, dynamic> rawGroup,
  ) async {

    final int? groupId =
        _toInt(
      rawGroup['id'],
    );


    if (groupId == null) {
      return null;
    }


    final Map<String, dynamic>
        merged =
        Map<String, dynamic>.from(
      rawGroup,
    );


    // =========================================================================
    // DETTAGLIO GRUPPO
    // =========================================================================

    try {
      final detail =
          await _apiService.getGroup(
        groupId,
      );


      merged.addAll(
        detail,
      );
    } catch (_) {
      // I dati base del gruppo rimangono comunque utilizzabili.
    }


    // =========================================================================
    // NUMERO MATERIALI
    // =========================================================================

    try {
      final materials =
          await _apiService
              .getGroupMaterials(
        groupId,
      );


      merged['material_count'] =
          materials.length;
    } catch (_) {
      merged['material_count'] =
          0;
    }


    // =========================================================================
    // NUMERO MEMBRI
    // =========================================================================

    final dynamic membersData =
        merged['members'];


    if (membersData is List) {
      merged['member_count'] =
          membersData.length;
    }


    // =========================================================================
    // NOME MATERIA
    // =========================================================================

    final int? subjectId =
        _toInt(
      merged['subject_id'],
    );


    final String department =
        merged['department']
                ?.toString() ??
            '';


    final String course =
        merged['course']
                ?.toString() ??
            '';


    if (subjectId != null &&
        department.isNotEmpty &&
        course.isNotEmpty) {

      final String? subjectName =
          await _loadSubjectName(
        subjectId:
            subjectId,

        department:
            department,

        course:
            course,
      );


      if (subjectName != null) {
        merged['subject_name'] =
            subjectName;
      }
    }


    return StudyGroup.fromJson(
      merged,

      currentUserId:
          _currentUserId,
    );
  }


  // ===========================================================================
  // NOME MATERIA
  // ===========================================================================

  Future<String?> _loadSubjectName({
    required int subjectId,

    required String department,

    required String course,
  }) async {
    try {
      final List<SocialSubject>
          subjects =
          await _apiService
              .getSocialSubjects(
        department,
        course,
      );


      for (final subject
          in subjects) {

        if (subject.id ==
            subjectId) {
          return subject.name;
        }
      }
    } catch (_) {
      // Se la materia non è disponibile,
      // mostreremo comunque il gruppo.
    }


    return null;
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
                'Crea gruppo',

            icon:
                const Icon(
              Icons.add_rounded,
            ),

            onPressed:
                _createGroup,
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
                          900
                      ? 900
                      : constraints
                          .maxWidth;


              return SizedBox(
                width:
                    width,

                child:
                    _buildBody(
                  constraints,
                ),
              );
            },
          ),
        ),
      ),
    );
  }


  // ===========================================================================
  // BODY
  // ===========================================================================

  Widget _buildBody(
    BoxConstraints constraints,
  ) {
    if (_loading) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }


    if (_error != null) {
      return RefreshIndicator(
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
            _buildMainActions(),

            const SizedBox(
              height:
                  28,
            ),

            _GroupsErrorCard(
              message:
                  _error!,

              onRetry:
                  _loadGroups,
            ),
          ],
        ),
      );
    }


    if (_groups.isEmpty) {
      return RefreshIndicator(
        onRefresh:
            _loadGroups,

        child:
            _buildEmptyGroups(),
      );
    }


    return RefreshIndicator(
      onRefresh:
          _loadGroups,

      child:
          _buildGroupsContent(
        constraints,
      ),
    );
  }


  // ===========================================================================
  // CONTENUTO
  // ===========================================================================

  Widget _buildGroupsContent(
    BoxConstraints constraints,
  ) {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),

      padding:
          const EdgeInsets.all(
        20,
      ),

      children: [
        _buildMainActions(),

        const SizedBox(
          height:
              28,
        ),

        Row(
          children: [
            const Expanded(
              child:
                  Text(
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
            ),

            Container(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal:
                    9,

                vertical:
                    5,
              ),

              decoration:
                  BoxDecoration(
                color:
                    AppColors
                        .brandNightBlue,

                borderRadius:
                    BorderRadius.circular(
                  8,
                ),
              ),

              child:
                  Text(
                '${_groups.length}',

                style:
                    const TextStyle(
                  color:
                      AppColors.materialSky,

                  fontSize:
                      11,

                  fontWeight:
                      FontWeight.w600,
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
          'Gruppi di studio a cui partecipi.',

          style:
              TextStyle(
            color:
                AppColors.pureWhite
                    .withOpacity(
              0.55,
            ),

            fontSize:
                13,
          ),
        ),

        const SizedBox(
          height:
              16,
        ),

        _buildGroupsGrid(
          constraints,
        ),
      ],
    );
  }


  // ===========================================================================
  // AZIONI
  // ===========================================================================

  Widget _buildMainActions() {
    return Column(
      children: [
        _GroupActionCard(
          icon:
              Icons
                  .add_circle_outline_rounded,

          title:
              'Crea un gruppo',

          description:
              'Crea un nuovo gruppo di studio e invita altri studenti o insegnanti.',

          onTap:
              _createGroup,
        ),

        const SizedBox(
          height:
              12,
        ),

        _GroupActionCard(
          icon:
              Icons
                  .person_add_alt_1_rounded,

          title:
              'Partecipa a un gruppo',

          description:
              'Cerca un gruppo esistente e invia una richiesta di partecipazione.',

          onTap:
              _joinGroup,
        ),
      ],
    );
  }


  // ===========================================================================
  // GRIGLIA
  // ===========================================================================

  Widget _buildGroupsGrid(
    BoxConstraints constraints,
  ) {
    final bool singleColumn =
        constraints.maxWidth <
            560;


    return GridView.builder(
      shrinkWrap:
          true,

      physics:
          const NeverScrollableScrollPhysics(),

      gridDelegate:
          SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:
            singleColumn
                ? 1
                : 2,

        crossAxisSpacing:
            14,

        mainAxisSpacing:
            14,

        mainAxisExtent:
            singleColumn
                ? 190
                : 220,
      ),

      itemCount:
          _groups.length,

      itemBuilder:
          (
        context,
        index,
      ) {

        final StudyGroup group =
            _groups[index];


        return _StudyGroupCard(
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
  }


  // ===========================================================================
  // APERTURA GRUPPO
  // ===========================================================================

  void _openGroup(
    StudyGroup group,
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
                StudyGroupDetailPage(
          group:
              group,
        ),
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


  // ===========================================================================
  // CREA GRUPPO
  // ===========================================================================

  void _createGroup() {
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


  // ===========================================================================
  // PARTECIPA A UN GRUPPO
  // ===========================================================================

  void _joinGroup() {
    /*
     * In futuro questa azione aprirà la ricerca di tutti
     * i gruppi disponibili e utilizzerà:
     *
     * requestJoinGroup()
     *
     * Gruppo pubblico -> ingresso diretto.
     * Gruppo privato  -> richiesta pending.
     */

    _showMessage(
      'Ricerca gruppi: da collegare alla lista dei gruppi disponibili.',
    );
  }


  // ===========================================================================
  // EMPTY
  // ===========================================================================

  Widget _buildEmptyGroups() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),

      padding:
          const EdgeInsets.all(
        20,
      ),

      children: [
        _buildMainActions(),

        const SizedBox(
          height:
              50,
        ),

        Container(
          width:
              double.infinity,

          padding:
              const EdgeInsets.all(
            30,
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
                0.12,
              ),
            ),
          ),

          child:
              Column(
            children: [
              Container(
                width:
                    72,

                height:
                    72,

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
                  Icons.groups_outlined,

                  color:
                      AppColors.skyBlue,

                  size:
                      38,
                ),
              ),

              const SizedBox(
                height:
                    18,
              ),

              const Text(
                'Nessun gruppo',

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
                    8,
              ),

              Text(
                'Non partecipi ancora a nessun gruppo di studio.',

                textAlign:
                    TextAlign.center,

                style:
                    TextStyle(
                  color:
                      AppColors.pureWhite
                          .withOpacity(
                    0.55,
                  ),

                  fontSize:
                      13,
                ),
              ),
            ],
          ),
        ),
      ],
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


  // ===========================================================================
  // UTILITY
  // ===========================================================================

  static int? _toInt(
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


// =============================================================================
// CARD AZIONE
// =============================================================================

class _GroupActionCard
    extends StatelessWidget {

  final IconData icon;

  final String title;

  final String description;

  final VoidCallback onTap;


  const _GroupActionCard({
    required this.icon,

    required this.title,

    required this.description,

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
          16,
        ),

        child:
            Container(
          width:
              double.infinity,

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
              16,
            ),

            border:
                Border.all(
              color:
                  AppColors.skyBlue
                      .withOpacity(
                0.15,
              ),
            ),
          ),

          child:
              Row(
            children: [
              Container(
                width:
                    48,

                height:
                    48,

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
                    Icon(
                  icon,

                  color:
                      AppColors.skyBlue,

                  size:
                      25,
                ),
              ),

              const SizedBox(
                width:
                    14,
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
                            15,

                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height:
                          5,
                    ),

                    Text(
                      description,

                      maxLines:
                          2,

                      overflow:
                          TextOverflow
                              .ellipsis,

                      style:
                          TextStyle(
                        color:
                            AppColors.pureWhite
                                .withOpacity(
                          0.55,
                        ),

                        fontSize:
                            12,

                        height:
                            1.3,
                      ),
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
                    24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// =============================================================================
// CARD GRUPPO
// =============================================================================

class _StudyGroupCard
    extends StatelessWidget {

  final StudyGroup group;

  final VoidCallback onTap;


  const _StudyGroupCard({
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
          18,
        ),

        child:
            Container(
          padding:
              const EdgeInsets.all(
            17,
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
                0.16,
              ),
            ),

            boxShadow: [
              BoxShadow(
                color:
                    Colors.black
                        .withOpacity(
                  0.14,
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
                        50,

                    height:
                        50,

                    decoration:
                        BoxDecoration(
                      color:
                          AppColors
                              .brandNightBlue,

                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),

                    child:
                        const Icon(
                      Icons.groups_rounded,

                      color:
                          AppColors.skyBlue,

                      size:
                          26,
                    ),
                  ),

                  const Spacer(),


                  if (group.isOwner)
                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal:
                            8,

                        vertical:
                            5,
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
                          const Text(
                        'OWNER',

                        style:
                            TextStyle(
                          color:
                              AppColors.materialSky,

                          fontSize:
                              9,

                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),


                  if (group.isOwner &&
                      group.isPrivate)
                    const SizedBox(
                      width:
                          8,
                    ),


                  if (group.isPrivate)
                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal:
                            8,

                        vertical:
                            5,
                      ),

                      decoration:
                          BoxDecoration(
                        color:
                            AppColors
                                .brandNightBlue,

                        borderRadius:
                            BorderRadius.circular(
                          8,
                        ),
                      ),

                      child:
                          const Row(
                        mainAxisSize:
                            MainAxisSize.min,

                        children: [
                          Icon(
                            Icons
                                .lock_outline,

                            color:
                                AppColors.skyBlue,

                            size:
                                13,
                          ),

                          SizedBox(
                            width:
                                4,
                          ),

                          Text(
                            'Privato',

                            style:
                                TextStyle(
                              color:
                                  AppColors.pureWhite,

                              fontSize:
                                  10,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(
                height:
                    13,
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
                      17,

                  fontWeight:
                      FontWeight.bold,

                  height:
                      1.2,
                ),
              ),

              const SizedBox(
                height:
                    5,
              ),


              if (group.subject
                  .isNotEmpty)
                Text(
                  group.subject,

                  maxLines:
                      1,

                  overflow:
                      TextOverflow
                          .ellipsis,

                  style:
                      const TextStyle(
                    color:
                        AppColors.materialSky,

                    fontSize:
                        11,

                    fontWeight:
                        FontWeight.w500,
                  ),
                ),


              if (group.subject
                  .isNotEmpty)
                const SizedBox(
                  height:
                      3,
                ),


              Text(
                group.course,

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
                    0.50,
                  ),

                  fontSize:
                      11,
                ),
              ),

              const SizedBox(
                height:
                    8,
              ),

              Expanded(
                child:
                    Text(
                  group.description
                          .isEmpty
                      ? 'Nessuna descrizione.'
                      : group.description,

                  maxLines:
                      2,

                  overflow:
                      TextOverflow
                          .ellipsis,

                  style:
                      TextStyle(
                    color:
                        AppColors.pureWhite
                            .withOpacity(
                      0.60,
                    ),

                    fontSize:
                        12,

                    height:
                        1.35,
                  ),
                ),
              ),

              const SizedBox(
                height:
                    10,
              ),

              Row(
                children: [
                  _GroupInfo(
                    icon:
                        Icons
                            .people_outline_rounded,

                    value:
                        '${group.memberCount}',

                    label:
                        'partecipanti',
                  ),

                  const SizedBox(
                    width:
                        14,
                  ),

                  _GroupInfo(
                    icon:
                        Icons.folder_outlined,

                    value:
                        '${group.materialCount}',

                    label:
                        'materiali',
                  ),

                  const Spacer(),

                  Icon(
                    Icons
                        .arrow_forward_ios_rounded,

                    color:
                        AppColors.pureWhite
                            .withOpacity(
                      0.30,
                    ),

                    size:
                        14,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// =============================================================================
// INFO GRUPPO
// =============================================================================

class _GroupInfo
    extends StatelessWidget {

  final IconData icon;

  final String value;

  final String label;


  const _GroupInfo({
    required this.icon,

    required this.value,

    required this.label,
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
          icon,

          color:
              AppColors.materialSky,

          size:
              15,
        ),

        const SizedBox(
          width:
              4,
        ),

        Text(
          value,

          style:
              const TextStyle(
            color:
                AppColors.pureWhite,

            fontSize:
                11,

            fontWeight:
                FontWeight.w600,
          ),
        ),

        const SizedBox(
          width:
              3,
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
    );
  }
}


// =============================================================================
// ERROR CARD
// =============================================================================

class _GroupsErrorCard
    extends StatelessWidget {

  final String message;

  final Future<void> Function()
      onRetry;


  const _GroupsErrorCard({
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
        24,
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
            Icons.error_outline_rounded,

            color:
                Colors.redAccent,

            size:
                40,
          ),

          const SizedBox(
            height:
                12,
          ),

          const Text(
            'Impossibile caricare i gruppi',

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
                  11,

              height:
                  1.4,
            ),
          ),

          const SizedBox(
            height:
                16,
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