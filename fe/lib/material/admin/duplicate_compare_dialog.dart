import 'package:flutter/material.dart';

import '../../services/user_facing_error.dart';
import '../../social/admin/admin_material_storage_api_service.dart';
import 'drive_file_preview.dart';

/// Cosa fare con un file nuovo che somiglia a uno già nel catalogo (v27).
enum DuplicateAction { keepExisting, replace, keepBoth }

class DuplicateChoice {
  final DuplicateAction action;
  /// Per [DuplicateAction.replace]: il file del catalogo da sostituire.
  final Map<String, dynamic>? target;
  /// Per [DuplicateAction.keepBoth]: la cartella del file nuovo nelle Dispense.
  final List<String> path;
  const DuplicateChoice(this.action, {this.target, this.path = const <String>[]});
}

String _bytes(Object? value) {
  final size = int.tryParse('$value') ?? 0;
  if (size <= 0) return '—';
  if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
  return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String _date(Object? value) {
  final d = DateTime.tryParse('${value ?? ''}')?.toLocal();
  if (d == null) return '—';
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

List<String> _path(Object? value) => value is List ? value.map((e) => '$e').toList() : <String>[];

/// Dove si trova un file del catalogo: «Materia / cartella / sottocartella».
String catalogPlace(Map<String, dynamic> file) =>
    [if ('${file['subject_name'] ?? ''}'.isNotEmpty) '${file['subject_name']}', ..._path(file['path_segments'])]
        .join(' / ');

/// Confronto affiancato: il file nuovo e quelli già nel catalogo, con la scelta.
Future<DuplicateChoice?> showDuplicateCompare(
  BuildContext context, {
  required AdminMaterialStorageApiService api,
  required Map<String, dynamic> incoming,
  required List<Map<String, dynamic>> existing,
  required Future<List<String>?> Function(List<String> current) pickFolder,
}) =>
    showDialog<DuplicateChoice>(
      context: context,
      builder: (_) => _DuplicateCompareDialog(api: api, incoming: incoming, existing: existing, pickFolder: pickFolder),
    );

class _DuplicateCompareDialog extends StatefulWidget {
  final AdminMaterialStorageApiService api;
  final Map<String, dynamic> incoming;
  final List<Map<String, dynamic>> existing;
  final Future<List<String>?> Function(List<String> current) pickFolder;
  const _DuplicateCompareDialog({required this.api, required this.incoming, required this.existing, required this.pickFolder});
  @override
  State<_DuplicateCompareDialog> createState() => _DuplicateCompareDialogState();
}

class _DuplicateCompareDialogState extends State<_DuplicateCompareDialog> {
  late Map<String, dynamic> _target = widget.existing.first;

  Widget _card(BuildContext context, {required String label, required Map<String, dynamic> file,
      required bool incoming, bool selected = false, VoidCallback? onTap}) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? scheme.primary : scheme.outlineVariant, width: selected ? 2 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.primary)),
          const SizedBox(height: 4),
          Text('${file['title'] ?? file['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w700)),
          if ('${file['title'] ?? ''}'.isNotEmpty && file['title'] != file['name'])
            Text('${file['name'] ?? ''}', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(incoming ? 'Andrà in: ${catalogPlace(file)}' : 'Si trova in: ${catalogPlace(file)}'),
          Text('${_bytes(file['size'])} · ${incoming ? 'su Drive' : 'aggiunto il ${_date(file['created_at'])}'}'
              '${'${file['uploader_name'] ?? ''}'.isNotEmpty ? ' · ${file['uploader_name']}' : ''}'),
          if (!incoming && file['visibility_state'] != null && file['visibility_state'] != 'visible')
            const Text('Nascosto agli studenti'),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('Anteprima'),
              onPressed: () => showDriveFilePreview(context,
                  load: () => incoming
                      ? widget.api.downloadDriveFilePreview('${file['drive_file_id']}')
                      : widget.api.downloadPublicMaterialPreview(int.tryParse('${file['id']}') ?? 0),
                  name: '${file['name'] ?? 'file'}',
                  mimeType: '${file['mime_type'] ?? ''}'),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 760;
    final incomingCard = _card(context, label: 'FILE NUOVO', file: widget.incoming, incoming: true);
    final existingCards = [
      for (final f in widget.existing)
        _card(context,
            label: widget.existing.length > 1 ? 'GIÀ NEL CATALOGO · tocca per sceglierlo' : 'GIÀ NEL CATALOGO',
            file: f,
            incoming: false,
            selected: widget.existing.length > 1 && identical(f, _target),
            onTap: widget.existing.length > 1 ? () => setState(() => _target = f) : null),
    ];
    return AlertDialog(
      title: const Text('Possibile doppione'),
      content: SizedBox(
        width: wide ? 720 : width - 48,
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
            const Text('Hanno lo stesso nome e la stessa dimensione. Guarda le anteprime e scegli quale tenere.'),
            const SizedBox(height: 12),
            if (wide)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: incomingCard),
                const SizedBox(width: 12),
                Expanded(child: Column(children: [
                  for (var i = 0; i < existingCards.length; i++) ...[if (i > 0) const SizedBox(height: 8), existingCards[i]],
                ])),
              ])
            else ...[
              incomingCard,
              const SizedBox(height: 8),
              for (var i = 0; i < existingCards.length; i++) ...[if (i > 0) const SizedBox(height: 8), existingCards[i]],
            ],
          ]),
        ),
      ),
      actionsOverflowDirection: VerticalDirection.down,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, const DuplicateChoice(DuplicateAction.keepExisting)),
          child: const Text('Tieni quello già nel catalogo'),
        ),
        TextButton(
          onPressed: () async {
            final path = await widget.pickFolder(_path(widget.incoming['path_segments']));
            if (path != null && context.mounted) {
              Navigator.pop(context, DuplicateChoice(DuplicateAction.keepBoth, path: path));
            }
          },
          child: const Text('Tienili entrambi…'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, DuplicateChoice(DuplicateAction.replace, target: _target)),
          child: const Text('Sostituisci con il nuovo'),
        ),
      ],
    );
  }
}

