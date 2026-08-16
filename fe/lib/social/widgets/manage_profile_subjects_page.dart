import 'package:flutter/material.dart';

import '../../theme/nightTheme.dart';

import '../../services/api_service.dart';
import '../../services/auth_session.dart';

import '../social_models.dart';


// =============================================================================
// MANAGE PROFILE SUBJECTS PAGE
// =============================================================================

class ManageProfileSubjectsPage
    extends StatefulWidget {

  final SocialUser user;


  const ManageProfileSubjectsPage({
    super.key,
    required this.user,
  });


  @override
  State<ManageProfileSubjectsPage>
      createState() =>
          _ManageProfileSubjectsPageState();
}


// =============================================================================
// STATE
// =============================================================================

class _ManageProfileSubjectsPageState
    extends State<ManageProfileSubjectsPage> {

  final ApiService _apiService =
      ApiService();


  final AuthSession _session =
      AuthSession.instance;


  // ===========================================================================
  // DATA
  // ===========================================================================

  late SocialUser _user;


  List<SocialSubject> _availableSubjects =
      [];


  // ===========================================================================
  // STATE
  // ===========================================================================

  bool _loading =
      true;


  bool _working =
      false;


  String? _error;


  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();


    _user =
        widget.user;


    _load();
  }


  // ===========================================================================
  // LOAD
  // ===========================================================================

  Future<void> _load() async {
    setState(() {
      _loading =
          true;

      _error =
          null;
    });


    try {
      // =======================================================================
      // MATERIE DISPONIBILI PER DIPARTIMENTO / CORSO
      // =======================================================================

      final List<SocialSubject> subjects =
          await _apiService
              .getSocialSubjects(
        _user.department,
        _user.course,
      );


      // =======================================================================
      // RICARICA PROFILO CORRENTE
      // =======================================================================

      final SocialUser user =
          await _apiService
              .getCurrentUser();


      if (!mounted) {
        return;
      }


      _session.updateUser(
        user,
      );


      setState(() {
        _user =
            user;

        _availableSubjects =
            subjects;

        _loading =
            false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }


      setState(() {
        _error =
            _cleanError(
          e,
        );

        _loading =
            false;
      });
    }
  }


  // ===========================================================================
  // ADD SUBJECT
  // ===========================================================================

  Future<void> _openAddSubject() async {
    if (_working) {
      return;
    }


    final List<SocialSubject>
        notAssociated =
        _availableSubjects
            .where(
              (
                subject,
              ) =>
                  !_user.subjects.any(
                (
                  current,
                ) =>
                    current.id ==
                    subject.id,
              ),
            )
            .toList();


    if (notAssociated.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content:
              Text(
            'Hai già aggiunto tutte le materie disponibili.',
          ),
        ),
      );

      return;
    }


    final _SubjectFormResult? result =
        await showModalBottomSheet<
            _SubjectFormResult>(
      context:
          context,

      isScrollControlled:
          true,

      backgroundColor:
          AppColors.eleganceDeepNavy,

      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top:
              Radius.circular(
            22,
          ),
        ),
      ),

      builder:
          (
        context,
      ) {
        return _AddSubjectSheet(
          subjects:
              notAssociated,
        );
      },
    );


    if (result ==
            null ||
        !mounted) {
      return;
    }


    await _addSubject(
      result,
    );
  }


  // ===========================================================================
  // ADD
  // ===========================================================================

  Future<void> _addSubject(
    _SubjectFormResult result,
  ) async {
    setState(() {
      _working =
          true;

      _error =
          null;
    });


    try {
      await _apiService
          .addUserSubject(
        userId:
            _user.id,

        subjectId:
            result.subject.id,

        grade:
            result.grade,

        note:
            result.note,

        canHelp:
            result.canHelp,
      );


      await _refreshUser();


      if (!mounted) {
        return;
      }


      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content:
              Text(
            '${result.subject.name} aggiunta al profilo.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }


      setState(() {
        _error =
            _cleanError(
          e,
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _working =
              false;
        });
      }
    }
  }


  // ===========================================================================
  // REMOVE
  // ===========================================================================

  Future<void> _removeSubject(
    SocialSubject subject,
  ) async {
    if (_working) {
      return;
    }


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
            'Rimuovi materia',

            style:
                TextStyle(
              color:
                  AppColors.pureWhite,
            ),
          ),

          content:
              Text(
            'Vuoi rimuovere "${subject.name}" dal tuo profilo?',

            style:
                TextStyle(
              color:
                  AppColors.pureWhite
                      .withOpacity(
                0.62,
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
                'Rimuovi',

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


    setState(() {
      _working =
          true;

      _error =
          null;
    });


    try {
      await _apiService
          .removeUserSubject(
        userId:
            _user.id,

        subjectId:
            subject.id,
      );


      await _refreshUser();


      if (!mounted) {
        return;
      }


      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content:
              Text(
            '${subject.name} rimossa.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }


      setState(() {
        _error =
            _cleanError(
          e,
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _working =
              false;
        });
      }
    }
  }


  // ===========================================================================
  // REFRESH USER
  // ===========================================================================

  Future<void> _refreshUser() async {
    final SocialUser user =
        await _apiService
            .getCurrentUser();


    _session.updateUser(
      user,
    );


    if (!mounted) {
      return;
    }


    setState(() {
      _user =
          user;
    });
  }


  // ===========================================================================
  // RETURN
  // ===========================================================================

  void _close() {
    Navigator.pop(
      context,
      _user,
    );
  }


  // ===========================================================================
  // CLEAN ERROR
  // ===========================================================================

  String _cleanError(
    Object error,
  ) {
    String value =
        error.toString();


    if (value.startsWith(
      'Exception: ',
    )) {
      value =
          value.substring(
        'Exception: '.length,
      );
    }


    return value;
  }


  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return PopScope(
      canPop:
          false,

      onPopInvokedWithResult:
          (
        didPop,
        result,
      ) {
        if (!didPop) {
          _close();
        }
      },

      child:
          Scaffold(
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

          leading:
              IconButton(
            tooltip:
                'Indietro',

            onPressed:
                _close,

            icon:
                const Icon(
              Icons.arrow_back_rounded,
            ),
          ),

          title:
              const Text(
            'Gestisci materie',
          ),

          actions: [
            IconButton(
              tooltip:
                  'Aggiorna',

              onPressed:
                  _working
                      ? null
                      : _load,

              icon:
                  const Icon(
                Icons.refresh_rounded,
              ),
            ),
          ],
        ),

        floatingActionButton:
            _loading
                ? null
                : FloatingActionButton.extended(
                    onPressed:
                        _working
                            ? null
                            : _openAddSubject,

                    backgroundColor:
                        AppColors.socialBlue,

                    foregroundColor:
                        AppColors.pureWhite,

                    icon:
                        const Icon(
                      Icons.add_rounded,
                    ),

                    label:
                        const Text(
                      'Aggiungi materia',
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
                  _buildBody(),
            ),
          ),
        ),
      ),
    );
  }


  // ===========================================================================
  // BODY
  // ===========================================================================

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }


    if (_error !=
        null &&
        _user.subjects.isEmpty) {
      return ListView(
        padding:
            const EdgeInsets.all(
          20,
        ),

        children: [
          _SubjectErrorCard(
            message:
                _error!,

            onRetry:
                _load,
          ),
        ],
      );
    }


    return RefreshIndicator(
      onRefresh:
          _load,

      child:
          ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        padding:
            const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          100,
        ),

        children: [
          // ===================================================================
          // HEADER
          // ===================================================================

          _buildHeader(),

          if (_error !=
              null) ...[
            const SizedBox(
              height:
                  14,
            ),

            _SubjectErrorCard(
              message:
                  _error!,

              onRetry:
                  _load,
            ),
          ],

          const SizedBox(
            height:
                24,
          ),


          // ===================================================================
          // SUBJECTS
          // ===================================================================

          Row(
            children: [
              const Icon(
                Icons.menu_book_outlined,

                color:
                    AppColors.skyBlue,

                size:
                    20,
              ),

              const SizedBox(
                width:
                    8,
              ),

              const Expanded(
                child:
                    Text(
                  'Le tue materie',

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
              ),

              Text(
                '${_user.subjects.length}',

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
            ],
          ),

          const SizedBox(
            height:
                14,
          ),


          if (_user.subjects.isEmpty)
            const _EmptySubjects()
          else
            ..._user.subjects.map(
              (
                SocialSubject subject,
              ) =>
                  Padding(
                padding:
                    const EdgeInsets.only(
                  bottom:
                      12,
                ),

                child:
                    _SubjectCard(
                  subject:
                      subject,

                  disabled:
                      _working,

                  onRemove:
                      () {
                    _removeSubject(
                      subject,
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }


  // ===========================================================================
  // HEADER
  // ===========================================================================

  Widget _buildHeader() {
    return Container(
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
          17,
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
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Container(
            width:
                45,

            height:
                45,

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
              Icons.school_outlined,

              color:
                  AppColors.skyBlue,

              size:
                  24,
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
                const Text(
                  'Materie del profilo',

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
                  'Aggiungi le materie che studi o insegni. '
                  'Puoi indicare il voto, inserire una nota '
                  'e specificare se puoi aiutare altri utenti.',

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
}


// =============================================================================
// SUBJECT CARD
// =============================================================================

class _SubjectCard
    extends StatelessWidget {

  final SocialSubject subject;

  final bool disabled;

  final VoidCallback onRemove;


  const _SubjectCard({
    required this.subject,
    required this.disabled,
    required this.onRemove,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
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
          Row(
            children: [
              Container(
                width:
                    38,

                height:
                    38,

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
                    const Icon(
                  Icons.menu_book_outlined,

                  color:
                      AppColors.skyBlue,

                  size:
                      19,
                ),
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
                      subject.name,

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

                    if (subject.department
                            .isNotEmpty ||
                        subject.course
                            .isNotEmpty) ...[
                      const SizedBox(
                        height:
                            3,
                      ),

                      Text(
                        '${subject.department} • ${subject.course}',

                        style:
                            const TextStyle(
                          color:
                              Colors.white38,

                          fontSize:
                              9,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              IconButton(
                tooltip:
                    'Rimuovi materia',

                onPressed:
                    disabled
                        ? null
                        : onRemove,

                icon:
                    const Icon(
                  Icons.delete_outline_rounded,

                  color:
                      Colors.redAccent,
                ),
              ),
            ],
          ),

          if (subject.grade !=
                  null ||
              subject.canHelp) ...[
            const SizedBox(
              height:
                  12,
            ),

            Wrap(
              spacing:
                  7,

              runSpacing:
                  7,

              children: [
                if (subject.grade !=
                    null)
                  _SubjectBadge(
                    icon:
                        Icons
                            .workspace_premium_outlined,

                    label:
                        '${subject.grade}/30',
                  ),

                if (subject.canHelp)
                  const _SubjectBadge(
                    icon:
                        Icons
                            .volunteer_activism_outlined,

                    label:
                        'Posso aiutare',
                  ),
              ],
            ),
          ],

          if (subject.note
              .isNotEmpty) ...[
            const SizedBox(
              height:
                  12,
            ),

            Text(
              subject.note,

              style:
                  const TextStyle(
                color:
                    Colors.white54,

                fontSize:
                    10,

                height:
                    1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}


// =============================================================================
// ADD SUBJECT SHEET
// =============================================================================

class _AddSubjectSheet
    extends StatefulWidget {

  final List<SocialSubject> subjects;


  const _AddSubjectSheet({
    required this.subjects,
  });


  @override
  State<_AddSubjectSheet>
      createState() =>
          _AddSubjectSheetState();
}


// =============================================================================
// ADD SUBJECT STATE
// =============================================================================

class _AddSubjectSheetState
    extends State<_AddSubjectSheet> {

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();


  final TextEditingController
      _gradeController =
      TextEditingController();


  final TextEditingController
      _noteController =
      TextEditingController();


  SocialSubject? _subject;


  bool _canHelp =
      false;


  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    _gradeController.dispose();

    _noteController.dispose();

    super.dispose();
  }


  // ===========================================================================
  // SUBMIT
  // ===========================================================================

  void _submit() {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }


    final SocialSubject? subject =
        _subject;


    if (subject ==
        null) {
      return;
    }


    final String gradeText =
        _gradeController.text
            .trim();


    Navigator.pop(
      context,

      _SubjectFormResult(
        subject:
            subject,

        grade:
            gradeText.isEmpty
                ? null
                : int.tryParse(
                    gradeText,
                  ),

        note:
            _noteController.text
                .trim(),

        canHelp:
            _canHelp,
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
    final double keyboard =
        MediaQuery.of(
      context,
    ).viewInsets.bottom;


    return Padding(
      padding:
          EdgeInsets.fromLTRB(
        20,
        18,
        20,
        keyboard +
            20,
      ),

      child:
          Form(
        key:
            _formKey,

        child:
            SingleChildScrollView(
          child:
              Column(
            mainAxisSize:
                MainAxisSize.min,

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              const Text(
                'Aggiungi materia',

                style:
                    TextStyle(
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
                    6,
              ),

              Text(
                'Seleziona una materia e aggiungi le informazioni '
                'che vuoi mostrare sul tuo profilo.',

                style:
                    TextStyle(
                  color:
                      AppColors.pureWhite
                          .withOpacity(
                    0.45,
                  ),

                  fontSize:
                      10,

                  height:
                      1.4,
                ),
              ),

              const SizedBox(
                height:
                    18,
              ),


              // ===============================================================
              // SUBJECT
              // ===============================================================

              DropdownButtonFormField<
                  SocialSubject>(
                value:
                    _subject,

                dropdownColor:
                    AppColors.eleganceDeepNavy,

                style:
                    const TextStyle(
                  color:
                      AppColors.pureWhite,
                ),

                decoration:
                    _sheetDecoration(
                  label:
                      'Materia',

                  icon:
                      Icons.menu_book_outlined,
                ),

                items:
                    widget.subjects
                        .map(
                          (
                            subject,
                          ) =>
                              DropdownMenuItem(
                            value:
                                subject,

                            child:
                                Text(
                              subject.name,
                            ),
                          ),
                        )
                        .toList(),

                validator:
                    (
                  value,
                ) {
                  if (value ==
                      null) {
                    return 'Seleziona una materia';
                  }

                  return null;
                },

                onChanged:
                    (
                  value,
                ) {
                  setState(() {
                    _subject =
                        value;
                  });
                },
              ),

              const SizedBox(
                height:
                    13,
              ),


              // ===============================================================
              // GRADE
              // ===============================================================

              TextFormField(
                controller:
                    _gradeController,

                keyboardType:
                    TextInputType.number,

                style:
                    const TextStyle(
                  color:
                      AppColors.pureWhite,
                ),

                decoration:
                    _sheetDecoration(
                  label:
                      'Voto (opzionale)',

                  icon:
                      Icons
                          .workspace_premium_outlined,

                  hint:
                      '18 - 30',
                ),

                validator:
                    (
                  value,
                ) {
                  if (value ==
                          null ||
                      value.trim()
                          .isEmpty) {
                    return null;
                  }


                  final int? grade =
                      int.tryParse(
                    value.trim(),
                  );


                  if (grade ==
                          null ||
                      grade <
                          18 ||
                      grade >
                          30) {
                    return 'Il voto deve essere tra 18 e 30';
                  }


                  return null;
                },
              ),

              const SizedBox(
                height:
                    13,
              ),


              // ===============================================================
              // NOTE
              // ===============================================================

              TextFormField(
                controller:
                    _noteController,

                minLines:
                    2,

                maxLines:
                    4,

                style:
                    const TextStyle(
                  color:
                      AppColors.pureWhite,
                ),

                decoration:
                    _sheetDecoration(
                  label:
                      'Nota (opzionale)',

                  icon:
                      Icons.notes_rounded,

                  hint:
                      'Esperienza, argomenti, disponibilità...',
                ),
              ),

              const SizedBox(
                height:
                    12,
              ),


              // ===============================================================
              // CAN HELP
              // ===============================================================

              SwitchListTile(
                contentPadding:
                    EdgeInsets.zero,

                value:
                    _canHelp,

                onChanged:
                    (
                  value,
                ) {
                  setState(() {
                    _canHelp =
                        value;
                  });
                },

                activeColor:
                    AppColors.skyBlue,

                title:
                    const Text(
                  'Posso aiutare',

                  style:
                      TextStyle(
                    color:
                        AppColors.pureWhite,

                    fontSize:
                        12,

                    fontWeight:
                        FontWeight.w500,
                  ),
                ),

                subtitle:
                    const Text(
                  'Mostra agli altri utenti che puoi offrire supporto su questa materia.',

                  style:
                      TextStyle(
                    color:
                        Colors.white38,

                    fontSize:
                        9,

                    height:
                        1.35,
                  ),
                ),
              ),

              const SizedBox(
                height:
                    18,
              ),


              // ===============================================================
              // ADD
              // ===============================================================

              SizedBox(
                width:
                    double.infinity,

                height:
                    50,

                child:
                    ElevatedButton.icon(
                  onPressed:
                      _submit,

                  icon:
                      const Icon(
                    Icons.add_rounded,
                  ),

                  label:
                      const Text(
                    'Aggiungi materia',
                  ),

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.socialBlue,

                    foregroundColor:
                        AppColors.pureWhite,

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
        ),
      ),
    );
  }


  InputDecoration _sheetDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText:
          label,

      hintText:
          hint,

      prefixIcon:
          Icon(
        icon,

        color:
            AppColors.skyBlue,
      ),

      labelStyle:
          const TextStyle(
        color:
            Colors.white54,
      ),

      hintStyle:
          const TextStyle(
        color:
            Colors.white24,
      ),

      filled:
          true,

      fillColor:
          AppColors.brandNightBlue,

      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          13,
        ),

        borderSide:
            BorderSide.none,
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          13,
        ),

        borderSide:
            BorderSide(
          color:
              AppColors.skyBlue
                  .withOpacity(
            0.08,
          ),
        ),
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          13,
        ),

        borderSide:
            BorderSide(
          color:
              AppColors.skyBlue
                  .withOpacity(
            0.45,
          ),
        ),
      ),
    );
  }
}


// =============================================================================
// RESULT
// =============================================================================

class _SubjectFormResult {
  final SocialSubject subject;

  final int? grade;

  final String note;

  final bool canHelp;


  const _SubjectFormResult({
    required this.subject,
    required this.grade,
    required this.note,
    required this.canHelp,
  });
}


// =============================================================================
// BADGE
// =============================================================================

class _SubjectBadge
    extends StatelessWidget {

  final IconData icon;

  final String label;


  const _SubjectBadge({
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
            7,

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


// =============================================================================
// EMPTY
// =============================================================================

class _EmptySubjects
    extends StatelessWidget {

  const _EmptySubjects();


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
          17,
        ),
      ),

      child:
          const Column(
        children: [
          Icon(
            Icons.menu_book_outlined,

            color:
                Colors.white30,

            size:
                36,
          ),

          SizedBox(
            height:
                10,
          ),

          Text(
            'Nessuna materia',

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

          SizedBox(
            height:
                5,
          ),

          Text(
            'Usa "Aggiungi materia" per completare il tuo profilo.',

            textAlign:
                TextAlign.center,

            style:
                TextStyle(
              color:
                  Colors.white38,

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
// ERROR
// =============================================================================

class _SubjectErrorCard
    extends StatelessWidget {

  final String message;

  final Future<void> Function()
      onRetry;


  const _SubjectErrorCard({
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
        15,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.redAccent
                .withOpacity(
          0.07,
        ),

        borderRadius:
            BorderRadius.circular(
          13,
        ),
      ),

      child:
          Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,

            color:
                Colors.redAccent,

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
              message,

              style:
                  const TextStyle(
                color:
                    Colors.white60,

                fontSize:
                    10,
              ),
            ),
          ),

          IconButton(
            tooltip:
                'Riprova',

            onPressed:
                () {
              onRetry();
            },

            icon:
                const Icon(
              Icons.refresh_rounded,

              color:
                  AppColors.skyBlue,
            ),
          ),
        ],
      ),
    );
  }
}