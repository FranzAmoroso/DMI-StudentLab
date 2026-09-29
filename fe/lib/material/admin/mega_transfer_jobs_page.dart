import 'dart:async';
import 'package:flutter/material.dart';
import 'mega_storage_api_service.dart';

class MegaTransferJobsPage extends StatefulWidget {
  const MegaTransferJobsPage({super.key});
  @override
  State<MegaTransferJobsPage> createState() => _MegaTransferJobsPageState();
}
class _MegaTransferJobsPageState extends State<MegaTransferJobsPage> {
  final _api = MegaStorageApiService();
  List<Map<String, dynamic>> _jobs = [];
  final Set<String> _staged = {};
  Timer? _timer;
  bool _loading = false;
  String? _error;
  @override
  void initState() { super.initState(); _load(); _timer = Timer.periodic(const Duration(seconds: 3), (_) => _load()); }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }
  Future<void> _load() async {
    if (_loading) return;
    _loading = true;
    try { final rows = await _api.jobs(); if (mounted) setState(() { _jobs = rows; _error = null; }); }
    catch (e) { if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', '')); }
    finally { _loading = false; }
  }
  void _message(String text) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text))); }
  Future<void> _stage(String id) async {
    try {
      final result = await _api.stageCompleted(id);
      if (result['staged'] == true || result['already_published'] == true) {
        if (mounted) setState(() => _staged.add(id));
        _message(result['staged'] == true ? 'File nella bozza. Pubblica la struttura dal catalogo quando è pronta.' : 'File già pubblicato.');
      } else {
        _message('Possibile duplicato nelle Dispense. Controllalo dalla sorgente Drive prima di registrarlo.');
      }
    } catch (e) { _message(e.toString().replaceFirst('Exception: ', '')); }
  }
  Future<void> _retry(String id) async {
    try { await _api.retryJob(id); await _load(); }
    catch (e) { _message(e.toString().replaceFirst('Exception: ', '')); }
  }
  int _int(dynamic x) => x is num ? x.toInt() : int.tryParse('$x') ?? 0;
  String _status(String x) => {'queued':'In coda','running':'Copia in corso','completed':'Copiato su Drive','partial':'Copia parziale','failed':'Copia non riuscita','interrupted':'Copia interrotta'}[x] ?? x;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Copie MEGA → Drive'), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
    body: RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Gli originali MEGA sono conservati. I file copiati sono nella struttura Drive; la pubblicazione nelle Dispense resta separata.'),
      const SizedBox(height: 12),
      if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
      if (_jobs.isEmpty && _error == null) const Padding(padding: EdgeInsets.all(24), child: Text('Nessuna copia avviata.')),
      for (final job in _jobs) Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('${job['name'] ?? 'Materiale'}', style: Theme.of(context).textTheme.titleMedium),
        Text(_status('${job['state']}')),
        Text('Drive / ${(job['destination'] as List? ?? []).join(' / ')}'),
        Text('${_int(job['completed_files'])} copiati · ${_int(job['skipped_files'])} già copiati · ${_int(job['failed_files'])} non riusciti / ${_int(job['total_files'])} file'),
        if (job['state'] == 'running' || job['state'] == 'queued') ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(value: _int(job['total_bytes']) > 0 ? (_int(job['bytes_done']) / _int(job['total_bytes'])).clamp(0.0, 1.0).toDouble() : null),
          if (job['current_file'] != null) Text('${job['phase'] == 'upload' ? 'Caricamento' : 'Download'}: ${job['current_file']} · ${_int(job['current_bytes'])} byte'),
        ],
        if (job['error'] != null) Text('${job['error']}'),
        if (['failed','partial','interrupted'].contains(job['state'])) Align(alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(onPressed: () => _retry('${job['id']}'), icon: const Icon(Icons.refresh), label: const Text('Riprova'))),
        if (job['state'] == 'completed' && job['import_options'] != null && !_staged.contains('${job['id']}'))
          FilledButton(onPressed: () => _stage('${job['id']}'), child: const Text('Aggiungi alla bozza delle Dispense')),
        if (job['results'] is List && (job['results'] as List).isNotEmpty)
          ExpansionTile(title: const Text('Dettagli file'), children: [
            for (final item in (job['results'] as List).whereType<Map>()) ListTile(dense: true,
              title: Text('${item['name']}'), subtitle: Text(item['error']?.toString() ?? (item['state'] == 'reused' ? 'Copia già presente su Drive' : 'Copiato su Drive'))),
          ]),
      ]))),
    ])),
  );
}
