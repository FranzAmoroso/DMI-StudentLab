import 'package:flutter/material.dart';

import '../../services/user_facing_error.dart';
import '../../social/admin/admin_material_storage_api_service.dart';
import '../transfer_upload_api.dart';
import '../upload/upload_items.dart';

/// File e cartelle trascinati dal PC direttamente nella struttura (v27).
///
/// 1. i file vanno su Drive in «Materia / cartella / sottocartelle»;
/// 2. il server ricorda dove vanno nella struttura;
/// 3. quando la copia su Drive è verificata, entrano da soli nella bozza,
///    con le stesse cartelle e sottocartelle.
Future<bool?> showStructureUploadDialog(
  BuildContext context, {
  required AdminMaterialStorageApiService api,
  required UploadSelection selection,
  required int subjectId,
  required String subjectName,
  required List<String> initialFolder,
  required Future<List<String>?> Function(List<String> current) pickFolder,
}) =>
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _StructureUploadDialog(
        api: api,
        selection: selection,
        subjectId: subjectId,
        subjectName: subjectName,
        folder: initialFolder,
        pickFolder: pickFolder,
      ),
    );

class _StructureUploadDialog extends StatefulWidget {
  final AdminMaterialStorageApiService api;
  final UploadSelection selection;
  final int subjectId;
  final String subjectName;
  final List<String> folder;
  final Future<List<String>?> Function(List<String> current) pickFolder;
  const _StructureUploadDialog({
    required this.api,
    required this.selection,
    required this.subjectId,
    required this.subjectName,
    required this.folder,
    required this.pickFolder,
  });
  @override
  State<_StructureUploadDialog> createState() => _StructureUploadDialogState();
}

class _StructureUploadDialogState extends State<_StructureUploadDialog> {
  final _transfers = TransferUploadApi();
  late List<String> _folder = List<String>.of(widget.folder);
  String _audience = 'course';
  bool _busy = false;
  int _done = 0;
  String? _current;
  String? _error;
  final List<String> _failed = [];

  static String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9àèéìòù]+'), ' ').trim();
  static String _safe(String s) => s.replaceAll(RegExp(r'[\\/\x00-\x1f]'), '-').trim();

  /// Cartelle relative del file; la prima si salta se ha il nome della materia.
  List<String> _relative(UploadItem item) {
    final folders = item.folders;
    if (folders.isNotEmpty && _norm(folders.first) == _norm(widget.subjectName)) return folders.skip(1).toList();
    return folders;
  }

  List<String> _catalogPath(UploadItem item) => [..._folder, ..._relative(item)];
  List<String> _drivePath(UploadItem item) => [_safe(widget.subjectName), ..._catalogPath(item)];

  Future<void> _start() async {
    final items = widget.selection.items;
    if (items.any((i) => _drivePath(i).length > 8)) {
      setState(() => _error = 'Alcuni file finirebbero oltre 8 cartelle: scegli una cartella meno profonda.');
      return;
    }
    setState(() { _busy = true; _done = 0; _error = null; _failed.clear(); });
    final planned = <Map<String, dynamic>>[];
    for (final item in items) {
      if (!mounted) return;
      setState(() => _current = item.relativePath);
      try {
        final job = await _transfers.upload(
          filename: item.name,
          bytes: item.bytes,
          destination: 'drive',
          pathSegments: _drivePath(item),
        );
        planned.add({'job_id': '${job['id']}', 'path_segments': _catalogPath(item)});
      } catch (e) {
        _failed.add('${item.name}: ${friendlyError(e, 'invio non riuscito')}');
        if (e is UserFacingError && e.status == 429) break;
      }
      if (mounted) setState(() => _done++);
    }
    try {
      if (planned.isNotEmpty) {
        // A blocchi da 500 (limite del server).
        for (var i = 0; i < planned.length; i += 500) {
          await widget.api.createCatalogIntent(
            kind: 'transfer',
            subjectId: widget.subjectId,
            audienceType: _audience,
            items: planned.sublist(i, i + 500 > planned.length ? planned.length : i + 500),
          );
        }
      }
    } catch (e) {
      _error = friendlyError(e, 'I file sono su Drive ma non è stato possibile prenotarne l’aggiunta: '
          'aggiungili dalla pagina di caricamento, scheda Trasferimenti.');
    }
    if (!mounted) return;
    setState(() { _busy = false; _current = null; });
    if (_failed.isEmpty && _error == null) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.selection.items;
    final total = items.fold<int>(0, (s, i) => s + i.size);
    final folders = {for (final i in items) _catalogPath(i).join(' / ')}.where((s) => s.isNotEmpty).length;
    final width = MediaQuery.sizeOf(context).width;
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: const Text('Aggiungi dal computer'),
        content: SizedBox(
          width: width < 560 ? width - 48 : 500,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
              Text('${items.length} file (${(total / (1024 * 1024)).toStringAsFixed(1)} MB)'
                  '${folders > 0 ? ' in $folders cartelle' : ''}. Cartelle e sottocartelle vengono ricreate.'),
              if (widget.selection.note != null) Text(widget.selection.note!),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.folder_outlined),
                title: Text([widget.subjectName, ..._folder].join(' / ')),
                subtitle: const Text('Cartella della struttura'),
                trailing: TextButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          final chosen = await widget.pickFolder(_folder);
                          if (chosen != null && mounted) setState(() => _folder = chosen);
                        },
                  child: const Text('Cambia'),
                ),
              ),
              DropdownButtonFormField<String>(
                initialValue: _audience,
                decoration: const InputDecoration(labelText: 'Destinatari'),
                items: const [
                  DropdownMenuItem(value: 'public', child: Text('Tutti, anche guest')),
                  DropdownMenuItem(value: 'course', child: Text('Studenti del corso')),
                  DropdownMenuItem(value: 'subject', child: Text('Studenti della materia')),
                ],
                onChanged: _busy ? null : (v) => setState(() => _audience = v ?? _audience),
              ),
              const SizedBox(height: 10),
              Text('Su Drive andranno in: StudentLab / ${_drivePath(items.first).take(1 + _folder.length).join(' / ')} / …',
                  style: Theme.of(context).textTheme.bodySmall),
              const Text('Entrano nella bozza da soli appena la copia su Drive è verificata (di solito pochi minuti).'),
              if (_busy) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(value: items.isEmpty ? null : _done / items.length),
                if (_current != null) Text('Invio ${_done + 1} di ${items.length}: $_current',
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
              if (_failed.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('${_failed.length} file non inviati:', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                for (final f in _failed.take(8)) Text(f, style: Theme.of(context).textTheme.bodySmall),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: _busy ? null : () => Navigator.pop(context, _done > 0), child: Text(_done > 0 ? 'Chiudi' : 'Annulla')),
          if (_done == 0)
            FilledButton(onPressed: _busy ? null : _start, child: Text('Carica ${items.length} file')),
        ],
      ),
    );
  }
}
