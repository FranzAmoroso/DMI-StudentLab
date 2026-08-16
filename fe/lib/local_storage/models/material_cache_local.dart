class MaterialCacheLocal {
  final int materialId;

  final int userId;
  final int groupId;

  final int? uploadedBy;

  final String originalName;

  final String? mimeType;

  final int? size;

  final DateTime? createdAt;

  final DateTime syncedAt;

  const MaterialCacheLocal({
    required this.materialId,

    required this.userId,

    required this.groupId,

    this.uploadedBy,

    required this.originalName,

    this.mimeType,

    this.size,

    this.createdAt,

    required this.syncedAt,
  });


  // ===========================================================================
  // TO MAP
  // ===========================================================================

  Map<String, dynamic> toMap() {
    return {
      'material_id':
          materialId,

      'user_id':
          userId,

      'group_id':
          groupId,

      'uploaded_by':
          uploadedBy,

      'original_name':
          originalName,

      'mime_type':
          mimeType,

      'size':
          size,

      'created_at':
          createdAt
              ?.toIso8601String(),

      'synced_at':
          syncedAt
              .toIso8601String(),
    };
  }


  // ===========================================================================
  // FROM MAP
  // ===========================================================================

  factory MaterialCacheLocal.fromMap(
    Map<String, dynamic> map,
  ) {
    return MaterialCacheLocal(
      materialId:
          _toInt(
        map['material_id'],
      ),

      userId:
          _toInt(
        map['user_id'],
      ),

      groupId:
          _toInt(
        map['group_id'],
      ),

      uploadedBy:
          _toNullableInt(
        map['uploaded_by'],
      ),

      originalName:
          map['original_name']
              ?.toString() ??
          '',

      mimeType:
          map['mime_type']
              ?.toString(),

      size:
          _toNullableInt(
        map['size'],
      ),

      createdAt:
          _toNullableDateTime(
        map['created_at'],
      ),

      syncedAt:
          _toDateTime(
        map['synced_at'],
      ),
    );
  }


  // ===========================================================================
  // COPY WITH
  // ===========================================================================

  MaterialCacheLocal copyWith({
    int? materialId,

    int? userId,

    int? groupId,

    int? uploadedBy,

    bool clearUploadedBy = false,

    String? originalName,

    String? mimeType,

    bool clearMimeType = false,

    int? size,

    bool clearSize = false,

    DateTime? createdAt,

    bool clearCreatedAt = false,

    DateTime? syncedAt,
  }) {
    return MaterialCacheLocal(
      materialId:
          materialId ??
              this.materialId,

      userId:
          userId ??
              this.userId,

      groupId:
          groupId ??
              this.groupId,

      uploadedBy:
          clearUploadedBy
              ? null
              : uploadedBy ??
                  this.uploadedBy,

      originalName:
          originalName ??
              this.originalName,

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

      createdAt:
          clearCreatedAt
              ? null
              : createdAt ??
                  this.createdAt,

      syncedAt:
          syncedAt ??
              this.syncedAt,
    );
  }


  // ===========================================================================
  // HELPERS
  // ===========================================================================

  bool get hasKnownSize {
    return size != null;
  }


  bool get hasMimeType {
    return mimeType != null &&
        mimeType!.isNotEmpty;
  }


  // ===========================================================================
  // UTILITY
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


  static DateTime? _toNullableDateTime(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }
}