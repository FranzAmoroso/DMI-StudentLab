import 'package:flutter/material.dart';

import '../../theme/nightTheme.dart';
import '../social_models.dart';

class SocialProfilePreview extends StatelessWidget {
  final SocialProfileDraft draft;

  const SocialProfilePreview({
    super.key,
    required this.draft,
  });

  @override
  Widget build(BuildContext context) {
    final bool isTeacher =
        draft.type == SocialUserType.teacher;

    return Scaffold(
      backgroundColor: AppColors.darkElegance,

      appBar: AppBar(
        backgroundColor: AppColors.brandNightBlue,
        foregroundColor: AppColors.pureWhite,
        elevation: 0,
        title: const Text(
          'Anteprima profilo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: SafeArea(
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double width =
                  constraints.maxWidth > 700
                      ? 650
                      : constraints.maxWidth;

              return SizedBox(
                width: width,

                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,

                    children: [


                      const Text(
                        'Così apparirà il tuo profilo',
                        textAlign: TextAlign.center,

                        style: TextStyle(
                          color: AppColors.pureWhite,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Controlla le informazioni prima di pubblicarlo.',

                        textAlign: TextAlign.center,

                        style: TextStyle(
                          color: AppColors.pureWhite
                              .withOpacity(0.55),
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 24),


                      _ProfileCard(
                        draft: draft,
                        isTeacher: isTeacher,
                      ),

                      const SizedBox(height: 28),

                      SizedBox(
                        height: 54,

                        child: ElevatedButton.icon(
                          onPressed: () {
                            final SocialUser user =
                                draft.toSocialUser(
                              id: DateTime.now()
                                  .millisecondsSinceEpoch
                                  .toString(),
                            );

                            debugPrint(
                              'Profilo creato: ${user.name}',
                            );

                            Navigator.pop(
                              context,
                              user,
                            );
                          },

                          icon: const Icon(
                            Icons.check_rounded,
                          ),

                          label: const Text(
                            'Conferma e pubblica',
                            style: TextStyle(
                              fontSize: 16,
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
                                      16),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // =====================================================
                      // MODIFICA
                      // =====================================================

                      SizedBox(
                        height: 50,

                        child:
                            OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },

                          icon: const Icon(
                            Icons.edit_outlined,
                          ),

                          label: const Text(
                            'Modifica profilo',
                          ),

                          style:
                              OutlinedButton.styleFrom(
                            foregroundColor:
                                AppColors.pureWhite,

                            side: BorderSide(
                              color: AppColors.pureWhite
                                  .withOpacity(0.20),
                            ),

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
}

// ============================================================================
// PROFILE CARD
// ============================================================================

class _ProfileCard extends StatelessWidget {
  final SocialProfileDraft draft;
  final bool isTeacher;

  const _ProfileCard({
    required this.draft,
    required this.isTeacher,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: AppColors.eleganceDeepNavy,

        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color: isTeacher
              ? AppColors.teacherIndigo
                  .withOpacity(0.35)
              : AppColors.socialBlue
                  .withOpacity(0.35),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Row(
            children: [

              CircleAvatar(
                radius: 25,

                backgroundColor: isTeacher
                    ? AppColors.teacherIndigo
                    : AppColors.studentBlue,

                child: Text(
                  draft.name.isNotEmpty
                      ? draft.name[0].toUpperCase()
                      : '?',

                  style: const TextStyle(
                    color:
                        AppColors.pureWhite,
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Text(
                      draft.name.isNotEmpty
                          ? draft.name
                          : 'Nome non inserito',

                      maxLines: 1,

                      overflow:
                          TextOverflow.ellipsis,

                      style: const TextStyle(
                        color:
                            AppColors.pureWhite,
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      isTeacher
                          ? 'Insegnante'
                          : 'Studente',

                      style: TextStyle(
                        color: AppColors.pureWhite
                            .withOpacity(0.55),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              if (draft.available)
                const Row(
                  children: [

                    Icon(
                      Icons.circle,
                      color: Colors.green,
                      size: 9,
                    ),

                    SizedBox(width: 5),

                    Text(
                      'Disponibile',

                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 18),
          if (draft.subjects.isNotEmpty) ...[
            Text(
              isTeacher
                  ? 'Materie insegnate'
                  : 'Materie',

              style: const TextStyle(
                color: AppColors.pureWhite,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 9),

            ...draft.subjects.map(
              (subject) => _SubjectPreview(
                subject: subject,
                isTeacher: isTeacher,
              ),
            ),
          ],

          if (draft.subjects.isEmpty)
            Text(
              'Nessuna materia inserita.',

              style: TextStyle(
                color: AppColors.pureWhite
                    .withOpacity(0.45),
                fontSize: 13,
              ),
            ),

          if (draft.description.isNotEmpty) ...[
            const SizedBox(height: 8),

            Text(
              draft.description,

              style: TextStyle(
                color: AppColors.pureWhite
                    .withOpacity(0.70),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],

          const SizedBox(height: 12),

          Text(
            '${draft.university} • ${draft.course}',

            maxLines: 2,

            overflow:
                TextOverflow.ellipsis,

            style: TextStyle(
              color: AppColors.pureWhite
                  .withOpacity(0.45),
              fontSize: 12,
            ),
          ),

          if (isTeacher &&
              draft.privateLessons) ...[
            const SizedBox(height: 14),

            Container(
              width: double.infinity,

              padding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 9,
              ),

              decoration: BoxDecoration(
                color: AppColors.teacherIndigo
                    .withOpacity(0.12),

                borderRadius:
                    BorderRadius.circular(10),
              ),

              child: const Row(
                children: [

                  Icon(
                    Icons.school_rounded,
                    color:
                        AppColors.skyBlue,
                    size: 18,
                  ),

                  SizedBox(width: 8),

                  Text(
                    'Lezioni private disponibili',

                    style: TextStyle(
                      color:
                          AppColors.skyBlue,
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),


          Container(
            padding:
                const EdgeInsets.all(12),

            decoration: BoxDecoration(
              color:
                  AppColors.brandNightBlue,

              borderRadius:
                  BorderRadius.circular(12),
            ),

            child: const Row(
              children: [

                Icon(
                  Icons.star_rounded,
                  color: Colors.amber,
                  size: 20,
                ),

                SizedBox(width: 6),

                Text(
                  'Nessuna recensione',

                  style: TextStyle(
                    color:
                        AppColors.pureWhite,
                    fontSize: 12,
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


class _SubjectPreview extends StatelessWidget {
  final SocialSubject subject;
  final bool isTeacher;

  const _SubjectPreview({
    required this.subject,
    required this.isTeacher,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      margin:
          const EdgeInsets.only(bottom: 8),

      padding:
          const EdgeInsets.all(11),

      decoration: BoxDecoration(
        color: isTeacher
            ? AppColors.teacherIndigo
                .withOpacity(0.08)
            : AppColors.socialBlue
                .withOpacity(0.08),

        borderRadius:
            BorderRadius.circular(12),

        border: Border.all(
          color: isTeacher
              ? AppColors.teacherIndigo
                  .withOpacity(0.18)
              : AppColors.socialBlue
                  .withOpacity(0.18),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [


          Row(
            children: [

              Icon(
                Icons.menu_book_outlined,

                color:
                    AppColors.skyBlue,

                size: 17,
              ),

              const SizedBox(width: 7),

              Expanded(
                child: Text(
                  subject.name,

                  style: const TextStyle(
                    color:
                        AppColors.skyBlue,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),


              if (!isTeacher &&
                  subject.grade != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),

                  decoration:
                      BoxDecoration(
                    color: Colors.green
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
                      fontSize: 11,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          if (subject.note.isNotEmpty) ...[
            const SizedBox(height: 5),

            Text(
              subject.note,

              style: TextStyle(
                color: AppColors.pureWhite
                    .withOpacity(0.55),

                fontSize: 12,

                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}