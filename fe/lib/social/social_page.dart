import 'package:flutter/material.dart';

import '../theme/nightTheme.dart';

import 'social_models.dart';

import 'widgets/social_intro.dart';
import 'widgets/student_help_card.dart';
import 'widgets/teacher_help_card.dart';

class SocialPage extends StatefulWidget {
  const SocialPage({super.key});

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> {

  SocialUserType selectedType =
      SocialUserType.student;

 final List<SocialUser> users = const [

  SocialUser(
    id: '1',
    name: 'Marco',
    university: 'Università di Catania',
    course: 'Informatica',

    subjects: [
      SocialSubject(
        name: 'Programmazione',
        grade: 28,
        note: 'Posso aiutare con C, C++ e programmazione.',
      ),

      SocialSubject(
        name: 'Algebra',
        grade: 25,
        note: 'Disponibile per esercizi e preparazione.',
      ),
    ],

    description:
        'Mi piace aiutare altri studenti e confrontarmi sugli argomenti del corso.',

    type: SocialUserType.student,

    available: true,

    privateLessons: false,

    reviews: [
      SocialReview(
        authorName: 'Francesca',
        rating: 5,
        comment: 'Molto disponibile e bravo a spiegare.',
      ),

      SocialReview(
        authorName: 'Luca',
        rating: 4.5,
        comment: 'Mi ha aiutato molto con programmazione.',
      ),
    ],
  ),

  SocialUser(
    id: '2',
    name: 'Francesca',
    university: 'Università di Catania',
    course: 'Informatica',

    subjects: [
      SocialSubject(
        name: 'Algebra',
        grade: 30,
        note: 'Posso aiutare con esercizi e teoria.',
      ),
    ],

    description:
        'Disponibile per confrontarsi e chiarire dubbi.',

    type: SocialUserType.student,

    available: true,

    privateLessons: false,

    reviews: [
      SocialReview(
        authorName: 'Marco',
        rating: 5,
        comment: 'Ottima compagna di studio.',
      ),
    ],
  ),

  SocialUser(
    id: '3',
    name: 'Prof. Rossi',
    university: 'Università di Catania',
    course: 'Informatica',

    subjects: [
      SocialSubject(
        name: 'Programmazione',
        note: 'C, C++, Java e programmazione ad oggetti.',
      ),

      SocialSubject(
        name: 'Ingegneria del Software',
        note: 'UML, design pattern e architettura software.',
      ),

      SocialSubject(
        name: 'Basi di Dati',
        note: 'SQL, progettazione e database relazionali.',
      ),
    ],

    description:
        'Docente disponibile per supporto nella preparazione degli esami e lezioni private.',

    type: SocialUserType.teacher,

    available: true,

    privateLessons: true,

    reviews: [
      SocialReview(
        authorName: 'Marco',
        rating: 5,
        comment: 'Spiegazioni molto chiare e grande disponibilità.',
      ),

      SocialReview(
        authorName: 'Francesca',
        rating: 4.5,
        comment: 'Ottimo docente, molto preparato.',
      ),
    ],
  ),
];

  @override
  Widget build(BuildContext context) {

    final students = users
        .where((u) => u.type == SocialUserType.student)
        .toList();

    final teachers = users
        .where((u) => u.type == SocialUserType.teacher)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.darkElegance,

      appBar: AppBar(
        title: const Text('StudentLab Social'),
      ),

      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {

            final width =
                constraints.maxWidth > 700
                    ? 700.0
                    : constraints.maxWidth;

            return SizedBox(
              width: width,

              child: ListView(
                padding: const EdgeInsets.all(20),

                children: [

                  const SocialIntro(),

                  const SizedBox(height: 24),

                  _buildSelector(),

                  const SizedBox(height: 24),

                  if (selectedType ==
                      SocialUserType.student)

                    ...students.map(
                      (student) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: 14),
                        child: StudentHelpCard(
                          student: student,
                        ),
                      ),
                    )

                  else

                    ...teachers.map(
                      (teacher) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: 14),
                        child: TeacherHelpCard(
                          teacher: teacher,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSelector() {

    return Row(
      children: [

        Expanded(
          child: _selectorButton(
            'Studenti',
            Icons.school,
            SocialUserType.student,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _selectorButton(
            'Insegnanti',
            Icons.person,
            SocialUserType.teacher,
          ),
        ),
      ],
    );
  }

  Widget _selectorButton(
    String title,
    IconData icon,
    SocialUserType type,
  ) {

    final selected = selectedType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedType = type;
        });
      },

      child: Container(
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: selected
              ? AppColors.socialBlue.withOpacity(0.15)
              : AppColors.charcoalGrey,

          borderRadius:
              BorderRadius.circular(14),

          border: Border.all(
            color: selected
                ? AppColors.socialBlue
                : Colors.transparent,
          ),
        ),

        child: Column(
          children: [

            Icon(
              icon,
              color: selected
                  ? AppColors.pureWhite
                  : AppColors.skyBlue,
            ),

            const SizedBox(height: 8),

            Text(
              title,
              style: TextStyle(
                color: selected
                    ? AppColors.skyBlue
                    : AppColors.pureWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}