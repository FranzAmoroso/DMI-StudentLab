import 'package:flutter/material.dart';

import '../../theme/nightTheme.dart';

import '../social_models.dart';

import '../message/contact_user_page.dart';

class StudentHelpCard extends StatelessWidget {
  final SocialUser student;

  const StudentHelpCard({super.key, required this.student});

  List<SocialSubject> get _helpSubjects {
    return student.subjects
        .where((SocialSubject subject) => subject.canHelp)
        .toList();
  }

  List<SocialSubject> get _privateLessonSubjects {
    return student.subjects
        .where((SocialSubject subject) => subject.canGivePrivateLessons)
        .toList();
  }

  SocialAcademicPath? get _primaryAcademicPath {
    for (final SocialAcademicPath path in student.academicPaths) {
      if (path.status != AcademicPathStatus.graduated && path.isCurrent) {
        return path;
      }
    }

    for (final SocialAcademicPath path in student.academicPaths) {
      if (path.status != AcademicPathStatus.graduated && path.isPrimary) {
        return path;
      }
    }

    for (final SocialAcademicPath path in student.academicPaths) {
      if (path.status != AcademicPathStatus.graduated) {
        return path;
      }
    }

    return null;
  }

  SocialAcademicTitle? get _primaryAcademicTitle {
    return student.primaryAcademicTitle;
  }

  SocialAcademicPath? get _graduatedAcademicPath {
    SocialAcademicPath? firstGraduated;

    for (final SocialAcademicPath path in student.academicPaths) {
      if (path.status != AcademicPathStatus.graduated) {
        continue;
      }

      firstGraduated ??= path;

      if (path.isPrimary && path.isVerified) {
        return path;
      }
    }

    if (firstGraduated != null) {
      return firstGraduated;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final SocialAcademicPath? path = _primaryAcademicPath;

    final SocialAcademicTitle? title = _primaryAcademicTitle;

    final SocialAcademicPath? graduatedPath = _graduatedAcademicPath;

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: AppColors.eleganceDeepNavy,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: AppColors.studentBlue.withValues(alpha: 0.30),
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
                  student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',

                  style: const TextStyle(
                    color: AppColors.pureWhite,

                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

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

                    const SizedBox(height: 4),

                    _AcademicIdentity(
                      path: path,

                      title: title,

                      graduatedPath: graduatedPath,
                    ),
                  ],
                ),
              ),

