// =============================================================================
// TIPO UTENTE SOCIAL
// =============================================================================

enum SocialUserType {
  student,
  teacher,
}


// =============================================================================
// MATERIA SOCIAL
// =============================================================================

class SocialSubject {
  final int id;

  final String name;

  final String department;

  final String course;

  final int? grade;

  final String note;

  final bool canHelp;


  const SocialSubject({
    required this.id,
    required this.name,
    required this.department,
    required this.course,

    this.grade,

    this.note = '',

    this.canHelp = false,
  });


  // ===========================================================================
  // FROM JSON
  // ===========================================================================

  factory SocialSubject.fromJson(
    Map<String, dynamic> json,
  ) {
    /*
     * Il backend può restituire:
     *
     * {
     *   "id": 1,
     *   "grade": 28,
     *   "note": "...",
     *   "can_help": true,
     *   "subject": {
     *     "id": 1,
     *     "name": "Programmazione 1",
     *     "department": "DMI",
     *     "course": "Informatica"
     *   }
     * }
     *
     * oppure direttamente una Subject.
     */

    final Map<String, dynamic> subjectData;

    if (json['subject'] is Map) {
      subjectData =
          Map<String, dynamic>.from(
        json['subject'] as Map,
      );
    } else {
      subjectData = json;
    }


    return SocialSubject(
      id:
          _toInt(
            subjectData['id'],
          ) ??
          0,

      name:
          subjectData['name']
              ?.toString() ??
          '',

      department:
          subjectData['department']
              ?.toString() ??
          '',

      course:
          subjectData['course']
              ?.toString() ??
          '',

      grade:
          _toInt(
            json['grade'],
          ),

      note:
          json['note']
              ?.toString() ??
          '',

      canHelp:
          json['can_help']
                  as bool? ??
              false,
    );
  }


  // ===========================================================================
  // TO JSON
  // ===========================================================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'department': department,
      'course': course,
      'grade': grade,
      'note': note,
      'can_help': canHelp,
    };
  }


  // ===========================================================================
  // UTILITY
  // ===========================================================================

  static int? _toInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ?? '',
    );
  }
}


// =============================================================================
// RECENSIONE
// =============================================================================

class SocialReview {
  final String authorName;

  final double rating;

  final String comment;


  const SocialReview({
    required this.authorName,
    required this.rating,
    required this.comment,
  });


  factory SocialReview.fromJson(
    Map<String, dynamic> json,
  ) {
    return SocialReview(
      authorName:
          json['author_name']
              ?.toString() ??
          '',

      rating:
          (json['rating'] as num?)
                  ?.toDouble() ??
              0,

      comment:
          json['comment']
              ?.toString() ??
          '',
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'author_name': authorName,
      'rating': rating,
      'comment': comment,
    };
  }
}


// =============================================================================
// UTENTE SOCIAL
// =============================================================================

class SocialUser {
  final int id;

  final String firstName;

  final String lastName;

  final String email;

  final String department;

  final String course;

  final List<SocialSubject> subjects;

  final String description;

  final SocialUserType type;

  final bool available;

  final bool willingToTeach;

  final bool isActive;

  final List<SocialReview> reviews;


  const SocialUser({
    required this.id,

    required this.firstName,

    required this.lastName,

    required this.email,

    required this.department,

    required this.course,

    required this.subjects,

    required this.description,

    required this.type,

    required this.available,

    required this.willingToTeach,

    required this.isActive,

    this.reviews = const [],
  });


  // ===========================================================================
  // COMPATIBILITÀ CON LA UI ESISTENTE
  // ===========================================================================

  String get name {
    return '$firstName $lastName'.trim();
  }


  /*
   * Nel backend abbiamo department.
   *
   * Lo manteniamo come alias per non rompere
   * StudentHelpCard / TeacherHelpCard che
   * utilizzano ancora user.university.
   */
  String get university {
    return department;
  }


  /*
   * Alias temporaneo per la vecchia UI.
   *
   * In futuro conviene modificare direttamente
   * le card affinché usino willingToTeach.
   */
  bool get privateLessons {
    return willingToTeach;
  }


  String get role {
    switch (type) {
      case SocialUserType.teacher:
        return 'teacher';

      case SocialUserType.student:
        return 'student';
    }
  }


  // ===========================================================================
  // FROM JSON
  // ===========================================================================

