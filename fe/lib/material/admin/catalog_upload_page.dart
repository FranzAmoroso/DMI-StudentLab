import 'dart:async';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

import '../../services/user_facing_error.dart';
import '../../social/admin/admin_material_storage_api_service.dart';
import '../transfer_upload_api.dart';
import '../upload/upload_items.dart';
import 'drive_destination_dialog.dart';
import 'subject_hierarchy_filter.dart';

/// Caricamento di più file o di cartelle intere su Drive o MEGA (v26).
///
/// - si trascinano file e cartelle dal computer, oppure si scelgono;
/// - l'admin sceglie la cartella di destinazione; le sottocartelle trascinate
///   vengono ricreate sotto quella cartella;
/// - finita la copia su Drive, i file si aggiungono alla struttura (bozza)
///   scegliendo materia e destinatari.
class CatalogUploadPage extends StatefulWidget {
  /// 'drive' oppure 'mega'.
  final String initialDestination;
  final List<String> initialPath;
  final UploadSelection? initialSelection;
  final List<Map<String, dynamic>> subjects;
  final int? initialSubjectId;

  const CatalogUploadPage({
    super.key,
    this.initialDestination = 'drive',
    this.initialPath = const <String>[],
    this.initialSelection,
    this.subjects = const <Map<String, dynamic>>[],
    this.initialSubjectId,
  });

  @override
  State<CatalogUploadPage> createState() => _CatalogUploadPageState();
}

