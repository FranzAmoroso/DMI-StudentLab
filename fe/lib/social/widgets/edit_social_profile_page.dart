import 'package:flutter/material.dart';

import '../../theme/nightTheme.dart';

import '../../services/api_service.dart';
import '../../services/auth_session.dart';

import '../social_models.dart';

import 'manage_profile_subjects_page.dart';


// =============================================================================
// EDIT SOCIAL PROFILE PAGE
// =============================================================================

class EditSocialProfilePage extends StatefulWidget {
  final SocialUser user;


  const EditSocialProfilePage({
    super.key,
    required this.user,
  });


  @override
  State<EditSocialProfilePage> createState() =>
      _EditSocialProfilePageState();
}


// =============================================================================
// STATE
// =============================================================================

class _EditSocialProfilePageState
    extends State<EditSocialProfilePage> {

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();


  final ApiService _apiService =
      ApiService();


  final AuthSession _session =
      AuthSession.instance;


  // ===========================================================================
  // USER STATE
  // ===========================================================================

  late SocialUser _user;


  // ===========================================================================
  // CONTROLLERS
  // ===========================================================================

  late final TextEditingController
      _firstNameController;


  late final TextEditingController
      _lastNameController;


  late final TextEditingController
      _emailController;


  late final TextEditingController
      _departmentController;


  late final TextEditingController
      _courseController;


  late final TextEditingController
      _descriptionController;


  // ===========================================================================
  // STATE
  // ===========================================================================

  late SocialUserType _type;


  late bool _available;


  late bool _willingToTeach;


  bool _saving =
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


    _firstNameController =
        TextEditingController(
      text:
          _user.firstName,
    );


    _lastNameController =
        TextEditingController(
      text:
          _user.lastName,
    );


    _emailController =
        TextEditingController(
      text:
          _user.email,
    );


    _departmentController =
        TextEditingController(
      text:
          _user.department,
    );


    _courseController =
        TextEditingController(
      text:
          _user.course,
    );


    _descriptionController =
        TextEditingController(
      text:
          _user.description,
    );


    _type =
        _user.type;


    _available =
        _user.available;


    _willingToTeach =
        _user.willingToTeach;
  }


  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    _firstNameController.dispose();

    _lastNameController.dispose();

    _emailController.dispose();

    _departmentController.dispose();

    _courseController.dispose();

    _descriptionController.dispose();

    super.dispose();
  }


  // ===========================================================================
  // SAVE
  // ===========================================================================

  Future<void> _save() async {
    if (_saving) {
      return;
    }


    if (!_formKey.currentState!
        .validate()) {
      return;
    }


    setState(() {
      _saving =
          true;

      _error =
          null;
    });


    try {
      final SocialUser updatedUser =
          await _apiService
              .updateSocialUser(
        userId:
            _user.id,

        firstName:
            _firstNameController.text
                .trim(),

        lastName:
            _lastNameController.text
                .trim(),

        email:
            _emailController.text
                .trim(),

        department:
            _departmentController.text
                .trim(),

        course:
            _courseController.text
                .trim(),

        description:
            _descriptionController.text
                .trim(),

        role:
            _type ==
                    SocialUserType.teacher
                ? 'teacher'
                : 'student',

        available:
            _available,

        willingToTeach:
            _willingToTeach,

        isActive:
            _user.isActive,
      );


      _session.updateUser(
        updatedUser,
      );


      _user =
          updatedUser;


      if (!mounted) {
        return;
      }


      Navigator.pop(
        context,
        updatedUser,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }


      setState(() {
        _error =
            _cleanErrorMessage(
          e,
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving =
              false;
        });
      }
    }
  }


  // ===========================================================================
  // MANAGE SUBJECTS
  // ===========================================================================

  Future<void> _manageSubjects() async {
    if (_saving) {
      return;
    }


    final SocialUser? updatedUser =
        await Navigator.of(
      context,
    ).push<SocialUser>(
      MaterialPageRoute(
        builder:
            (_) =>
                ManageProfileSubjectsPage(
          user:
              _user,
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
  // CLEAN ERROR
  // ===========================================================================

  String _cleanErrorMessage(
    Object error,
  ) {
    String message =
        error.toString();


    if (message.startsWith(
      'Exception: ',
    )) {
      message =
          message.substring(
        'Exception: '.length,
      );
    }


    return message;
  }


  // ===========================================================================
  // VALIDATION
  // ===========================================================================

  String? _requiredValidator(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Campo obbligatorio';
    }


    return null;
  }


  String? _emailValidator(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Inserisci la tua email';
    }


    final String email =
        value.trim();


    final RegExp expression =
        RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );


    if (!expression.hasMatch(
      email,
    )) {
      return 'Email non valida';
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
    final bool isTeacher =
        _type ==
            SocialUserType.teacher;


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
          'Modifica profilo',

          style:
              TextStyle(
            fontSize:
                18,

            fontWeight:
                FontWeight.w600,
          ),
        ),

        actions: [
          TextButton(
            onPressed:
                _saving
                    ? null
                    : _save,

            child:
                const Text(
              'Salva',

              style:
                  TextStyle(
                color:
                    AppColors.skyBlue,

                fontWeight:
                    FontWeight.w600,
              ),
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
                  700,
            ),

            child:
                Form(
              key:
                  _formKey,

              child:
                  ListView(
                padding:
                    const EdgeInsets.all(
                  20,
                ),

                children: [
                  // ===========================================================
                  // HEADER
                  // ===========================================================

                  _buildHeader(
                    isTeacher,
                  ),

                  const SizedBox(
                    height:
                        20,
                  ),


                  // ===========================================================
                  // PERSONAL DATA
                  // ===========================================================

                  _buildPersonalSection(),

                  const SizedBox(
                    height:
                        16,
                  ),


                  // ===========================================================
                  // ACADEMIC DATA
                  // ===========================================================

                  _buildAcademicSection(),

                  const SizedBox(
                    height:
                        16,
                  ),


                  // ===========================================================
                  // SUBJECTS
                  // ===========================================================

                  _buildSubjectsSection(),

                  const SizedBox(
                    height:
                        16,
                  ),


                  // ===========================================================
                  // TYPE
                  // ===========================================================

                  _buildTypeSection(),

                  const SizedBox(
                    height:
                        16,
                  ),


                  // ===========================================================
                  // AVAILABILITY
                  // ===========================================================

                  _buildAvailabilitySection(),

                  const SizedBox(
                    height:
                        16,
                  ),


                  // ===========================================================
                  // DESCRIPTION
                  // ===========================================================

                  _buildDescriptionSection(),


                  // ===========================================================
                  // ERROR
                  // ===========================================================

                  if (_error !=
                      null) ...[
                    const SizedBox(
                      height:
                          18,
                    ),

                    _buildError(),
                  ],

                  const SizedBox(
                    height:
                        24,
                  ),


                  // ===========================================================
                  // SAVE
                  // ===========================================================

                  SizedBox(
                    height:
                        52,

                    child:
                        ElevatedButton.icon(
                      onPressed:
                          _saving
                              ? null
                              : _save,

                      icon:
                          _saving
                              ? const SizedBox(
                                  width:
                                      18,

                                  height:
                                      18,

                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,

                                    color:
                                        AppColors.pureWhite,
                                  ),
                                )
                              : const Icon(
                                  Icons.save_outlined,
                                ),

                      label:
                          Text(
                        _saving
                            ? 'Salvataggio...'
                            : 'Salva modifiche',

                        style:
                            const TextStyle(
                          fontSize:
                              15,

                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            isTeacher
                                ? AppColors.teacherIndigo
                                : AppColors.socialBlue,

                        foregroundColor:
                            AppColors.pureWhite,

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            15,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height:
                        30,
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
  // HEADER
  // ===========================================================================

  Widget _buildHeader(
    bool isTeacher,
  ) {
    final String name =
        '${_firstNameController.text} '
                '${_lastNameController.text}'
            .trim();


    return Container(
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
          Row(
        children: [
          CircleAvatar(
            radius:
                26,

            backgroundColor:
                isTeacher
                    ? AppColors.teacherIndigo
                    : AppColors.studentBlue,

            child:
                Text(
              name.isNotEmpty
                  ? name[0]
                      .toUpperCase()
                  : '?',

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
                  name.isEmpty
                      ? 'Profilo StudentLab'
                      : name,

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
                  isTeacher
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
    );
  }


  // ===========================================================================
  // PERSONAL SECTION
  // ===========================================================================

  Widget _buildPersonalSection() {
    return _EditSection(
      title:
          'Informazioni personali',

      icon:
          Icons.person_outline_rounded,

      child:
          Column(
        children: [
          TextFormField(
            controller:
                _firstNameController,

            enabled:
                !_saving,

            validator:
                _requiredValidator,

            textInputAction:
                TextInputAction.next,

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
                _inputDecoration(
              label:
                  'Nome',

              icon:
                  Icons.badge_outlined,
            ),
          ),

          const SizedBox(
            height:
                12,
          ),

          TextFormField(
            controller:
                _lastNameController,

            enabled:
                !_saving,

            validator:
                _requiredValidator,

            textInputAction:
                TextInputAction.next,

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
                _inputDecoration(
              label:
                  'Cognome',

              icon:
                  Icons.badge_outlined,
            ),
          ),

          const SizedBox(
            height:
                12,
          ),

          TextFormField(
            controller:
                _emailController,

            enabled:
                !_saving,

            validator:
                _emailValidator,

            keyboardType:
                TextInputType.emailAddress,

            textInputAction:
                TextInputAction.next,

            style:
                const TextStyle(
              color:
                  AppColors.pureWhite,
            ),

            decoration:
                _inputDecoration(
              label:
                  'Email',

              icon:
                  Icons.email_outlined,
            ),
          ),
        ],
      ),
    );
  }


  // ===========================================================================
  // ACADEMIC SECTION
  // ===========================================================================

  Widget _buildAcademicSection() {
    return _EditSection(
      title:
          'Percorso accademico',

      icon:
          Icons.school_outlined,

      child:
          Column(
        children: [
          TextFormField(
            controller:
                _departmentController,

            enabled:
                !_saving,

            validator:
                _requiredValidator,

            textInputAction:
                TextInputAction.next,

            style:
                const TextStyle(
              color:
                  AppColors.pureWhite,
            ),

            decoration:
                _inputDecoration(
              label:
                  'Dipartimento',

              icon:
                  Icons
                      .account_balance_outlined,
            ),
          ),

          const SizedBox(
            height:
                12,
          ),

          TextFormField(
            controller:
                _courseController,

            enabled:
                !_saving,

            validator:
                _requiredValidator,

            style:
                const TextStyle(
              color:
                  AppColors.pureWhite,
            ),

            decoration:
                _inputDecoration(
              label:
                  'Corso',

              icon:
                  Icons.school_outlined,
            ),
          ),
        ],
      ),
    );
  }


  // ===========================================================================
  // SUBJECTS SECTION
  // ===========================================================================

  Widget _buildSubjectsSection() {
    return _EditSection(
      title:
          'Materie',

      icon:
          Icons.menu_book_outlined,

      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,

        children: [
          Text(
            _user.subjects.isEmpty
                ? 'Non hai ancora aggiunto materie al tuo profilo.'
                : '${_user.subjects.length} '
                    '${_user.subjects.length == 1 ? 'materia associata' : 'materie associate'} '
                    'al profilo.',

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

          if (_user.subjects
              .isNotEmpty) ...[
            const SizedBox(
              height:
                  13,
            ),

            Wrap(
              spacing:
                  7,

              runSpacing:
                  7,

              children:
                  _user.subjects
                      .map(
                        (
                          SocialSubject subject,
                        ) =>
                            _ProfileSubjectChip(
                          subject:
                              subject,
                        ),
                      )
                      .toList(),
            ),
          ],

          const SizedBox(
            height:
                15,
          ),

          OutlinedButton.icon(
            onPressed:
                _saving
                    ? null
                    : _manageSubjects,

            icon:
                const Icon(
              Icons.tune_rounded,
            ),

            label:
                const Text(
              'Gestisci materie',
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
        ],
      ),
    );
  }


  // ===========================================================================
  // TYPE SECTION
  // ===========================================================================

  Widget _buildTypeSection() {
    return _EditSection(
      title:
          'Tipo di profilo',

      icon:
          Icons.manage_accounts_outlined,

      child:
          Column(
        children: [
          _RoleOption(
            title:
                'Studente',

            description:
                'Profilo per studenti e colleghi di corso.',

            icon:
                Icons.school_rounded,

            selected:
                _type ==
                    SocialUserType.student,

            color:
                AppColors.studentBlue,

            onTap:
                _saving
                    ? null
                    : () {
                        setState(() {
                          _type =
                              SocialUserType.student;
                        });
                      },
          ),

          const SizedBox(
            height:
                9,
          ),

          _RoleOption(
            title:
                'Insegnante',

            description:
                'Profilo per docenti o persone che offrono supporto didattico.',

            icon:
                Icons
                    .cast_for_education_rounded,

            selected:
                _type ==
                    SocialUserType.teacher,

            color:
                AppColors.teacherIndigo,

            onTap:
                _saving
                    ? null
                    : () {
                        setState(() {
                          _type =
                              SocialUserType.teacher;
                        });
                      },
          ),
        ],
      ),
    );
  }


  // ===========================================================================
  // AVAILABILITY SECTION
  // ===========================================================================

  Widget _buildAvailabilitySection() {
    final bool isTeacher =
        _type ==
            SocialUserType.teacher;


    return _EditSection(
      title:
          'Disponibilità',

      icon:
          Icons.schedule_outlined,

      child:
          Column(
        children: [
          SwitchListTile(
            contentPadding:
                EdgeInsets.zero,

            value:
                _available,

            onChanged:
                _saving
                    ? null
                    : (
                        value,
                      ) {
                        setState(() {
                          _available =
                              value;
                        });
                      },

            activeColor:
                AppColors.skyBlue,

            title:
                const Text(
              'Disponibile',

              style:
                  TextStyle(
                color:
                    AppColors.pureWhite,

                fontSize:
                    13,

                fontWeight:
                    FontWeight.w500,
              ),
            ),

            subtitle:
                Text(
              'Indica agli altri utenti che sei disponibile '
              'a essere contattato.',

              style:
                  TextStyle(
                color:
                    AppColors.pureWhite
                        .withOpacity(
                  0.42,
                ),

                fontSize:
                    10,

                height:
                    1.35,
              ),
            ),
          ),

          Divider(
            color:
                AppColors.pureWhite
                    .withOpacity(
              0.06,
            ),
          ),

          SwitchListTile(
            contentPadding:
                EdgeInsets.zero,

            value:
                _willingToTeach,

            onChanged:
                _saving
                    ? null
                    : (
                        value,
                      ) {
                        setState(() {
                          _willingToTeach =
                              value;
                        });
                      },

            activeColor:
                AppColors.skyBlue,

            title:
                Text(
              isTeacher
                  ? 'Disponibile per lezioni'
                  : 'Disponibile ad aiutare',

              style:
                  const TextStyle(
                color:
                    AppColors.pureWhite,

                fontSize:
                    13,

                fontWeight:
                    FontWeight.w500,
              ),
            ),

            subtitle:
                Text(
              isTeacher
                  ? 'Indica che sei disponibile per lezioni o supporto didattico.'
                  : 'Indica che sei disponibile ad aiutare altri studenti.',

              style:
                  TextStyle(
                color:
                    AppColors.pureWhite
                        .withOpacity(
                  0.42,
                ),

                fontSize:
                    10,

                height:
                    1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ===========================================================================
  // DESCRIPTION
  // ===========================================================================

  Widget _buildDescriptionSection() {
    return _EditSection(
      title:
          'Descrizione',

      icon:
          Icons.notes_rounded,

      child:
          TextFormField(
        controller:
            _descriptionController,

        enabled:
            !_saving,

        minLines:
            4,

        maxLines:
            7,

        maxLength:
            1000,

        style:
            const TextStyle(
          color:
              AppColors.pureWhite,
        ),

        decoration:
            _inputDecoration(
          label:
              'Parla di te',

          icon:
              Icons.edit_note_rounded,

          hint:
              'Interessi, materie, obiettivi di studio...',
        ),
      ),
    );
  }


  // ===========================================================================
  // ERROR
  // ===========================================================================

  Widget _buildError() {
    return Container(
      padding:
          const EdgeInsets.all(
        14,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.redAccent
                .withOpacity(
          0.08,
        ),

        borderRadius:
            BorderRadius.circular(
          12,
        ),

        border:
            Border.all(
          color:
              Colors.redAccent
                  .withOpacity(
            0.20,
          ),
        ),
      ),

      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

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
                8,
          ),

          Expanded(
            child:
                Text(
              _error ??
                  'Errore durante il salvataggio.',

              style:
                  const TextStyle(
                color:
                    Colors.white70,

                fontSize:
                    10,

                height:
                    1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ===========================================================================
  // INPUT DECORATION
  // ===========================================================================

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText:
          label,

      hintText:
          hint,

      labelStyle:
          TextStyle(
        color:
            AppColors.pureWhite
                .withOpacity(
          0.55,
        ),
      ),

      hintStyle:
          TextStyle(
        color:
            AppColors.pureWhite
                .withOpacity(
          0.28,
        ),
      ),

      prefixIcon:
          Icon(
        icon,

        color:
            AppColors.skyBlue,
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
            0.50,
          ),
        ),
      ),

      errorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          13,
        ),

        borderSide:
            const BorderSide(
          color:
              Colors.redAccent,
        ),
      ),

      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          13,
        ),

        borderSide:
            const BorderSide(
          color:
              Colors.redAccent,
        ),
      ),
    );
  }
}


// =============================================================================
// EDIT SECTION
// =============================================================================

class _EditSection
    extends StatelessWidget {

  final String title;

  final IconData icon;

  final Widget child;


  const _EditSection({
    required this.title,
    required this.icon,
    required this.child,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
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
            ],
          ),

          const SizedBox(
            height:
                15,
          ),

          child,
        ],
      ),
    );
  }
}


// =============================================================================
// PROFILE SUBJECT CHIP
// =============================================================================

class _ProfileSubjectChip
    extends StatelessWidget {

  final SocialSubject subject;


  const _ProfileSubjectChip({
    required this.subject,
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
            0.08,
          ),
        ),
      ),

      child:
          Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          const Icon(
            Icons.menu_book_outlined,

            color:
                AppColors.materialSky,

            size:
                13,
          ),

          const SizedBox(
            width:
                5,
          ),

          Text(
            subject.name,

            style:
                const TextStyle(
              color:
                  AppColors.pureWhite,

              fontSize:
                  9,

              fontWeight:
                  FontWeight.w500,
            ),
          ),

          if (subject.grade !=
              null) ...[
            const SizedBox(
              width:
                  6,
            ),

            Text(
              '${subject.grade}/30',

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

          if (subject.canHelp) ...[
            const SizedBox(
              width:
                  5,
            ),

            const Icon(
              Icons
                  .volunteer_activism_outlined,

              color:
                  AppColors.materialSky,

              size:
                  11,
            ),
          ],
        ],
      ),
    );
  }
}


// =============================================================================
// ROLE OPTION
// =============================================================================

class _RoleOption
    extends StatelessWidget {

  final String title;

  final String description;

  final IconData icon;

  final bool selected;

  final Color color;

  final VoidCallback? onTap;


  const _RoleOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.color,
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
        13,
      ),

      child:
          AnimatedContainer(
        duration:
            const Duration(
          milliseconds:
              170,
        ),

        padding:
            const EdgeInsets.all(
          13,
        ),

        decoration:
            BoxDecoration(
          color:
              selected
                  ? color.withOpacity(
                      0.12,
                    )
                  : AppColors.brandNightBlue,

          borderRadius:
              BorderRadius.circular(
            13,
          ),

          border:
              Border.all(
            color:
                selected
                    ? color.withOpacity(
                        0.45,
                      )
                    : AppColors.skyBlue
                        .withOpacity(
                        0.06,
                      ),
          ),
        ),

        child:
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
                    color.withOpacity(
                  0.12,
                ),

                borderRadius:
                    BorderRadius.circular(
                  11,
                ),
              ),

              child:
                  Icon(
                icon,

                color:
                    color,

                size:
                    21,
              ),
            ),

            const SizedBox(
              width:
                  11,
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
                          12,

                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  const SizedBox(
                    height:
                        3,
                  ),

                  Text(
                    description,

                    style:
                        TextStyle(
                      color:
                          AppColors.pureWhite
                              .withOpacity(
                        0.40,
                      ),

                      fontSize:
                          9,

                      height:
                          1.35,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              width:
                  8,
            ),

            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,

              color:
                  selected
                      ? color
                      : Colors.white24,

              size:
                  20,
            ),
          ],
        ),
      ),
    );
  }
}