import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';


// =============================================================================
// LOCAL FILE SERVICE
// =============================================================================

class LocalFileService {
  // ===========================================================================
  // ROOT DIRECTORY
  // ===========================================================================

  Future<Directory> _getRootDirectory() async {
    final Directory root =
        await getApplicationDocumentsDirectory();

    final Directory directory =
        Directory(
      p.join(
        root.path,
        'studentlab',
      ),
    );

    if (!await directory.exists()) {
      await directory.create(
        recursive: true,
      );
    }

    return directory;
  }


  // ===========================================================================
  // USER DIRECTORY
  // ===========================================================================

  Future<Directory> _getUserDirectory(
    int userId,
  ) async {
    final Directory root =
        await _getRootDirectory();

    final Directory directory =
        Directory(
      p.join(
        root.path,
        'users',
        userId.toString(),
      ),
    );

    if (!await directory.exists()) {
      await directory.create(
        recursive: true,
      );
    }

    return directory;
  }


  // ===========================================================================
  // DOWNLOAD DIRECTORY
  // ===========================================================================

  Future<Directory> _getDownloadsDirectory({
    required int userId,
    required int groupId,
  }) async {
    final Directory userDirectory =
        await _getUserDirectory(
      userId,
    );

    final Directory directory =
        Directory(
      p.join(
        userDirectory.path,
        'downloads',
        'groups',
        groupId.toString(),
      ),
    );

    if (!await directory.exists()) {
      await directory.create(
        recursive: true,
      );
    }

    return directory;
  }


  // ===========================================================================
  // PENDING UPLOAD DIRECTORY
  // ===========================================================================

  Future<Directory> _getPendingUploadsDirectory({
    required int userId,
    required int groupId,
  }) async {
    final Directory userDirectory =
        await _getUserDirectory(
      userId,
    );

    final Directory directory =
        Directory(
      p.join(
        userDirectory.path,
        'uploads',
        'pending',
        'groups',
        groupId.toString(),
      ),
    );

    if (!await directory.exists()) {
      await directory.create(
        recursive: true,
      );
    }

    return directory;
  }


  // ===========================================================================
  // SAVE DOWNLOADED MATERIAL
  // ===========================================================================