class _CatalogUploadPageState extends State<CatalogUploadPage> with SingleTickerProviderStateMixin {
  final _transfers = TransferUploadApi();
  final _storage = AdminMaterialStorageApiService();
  late final TabController _tabs = TabController(length: 3, vsync: this);
  late String _destination = widget.initialDestination == 'mega' ? 'mega' : 'drive';
  late List<String> _path = List<String>.of(widget.initialPath);
  final List<UploadItem> _queue = [];
  final Map<String, String> _itemErrors = {};
  List<Map<String, dynamic>> _jobs = [];
  List<Map<String, dynamic>> _students = [];
  late List<Map<String, dynamic>> _subjects = widget.subjects;
  final Set<String> _selectedJobs = {};
  final Set<String> _stagedDriveIds = {};
  String? _note;
  String? _error;
  String? _studentsError;
  bool _busy = false;
  bool _dragging = false;
  int _done = 0;
  String? _current;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSelection;
    if (initial != null) {
      _queue.addAll(initial.items);
      _note = initial.note;
    }
    _loadJobs();
    _tabs.addListener(() {
      if (_tabs.index == 2 && _students.isEmpty && _studentsError == null) _loadStudents();
    });
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted && !_busy && _tabs.index == 1) _loadJobs();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  String _bytes(int size) => size < 1024 * 1024
      ? '${(size / 1024).toStringAsFixed(1)} KB'
      : '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';

  Future<void> _loadJobs() async {
    try {
      final rows = await _transfers.list();
      Set<String> staged = {};
      try {
        final snapshot = await _storage.getCatalogSnapshot();
        staged = {
          for (final i in (snapshot['imports'] as List? ?? const []).whereType<Map>()) '${i['drive_file_id']}',
        };
      } catch (_) {/* senza bozza si mostra comunque l'elenco */}
      if (!mounted) return;
      setState(() {
        _jobs = rows;
        _stagedDriveIds.addAll(staged);
        _selectedJobs.removeWhere((id) => !rows.any((j) => '${j['id']}' == id));
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e, 'Elenco dei trasferimenti non disponibile.'));
    }
  }

  Future<void> _loadStudents() async {
    try {
      final rows = await _transfers.studentUploads();
      if (mounted) setState(() { _students = rows; _studentsError = null; });
    } catch (e) {
      if (mounted) setState(() => _studentsError = friendlyError(e, 'Caricamenti degli studenti non disponibili.'));
    }
  }

  void _add(UploadSelection? selection) {
    if (selection == null || !mounted) return;
    setState(() {
      final known = _queue.map((i) => i.relativePath).toSet();
      for (final item in selection.items) {
        if (known.add(item.relativePath) && _queue.length < uploadMaxFiles) _queue.add(item);
      }
      _note = selection.note;
      if (selection.items.isEmpty && selection.note == null) _note = 'Nessun file da aggiungere.';
    });
  }

  Future<void> _chooseDestination() async {
    if (_destination == 'drive') {
      final chosen = await showDialog<List<String>>(
        context: context,
        builder: (_) => DriveDestinationDialog(
          api: _storage,
          title: 'Dove caricare su Drive',
          intro: 'Le cartelle trascinate verranno ricreate dentro questa cartella.',
          confirmLabel: 'Usa questa cartella',
          initialPath: _path,
        ),
      );
      if (chosen != null && mounted) setState(() => _path = chosen);
      return;
    }
    final controller = TextEditingController(text: _path.join(' / '));
    final chosen = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dove caricare su MEGA'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Cartella dentro /StudentLab',
            hintText: 'Da smistare / Analisi 1',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
          FilledButton(
            onPressed: () {
              final parts = controller.text.trim().isEmpty
                  ? <String>[]
                  : controller.text.split('/').map((s) => s.trim()).toList();
              if (parts.any((p) => p.isEmpty || p == '.' || p == '..' || p.contains('\\') || p.length > 80) ||
                  parts.length > 8) {
                return;
              }
              Navigator.pop(ctx, parts);
            },
            child: const Text('Usa questa cartella'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (chosen != null && mounted) setState(() => _path = chosen);
  }

  Future<void> _upload() async {
    if (_queue.isEmpty || _busy) return;
    final tooDeep = _queue.where((i) => _path.length + i.folders.length > 8).length;
    if (tooDeep > 0) {
      setState(() => _error = '$tooDeep file finirebbero oltre 8 cartelle una dentro l’altra. Scegli una cartella meno profonda.');
      return;
    }
    setState(() {
      _busy = true;
      _done = 0;
      _error = null;
      _itemErrors.clear();
    });
    final failed = <UploadItem>[];
    for (final item in List<UploadItem>.of(_queue)) {
      if (!mounted) return;
      setState(() => _current = item.relativePath);
      try {
        await _transfers.upload(
          filename: item.name,
          bytes: item.bytes,
          destination: _destination,
          pathSegments: [..._path, ...item.folders],
        );
      } catch (e) {
        failed.add(item);
        _itemErrors[item.relativePath] = friendlyError(e, 'Caricamento non riuscito.');
        // Limite di 20 trasferimenti in attesa: inutile continuare.
        if (e is UserFacingError && e.status == 429) {
          final index = _queue.indexOf(item);
          failed.addAll(_queue.skip(index + 1));
          break;
        }
      }
      if (mounted) setState(() => _done++);
    }
    if (!mounted) return;
    final sent = _queue.length - failed.length;
    setState(() {
      _queue
        ..clear()
        ..addAll(failed);
      _busy = false;
      _current = null;
      _note = failed.isEmpty
          ? '$sent file inviati. La copia parte al prossimo avvio del servizio di trasferimento.'
          : '$sent file inviati, ${failed.length} da riprovare (sono rimasti nell’elenco).';
    });
    await _loadJobs();
    if (failed.isEmpty && mounted) _tabs.animateTo(1);
  }

  Future<void> _stageSelected() async {
    final jobs = _jobs.where((j) => _selectedJobs.contains('${j['id']}')).toList();
    if (jobs.isEmpty) return;
    if (_subjects.isEmpty) {
      try {
        _subjects = await _storage.getDriveImportOptions();
      } catch (e) {
        if (mounted) setState(() => _error = friendlyError(e, 'Materie non disponibili.'));
        return;
      }
    }
    if (!mounted) return;
    int? subjectId = widget.initialSubjectId;
    String audience = 'course';
    bool sameFolders = true;
    final folder = TextEditingController();
    final chosen = await showDialog<(int, String, bool, List<String>)>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: Text('Aggiungi ${jobs.length} file alla struttura'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Text('I file restano su Drive. Saranno visibili agli studenti dopo «Pubblica struttura».'),
                const SizedBox(height: 12),
                SubjectPickerField(subjects: _subjects, value: subjectId, onChanged: (v) => update(() => subjectId = v)),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: audience,
                  decoration: const InputDecoration(labelText: 'Destinatari'),
                  items: const [
                    DropdownMenuItem(value: 'public', child: Text('Tutti, anche guest')),
                    DropdownMenuItem(value: 'course', child: Text('Studenti del corso')),
                    DropdownMenuItem(value: 'subject', child: Text('Studenti della materia')),
                  ],
                  onChanged: (v) => update(() => audience = v ?? audience),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: sameFolders,
                  onChanged: (v) => update(() => sameFolders = v),
                  title: const Text('Stesse cartelle che hanno su Drive'),
                  subtitle: const Text('Disattiva per metterli tutti nella stessa cartella'),
                ),
                if (!sameFolders)
                  TextField(
                    controller: folder,
                    decoration: const InputDecoration(labelText: 'Cartella nelle Dispense', hintText: 'Esercizi / 2025-26'),
                  ),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
            FilledButton(
              onPressed: subjectId == null
                  ? null
                  : () {
                      final parts = folder.text.trim().isEmpty
                          ? <String>[]
                          : folder.text.split('/').map((s) => s.trim()).toList();
                      if (parts.any((p) => p.isEmpty)) return;
                      Navigator.pop(ctx, (subjectId!, audience, sameFolders, parts));
                    },
              child: const Text('Aggiungi alla bozza'),
            ),
          ],
        ),
      ),
    );
    folder.dispose();
    if (chosen == null || !mounted) return;
    setState(() => _busy = true);
    var staged = 0, duplicates = 0, tooBig = 0, failed = 0;
    String? lastError;
    for (final job in jobs) {
      final driveId = '${job['result_id']}';
      if ((int.tryParse('${job['size']}') ?? 0) > 20 * 1024 * 1024) {
        tooBig++;
        continue;
      }
      final path = chosen.$3
          ? (job['path_segments'] as List? ?? const []).map((e) => '$e').toList()
          : chosen.$4;
      try {
        final result = await _storage.stageDriveImport(
          fileId: driveId,
          subjectId: chosen.$1,
          pathSegments: path,
          audienceType: chosen.$2,
        );
        if (result['staged'] == true) {
          staged++;
          _stagedDriveIds.add(driveId);
        } else {
          duplicates++;
        }
      } catch (e) {
        failed++;
        lastError = friendlyError(e, 'File non aggiunto.');
      }
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _selectedJobs.clear();
      _note = [
        '$staged file aggiunti alla bozza.',
        if (duplicates > 0) '$duplicates possibili duplicati: controllali dal Catalogo.',
        if (tooBig > 0) '$tooBig oltre 20 MB: restano su Drive ma non entrano nelle Dispense.',
        if (failed > 0) '$failed non aggiunti. ${lastError ?? ''}',
      ].join(' ');
    });
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  Widget _uploadTab() {
    final scheme = Theme.of(context).colorScheme;
    final total = _queue.fold<int>(0, (sum, i) => sum + i.size);
    return ListView(padding: const EdgeInsets.all(16), children: [
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'drive', icon: Icon(Icons.cloud_outlined), label: Text('Google Drive')),
          ButtonSegment(value: 'mega', icon: Icon(Icons.inventory_2_outlined), label: Text('MEGA (raccoglitore)')),
        ],
        selected: {_destination},
        onSelectionChanged: _busy ? null : (v) => setState(() { _destination = v.first; _path = []; }),
      ),
      const SizedBox(height: 12),
      Card(
        child: ListTile(
          leading: const Icon(Icons.folder_outlined),
          title: Text([_destination == 'drive' ? 'Drive · StudentLab' : 'MEGA · StudentLab', ..._path].join(' / ')),
          subtitle: const Text('Cartella di destinazione'),
          trailing: TextButton(onPressed: _busy ? null : _chooseDestination, child: const Text('Cambia')),
        ),
      ),
      const SizedBox(height: 12),
      DropTarget(
        enable: !_busy,
        onDragEntered: (_) => setState(() => _dragging = true),
        onDragExited: (_) => setState(() => _dragging = false),
        onDragDone: (details) async {
          setState(() => _dragging = false);
          _add(await itemsFromDrop(details.files));
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _dragging ? scheme.primary.withValues(alpha: 0.10) : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _dragging ? scheme.primary : scheme.outlineVariant, width: _dragging ? 2 : 1),
          ),
          child: Column(children: [
            Icon(Icons.upload_file_rounded, size: 36, color: scheme.primary),
            const SizedBox(height: 8),
            Text(_dragging ? 'Rilascia per aggiungere' : 'Trascina qui file o cartelle',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Fino a 50 MB per file, massimo 500 file. Le sottocartelle vengono conservate.',
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
              OutlinedButton.icon(
                onPressed: _busy ? null : () async => _add(await pickUploadFiles()),
                icon: const Icon(Icons.insert_drive_file_outlined),
                label: const Text('Scegli file'),
              ),
              if (canPickFolder)
                OutlinedButton.icon(
                  onPressed: _busy ? null : () async => _add(await pickUploadFolder()),
                  icon: const Icon(Icons.folder_open_outlined),
                  label: const Text('Scegli cartella'),
                ),
            ]),
          ]),
        ),
      ),
      if (_note != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_note!)),
      if (_error != null)
        Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: TextStyle(color: scheme.error))),
      if (_busy && _current != null) ...[
        const SizedBox(height: 12),
        LinearProgressIndicator(value: _queue.isEmpty ? null : _done / _queue.length),
        const SizedBox(height: 4),
        Text('Invio ${_done + 1} di ${_queue.length}: $_current', maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
      if (_queue.isNotEmpty) ...[
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Text('${_queue.length} file · ${_bytes(total)}', style: const TextStyle(fontWeight: FontWeight.w700))),
          TextButton(onPressed: _busy ? null : () => setState(() { _queue.clear(); _itemErrors.clear(); }), child: const Text('Svuota')),
        ]),
        for (final item in _queue)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.insert_drive_file_outlined),
            title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              _itemErrors[item.relativePath] ??
                  '${[..._path, ...item.folders].isEmpty ? 'Cartella scelta' : [..._path, ...item.folders].join(' / ')} · ${_bytes(item.size)}',
              style: _itemErrors.containsKey(item.relativePath) ? TextStyle(color: scheme.error) : null,
            ),
            trailing: IconButton(
              tooltip: 'Togli dall’elenco',
              onPressed: _busy ? null : () => setState(() => _queue.remove(item)),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _busy ? null : _upload,
          icon: const Icon(Icons.cloud_upload_outlined),
          label: Text('Carica ${_queue.length} file su ${_destination == 'drive' ? 'Drive' : 'MEGA'}'),
        ),
      ],
    ]);
  }

  static const _states = {
    'uploading': 'Invio da confermare',
    'pending': 'In attesa della copia',
    'running': 'Copia in corso',
    'failed': 'Copia non riuscita',
    'completed': 'Copia verificata',
    'cancelled': 'Annullato',
    'expired': 'Scaduto',
  };

  Future<void> _jobAction(String id, Future<void> Function(String) action) async {
    setState(() => _busy = true);
    try {
      await action(id);
      await _loadJobs();
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e, 'Operazione non riuscita.'));
    }
    if (mounted) setState(() => _busy = false);
  }

  Widget _jobsTab() {
    final scheme = Theme.of(context).colorScheme;
    final stageable = _jobs.where((j) =>
        j['state'] == 'completed' && j['destination'] == 'drive' &&
        '${j['result_id'] ?? ''}'.isNotEmpty && !_stagedDriveIds.contains('${j['result_id']}')).toList();
    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Il file resta nel deposito temporaneo finché la copia non è verificata, poi viene eliminato da lì. '
            'I tentativi non completati scadono dopo 7 giorni.'),
        if (_error != null)
          Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: TextStyle(color: scheme.error))),
        if (_note != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_note!)),
        if (stageable.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text('${stageable.length} file su Drive non ancora nella struttura'),
            TextButton(
              onPressed: _busy ? null : () => setState(() => _selectedJobs.addAll(stageable.map((j) => '${j['id']}'))),
              child: const Text('Seleziona tutti'),
            ),
            FilledButton.icon(
              onPressed: _busy || _selectedJobs.isEmpty ? null : _stageSelected,
              icon: const Icon(Icons.playlist_add_rounded),
              label: Text('Aggiungi alla struttura (${_selectedJobs.length})'),
            ),
          ]),
        ],
        const SizedBox(height: 8),
        if (_jobs.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('Nessun caricamento.')),
        for (final j in _jobs)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (stageable.contains(j))
                  Checkbox(
                    value: _selectedJobs.contains('${j['id']}'),
                    onChanged: _busy
                        ? null
                        : (v) => setState(() => v == true
                            ? _selectedJobs.add('${j['id']}')
                            : _selectedJobs.remove('${j['id']}')),
                  ),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${j['filename']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('${j['destination'] == 'mega' ? 'MEGA' : 'Drive'} · ${_states['${j['state']}'] ?? 'In lavorazione'}'),
                    Text((j['path_segments'] as List? ?? const []).join(' / ')),
                    if (j['error'] != null) Text('${j['error']}', style: TextStyle(color: scheme.error)),
                    if (j['state'] == 'completed' && _stagedDriveIds.contains('${j['result_id']}'))
                      const Text('Nella bozza della struttura'),
                    Wrap(spacing: 8, children: [
                      if (j['state'] == 'failed' && j['cleaned'] != true)
                        TextButton(onPressed: _busy ? null : () => _jobAction('${j['id']}', _transfers.retry), child: const Text('Riprova')),
                      if (j['state'] == 'uploading')
                        TextButton(onPressed: _busy ? null : () => _jobAction('${j['id']}', _transfers.confirm), child: const Text('Verifica invio')),
                      if (['uploading', 'pending', 'failed'].contains(j['state']))
                        TextButton(onPressed: _busy ? null : () => _jobAction('${j['id']}', _transfers.cancel), child: const Text('Annulla')),
                    ]),
                  ]),
                ),
              ]),
            ),
          ),
      ]),
    );
  }

  Widget _studentsTab() {
    final scheme = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _loadStudents,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('I file inviati dagli studenti arrivano su MEGA in «Caricamenti studenti», una cartella per studente. '
            'Aprili dal Catalogo con la sorgente MEGA e scegli dove copiarli su Drive. '
            'Dopo la copia l’app ti chiede se eliminarli da MEGA.'),
        if (_studentsError != null)
          Padding(padding: const EdgeInsets.only(top: 8), child: Text(_studentsError!, style: TextStyle(color: scheme.error))),
        const SizedBox(height: 8),
        if (_students.isEmpty && _studentsError == null)
          const Padding(padding: EdgeInsets.all(24), child: Text('Nessun file dagli studenti.')),
        for (final j in _students)
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text('${j['filename']}'),
            subtitle: Text([
              '${j['student_name']}',
              _states['${j['state']}'] ?? 'In lavorazione',
              (j['path_segments'] as List? ?? const []).skip(2).join(' / '),
            ].where((s) => s.trim().isNotEmpty).join(' · ')),
          ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_busy,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Carica file e cartelle'),
            actions: [
              IconButton(
                tooltip: 'Aggiorna',
                onPressed: _busy ? null : () => _tabs.index == 2 ? _loadStudents() : _loadJobs(),
                icon: const Icon(Icons.refresh),
              ),
            ],
            bottom: TabBar(controller: _tabs, isScrollable: true, tabs: const [
              Tab(text: 'Carica'),
              Tab(text: 'Trasferimenti'),
              Tab(text: 'Dagli studenti'),
            ]),
          ),
          body: TabBarView(controller: _tabs, children: [_uploadTab(), _jobsTab(), _studentsTab()]),
        ),
      );
}
