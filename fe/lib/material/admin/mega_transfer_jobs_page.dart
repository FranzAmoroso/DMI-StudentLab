import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/user_facing_error.dart';
import 'mega_storage_api_service.dart';

/// Copie MEGA → Drive.
///
/// v26: MEGA è un raccoglitore temporaneo. Quando una copia è completa e
/// verificata, l'app chiede ogni volta se eliminare gli originali da MEGA
/// (finiscono nel cestino di MEGA, quindi sono recuperabili).
class MegaTransferJobsPage extends StatefulWidget {
  const MegaTransferJobsPage({super.key});
  @override
  State<MegaTransferJobsPage> createState() => _MegaTransferJobsPageState();
}

class _MegaTransferJobsPageState extends State<MegaTransferJobsPage> {
  final _api = MegaStorageApiService();
  List<Map<String, dynamic>> _jobs = [];
  final Set<String> _staged = {};
  /// Copie per cui la domanda «elimina da MEGA?» è già stata fatta in questa sessione.
  final Set<String> _asked = {};
  bool _canDelete = false;
  bool _dialogOpen = false;
  Timer? _timer;
  bool _loading = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatus();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    try {
      final status = await _api.status();
      final permissions = status['permissions'];
      if (mounted) setState(() => _canDelete = permissions is Map && permissions['delete'] == true);
    } catch (_) {/* senza stato si nasconde solo l'eliminazione da MEGA */}
  }

  bool _deletable(Map<String, dynamic> job) =>
      _canDelete && job['state'] == 'completed' && _int(job['failed_files']) == 0 && job['source_deleted'] == null;

  /// Si chiede ogni volta: per ogni copia completata finché l'admin non sceglie.
  bool _undecided(Map<String, dynamic> job) => _deletable(job) && job['source_kept'] == null;

  Future<void> _load() async {
    if (_loading) return;
    _loading = true;
    try {
      final rows = await _api.jobs();
      if (!mounted) return;
      setState(() { _jobs = rows; _error = null; });
      final next = rows.where((j) => _undecided(j) && !_asked.contains('${j['id']}'));
      if (next.isNotEmpty && !_dialogOpen) unawaited(_askDelete(next.first, automatic: true));
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e, 'Copie non disponibili in questo momento.'));
    } finally {
      _loading = false;
    }
  }

  void _message(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// «Chiedi ogni volta»: dopo una copia verificata, conservare o eliminare da MEGA?
  Future<void> _askDelete(Map<String, dynamic> job, {bool automatic = false}) async {
    final id = '${job['id']}';
    _asked.add(id);
    _dialogOpen = true;
    final total = _int(job['total_files']);
    final choice = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(automatic ? 'Copia completata' : 'Eliminare da MEGA?'),
        content: Text(
          '«${job['name'] ?? 'Materiale'}»: $total file copiati e verificati su Drive '
          '(Drive / ${(job['destination'] as List? ?? []).join(' / ')}).\n\n'
          'Vuoi eliminare gli originali da MEGA? Finiscono nel cestino di MEGA e si possono recuperare da lì. '
          'Prima di eliminarli StudentLab ricontrolla le copie su Drive.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Conserva su MEGA')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Elimina da MEGA')),
        ],
      ),
    );
    _dialogOpen = false;
    if (!mounted || choice == null) return; // chiuso senza scegliere: si richiede alla prossima apertura
    if (choice == false) {
      try {
        await _api.keepSourceAfterCopy(id);
        await _load();
      } catch (_) {/* la domanda tornerà alla prossima apertura */}
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await _api.deleteSourceAfterCopy(id);
      final deleted = result['source_deleted'] is Map ? Map<String, dynamic>.from(result['source_deleted'] as Map) : null;
      final skipped = (deleted?['skipped'] as List? ?? const []).length;
      _message(skipped == 0
          ? 'Originali spostati nel cestino di MEGA.'
          : 'Originali spostati nel cestino di MEGA, tranne $skipped file cambiati nel frattempo.');
      await _load();
    } catch (e) {
      _message(friendlyError(e, 'Eliminazione da MEGA non riuscita. Gli originali sono ancora su MEGA.'));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _stage(String id) async {
    try {
      final result = await _api.stageCompleted(id);
      if (result['staged'] == true || result['already_published'] == true) {
        if (mounted) setState(() => _staged.add(id));
        _message(result['staged'] == true ? 'File nella bozza. Pubblica la struttura dal catalogo quando è pronta.' : 'File già pubblicato.');
      } else {
        _message('Possibile duplicato nelle Dispense. Controllalo dalla sorgente Drive prima di registrarlo.');
      }
    } catch (e) {
      _message(friendlyError(e, 'File non aggiunto alla bozza.'));
    }
  }

  Future<void> _retry(String id) async {
    try {
      await _api.retryJob(id);
      await _load();
    } catch (e) {
      _message(friendlyError(e, 'Nuovo tentativo non avviato.'));
    }
  }

  int _int(dynamic x) => x is num ? x.toInt() : int.tryParse('$x') ?? 0;

  String _status(String x) => {
        'queued': 'In coda',
        'running': 'Copia in corso',
        'completed': 'Copiato su Drive',
        'partial': 'Copia parziale',
        'failed': 'Copia non riuscita',
        'interrupted': 'Copia interrotta'
      }[x] ??
      'In lavorazione';

  String _mb(int bytes) => bytes < 1024 * 1024
      ? '${(bytes / 1024).toStringAsFixed(0)} KB'
      : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Copie MEGA → Drive'), actions: [
          IconButton(tooltip: 'Aggiorna', onPressed: _load, icon: const Icon(Icons.refresh)),
        ]),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            const Text('MEGA è il raccoglitore temporaneo: dopo ogni copia verificata ti chiediamo se eliminare gli originali. '
                'La pubblicazione nelle Dispense resta separata.'),
            const SizedBox(height: 12),
            if (_busy) const LinearProgressIndicator(),
            if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            if (_jobs.isEmpty && _error == null)
              const Padding(padding: EdgeInsets.all(24), child: Text('Nessuna copia avviata.')),
            for (final job in _jobs)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text('${job['name'] ?? 'Materiale'}', style: Theme.of(context).textTheme.titleMedium),
                    Text(_status('${job['state']}')),
                    Text('Drive / ${(job['destination'] as List? ?? []).join(' / ')}'),
                    Text('${_int(job['completed_files'])} copiati · ${_int(job['skipped_files'])} già copiati · '
                        '${_int(job['failed_files'])} non riusciti / ${_int(job['total_files'])} file'),
                    if (job['state'] == 'running' || job['state'] == 'queued') ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                          value: _int(job['total_bytes']) > 0
                              ? (_int(job['bytes_done']) / _int(job['total_bytes'])).clamp(0.0, 1.0).toDouble()
                              : null),
                      if (job['current_file'] != null)
                        Text('${job['phase'] == 'upload' ? 'Caricamento su Drive' : 'Download da MEGA'}: '
                            '${job['current_file']} · ${_mb(_int(job['current_bytes']))}'),
                    ],
                    if (job['error'] != null) Text('${job['error']}'),
                    if (job['source_deleted'] is Map)
                      const Text('Originali spostati nel cestino di MEGA.'),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      if (['failed', 'partial', 'interrupted'].contains(job['state']))
                        OutlinedButton.icon(
                            onPressed: () => _retry('${job['id']}'),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Riprova')),
                      if (job['state'] == 'completed' && job['import_options'] != null && !_staged.contains('${job['id']}'))
                        FilledButton(
                            onPressed: () => _stage('${job['id']}'),
                            child: const Text('Aggiungi alla bozza delle Dispense')),
                      if (_deletable(job))
                        OutlinedButton.icon(
                            onPressed: _busy || _dialogOpen ? null : () => _askDelete(job),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Elimina da MEGA…')),
                    ]),
                    if (job['results'] is List && (job['results'] as List).isNotEmpty)
                      ExpansionTile(title: const Text('Dettagli file'), children: [
                        for (final item in (job['results'] as List).whereType<Map>())
                          ListTile(
                              dense: true,
                              title: Text('${item['name']}'),
                              subtitle: Text(item['error']?.toString() ??
                                  (item['state'] == 'reused' ? 'Copia già presente su Drive' : 'Copiato su Drive'))),
                      ]),
                  ]),
                ),
              ),
          ]),
        ),
      );
}
