import 'package:flutter/material.dart';
import 'package:fe/theme/nightTheme.dart';
import 'package:fe/social/widgets/student_social_form.dart';
import 'package:fe/social/widgets/teacher_social_form.dart';


class SocialProfileType extends StatelessWidget {
  const SocialProfileType({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkElegance,

      appBar: AppBar(
        backgroundColor: AppColors.brandNightBlue,
        foregroundColor: AppColors.pureWhite,
        elevation: 0,
        title: const Text(
          'StudentLab Social',
        ),
      ),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 650,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),

                        const Icon(
                          Icons.groups_rounded,
                          size: 70,
                          color: AppColors.socialSky,
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'Entra nella community',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.pureWhite,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          'Connettiti con altri studenti e insegnanti '
                          'per condividere conoscenze, chiarire dubbi '
                          'e aiutarti nello studio.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.pureWhite.withOpacity(0.65),
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 35),

                        _buildOptionCard(
                          icon: Icons.school_rounded,
                          title: 'Sono uno studente',
                          description:
                              'Voglio aiutare altri studenti oppure '
                              'trovare qualcuno con cui studiare.',
                          color: AppColors.studentBlue,
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const StudentSocialForm(),
                                ),
                              );
                          },
                        ),

                        const SizedBox(height: 16),

                        _buildOptionCard(
                          icon: Icons.cast_for_education_rounded,
                          title: 'Sono un insegnante',
                          description:
                              'Voglio rendermi disponibile per lezioni '
                              'private e supporto agli studenti.',
                          color: AppColors.teacherIndigo,
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TeacherSocialForm(),
                                ),
                              );
                          },
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),

      child: Container(
        padding: const EdgeInsets.all(20),

        decoration: BoxDecoration(
          color: AppColors.eleganceMidnight,
          borderRadius: BorderRadius.circular(20),

          border: Border.all(
            color: color.withOpacity(0.35),
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),

        child: Row(
          children: [
            Container(
              width: 55,
              height: 55,

              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(15),
              ),

              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.pureWhite,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    description,
                    style: TextStyle(
                      color: AppColors.pureWhite.withOpacity(0.60),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color,
              size: 17,
            ),
          ],
        ),
      ),
    );
  }
}