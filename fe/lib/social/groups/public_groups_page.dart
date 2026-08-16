import 'package:flutter/material.dart';

import '../../theme/nightTheme.dart';

import '../../services/api_service.dart';

import 'models/study_group.dart';


// =============================================================================
// PUBLIC GROUPS PAGE
// =============================================================================

class PublicGroupsPage extends StatefulWidget {
  const PublicGroupsPage({
    super.key,
  });


  @override
  State<PublicGroupsPage> createState() =>
      _PublicGroupsPageState();
}


// =============================================================================
// STATE
// =============================================================================

class _PublicGroupsPageState
    extends State<PublicGroupsPage> {

  final ApiService _apiService =
      ApiService();


  final TextEditingController
      _searchController =
      TextEditingController();


  // ===========================================================================
  // DATI
  // ===========================================================================

  List<StudyGroup> _groups =
      [];


  // ===========================================================================
  // FILTRI
  // ===========================================================================

  String _searchQuery =
      '';


  String? _selectedSubject;


  String? _selectedDepartment;


  String? _selectedCourse;


  _GroupSort _sort =
      _GroupSort.name;


  // ===========================================================================
  // STATO
  // ===========================================================================

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
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }


  // ===========================================================================
  // LOAD GROUPS
  // ===========================================================================

  Future<void> _loadGroups() async {
    if (mounted) {
      setState(() {
        _loading =
            true;

        _error =
            null;
      });
    }


    try {
      final List<Map<String, dynamic>>
          data =
          await _apiService.getGroups();


      final List<StudyGroup> groups =
          data
              .map(
                (
                  json,
                ) =>
                    StudyGroup.fromJson(
                  json,
                ),
              )
              .where(
                (
                  group,
                ) =>
                    !group.isPrivate,
              )
              .toList();


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
  // GRUPPI FILTRATI
  // ===========================================================================

  List<StudyGroup> get _filteredGroups {
    Iterable<StudyGroup> result =
        _groups.where(
      (
        group,
      ) =>
          !group.isPrivate,
    );


    // =========================================================================
    // SEARCH
    // =========================================================================

    final String query =
        _searchQuery
            .trim()
            .toLowerCase();


    if (query.isNotEmpty) {
      result =
          result.where(
        (
          group,
        ) {
          final String name =
              group.name
                  .toLowerCase();


          final String description =
              group.description
                  .toLowerCase();


          final String subject =
              group.subject
                  .toLowerCase();


          final String department =
              group.department
                  .toLowerCase();


          final String course =
              group.course
                  .toLowerCase();


          return name.contains(
                query,
              ) ||
              description.contains(
                query,
              ) ||
              subject.contains(
                query,
              ) ||
              department.contains(
                query,
              ) ||
              course.contains(
                query,
              );
        },
      );
    }


    // =========================================================================
    // MATERIA
    // =========================================================================

    if (_selectedSubject !=
        null) {
      result =
          result.where(
        (
          group,
        ) =>
            group.subject ==
            _selectedSubject,
      );
    }


    // =========================================================================
    // DIPARTIMENTO
    // =========================================================================

    if (_selectedDepartment !=
        null) {
      result =
          result.where(
        (
          group,
        ) =>
            group.department ==
            _selectedDepartment,
      );
    }


    // =========================================================================
    // CORSO
    // =========================================================================

    if (_selectedCourse !=
        null) {
      result =
          result.where(
        (
          group,
        ) =>
            group.course ==
            _selectedCourse,
      );
    }


    final List<StudyGroup> groups =
        result.toList();


    // =========================================================================
    // ORDINAMENTO
    // =========================================================================

    switch (_sort) {
      case _GroupSort.name:
        groups.sort(
          (
            a,
            b,
          ) =>
              a.name
                  .toLowerCase()
                  .compareTo(
                    b.name
                        .toLowerCase(),
                  ),
        );

        break;


      case _GroupSort.members:
        groups.sort(
          (
            a,
            b,
          ) =>
              b.memberCount.compareTo(
            a.memberCount,
          ),
        );

        break;


      case _GroupSort.materials:
        groups.sort(
          (
            a,
            b,
          ) =>
              b.materialCount.compareTo(
            a.materialCount,
          ),
        );

        break;
    }


    return groups;
  }


  // ===========================================================================
  // MATERIE DISPONIBILI
  // ===========================================================================

  List<String> get _subjects {
    final List<String> values =
        _groups
            .map(
              (
                group,
              ) =>
                  group.subject,
            )
            .where(
              (
                value,
              ) =>
                  value.trim().isNotEmpty,
            )
            .toSet()
            .toList();


    values.sort();


    return values;
  }


  // ===========================================================================
  // DIPARTIMENTI
  // ===========================================================================

  List<String> get _departments {
    final List<String> values =
        _groups
            .map(
              (
                group,
              ) =>
                  group.department,
            )
            .where(
              (
                value,
              ) =>
                  value.trim().isNotEmpty,
            )
            .toSet()
            .toList();


    values.sort();


    return values;
  }


  // ===========================================================================
  // CORSI
  // ===========================================================================

  List<String> get _courses {
    final List<String> values =
        _groups
            .where(
              (
                group,
              ) =>
                  _selectedDepartment ==
                      null ||
                  group.department ==
                      _selectedDepartment,
            )
            .map(
              (
                group,
              ) =>
                  group.course,
            )
            .where(
              (
                value,
              ) =>
                  value.trim().isNotEmpty,
            )
            .toSet()
            .toList();


    values.sort();


    return values;
  }


  // ===========================================================================
  // RESET FILTRI
  // ===========================================================================

  void _resetFilters() {
    _searchController.clear();


    setState(() {
      _searchQuery =
          '';

      _selectedSubject =
          null;

      _selectedDepartment =
          null;

      _selectedCourse =
          null;

      _sort =
          _GroupSort.name;
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


      // =========================================================================
      // APP BAR
      // =========================================================================

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
          'Gruppi pubblici',

          style:
              TextStyle(
            fontSize:
                19,

            fontWeight:
                FontWeight.w600,
          ),
        ),

        actions: [
          IconButton(
            tooltip:
                'Aggiorna',

            onPressed:
                _loading
                    ? null
                    : _loadGroups,

            icon:
                const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),


      // =========================================================================
      // BODY
      // =========================================================================

      body:
          SafeArea(
        child:
            Center(
          child:
              ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth:
                  1050,
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
                  // ===========================================================
                  // HEADER
                  // ===========================================================

                  const Text(
                    'Trova il tuo gruppo',

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
                        6,
                  ),

                  Text(
                    'Esplora i gruppi pubblici di StudentLab. '
                    'Puoi cercare per nome, materia, dipartimento '
                    'o corso e scoprire dove vengono condivisi '
                    'materiali, appunti e sessioni di studio.',

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
                          1.45,
                    ),
                  ),

                  const SizedBox(
                    height:
                        20,
                  ),


                  // ===========================================================
                  // GUEST INFO
                  // ===========================================================

                  _buildGuestInfo(),

                  const SizedBox(
                    height:
                        18,
                  ),


                  // ===========================================================
                  // SEARCH
                  // ===========================================================

                  _buildSearchBar(),

                  const SizedBox(
                    height:
                        12,
                  ),


                  // ===========================================================
                  // FILTRI
                  // ===========================================================

                  _buildFilters(),

                  const SizedBox(
                    height:
                        16,
                  ),


                  // ===========================================================
                  // RISULTATI
                  // ===========================================================

                  _buildResultsHeader(),

                  const SizedBox(
                    height:
                        14,
                  ),


                  // ===========================================================
                  // CONTENT
                  // ===========================================================

                  _buildContent(),

                  const SizedBox(
                    height:
                        24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  // ===========================================================================
  // GUEST INFO
  // ===========================================================================

  Widget _buildGuestInfo() {
    return Container(
      padding:
          const EdgeInsets.all(
        14,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.skyBlue
                .withOpacity(
          0.06,
        ),

        borderRadius:
            BorderRadius.circular(
          14,
        ),

        border:
            Border.all(
          color:
              AppColors.skyBlue
                  .withOpacity(
            0.13,
          ),
        ),
      ),

      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Icon(
            Icons.visibility_outlined,

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
                Text(
              'Stai esplorando come Guest. '
              'Puoi vedere e cercare i gruppi pubblici. '
              'Per entrare in un gruppo, condividere materiale '
              'o partecipare alle attività dovrai accedere '
              'oppure creare un profilo StudentLab.',

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
                    1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ===========================================================================
  // SEARCH BAR
  // ===========================================================================

  Widget _buildSearchBar() {
    return TextField(
      controller:
          _searchController,

      onChanged:
          (
        String value,
      ) {
        setState(() {
          _searchQuery =
              value;
        });
      },

      style:
          const TextStyle(
        color:
            AppColors.pureWhite,
      ),

      decoration:
          InputDecoration(
        hintText:
            'Cerca per nome, materia, corso...',

        hintStyle:
            TextStyle(
          color:
              AppColors.pureWhite
                  .withOpacity(
            0.35,
          ),
        ),

        prefixIcon:
            const Icon(
          Icons.search_rounded,

          color:
              AppColors.skyBlue,
        ),

        suffixIcon:
            _searchQuery.isEmpty
                ? null
                : IconButton(
                    tooltip:
                        'Cancella ricerca',

                    onPressed:
                        () {
                      _searchController.clear();


                      setState(() {
                        _searchQuery =
                            '';
                      });
                    },

                    icon:
                        const Icon(
                      Icons.close_rounded,

                      color:
                          Colors.white54,
                    ),
                  ),

        filled:
            true,

        fillColor:
            AppColors.eleganceMidnight,

        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            15,
          ),

          borderSide:
              BorderSide.none,
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            15,
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
            15,
          ),

          borderSide:
              BorderSide(
            color:
                AppColors.skyBlue
                    .withOpacity(
              0.50,
            ),
          ),
        ),
      ),
    );
  }


  // ===========================================================================
  // FILTRI
  // ===========================================================================

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection:
          Axis.horizontal,

      child:
          Row(
        children: [
          // ===================================================================
          // MATERIA
          // ===================================================================

          _FilterButton(
            icon:
                Icons.menu_book_outlined,

            label:
                _selectedSubject ??
                    'Materia',

            active:
                _selectedSubject !=
                    null,

            onTap:
                () {
              _showStringFilter(
                title:
                    'Seleziona materia',

                values:
                    _subjects,

                selected:
                    _selectedSubject,

                onSelected:
                    (
                  value,
                ) {
                  setState(() {
                    _selectedSubject =
                        value;
                  });
                },
              );
            },
          ),

          const SizedBox(
            width:
                8,
          ),


          // ===================================================================
          // DIPARTIMENTO
          // ===================================================================

          _FilterButton(
            icon:
                Icons
                    .account_balance_outlined,

            label:
                _selectedDepartment ??
                    'Dipartimento',

            active:
                _selectedDepartment !=
                    null,

            onTap:
                () {
              _showStringFilter(
                title:
                    'Seleziona dipartimento',

                values:
                    _departments,

                selected:
                    _selectedDepartment,

                onSelected:
                    (
                  value,
                ) {
                  setState(() {
                    _selectedDepartment =
                        value;

                    _selectedCourse =
                        null;
                  });
                },
              );
            },
          ),

          const SizedBox(
            width:
                8,
          ),


          // ===================================================================
          // CORSO
          // ===================================================================

          _FilterButton(
            icon:
                Icons.school_outlined,

            label:
                _selectedCourse ??
                    'Corso',

            active:
                _selectedCourse !=
                    null,

            onTap:
                () {
              _showStringFilter(
                title:
                    'Seleziona corso',

                values:
                    _courses,

                selected:
                    _selectedCourse,

                onSelected:
                    (
                  value,
                ) {
                  setState(() {
                    _selectedCourse =
                        value;
                  });
                },
              );
            },
          ),

          const SizedBox(
            width:
                8,
          ),


          // ===================================================================
          // SORT
          // ===================================================================

          _FilterButton(
            icon:
                Icons.sort_rounded,

            label:
                _sortLabel,

            active:
                _sort !=
                    _GroupSort.name,

            onTap:
                _showSortFilter,
          ),


          // ===================================================================
          // RESET
          // ===================================================================

          if (_hasFilters ||
              _searchQuery
                  .isNotEmpty) ...[
            const SizedBox(
              width:
                  8,
            ),

            TextButton.icon(
              onPressed:
                  _resetFilters,

              icon:
                  const Icon(
                Icons
                    .filter_alt_off_outlined,

                size:
                    17,
              ),

              label:
                  const Text(
                'Reset',
              ),
            ),
          ],
        ],
      ),
    );
  }


  // ===========================================================================
  // RESULTS HEADER
  // ===========================================================================

  Widget _buildResultsHeader() {
    if (_loading ||
        _error !=
            null) {
      return const SizedBox.shrink();
    }


    final int count =
        _filteredGroups.length;


    return Row(
      children: [
        Expanded(
          child:
              Text(
            count ==
                    1
                ? '1 gruppo trovato'
                : '$count gruppi trovati',

            style:
                TextStyle(
              color:
                  AppColors.pureWhite
                      .withOpacity(
                0.55,
              ),

              fontSize:
                  11,

              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ),

        Text(
          '${_groups.length} pubblici',

          style:
              TextStyle(
            color:
                AppColors.materialSky
                    .withOpacity(
              0.75,
            ),

            fontSize:
                10,
          ),
        ),
      ],
    );
  }


  // ===========================================================================
  // CONTENT
  // ===========================================================================

  Widget _buildContent() {
    if (_loading) {
      return const Padding(
        padding:
            EdgeInsets.symmetric(
          vertical:
              60,
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
      return _PublicGroupsError(
        message:
            _error!,

        onRetry:
            _loadGroups,
      );
    }


    final List<StudyGroup> groups =
        _filteredGroups;


    if (groups.isEmpty) {
      return _EmptyPublicGroups(
        filtered:
            _hasFilters ||
                _searchQuery
                    .isNotEmpty,

        onReset:
            _resetFilters,
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
            500) {
          columns =
              1;
        } else if (constraints.maxWidth >=
            900) {
          columns =
              3;
        }


        return GridView.builder(
          shrinkWrap:
              true,

          physics:
              const NeverScrollableScrollPhysics(),

          itemCount:
              groups.length,

          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:
                columns,

            crossAxisSpacing:
                12,

            mainAxisSpacing:
                12,

            mainAxisExtent:
                205,
          ),

          itemBuilder:
              (
            context,
            index,
          ) {
            final StudyGroup group =
                groups[index];


            return _PublicGroupCard(
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


  // ===========================================================================
  // OPEN GROUP
  // ===========================================================================

  void _openGroup(
    StudyGroup group,
  ) {
    Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (_) =>
                PublicGroupDetailPage(
          group:
              group,
        ),
      ),
    );
  }


  // ===========================================================================
  // STRING FILTER
  // ===========================================================================

  Future<void> _showStringFilter({
    required String title,
    required List<String> values,
    required String? selected,
    required ValueChanged<String?> onSelected,
  }) async {
    final String? value =
        await showModalBottomSheet<String?>(
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
              ListView(
            shrinkWrap:
                true,

            padding:
                const EdgeInsets.symmetric(
              vertical:
                  10,
            ),

            children: [
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  18,
                  8,
                  18,
                  10,
                ),

                child:
                    Text(
                  title,

                  style:
                      const TextStyle(
                    color:
                        AppColors.pureWhite,

                    fontSize:
                        18,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              ListTile(
                leading:
                    const Icon(
                  Icons.clear_all_rounded,

                  color:
                      AppColors.skyBlue,
                ),

                title:
                    const Text(
                  'Tutti',

                  style:
                      TextStyle(
                    color:
                        AppColors.pureWhite,
                  ),
                ),

                trailing:
                    selected ==
                            null
                        ? const Icon(
                            Icons.check_rounded,

                            color:
                                AppColors.skyBlue,
                          )
                        : null,

                onTap:
                    () {
                  Navigator.pop(
                    sheetContext,
                    '',
                  );
                },
              ),

              ...values.map(
                (
                  String value,
                ) {
                  return ListTile(
                    title:
                        Text(
                      value,

                      style:
                          const TextStyle(
                        color:
                            AppColors.pureWhite,
                      ),
                    ),

                    trailing:
                        selected ==
                                value
                            ? const Icon(
                                Icons.check_rounded,

                                color:
                                    AppColors.skyBlue,
                              )
                            : null,

                    onTap:
                        () {
                      Navigator.pop(
                        sheetContext,
                        value,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );


    if (!mounted ||
        value ==
            null) {
      return;
    }


    if (value.isEmpty) {
      onSelected(
        null,
      );
    } else {
      onSelected(
        value,
      );
    }
  }


  // ===========================================================================
  // SORT FILTER
  // ===========================================================================

  Future<void> _showSortFilter() async {
    final _GroupSort? selected =
        await showModalBottomSheet<
            _GroupSort>(
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

              _SortOption(
                title:
                    'Nome A-Z',

                icon:
                    Icons.sort_by_alpha_rounded,

                selected:
                    _sort ==
                        _GroupSort.name,

                onTap:
                    () {
                  Navigator.pop(
                    sheetContext,
                    _GroupSort.name,
                  );
                },
              ),

              _SortOption(
                title:
                    'Più membri',

                icon:
                    Icons.groups_rounded,

                selected:
                    _sort ==
                        _GroupSort.members,

                onTap:
                    () {
                  Navigator.pop(
                    sheetContext,
                    _GroupSort.members,
                  );
                },
              ),

              _SortOption(
                title:
                    'Più materiale',

                icon:
                    Icons.folder_copy_outlined,

                selected:
                    _sort ==
                        _GroupSort.materials,

                onTap:
                    () {
                  Navigator.pop(
                    sheetContext,
                    _GroupSort.materials,
                  );
                },
              ),

              const SizedBox(
                height:
                    8,
              ),
            ],
          ),
        );
      },
    );


    if (selected ==
            null ||
        !mounted) {
      return;
    }


    setState(() {
      _sort =
          selected;
    });
  }


  // ===========================================================================
  // HELPERS FILTRI
  // ===========================================================================

  bool get _hasFilters {
    return _selectedSubject !=
            null ||
        _selectedDepartment !=
            null ||
        _selectedCourse !=
            null ||
        _sort !=
            _GroupSort.name;
  }


  String get _sortLabel {
    switch (_sort) {
      case _GroupSort.name:
        return 'Ordina';

      case _GroupSort.members:
        return 'Più membri';

      case _GroupSort.materials:
        return 'Più materiale';
    }
  }
}


// =============================================================================
// SORT
// =============================================================================

enum _GroupSort {
  name,
  members,
  materials,
}


// =============================================================================
// FILTER BUTTON
// =============================================================================

class _FilterButton
    extends StatelessWidget {

  final IconData icon;

  final String label;

  final bool active;

  final VoidCallback onTap;


  const _FilterButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return InkWell(
      onTap:
          onTap,

      borderRadius:
          BorderRadius.circular(
        10,
      ),

      child:
          Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal:
              11,

          vertical:
              9,
        ),

        decoration:
            BoxDecoration(
          color:
              active
                  ? AppColors.skyBlue
                      .withOpacity(
                      0.14,
                    )
                  : AppColors
                      .eleganceMidnight,

          borderRadius:
              BorderRadius.circular(
            10,
          ),

          border:
              Border.all(
            color:
                active
                    ? AppColors.skyBlue
                        .withOpacity(
                        0.32,
                      )
                    : AppColors.skyBlue
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
                  16,

              color:
                  active
                      ? AppColors.skyBlue
                      : Colors.white54,
            ),

            const SizedBox(
              width:
                  6,
            ),

            Text(
              label,

              style:
                  TextStyle(
                color:
                    active
                        ? AppColors.pureWhite
                        : AppColors.pureWhite
                            .withOpacity(
                            0.60,
                          ),

                fontSize:
                    10,

                fontWeight:
                    active
                        ? FontWeight.w600
                        : FontWeight.normal,
              ),
            ),

            const SizedBox(
              width:
                  3,
            ),

            const Icon(
              Icons.arrow_drop_down_rounded,

              size:
                  17,

              color:
                  Colors.white38,
            ),
          ],
        ),
      ),
    );
  }
}


// =============================================================================
// PUBLIC GROUP CARD
// =============================================================================

class _PublicGroupCard
    extends StatelessWidget {

  final StudyGroup group;

  final VoidCallback onTap;


  const _PublicGroupCard({
    required this.group,
    required this.onTap,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return InkWell(
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
          15,
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
              children: [
                Container(
                  width:
                      40,

                  height:
                      40,

                  decoration:
                      BoxDecoration(
                    color:
                        AppColors
                            .brandNightBlue,

                    borderRadius:
                        BorderRadius.circular(
                      11,
                    ),
                  ),

                  child:
                      const Icon(
                    Icons.groups_2_outlined,

                    color:
                        AppColors.skyBlue,

                    size:
                        21,
                  ),
                ),

                const SizedBox(
                  width:
                      10,
                ),

                Expanded(
                  child:
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
                          14,

                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height:
                  11,
            ),

            Text(
              group.description.isEmpty
                  ? 'Nessuna descrizione.'
                  : group.description,

              maxLines:
                  2,

              overflow:
                  TextOverflow.ellipsis,

              style:
                  TextStyle(
                color:
                    AppColors.pureWhite
                        .withOpacity(
                  0.48,
                ),

                fontSize:
                    10,

                height:
                    1.35,
              ),
            ),

            const Spacer(),

            _GroupInfoRow(
              icon:
                  Icons.menu_book_outlined,

              text:
                  group.subject.isEmpty
                      ? 'Materia non specificata'
                      : group.subject,
            ),

            const SizedBox(
              height:
                  6,
            ),

            _GroupInfoRow(
              icon:
                  Icons.school_outlined,

              text:
                  '${group.department} • ${group.course}',
            ),

            const SizedBox(
              height:
                  10,
            ),

            Row(
              children: [
                _GroupCounter(
                  icon:
                      Icons.people_outline_rounded,

                  value:
                      '${group.memberCount}',
                ),

                const SizedBox(
                  width:
                      12,
                ),

                _GroupCounter(
                  icon:
                      Icons.folder_outlined,

                  value:
                      '${group.materialCount}',
                ),

                const Spacer(),

                const Icon(
                  Icons.arrow_forward_rounded,

                  color:
                      AppColors.skyBlue,

                  size:
                      17,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


// =============================================================================
// PUBLIC GROUP DETAIL PAGE
// =============================================================================

class PublicGroupDetailPage
    extends StatelessWidget {

  final StudyGroup group;


  const PublicGroupDetailPage({
    super.key,
    required this.group,
  });


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
            Text(
          group.name,

          maxLines:
              1,

          overflow:
              TextOverflow.ellipsis,
        ),
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
                  750,
            ),

            child:
                ListView(
              padding:
                  const EdgeInsets.all(
                20,
              ),

              children: [
                // =============================================================
                // MAIN CARD
                // =============================================================

                Container(
                  padding:
                      const EdgeInsets.all(
                    18,
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
                      const Row(
                        children: [
                          Icon(
                            Icons.public_rounded,

                            color:
                                AppColors.skyBlue,
                          ),

                          SizedBox(
                            width:
                                8,
                          ),

                          Text(
                            'Gruppo pubblico',

                            style:
                                TextStyle(
                              color:
                                  AppColors.materialSky,

                              fontSize:
                                  11,

                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height:
                            16,
                      ),

                      Text(
                        group.name,

                        style:
                            const TextStyle(
                          color:
                              AppColors.pureWhite,

                          fontSize:
                              22,

                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height:
                            8,
                      ),

                      Text(
                        group.description.isEmpty
                            ? 'Nessuna descrizione disponibile.'
                            : group.description,

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
                              1.45,
                        ),
                      ),

                      const SizedBox(
                        height:
                            18,
                      ),

                      _GroupInfoRow(
                        icon:
                            Icons.menu_book_outlined,

                        text:
                            group.subject.isEmpty
                                ? 'Materia non specificata'
                                : group.subject,
                      ),

                      const SizedBox(
                        height:
                            8,
                      ),

                      _GroupInfoRow(
                        icon:
                            Icons
                                .account_balance_outlined,

                        text:
                            group.department,
                      ),

                      const SizedBox(
                        height:
                            8,
                      ),

                      _GroupInfoRow(
                        icon:
                            Icons.school_outlined,

                        text:
                            group.course,
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height:
                      16,
                ),


                // =============================================================
                // STATS
                // =============================================================

                Container(
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
                          AppColors.skyBlue
                              .withOpacity(
                        0.10,
                      ),
                    ),
                  ),

                  child:
                      Row(
                    children: [
                      Expanded(
                        child:
                            _DetailStatistic(
                          value:
                              '${group.memberCount}',

                          label:
                              'Partecipanti',

                          icon:
                              Icons
                                  .people_outline_rounded,
                        ),
                      ),

                      Container(
                        width:
                            1,

                        height:
                            52,

                        color:
                            AppColors.pureWhite
                                .withOpacity(
                          0.07,
                        ),
                      ),

                      Expanded(
                        child:
                            _DetailStatistic(
                          value:
                              '${group.materialCount}',

                          label:
                              'Materiali',

                          icon:
                              Icons.folder_outlined,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height:
                      16,
                ),


                // =============================================================
                // INFO MATERIALI
                // =============================================================

                Container(
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
                      const Row(
                        children: [
                          Icon(
                            Icons
                                .folder_copy_outlined,

                            color:
                                AppColors.skyBlue,

                            size:
                                20,
                          ),

                          SizedBox(
                            width:
                                8,
                          ),

                          Text(
                            'Materiale condiviso',

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
                        ],
                      ),

                      const SizedBox(
                        height:
                            9,
                      ),

                      Text(
                        'Questo gruppo contiene ${group.materialCount} '
                        'materiali condivisi tra i partecipanti. '
                        'Possono includere PDF, slide, appunti, '
                        'documenti e materiale relativo alle lezioni.',

                        style:
                            TextStyle(
                          color:
                              AppColors.pureWhite
                                  .withOpacity(
                            0.48,
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

                const SizedBox(
                  height:
                      16,
                ),


                // =============================================================
                // GUEST LIMIT
                // =============================================================

                Container(
                  padding:
                      const EdgeInsets.all(
                    15,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        AppColors.skyBlue
                            .withOpacity(
                      0.07,
                    ),

                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),

                    border:
                        Border.all(
                      color:
                          AppColors.skyBlue
                              .withOpacity(
                        0.14,
                      ),
                    ),
                  ),

                  child:
                      Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      const Icon(
                        Icons
                            .info_outline_rounded,

                        color:
                            AppColors.materialSky,

                        size:
                            19,
                      ),

                      const SizedBox(
                        width:
                            9,
                      ),

                      Expanded(
                        child:
                            Text(
                          'Come Guest puoi esplorare le informazioni '
                          'del gruppo pubblico. Per partecipare al gruppo, '
                          'scaricare o condividere materiale e utilizzare '
                          'le funzionalità riservate ai membri è necessario '
                          'accedere o creare un profilo StudentLab.',

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
                                1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// =============================================================================
// GROUP INFO ROW
// =============================================================================

class _GroupInfoRow
    extends StatelessWidget {

  final IconData icon;

  final String text;


  const _GroupInfoRow({
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

          size:
              14,

          color:
              AppColors.materialSky,
        ),

        const SizedBox(
          width:
              6,
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
                TextStyle(
              color:
                  AppColors.pureWhite
                      .withOpacity(
                0.55,
              ),

              fontSize:
                  10,
            ),
          ),
        ),
      ],
    );
  }
}


// =============================================================================
// COUNTER
// =============================================================================

class _GroupCounter
    extends StatelessWidget {

  final IconData icon;

  final String value;


  const _GroupCounter({
    required this.icon,
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
              Colors.white38,

          size:
              14,
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
                Colors.white54,

            fontSize:
                9,
          ),
        ),
      ],
    );
  }
}


// =============================================================================
// DETAIL STATISTIC
// =============================================================================

class _DetailStatistic
    extends StatelessWidget {

  final String value;

  final String label;

  final IconData icon;


  const _DetailStatistic({
    required this.value,
    required this.label,
    required this.icon,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: [
        Icon(
          icon,

          color:
              AppColors.skyBlue,

          size:
              22,
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

        const SizedBox(
          height:
              2,
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
    );
  }
}


// =============================================================================
// SORT OPTION
// =============================================================================

class _SortOption
    extends StatelessWidget {

  final String title;

  final IconData icon;

  final bool selected;

  final VoidCallback onTap;


  const _SortOption({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return ListTile(
      onTap:
          onTap,

      leading:
          Icon(
        icon,

        color:
            AppColors.skyBlue,
      ),

      title:
          Text(
        title,

        style:
            const TextStyle(
          color:
              AppColors.pureWhite,
        ),
      ),

      trailing:
          selected
              ? const Icon(
                  Icons.check_rounded,

                  color:
                      AppColors.skyBlue,
                )
              : null,
    );
  }
}


// =============================================================================
// ERROR
// =============================================================================

class _PublicGroupsError
    extends StatelessWidget {

  final String message;

  final VoidCallback onRetry;


  const _PublicGroupsError({
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
        18,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.eleganceMidnight,

        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),

      child:
          Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,

            color:
                Colors.redAccent,

            size:
                34,
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
                12,
          ),

          OutlinedButton.icon(
            onPressed:
                onRetry,

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
// EMPTY
// =============================================================================

class _EmptyPublicGroups
    extends StatelessWidget {

  final bool filtered;

  final VoidCallback onReset;


  const _EmptyPublicGroups({
    required this.filtered,
    required this.onReset,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
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
      ),

      child:
          Column(
        children: [
          const Icon(
            Icons.groups_outlined,

            color:
                AppColors.skyBlue,

            size:
                38,
          ),

          const SizedBox(
            height:
                12,
          ),

          Text(
            filtered
                ? 'Nessun gruppo corrisponde alla ricerca.'
                : 'Non ci sono ancora gruppi pubblici.',

            textAlign:
                TextAlign.center,

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

          if (filtered) ...[
            const SizedBox(
              height:
                  12,
            ),

            TextButton.icon(
              onPressed:
                  onReset,

              icon:
                  const Icon(
                Icons
                    .filter_alt_off_outlined,
              ),

              label:
                  const Text(
                'Rimuovi filtri',
              ),
            ),
          ],
        ],
      ),
    );
  }
}