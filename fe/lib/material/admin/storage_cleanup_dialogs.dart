import 'package:flutter/material.dart';

import '../../services/user_facing_error.dart';
import '../../social/admin/admin_material_storage_api_service.dart';
import '../transfer_upload_api.dart';

// ---------------------------------------------------------------------------
// v31: pulizia del Blob e caricamenti interrotti, dentro «Gestione materiale».
// I dettagli tecnici degli errori vanno solo nel registro diagnostico.
// ---------------------------------------------------------------------------

int _int(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;

String _bytes(dynamic value) {
  final size = _int(value);
  if (size < 1024) return '$size B';
  if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
  if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

double _width(BuildContext context, double max) {
  final w = MediaQuery.sizeOf(context).width;
  return w < max + 48 ? w - 48 : max;
}

/// Pulizia dello storage Blob. Restituisce true se qualcosa è stato eliminato.
Future<bool?> showStorageCleanupDialog(BuildContext context, {required AdminMaterialStorageApiService api}) =>
    showDialog<bool>(context: context, barrierDismissible: false, builder: (_) => _CleanupDialog(api: api));

class _CleanupDialog extends StatefulWidget {
  final AdminMaterialStorageApiService api;
  const _CleanupDialog({required this.api});
  @override
  State<_CleanupDialog> createState() => _CleanupDialogState();
}

class _CleanupDialogState extends State<_CleanupDialog> {
  Map<String, dynamic>? _data;
  String? _error;
  bool _busy = false;
  String? _result;
  bool _rejected = true, _removed = true, _orphans = true, _transfers = true;
  final _confirm = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _data = null; _error = null; });
    try {
      final d = await widget.api.getCleanupDryRun();
      if (mounted) setState(() => _data = d);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e, 'Analisi dello storage non riuscita. Riprova tra poco.'));
    }
  }

  List<Map<String, dynamic>> _list(String key) =>
      (_data?[key] as List? ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();

  List<Map<String, dynamic>> get _rejectedItems =>
      _list('record_candidates').where((i) => i['source'] == 'publication_request' && i['status'] == 'rejected').toList();
  List<Map<String, dynamic>> get _removedItems =>
      _list('record_candidates').where((i) => i['status'] == 'removed' && {'public', 'teacher', 'group'}.contains(i['source'])).toList();

  int _sum(List<Map<String, dynamic>> items, String key) => items.fold(0, (s, i) => s + _int(i[key]));

  Future<void> _run() async {
    setState(() { _busy = true; _error = null; });
    try {
      final r = await widget.api.executeCleanup(
        rejectedPublications: _rejected,
        removedMaterials: _removed,
        orphanBlobs: _orphans,
        temporaryTransfers: _transfers,
      );
      final failed = _int(r['failed_count']);
      _result = '${_int(r['deleted_count'])} file eliminati · ${_bytes(r['freed_bytes'])} liberati.'
          '${failed > 0 ? ' $failed non eliminati: riprova più tardi (dettagli nel registro diagnostico).' : ''}';
      _confirm.clear();
      await _load();
    } catch (e) {
      _error = friendlyError(e, 'Pulizia non riuscita. Nessun file è stato toccato oltre a quelli già eliminati.');
    }
    if (mounted) setState(() => _busy = false);
  }

  Widget _option(bool value, ValueChanged<bool> onChanged, String title, String subtitle, int count, int bytes) =>
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: value && count > 0,
        onChanged: _busy || count == 0 ? null : (v) => setState(() => onChanged(v ?? false)),
        title: Text('$title · $count${count > 0 ? ' (${_bytes(bytes)})' : ''}'),
        subtitle: Text(subtitle),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = _data;
    final rejected = _rejectedItems, removed = _removedItems;
    final orphans = _list('orphan_candidates'), transfers = _list('transfer_candidates');
    final protected = (d?['protected_blobs'] as Map?) ?? const {};
    final selected = (_rejected ? rejected.length : 0) + (_removed ? removed.length : 0) +
        (_orphans ? orphans.length : 0) + (_transfers ? transfers.length : 0);
    final ready = selected > 0 && _confirm.text.trim() == 'ELIMINA' && !_busy;
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: const Text('Pulizia dello storage'),
        content: SizedBox(
          width: _width(context, 560),
          child: d == null && _error == null
              ? const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
              : SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    if (d != null) ...[
                      const Text('Elimina dal Blob i file che non servono più. Su Drive e MEGA non cambia nulla. '
                          'L’eliminazione dal Blob è definitiva.'),
                      const SizedBox(height: 8),
                      _option(_transfers, (v) => _transfers = v, 'Copie temporanee dei trasferimenti',
                          'File già copiati su Drive o MEGA, annullati o scaduti. Mai quelli in corso.',
                          transfers.length, _sum(transfers, 'size')),
                      _option(_removed, (v) => _removed = v, 'Materiali tolti',
                          'Materiali già rimossi dalle Dispense, dai docenti o dai gruppi.',
                          removed.length, _sum(removed, 'blob_size')),
                      _option(_rejected, (v) => _rejected = v, 'Proposte rifiutate',
                          'File delle proposte di pubblicazione rifiutate.',
                          rejected.length, _sum(rejected, 'blob_size')),
                      _option(_orphans, (v) => _orphans = v, 'File dei materiali senza riferimenti',
                          'Caricati da più di 2 ore ma non collegati a nessun materiale.',
                          orphans.length, _sum(orphans, 'size')),
                      const SizedBox(height: 6),
                      Text('Non vengono mai toccati i dati dell’app (quiz, esercizi, FAQ, allegati delle domande): '
                          '${_int(protected['count'])} file, ${_bytes(protected['bytes'])}.',
                          style: theme.textTheme.bodySmall),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirm,
                        enabled: !_busy && selected > 0,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(labelText: 'Scrivi ELIMINA per confermare'),
                      ),
                    ],
                    if (_busy) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
                    if (_result != null)
                      Padding(padding: const EdgeInsets.only(top: 10),
                          child: Text(_result!, style: TextStyle(color: theme.colorScheme.primary))),
                    if (_error != null)
                      Padding(padding: const EdgeInsets.only(top: 10),
                          child: Text(_error!, style: TextStyle(color: theme.colorScheme.error))),
                  ]),
                ),
        ),
        actions: [
          TextButton(onPressed: _busy ? null : () => Navigator.pop(context, _result != null), child: const Text('Chiudi')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error, foregroundColor: theme.colorScheme.onError),
            onPressed: ready ? _run : null,
            child: Text(selected == 0 ? 'Niente da pulire' : 'Elimina $selected file'),
          ),
        ],
      ),
    );
  }
}

