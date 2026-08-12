import 'package:flutter/material.dart';

import '../../theme/nightTheme.dart';
import '../social_models.dart';
import 'social_profile_preview.dart';

class StudentSocialForm extends StatefulWidget {
  const StudentSocialForm({super.key});

  @override
  State<StudentSocialForm> createState() =>
      _StudentSocialFormState();
}

class _StudentSocialFormState
    extends State<StudentSocialForm> {

  final _formKey = GlobalKey<FormState>();

  final _nameController =
      TextEditingController();

  final _universityController =
      TextEditingController();

  final _courseController =
      TextEditingController();

  final _descriptionController =
      TextEditingController();

  bool _available = true;

  final List<_StudentSubjectData> _subjects = [
    _StudentSubjectData(),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _universityController.dispose();
    _courseController.dispose();
    _descriptionController.dispose();

    for (final subject in _subjects) {
      subject.dispose();
    }

    super.dispose();
  }

  void _addSubject() {
    setState(() {
      _subjects.add(
        _StudentSubjectData(),
      );
    });
  }

  // ============================================================
  // RIMUOVI MATERIA
  // ============================================================

  void _removeSubject(int index) {
    if (_subjects.length == 1) {
      return;
    }

    setState(() {
      _subjects[index].dispose();
      _subjects.removeAt(index);
    });
  }

  void _continue() {

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final subjects =
        _subjects.map(
      (item) {

        final gradeText =
            item.gradeController.text.trim();

        final int? grade =
            gradeText.isEmpty
                ? null
                : int.tryParse(gradeText);

        return SocialSubject(
          name:
              item.nameController.text.trim(),

          grade:
              grade,

          note:
              item.noteController.text.trim(),
        );
      },
    ).toList();

    final draft =
        SocialProfileDraft(

      name:
          _nameController.text.trim(),

      university:
          _universityController.text.trim(),

      course:
          _courseController.text.trim(),

      subjects:
          subjects,

      description:
          _descriptionController.text.trim(),

      type:
          SocialUserType.student,

      available:
          _available,

      privateLessons:
          false,
    );

    Navigator.push(
      context,

      MaterialPageRoute(
        builder: (_) =>
            SocialProfilePreview(
          draft: draft,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor:
          AppColors.darkElegance,

      appBar: AppBar(
        backgroundColor:
            AppColors.brandNightBlue,

        foregroundColor:
            AppColors.pureWhite,

        title: const Text(
          'Profilo studente',
        ),
      ),

      body: SafeArea(
        child: Center(
          child: LayoutBuilder(
            builder:
                (context, constraints) {

              final width =
                  constraints.maxWidth > 700
                      ? 650.0
                      : constraints.maxWidth;

              return SizedBox(
                width: width,

                child: Form(
                  key: _formKey,

                  child: ListView(
                    padding:
                        const EdgeInsets.all(20),

                    children: [


                      const Text(
                        'Crea il tuo profilo',
                        style: TextStyle(
                          color:
                              AppColors.pureWhite,
                          fontSize: 24,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Presentati agli altri studenti e '
                        'indica le materie in cui puoi '
                        'condividere le tue conoscenze.',

                        style: TextStyle(
                          color: AppColors
                              .pureWhite
                              .withOpacity(0.60),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 28),


                      _buildField(
                        controller:
                            _nameController,

                        label:
                            'Nome',

                        hint:
                            'Es. Franz',

                        icon:
                            Icons.person_outline,
                      ),

                      const SizedBox(height: 16),

                      _buildField(
                        controller:
                            _universityController,

                        label:
                            'Università',

                        hint:
                            'Es. Università di Catania',

                        icon:
                            Icons.account_balance_outlined,
                      ),

                      const SizedBox(height: 16),

                      _buildField(
                        controller:
                            _courseController,

                        label:
                            'Corso',

                        hint:
                            'Es. Informatica L-31',

                        icon:
                            Icons.school_outlined,
                      ),

                      const SizedBox(height: 28),

                      Row(
                        children: [

                          const Icon(
                            Icons.menu_book_outlined,
                            color:
                                AppColors.skyBlue,
                          ),

                          const SizedBox(width: 9),

                          const Text(
                            'Materie',
                            style: TextStyle(
                              color:
                                  AppColors.pureWhite,
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Puoi aggiungere più materie. '
                        'Per ogni materia puoi indicare '
                        'facoltativamente il voto e una nota.',

                        style: TextStyle(
                          color: AppColors
                              .pureWhite
                              .withOpacity(0.50),
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 14),

                      ...List.generate(
                        _subjects.length,
                        (index) {

                          return Padding(
                            padding:
                                const EdgeInsets.only(
                              bottom: 14,
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

                          side: BorderSide(
                            color: AppColors
                                .skyBlue
                                .withOpacity(0.30),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ==================================================
                      // DESCRIZIONE
                      // ==================================================

                      TextFormField(
                        controller:
                            _descriptionController,

                        maxLines: 5,

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
                              Icons
                                  .description_outlined,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ==================================================
                      // DISPONIBILITÀ
                      // ==================================================

                      _switchCard(
                        title:
                            'Disponibile',

                        subtitle:
                            'Gli altri studenti potranno '
                            'vedere che sei disponibile.',

                        value:
                            _available,

                        onChanged:
                            (value) {

                          setState(() {
                            _available =
                                value;
                          });

                        },
                      ),

                      const SizedBox(height: 28),

                      // ==================================================
                      // PREVIEW
                      // ==================================================

                      SizedBox(
                        height: 54,

                        child:
                            ElevatedButton.icon(
                          onPressed:
                              _continue,

                          icon:
                              const Icon(
                            Icons
                                .arrow_forward_rounded,
                          ),

                          label:
                              const Text(
                            'Visualizza anteprima',

                            style:
                                TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),

                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                AppColors
                                    .socialBlue,

                            foregroundColor:
                                AppColors
                                    .pureWhite,

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      16),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
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

  // ============================================================
  // BLOCCO MATERIA
  // ============================================================

  Widget _buildSubject(int index) {

    final subject =
        _subjects[index];

    return Container(
      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color:
            AppColors.brandNightBlue,

        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color:
              AppColors.socialBlue
                  .withOpacity(0.20),
        ),
      ),

      child: Column(
        children: [

          // ==========================================================
          // HEADER MATERIA
          // ==========================================================

          Row(
            children: [

              const Icon(
                Icons.menu_book_outlined,
                color:
                    AppColors.skyBlue,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
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

              if (_subjects.length > 1)
                IconButton(
                  onPressed:
                      () =>
                          _removeSubject(
                            index,
                          ),

                  icon:
                      const Icon(
                    Icons.delete_outline,
                  ),

                  color:
                      Colors.redAccent,
                ),
            ],
          ),

          const SizedBox(height: 12),

          // ==========================================================
          // NOME MATERIA
          // ==========================================================

          TextFormField(
            controller:
                subject.nameController,

            style:
                const TextStyle(
              color:
                  AppColors.pureWhite,
            ),

            validator:
                (value) {

              if (value == null ||
                  value.trim().isEmpty) {

                return 'Inserisci la materia';
              }

              return null;
            },

            decoration:
                _decoration(
              label:
                  'Materia',

              hint:
                  'Es. Programmazione',

              icon:
                  Icons.book_outlined,
            ),
          ),

          const SizedBox(height: 12),

          // ==========================================================
          // VOTO
          // ==========================================================

          TextFormField(
            controller:
                subject.gradeController,

            keyboardType:
                TextInputType.number,

            style:
                const TextStyle(
              color:
                  AppColors.pureWhite,
            ),

            validator:
                (value) {

              if (value == null ||
                  value.trim().isEmpty) {
                return null;
              }

              final grade =
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

          const SizedBox(height: 12),

          // ==========================================================
          // NOTA
          // ==========================================================

          TextFormField(
            controller:
                subject.noteController,

            maxLines: 3,

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

  // ============================================================
  // CAMPO GENERICO
  // ============================================================

  Widget _buildField({
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
          (value) {

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

  // ============================================================
  // DECORAZIONE
  // ============================================================

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
        color: AppColors
            .pureWhite
            .withOpacity(0.60),
      ),

      hintStyle:
          TextStyle(
        color: AppColors
            .pureWhite
            .withOpacity(0.30),
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
            BorderRadius.circular(14),

        borderSide:
            BorderSide.none,
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),

        borderSide:
            BorderSide.none,
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),

        borderSide:
            const BorderSide(
          color:
              AppColors.socialBlue,
        ),
      ),
    );
  }

  // ============================================================
  // SWITCH CARD
  // ============================================================

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
            BorderRadius.circular(16),
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
            const Text(
          'Disponibile',

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
          subtitle,

          style:
              TextStyle(
            color: AppColors
                .pureWhite
                .withOpacity(0.50),
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// STUDENT SUBJECT DATA
// ============================================================================

class _StudentSubjectData {

  final nameController =
      TextEditingController();

  final gradeController =
      TextEditingController();

  final noteController =
      TextEditingController();

  void dispose() {
    nameController.dispose();
    gradeController.dispose();
    noteController.dispose();
  }
}