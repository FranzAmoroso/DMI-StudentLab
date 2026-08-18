class StudyGroup {
  final int id;

  final String name;

  final String description;

  final int? subjectId;

  final String subject;

  final String course;

  final String department;

  final String university;

  final int memberCount;

  final int materialCount;

  final bool isPrivate;

  final bool isOwner;

  final bool isAdmin;

  final String currentUserRole;


  const StudyGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.subjectId,
    required this.subject,
    required this.course,
    required this.department,
    required this.university,
    required this.memberCount,
    required this.materialCount,
    required this.isPrivate,
    required this.isOwner,
    this.isAdmin = false,
    this.currentUserRole = '',
  });


  bool get isManager {
    return isOwner ||
        isAdmin;
  }


  bool get isMember {
    return currentUserRole
        .trim()
        .isNotEmpty;
  }


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

    String currentUserRole =
        '';

    if (
      currentUserId != null &&
      membersData is List
    ) {
      for (
        final dynamic rawMember
        in membersData
      ) {
        if (rawMember is! Map) {
          continue;
        }

        final Map<String, dynamic>
            member =
            Map<String, dynamic>.from(
          rawMember,
        );

        final int? memberUserId =
            _toInt(
          member['user_id'] ??
              member['id'],
        );

        if (
          memberUserId !=
          currentUserId
        ) {
          continue;
        }

        currentUserRole =
            member['role']
                    ?.toString()
                    .trim()
                    .toLowerCase() ??
                '';

        break;
      }
    }

    final bool ownerFromCreatedBy =
        currentUserId != null &&
        createdBy == currentUserId;

    final bool ownerFromRole =
        currentUserRole ==
        'owner';

    final bool isOwner =
        ownerFromCreatedBy ||
        ownerFromRole;

    if (
      isOwner &&
      currentUserRole.isEmpty
    ) {
      currentUserRole =
          'owner';
    }

    final bool isAdmin =
        currentUserRole ==
        'admin';

    String subjectName =
        '';

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
          json['name']
                  ?.toString() ??
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
          json['course']
                  ?.toString() ??
              '',

      department:
          json['department']
                  ?.toString() ??
              '',

      university:
          (
            json['university'] ??
            json['university_name'] ??
            json['ateneo']
          )
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

      isAdmin:
          isAdmin,

      currentUserRole:
          currentUserRole,
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

      'university':
          university,

      'member_count':
          memberCount,

      'material_count':
          materialCount,

      'is_private':
          isPrivate,

      'is_owner':
          isOwner,

      'is_admin':
          isAdmin,

      'current_user_role':
          currentUserRole,
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
    String? university,
    int? memberCount,
    int? materialCount,
    bool? isPrivate,
    bool? isOwner,
    bool? isAdmin,
    String? currentUserRole,
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

      university:
          university ??
          this.university,

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

      isAdmin:
          isAdmin ??
          this.isAdmin,

      currentUserRole:
          currentUserRole ??
          this.currentUserRole,
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