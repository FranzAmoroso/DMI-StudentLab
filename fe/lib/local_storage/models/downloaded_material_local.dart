// =============================================================================
// DOWNLOADED MATERIAL LOCAL
// =============================================================================
//
// Rappresenta una COPIA LOCALE di un materiale presente sul backend.
//
// Il materialId rimane l'identificatore principale del materiale server.
//
// subjectId / subjectName / course / department servono invece per
// organizzare la libreria locale dell'utente.
//
// Esempio:
//
// Programmazione 1
// ├── puntatori.pdf
// ├── array.pdf
// └── ricorsione.pdf
//
// =============================================================================

class DownloadedMaterialLocal {
  final int? id;


  // ===========================================================================
  // OWNER LOCALE
  // ===========================================================================
  //
  // userId reale per utenti autenticati.
  //
  // 0 per Guest.
  // ===========================================================================

  final int userId;


  // ===========================================================================
  // SERVER REFERENCES
  // ===========================================================================

  final int materialId;

  final int groupId;


  // ===========================================================================
  // SUBJECT
  // ===========================================================================

  final int? subjectId;

  final String? subjectName;

  final String? course;

  final String? department;


  // ===========================================================================
  // FILE
  // ===========================================================================

  final String originalName;

  final String localPath;

  final String? mimeType;

  final int? size;


  // ===========================================================================
  // DATE
  // ===========================================================================

  final DateTime downloadedAt;


  // ===========================================================================
  // CONSTRUCTOR
  // ===========================================================================

  const DownloadedMaterialLocal({
    this.id,

    required this.userId,

    required this.materialId,

    required this.groupId,

    this.subjectId,

    this.subjectName,

    this.course,

    this.department,

    required this.originalName,

    required this.localPath,

    this.mimeType,

    this.size,

    required this.downloadedAt,
  });


  // ===========================================================================
  // TO MAP
  // ===========================================================================

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

      'subject_id':
          subjectId,

      'subject_name':
          subjectName,

      'course':
          course,

      'department':
          department,

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


  // ===========================================================================
  // FROM MAP
  // ===========================================================================

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

      subjectId:
          _toNullableInt(
        map['subject_id'],
      ),

      subjectName:
          _toNullableString(
        map['subject_name'],
      ),

      course:
          _toNullableString(
        map['course'],
      ),

      department:
          _toNullableString(
        map['department'],
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


  // ===========================================================================
  // COPY WITH
  // ===========================================================================

  DownloadedMaterialLocal copyWith({
    int? id,

    int? userId,

    int? materialId,

    int? groupId,

    int? subjectId,

    bool clearSubjectId = false,

    String? subjectName,

    bool clearSubjectName = false,

    String? course,

    bool clearCourse = false,

    String? department,

    bool clearDepartment = false,

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

      course:
          clearCourse
              ? null
              : course ??
                  this.course,

      department:
          clearDepartment
              ? null
              : department ??
                  this.department,

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


  // ===========================================================================
  // HELPERS
  // ===========================================================================

  bool get hasSubject {
    return subjectId != null ||
        (
          subjectName != null &&
              subjectName!
                  .trim()
                  .isNotEmpty
        );
  }


  String get displaySubjectName {
    final String? value =
        subjectName;


    if (value == null ||
        value.trim().isEmpty) {
      return 'Materia';
    }


    return value.trim();
  }


  String get displayCourse {
    return course?.trim() ??
        '';
  }


  String get displayDepartment {
    return department?.trim() ??
        '';
  }


  // ===========================================================================
  // INT
  // ===========================================================================

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
    if (value ==
        null) {
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


  // ===========================================================================
  // STRING
  // ===========================================================================

  static String? _toNullableString(
    dynamic value,
  ) {
    if (value ==
        null) {
      return null;
    }


    final String result =
        value.toString().trim();


    if (result.isEmpty) {
      return null;
    }


    return result;
  }


  // ===========================================================================
  // DATE
  // ===========================================================================

  static DateTime _toDateTime(
    dynamic value,
  ) {
    if (value
        is DateTime) {
      return value;
    }


    return DateTime.tryParse(
          value?.toString() ??
              '',
        ) ??
        DateTime.now();
  }
}