              if (student.available) const _AvailableBadge(),
            ],
          ),

          const SizedBox(height: 16),

          Wrap(
            spacing: 8,

            runSpacing: 8,

            children: [
              if (student.availableForHelp)
                const _CapabilityChip(
                  icon: Icons.volunteer_activism_outlined,

                  label: 'Aiuto allo studio',
                ),

              if (student.availableForPrivateLessons)
                const _CapabilityChip(
                  icon: Icons.school_outlined,

                  label: 'Lezioni private',
                ),
            ],
          ),

          if (title != null || graduatedPath != null || path != null) ...[
            const SizedBox(height: 16),

            _CompactAcademicSummary(
              title: title,

              graduatedPath: graduatedPath,

              path: path,
            ),
          ],

          if (_helpSubjects.isNotEmpty) ...[
            const SizedBox(height: 18),

            const Text(
              'Può aiutarti in',

              style: TextStyle(
                color: AppColors.pureWhite,

                fontSize: 13,

                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            ..._helpSubjects.map(
              (SocialSubject subject) => _StudentSubject(
                subject: subject,

                type: _StudentSubjectType.help,
              ),
            ),
          ],

          if (_privateLessonSubjects.isNotEmpty) ...[
            const SizedBox(height: 18),

            const Text(
              'Lezioni private in',

              style: TextStyle(
                color: AppColors.pureWhite,

                fontSize: 13,

                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            ..._privateLessonSubjects.map(
              (SocialSubject subject) => _StudentSubject(
                subject: subject,

                type: _StudentSubjectType.privateLesson,
              ),
            ),
          ],

          if (student.description.isNotEmpty) ...[
            const SizedBox(height: 14),

            Text(
              student.description,

              style: TextStyle(
                color: AppColors.pureWhite.withValues(alpha: 0.70),

                fontSize: 14,

                height: 1.4,
              ),
            ),
          ],

          if (student.reviews.isNotEmpty) ...[
            const SizedBox(height: 14),

            _ReviewSummary(user: student),
          ],

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,

            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ContactUserPage(user: student),
                  ),
                );
              },

              icon: const Icon(Icons.mail_outline_rounded),

              label: const Text('Contatta'),

              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.studentBlue,

                foregroundColor: AppColors.pureWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _StudentSubjectType { help, privateLesson }

class _AcademicIdentity extends StatelessWidget {
  final SocialAcademicPath? path;

  final SocialAcademicTitle? title;

  final SocialAcademicPath? graduatedPath;

  const _AcademicIdentity({
    required this.path,

    required this.title,

    required this.graduatedPath,
  });

  @override
  Widget build(BuildContext context) {
    final SocialAcademicPath? academicPath = path;

    if (academicPath != null) {
      String label;

      switch (academicPath.status) {
        case AcademicPathStatus.enrolled:
          label = 'Studente in ${academicPath.course}';

        case AcademicPathStatus.suspended:
          label = 'Percorso in ${academicPath.course} sospeso';

        case AcademicPathStatus.withdrawn:
          label = 'Percorso in ${academicPath.course} interrotto';

        case AcademicPathStatus.transferred:
          label = 'Trasferito da ${academicPath.course}';

        case AcademicPathStatus.graduated:
          label = 'Titolo conseguito in ${academicPath.course}';
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Icon(
            Icons.school_outlined,

            color: AppColors.studentBlue,

            size: 14,
          ),

          const SizedBox(width: 5),

          Expanded(
            child: Text(
              label,

              maxLines: 2,

              overflow: TextOverflow.ellipsis,

              style: const TextStyle(
                color: AppColors.studentBlue,

                fontSize: 11,

                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          if (academicPath.isVerified) ...[
            const SizedBox(width: 5),

            const Icon(
              Icons.verified_rounded,

              color: Colors.greenAccent,

              size: 14,
            ),
          ],
        ],
      );
    }

    final SocialAcademicTitle? academicTitle = title;

    if (academicTitle != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Icon(
            Icons.workspace_premium_outlined,

            color: Colors.amber,

            size: 14,
          ),

          const SizedBox(width: 5),

          Expanded(
            child: Text(
              '${academicTitle.titleTypeLabel} in ${academicTitle.course}',

              maxLines: 2,

              overflow: TextOverflow.ellipsis,

              style: const TextStyle(
                color: AppColors.studentBlue,

                fontSize: 11,

                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          if (academicTitle.isVerified) ...[
            const SizedBox(width: 5),

            const Icon(
              Icons.verified_rounded,

              color: Colors.greenAccent,

              size: 14,
            ),
          ],
        ],
      );
    }

    final SocialAcademicPath? legacyGraduatedPath = graduatedPath;

    if (legacyGraduatedPath != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Icon(
            Icons.workspace_premium_outlined,

            color: Colors.amber,

            size: 14,
          ),

          const SizedBox(width: 5),

          Expanded(
            child: Text(
              legacyGraduatedPath.degreeType.trim().isEmpty
                  ? 'Titolo conseguito in ${legacyGraduatedPath.course}'
                  : '${academicPathTypeLabel(legacyGraduatedPath.degreeType)} in ${legacyGraduatedPath.course}',

              maxLines: 2,

              overflow: TextOverflow.ellipsis,

              style: const TextStyle(
                color: AppColors.studentBlue,

                fontSize: 11,

                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          if (legacyGraduatedPath.isVerified) ...[
            const SizedBox(width: 5),

            const Icon(
              Icons.verified_rounded,

              color: Colors.greenAccent,

              size: 14,
            ),
          ],
        ],
      );
    }

    return const Text(
      'Studente',

      style: TextStyle(
        color: AppColors.studentBlue,

        fontSize: 12,

        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _CompactAcademicSummary extends StatelessWidget {
  final SocialAcademicTitle? title;
  final SocialAcademicPath? graduatedPath;
  final SocialAcademicPath? path;

  const _CompactAcademicSummary({
    required this.title,
    required this.graduatedPath,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasTitle = title != null || graduatedPath != null;
    final bool hasPath = path != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasTitle)
          _AcademicSummaryCard(
            borderColor: Colors.amber.withValues(alpha: 0.18),
            child: title != null
                ? _CompactAcademicTitleRow(title: title!)
                : _CompactGraduatedPathRow(path: graduatedPath!),
          ),
        if (hasTitle && hasPath) const SizedBox(height: 10),
        if (hasPath)
          _AcademicSummaryCard(
            borderColor: AppColors.skyBlue.withValues(alpha: 0.14),
            child: _CompactAcademicPathRow(path: path!),
          ),
      ],
    );
  }
}

class _AcademicSummaryCard extends StatelessWidget {
  final Widget child;
  final Color borderColor;

  const _AcademicSummaryCard({required this.child, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.brandNightBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

class _CompactAcademicTitleRow extends StatelessWidget {
  final SocialAcademicTitle title;

  const _CompactAcademicTitleRow({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        const Icon(
          Icons.workspace_premium_outlined,

          color: Colors.amber,

          size: 16,
        ),

        const SizedBox(width: 7),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                title.titleTypeLabel,

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: const TextStyle(
                  color: AppColors.pureWhite,

                  fontSize: 11,

                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                title.course,

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: TextStyle(
                  color: AppColors.pureWhite.withValues(alpha: 0.45),

                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),

        if (title.isVerified)
          const Icon(
            Icons.verified_rounded,

            color: Colors.greenAccent,

            size: 14,
          ),
      ],
    );
  }
}

class _CompactGraduatedPathRow extends StatelessWidget {
  final SocialAcademicPath path;

  const _CompactGraduatedPathRow({required this.path});

  @override
  Widget build(BuildContext context) {
    final String title = path.degreeType.trim().isEmpty
        ? 'Titolo conseguito'
        : academicPathTypeLabel(path.degreeType);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        const Icon(
          Icons.workspace_premium_outlined,

          color: Colors.amber,

          size: 16,
        ),

        const SizedBox(width: 7),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                title,

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: const TextStyle(
                  color: AppColors.pureWhite,

                  fontSize: 11,

                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                path.course,

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: TextStyle(
                  color: AppColors.pureWhite.withValues(alpha: 0.45),

                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),

        if (path.isVerified)
          const Icon(
            Icons.verified_rounded,

            color: Colors.greenAccent,

            size: 14,
          ),
      ],
    );
  }
}

class _CompactAcademicPathRow extends StatelessWidget {
  final SocialAcademicPath path;

  const _CompactAcademicPathRow({required this.path});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        const Icon(Icons.school_outlined, color: AppColors.skyBlue, size: 16),

        const SizedBox(width: 7),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                path.course,

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: const TextStyle(
                  color: AppColors.pureWhite,

                  fontSize: 11,

                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                _compactPathStatus(path.status),

                style: TextStyle(
                  color: AppColors.materialSky.withValues(alpha: 0.80),

                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),

        if (path.isVerified)
          const Icon(
            Icons.verified_rounded,

            color: Colors.greenAccent,

            size: 14,
          ),
      ],
    );
  }

  String _compactPathStatus(AcademicPathStatus status) {
    switch (status) {
      case AcademicPathStatus.enrolled:
        return 'Percorso in corso';

      case AcademicPathStatus.suspended:
        return 'Percorso sospeso';

      case AcademicPathStatus.withdrawn:
        return 'Percorso interrotto';

      case AcademicPathStatus.transferred:
        return 'Trasferito';

      case AcademicPathStatus.graduated:
        return 'Titolo conseguito';
    }
  }
}

class _AvailableBadge extends StatelessWidget {
  const _AvailableBadge();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,

      children: [
        Icon(Icons.circle, color: Colors.green, size: 9),

        SizedBox(width: 5),

        Text(
          'Disponibile',

          style: TextStyle(color: Colors.green, fontSize: 11),
        ),
      ],
    );
  }
}

class _CapabilityChip extends StatelessWidget {
  final IconData icon;

  final String label;

  const _CapabilityChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),

      decoration: BoxDecoration(
        color: AppColors.skyBlue.withValues(alpha: 0.08),

        borderRadius: BorderRadius.circular(9),

        border: Border.all(color: AppColors.skyBlue.withValues(alpha: 0.15)),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Icon(icon, color: AppColors.materialSky, size: 15),

          const SizedBox(width: 5),

          Text(
            label,

            style: const TextStyle(
              color: AppColors.materialSky,

              fontSize: 10,

              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentSubject extends StatelessWidget {
  final SocialSubject subject;

  final _StudentSubjectType type;

  const _StudentSubject({required this.subject, required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(bottom: 8),

      padding: const EdgeInsets.all(11),

      decoration: BoxDecoration(
        color: AppColors.socialBlue.withValues(alpha: 0.08),

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: AppColors.socialBlue.withValues(alpha: 0.18)),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

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

              _SubjectCapabilityBadge(type: type),

              if (subject.grade != null && subject.isGradeVerified) ...[
                const SizedBox(width: 6),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,

                    vertical: 4,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),

                    borderRadius: BorderRadius.circular(8),
                  ),

                  child: Row(
                    mainAxisSize: MainAxisSize.min,

                    children: [
                      const Icon(
                        Icons.verified_rounded,

                        color: Colors.greenAccent,

                        size: 11,
                      ),

                      const SizedBox(width: 3),

                      Text(
                        '${subject.grade}/30',

                        style: const TextStyle(
                          color: Colors.greenAccent,

                          fontSize: 10,

                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          if (subject.note.isNotEmpty) ...[
            const SizedBox(height: 5),

            Text(
              subject.note,

              style: TextStyle(
                color: AppColors.pureWhite.withValues(alpha: 0.55),

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

class _SubjectCapabilityBadge extends StatelessWidget {
  final _StudentSubjectType type;

  const _SubjectCapabilityBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final bool help = type == _StudentSubjectType.help;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),

      decoration: BoxDecoration(
        color: AppColors.skyBlue.withValues(alpha: 0.10),

        borderRadius: BorderRadius.circular(8),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Icon(
            help ? Icons.volunteer_activism_outlined : Icons.school_outlined,

            color: AppColors.materialSky,

            size: 10,
          ),

          const SizedBox(width: 4),

          Text(
            help ? 'AIUTO' : 'LEZIONI',

            style: const TextStyle(
              color: AppColors.materialSky,

              fontSize: 8,

              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewSummary extends StatelessWidget {
  final SocialUser user;

  const _ReviewSummary({required this.user});

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
          const Icon(Icons.star_rounded, color: Colors.amber, size: 20),

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
              color: AppColors.pureWhite.withValues(alpha: 0.50),

              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
