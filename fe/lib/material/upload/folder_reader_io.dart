import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'upload_items.dart';

bool get canPickFolder => Platform.isWindows || Platform.isMacOS || Platform.isLinux;

/// Legge una cartella e le sottocartelle (al massimo 10 livelli e 500 file).
Future<UploadSelection?> pickFolder() async {
  final path = await FilePicker.getDirectoryPath(dialogTitle: 'Scegli la cartella da caricare');
  if (path == null) return null;
  final root = Directory(path);
  final segments = root.uri.pathSegments.where((s) => s.isNotEmpty).toList();
  final rootName = segments.isEmpty ? 'Cartella' : segments.last;
  final items = <UploadItem>[];
  var tooLarge = 0, skipped = 0;
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final relative = entity.path.substring(root.path.length).split(RegExp(r'[\\/]')).where((s) => s.isNotEmpty).toList();
    if (relative.isEmpty) continue;
    final name = relative.last;
    final folders = [rootName, ...relative.take(relative.length - 1)];
    if (name.startsWith('.') || name == 'Thumbs.db' || name == 'desktop.ini') continue;
    if (folders.length > 10 || items.length >= uploadMaxFiles) {
      skipped++;
      continue;
    }
    try {
      final length = await entity.length();
      if (length > uploadMaxBytes) {
        tooLarge++;
        continue;
      }
      if (length == 0) {
        skipped++;
        continue;
      }
      items.add(UploadItem(name: name, folders: folders, bytes: await entity.readAsBytes()));
    } catch (_) {
      skipped++;
    }
  }
  return UploadSelection(items, tooLarge: tooLarge, skipped: skipped);
}
