import 'package:flutter/material.dart';

import '../../theme/nightTheme.dart';
import '../social_models.dart';
import '../booking/teacher_booking_page.dart';

class TeacherHelpCard extends StatelessWidget {
  final SocialUser teacher;

  const TeacherHelpCard({
    super.key,
    required this.teacher,
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
          color: AppColors.teacherIndigo.withOpacity(0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ============================================================
          // HEADER
          // ============================================================

          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.teacherIndigo,
                child: Text(
                  teacher.name.isNotEmpty
                      ? teacher.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teacher.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.pureWhite,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      'Insegnante',
                      style: TextStyle(
                        color: AppColors.pureWhite.withOpacity(0.55),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              if (teacher.available)
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

          // ============================================================
          // MATERIE
          // ============================================================

          if (teacher.subjects.isNotEmpty) ...[
            const Text(
              'Materie insegnate',
              style: TextStyle(
                color: AppColors.pureWhite,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 9),

            ...teacher.subjects.map(
              (subject) => _TeacherSubject(
                subject: subject,
              ),
            ),
          ],

          const SizedBox(height: 8),

          // ============================================================
          // DESCRIZIONE
          // ============================================================

          if (teacher.description.isNotEmpty)
            Text(
              teacher.description,
              style: TextStyle(
                color: AppColors.pureWhite.withOpacity(0.70),
                fontSize: 14,
                height: 1.4,
              ),
            ),

          const SizedBox(height: 12),

          // ============================================================
          // UNIVERSITÀ / CORSO
          // ============================================================

          Text(
            '${teacher.university} • ${teacher.course}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.pureWhite.withOpacity(0.45),
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 14),

          // ============================================================
          // RECENSIONI
          // ============================================================

          if (teacher.reviews.isNotEmpty)
            _TeacherReviewSummary(
              teacher: teacher,
            ),

          const SizedBox(height: 14),

          // ============================================================
          // LEZIONI PRIVATE
          // ============================================================

          if (teacher.privateLessons)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: AppColors.teacherIndigo.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.school_rounded,
                    color: AppColors.skyBlue,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Lezioni private disponibili',
                    style: TextStyle(
                      color: AppColors.skyBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // ============================================================
          // RICHIEDI LEZIONE
          // ============================================================

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: teacher.privateLessons
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TeacherBookingPage(
                            teacher: teacher,
                          ),
                        ),
                      );
                    }
                  : null,

              icon: const Icon(
                Icons.calendar_month_rounded,
              ),

              label: const Text(
                'Richiedi una lezione',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// MATERIA
// ============================================================================

class _TeacherSubject extends StatelessWidget {
  final SocialSubject subject;

  const _TeacherSubject({
    required this.subject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.teacherIndigo.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.teacherIndigo.withOpacity(0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.menu_book_outlined,
                color: AppColors.skyBlue,
                size: 17,
              ),

              const SizedBox(width: 7),

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
            ],
          ),

          if (subject.note.isNotEmpty) ...[
            const SizedBox(height: 5),

            Text(
              subject.note,
              style: TextStyle(
                color: AppColors.pureWhite.withOpacity(0.55),
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

// ============================================================================
// RECENSIONI
// ============================================================================

class _TeacherReviewSummary extends StatelessWidget {
  final SocialUser teacher;

  const _TeacherReviewSummary({
    required this.teacher,
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
            teacher.averageRating.toStringAsFixed(1),
            style: const TextStyle(
              color: AppColors.pureWhite,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(width: 6),

          Text(
            '(${teacher.reviews.length} '
            '${teacher.reviews.length == 1 ? 'recensione' : 'recensioni'})',
            style: TextStyle(
              color: AppColors.pureWhite.withOpacity(0.50),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}