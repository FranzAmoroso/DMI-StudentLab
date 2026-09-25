import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../social/admin/admin_material_storage_api_service.dart';
import '../../theme/app_palette.dart';
import '../../widgets/studentlab_ui/studentlab_ui.dart';
import 'drive_file_preview.dart';

/// La struttura StudentLab è indipendente dai percorsi fisici su Drive.
class AdminDriveCatalogPage extends StatefulWidget {
  const AdminDriveCatalogPage({super.key});

  @override
  State<AdminDriveCatalogPage> createState() => _AdminDriveCatalogPageState();
}

class _AdminDriveCatalogPageState extends State<AdminDriveCatalogPage> {
  final _api = AdminMaterialStorageApiService();
  final _trail = <(String?, String)>[(null, 'StudentLab')];
  final _search = TextEditingController();
  List<Map<String, dynamic>> _drive = [];
  List<Map<String, dynamic>> _materials = [];
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _draft = [];
  List<Map<String, dynamic>> _folders = [];
  List<Map<String, dynamic>> _imports = [];
  String? _nextPage;
  String? _error;
  bool _loading = true;
  bool _busy = false;
  bool _previewMode = false;
  int? _viewerId;
  Map<String, dynamic>? _preview;
  int? _subjectId;
  int? _selectedId;
  int _compactPane = 1;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  int _integer(Object? value) => int.tryParse('$value') ?? 0;
  int get _draftCount => _draft.length + _imports.length +
    _folders.where((folder) => folder['draft'] == true).length;
  String _string(Object? value) => value?.toString() ?? '';
  List<String> _path(Object? value) => value is List ? value.map((e) => '$e').toList() : [];

  Map<String, dynamic> _effective(Map<String, dynamic> item) {
    final id = _integer(item['id']);
    final change = _draft.where((d) => _integer(d['material_id']) == id);
    if (change.isEmpty) return item;
    final d = change.first;
    return {...item, 'subject_id': d['subject_id'], 'path_segments': d['path_segments'],
      'visibility_state': d['visibility_state'], 'audience_type': d['audience_type'],
      'audience_id': d['audience_id'], 'draft': true};
  }

