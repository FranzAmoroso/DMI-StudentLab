import 'package:flutter/material.dart';

import '../../theme/nightTheme.dart';

import '../social_models.dart';


class SocialSubjectEditor extends StatefulWidget {
  final String department;
  final String course;

  final bool showGrade;

  final SocialSubject? initialSubject;


  const SocialSubjectEditor({
    super.key,

    required this.department,
    required this.course,

    this.showGrade = true,

    this.initialSubject,
  });


  @override
  State<SocialSubjectEditor> createState() =>
      _SocialSubjectEditorState();
}


class _SocialSubjectEditorState
    extends State<SocialSubjectEditor> {

  late final TextEditingController
      _nameController;

  late final TextEditingController
      _gradeController;

  late final TextEditingController
      _noteController;


  bool _canHelp = false;


  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();


    _nameController =
        TextEditingController(
      text:
          widget.initialSubject?.name ??
              '',
    );


    _gradeController =
        TextEditingController(
      text:
          widget.initialSubject?.grade
                  ?.toString() ??
              '',
    );


    _noteController =
        TextEditingController(
      text:
          widget.initialSubject?.note ??
              '',
    );


    _canHelp =
        widget.initialSubject?.canHelp ??
            false;
  }


  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    _nameController.dispose();

    _gradeController.dispose();

    _noteController.dispose();

    super.dispose();
  }


  // ===========================================================================
  // SAVE
  // ===========================================================================

  void _save() {
    final String name =
        _nameController.text.trim();


    final String gradeText =
        _gradeController.text.trim();


    final String note =
        _noteController.text.trim();


    if (name.isEmpty) {
      _showMessage(
        'Inserisci il nome della materia.',
      );

      return;
    }


    int? grade;


    if (widget.showGrade &&
        gradeText.isNotEmpty) {

      final int? parsedGrade =
          int.tryParse(
        gradeText,
      );


      if (parsedGrade == null ||
          parsedGrade < 0 ||
          parsedGrade > 30) {

        _showMessage(
          'Il voto deve essere un numero tra 0 e 30.',
        );

        return;
      }


      grade =
          parsedGrade;
    }


    final SocialSubject subject =
        SocialSubject(
      /*
       * Se stiamo modificando una materia
       * esistente manteniamo il suo ID.
       *
       * Se è nuova, 0 significa che non è
       * ancora associata a una Subject reale
       * del backend.
       *
       * In futuro sarebbe meglio NON digitare
       * manualmente la materia, ma selezionarla
       * da GET /social_subjects/{department}/{course}.
       */
      id:
          widget.initialSubject?.id ??
              0,

      name:
          name,

      department:
          widget.department,

      course:
          widget.course,

      grade:
          grade,

      note:
          note,

      canHelp:
          _canHelp,
    );


    Navigator.pop(
      context,
      subject,
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
            Text(
          widget.initialSubject ==
                  null
              ? 'Aggiungi materia'
              : 'Modifica materia',
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
                  650,
            ),

            child:
                SingleChildScrollView(
              padding:
                  const EdgeInsets.all(
                20,
              ),

              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,

                children: [
                  // ===========================================================
                  // MATERIA
                  // ===========================================================

                  const Text(
                    'Materia',

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

                  TextField(
                    controller:
                        _nameController,

                    style:
                        const TextStyle(
                      color:
                          AppColors.pureWhite,
                    ),

                    decoration:
                        _decoration(
                      hint:
                          'Es. Programmazione 1',

                      icon:
                          Icons.menu_book_outlined,
                    ),
                  ),


                  // ===========================================================
                  // VOTO
                  // ===========================================================

                  if (widget.showGrade) ...[
                    const SizedBox(
                      height:
                          20,
                    ),

                    const Text(
                      'Voto',

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
                          4,
                    ),

                    Text(
                      'Facoltativo',

                      style:
                          TextStyle(
                        color:
                            AppColors.pureWhite
                                .withOpacity(
                          0.40,
                        ),

                        fontSize:
                            12,
                      ),
                    ),

                    const SizedBox(
                      height:
                          8,
                    ),

                    TextField(
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
                          InputDecoration(
                        hintText:
                            'Es. 28',

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
                          Icons.grade_outlined,

                          color:
                              AppColors.skyBlue,
                        ),

                        suffixText:
                            '/ 30',

                        suffixStyle:
                            TextStyle(
                          color:
                              AppColors.pureWhite
                                  .withOpacity(
                            0.45,
                          ),
                        ),

                        filled:
                            true,

                        fillColor:
                            AppColors.brandNightBlue,

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
                    ),
                  ],


                  // ===========================================================
                  // AIUTO
                  // ===========================================================

                  const SizedBox(
                    height:
                        20,
                  ),

                  Container(
                    decoration:
                        BoxDecoration(
                      color:
                          AppColors.brandNightBlue,

                      borderRadius:
                          BorderRadius.circular(
                        14,
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
                        SwitchListTile(
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
                        'Disponibile ad aiutare',

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

                      subtitle:
                          Text(
                        'Gli altri utenti potranno contattarti per chiedere aiuto su questa materia.',

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
                    ),
                  ),


                  // ===========================================================
                  // NOTA
                  // ===========================================================

                  const SizedBox(
                    height:
                        20,
                  ),

                  const Text(
                    'Nota sulla materia',

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
                        4,
                  ),

                  Text(
                    'Facoltativa',

                    style:
                        TextStyle(
                      color:
                          AppColors.pureWhite
                              .withOpacity(
                        0.40,
                      ),

                      fontSize:
                          12,
                    ),
                  ),

                  const SizedBox(
                    height:
                        8,
                  ),

                  TextField(
                    controller:
                        _noteController,

                    maxLines:
                        5,

                    style:
                        const TextStyle(
                      color:
                          AppColors.pureWhite,
                    ),

                    decoration:
                        InputDecoration(
                      hintText:
                          'Scrivi una breve nota su questa materia...',

                      hintStyle:
                          TextStyle(
                        color:
                            AppColors.pureWhite
                                .withOpacity(
                          0.35,
                        ),
                      ),

                      prefixIcon:
                          const Padding(
                        padding:
                            EdgeInsets.only(
                          bottom:
                              70,
                        ),

                        child:
                            Icon(
                          Icons.notes_outlined,

                          color:
                              AppColors.skyBlue,
                        ),
                      ),

                      filled:
                          true,

                      fillColor:
                          AppColors.brandNightBlue,

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
                  ),


                  // ===========================================================
                  // SALVA
                  // ===========================================================

                  const SizedBox(
                    height:
                        30,
                  ),

                  SizedBox(
                    height:
                        54,

                    child:
                        ElevatedButton.icon(
                      onPressed:
                          _save,

                      icon:
                          const Icon(
                        Icons.check_rounded,
                      ),

                      label:
                          Text(
                        widget.initialSubject ==
                                null
                            ? 'Aggiungi materia'
                            : 'Salva modifiche',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  // ===========================================================================
  // DECORATION
  // ===========================================================================

  InputDecoration _decoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText:
          hint,

      hintStyle:
          TextStyle(
        color:
            AppColors.pureWhite
                .withOpacity(
          0.35,
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
          14,
        ),

        borderSide:
            BorderSide.none,
      ),
    );
  }


  // ===========================================================================
  // MESSAGE
  // ===========================================================================

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(
          message,
        ),
      ),
    );
  }
}