import 'package:flutter/material.dart';

import '../../services/user_facing_error.dart';
import '../../social/admin/admin_material_storage_api_service.dart';
import '../drive_direct_upload.dart';
import '../upload/upload_items.dart';

/// File e cartelle trascinati dal PC direttamente nella struttura (v27, v31).
///
/// 1. i file vanno su Drive: di base in «Materia / cartella / sottocartelle»,
///    ma per ogni cartella o file sciolto si può scegliere un'altra cartella Drive (v31);
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

/// Una voce scelta dal PC: una cartella di primo livello o un file sciolto.
class _Group {
  final String key;
  final String label;
  final bool isFolder;
  final List<UploadItem> items;
  _Group(this.key, this.label, this.isFolder, this.items);
}

class _StructureUploadDialogState extends State<_StructureUploadDialog> {
  final _uploader = DriveDirectUpload();
  late List<String> _folder = List<String>.of(widget.folder);
  String _audience = 'course';
  bool _busy = false;
  int _done = 0;
  String? _current;
  String? _error;
  final List<String> _failed = [];

  /// Cartella Drive scelta a mano per una voce (null = quella proposta).
  final Map<String, List<String>> _driveOverride = {};

  static String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9àèéìòù]+'), ' ').trim();
  static String _safe(String s) => s.replaceAll(RegExp(r'[\\/\x00-\x1f]'), '-').trim();

  /// Cartelle relative del file; la prima si salta se ha il nome della materia.
  List<String> _relative(UploadItem item) {
    final folders = item.folders;
    if (folders.isNotEmpty && _norm(folders.first) == _norm(widget.subjectName)) return folders.skip(1).toList();
    return folders;
  }

  String _groupKey(UploadItem item) {
    final rel = _relative(item);
    return rel.isNotEmpty ? 'd:${rel.first}' : 'f:${item.relativePath}';
  }

  late final List<_Group> _groups = () {
    final map = <String, _Group>{};
    for (final item in widget.selection.items) {
      final rel = _relative(item);
      final key = _groupKey(item);
      map.putIfAbsent(key, () => _Group(key, rel.isNotEmpty ? rel.first : item.name, rel.isNotEmpty, [])).items.add(item);
    }
    final list = map.values.toList()
      ..sort((a, b) => a.isFolder == b.isFolder
          ? a.label.toLowerCase().compareTo(b.label.toLowerCase())
          : (a.isFolder ? -1 : 1));
    return list;
  }();

  List<String> _catalogPath(UploadItem item) => [..._folder, ..._relative(item)];

  /// Cartella Drive proposta: «Materia / cartella della struttura».
  List<String> get _defaultDriveBase => [_safe(widget.subjectName), ..._folder.map(_safe)];

  /// Cartella Drive della voce (quella scelta a mano o la proposta).
  List<String> _driveBase(String key) => _driveOverride[key] ?? _defaultDriveBase;

  /// Percorso Drive completo del file: cartella della voce + sottocartelle del PC.
  List<String> _drivePath(UploadItem item) =>
      [..._driveBase(_groupKey(item)), ..._relative(item).map(_safe)];

  Future<void> _chooseDrive(_Group group) async {
    final chosen = await showDriveFolderPicker(context,
        api: widget.api,
        title: 'Dove mettere «${group.label}» su Drive?',
        hint: group.isFolder ? 'La cartella «${group.label}» verrà creata dentro quella che scegli.' : null);
    if (chosen != null && mounted) setState(() => _driveOverride[group.key] = chosen);
  }

  Future<void> _chooseDriveForAll() async {
    final chosen = await showDriveFolderPicker(context, api: widget.api, title: 'Dove mettere tutto su Drive?');
    if (chosen != null && mounted) {
      setState(() {
        for (final g in _groups) {
          _driveOverride[g.key] = chosen;
        }
      });
    }
  }

  Future<void> _start() async {
    final items = widget.selection.items;
    if (items.any((i) => _drivePath(i).length > 8)) {
      setState(() => _error = 'Alcuni file finirebbero oltre 8 cartelle su Drive: scegli una cartella meno profonda.');
      return;
    }
    if (items.any((i) => _drivePath(i).any((s) => s.length > 80))) {
      setState(() => _error = 'Un nome di cartella supera 80 caratteri: scegli un’altra cartella su Drive.');
      return;
    }
    setState(() { _busy = true; _done = 0; _error = null; _failed.clear(); });
    var notBooked = 0;
    final toDecide = <String>[];
    for (final item in items) {
      if (!mounted) return;
      setState(() => _current = item.relativePath);
      try {
        // v31: invio diretto su Drive; il file entra subito nella bozza.
        final r = await _uploader.upload(
          filename: item.name,
          bytes: item.bytes,
          pathSegments: _drivePath(item),
          stage: {'subject_id': widget.subjectId, 'path_segments': _catalogPath(item), 'audience_type': _audience},
        );
        if (r['mode'] == 'direct') {
          final staged = r['staged'];
          if (staged is Map && staged['staged'] != true) toDecide.add(item.name);
        } else {
          // Ripiego tramite Blob: il posto nella struttura si prenota subito, file per file.
          final job = r['job'] as Map? ?? const {};
          try {
            await widget.api.createCatalogIntent(
              kind: 'transfer',
              subjectId: widget.subjectId,
              audienceType: _audience,
              items: [{'job_id': '${job['id']}', 'path_segments': _catalogPath(item)}],
            );
          } catch (_) {
            notBooked++;
          }
        }
      } catch (e) {
        _failed.add('${item.name}: ${friendlyError(e, 'invio non riuscito')}');
        if (e is UserFacingError && e.status == 429) break;
      }
      if (mounted) setState(() => _done++);
    }
    if (toDecide.isNotEmpty) {
      _error = '${toDecide.length} file sono su Drive ma risultano già nel catalogo o uguali a un altro '
          '(${toDecide.take(3).join(', ')}${toDecide.length > 3 ? '…' : ''}): aggiungili dal pannello Drive con «+» '
          'per scegliere quale tenere.';
    }
    if (notBooked > 0) {
      _error = '$notBooked file sono su Drive ma non è stato possibile prenotarne l’aggiunta: '
          'aggiungili dalla pagina di caricamento, scheda Trasferimenti.';
    }
    if (!mounted) return;
    setState(() { _busy = false; _current = null; });
    if (_failed.isEmpty && _error == null) Navigator.pop(context, true);
  }

  Widget _groupRow(_Group g) {
    final theme = Theme.of(context);
    final custom = _driveOverride.containsKey(g.key);
    final target = ['StudentLab', ..._driveBase(g.key), if (g.isFolder) _safe(g.label)].join(' / ');
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(g.isFolder ? Icons.folder_outlined : Icons.insert_drive_file_outlined),
      title: Text(g.isFolder ? '${g.label} (${g.items.length} file)' : g.label,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('Drive: $target',
          maxLines: 2, overflow: TextOverflow.ellipsis,
          style: custom ? TextStyle(color: theme.colorScheme.primary) : null),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (custom)
          IconButton(
            tooltip: 'Torna alla cartella proposta',
            icon: const Icon(Icons.undo, size: 18),
            onPressed: _busy ? null : () => setState(() => _driveOverride.remove(g.key)),
          ),
        TextButton(onPressed: _busy ? null : () => _chooseDrive(g), child: const Text('Cambia')),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.selection.items;
    final total = items.fold<int>(0, (s, i) => s + i.size);
    final folders = {for (final i in items) _catalogPath(i).join(' / ')}.where((s) => s.isNotEmpty).length;
    final width = MediaQuery.sizeOf(context).width;
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: const Text('Aggiungi dal computer'),
        content: SizedBox(
          width: width < 620 ? width - 48 : 560,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
              Text('${items.length} file (${(total / (1024 * 1024)).toStringAsFixed(1)} MB)'
                  '${folders > 0 ? ' in $folders cartelle' : ''}. Cartelle e sottocartelle vengono ricreate.'),
              if (widget.selection.note != null) Text(widget.selection.note!),
              const SizedBox(height: 10),
              Text('Nella struttura per gli studenti', style: theme.textTheme.titleSmall),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.account_tree_outlined),
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
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: Text('Su Google Drive', style: theme.textTheme.titleSmall)),
                if (_groups.length > 1)
                  TextButton.icon(
                    onPressed: _busy ? null : _chooseDriveForAll,
                    icon: const Icon(Icons.drive_file_move_outline, size: 18),
                    label: const Text('Stessa cartella per tutti'),
                  ),
              ]),
              Text('Di base vanno in «Materia / cartella della struttura». Con «Cambia» scegli un’altra cartella '
                  'di Drive per ogni cartella o file: la posizione nella struttura per gli studenti non cambia.',
                  style: theme.textTheme.bodySmall),
              for (final g in _groups.take(60)) _groupRow(g),
              if (_groups.length > 60)
                Text('… e altre ${_groups.length - 60} voci (vanno nella cartella proposta o in quella scelta per tutti).',
                    style: theme.textTheme.bodySmall),
              const SizedBox(height: 6),
              const Text('Ogni file entra nella bozza appena arriva su Drive. '
                  'I file vanno direttamente su Drive. Resta su questa finestra fino alla fine: se la chiudi, '
                  'i file già inviati restano, quello in corso va ricaricato.'),
              if (_busy) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(value: items.isEmpty ? null : _done / items.length),
                if (_current != null) Text('Invio ${_done + 1} di ${items.length}: $_current',
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
              if (_failed.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('${_failed.length} file non inviati:', style: TextStyle(color: theme.colorScheme.error)),
                for (final f in _failed.take(8)) Text(f, style: theme.textTheme.bodySmall),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
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

// ---------------------------------------------------------------------------
// v31: scelta di una cartella su Google Drive (dentro la cartella StudentLab).
// Restituisce i nomi delle cartelle dalla radice StudentLab in giù;
// le cartelle nuove vengono create da Drive al momento della copia.
// ---------------------------------------------------------------------------

const _folderMime = 'application/vnd.google-apps.folder';

Future<List<String>?> showDriveFolderPicker(
  BuildContext context, {
  required AdminMaterialStorageApiService api,
  required String title,
  String? hint,
}) =>
    showDialog<List<String>>(
      context: context,
      builder: (_) => _DriveFolderPicker(api: api, title: title, hint: hint),
    );

class _DriveFolderPicker extends StatefulWidget {
  final AdminMaterialStorageApiService api;
  final String title;
  final String? hint;
  const _DriveFolderPicker({required this.api, required this.title, this.hint});
  @override
  State<_DriveFolderPicker> createState() => _DriveFolderPickerState();
}

class _DriveFolderPickerState extends State<_DriveFolderPicker> {
  /// Cartelle aperte: (id Drive o null se ancora da creare, nome).
  final List<({String? id, String name})> _trail = [];
  List<Map<String, dynamic>> _folders = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String? get _currentId => _trail.isEmpty ? null : _trail.last.id;
  bool get _isNew => _trail.isNotEmpty && _trail.last.id == null;

  Future<void> _load() async {
    if (_isNew) {
      setState(() { _folders = const []; _loading = false; _error = null; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final all = <Map<String, dynamic>>[];
      String? token;
      for (var page = 0; page < 10; page++) {
        final res = await widget.api.getDriveTree(_currentId, token);
        for (final e in (res['items'] as List? ?? const []).whereType<Map>()) {
          if (e['mime_type'] == _folderMime) all.add(Map<String, dynamic>.from(e));
        }
        token = res['next_page_token'] as String?;
        if (token == null || token.isEmpty) break;
      }
      if (!mounted) return;
      setState(() { _folders = all; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = friendlyError(e, 'Cartelle di Drive non disponibili. Riprova.'); });
    }
  }

  void _open(({String? id, String name}) folder) {
    setState(() => _trail.add(folder));
    _load();
  }

  void _goTo(int length) {
    setState(() => _trail.removeRange(length, _trail.length));
    _load();
  }

  Future<void> _newFolder() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuova cartella su Drive'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Crea')),
        ],
      ),
    );
    final clean = (name ?? '').replaceAll(RegExp(r'[\\/\x00-\x1f]'), '-').trim();
    if (clean.isEmpty || !mounted) return;
    final existing = _folders.where((f) => '${f['name']}'.toLowerCase() == clean.toLowerCase());
    if (existing.isNotEmpty) {
      _open((id: '${existing.first['id']}', name: '${existing.first['name']}'));
    } else {
      _open((id: null, name: clean));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: width < 560 ? width - 48 : 500,
        height: 420,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (widget.hint != null) Text(widget.hint!, style: theme.textTheme.bodySmall),
          const SizedBox(height: 6),
          Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
            TextButton(onPressed: _trail.isEmpty ? null : () => _goTo(0), child: const Text('StudentLab')),
            for (var i = 0; i < _trail.length; i++) ...[
              const Icon(Icons.chevron_right, size: 16),
              TextButton(
                onPressed: i == _trail.length - 1 ? null : () => _goTo(i + 1),
                child: Text(_trail[i].id == null ? '${_trail[i].name} (nuova)' : _trail[i].name),
              ),
            ],
          ]),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)))
                    : _folders.isEmpty
                        ? Center(child: Text(_isNew
                            ? 'Cartella nuova: verrà creata su Drive al momento della copia.'
                            : 'Nessuna sottocartella.'))
                        : ListView(children: [
                            for (final f in _folders)
                              ListTile(
                                dense: true,
                                leading: const Icon(Icons.folder_outlined),
                                title: Text('${f['name']}'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _open((id: '${f['id']}', name: '${f['name']}')),
                              ),
                          ]),
          ),
        ]),
      ),
      actions: [
        TextButton.icon(
          onPressed: _loading || _trail.length >= 7 ? null : _newFolder,
          icon: const Icon(Icons.create_new_folder_outlined, size: 18),
          label: const Text('Nuova cartella'),
        ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
        FilledButton(
          onPressed: _loading ? null : () => Navigator.pop(context, [for (final t in _trail) t.name]),
          child: const Text('Scegli questa cartella'),
        ),
      ],
    );
  }
}
