import 'package:flutter/material.dart';

import '../../theme/nightTheme.dart';
import '../social_models.dart';

class StudentLabUserAvatar extends StatelessWidget {
  static const String studentAsset =
      'asset/mascot/student_profile.png';
  static const String teacherAsset =
      'asset/mascot/teacher_profile.png';

  final SocialUserType type;
  final double radius;

  const StudentLabUserAvatar({
    super.key,
    required this.type,
    this.radius = 25,
  });

  bool get _isTeacher =>
      type == SocialUserType.teacher;

  @override
  Widget build(BuildContext context) {
    final String assetPath =
        _isTeacher ? teacherAsset : studentAsset;

    return Semantics(
      image: true,
      label: _isTeacher
          ? 'Immagine profilo insegnante'
          : 'Immagine profilo studente',
      child: CircleAvatar(
        radius: radius,
        backgroundColor: _isTeacher
            ? AppColors.teacherIndigo
            : AppColors.studentBlue,
        child: ClipOval(
          child: Image.asset(
            assetPath,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (
              BuildContext context,
              Object error,
              StackTrace? stackTrace,
            ) {
              return SizedBox(
                width: radius * 2,
                height: radius * 2,
                child: Icon(
                  _isTeacher
                      ? Icons.cast_for_education_rounded
                      : Icons.school_rounded,
                  color: AppColors.pureWhite,
                  size: radius,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}