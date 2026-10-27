import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

import 'package:fe/services/user_facing_error.dart';

import 'transfer_upload_api.dart';
import 'upload/upload_items.dart';

/// Invio di materiale a StudentLab da parte degli studenti (v26).
///
/// I file arrivano nel raccoglitore temporaneo (MEGA) e vengono controllati
/// dagli amministratori prima di essere pubblicati nelle Dispense.
class StudentMegaUploadPage extends StatefulWidget {
  const StudentMegaUploadPage({super.key});

  @override
  State<StudentMegaUploadPage> createState() => _StudentMegaUploadPageState();
}

class _StudentMegaUploadPageState extends State<StudentMegaUploadPage> {
  final _api = TransferUploadApi(student: true);
  final _folder = TextEditingController();
  final List<UploadItem> _queue = [];
  List<Map<String, dynamic>> _jobs = [];
  List<String> _extensions = const ['pdf', 'docx', 'pptx', 'xlsx', 'txt', 'md', 'png', 'jpg', 'jpeg', 'zip'];
  bool? _enabled;
  bool _busy = false;
  bool _dragging = false;
  int _done = 0;
  String? _message;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _folder.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final status = await _api.studentStatus();
      final jobs = status['enabled'] == true ? await _api.list() : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        _enabled = status['enabled'] == true;
        if (status['extensions'] is List) {
          _extensions = (status['extensions'] as List).map((e) => '$e').toList();
        }
        _jobs = jobs;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() { _enabled ??= false; _error = friendlyError(e, 'Servizio non disponibile in questo momento.'); });
    }
  }

  bool _accepted(String name) => name.contains('.') && _extensions.contains(name.split('.').last.toLowerCase());

  void _add(UploadSelection? selection) {
    if (selection == null || !mounted) return;
    final accepted = selection.items.where((i) => _accepted(i.name)).toList();
    final refused = selection.items.length - accepted.length;
    setState(() {
      for (final item in accepted) {
        if (_queue.length < 20 && !_queue.any((q) => q.relativePath == item.relativePath)) _queue.add(item);
      }
      _message = [
        if (refused > 0) '$refused file di un tipo non accettato.',
        if (selection.note != null) selection.note!,
      ].join(' ');
      if (_message!.isEmpty) _message = null;
    });
  }

  Future<void> _send() async {
    if (_queue.isEmpty || _busy) return;
    setState(() { _busy = true; _done = 0; _error = null; _message = null; });
    final failed = <UploadItem>[];
    String? lastError;
    for (final item in List<UploadItem>.of(_queue)) {
      try {
        await _api.upload(
          filename: item.name,
          bytes: item.bytes,
          folder: _folder.text.trim().isEmpty ? null : _folder.text.trim(),
        );
      } catch (e) {
        failed.add(item);
        lastError = friendlyError(e, 'Invio non riuscito.');
        if (e is UserFacingError && (e.status == 429 || e.status == 409)) break;
      }
      if (mounted) setState(() => _done++);
    }
    if (!mounted) return;
    final sent = _done - failed.length;
    setState(() {
      _queue.removeWhere((i) => !failed.contains(i));
      _busy = false;
      _message = failed.isEmpty
          ? 'Grazie! $sent file inviati. Gli amministratori li controlleranno prima di pubblicarli.'
          : '$sent file inviati. ${lastError ?? ''}';
    });
    await _load();
  }

  static const _states = {
    'uploading': 'Invio in corso',
    'pending': 'Ricevuto, in attesa',
    'running': 'In elaborazione',
    'completed': 'Ricevuto',
    'failed': 'Non riuscito: invialo di nuovo',
    'cancelled': 'Annullato',
    'expired': 'Scaduto',
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Invia materiale')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if (_enabled == null) const LinearProgressIndicator(),
          if (_enabled == false)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error ?? 'L’invio di materiale non è attivo in questo momento. Riprova più tardi.'),
              ),
            ),
          if (_enabled == true) ...[
            const Text('Appunti, esercizi o slide che vuoi condividere: li riceve lo staff di StudentLab, '
                'che li controlla prima di pubblicarli nelle Dispense. Invia solo materiale tuo o che puoi condividere.'),
            const SizedBox(height: 12),
            TextField(
              controller: _folder,
              enabled: !_busy,
              maxLength: 80,
              decoration: const InputDecoration(
                labelText: 'Materia o argomento (facoltativo)',
                hintText: 'Analisi 1',
              ),
            ),
            DropTarget(
              enable: !_busy,
              onDragEntered: (_) => setState(() => _dragging = true),
              onDragExited: (_) => setState(() => _dragging = false),
              onDragDone: (details) async {
                setState(() => _dragging = false);
                _add(await itemsFromDrop(details.files));
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _dragging ? scheme.primary.withValues(alpha: 0.10) : null,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _dragging ? scheme.primary : scheme.outlineVariant),
                ),
                child: Column(children: [
                  Icon(Icons.upload_rounded, size: 34, color: scheme.primary),
                  const SizedBox(height: 6),
                  const Text('Trascina qui i file oppure sceglili', textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text('Fino a 50 MB per file · ${_extensions.map((e) => e.toUpperCase()).join(', ')}',
                      textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () async => _add(await pickUploadFiles(extensions: _extensions)),
                    icon: const Icon(Icons.attach_file_rounded),
                    label: const Text('Scegli file'),
                  ),
                ]),
              ),
            ),
            if (_message != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_message!)),
            if (_error != null)
              Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: TextStyle(color: scheme.error))),
            for (final item in _queue)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  tooltip: 'Togli',
                  onPressed: _busy ? null : () => setState(() => _queue.remove(item)),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            if (_busy) LinearProgressIndicator(value: _queue.isEmpty ? null : _done / _queue.length),
            if (_queue.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: FilledButton.icon(
                  onPressed: _busy ? null : _send,
                  icon: const Icon(Icons.send_rounded),
                  label: Text('Invia ${_queue.length} file'),
                ),
              ),
            if (_jobs.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('I tuoi invii', style: Theme.of(context).textTheme.titleMedium),
              for (final j in _jobs)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${j['filename']}'),
                  subtitle: Text(_states['${j['state']}'] ?? 'In elaborazione'),
                  trailing: ['uploading', 'pending', 'failed'].contains(j['state'])
                      ? TextButton(
                          onPressed: _busy
                              ? null
                              : () async {
                                  try {
                                    await _api.cancel('${j['id']}');
                                  } catch (e) {
                                    if (mounted) setState(() => _error = friendlyError(e, 'Annullamento non riuscito.'));
                                  }
                                  await _load();
                                },
                          child: const Text('Annulla'),
                        )
                      : null,
                ),
            ],
          ],
        ]),
      ),
    );
  }
}
