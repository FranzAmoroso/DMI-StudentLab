import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../theme/nightTheme.dart';

Future<void> showDriveFilePreview(BuildContext context, {
  required Future<Uint8List> Function() load,
  required String name,
  required String mimeType,
}) async {
  try {
    final bytes = await load();
    if (!context.mounted) return;
    final Widget content;
    if (mimeType == 'application/pdf') {
      content = PdfViewer.data(bytes, sourceName: name);
    } else if (mimeType.startsWith('image/')) {
      content = InteractiveViewer(child: Center(child: Image.memory(bytes)));
    } else if (mimeType.startsWith('text/')) {
      content = SingleChildScrollView(child: SelectableText(utf8.decode(bytes,
        allowMalformed: true), style: TextStyle(color: AppColors.white)));
    } else {
      content = Center(child: Text('Anteprima non disponibile per questo formato.',
        style: TextStyle(color: AppColors.white70)));
    }
    await showDialog<void>(context: context, builder: (ctx) => Dialog(
      backgroundColor: AppColors.eleganceMidnight,
      child: SizedBox(width: 900, height: 650, child: Column(children: [
        ListTile(title: Text(name, style: TextStyle(color: AppColors.white)),
          trailing: IconButton(onPressed: () => Navigator.pop(ctx),
            icon: Icon(Icons.close, color: AppColors.white))),
        Expanded(child: content),
      ]))));
  } catch (_) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impossibile aprire l’anteprima del file.')));
  }
}
