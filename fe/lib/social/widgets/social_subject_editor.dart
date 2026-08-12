import 'package:flutter/material.dart';
import '../../theme/nightTheme.dart';
import '../social_models.dart';

class SocialSubjectEditor extends StatefulWidget {
  final bool showGrade;
  final SocialSubject? initialSubject;

  const SocialSubjectEditor({
    super.key,
    this.showGrade = true,
    this.initialSubject,
  });

  @override
  State<SocialSubjectEditor> createState() =>
      _SocialSubjectEditorState();
}

class _SocialSubjectEditorState
    extends State<SocialSubjectEditor> {

  late final TextEditingController _nameController;
  late final TextEditingController _gradeController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.initialSubject?.name ?? '',
    );

    _gradeController = TextEditingController(
      text: widget.initialSubject?.grade?.toString() ?? '',
    );

    _noteController = TextEditingController(
      text: widget.initialSubject?.note ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gradeController.dispose();
    _noteController.dispose();

    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final gradeText = _gradeController.text.trim();
    final note = _noteController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inserisci il nome della materia.'),
        ),
      );

      return;
    }

    int? grade;

    if (gradeText.isNotEmpty) {
      final parsedGrade = int.tryParse(gradeText);

      if (parsedGrade == null ||
          parsedGrade < 0 ||
          parsedGrade > 30) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Il voto deve essere un numero tra 0 e 30.',
            ),
          ),
        );

        return;
      }

      grade = parsedGrade;
    }

    final subject = SocialSubject(
      name: name,
      grade: grade,
      note: note,
    );

    Navigator.pop(context, subject);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkElegance,

      appBar: AppBar(
        backgroundColor: AppColors.brandNightBlue,
        foregroundColor: AppColors.pureWhite,
        title: Text(
          widget.initialSubject == null
              ? 'Aggiungi materia'
              : 'Modifica materia',
        ),
      ),

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 650,
            ),

            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,

                children: [

                  const Text(
                    'Materia',
                    style: TextStyle(
                      color: AppColors.pureWhite,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller: _nameController,

                    style: const TextStyle(
                      color: AppColors.pureWhite,
                    ),

                    decoration: InputDecoration(
                      hintText: 'Es. Programmazione',
                      hintStyle: TextStyle(
                        color: AppColors.pureWhite
                            .withOpacity(0.35),
                      ),

                      prefixIcon: const Icon(
                        Icons.menu_book_outlined,
                        color: AppColors.skyBlue,
                      ),

                      filled: true,

                      fillColor:
                          AppColors.brandNightBlue,

                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (widget.showGrade) ...[
                    const Text(
                      'Voto',
                      style: TextStyle(
                        color: AppColors.pureWhite,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Facoltativo',
                      style: TextStyle(
                        color: AppColors.pureWhite
                            .withOpacity(0.40),
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller: _gradeController,

                      keyboardType:
                          TextInputType.number,

                      style: const TextStyle(
                        color: AppColors.pureWhite,
                      ),

                      decoration: InputDecoration(
                        hintText: 'Es. 28',
                        hintStyle: TextStyle(
                          color: AppColors.pureWhite
                              .withOpacity(0.35),
                        ),

                        prefixIcon: const Icon(
                          Icons.grade_outlined,
                          color: AppColors.skyBlue,
                        ),

                        suffixText: '/ 30',

                        suffixStyle: TextStyle(
                          color: AppColors.pureWhite
                              .withOpacity(0.45),
                        ),

                        filled: true,

                        fillColor:
                            AppColors.brandNightBlue,

                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                          borderSide:
                              BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                  const Text(
                    'Nota sulla materia',
                    style: TextStyle(
                      color: AppColors.pureWhite,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Facoltativa',
                    style: TextStyle(
                      color: AppColors.pureWhite
                          .withOpacity(0.40),
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller: _noteController,

                    maxLines: 5,

                    style: const TextStyle(
                      color: AppColors.pureWhite,
                    ),

                    decoration: InputDecoration(
                      hintText:
                          'Scrivi una breve nota su questa materia...',
                      hintStyle: TextStyle(
                        color: AppColors.pureWhite
                            .withOpacity(0.35),
                      ),

                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(
                          bottom: 70,
                        ),

                        child: Icon(
                          Icons.notes_outlined,
                          color: AppColors.skyBlue,
                        ),
                      ),

                      filled: true,

                      fillColor:
                          AppColors.brandNightBlue,

                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // =====================================================
                  // SALVA
                  // =====================================================

                  SizedBox(
                    height: 54,

                    child: ElevatedButton.icon(
                      onPressed: _save,

                      icon: const Icon(
                        Icons.check_rounded,
                      ),

                      label: Text(
                        widget.initialSubject == null
                            ? 'Aggiungi materia'
                            : 'Salva modifiche',
                      ),

                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.socialBlue,

                        foregroundColor:
                            AppColors.pureWhite,

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(16),
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
}