  Future<void> _reload() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await Future.wait<dynamic>([
        _api.getDriveTree(_trail.last.$1),
        _api.getItems(source: 'public'),
        _api.getDriveImportOptions(),
        _api.getCatalogSnapshot(),
      ]);
      if (!mounted) return;
      final drive = Map<String, dynamic>.from(data[0] as Map);
      final subjects = (data[2] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      final catalog = Map<String, dynamic>.from(data[3] as Map);
      setState(() {
        _drive = (drive['items'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _nextPage = drive['next_page_token']?.toString();
        _materials = (data[1] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _subjects = subjects;
        _draft = (catalog['changes'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _folders = (catalog['folders'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _imports = (catalog['imports'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (_subjectId == null && subjects.isNotEmpty) _subjectId = _integer(subjects.first['id']);
        _loading = false;
      });
      if (_previewMode) await _loadPreview();
    } catch (_) {
      if (mounted) setState(() {
        _loading = false;
        _error = 'Il catalogo non è disponibile. Verifica la connessione e riprova.';
      });
    }
  }

  Future<void> _loadDrive() async {
    try {
      final value = await _api.getDriveTree(_trail.last.$1);
      if (!mounted) return;
      setState(() {
        _drive = (value['items'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _nextPage = value['next_page_token']?.toString();
        _search.clear();
      });
    } catch (_) { _showError('Impossibile aprire questa cartella Drive.'); }
  }

  Future<void> _more() async {
    if (_nextPage == null) return;
    final token = _nextPage;
    setState(() => _busy = true);
    try {
      final value = await _api.getDriveTree(_trail.last.$1, token);
      if (mounted) setState(() {
        _drive.addAll((value['items'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)));
        _nextPage = value['next_page_token']?.toString();
      });
    } catch (_) { _showError('Non è stato possibile caricare gli altri file.'); }
    if (mounted) setState(() => _busy = false);
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _error = message);
  }

  Future<void> _loadPreview() async {
    setState(() => _busy = true);
    try {
      final value = await _api.previewCatalog(userId: _viewerId);
      if (mounted) setState(() => _preview = value);
    } catch (_) { _showError('Anteprima non disponibile. Riprova tra poco.'); }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _setViewer() async {
    final controller = TextEditingController(text: _viewerId?.toString() ?? '');
    final chosen = await showDialog<int?>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Anteprima come studente'),
      content: TextField(controller: controller, keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'ID studente', hintText: 'Lascia vuoto per guest')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
        FilledButton(onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text.trim()) ?? 0),
          child: const Text('Mostra'))],
    ));
    controller.dispose();
    if (chosen == null || !mounted) return;
    setState(() => _viewerId = chosen == 0 ? null : chosen);
    await _loadPreview();
  }

  Future<void> _stage(Map<String, dynamic> item) async {
    final current = _effective(item);
    int subjectId = _integer(current['subject_id']);
    String state = _string(current['visibility_state']);
    if (!{'visible', 'hidden', 'in_review', 'archived'}.contains(state)) state = 'visible';
    String audience = _string(current['audience_type']);
    if (!{'public', 'course', 'subject', 'group', 'user'}.contains(audience)) audience = 'public';
    final path = TextEditingController(text: _path(current['path_segments']).join(' / '));
    final recipient = TextEditingController(text: current['audience_id']?.toString() ?? '');
    final choice = await showDialog<(int, List<String>, String, String, int?)>(context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, update) => AlertDialog(
        title: Text('Gestisci: ${_string(item['title'])}'),
        content: SizedBox(width: 460, child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Le modifiche resteranno in bozza fino a «Pubblica struttura».'),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(isExpanded: true, value: _subjects.any((e) => _integer(e['id']) == subjectId)
              ? subjectId : null, decoration: const InputDecoration(labelText: 'Materia'),
              items: [for (final s in _subjects) DropdownMenuItem(value: _integer(s['id']),
                child: Text('${s['name']} · ${s['course']}', overflow: TextOverflow.ellipsis))],
              onChanged: (v) { if (v != null) update(() => subjectId = v); }),
            TextField(controller: path, decoration: const InputDecoration(
              labelText: 'Percorso nelle Dispense', hintText: 'Cartella / Sottocartella',
              helperText: 'Il percorso Drive non cambia')),
            DropdownButtonFormField<String>(isExpanded: true, value: state, decoration: const InputDecoration(labelText: 'Visibilità'),
              items: const [DropdownMenuItem(value: 'visible', child: Text('Visibile')),
                DropdownMenuItem(value: 'hidden', child: Text('Nascosto')),
                DropdownMenuItem(value: 'in_review', child: Text('In revisione')),
                DropdownMenuItem(value: 'archived', child: Text('Archiviato'))],
              onChanged: (v) { if (v != null) update(() => state = v); }),
            DropdownButtonFormField<String>(isExpanded: true, value: audience, decoration: const InputDecoration(labelText: 'Destinatari'),
              items: const [DropdownMenuItem(value: 'public', child: Text('Tutti, anche guest')),
                DropdownMenuItem(value: 'course', child: Text('Studenti del corso')),
                DropdownMenuItem(value: 'subject', child: Text('Studenti della materia')),
                DropdownMenuItem(value: 'group', child: Text('Un gruppo')),
                DropdownMenuItem(value: 'user', child: Text('Uno studente'))],
              onChanged: (v) { if (v != null) update(() => audience = v); }),
            if (audience == 'group' || audience == 'user') TextField(controller: recipient,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: audience == 'group' ? 'ID gruppo' : 'ID studente')),
          ],
        ))),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
          FilledButton(onPressed: () {
            final parts = path.text.split('/').map((s) => s.trim()).toList();
            final cleaned = path.text.trim().isEmpty ? <String>[] : parts;
            final id = int.tryParse(recipient.text.trim());
            if (subjectId <= 0 || cleaned.any((s) => s.isEmpty) ||
                ((audience == 'group' || audience == 'user') && (id == null || id <= 0))) return;
            Navigator.pop(ctx, (subjectId, cleaned, state, audience,
              audience == 'group' || audience == 'user' ? id : null));
          }, child: const Text('Salva in bozza'))],
      )));
    path.dispose(); recipient.dispose();
    if (choice == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await _api.stageCatalogFile(materialId: _integer(item['id']),
        subjectId: choice.$1, pathSegments: choice.$2,
        visibilityState: choice.$3, audienceType: choice.$4, audienceId: choice.$5);
      await _reload();
    } catch (_) { _showError('Modifica non salvata. Controlla materia, destinatari e percorso.'); }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _editFolder(String folder, List<Map<String, dynamic>> children) async {
    if (folder.isEmpty || children.isEmpty) return;
    final parts = folder.split(' / ');
    final controller = TextEditingController(text: parts.last);
    String action = 'rename';
    final choice = await showDialog<(String, String)>(context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, update) => AlertDialog(
        title: Text('Cartella ${parts.last}'),
        content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min,
          children: [
            const Text('L’operazione interessa tutti i file di questa cartella. La bozza si pubblica dalla barra in alto.'),
            DropdownButtonFormField<String>(isExpanded: true, value: action,
              items: const [DropdownMenuItem(value: 'rename', child: Text('Rinomina cartella')),
                DropdownMenuItem(value: 'move', child: Text('Sposta in un altro percorso')),
                DropdownMenuItem(value: 'hide', child: Text('Nascondi tutti i file')),
                DropdownMenuItem(value: 'show', child: Text('Mostra tutti i file'))],
              onChanged: (v) { if (v != null) update(() => action = v); }),
            if (action == 'rename' || action == 'move') TextField(controller: controller,
              decoration: InputDecoration(labelText: action == 'rename'
                ? 'Nuovo nome cartella' : 'Nuovo percorso completo',
                hintText: action == 'move' ? 'Cartella / Sottocartella' : null)),
          ])),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
          FilledButton(onPressed: () {
            if ((action == 'rename' || action == 'move') && controller.text.trim().isEmpty) return;
            Navigator.pop(ctx, (action, controller.text.trim()));
          }, child: const Text('Salva in bozza'))],
      )));
    controller.dispose();
    if (choice == null || !mounted) return;
    final oldPath = parts;
    final target = choice.$1 == 'rename'
      ? [...oldPath.take(oldPath.length - 1), choice.$2]
      : choice.$2.split('/').map((s) => s.trim()).toList();
    setState(() => _busy = true);
    try {
      for (final row in children) {
        final effective = _effective(row);
        final path = _path(effective['path_segments']);
        if (path.length < oldPath.length ||
            path.take(oldPath.length).join('/') != oldPath.join('/')) continue;
        final next = choice.$1 == 'hide' || choice.$1 == 'show'
          ? path : [...target, ...path.skip(oldPath.length)];
        await _api.stageCatalogFile(materialId: _integer(row['id']),
          subjectId: _integer(effective['subject_id']), pathSegments: next,
          visibilityState: choice.$1 == 'hide' ? 'hidden'
            : choice.$1 == 'show' ? 'visible' : _string(effective['visibility_state']),
          audienceType: _string(effective['audience_type']),
          audienceId: effective['audience_id'] == null ? null : _integer(effective['audience_id']));
      }
      await _reload();
    } catch (_) {
      _showError('Operazione sulla cartella incompleta. Controlla le modifiche in bozza prima di pubblicare.');
      await _reload();
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _import(Map<String, dynamic> file) async {
    if (_subjects.isEmpty) { _showError('Nessuna materia disponibile per classificare il file.'); return; }
    int subjectId = _subjectId ?? _integer(_subjects.first['id']);
    String audience = 'public';
    final recipient = TextEditingController();
    final pathController = TextEditingController();
    final selected = await showDialog<(int, String, int?, List<String>)>(context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, update) => AlertDialog(
        title: const Text('Aggiungi dal Drive'),
        content: SizedBox(width: 420, child: SingleChildScrollView(child:
          Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_string(file['name']), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          const Text('Il file resta sul Drive. Sarà visibile solo dopo «Pubblica struttura».'),
          DropdownButtonFormField<int>(isExpanded: true, value: subjectId,
            items: [for (final s in _subjects) DropdownMenuItem(value: _integer(s['id']),
              child: Text('${s['name']} · ${s['course']}', overflow: TextOverflow.ellipsis))],
            onChanged: (v) { if (v != null) update(() => subjectId = v); }),
          DropdownButtonFormField<String>(isExpanded: true, value: audience,
            items: const [DropdownMenuItem(value: 'public', child: Text('Tutti, anche guest')),
              DropdownMenuItem(value: 'course', child: Text('Studenti del corso')),
              DropdownMenuItem(value: 'subject', child: Text('Studenti della materia')),
              DropdownMenuItem(value: 'group', child: Text('Un gruppo')),
              DropdownMenuItem(value: 'user', child: Text('Uno studente'))],
            onChanged: (v) { if (v != null) update(() => audience = v); }),
          TextField(controller: pathController,
            decoration: const InputDecoration(labelText: 'Percorso nelle Dispense',
              hintText: 'Cartella / Sottocartella')),
          if (audience == 'group' || audience == 'user') TextField(controller: recipient,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: audience == 'group' ? 'ID gruppo' : 'ID studente')),
        ]))),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
          FilledButton(onPressed: () {
            final id = int.tryParse(recipient.text.trim());
            if ((audience == 'group' || audience == 'user') && (id == null || id <= 0)) return;
            final path = pathController.text.trim().isEmpty ? <String>[] :
              pathController.text.split('/').map((e) => e.trim()).toList();
            if (path.any((e) => e.isEmpty)) return;
            Navigator.pop(ctx, (subjectId, audience, id, path));
          }, child: const Text('Aggiungi alla bozza'))],
      )));
    recipient.dispose(); pathController.dispose();
    if (selected == null || !mounted) return;
    setState(() => _busy = true);
    try {
      var path = selected.$4;
      var allowDuplicate = false;
      for (var attempt = 0; attempt < 3; attempt++) {
        final result = await _api.stageDriveImport(fileId: _string(file['id']),
          subjectId: selected.$1, pathSegments: path,
          audienceType: selected.$2, audienceId: selected.$3,
          allowDuplicate: allowDuplicate);
        if (result['staged'] == true || !mounted) break;
        final matches = (result['conflicts'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (matches.isEmpty) break;
        final candidate = TextEditingController(text: path.join(' / '));
        final decision = await showDialog<(List<String>, bool)>(context: context,
          builder: (ctx) => AlertDialog(title: const Text('Possibile duplicato'),
            content: SizedBox(width: 460, child: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Da aggiungere: ${_string(file['name'])}\nPercorso: ${path.join(' / ')}\nDimensione: ${_string(file['size'])} byte'),
                const SizedBox(height: 12),
                for (final match in matches) ListTile(
                  title: Text(_string(match['name'])),
                  subtitle: Text('Già in: ${_path(match['path_segments']).join(' / ')} · ${_string(match['size'])} byte'),
                  trailing: IconButton(tooltip: 'Vedi file trovato',
                    icon: const Icon(Icons.visibility_outlined),
                    onPressed: () => showDriveFilePreview(context,
                      load: () => _api.downloadPublicMaterialPreview(_integer(match['id'])),
                      name: _string(match['name']), mimeType: _string(file['mime_type'])))),
                TextField(controller: candidate, decoration: const InputDecoration(
                  labelText: 'Nuovo percorso nelle Dispense')),
              ]))),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
              TextButton(onPressed: () => Navigator.pop(ctx, (path, true)),
                child: const Text('Conserva anche questo file')),
              FilledButton(onPressed: () {
                final next = candidate.text.trim().isEmpty ? <String>[] :
                  candidate.text.split('/').map((s) => s.trim()).toList();
                if (next.any((s) => s.isEmpty)) return;
                Navigator.pop(ctx, (next, true));
              }, child: const Text('Cambia percorso'))],
          ));
        candidate.dispose();
        if (decision == null) break;
        path = decision.$1;
        allowDuplicate = decision.$2;
      }
      await _reload();
    } catch (_) { _showError('File non aggiunto alla bozza. Verifica permessi e dimensione (massimo 20 MB).'); }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _publish() async {
    if (_draftCount == 0 || _busy) return;
    setState(() => _busy = true);
    try { await _api.publishCatalogDraft(); await _reload(); }
    catch (_) { _showError('La pubblicazione non è riuscita. Aggiorna il catalogo e controlla la bozza.'); }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _discard() async {
    if (_draftCount == 0 || _busy) return;
    final confirm = await showDialog<bool>(context: context,
      builder: (ctx) => AlertDialog(title: const Text('Scartare la bozza?'),
        content: const Text('Le modifiche non pubblicate verranno eliminate.'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Scarta'))]));
    if (confirm != true) return;
    try { await _api.discardCatalogDraft(); await _reload(); }
    catch (_) { _showError('Non è stato possibile scartare la bozza.'); }
  }

  Future<void> _addFolder() async {
    final subject = _subjectId;
    if (subject == null) return;
    final path = TextEditingController();
    final proposed = await showDialog<List<String>>(context: context,
      builder: (ctx) => AlertDialog(title: const Text('Nuova cartella'),
        content: TextField(controller: path, autofocus: true,
          decoration: const InputDecoration(labelText: 'Percorso completo',
            hintText: 'Esercitazioni / 2025-26',
            helperText: 'Verrà creata nel catalogo, non su Drive')),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
          FilledButton(onPressed: () {
            final segments = path.text.split('/').map((e) => e.trim()).toList();
            if (segments.any((e) => e.isEmpty)) return;
            Navigator.pop(ctx, segments);
          }, child: const Text('Aggiungi alla bozza'))]));
    path.dispose();
    if (proposed == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await _api.stageCatalogFolder(subjectId: subject, pathSegments: proposed);
      await _reload();
    } catch (_) { _showError('Cartella non aggiunta. Controlla il percorso.'); }
    if (mounted) setState(() => _busy = false);
  }

  // ===========================================================================
  // UI (canvas "Catalogo Drive · struttura per gli studenti")
  // Le funzioni sopra (bozza, importazione, pubblicazione, anteprima) sono
  // quelle di prima; qui cambia la presentazione.
  // ===========================================================================

  static const String _folderMime = 'application/vnd.google-apps.folder';

  String _bytes(Object? value) {
    final int size = _integer(value);
    if (size <= 0) return '—';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _date(Object? value) {
    final d = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _short(Object? value) {
    final text = value?.toString() ?? '';
    return text.length <= 12 ? text : '${text.substring(0, 4)}…${text.substring(text.length - 4)}';
  }

  Map<String, dynamic>? get _currentSubject {
    final matches = _subjects.where((s) => _integer(s['id']) == _subjectId);
    return matches.isEmpty ? null : matches.first;
  }

  (String, SlTone) _visibilityBadge(String state) => switch (state) {
        'visible' => ('Visibile', SlTone.success),
        'hidden' => ('Nascosto', SlTone.neutral),
        'in_review' => ('In revisione', SlTone.warning),
        'archived' => ('Archiviato', SlTone.neutral),
        _ => (state.isEmpty ? '—' : state, SlTone.neutral),
      };

  String _audienceLabel(String audience) => switch (audience) {
        'public' => 'Tutti, anche guest',
        'course' => 'Studenti del corso',
        'subject' => 'Studenti della materia',
        'group' => 'Un gruppo',
        'user' => 'Uno studente',
        _ => audience,
      };

  (String, SlTone) _audienceBadge(String audience) => switch (audience) {
        'public' => ('Guest', SlTone.cyan),
        'course' => ('Corso', SlTone.info),
        'subject' => ('Materia', SlTone.info),
        'group' => ('Gruppo', SlTone.violet),
        'user' => ('Studente', SlTone.private),
        _ => (audience, SlTone.neutral),
      };

  /// Cartelle conosciute della materia corrente (file, cartelle vuote, bozze).
  List<List<String>> _knownFolders() {
    final seen = <String>{};
    final result = <List<String>>[];
    void add(List<String> path) {
      for (var i = 1; i <= path.length; i++) {
        final prefix = path.take(i).toList();
        if (seen.add(prefix.join('\u0000'))) result.add(prefix);
      }
    }

    for (final m in _materials.map(_effective)) {
      if (_integer(m['subject_id']) == _subjectId && _string(m['status']) != 'removed') {
        add(_path(m['path_segments']));
      }
    }
    for (final f in _folders.where((f) => _integer(f['subject_id']) == _subjectId)) {
      add(_path(f['path_segments']));
    }
    for (final f in _imports.where((f) => _integer(f['subject_id']) == _subjectId)) {
      add(_path(f['path_segments']));
    }
    result.sort((a, b) => a.join(' / ').toLowerCase().compareTo(b.join(' / ').toLowerCase()));
    return result;
  }

  /// Scelta della cartella di destinazione (dialog "Sposta").
  Future<List<String>?> _pickFolder({required String title, required List<String> current}) async {
    final p = context.palette;
    final folders = _knownFolders();
    List<String> selected = List<String>.of(current);
    final newFolder = TextEditingController();
    final result = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (dialogContext, update) {
        final List<String> target = [
          ...selected,
          if (newFolder.text.trim().isNotEmpty) newFolder.text.trim(),
        ];
        Widget row(List<String> path, {required bool isRoot}) {
          final bool active = selected.join('\u0000') == path.join('\u0000');
          return Padding(
            padding: EdgeInsets.only(left: isRoot ? 0 : 14.0 * path.length, bottom: 2),
            child: Material(
              color: active ? p.skyBlue.withValues(alpha: 0.12) : Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
                side: BorderSide(color: active ? p.skyBlue.withValues(alpha: 0.36) : Colors.transparent),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(9),
                onTap: () => update(() => selected = path),
                child: SizedBox(
                  height: 40,
                  child: Row(children: [
                    const SizedBox(width: 10),
                    Icon(isRoot ? Icons.school_outlined : Icons.folder_outlined,
                        size: 17, color: isRoot ? p.adminIndigo : p.skyBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isRoot ? _string(_currentSubject?['name']) : path.last,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: active ? p.diamondDust : p.pureWhite,
                          fontWeight: active || isRoot ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (active) Icon(Icons.check_rounded, size: 17, color: p.skyBlue),
                    const SizedBox(width: 10),
                  ]),
                ),
              ),
            ),
          );
        }

        return AlertDialog(
          backgroundColor: p.eleganceDeepNavy,
          title: Text(title),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: p.adminCyan.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: p.adminCyan.withValues(alpha: 0.24)),
                    ),
                    child: Row(children: [
                      Icon(Icons.shield_outlined, size: 16, color: p.adminCyan),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Cambia solo la posizione per gli studenti. Su Drive i file restano dove sono.',
                            style: SlText.muted(p).copyWith(color: p.pureWhite.withValues(alpha: 0.80))),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: p.eleganceMidnight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: p.pureWhite.withValues(alpha: 0.08)),
                    ),
                    child: Column(children: [
                      row(const <String>[], isRoot: true),
                      for (final path in folders) row(path, isRoot: false),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: newFolder,
                    onChanged: (_) => update(() {}),
                    decoration: const InputDecoration(
                      isDense: true,
                      prefixIcon: Icon(Icons.create_new_folder_outlined),
                      labelText: 'Nuova sottocartella qui (facoltativa)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: p.eleganceSoftNight, borderRadius: BorderRadius.circular(11)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Nuovo percorso per gli studenti', style: SlText.muted(p)),
                      const SizedBox(height: 3),
                      Text(
                        [_string(_currentSubject?['name']), ...target].join(' / '),
                        style: SlText.mono(p, size: 12, color: p.diamondDust),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Icon(Icons.info_outline_rounded, size: 15, color: p.adminAmber),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('Chi ha i file offline li vedrà nella nuova posizione alla prossima sincronizzazione.',
                          style: SlText.muted(p).copyWith(color: p.adminAmber)),
                    ),
                  ]),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annulla')),
            FilledButton(
              onPressed: target.any((s) => s.isEmpty || s.contains('/'))
                  ? null
                  : () => Navigator.pop(dialogContext, target),
              child: const Text('Aggiungi alla bozza'),
            ),
          ],
        );
      }),
    );
    newFolder.dispose();
    return result;
  }

  Future<void> _stageChange(Map<String, dynamic> item,
      {List<String>? path, String? visibility}) async {
    final current = _effective(item);
    setState(() => _busy = true);
    try {
      await _api.stageCatalogFile(
        materialId: _integer(item['id']),
        subjectId: _integer(current['subject_id']),
        pathSegments: path ?? _path(current['path_segments']),
        visibilityState: visibility ?? _string(current['visibility_state']),
        audienceType: _string(current['audience_type']).isEmpty ? 'public' : _string(current['audience_type']),
        audienceId: current['audience_id'] == null ? null : _integer(current['audience_id']),
      );
      await _reload();
    } catch (_) {
      _showError('Modifica non salvata in bozza. Controlla materia, destinatari e percorso.');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _moveFile(Map<String, dynamic> item) async {
    final current = _effective(item);
    final target = await _pickFolder(
      title: 'Sposta “${_string(item['title'])}”',
      current: _path(current['path_segments']),
    );
    if (target == null || !mounted) return;
    await _stageChange(item, path: target);
  }

  Future<void> _openInDrive(String fileId) async {
    final uri = Uri.parse('https://drive.google.com/file/d/$fileId/view');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showError('Non è stato possibile aprire Google Drive.');
    }
  }

  // ---------------------------------------------------------------------------
  // Colonne
  // ---------------------------------------------------------------------------

  Widget _column({required Widget header, required Widget body, Widget? footer, bool elevated = false}) {
    final p = context.palette;
    return Material(
      color: elevated ? p.eleganceDeepNavy : p.eleganceMidnight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: p.skyBlue.withValues(alpha: elevated ? 0.18 : 0.12)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        header,
        Divider(height: 1, color: p.pureWhite.withValues(alpha: 0.07)),
        Expanded(child: body),
        if (footer != null) ...[
          Divider(height: 1, color: p.pureWhite.withValues(alpha: 0.07)),
          footer,
        ],
      ]),
    );
  }

  Widget _columnHeader({required IconData icon, required SlTone tone, required String title,
      required String subtitle, List<Widget> trailing = const []}) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Row(children: [
        SlIconTile(icon: icon, tone: tone, size: 34),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: p.pureWhite, fontSize: 14, fontWeight: FontWeight.w700)),
            Text(subtitle, style: SlText.muted(p).copyWith(fontSize: 11)),
          ]),
        ),
        ...trailing,
      ]),
    );
  }

  Widget _drivePane() {
    final p = context.palette;
    final query = _search.text.trim().toLowerCase();
    final shown = _drive.where((e) => _string(e['name']).toLowerCase().contains(query)).toList();
    final draftImports = _imports.map((e) => _string(e['drive_file_id'])).toSet();
    return _column(
      header: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _columnHeader(
          icon: Icons.cloud_outlined,
          tone: SlTone.info,
          title: 'Google Drive',
          subtitle: 'Struttura reale, come sul Drive',
          trailing: const [SlStatusBadge(label: 'Sola lettura')],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: p.pureWhite, fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              hintText: 'Cerca su Drive',
              fillColor: p.darkElegance,
            ),
          ),
        ),
      ]),
      body: ListView(padding: const EdgeInsets.all(8), children: [
        if (_trail.length > 1)
          _driveRow(
            icon: Icons.arrow_upward_rounded,
            iconColor: p.pureWhite.withValues(alpha: 0.66),
            title: _trail.map((e) => e.$2).join(' / '),
            subtitle: 'Torna su',
            onTap: () {
              _trail.removeLast();
              _loadDrive();
            },
          ),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(query.isEmpty ? 'Cartella vuota.' : 'Nessun file corrisponde alla ricerca.',
                style: SlText.muted(p)),
          ),
        for (final file in shown)
          if (file['mime_type'] == _folderMime)
            _driveRow(
              icon: Icons.folder_outlined,
              iconColor: p.skyBlue,
              title: _string(file['name']),
              subtitle: file['modified_at'] == null ? null : 'Modificata ${_date(file['modified_at'])}',
              trailingIcon: Icons.chevron_right_rounded,
              onTap: () {
                _trail.add((_string(file['id']), _string(file['name'])));
                _loadDrive();
              },
            )
          else
            _driveRow(
              icon: Icons.insert_drive_file_outlined,
              iconColor: p.pureWhite.withValues(alpha: 0.72),
              title: _string(file['name']),
              subtitle: <String>[
                _bytes(file['size']),
                if (file['modified_at'] != null) _date(file['modified_at']),
                if (_string(file['last_modified_by']).isNotEmpty) _string(file['last_modified_by']),
              ].join(' · '),
              dot: file['indexed'] == true
                  ? _DriveDot.catalog
                  : (draftImports.contains(_string(file['id'])) ? _DriveDot.draft : _DriveDot.driveOnly),
              onTap: () => showDriveFilePreview(context,
                  load: () => _api.downloadDriveFilePreview(_string(file['id'])),
                  name: _string(file['name']),
                  mimeType: _string(file['mime_type'])),
              action: file['indexed'] != true && !draftImports.contains(_string(file['id']))
                  ? IconButton(
                      tooltip: 'Aggiungi alla struttura per gli studenti',
                      onPressed: _busy ? null : () => _import(file),
                      icon: Icon(Icons.add_circle_outline_rounded, color: p.skyBlue, size: 20),
                    )
                  : null,
            ),
        if (_nextPage != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: SlActionButton(
              icon: Icons.expand_more_rounded,
              label: 'Carica altri file',
              onPressed: _busy ? null : _more,
            ),
          ),
      ]),
      footer: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _legend(_DriveDot.catalog, 'Nel catalogo'),
          const SizedBox(height: 5),
          _legend(_DriveDot.draft, 'Aggiunto alla bozza, non ancora pubblicato'),
          const SizedBox(height: 5),
          _legend(_DriveDot.driveOnly, 'Solo su Drive: usa + per aggiungerlo'),
        ]),
      ),
    );
  }

  Widget _dot(_DriveDot kind) {
    final p = context.palette;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: switch (kind) {
          _DriveDot.catalog => p.adminGreen,
          _DriveDot.draft => p.adminAmber,
          _DriveDot.driveOnly => Colors.transparent,
        },
        border: kind == _DriveDot.driveOnly
            ? Border.all(color: p.pureWhite.withValues(alpha: 0.45), width: 1.5)
            : null,
      ),
    );
  }

  Widget _legend(_DriveDot kind, String label) {
    final p = context.palette;
    return Row(children: [
      _dot(kind),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: SlText.muted(p).copyWith(fontSize: 11))),
    ]);
  }

  Widget _driveRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    _DriveDot? dot,
    IconData? trailingIcon,
    Widget? action,
    required VoidCallback onTap,
  }) {
    final p = context.palette;
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(children: [
            Icon(icon, size: 17, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: p.pureWhite, fontSize: 13)),
                if (subtitle != null && subtitle.isNotEmpty)
                  Text(subtitle, style: SlText.mono(p, size: 10, color: p.pureWhite.withValues(alpha: 0.56))),
              ]),
            ),
            if (dot != null) ...[const SizedBox(width: 6), _dot(dot)],
            if (action != null) action,
            if (trailingIcon != null) Icon(trailingIcon, size: 18, color: p.pureWhite.withValues(alpha: 0.4)),
          ]),
        ),
      ),
    );
  }

  Widget _catalogPane() {
    final p = context.palette;
    final subset = _materials
        .where((m) => _integer(_effective(m)['subject_id']) == _subjectId && _string(m['status']) != 'removed')
        .map(_effective)
        .toList();
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final m in subset) {
      groups.putIfAbsent(_path(m['path_segments']).join(' / '), () => []).add(m);
    }
    final keys = groups.keys.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final folderRows = _folders.where((f) => _integer(f['subject_id']) == _subjectId).toList();
    final importRows = _imports.where((f) => _integer(f['subject_id']) == _subjectId).toList();
    final subject = _currentSubject;

    return _column(
      header: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _columnHeader(
          icon: Icons.layers_outlined,
          tone: SlTone.violet,
          title: 'Struttura per gli studenti',
          subtitle: 'Come apparirà nelle Dispense, anche offline',
          trailing: [
            SlActionButton(
              icon: Icons.create_new_folder_outlined,
              label: 'Nuova cartella',
              primary: true,
              onPressed: _busy || _subjectId == null ? null : _addFolder,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: PopupMenuButton<int>(
            tooltip: 'Materia',
            color: p.eleganceDeepNavy,
            onSelected: (value) => setState(() {
              _subjectId = value;
              _selectedId = null;
            }),
            itemBuilder: (_) => [
              for (final s in _subjects)
                PopupMenuItem<int>(
                  value: _integer(s['id']),
                  child: Text('${s['name']} · ${s['course']}', overflow: TextOverflow.ellipsis),
                ),
            ],
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: p.darkElegance,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: p.pureWhite.withValues(alpha: 0.12)),
              ),
              child: Row(children: [
                Text('Materia', style: SlText.muted(p)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    subject == null ? 'Scegli una materia' : '${subject['name']} · ${subject['course']}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: p.pureWhite, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              ]),
            ),
          ),
        ),
      ]),
      body: subset.isEmpty && folderRows.isEmpty && importRows.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: SlEmptyState(
                icon: Icons.folder_open_outlined,
                title: 'Nessun materiale in questa materia',
                message: 'Aggiungi file dal Drive con il pulsante + oppure crea una cartella.',
                actions: [
                  SlActionButton(
                    icon: Icons.create_new_folder_outlined,
                    label: 'Nuova cartella',
                    onPressed: _busy || _subjectId == null ? null : _addFolder,
                  ),
                ],
              ),
            )
          : ListView(padding: const EdgeInsets.all(10), children: [
              if (subject != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    const SlIconTile(icon: Icons.school_outlined, tone: SlTone.violet, size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_string(subject['name']),
                          style: TextStyle(color: p.pureWhite, fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                    Text('${subject['course']} · ${subset.length} file',
                        style: SlText.mono(p, size: 11, color: p.pureWhite.withValues(alpha: 0.56))),
                  ]),
                ),
              for (final key in keys) ...[
                if (key.isNotEmpty) _folderRow(key, groups[key]!, subset),
                for (final material in groups[key]!) _fileRow(material, indent: key.isEmpty ? 1 : 2),
              ],
              for (final folder in folderRows.where(
                  (f) => !groups.containsKey(_path(f['path_segments']).join(' / '))))
                _simpleRow(
                  icon: Icons.folder_outlined,
                  title: _path(folder['path_segments']).join(' / '),
                  badge: SlStatusBadge(
                    label: folder['draft'] == true ? 'Cartella in bozza' : 'Vuota',
                    tone: folder['draft'] == true ? SlTone.warning : SlTone.neutral,
                  ),
                ),
              for (final file in importRows)
                _simpleRow(
                  icon: Icons.insert_drive_file_outlined,
                  title: _string(file['name']),
                  subtitle: '${_path(file['path_segments']).join(' / ')} · ${_bytes(file['size'])} · da Drive',
                  badge: const SlStatusBadge(label: 'Nuovo', tone: SlTone.warning),
                  onTap: () => showDriveFilePreview(context,
                      load: () => _api.downloadDriveFilePreview(_string(file['drive_file_id'])),
                      name: _string(file['name']),
                      mimeType: _string(file['mime_type'])),
                ),
            ]),
      footer: _draftCount == 0 ? null : _changeLog(),
    );
  }

  Widget _folderRow(String key, List<Map<String, dynamic>> files, List<Map<String, dynamic>> subset) {
    final p = context.palette;
    final parts = key.split(' / ');
    final hidden = files.where((f) => _string(f['visibility_state']) != 'visible').length;
    final allHidden = hidden == files.length;
    final drafted = files.any((f) => f['draft'] == true);
    return Padding(
      padding: EdgeInsets.only(left: 14.0 * (parts.length - 1) + 8, top: 4, bottom: 2),
      child: Opacity(
        opacity: allHidden ? 0.62 : 1,
        child: Container(
          height: 44,
          padding: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Icon(Icons.folder_outlined, size: 18, color: allHidden ? p.pureWhite.withValues(alpha: 0.7) : p.skyBlue),
            const SizedBox(width: 8),
            Flexible(
              child: Text(parts.last,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.pureWhite, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            if (allHidden)
              SlStatusBadge(label: 'Nascosta · ${files.length} file')
            else if (hidden > 0)
              SlStatusBadge(label: '$hidden nascosti'),
            if (drafted) ...[
              const SizedBox(width: 6),
              const SlStatusBadge(label: 'In bozza', tone: SlTone.warning),
            ],
            const Spacer(),
            IconButton(
              tooltip: 'Rinomina, sposta o nascondi la cartella',
              onPressed: _busy ? null : () => _editFolder(key, subset),
              icon: Icon(Icons.more_horiz_rounded, color: p.pureWhite.withValues(alpha: 0.66)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _fileRow(Map<String, dynamic> material, {required int indent}) {
    final p = context.palette;
    final id = _integer(material['id']);
    final bool selected = id == _selectedId;
    final state = _string(material['visibility_state']);
    final (visLabel, visTone) = _visibilityBadge(state);
    final (audLabel, audTone) = _audienceBadge(_string(material['audience_type']));
    final bool hidden = state != 'visible';
    return Padding(
      padding: EdgeInsets.only(left: 14.0 * indent, bottom: 4),
      child: Material(
        color: selected ? p.skyBlue.withValues(alpha: 0.10) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: selected ? p.skyBlue.withValues(alpha: 0.34) : Colors.transparent),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() {
            _selectedId = id;
            _compactPane = 2;
          }),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
            child: Row(children: [
              SlFileTile(kind: slFileKind(_string(material['mime_type']), _string(material['original_name'])), size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Opacity(
                  opacity: hidden ? 0.7 : 1,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_string(material['title']),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: p.pureWhite, fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(
                      <String>[
                        _string(material['original_name']),
                        _bytes(material['size']),
                        if (_string(material['uploader_name']).isNotEmpty) _string(material['uploader_name']),
                      ].where((s) => s.isNotEmpty).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SlText.mono(p, size: 10, color: p.pureWhite.withValues(alpha: 0.56)),
                    ),
                    const SizedBox(height: 4),
                    Wrap(spacing: 5, runSpacing: 4, children: [
                      SlStatusBadge(label: visLabel, tone: visTone),
                      SlStatusBadge(label: audLabel, tone: audTone),
                      if (material['draft'] == true) const SlStatusBadge(label: 'Bozza', tone: SlTone.warning),
                    ]),
                  ]),
                ),
              ),
              IconButton(
                tooltip: hidden ? 'Mostra agli studenti' : 'Nascondi agli studenti',
                onPressed: _busy ? null : () => _stageChange(material, visibility: hidden ? 'visible' : 'hidden'),
                icon: Icon(hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 18, color: p.pureWhite.withValues(alpha: 0.72)),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _simpleRow({required IconData icon, required String title, String? subtitle,
      required Widget badge, VoidCallback? onTap}) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 8, 8),
        child: Row(children: [
          Icon(icon, size: 17, color: p.adminAmber),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(color: p.pureWhite, fontSize: 13, fontWeight: FontWeight.w600)),
              if (subtitle != null) Text(subtitle, style: SlText.muted(p).copyWith(fontSize: 11)),
            ]),
          ),
          badge,
        ]),
      ),
    );
  }

  /// Registro della bozza: cosa cambierà alla pubblicazione.
  Widget _changeLog() {
    final p = context.palette;
    final lines = <(String, String)>[];
    for (final d in _draft) {
      final matches = _materials.where((m) => _integer(m['id']) == _integer(d['material_id']));
      final before = matches.isEmpty ? null : matches.first;
      final name = before == null ? 'File ${d['material_id']}' : _string(before['title']);
      final pathBefore = before == null ? '' : _path(before['path_segments']).join(' / ');
      final pathAfter = _path(d['path_segments']).join(' / ');
      if (before != null && pathBefore != pathAfter) {
        lines.add(('SPOSTA', '“$name” → ${pathAfter.isEmpty ? 'materia' : pathAfter}'));
      }
      if (before != null && _string(before['visibility_state']) != _string(d['visibility_state'])) {
        lines.add((_string(d['visibility_state']) == 'visible' ? 'MOSTRA' : 'NASCONDI', '“$name”'));
      }
      if (before != null && _string(before['audience_type']) != _string(d['audience_type'])) {
        lines.add(('DESTINATARI', '“$name”: ${_audienceLabel(_string(d['audience_type']))}'));
      }
      if (before != null && _integer(before['subject_id']) != _integer(d['subject_id'])) {
        lines.add(('MATERIA', '“$name” cambia materia'));
      }
    }
    for (final i in _imports) {
      lines.add(('AGGIUNGI', '“${_string(i['name'])}” in ${_path(i['path_segments']).join(' / ').isEmpty ? 'materia' : _path(i['path_segments']).join(' / ')}'));
    }
    for (final f in _folders.where((f) => f['draft'] == true)) {
      lines.add(('CARTELLA', _path(f['path_segments']).join(' / ')));
    }
    return Container(
      constraints: const BoxConstraints(maxHeight: 190),
      color: p.eleganceSoftNight,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        children: [
          Text('BOZZA · $_draftCount MODIFICHE',
              style: SlText.mono(p, size: 11, color: p.pureWhite.withValues(alpha: 0.56))),
          const SizedBox(height: 6),
          for (final (kind, text) in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 92, child: Text(kind, style: SlText.mono(p, size: 11, color: p.adminAmber))),
                Expanded(child: Text(text, style: SlText.body(p).copyWith(fontSize: 12))),
              ]),
            ),
          Text('Per annullare usa “Scarta bozza”.', style: SlText.muted(p).copyWith(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _detailsPane() {
    final p = context.palette;
    final matches = _materials.where((m) => _integer(m['id']) == _selectedId);
    if (matches.isEmpty) {
      return _column(
        elevated: true,
        header: _columnHeader(
            icon: Icons.description_outlined, tone: SlTone.info, title: 'Dettaglio', subtitle: 'File selezionato'),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: SlEmptyState(
            icon: Icons.touch_app_outlined,
            title: 'Nessun file selezionato',
            message: 'Scegli un file nella struttura per vederne provenienza, posizione e visibilità.',
          ),
        ),
      );
    }
    final original = matches.first;
    final row = _effective(original);
    final id = _integer(row['id']);
    final state = _string(row['visibility_state']);
    final (visLabel, visTone) = _visibilityBadge(state);
    final drivePath = _path(row['drive_path_segments']);
    final catalogPath = _path(row['path_segments']);
    final driveId = _string(row['drive_file_id']).isNotEmpty
        ? _string(row['drive_file_id'])
        : (_string(row['stored_name']).startsWith('drive-import/')
            ? _string(row['stored_name']).substring('drive-import/'.length)
            : '');

    Widget section(String label, List<Widget> children) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SlOverline(label),
            const SizedBox(height: 6),
            ...children,
          ]),
        );

    return _column(
      elevated: true,
      header: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SlFileTile(kind: slFileKind(_string(row['mime_type']), _string(row['original_name'])), size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_string(row['title']),
                  style: TextStyle(color: p.pureWhite, fontSize: 15, fontWeight: FontWeight.w700)),
              Text(_string(row['original_name']), style: SlText.mono(p, size: 11)),
              const SizedBox(height: 6),
              Wrap(spacing: 5, runSpacing: 4, children: [
                SlStatusBadge(label: visLabel, tone: visTone),
                SlStatusBadge(
                  label: row['draft'] == true ? 'In bozza' : 'Nel catalogo',
                  tone: row['draft'] == true ? SlTone.warning : SlTone.cyan,
                ),
              ]),
            ]),
          ),
        ]),
      ),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          SlActionButton(
            icon: Icons.visibility_outlined,
            label: 'Anteprima',
            primary: true,
            onPressed: () => showDriveFilePreview(context,
                load: () => _api.downloadPublicMaterialPreview(id),
                name: _string(row['original_name']),
                mimeType: _string(row['mime_type'])),
          ),
          if (driveId.isNotEmpty)
            SlActionButton(
              icon: Icons.open_in_new_rounded,
              label: 'Apri su Drive',
              onPressed: () => _openInDrive(driveId),
            ),
        ]),
        const SizedBox(height: 16),
        section('Provenienza', [
          SlKeyValue(
            label: 'Caricato da',
            value: _string(row['uploader_name']).isNotEmpty
                ? _string(row['uploader_name'])
                : (driveId.isNotEmpty ? 'Importato da Google Drive' : '—'),
          ),
          if (_string(row['contributor_mode']) == 'anonymous' && _string(row['uploader_name']).isNotEmpty)
            const SlKeyValue(label: 'Pubblicazione', value: 'Anonima per gli studenti'),
          SlKeyValue(
            label: 'Approvato',
            value: [
              if (_string(row['approver_name']).isNotEmpty) _string(row['approver_name']),
              if (row['approved_at'] != null) _date(row['approved_at']),
            ].join(' · ').isEmpty
                ? '—'
                : [
                    if (_string(row['approver_name']).isNotEmpty) _string(row['approver_name']),
                    if (row['approved_at'] != null) _date(row['approved_at']),
                  ].join(' · '),
          ),
          SlKeyValue(label: 'Ultima modifica', value: _date(row['updated_at'])),
        ]),
        section('File', [
          SlKeyValue(label: 'Tipo', value: _string(row['mime_type']).isEmpty ? '—' : _string(row['mime_type']), mono: true),
          SlKeyValue(label: 'Dimensione', value: _bytes(row['size']), mono: true),
          if (driveId.isNotEmpty)
            Row(children: [
              Expanded(child: SlKeyValue(label: 'ID Drive', value: _short(driveId), mono: true)),
              IconButton(
                tooltip: 'Copia ID Drive',
                onPressed: () => Clipboard.setData(ClipboardData(text: driveId)),
                icon: Icon(Icons.copy_rounded, size: 16, color: p.skyBlue),
              ),
            ]),
          if (_string(row['file_hash']).isNotEmpty)
            SlKeyValue(label: 'SHA-256', value: _short(row['file_hash']), mono: true),
        ]),
        section('Posizione', [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: p.eleganceMidnight, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Su Google Drive · invariata', style: SlText.muted(p).copyWith(fontSize: 11)),
              Text(drivePath.isEmpty ? 'Posizione originaria del file' : drivePath.join(' / '),
                  style: SlText.mono(p, size: 12, color: p.pureWhite)),
              const SizedBox(height: 8),
              Divider(height: 1, color: p.pureWhite.withValues(alpha: 0.07)),
              const SizedBox(height: 8),
              Text('Per gli studenti', style: SlText.muted(p).copyWith(fontSize: 11, color: p.diamondDust)),
              Text(
                [_string(_currentSubject?['name']), ...catalogPath].where((s) => s.isNotEmpty).join(' / '),
                style: SlText.mono(p, size: 12, color: p.diamondDust),
              ),
            ]),
          ),
        ]),
        section('Visibilità', [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: state == 'visible',
            onChanged: _busy ? null : (value) => _stageChange(original, visibility: value ? 'visible' : 'hidden'),
            title: Text('Visibile agli studenti', style: SlText.body(p)),
            subtitle: state == 'visible' || state == 'hidden'
                ? null
                : Text('Stato attuale: $visLabel', style: SlText.muted(p)),
          ),
          SlKeyValue(label: 'Destinatari', value: _audienceLabel(_string(row['audience_type']))),
        ]),
      ]),
      footer: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(
            child: SlActionButton(
              icon: Icons.drive_file_move_outline,
              label: 'Sposta in…',
              onPressed: _busy ? null : () => _moveFile(original),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SlActionButton(
              icon: Icons.tune_rounded,
              label: 'Permessi',
              primary: true,
              onPressed: _busy ? null : () => _stage(original),
            ),
          ),
        ]),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Anteprima "Visualizza come"
  // ---------------------------------------------------------------------------

  Widget _viewAsPane() {
    final p = context.palette;
    final items = (_preview?['files'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final visible = items.where((e) => e['allowed'] == true).length;
    final driveFiles = _drive.where((e) => e['mime_type'] != _folderMime).length;
    Widget option({required bool selected, required String title, String? subtitle, required VoidCallback onTap}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: SlChoiceTile(title: title, description: subtitle, selected: selected, onTap: onTap),
      );
    }

    Widget stat(String label, String value, {bool accent = false}) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: p.eleganceSoftNight, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: SlText.muted(p).copyWith(fontSize: 11, color: accent ? p.diamondDust : null)),
              const SizedBox(height: 4),
              Text(value,
                  style: SlText.mono(p, size: 20, color: accent ? p.diamondDust : p.pureWhite, weight: FontWeight.w700)),
            ]),
          ),
        );

    return _column(
      header: _columnHeader(
        icon: Icons.person_search_outlined,
        tone: SlTone.info,
        title: 'Visualizza come',
        subtitle: 'Permessi calcolati dal server, incluse le bozze',
      ),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        option(
          selected: _viewerId == null,
          title: 'Ospite non registrato',
          subtitle: 'Vede solo i file per “Tutti, anche guest”',
          onTap: () {
            setState(() => _viewerId = null);
            _loadPreview();
          },
        ),
        option(
          selected: _viewerId != null,
          title: _viewerId == null ? 'Studente specifico…' : 'Studente $_viewerId',
          subtitle: 'Indica l’ID di uno studente per vedere esattamente cosa vede lui',
          onTap: _setViewer,
        ),
        const SizedBox(height: 14),
        const SlOverline('Drive e studenti a confronto'),
        const SizedBox(height: 8),
        Row(children: [
          stat('File in questa cartella Drive', '$driveFiles'),
          const SizedBox(width: 8),
          stat('File visibili', '$visible', accent: true),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          stat('File nel catalogo', '${items.length}'),
          const SizedBox(width: 8),
          stat('Esclusi per questo profilo', '${items.length - visible}'),
        ]),
      ]),
    );
  }

  Widget _phonePane() {
    final p = context.palette;
    final items = (_preview?['files'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((e) => e['allowed'] == true && _integer(e['subject_id']) == _subjectId)
        .toList();
    final folders = <String, int>{};
    final rootFiles = <Map<String, dynamic>>[];
    for (final file in items) {
      final path = _path(file['path_segments']);
      if (path.isEmpty) {
        rootFiles.add(file);
      } else {
        folders[path.first] = (folders[path.first] ?? 0) + 1;
      }
    }
    final subject = _currentSubject;
    return Column(children: [
      Text('SEZIONE MATERIALE · COME LA VEDE ${_viewerId == null ? 'UN OSPITE' : 'LO STUDENTE $_viewerId'}',
          style: SlText.mono(p, size: 11, color: p.pureWhite.withValues(alpha: 0.56))),
      const SizedBox(height: 10),
      Expanded(
        child: Center(
          child: AspectRatio(
            aspectRatio: 390 / 780,
            child: Container(
              decoration: BoxDecoration(
                color: p.darkElegance,
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: p.skyBlue.withValues(alpha: 0.26)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const SizedBox(height: 16),
                Container(
                  height: 50,
                  color: p.eleganceMidnight,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.centerLeft,
                  child: Text('Dispense',
                      style: TextStyle(color: p.pureWhite, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                if (_draftCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    color: p.adminAmber.withValues(alpha: 0.14),
                    alignment: Alignment.center,
                    child: Text('ANTEPRIMA · INCLUDE LA BOZZA NON PUBBLICATA',
                        style: SlText.mono(p, size: 9, color: p.adminAmber, weight: FontWeight.w700)),
                  ),
                Expanded(
                  child: ListView(padding: const EdgeInsets.all(12), children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: p.eleganceDeepNavy,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: p.skyBlue.withValues(alpha: 0.14)),
                      ),
                      child: Row(children: [
                        const SlIconTile(icon: Icons.school_outlined, size: 40),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(_string(subject?['name']),
                                style: TextStyle(color: p.pureWhite, fontSize: 14, fontWeight: FontWeight.w700)),
                            Text('${_string(subject?['course'])} · ${items.length} file',
                                style: SlText.muted(p).copyWith(fontSize: 11)),
                          ]),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text('Nessun file di questa materia è visibile a questo profilo.',
                            textAlign: TextAlign.center, style: SlText.muted(p)),
                      ),
                    for (final entry in folders.entries)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: p.eleganceMidnight, borderRadius: BorderRadius.circular(14)),
                        child: Row(children: [
                          const SlIconTile(icon: Icons.folder_outlined, size: 34),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(entry.key,
                                  style: TextStyle(color: p.pureWhite, fontSize: 13, fontWeight: FontWeight.w600)),
                              Text('${entry.value} file', style: SlText.muted(p).copyWith(fontSize: 11)),
                            ]),
                          ),
                          Icon(Icons.chevron_right_rounded, size: 18, color: p.pureWhite.withValues(alpha: 0.4)),
                        ]),
                      ),
                    for (final file in rootFiles)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: p.eleganceMidnight, borderRadius: BorderRadius.circular(14)),
                        child: Row(children: [
                          const SlFileTile(kind: 'FILE', size: 34),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_string(file['title']),
                                style: TextStyle(color: p.pureWhite, fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                          if (file['draft'] == true) const SlStatusBadge(label: 'Bozza', tone: SlTone.warning),
                        ]),
                      ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _excludedPane() {
    final p = context.palette;
    final items = (_preview?['files'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((e) => e['allowed'] != true && _integer(e['subject_id']) == _subjectId)
        .toList();
    return _column(
      header: _columnHeader(
        icon: Icons.visibility_off_outlined,
        tone: SlTone.neutral,
        title: 'Non visibile a questo profilo',
        subtitle: 'Nella materia selezionata',
      ),
      body: items.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Tutti i file della materia sono visibili a questo profilo.', style: SlText.muted(p)),
            )
          : ListView(padding: const EdgeInsets.all(10), children: [
              for (final file in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    Icon(
                      _string(file['visibility_state']) == 'visible'
                          ? Icons.lock_outline_rounded
                          : Icons.visibility_off_outlined,
                      size: 16,
                      color: p.pureWhite.withValues(alpha: 0.66),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_string(file['title']), style: SlText.body(p).copyWith(color: p.pureWhite)),
                        Text(_path(file['path_segments']).join(' / '), style: SlText.muted(p).copyWith(fontSize: 11)),
                      ]),
                    ),
                    SlStatusBadge(
                      label: _string(file['visibility_state']) == 'visible'
                          ? _audienceBadge(_string(file['audience_type'])).$1
                          : _visibilityBadge(_string(file['visibility_state'])).$1,
                      tone: _string(file['visibility_state']) == 'visible' ? SlTone.private : SlTone.neutral,
                    ),
                  ]),
                ),
            ]),
      footer: Padding(
        padding: const EdgeInsets.all(12),
        child: SlActionButton(
          icon: Icons.layers_outlined,
          label: 'Torna alla struttura',
          primary: true,
          onPressed: () => setState(() => _previewMode = false),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Pagina
  // ---------------------------------------------------------------------------

  Widget _draftBar(bool wide) {
    final p = context.palette;
    final notice = Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.shield_outlined, size: 18, color: p.adminCyan),
      const SizedBox(width: 10),
      Flexible(
        child: Text.rich(TextSpan(children: [
          TextSpan(text: 'Le modifiche riguardano solo il catalogo StudentLab. ',
              style: TextStyle(color: p.pureWhite.withValues(alpha: 0.80))),
          TextSpan(text: 'Cartelle e file su Google Drive restano invariati.',
              style: TextStyle(color: p.adminCyan, fontWeight: FontWeight.w600)),
        ]), style: const TextStyle(fontSize: 13)),
      ),
    ]);
    final actions = Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
      if (_draftCount > 0) SlStatusBadge(label: '$_draftCount modifiche in bozza', tone: SlTone.warning),
      OutlinedButton(
        onPressed: _draftCount == 0 || _busy ? null : _discard,
        style: OutlinedButton.styleFrom(
          foregroundColor: p.pureWhite.withValues(alpha: 0.86),
          minimumSize: const Size(0, 40),
          side: BorderSide(color: p.pureWhite.withValues(alpha: 0.14)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text('Scarta bozza'),
      ),
      FilledButton(
        onPressed: _draftCount == 0 || _busy ? null : _publish,
        style: FilledButton.styleFrom(
          backgroundColor: p.skyBlue,
          foregroundColor: p.darkElegance,
          minimumSize: const Size(0, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
        child: _busy
            ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: p.darkElegance))
            : const Text('Pubblica struttura'),
      ),
    ]);
    return Container(
      margin: EdgeInsets.fromLTRB(wide ? 24 : 12, 14, wide ? 24 : 12, 0),
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      decoration: BoxDecoration(
        color: p.eleganceDeepNavy,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.adminCyan.withValues(alpha: 0.24)),
      ),
      child: wide
          ? Row(children: [Expanded(child: notice), const SizedBox(width: 12), actions])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [notice, const SizedBox(height: 10), actions]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.darkElegance,
      appBar: slAdminAppBar(context, title: 'Catalogo Drive', actions: [
        IconButton(
          onPressed: _busy ? null : _reload,
          tooltip: 'Aggiorna da Drive',
          icon: const Icon(Icons.refresh_rounded),
        ),
      ]),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: p.skyBlue))
          : LayoutBuilder(builder: (context, box) {
              final bool wide = box.maxWidth >= 1350;
              final modeBar = SlFilterBar<bool>(
                selected: _previewMode,
                options: const [
                  SlFilterOption(value: false, label: 'Struttura'),
                  SlFilterOption(value: true, label: 'Anteprima studente'),
                ],
                onSelected: (value) {
                  setState(() => _previewMode = value);
                  if (value) _loadPreview();
                },
              );
              final Widget content;
              if (wide) {
                content = Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: _previewMode
                    ? [
                        SizedBox(width: 340, child: _viewAsPane()),
                        const SizedBox(width: 16),
                        Expanded(child: _phonePane()),
                        const SizedBox(width: 16),
                        SizedBox(width: 360, child: _excludedPane()),
                      ]
                    : [
                        SizedBox(width: 340, child: _drivePane()),
                        const SizedBox(width: 16),
                        Expanded(child: _catalogPane()),
                        const SizedBox(width: 16),
                        SizedBox(width: 380, child: _detailsPane()),
                      ]);
              } else {
                final panes = _previewMode
                    ? [_viewAsPane(), _phonePane(), _excludedPane()]
                    : [_drivePane(), _catalogPane(), _detailsPane()];
                final labels = _previewMode
                    ? const ['Profilo', 'Anteprima', 'Esclusi']
                    : const ['Drive', 'Struttura', 'Dettaglio'];
                content = Column(children: [
                  SlFilterBar<int>(
                    selected: _compactPane,
                    options: [
                      for (var i = 0; i < 3; i++) SlFilterOption(value: i, label: labels[i]),
                    ],
                    onSelected: (value) => setState(() => _compactPane = value),
                  ),
                  const SizedBox(height: 10),
                  Expanded(child: panes[_compactPane < 0 ? 0 : (_compactPane > 2 ? 2 : _compactPane)]),
                ]);
              }
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(wide ? 24 : 12, 12, wide ? 24 : 12, 0),
                  child: Align(alignment: Alignment.centerRight, child: modeBar),
                ),
                _draftBar(wide),
                if (_error != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(wide ? 24 : 12, 12, wide ? 24 : 12, 0),
                    child: Stack(children: [
                      SlErrorCard(title: 'Operazione non completata', message: _error!),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          tooltip: 'Chiudi',
                          onPressed: () => setState(() => _error = null),
                          icon: Icon(Icons.close_rounded, size: 18, color: p.pureWhite.withValues(alpha: 0.66)),
                        ),
                      ),
                    ]),
                  ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(wide ? 24 : 12, 14, wide ? 24 : 12, wide ? 24 : 12),
                    child: content,
                  ),
                ),
              ]);
            }),
    );
  }
}

enum _DriveDot { catalog, draft, driveOnly }
