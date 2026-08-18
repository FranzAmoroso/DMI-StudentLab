class DownloadedMaterialLocal {
  final int? id;

  final int userId;

  final int materialId;

  final int groupId;

  final String? university;

  final String? department;

  final String? course;

  final int? subjectId;

  final String? subjectName;

  final String originalName;

  final String localPath;

  final String? mimeType;

  final int? size;

  final DateTime downloadedAt;


  const DownloadedMaterialLocal({
    this.id,
    required this.userId,
    required this.materialId,
    required this.groupId,
    this.university,
    this.department,
    this.course,
    this.subjectId,
    this.subjectName,
    required this.originalName,
    required this.localPath,
    this.mimeType,
    this.size,
    required this.downloadedAt,
  });


  Map<String, dynamic> toMap() {
    return {
      'id':
          id,

      'user_id':
          userId,

      'material_id':
          materialId,

      'group_id':
          groupId,

      'university':
          university,

      'department':
          department,

      'course':
          course,

      'subject_id':
          subjectId,

      'subject_name':
          subjectName,

      'original_name':
          originalName,

      'local_path':
          localPath,

      'mime_type':
          mimeType,

      'size':
          size,

      'downloaded_at':
          downloadedAt
              .toIso8601String(),
    };
  }


  factory DownloadedMaterialLocal.fromMap(
    Map<String, dynamic> map,
  ) {
    return DownloadedMaterialLocal(
      id:
          _toNullableInt(
        map['id'],
      ),

      userId:
          _toInt(
        map['user_id'],
      ),

      materialId:
          _toInt(
        map['material_id'],
      ),

      groupId:
          _toInt(
        map['group_id'],
      ),

      university:
          _toNullableString(
        map['university'],
      ),

      department:
          _toNullableString(
        map['department'],
      ),

      course:
          _toNullableString(
        map['course'],
      ),

      subjectId:
          _toNullableInt(
        map['subject_id'],
      ),

      subjectName:
          _toNullableString(
        map['subject_name'],
      ),

      originalName:
          map['original_name']
                  ?.toString() ??
              '',

      localPath:
          map['local_path']
                  ?.toString() ??
              '',

      mimeType:
          _toNullableString(
        map['mime_type'],
      ),

      size:
          _toNullableInt(
        map['size'],
      ),

      downloadedAt:
          _toDateTime(
        map['downloaded_at'],
      ),
    );
  }


  DownloadedMaterialLocal copyWith({
    int? id,

    int? userId,

    int? materialId,

    int? groupId,

    String? university,

    bool clearUniversity = false,

    String? department,

    bool clearDepartment = false,

    String? course,

    bool clearCourse = false,

    int? subjectId,

    bool clearSubjectId = false,

    String? subjectName,

    bool clearSubjectName = false,

    String? originalName,

    String? localPath,

    String? mimeType,

    bool clearMimeType = false,

    int? size,

    bool clearSize = false,

    DateTime? downloadedAt,
  }) {
    return DownloadedMaterialLocal(
      id:
          id ??
              this.id,

      userId:
          userId ??
              this.userId,

      materialId:
          materialId ??
              this.materialId,

      groupId:
          groupId ??
              this.groupId,

      university:
          clearUniversity
              ? null
              : university ??
                  this.university,

      department:
          clearDepartment
              ? null
              : department ??
                  this.department,

      course:
          clearCourse
              ? null
              : course ??
                  this.course,

      subjectId:
          clearSubjectId
              ? null
              : subjectId ??
                  this.subjectId,

      subjectName:
          clearSubjectName
              ? null
              : subjectName ??
                  this.subjectName,

      originalName:
          originalName ??
              this.originalName,

      localPath:
          localPath ??
              this.localPath,

      mimeType:
          clearMimeType
              ? null
              : mimeType ??
                  this.mimeType,

      size:
          clearSize
              ? null
              : size ??
                  this.size,

      downloadedAt:
          downloadedAt ??
              this.downloadedAt,
    );
  }


  bool get hasUniversity {
    return university != null &&
        university!
            .trim()
            .isNotEmpty;
  }


  bool get hasDepartment {
    return department != null &&
        department!
            .trim()
            .isNotEmpty;
  }


  bool get hasCourse {
    return course != null &&
        course!
            .trim()
            .isNotEmpty;
  }


  bool get hasSubject {
    return subjectId != null ||
        (
          subjectName != null &&
          subjectName!
              .trim()
              .isNotEmpty
        );
  }


  String get displayUniversity {
    final String? value =
        university;

    if (
      value == null ||
      value.trim().isEmpty
    ) {
      return 'Ateneo';
    }

    return value.trim();
  }


  String get displayDepartment {
    final String? value =
        department;

    if (
      value == null ||
      value.trim().isEmpty
    ) {
      return 'Dipartimento';
    }

    return value.trim();
  }


  String get displayCourse {
    final String? value =
        course;

    if (
      value == null ||
      value.trim().isEmpty
    ) {
      return 'Corso';
    }

    return value.trim();
  }


  String get displaySubjectName {
    final String? value =
        subjectName;

    if (
      value == null ||
      value.trim().isEmpty
    ) {
      return 'Materia';
    }

    return value.trim();
  }


  static int _toInt(
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
        ) ??
        0;
  }


  static int? _toNullableInt(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString(),
    );
  }


  static String? _toNullableString(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final String result =
        value
            .toString()
            .trim();

    if (result.isEmpty) {
      return null;
    }

    return result;
  }


  static DateTime _toDateTime(
    dynamic value,
  ) {
    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(
          value?.toString() ??
              '',
        ) ??
        DateTime.now();
  }
}