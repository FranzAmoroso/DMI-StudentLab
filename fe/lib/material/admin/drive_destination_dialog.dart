import 'package:flutter/material.dart';

import '../../services/user_facing_error.dart';
import '../../social/admin/admin_material_storage_api_service.dart';

/// Scelta di una cartella di destinazione su Google Drive (dentro StudentLab).
///
/// Restituisce i nomi delle cartelle, dalla radice StudentLab in giù
/// (es. ['Analisi 1', 'Esercizi']); una lista vuota indica la radice.
/// Usata per le copie MEGA → Drive, per l'import da MEGA e per i caricamenti.
class DriveDestinationDialog extends StatefulWidget {
  final AdminMaterialStorageApiService api;
  final String title;
  final String intro;
  final String confirmLabel;
  final List<String> initialPath;

  const DriveDestinationDialog({
    super.key,
    required this.api,
    this.title = 'Cartella su Drive',
    this.intro = '',
    this.confirmLabel = 'Scegli',
    this.initialPath = const <String>[],
  });

  @override
  State<DriveDestinationDialog> createState() => _DriveDestinationDialogState();
}

class _DriveDestinationDialogState extends State<DriveDestinationDialog> {
  /// (id cartella Drive, nome)
  final List<(String, String)> _path = [];
  final _newFolder = TextEditingController();
  List<Map<String, dynamic>> _folders = [];
  bool _loading = true;
  String? _error;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _openInitial();
  }

  @override
  void dispose() {
    _request++;
    _newFolder.dispose();
    super.dispose();
  }

  /// Apre il percorso iniziale cartella per cartella; se una cartella non esiste,
  /// il resto del percorso diventa la «nuova sottocartella» da creare.
  Future<void> _openInitial() async {
    final wanted = widget.initialPath.where((s) => s.trim().isNotEmpty).toList();
    await _load();
    for (var i = 0; i < wanted.length && mounted && _error == null; i++) {
      final match = _folders.where((f) => '${f['name']}' == wanted[i]);
      if (match.isEmpty) {
        _newFolder.text = wanted.skip(i).join(' / ');
        break;
      }
      _path.add(('${match.first['id']}', wanted[i]));
      await _load();
    }
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = <Map<String, dynamic>>[];
      String? token;
      do {
        final page = await widget.api.getDriveTree(_path.isEmpty ? null : _path.last.$1, token);
        rows.addAll((page['items'] as List? ?? []).whereType<Map>().map((x) => Map<String, dynamic>.from(x)));
        token = page['next_page_token']?.toString();
      } while (token != null && token.isNotEmpty);
      if (mounted && request == _request) {
        setState(() => _folders = rows.where((x) => x['mime_type'] == 'application/vnd.google-apps.folder').toList());
      }
    } catch (e) {
      if (mounted && request == _request) {
        setState(() => _error = friendlyError(e, 'Non è stato possibile aprire le cartelle di Drive.'));
      }
    }
    if (mounted && request == _request) setState(() => _loading = false);
  }

  List<String>? _extra() {
    final raw = _newFolder.text.trim();
    if (raw.isEmpty) return const <String>[];
    final parts = raw.split('/').map((s) => s.trim()).toList();
    if (parts.any((p) => p.isEmpty || p == '.' || p == '..' || p.contains('\\') || p.length > 80)) return null;
    return parts;
  }

  void _choose() {
    final extra = _extra();
    if (extra == null) {
      setState(() => _error = 'Scrivi nomi di cartella validi, separati da «/».');
      return;
    }
    final parts = [for (final item in _path) item.$2, ...extra];
    if (parts.length > 12) {
      setState(() => _error = 'Massimo 12 cartelle una dentro l’altra.');
      return;
    }
    Navigator.pop(context, parts);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final extra = _extra() ?? const <String>[];
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: width < 560 ? width - 48 : 480,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (widget.intro.isNotEmpty) ...[Text(widget.intro), const SizedBox(height: 12)],
            Text('Destinazione: ${['StudentLab', ..._path.map((x) => x.$2), ...extra].join(' / ')}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            if (_path.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _loading
                      ? null
                      : () {
                          _path.removeLast();
                          _load();
                        },
                  icon: const Icon(Icons.arrow_upward),
                  label: const Text('Cartella superiore'),
                ),
              ),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            if (!_loading && _error == null && _folders.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Nessuna sottocartella qui.')),
            for (final folder in _folders)
              ListTile(
                dense: true,
                leading: const Icon(Icons.folder_outlined),
                title: Text('${folder['name']}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _loading
                    ? null
                    : () {
                        _path.add(('${folder['id']}', '${folder['name']}'));
                        _load();
                      },
              ),
            const SizedBox(height: 6),
            TextField(
              controller: _newFolder,
              onChanged: (_) => setState(() => _error = null),
              decoration: const InputDecoration(
                labelText: 'Nuove sottocartelle (facoltative)',
                hintText: 'Esercizi / 2025-26',
                helperText: 'Vengono create su Drive solo al momento della copia.',
              ),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
        FilledButton(onPressed: _loading ? null : _choose, child: Text(widget.confirmLabel)),
      ],
    );
  }
}