/// Elenco dei file identici già nella struttura, per tenerne uno solo (v27).
Future<bool?> showCatalogDuplicates(BuildContext context, AdminMaterialStorageApiService api) =>
    showDialog<bool>(context: context, builder: (_) => _DuplicatesDialog(api: api));

class _DuplicatesDialog extends StatefulWidget {
  final AdminMaterialStorageApiService api;
  const _DuplicatesDialog({required this.api});
  @override
  State<_DuplicatesDialog> createState() => _DuplicatesDialogState();
}

class _DuplicatesDialogState extends State<_DuplicatesDialog> {
  List<List<Map<String, dynamic>>>? _groups;
  String? _error;
  bool _busy = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await widget.api.listCatalogDuplicates();
      final groups = [
        for (final g in (data['groups'] as List? ?? const []).whereType<Map>())
          (g['files'] as List? ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(),
      ];
      if (mounted) setState(() { _groups = groups; _error = null; });
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e, 'Elenco dei doppioni non disponibile.'));
    }
  }

  Future<void> _keep(List<Map<String, dynamic>> group, Map<String, dynamic> keep) async {
    final others = group.where((f) => !identical(f, keep)).toList();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tenere solo questo?'),
        content: Text('Gli altri ${others.length} file escono dalla struttura. Restano su Drive e si possono '
            'ripristinare da «Tolti dalla struttura».'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tieni solo questo')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await widget.api.removeFromStructure(
          materialIds: [for (final f in others) int.tryParse('${f['id']}') ?? 0].where((i) => i > 0).toList());
      _changed = true;
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e, 'Non è stato possibile togliere i doppioni.'));
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return AlertDialog(
      title: const Text('File identici nella struttura'),
      content: SizedBox(
        width: width < 720 ? width - 48 : 640,
        child: _groups == null && _error == null
            ? const Padding(padding: EdgeInsets.all(24), child: LinearProgressIndicator())
            : SingleChildScrollView(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
                  if (_busy) const LinearProgressIndicator(),
                  if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  if (_groups != null && _groups!.isEmpty)
                    const Padding(padding: EdgeInsets.all(16), child: Text('Nessun file identico: la struttura è pulita.')),
                  for (final group in _groups ?? const <List<Map<String, dynamic>>>[])
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Text('${group.first['name']} · ${group.length} copie identiche',
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          for (final f in group)
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(catalogPlace(f)),
                              subtitle: Text('Aggiunto il ${_date(f['created_at'])}'
                                  '${'${f['uploader_name'] ?? ''}'.isNotEmpty ? ' · ${f['uploader_name']}' : ''}'),
                              trailing: TextButton(
                                onPressed: _busy ? null : () => _keep(group, f),
                                child: const Text('Tieni questo'),
                              ),
                            ),
                        ]),
                      ),
                    ),
                ]),
              ),
      ),
      actions: [FilledButton(onPressed: () => Navigator.pop(context, _changed), child: const Text('Chiudi'))],
    );
  }
}
