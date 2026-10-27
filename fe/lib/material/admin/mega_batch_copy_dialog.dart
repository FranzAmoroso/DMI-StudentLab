import 'package:flutter/material.dart';

import '../../social/admin/admin_material_storage_api_service.dart';
import 'drive_destination_dialog.dart';

/// Copia su Drive di più file o cartelle MEGA, ognuno con la sua destinazione.
///
/// Si parte da una destinazione comune; per ogni elemento si può scegliere
/// un'altra cartella. Restituisce (elemento, percorso Drive) per ogni riga.
class MegaBatchCopyDialog extends StatefulWidget {
  final AdminMaterialStorageApiService api;
  final List<Map<String, dynamic>> items;
  const MegaBatchCopyDialog({super.key, required this.api, required this.items});

  @override
  State<MegaBatchCopyDialog> createState() => _MegaBatchCopyDialogState();
}

class _MegaBatchCopyDialogState extends State<MegaBatchCopyDialog> {
  List<String> _common = const ['Da MEGA'];
  final Map<String, List<String>> _custom = {};

  String _id(Map<String, dynamic> item) => '${item['id']}';
  bool _folder(Map<String, dynamic> item) =>
      item['is_folder'] == true || item['mime_type'] == 'application/vnd.google-apps.folder';

  Future<List<String>?> _pick(String title, List<String> current) => showDialog<List<String>>(
        context: context,
        builder: (_) => DriveDestinationDialog(
          api: widget.api,
          title: title,
          confirmLabel: 'Usa questa cartella',
          initialPath: current,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return AlertDialog(
      title: Text('Copia ${widget.items.length} elementi su Drive'),
      content: SizedBox(
        width: width < 600 ? width - 48 : 540,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Gli originali restano su MEGA finché la copia non è verificata. '
                'A copia completata ti verrà chiesto se eliminarli da MEGA.'),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.folder_special_outlined),
                title: Text('StudentLab / ${_common.join(' / ')}'),
                subtitle: const Text('Destinazione comune'),
                trailing: TextButton(
                  onPressed: () async {
                    final chosen = await _pick('Destinazione comune', _common);
                    if (chosen != null && mounted) setState(() => _common = chosen);
                  },
                  child: const Text('Cambia'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (final item in widget.items)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(_folder(item) ? Icons.folder_outlined : Icons.insert_drive_file_outlined),
                title: Text('${item['name']}', maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(_custom.containsKey(_id(item))
                    ? '→ StudentLab / ${_custom[_id(item)]!.join(' / ')}'
                    : '→ destinazione comune'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (_custom.containsKey(_id(item)))
                    IconButton(
                      tooltip: 'Usa la destinazione comune',
                      onPressed: () => setState(() => _custom.remove(_id(item))),
                      icon: const Icon(Icons.undo_rounded),
                    ),
                  IconButton(
                    tooltip: 'Scegli una cartella per questo elemento',
                    onPressed: () async {
                      final chosen = await _pick('Destinazione di ${item['name']}', _custom[_id(item)] ?? _common);
                      if (chosen != null && mounted) setState(() => _custom[_id(item)] = chosen);
                    },
                    icon: const Icon(Icons.drive_file_move_outline),
                  ),
                ]),
              ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
        FilledButton(
          onPressed: () => Navigator.pop(context, [
            for (final item in widget.items) (item, _custom[_id(item)] ?? _common),
          ]),
          child: const Text('Avvia copie'),
        ),
      ],
    );
  }
}
