enum SocialUserType {
  student,
  teacher,
}


class SocialSubject {
  final String name;

  final int? grade;

  /// Nota personale relativa alla materia.
  final String note;

  const SocialSubject({
    required this.name,
    this.grade,
    this.note = '',
  });
}


class SocialReview {
  final String authorName;
  final double rating;
  final String comment;

  const SocialReview({
    required this.authorName,
    required this.rating,
    required this.comment,
  });
}


class SocialUser {
  final String id;

  final String name;

  final String university;

  final String course;

  final List<SocialSubject> subjects;

  final String description;

  final SocialUserType type;

  final bool available;

  final bool privateLessons;

  final List<SocialReview> reviews;

  const SocialUser({
    required this.id,
    required this.name,
    required this.university,
    required this.course,
    required this.subjects,
    required this.description,
    required this.type,
    required this.available,
    required this.privateLessons,
    this.reviews = const [],
  });

  /// Media delle recensioni.
  double get averageRating {
    if (reviews.isEmpty) {
      return 0;
    }

    final total = reviews.fold<double>(
      0,
      (sum, review) => sum + review.rating,
    );

    return total / reviews.length;
  }
}


class SocialProfileDraft {
  final String name;

  final String university;

  final String course;

  final List<SocialSubject> subjects;

  final String description;

  final SocialUserType type;

  final bool available;

  final bool privateLessons;

  const SocialProfileDraft({
    required this.name,
    required this.university,
    required this.course,
    required this.subjects,
    required this.description,
    required this.type,
    required this.available,
    required this.privateLessons,
  });

  /// Trasforma il Draft nel profilo definitivo.
  SocialUser toSocialUser({
    required String id,
  }) {
    return SocialUser(
      id: id,
      name: name,
      university: university,
      course: course,
      subjects: subjects,
      description: description,
      type: type,
      available: available,
      privateLessons: privateLessons,
    );
  }
}

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

class ChatConversation {
  final String id;
  final String user1Id;
  final String user2Id;
  final List<ChatMessage> messages;

  ChatConversation({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.messages,
  });
}