/// Caricamenti interrotti (pagina chiusa durante l'invio): riprendi o elimina.
Future<bool?> showInterruptedUploadsDialog(BuildContext context) =>
    showDialog<bool>(context: context, barrierDismissible: false, builder: (_) => const _InterruptedDialog());

class _InterruptedDialog extends StatefulWidget {
  const _InterruptedDialog();
  @override
  State<_InterruptedDialog> createState() => _InterruptedDialogState();
}

class _InterruptedDialogState extends State<_InterruptedDialog> {
  final _api = TransferUploadApi();
  List<Map<String, dynamic>>? _items;
  String? _error;
  String? _result;
  bool _busy = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _items = null; _error = null; });
    try {
      final items = await _api.interrupted();
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e, 'Elenco dei caricamenti interrotti non disponibile.'));
    }
  }

  Future<void> _resolve(List<Map<String, dynamic>> items, String action) async {
    if (items.isEmpty) return;
    setState(() { _busy = true; _error = null; });
    try {
      final r = await _api.resolveInterrupted([for (final i in items) '${i['id']}'], action);
      _changed = true;
      final parts = <String>[
        if (_int(r['resumed']) > 0) '${_int(r['resumed'])} ripresi: la copia riparte in pochi minuti',
        if (_int(r['deleted']) > 0) '${_int(r['deleted'])} eliminati',
        if (_int(r['incomplete']) > 0) '${_int(r['incomplete'])} incompleti: vanno eliminati e ricaricati',
        if (_int(r['failed']) > 0) '${_int(r['failed'])} non riusciti (dettagli nel registro diagnostico)',
      ];
      _result = parts.isEmpty ? 'Nessuna modifica.' : '${parts.join(' · ')}.';
      await _load();
    } catch (e) {
      _error = friendlyError(e, 'Operazione non riuscita. Riprova.');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _items;
    final complete = items?.where((i) => i['blob_complete'] == true).toList() ?? const <Map<String, dynamic>>[];
    final broken = items?.where((i) => i['blob_complete'] != true).toList() ?? const <Map<String, dynamic>>[];
    String where(Map<String, dynamic> i) {
      final dest = i['destination'] == 'mega' ? 'MEGA' : 'Drive';
      final path = (i['path_segments'] as List? ?? const []).join(' / ');
      return '$dest${path.isEmpty ? '' : ': $path'}${i['student'] == true ? ' · studente' : ''}';
    }

    Widget row(Map<String, dynamic> i) {
      final ok = i['blob_complete'] == true;
      return ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: Icon(ok ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
            color: ok ? theme.colorScheme.primary : theme.colorScheme.error),
        title: Text('${i['filename']} · ${_bytes(i['size'])}', maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${where(i)}\n${ok ? 'File arrivato per intero: si può riprendere' : 'File incompleto o assente'}',
            maxLines: 2, overflow: TextOverflow.ellipsis),
        isThreeLine: true,
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (ok)
            IconButton(tooltip: 'Riprendi la copia', icon: const Icon(Icons.play_arrow_rounded),
                onPressed: _busy ? null : () => _resolve([i], 'resume')),
          IconButton(tooltip: 'Elimina', icon: const Icon(Icons.delete_outline),
              onPressed: _busy ? null : () => _resolve([i], 'delete')),
        ]),
      );
    }

    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: const Text('Caricamenti interrotti'),
        content: SizedBox(
          width: _width(context, 580),
          child: items == null && _error == null
              ? const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
              : SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    const Text('Invii lasciati a metà, per esempio chiudendo la pagina. Se il file è arrivato per intero '
                        'puoi riprendere la copia verso Drive o MEGA: i file della struttura entrano poi nella bozza '
                        'da soli. Altrimenti eliminalo e liberi il posto.'),
                    const SizedBox(height: 8),
                    if (items != null && items.isEmpty) const Text('Nessun caricamento interrotto.'),
                    if (items != null) for (final i in items.take(200)) row(i),
                    if (_busy) const Padding(padding: EdgeInsets.only(top: 10), child: LinearProgressIndicator()),
                    if (_result != null)
                      Padding(padding: const EdgeInsets.only(top: 10),
                          child: Text(_result!, style: TextStyle(color: theme.colorScheme.primary))),
                    if (_error != null)
                      Padding(padding: const EdgeInsets.only(top: 10),
                          child: Text(_error!, style: TextStyle(color: theme.colorScheme.error))),
                  ]),
                ),
        ),
        actions: [
          TextButton(onPressed: _busy ? null : () => Navigator.pop(context, _changed), child: const Text('Chiudi')),
          if (broken.isNotEmpty)
            TextButton(onPressed: _busy ? null : () => _resolve(broken, 'delete'),
                child: Text('Elimina gli incompleti (${broken.length})')),
          if (complete.isNotEmpty)
            FilledButton(onPressed: _busy ? null : () => _resolve(complete, 'resume'),
                child: Text('Riprendi i completi (${complete.length})')),
        ],
      ),
    );
  }
}
