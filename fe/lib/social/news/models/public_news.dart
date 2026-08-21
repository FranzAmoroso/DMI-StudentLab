class PublicNewsUser {
  final int id;
  final String firstName;
  final String lastName;
  final String role;
  final String teacherVerificationStatus;

  const PublicNewsUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.teacherVerificationStatus,
  });

  String get fullName {
    final String value = [
      firstName.trim(),
      lastName.trim(),
    ].where((String part) => part.isNotEmpty).join(' ');

    return value.isEmpty ? 'Utente StudentLab' : value;
  }

  bool get isVerifiedTeacher {
    return role == 'teacher' &&
        teacherVerificationStatus == 'verified';
  }

  bool get isAdmin {
    return role == 'admin';
  }

  bool get isCreator {
    return role == 'creator';
  }

  String get roleLabel {
    if (isCreator) {
      return 'Creator';
    }

    if (isAdmin) {
      return 'Admin';
    }

    if (isVerifiedTeacher) {
      return 'Docente verificato';
    }

    if (role == 'teacher') {
      return 'Docente';
    }

    return 'Studente';
  }

  factory PublicNewsUser.fromJson(Map<String, dynamic> json) {
    return PublicNewsUser(
      id: _toInt(json['id']) ?? 0,
      firstName: json['first_name']?.toString().trim() ?? '',
      lastName: json['last_name']?.toString().trim() ?? '',
      role: json['role']?.toString().trim().toLowerCase() ?? 'student',
      teacherVerificationStatus:
          json['teacher_verification_status']?.toString().trim().toLowerCase() ??
              '',
    );
  }

  static int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '');
  }
}

class PublicNews {
  final int id;
  final int authorUserId;
  final String title;
  final String content;
  final String city;
  final String university;
  final String department;
  final String course;
  final int? subjectId;
  final String subjectName;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final PublicNewsUser author;
  final bool canDelete;
  final bool canModerate;
  final bool canReport;
  final bool canBlockAuthor;

  const PublicNews({
    required this.id,
    required this.authorUserId,
    required this.title,
    required this.content,
    required this.city,
    required this.university,
    required this.department,
    required this.course,
    required this.subjectId,
    required this.subjectName,
    required this.createdAt,
    required this.expiresAt,
    required this.author,
    required this.canDelete,
    required this.canModerate,
    required this.canReport,
    required this.canBlockAuthor,
  });

  String get academicContext {
    final List<String> values = [
      city.trim(),
      university.trim(),
      department.trim(),
      course.trim(),
      subjectName.trim(),
    ].where((String value) => value.isNotEmpty).toList();

    return values.isEmpty ? 'StudentLab' : values.join(' • ');
  }

  bool get isExpired {
    final DateTime? value = expiresAt;
    return value != null && !value.isAfter(DateTime.now());
  }

  bool get needsDedicatedPage {
    return content.trim().length > 260 || title.trim().length > 90;
  }

  factory PublicNews.fromJson(Map<String, dynamic> json) {
    final dynamic authorData = json['author'];

    if (authorData is! Map) {
      throw const FormatException('Autore della news non disponibile.');
    }

    return PublicNews(
      id: _toInt(json['id']) ?? 0,
      authorUserId: _toInt(json['author_user_id']) ?? 0,
      title: json['title']?.toString().trim() ?? '',
      content: json['content']?.toString().trim() ?? '',
      city: json['city']?.toString().trim() ?? '',
      university: json['university']?.toString().trim() ?? '',
      department: json['department']?.toString().trim() ?? '',
      course: json['course']?.toString().trim() ?? '',
      subjectId: _toInt(json['subject_id']),
      subjectName: json['subject_name']?.toString().trim() ?? '',
      createdAt: _parseDate(json['created_at']),
      expiresAt: _parseNullableDate(json['expires_at']),
      author: PublicNewsUser.fromJson(
        Map<String, dynamic>.from(authorData),
      ),
      canDelete: json['can_delete'] == true,
      canModerate: json['can_moderate'] == true,
      canReport: json['can_report'] == true,
      canBlockAuthor: json['can_block_author'] == true,
    );
  }

  static DateTime _parseDate(dynamic value) {
    final DateTime? parsed = DateTime.tryParse(value?.toString() ?? '');

    if (parsed == null) {
      throw const FormatException('Data della news non valida.');
    }

    return parsed.toLocal();
  }

  static DateTime? _parseNullableDate(dynamic value) {
    final String normalized = value?.toString().trim() ?? '';

    if (normalized.isEmpty) {
      return null;
    }

    return DateTime.tryParse(normalized)?.toLocal();
  }

  static int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '');
  }
}