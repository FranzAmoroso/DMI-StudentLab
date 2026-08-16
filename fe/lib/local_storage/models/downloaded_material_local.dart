class DownloadedMaterialLocal {
  final int? id;

  final int userId;
  final int materialId;
  final int groupId;

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

    required this.originalName,
    required this.localPath,

    this.mimeType,
    this.size,

    required this.downloadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,

      'user_id':
          userId,

      'material_id':
          materialId,

      'group_id':
          groupId,

      'original_name':
          originalName,

      'local_path':
          localPath,

      'mime_type':
          mimeType,

      'size':
          size,

      'downloaded_at':
          downloadedAt.toIso8601String(),
    };
  }

  factory DownloadedMaterialLocal.fromMap(
    Map<String, dynamic> map,
  ) {
    return DownloadedMaterialLocal(
      id:
          map['id'] as int?,

      userId:
          map['user_id'] as int,

      materialId:
          map['material_id'] as int,

      groupId:
          map['group_id'] as int,

      originalName:
          map['original_name'] as String,

      localPath:
          map['local_path'] as String,

      mimeType:
          map['mime_type'] as String?,

      size:
          map['size'] as int?,

      downloadedAt:
          DateTime.parse(
        map['downloaded_at'] as String,
      ),
    );
  }
}