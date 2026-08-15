class StudyGroup {
  final int id;

  final String name;

  final String description;

  final int? subjectId;

  final String subject;

  final String course;

  final String department;

  final int memberCount;

  final int materialCount;

  final bool isPrivate;

  final bool isOwner;


  const StudyGroup({
    required this.id,

    required this.name,

    required this.description,

    required this.subjectId,

    required this.subject,

    required this.course,

    required this.department,

    required this.memberCount,

    required this.materialCount,

    required this.isPrivate,

    required this.isOwner,
  });


  // ===========================================================================
  // FROM JSON
  // ===========================================================================

factory StudyGroup.fromJson(
  Map<String, dynamic> json, {
  int? currentUserId,
}) {
  final dynamic membersData =
      json['members'];

  final int memberCount =
      membersData is List
          ? membersData.length
          : _toInt(
                json['member_count'],
              ) ??
              0;

  final int? createdBy =
      _toInt(
    json['created_by'],
  );

  final bool isOwner =
      currentUserId != null &&
      createdBy == currentUserId;

  String subjectName = '';

  final dynamic subjectData =
      json['subject'];

  if (subjectData is Map) {
    subjectName =
        subjectData['name']
            ?.toString() ??
        '';
  } else {
    subjectName =
        json['subject_name']
            ?.toString() ??
        '';
  }

  return StudyGroup(
    id:
        _toInt(
          json['id'],
        ) ??
        0,

    name:
        json['name']?.toString() ??
        '',

    description:
        json['description']
                ?.toString() ??
            '',

    subjectId:
        _toInt(
      json['subject_id'],
    ),

    subject:
        subjectName,

    course:
        json['course']?.toString() ??
        '',

    department:
        json['department']
                ?.toString() ??
            '',

    memberCount:
        memberCount,

    materialCount:
        _toInt(
              json['material_count'],
            ) ??
            0,

    isPrivate:
        json['is_private']
                as bool? ??
            false,

    isOwner:
        isOwner,
  );
}


  Map<String, dynamic> toJson() {
    return {
      'id':
          id,

      'name':
          name,

      'description':
          description,

      'subject_id':
          subjectId,

      'subject':
          subject,

      'course':
          course,

      'department':
          department,

      'member_count':
          memberCount,

      'material_count':
          materialCount,

      'is_private':
          isPrivate,

      'is_owner':
          isOwner,
    };
  }


  StudyGroup copyWith({
    int? id,

    String? name,

    String? description,

    int? subjectId,

    String? subject,

    String? course,

    String? department,

    int? memberCount,

    int? materialCount,

    bool? isPrivate,

    bool? isOwner,
  }) {
    return StudyGroup(
      id:
          id ??
          this.id,

      name:
          name ??
          this.name,

      description:
          description ??
          this.description,

      subjectId:
          subjectId ??
          this.subjectId,

      subject:
          subject ??
          this.subject,

      course:
          course ??
          this.course,

      department:
          department ??
          this.department,

      memberCount:
          memberCount ??
          this.memberCount,

      materialCount:
          materialCount ??
          this.materialCount,

      isPrivate:
          isPrivate ??
          this.isPrivate,

      isOwner:
          isOwner ??
          this.isOwner,
    );
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
      value?.toString() ??
          '',
    );
  }
}