  Future<String> saveDownloadedMaterial({
    required int userId,
    required int groupId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final Directory directory =
        await _getDownloadsDirectory(
      userId: userId,
      groupId: groupId,
    );

    final String safeName =
        _sanitizeFileName(
      fileName,
    );

    final String filePath =
        p.join(
      directory.path,
      safeName,
    );

    final File file =
        File(
      filePath,
    );

    await file.writeAsBytes(
      bytes,
      flush: true,
    );

    return file.path;
  }


  // ===========================================================================
  // COPY FILE TO PENDING UPLOAD
  // ===========================================================================

  Future<String> copyToPendingUpload({
    required int userId,
    required int groupId,
    required String sourcePath,
    String? preferredFileName,
  }) async {
    final File sourceFile =
        File(
      sourcePath,
    );

    if (!await sourceFile.exists()) {
      throw FileSystemException(
        'Il file selezionato non esiste.',
        sourcePath,
      );
    }

    final Directory directory =
        await _getPendingUploadsDirectory(
      userId:
          userId,

      groupId:
          groupId,
    );

    final String originalName =
        preferredFileName != null &&
                preferredFileName.trim().isNotEmpty
            ? preferredFileName.trim()
            : p.basename(
                sourcePath,
              );

    final String safeName =
        _sanitizeFileName(
      originalName,
    );

    final String uniqueName =
        _generateUniqueFileName(
      safeName,
    );

    final String destinationPath =
        p.join(
      directory.path,
      uniqueName,
    );

    final File copiedFile =
        await sourceFile.copy(
      destinationPath,
    );

    return copiedFile.path;
  }


  // ===========================================================================
  // SAVE PENDING UPLOAD FROM BYTES
  // ===========================================================================
  //
  // Utile anche per Flutter Web o per sorgenti
  // che non forniscono un filePath fisico.
  // ===========================================================================

  Future<String> savePendingUploadBytes({
    required int userId,
    required int groupId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final Directory directory =
        await _getPendingUploadsDirectory(
      userId:
          userId,

      groupId:
          groupId,
    );

    final String safeName =
        _sanitizeFileName(
      fileName,
    );

    final String uniqueName =
        _generateUniqueFileName(
      safeName,
    );

    final String destinationPath =
        p.join(
      directory.path,
      uniqueName,
    );

    final File file =
        File(
      destinationPath,
    );

    await file.writeAsBytes(
      bytes,
      flush:
          true,
    );

    return file.path;
  }


  // ===========================================================================
  // FILE EXISTS
  // ===========================================================================

  Future<bool> exists(
    String path,
  ) async {
    return File(
      path,
    ).exists();
  }


  // ===========================================================================
  // FILE SIZE
  // ===========================================================================

  Future<int?> getFileSize(
    String path,
  ) async {
    final File file =
        File(
      path,
    );

    if (!await file.exists()) {
      return null;
    }

    return file.length();
  }


  // ===========================================================================
  // FILE NAME
  // ===========================================================================

  String getFileName(
    String path,
  ) {
    return p.basename(
      path,
    );
  }


  // ===========================================================================
  // EXTENSION
  // ===========================================================================

  String getExtension(
    String path,
  ) {
    return p.extension(
      path,
    );
  }


  // ===========================================================================
  // DELETE FILE
  // ===========================================================================

  Future<void> delete(
    String path,
  ) async {
    final File file =
        File(
      path,
    );

    if (await file.exists()) {
      await file.delete();
    }
  }


  // ===========================================================================
  // DELETE DIRECTORY
  // ===========================================================================

  Future<void> deleteDirectory(
    String path,
  ) async {
    final Directory directory =
        Directory(
      path,
    );

    if (await directory.exists()) {
      await directory.delete(
        recursive:
            true,
      );
    }
  }


  // ===========================================================================
  // DELETE USER FILES
  // ===========================================================================

  Future<void> deleteUserFiles(
    int userId,
  ) async {
    final Directory root =
        await _getRootDirectory();

    final Directory userDirectory =
        Directory(
      p.join(
        root.path,
        'users',
        userId.toString(),
      ),
    );

    if (await userDirectory.exists()) {
      await userDirectory.delete(
        recursive:
            true,
      );
    }
  }


  // ===========================================================================
  // USER STORAGE PATH
  // ===========================================================================

  Future<String> getUserStoragePath(
    int userId,
  ) async {
    final Directory directory =
        await _getUserDirectory(
      userId,
    );

    return directory.path;
  }


  // ===========================================================================
  // PENDING UPLOAD DIRECTORY PATH
  // ===========================================================================

  Future<String> getPendingUploadDirectoryPath({
    required int userId,
    required int groupId,
  }) async {
    final Directory directory =
        await _getPendingUploadsDirectory(
      userId:
          userId,

      groupId:
          groupId,
    );

    return directory.path;
  }


  // ===========================================================================
  // DOWNLOAD DIRECTORY PATH
  // ===========================================================================

  Future<String> getDownloadDirectoryPath({
    required int userId,
    required int groupId,
  }) async {
    final Directory directory =
        await _getDownloadsDirectory(
      userId:
          userId,

      groupId:
          groupId,
    );

    return directory.path;
  }


  // ===========================================================================
  // SANITIZE FILE NAME
  // ===========================================================================

  String _sanitizeFileName(
    String fileName,
  ) {
    String result =
        fileName.trim();

    if (result.isEmpty) {
      result =
          'file';
    }

    result =
        result.replaceAll(
      RegExp(
        r'[\\/:*?"<>|]',
      ),
      '_',
    );

    result =
        result.replaceAll(
      RegExp(
        r'\s+',
      ),
      ' ',
    );

    return result;
  }


  // ===========================================================================
  // UNIQUE FILE NAME
  // ===========================================================================

  String _generateUniqueFileName(
    String fileName,
  ) {
    final String extension =
        p.extension(
      fileName,
    );

    final String nameWithoutExtension =
        p.basenameWithoutExtension(
      fileName,
    );

    final int timestamp =
        DateTime.now()
            .microsecondsSinceEpoch;

    if (extension.isEmpty) {
      return '${nameWithoutExtension}_$timestamp';
    }

    return '${nameWithoutExtension}_$timestamp$extension';
  }
}