import 'package:flutter/material.dart';

import '../../theme/nightTheme.dart';
import '../../services/api_service.dart';

import '../social_models.dart';

import 'social_profile_preview.dart';


class StudentSocialForm extends StatefulWidget {
  const StudentSocialForm({
    super.key,
  });

  @override
  State<StudentSocialForm> createState() =>
      _StudentSocialFormState();
}


class _StudentSocialFormState
    extends State<StudentSocialForm> {

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final ApiService _apiService =
      ApiService();


  // ===========================================================================
  // DATI UTENTE
  // ===========================================================================

  final TextEditingController
      _firstNameController =
      TextEditingController();

  final TextEditingController
      _lastNameController =
      TextEditingController();

  final TextEditingController
      _emailController =
      TextEditingController();

  final TextEditingController
      _passwordController =
      TextEditingController();

  final TextEditingController
      _confirmPasswordController =
      TextEditingController();

  final TextEditingController
      _departmentController =
      TextEditingController(
    text: 'DMI',
  );

  final TextEditingController
      _courseController =
      TextEditingController(
    text: 'Informatica',
  );

  final TextEditingController
      _descriptionController =
      TextEditingController();


  // ===========================================================================
  // STATO
  // ===========================================================================

  bool _available =
      true;

  bool _willingToTeach =
      false;

  bool _loadingSubjects =
      false;

  bool _passwordVisible =
      false;

  bool _confirmPasswordVisible =
      false;

  String? _subjectsError;


  // ===========================================================================
  // MATERIE DISPONIBILI DAL BACKEND
  // ===========================================================================

  List<SocialSubject> _availableSubjects =
      [];


  // ===========================================================================
  // MATERIE SELEZIONATE
  // ===========================================================================

  final List<_StudentSubjectData> _subjects = [
    _StudentSubjectData(),
  ];


  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    _loadSubjects();
  }


  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();

    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _departmentController.dispose();
    _courseController.dispose();
    _descriptionController.dispose();

    for (final _StudentSubjectData subject
        in _subjects) {
      subject.dispose();
    }

    super.dispose();
  }


  // ===========================================================================
  // CARICA MATERIE
  // ===========================================================================

  Future<void> _loadSubjects() async {
    final String department =
        _departmentController.text.trim();

    final String course =
        _courseController.text.trim();

    if (department.isEmpty ||
        course.isEmpty) {
      return;
    }

    setState(() {
      _loadingSubjects =
          true;

      _subjectsError =
          null;
    });

    try {
      final List<SocialSubject> loadedSubjects =
          await _apiService.getSocialSubjects(
        department,
        course,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _availableSubjects =
            loadedSubjects;

        _loadingSubjects =
            false;

        for (final _StudentSubjectData item
            in _subjects) {
          item.selectedSubject =
              null;
        }
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingSubjects =
            false;

        _subjectsError =
            e.toString();
      });
    }
  }


  // ===========================================================================
  // AGGIUNGI MATERIA
  // ===========================================================================

  void _addSubject() {
    setState(() {
      _subjects.add(
        _StudentSubjectData(),
      );
    });
  }


  // ===========================================================================
  // RIMUOVI MATERIA
  // ===========================================================================

  void _removeSubject(
    int index,
  ) {
    if (_subjects.length ==
        1) {
      return;
    }

    setState(() {
      _subjects[index]
          .dispose();

      _subjects.removeAt(
        index,
      );
    });
  }


  // ===========================================================================
  // CONTINUA
  // ===========================================================================

  Future<void> _continue() async {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }


    final List<SocialSubject> subjects =
        [];

    final Set<int> usedSubjectIds =
        {};


    for (final _StudentSubjectData item
        in _subjects) {
      final SocialSubject? selected =
          item.selectedSubject;


      if (selected == null) {
        _showMessage(
          'Seleziona tutte le materie.',
        );

        return;
      }


      if (usedSubjectIds.contains(
        selected.id,
      )) {
        _showMessage(
          'Hai selezionato la stessa materia più di una volta.',
        );

        return;
      }


      usedSubjectIds.add(
        selected.id,
      );


      final String gradeText =
          item.gradeController.text
              .trim();


      final int? grade =
          gradeText.isEmpty
              ? null
              : int.tryParse(
                  gradeText,
                );


      subjects.add(
        SocialSubject(
          id:
              selected.id,

          name:
              selected.name,

          department:
              selected.department,

          course:
              selected.course,

          grade:
              grade,

          note:
              item.noteController.text
                  .trim(),

          canHelp:
              item.canHelp,
        ),
      );
    }


    final SocialProfileDraft draft =
        SocialProfileDraft(
      firstName:
          _firstNameController.text
              .trim(),

      lastName:
          _lastNameController.text
              .trim(),

      email:
          _emailController.text
              .trim(),

      password:
          _passwordController.text,

      department:
          _departmentController.text
              .trim(),

      course:
          _courseController.text
              .trim(),

      subjects:
          subjects,

      description:
          _descriptionController.text
              .trim(),

      type:
          SocialUserType.student,

      available:
          _available,

      willingToTeach:
          _willingToTeach,
    );


    final SocialUser? user =
        await Navigator.push<SocialUser>(
      context,

      MaterialPageRoute(
        builder: (_) =>
            SocialProfilePreview(
          draft:
              draft,
        ),
      ),
    );


    if (user != null &&
        mounted) {
      Navigator.pop(
        context,
        user,
      );
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
          'Profilo studente',
        ),
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
                          700
                      ? 650
                      : constraints
                          .maxWidth;


              return SizedBox(
                width:
                    width,

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
                      const Text(
                        'Crea il tuo profilo',

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
                            8,
                      ),

                      Text(
                        'Crea il tuo account StudentLab e presentati '
                        'agli altri studenti.',

                        style:
                            TextStyle(
                          color:
                              AppColors.pureWhite
                                  .withOpacity(
                            0.60,
                          ),

                          fontSize:
                              14,

                          height:
                              1.4,
                        ),
                      ),

                      const SizedBox(
                        height:
                            28,
                      ),


                      // =======================================================
                      // NOME
                      // =======================================================

                      _buildRequiredField(
                        controller:
                            _firstNameController,

                        label:
                            'Nome',

                        hint:
                            'Es. Franz',

                        icon:
                            Icons.person_outline,
                      ),

                      const SizedBox(
                        height:
                            16,
                      ),


                      // =======================================================
                      // COGNOME
                      // =======================================================

                      _buildRequiredField(
                        controller:
                            _lastNameController,

                        label:
                            'Cognome',

                        hint:
                            'Es. Amoroso',

                        icon:
                            Icons.person_outline,
                      ),

                      const SizedBox(
                        height:
                            16,
                      ),


                      // =======================================================
                      // EMAIL
                      // =======================================================

                      TextFormField(
                        controller:
                            _emailController,

                        keyboardType:
                            TextInputType.emailAddress,

                        autofillHints:
                            const [
                          AutofillHints.email,
                        ],

                        style:
                            const TextStyle(
                          color:
                              AppColors.pureWhite,
                        ),

                        validator:
                            _validateEmail,

                        decoration:
                            _decoration(
                          label:
                              'Email',

                          hint:
                              'nome@example.com',

                          icon:
                              Icons.email_outlined,
                        ),
                      ),

                      const SizedBox(
                        height:
                            16,
                      ),


                      // =======================================================
                      // PASSWORD
                      // =======================================================

                      TextFormField(
                        controller:
                            _passwordController,

                        obscureText:
                            !_passwordVisible,

                        enableSuggestions:
                            false,

                        autocorrect:
                            false,

                        autofillHints:
                            const [
                          AutofillHints.newPassword,
                        ],

                        style:
                            const TextStyle(
                          color:
                              AppColors.pureWhite,
                        ),

                        validator:
                            _validatePassword,

                        decoration:
                            _passwordDecoration(
                          label:
                              'Password',

                          hint:
                              'Inserisci una password',

                          visible:
                              _passwordVisible,

                          onVisibilityPressed:
                              () {
                            setState(() {
                              _passwordVisible =
                                  !_passwordVisible;
                            });
                          },
                        ),
                      ),

                      const SizedBox(
                        height:
                            8,
                      ),

                      Text(
                        'Usa almeno 8 caratteri.',

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
                      ),

                      const SizedBox(
                        height:
                            16,
                      ),


                      // =======================================================
                      // CONFERMA PASSWORD
                      // =======================================================

                      TextFormField(
                        controller:
                            _confirmPasswordController,

                        obscureText:
                            !_confirmPasswordVisible,

                        enableSuggestions:
                            false,

                        autocorrect:
                            false,

                        textInputAction:
                            TextInputAction.next,

                        style:
                            const TextStyle(
                          color:
                              AppColors.pureWhite,
                        ),

                        validator:
                            _validateConfirmPassword,

                        decoration:
                            _passwordDecoration(
                          label:
                              'Conferma password',

                          hint:
                              'Ripeti la password',

                          visible:
                              _confirmPasswordVisible,

                          onVisibilityPressed:
                              () {
                            setState(() {
                              _confirmPasswordVisible =
                                  !_confirmPasswordVisible;
                            });
                          },
                        ),
                      ),

                      const SizedBox(
                        height:
                            24,
                      ),


                      // =======================================================
                      // DIPARTIMENTO
                      // =======================================================

                      _buildRequiredField(
                        controller:
                            _departmentController,

                        label:
                            'Dipartimento',

                        hint:
                            'Es. DMI',

                        icon:
                            Icons.account_balance_outlined,
                      ),

                      const SizedBox(
                        height:
                            16,
                      ),


                      // =======================================================
                      // CORSO
                      // =======================================================

                      _buildRequiredField(
                        controller:
                            _courseController,

                        label:
                            'Corso',

                        hint:
                            'Es. Informatica',

                        icon:
                            Icons.school_outlined,
                      ),

                      const SizedBox(
                        height:
                            12,
                      ),


                      // =======================================================
                      // CARICA MATERIE
                      // =======================================================

                      OutlinedButton.icon(
                        onPressed:
                            _loadingSubjects
                                ? null
                                : _loadSubjects,

                        icon:
                            _loadingSubjects
                                ? const SizedBox(
                                    width:
                                        17,

                                    height:
                                        17,

                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.refresh_rounded,
                                  ),

                        label:
                            const Text(
                          'Carica materie',
                        ),
                      ),


                      if (_subjectsError !=
                          null) ...[
                        const SizedBox(
                          height:
                              8,
                        ),

                        Text(
                          _subjectsError!,

                          style:
                              const TextStyle(
                            color:
                                Colors.redAccent,

                            fontSize:
                                11,
                          ),
                        ),
                      ],


                      const SizedBox(
                        height:
                            28,
                      ),


                      // =======================================================
                      // MATERIE
                      // =======================================================

                      const Row(
                        children: [
                          Icon(
                            Icons.menu_book_outlined,

                            color:
                                AppColors.skyBlue,
                          ),

                          SizedBox(
                            width:
                                9,
                          ),

                          Text(
                            'Materie',

                            style:
                                TextStyle(
                              color:
                                  AppColors.pureWhite,

                              fontSize:
                                  17,

                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height:
                            8,
                      ),

                      Text(
                        'Scegli le materie disponibili per il tuo '
                        'dipartimento e corso.',

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


                      ...List.generate(
                        _subjects.length,
                        (
                          int index,
                        ) {
                          return Padding(
                            padding:
                                const EdgeInsets.only(
                              bottom:
                                  14,
                            ),

                            child:
                                _buildSubject(
                              index,
                            ),
                          );
                        },
                      ),


                      OutlinedButton.icon(
                        onPressed:
                            _addSubject,

                        icon:
                            const Icon(
                          Icons.add,
                        ),

                        label:
                            const Text(
                          'Aggiungi materia',
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
                              0.30,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height:
                            28,
                      ),


                      // =======================================================
                      // DESCRIZIONE
                      // =======================================================

                      TextFormField(
                        controller:
                            _descriptionController,

                        maxLines:
                            5,

                        style:
                            const TextStyle(
                          color:
                              AppColors.pureWhite,
                        ),

                        decoration:
                            _decoration(
                          label:
                              'Descrizione',

                          hint:
                              'Presentati agli altri studenti...',

                          icon:
                              Icons.description_outlined,
                        ),
                      ),

                      const SizedBox(
                        height:
                            20,
                      ),


                      // =======================================================
                      // DISPONIBILE
                      // =======================================================

                      _switchCard(
                        title:
                            'Disponibile',

                        subtitle:
                            'Gli altri utenti vedranno che sei disponibile.',

                        value:
                            _available,

                        onChanged:
                            (
                          bool value,
                        ) {
                          setState(() {
                            _available =
                                value;
                          });
                        },
                      ),

                      const SizedBox(
                        height:
                            12,
                      ),


                      // =======================================================
                      // DISPONIBILE AD AIUTARE
                      // =======================================================

                      _switchCard(
                        title:
                            'Disponibile ad aiutare',

                        subtitle:
                            'Indica se vuoi renderti disponibile '
                            'per aiutare altri studenti.',

                        value:
                            _willingToTeach,

                        onChanged:
                            (
                          bool value,
                        ) {
                          setState(() {
                            _willingToTeach =
                                value;
                          });
                        },
                      ),

                      const SizedBox(
                        height:
                            28,
                      ),


                      // =======================================================
                      // PREVIEW
                      // =======================================================

                      SizedBox(
                        height:
                            54,

                        child:
                            ElevatedButton.icon(
                          onPressed:
                              _continue,

                          icon:
                              const Icon(
                            Icons.arrow_forward_rounded,
                          ),

                          label:
                              const Text(
                            'Visualizza anteprima',

                            style:
                                TextStyle(
                              fontSize:
                                  16,

                              fontWeight:
                                  FontWeight.w600,
                            ),
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
                                16,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height:
                            20,
                      ),
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
  // BLOCCO MATERIA
  // ===========================================================================

  Widget _buildSubject(
    int index,
  ) {
    final _StudentSubjectData item =
        _subjects[index];

    return Container(
      padding:
          const EdgeInsets.all(
        16,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.brandNightBlue,

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        border:
            Border.all(
          color:
              AppColors.socialBlue
                  .withOpacity(
            0.20,
          ),
        ),
      ),

      child:
          Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.menu_book_outlined,

                color:
                    AppColors.skyBlue,
              ),

              const SizedBox(
                width:
                    10,
              ),

              Expanded(
                child:
                    Text(
                  'Materia ${index + 1}',

                  style:
                      const TextStyle(
                    color:
                        AppColors.pureWhite,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              if (_subjects.length >
                  1)
                IconButton(
                  onPressed:
                      () {
                    _removeSubject(
                      index,
                    );
                  },

                  icon:
                      const Icon(
                    Icons.delete_outline,
                  ),

                  color:
                      Colors.redAccent,
                ),
            ],
          ),

          const SizedBox(
            height:
                12,
          ),


          // ===================================================================
          // SELECT MATERIA
          // ===================================================================

          DropdownButtonFormField<SocialSubject>(
            value:
                item.selectedSubject,

            isExpanded:
                true,

            dropdownColor:
                AppColors.eleganceDeepNavy,

            validator:
                (
              SocialSubject? value,
            ) {
              if (value == null) {
                return 'Seleziona una materia';
              }

              return null;
            },

            decoration:
                _decoration(
              label:
                  'Materia',

              hint:
                  'Seleziona una materia',

              icon:
                  Icons.book_outlined,
            ),

            items:
                _availableSubjects.map(
              (
                SocialSubject subject,
              ) {
                return DropdownMenuItem<
                    SocialSubject>(
                  value:
                      subject,

                  child:
                      Text(
                    subject.name,

                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        const TextStyle(
                      color:
                          AppColors.pureWhite,
                    ),
                  ),
                );
              },
            ).toList(),

            onChanged:
                (
              SocialSubject? value,
            ) {
              setState(() {
                item.selectedSubject =
                    value;
              });
            },
          ),

          const SizedBox(
            height:
                12,
          ),


          // ===================================================================
          // VOTO
          // ===================================================================

          TextFormField(
            controller:
                item.gradeController,

            keyboardType:
                TextInputType.number,

            style:
                const TextStyle(
              color:
                  AppColors.pureWhite,
            ),

            validator:
                (
              String? value,
            ) {
              if (value == null ||
                  value.trim().isEmpty) {
                return null;
              }

              final int? grade =
                  int.tryParse(
                value.trim(),
              );

              if (grade == null) {
                return 'Inserisci un numero valido';
              }

              if (grade < 18 ||
                  grade > 30) {
                return 'Il voto deve essere tra 18 e 30';
              }

              return null;
            },

            decoration:
                _decoration(
              label:
                  'Voto (facoltativo)',

              hint:
                  'Es. 28',

              icon:
                  Icons.grade_outlined,
            ),
          ),

          const SizedBox(
            height:
                12,
          ),


          // ===================================================================
          // CAN HELP
          // ===================================================================

          SwitchListTile(
            contentPadding:
                EdgeInsets.zero,

            value:
                item.canHelp,

            onChanged:
                (
              bool value,
            ) {
              setState(() {
                item.canHelp =
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
                    13,

                fontWeight:
                    FontWeight.w600,
              ),
            ),

            subtitle:
                Text(
              'Gli altri utenti potranno chiederti aiuto su questa materia.',

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
          ),

          const SizedBox(
            height:
                4,
          ),


          // ===================================================================
          // NOTA
          // ===================================================================

          TextFormField(
            controller:
                item.noteController,

            maxLines:
                3,

            style:
                const TextStyle(
              color:
                  AppColors.pureWhite,
            ),

            decoration:
                _decoration(
              label:
                  'Nota (facoltativa)',

              hint:
                  'Es. Posso aiutare con esercizi e teoria...',

              icon:
                  Icons.notes_outlined,
            ),
          ),
        ],
      ),
    );
  }


  // ===========================================================================
  // EMAIL VALIDATION
  // ===========================================================================

  String? _validateEmail(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Campo obbligatorio';
    }

    final String email =
        value.trim();

    final RegExp emailRegex =
        RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(
      email,
    )) {
      return 'Inserisci una email valida';
    }

    return null;
  }


  // ===========================================================================
  // PASSWORD VALIDATION
  // ===========================================================================

  String? _validatePassword(
    String? value,
  ) {
    if (value == null ||
        value.isEmpty) {
      return 'Inserisci una password';
    }

    if (value.length < 8) {
      return 'La password deve contenere almeno 8 caratteri';
    }

    return null;
  }


  // ===========================================================================
  // CONFIRM PASSWORD
  // ===========================================================================

  String? _validateConfirmPassword(
    String? value,
  ) {
    if (value == null ||
        value.isEmpty) {
      return 'Conferma la password';
    }

    if (value !=
        _passwordController.text) {
      return 'Le password non coincidono';
    }

    return null;
  }


  // ===========================================================================
  // CAMPO GENERICO
  // ===========================================================================

  Widget _buildRequiredField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextFormField(
      controller:
          controller,

      style:
          const TextStyle(
        color:
            AppColors.pureWhite,
      ),

      validator:
          (
        String? value,
      ) {
        if (value == null ||
            value.trim().isEmpty) {
          return 'Campo obbligatorio';
        }

        return null;
      },

      decoration:
          _decoration(
        label:
            label,

        hint:
            hint,

        icon:
            icon,
      ),
    );
  }


  // ===========================================================================
  // DECORAZIONE
  // ===========================================================================

  InputDecoration _decoration({
    required String label,
    required String hint,
    required IconData icon,
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
          0.60,
        ),
      ),

      hintStyle:
          TextStyle(
        color:
            AppColors.pureWhite
                .withOpacity(
          0.30,
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
          AppColors.darkElegance,

      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),

        borderSide:
            BorderSide.none,
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),

        borderSide:
            BorderSide.none,
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),

        borderSide:
            const BorderSide(
          color:
              AppColors.socialBlue,
        ),
      ),
    );
  }


  // ===========================================================================
  // PASSWORD DECORATION
  // ===========================================================================

  InputDecoration _passwordDecoration({
    required String label,
    required String hint,
    required bool visible,
    required VoidCallback onVisibilityPressed,
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
          0.60,
        ),
      ),

      hintStyle:
          TextStyle(
        color:
            AppColors.pureWhite
                .withOpacity(
          0.30,
        ),
      ),

      prefixIcon:
          const Icon(
        Icons.lock_outline_rounded,

        color:
            AppColors.skyBlue,
      ),

      suffixIcon:
          IconButton(
        tooltip:
            visible
                ? 'Nascondi password'
                : 'Mostra password',

        onPressed:
            onVisibilityPressed,

        icon:
            Icon(
          visible
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,

          color:
              AppColors.pureWhite
                  .withOpacity(
            0.55,
          ),
        ),
      ),

      filled:
          true,

      fillColor:
          AppColors.darkElegance,

      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),

        borderSide:
            BorderSide.none,
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),

        borderSide:
            BorderSide.none,
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),

        borderSide:
            const BorderSide(
          color:
              AppColors.socialBlue,
        ),
      ),
    );
  }


  // ===========================================================================
  // SWITCH
  // ===========================================================================

  Widget _switchCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration:
          BoxDecoration(
        color:
            AppColors.brandNightBlue,

        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),

      child:
          SwitchListTile(
        value:
            value,

        onChanged:
            onChanged,

        activeColor:
            AppColors.skyBlue,

        title:
            Text(
          title,

          style:
              const TextStyle(
            color:
                AppColors.pureWhite,

            fontWeight:
                FontWeight.w600,
          ),
        ),

        subtitle:
            Text(
          subtitle,

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
      ),
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
// STUDENT SUBJECT DATA
// =============================================================================

class _StudentSubjectData {
  SocialSubject? selectedSubject;


  final TextEditingController
      gradeController =
      TextEditingController();


  final TextEditingController
      noteController =
      TextEditingController();


  bool canHelp =
      false;


  void dispose() {
    gradeController.dispose();

    noteController.dispose();
  }
}