  factory SocialUser.fromJson(
    Map<String, dynamic> json,
  ) {
    final List<SocialSubject> parsedSubjects =
        [];


    final dynamic subjectsData =
        json['subjects'];


    if (subjectsData is List) {
      for (final dynamic item
          in subjectsData) {
        if (item is Map) {
          parsedSubjects.add(
            SocialSubject.fromJson(
              Map<String, dynamic>.from(
                item,
              ),
            ),
          );
        }
      }
    }


    return SocialUser(
      id:
          _toInt(
            json['id'],
          ) ??
          0,

      firstName:
          json['first_name']
              ?.toString() ??
          '',

      lastName:
          json['last_name']
              ?.toString() ??
          '',

      email:
          json['email']
              ?.toString() ??
          '',

      department:
          json['department']
              ?.toString() ??
          '',

      course:
          json['course']
              ?.toString() ??
          '',

      subjects:
          parsedSubjects,

      description:
          json['description']
              ?.toString() ??
          '',

      type:
          _typeFromRole(
        json['role']
            ?.toString(),
      ),

      available:
          json['available']
                  as bool? ??
              false,

      willingToTeach:
          json['willing_to_teach']
                  as bool? ??
              false,

      isActive:
          json['is_active']
                  as bool? ??
              true,

      // Il backend recensioni non esiste ancora.
      reviews:
          const [],
    );
  }


  // ===========================================================================
  // TO JSON
  // ===========================================================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,

      'first_name':
          firstName,

      'last_name':
          lastName,

      'email':
          email,

      'department':
          department,

      'course':
          course,

      'description':
          description,

      'role':
          role,

      'available':
          available,

      'willing_to_teach':
          willingToTeach,

      'is_active':
          isActive,

      'subjects':
          subjects
              .map(
                (subject) =>
                    subject.toJson(),
              )
              .toList(),
    };
  }


  // ===========================================================================
  // RATING
  // ===========================================================================

  double get averageRating {
    if (reviews.isEmpty) {
      return 0;
    }


    final double total =
        reviews.fold<double>(
      0,

      (
        sum,
        review,
      ) =>
          sum +
          review.rating,
    );


    return total /
        reviews.length;
  }


  // ===========================================================================
  // UTILITY
  // ===========================================================================

  static SocialUserType _typeFromRole(
    String? role,
  ) {
    switch (
        role?.toLowerCase()) {
      case 'teacher':
        return SocialUserType.teacher;

      case 'student':
      default:
        return SocialUserType.student;
    }
  }


  static int? _toInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ?? '',
    );
  }
}


// =============================================================================
// DRAFT PROFILO SOCIAL
// =============================================================================

// =============================================================================
// DRAFT PROFILO SOCIAL
// =============================================================================

class SocialProfileDraft {
  final String firstName;

  final String lastName;

  final String email;

  // Utilizzata esclusivamente durante la registrazione.
  // Non viene mai inserita in SocialUser.
  final String password;

  final String department;

  final String course;

  final List<SocialSubject> subjects;

  final String description;

  final SocialUserType type;

  final bool available;

  final bool willingToTeach;


  const SocialProfileDraft({
    required this.firstName,

    required this.lastName,

    required this.email,

    required this.password,

    required this.department,

    required this.course,

    required this.subjects,

    required this.description,

    required this.type,

    required this.available,

    required this.willingToTeach,
  });


  String get name {
    return '$firstName $lastName'.trim();
  }


  String get university {
    return department;
  }


  bool get privateLessons {
    return willingToTeach;
  }


  String get role {
    switch (type) {
      case SocialUserType.student:
        return 'student';

      case SocialUserType.teacher:
        return 'teacher';
    }
  }


  // ===========================================================================
  // DRAFT -> SOCIAL USER
  // ===========================================================================

  SocialUser toSocialUser({
    required int id,
  }) {
    return SocialUser(
      id: id,

      firstName: firstName,

      lastName: lastName,

      email: email,

      department: department,

      course: course,

      subjects: subjects,

      description: description,

      type: type,

      available: available,

      willingToTeach: willingToTeach,

      isActive: true,
    );
  }
}


// =============================================================================
// MESSAGGIO CHAT
// =============================================================================

class ChatMessage {
  final String id;

  final String conversationId;

  final String senderId;

  final String text;

  final DateTime createdAt;

  final bool isRead;


  const ChatMessage({
    required this.id,

    required this.conversationId,

    required this.senderId,

    required this.text,

    required this.createdAt,

    this.isRead = false,
  });
}


// =============================================================================
// CONVERSAZIONE CHAT
// =============================================================================

class ChatConversation {
  final String id;

  final String user1Id;

  final String user2Id;

  final List<ChatMessage> messages;


  const ChatConversation({
    required this.id,

    required this.user1Id,

    required this.user2Id,

    required this.messages,
  });
}