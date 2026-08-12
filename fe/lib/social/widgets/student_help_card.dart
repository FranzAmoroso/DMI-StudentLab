import 'package:flutter/material.dart';

import '../../theme/nightTheme.dart';
import '../social_models.dart';

class StudentHelpCard extends StatelessWidget {
  final SocialUser student;

  const StudentHelpCard({
    super.key,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: AppColors.eleganceDeepNavy,
        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: AppColors.studentBlue.withOpacity(0.30),
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [

              CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.studentBlue,

                child: Text(
                  student.name.isNotEmpty
                      ? student.name[0].toUpperCase()
                      : '?',

                  style: const TextStyle(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.bold,
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
                      student.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        color: AppColors.pureWhite,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Text(
                      'Studente',
                      style: TextStyle(
                        color: AppColors.pureWhite
                            .withOpacity(0.55),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              if (student.available)
                Row(
                  children: [

                    const Icon(
                      Icons.circle,
                      color: Colors.green,
                      size: 9,
                    ),

                    const SizedBox(width: 5),

                    Text(
                      'Disponibile',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 16),

          if (student.subjects.isNotEmpty) ...[
            const Text(
              'Materie',
              style: TextStyle(
                color: AppColors.pureWhite,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            ...student.subjects.map(
              (subject) => _StudentSubject(
                subject: subject,
              ),
            ),
          ],

          const SizedBox(height: 8),
          if (student.description.isNotEmpty) ...[
            Text(
              student.description,

              style: TextStyle(
                color: AppColors.pureWhite
                    .withOpacity(0.70),
                fontSize: 14,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 12),
          ],


          Text(
            '${student.university} • ${student.course}',

            maxLines: 2,
            overflow: TextOverflow.ellipsis,

            style: TextStyle(
              color: AppColors.pureWhite
                  .withOpacity(0.45),
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 14),

          if (student.reviews.isNotEmpty)
            _ReviewSummary(
              user: student,
            ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,

            child: ElevatedButton.icon(
              onPressed: () {
                // TODO:
                // Aprire profilo completo
                // oppure chat
              },

              icon: const Icon(
                Icons.chat_bubble_outline,
              ),

              label: const Text(
                'Contatta',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentSubject extends StatelessWidget {
  final SocialSubject subject;

  const _StudentSubject({
    required this.subject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(bottom: 8),

      padding: const EdgeInsets.all(11),

      decoration: BoxDecoration(
        color: AppColors.socialBlue.withOpacity(0.08),

        borderRadius: BorderRadius.circular(12),

        border: Border.all(
          color: AppColors.socialBlue.withOpacity(0.18),
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

                  style: const TextStyle(
                    color: AppColors.skyBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
                    color: Colors.green
                        .withOpacity(0.12),

                    borderRadius:
                        BorderRadius.circular(8),
                  ),

                  child: Text(
                    '${subject.grade}/30',

                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
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

class _ReviewSummary extends StatelessWidget {
  final SocialUser user;

  const _ReviewSummary({
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: AppColors.brandNightBlue,

        borderRadius: BorderRadius.circular(12),
      ),

      child: Row(
        children: [

          const Icon(
            Icons.star_rounded,
            color: Colors.amber,
            size: 20,
          ),

          const SizedBox(width: 6),

          Text(
            user.averageRating.toStringAsFixed(1),

            style: const TextStyle(
              color: AppColors.pureWhite,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(width: 6),

          Text(
            '(${user.reviews.length} '
            '${user.reviews.length == 1 ? 'recensione' : 'recensioni'})',

            style: TextStyle(
              color: AppColors.pureWhite
                  .withOpacity(0.50),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}