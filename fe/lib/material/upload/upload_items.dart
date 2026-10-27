import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';

import 'folder_reader_stub.dart' if (dart.library.io) 'folder_reader_io.dart' as folder_reader;

/// Un file da caricare, con le cartelle relative (per conservare la struttura).
class UploadItem {
  final String name;
  final List<String> folders;
  final Uint8List bytes;
  const UploadItem({required this.name, required this.folders, required this.bytes});

  int get size => bytes.length;
  String get relativePath => [...folders, name].join(' / ');
}

/// Esito di una raccolta: file validi e quanti sono stati esclusi.
class UploadSelection {
  final List<UploadItem> items;
  final int tooLarge;
  final int skipped;
  const UploadSelection(this.items, {this.tooLarge = 0, this.skipped = 0});

  String? get note {
    final parts = <String>[
      if (tooLarge > 0) '$tooLarge oltre 50 MB',
      if (skipped > 0) '$skipped non leggibili o oltre il limite di 500 file',
    ];
    return parts.isEmpty ? null : 'Esclusi: ${parts.join(', ')}.';
  }
}

const int uploadMaxBytes = 50 * 1024 * 1024;
const int uploadMaxFiles = 500;

bool _hidden(String name) => name.startsWith('.') || name == 'Thumbs.db' || name == 'desktop.ini';

/// Scelta di uno o più file dal dispositivo.
Future<UploadSelection?> pickUploadFiles({List<String>? extensions}) async {
  final result = await FilePicker.pickFiles(
    allowMultiple: true,
    withData: true,
    type: extensions == null ? FileType.any : FileType.custom,
    allowedExtensions: extensions,
  );
  if (result == null || result.files.isEmpty) return null;
  final items = <UploadItem>[];
  var tooLarge = 0, skipped = 0;
  for (final f in result.files) {
    if (f.size > uploadMaxBytes) {
      tooLarge++;
    } else if (f.bytes == null || f.bytes!.isEmpty || items.length >= uploadMaxFiles) {
      skipped++;
    } else {
      items.add(UploadItem(name: f.name, folders: const [], bytes: f.bytes!));
    }
  }
  return UploadSelection(items, tooLarge: tooLarge, skipped: skipped);
}

/// Scelta di una cartella con le sue sottocartelle (PC e tablet; sul web si trascina).
bool get canPickFolder => folder_reader.canPickFolder;

Future<UploadSelection?> pickUploadFolder() => folder_reader.pickFolder();

/// File e cartelle trascinati dal computer nella pagina.
Future<UploadSelection> itemsFromDrop(List<DropItem> dropped) async {
  final items = <UploadItem>[];
  var tooLarge = 0, skipped = 0;
  Future<void> visit(DropItem item, List<String> folders) async {
    if (items.length >= uploadMaxFiles) {
      skipped++;
      return;
    }
    if (item is DropItemDirectory) {
      if (folders.length >= 10) {
        skipped++;
        return;
      }
      for (final child in item.children) {
        await visit(child, [...folders, item.name]);
      }
      return;
    }
    if (_hidden(item.name)) return;
    try {
      final length = await item.length();
      if (length > uploadMaxBytes) {
        tooLarge++;
        return;
      }
      final bytes = await item.readAsBytes();
      if (bytes.isEmpty) {
        skipped++;
        return;
      }
      items.add(UploadItem(name: item.name, folders: folders, bytes: bytes));
    } catch (_) {
      skipped++;
    }
  }

  for (final item in dropped) {
    await visit(item, const []);
  }
  return UploadSelection(items, tooLarge: tooLarge, skipped: skipped);
}
