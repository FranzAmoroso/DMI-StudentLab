import 'package:flutter/material.dart';

import '../../theme/nightTheme.dart';

import '../social_models.dart';

import '../message/contact_user_page.dart';


class TeacherHelpCard
    extends StatelessWidget {

  final SocialUser teacher;


  const TeacherHelpCard({
    super.key,
    required this.teacher,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color:
            AppColors.eleganceDeepNavy,

        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color:
              AppColors.teacherIndigo
                  .withOpacity(0.30),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          // ===================================================================
          // HEADER
          // ===================================================================

          Row(
            children: [
              CircleAvatar(
                radius:
                    25,

                backgroundColor:
                    AppColors.teacherIndigo,

                child: Text(
                  teacher.name.isNotEmpty
                      ? teacher.name[0]
                          .toUpperCase()
                      : '?',

                  style:
                      const TextStyle(
                    color:
                        AppColors.pureWhite,

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
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      teacher.name,

                      maxLines:
                          1,

                      overflow:
                          TextOverflow.ellipsis,

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
                          3,
                    ),

                    const Text(
                      'Insegnante',

                      style: TextStyle(
                        color:
                            AppColors.teacherIndigo,

                        fontSize:
                            12,

                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              if (teacher.available)
                const _AvailableBadge(),
            ],
          ),

          const SizedBox(
            height:
                16,
          ),


          // ===================================================================
          // DISPONIBILITÀ
          // ===================================================================

          Wrap(
            spacing:
                8,

            runSpacing:
                8,

            children: [
              if (teacher.available)
                const _CapabilityChip(
                  icon:
                      Icons.support_agent_rounded,

                  label:
                      'Disponibile',
                ),

              if (teacher.willingToTeach)
                const _CapabilityChip(
                  icon:
                      Icons.school_outlined,

                  label:
                      'Lezioni private',
                ),
            ],
          ),


          // ===================================================================
          // MATERIE
          // ===================================================================

          if (teacher.subjects.isNotEmpty) ...[
            const SizedBox(
              height:
                  18,
            ),

            const Text(
              'Materie',

              style: TextStyle(
                color:
                    AppColors.pureWhite,

                fontSize:
                    13,

                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height:
                  8,
            ),

            ...teacher.subjects.map(
              (subject) =>
                  _TeacherSubject(
                subject:
                    subject,
              ),
            ),
          ],


          // ===================================================================
          // DESCRIZIONE
          // ===================================================================

          if (teacher.description.isNotEmpty) ...[
            const SizedBox(
              height:
                  10,
            ),

            Text(
              teacher.description,

              style: TextStyle(
                color:
                    AppColors.pureWhite
                        .withOpacity(0.70),

                fontSize:
                    14,

                height:
                    1.4,
              ),
            ),
          ],


          const SizedBox(
            height:
                12,
          ),


          Text(
            '${teacher.department} • ${teacher.course}',

            maxLines:
                2,

            overflow:
                TextOverflow.ellipsis,

            style: TextStyle(
              color:
                  AppColors.pureWhite
                      .withOpacity(0.45),

              fontSize:
                  12,
            ),
          ),


          if (teacher.reviews.isNotEmpty) ...[
            const SizedBox(
              height:
                  14,
            ),

            _ReviewSummary(
              user:
                  teacher,
            ),
          ],


          const SizedBox(
            height:
                16,
          ),


          // ===================================================================
          // CONTATTA
          // ===================================================================

          SizedBox(
            width:
                double.infinity,

            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (_) =>
                            ContactUserPage(
                      user:
                          teacher,
                    ),
                  ),
                );
              },

              icon: const Icon(
                Icons.mail_outline_rounded,
              ),

              label: const Text(
                'Contatta',
              ),

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.teacherIndigo,

                foregroundColor:
                    AppColors.pureWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// =============================================================================
// AVAILABLE
// =============================================================================

class _AvailableBadge
    extends StatelessWidget {

  const _AvailableBadge();


  @override
  Widget build(
    BuildContext context,
  ) {
    return const Row(
      mainAxisSize:
          MainAxisSize.min,

      children: [
        Icon(
          Icons.circle,

          color:
              Colors.green,

          size:
              9,
        ),

        SizedBox(
          width:
              5,
        ),

        Text(
          'Disponibile',

          style: TextStyle(
            color:
                Colors.green,

            fontSize:
                11,
          ),
        ),
      ],
    );
  }
}


// =============================================================================
// CAPABILITY
// =============================================================================

class _CapabilityChip
    extends StatelessWidget {

  final IconData icon;

  final String label;


  const _CapabilityChip({
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
            9,

        vertical:
            6,
      ),

      decoration: BoxDecoration(
        color:
            AppColors.teacherIndigo
                .withOpacity(0.09),

        borderRadius:
            BorderRadius.circular(9),

        border: Border.all(
          color:
              AppColors.teacherIndigo
                  .withOpacity(0.18),
        ),
      ),

      child: Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          Icon(
            icon,

            color:
                AppColors.skyBlue,

            size:
                15,
          ),

          const SizedBox(
            width:
                5,
          ),

          Text(
            label,

            style: const TextStyle(
              color:
                  AppColors.skyBlue,

              fontSize:
                  10,

              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}


// =============================================================================
// SUBJECT
// =============================================================================

class _TeacherSubject
    extends StatelessWidget {

  final SocialSubject subject;


  const _TeacherSubject({
    required this.subject,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width:
          double.infinity,

      margin:
          const EdgeInsets.only(
        bottom: 8,
      ),

      padding:
          const EdgeInsets.all(11),

      decoration: BoxDecoration(
        color:
            AppColors.teacherIndigo
                .withOpacity(0.08),

        borderRadius:
            BorderRadius.circular(12),

        border: Border.all(
          color:
              AppColors.teacherIndigo
                  .withOpacity(0.18),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  subject.name,

                  style:
                      const TextStyle(
                    color:
                        AppColors.skyBlue,

                    fontSize:
                        13,

                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),

              if (subject.canHelp)
                Container(
                  margin:
                      const EdgeInsets.only(
                    right: 6,
                  ),

                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),

                  decoration: BoxDecoration(
                    color:
                        AppColors.skyBlue
                            .withOpacity(0.10),

                    borderRadius:
                        BorderRadius.circular(8),
                  ),

                  child:
                      const Text(
                    'AIUTO',

                    style:
                        TextStyle(
                      color:
                          AppColors.materialSky,

                      fontSize:
                          8,

                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

              if (subject.grade != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),

                  decoration: BoxDecoration(
                    color:
                        Colors.green
                            .withOpacity(0.12),

                    borderRadius:
                        BorderRadius.circular(8),
                  ),

                  child: Text(
                    '${subject.grade}/30',

                    style:
                        const TextStyle(
                      color:
                          Colors.green,

                      fontSize:
                          11,

                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          if (subject.note.isNotEmpty) ...[
            const SizedBox(
              height: 5,
            ),

            Text(
              subject.note,

              style: TextStyle(
                color:
                    AppColors.pureWhite
                        .withOpacity(0.55),

                fontSize:
                    12,

                height:
                    1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}


// =============================================================================
// REVIEW
// =============================================================================

class _ReviewSummary
    extends StatelessWidget {

  final SocialUser user;


  const _ReviewSummary({
    required this.user,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color:
            AppColors.brandNightBlue,

        borderRadius:
            BorderRadius.circular(12),
      ),

      child: Row(
        children: [
          const Icon(
            Icons.star_rounded,

            color:
                Colors.amber,

            size:
                20,
          ),

          const SizedBox(
            width:
                6,
          ),

          Text(
            user.averageRating
                .toStringAsFixed(1),

            style:
                const TextStyle(
              color:
                  AppColors.pureWhite,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            width:
                6,
          ),

          Text(
            '(${user.reviews.length} '
            '${user.reviews.length == 1 ? 'recensione' : 'recensioni'})',

            style: TextStyle(
              color:
                  AppColors.pureWhite
                      .withOpacity(0.50),

              fontSize:
                  12,
            ),
          ),
        ],
      ),
    );
  }
}