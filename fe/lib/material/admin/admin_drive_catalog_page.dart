import 'package:flutter/material.dart';

import '../../social/admin/admin_material_storage_api_service.dart';
import '../../theme/nightTheme.dart';
import '../../theme/app_palette.dart';
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
            DropdownButtonFormField<int>(value: _subjects.any((e) => _integer(e['id']) == subjectId)
              ? subjectId : null, decoration: const InputDecoration(labelText: 'Materia'),
              items: [for (final s in _subjects) DropdownMenuItem(value: _integer(s['id']),
                child: Text('${s['name']} · ${s['course']}', overflow: TextOverflow.ellipsis))],
              onChanged: (v) { if (v != null) update(() => subjectId = v); }),
            TextField(controller: path, decoration: const InputDecoration(
              labelText: 'Percorso nelle Dispense', hintText: 'Cartella / Sottocartella',
              helperText: 'Il percorso Drive non cambia')),
            DropdownButtonFormField<String>(value: state, decoration: const InputDecoration(labelText: 'Visibilità'),
              items: const [DropdownMenuItem(value: 'visible', child: Text('Visibile')),
                DropdownMenuItem(value: 'hidden', child: Text('Nascosto')),
                DropdownMenuItem(value: 'in_review', child: Text('In revisione')),
                DropdownMenuItem(value: 'archived', child: Text('Archiviato'))],
              onChanged: (v) { if (v != null) update(() => state = v); }),
            DropdownButtonFormField<String>(value: audience, decoration: const InputDecoration(labelText: 'Destinatari'),
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
            DropdownButtonFormField<String>(value: action,
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
          DropdownButtonFormField<int>(value: subjectId,
            items: [for (final s in _subjects) DropdownMenuItem(value: _integer(s['id']),
              child: Text('${s['name']} · ${s['course']}', overflow: TextOverflow.ellipsis))],
            onChanged: (v) { if (v != null) update(() => subjectId = v); }),
          DropdownButtonFormField<String>(value: audience,
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

  Widget _panel({required Widget child}) => Container(
    decoration: BoxDecoration(color: context.palette.eleganceMidnight,
      border: Border.all(color: context.palette.surfaceBorder),
      borderRadius: BorderRadius.circular(14)), child: child);

  Widget _drivePane() {
    final shown = _drive.where((e) => _string(e['name']).toLowerCase()
      .contains(_search.text.trim().toLowerCase())).toList();
    return _panel(child: Column(children: [
      const ListTile(leading: Icon(Icons.cloud_outlined, color: AppColors.adminCyan),
        title: Text('Google Drive', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Struttura reale, come sul Drive')),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: TextField(controller: _search,
        onChanged: (_) => setState(() {}), decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search), hintText: 'Cerca su Drive'))),
      if (_trail.length > 1) ListTile(dense: true, leading: const Icon(Icons.arrow_upward),
        title: Text(_trail.map((e) => e.$2).join(' / '), maxLines: 1, overflow: TextOverflow.ellipsis),
        onTap: () { _trail.removeLast(); _loadDrive(); }),
      Expanded(child: ListView(children: [
        for (final file in shown) ListTile(dense: true,
          leading: Icon(file['mime_type'] == 'application/vnd.google-apps.folder'
            ? Icons.folder_outlined : Icons.insert_drive_file_outlined,
            color: file['indexed'] == true ? AppColors.adminGreen : AppColors.materialSky),
          title: Text(_string(file['name']), maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: file['indexed'] == true ? const Text('Nel catalogo') : null,
          onTap: file['mime_type'] == 'application/vnd.google-apps.folder' ? () {
            _trail.add((_string(file['id']), _string(file['name']))); _loadDrive();
          } : () => showDriveFilePreview(context,
            load: () => _api.downloadDriveFilePreview(_string(file['id'])),
            name: _string(file['name']), mimeType: _string(file['mime_type'])),
          trailing: file['mime_type'] != 'application/vnd.google-apps.folder' && file['indexed'] != true
            ? IconButton(tooltip: 'Registra nelle Dispense', icon: const Icon(Icons.add_circle_outline),
                onPressed: _busy ? null : () => _import(file)) : null),
        if (_nextPage != null) TextButton(onPressed: _busy ? null : _more,
          child: const Text('Carica altri file')),
      ])),
      const Padding(padding: EdgeInsets.all(12), child: Text('● Nel catalogo    ● Solo su Drive',
        style: TextStyle(fontSize: 11, color: AppColors.adminGreen))),
    ]));
  }

  Widget _catalogPane() {
    final subset = _materials.where((m) => _integer(_effective(m)['subject_id']) == _subjectId &&
      _string(m['status']) != 'removed').map(_effective).toList();
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final m in subset) {
      final key = _path(m['path_segments']).join(' / ');
      groups.putIfAbsent(key, () => []).add(m);
    }
    final folderRows = _folders.where((f) => _integer(f['subject_id']) == _subjectId).toList();
    final importRows = _imports.where((f) => _integer(f['subject_id']) == _subjectId).toList();
    return _panel(child: Column(children: [
      ListTile(leading: const Icon(Icons.layers_outlined, color: AppColors.adminIndigo),
        title: const Text('Struttura per gli studenti', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Apparirà nelle Dispense, anche offline'),
        trailing: IconButton(tooltip: 'Nuova cartella nel catalogo',
          onPressed: _busy ? null : _addFolder, icon: const Icon(Icons.create_new_folder_outlined))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child:
        DropdownButtonFormField<int>(value: _subjects.any((s) => _integer(s['id']) == _subjectId) ? _subjectId : null,
          decoration: const InputDecoration(labelText: 'Materia'),
          items: [for (final s in _subjects) DropdownMenuItem(value: _integer(s['id']),
            child: Text('${s['name']} · ${s['course']}', overflow: TextOverflow.ellipsis))],
          onChanged: (value) => setState(() { _subjectId = value; _selectedId = null; }))),
      const SizedBox(height: 8),
      Expanded(child: subset.isEmpty && folderRows.isEmpty && importRows.isEmpty
        ? const Center(child: Text('Nessun materiale in questa materia.'))
        : ListView(children: [for (final group in groups.entries) ...[
          ListTile(dense: true, leading: const Icon(Icons.folder_outlined, color: AppColors.adminCyan),
            title: Text(group.key.isEmpty ? 'Materiali della materia' : group.key),
            trailing: group.key.isEmpty ? Text('${group.value.length} file')
              : IconButton(tooltip: 'Rinomina, sposta o nascondi la cartella',
                  icon: const Icon(Icons.more_horiz),
                  onPressed: _busy ? null : () => _editFolder(group.key, subset))),
          for (final material in group.value) Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
              color: _selectedId == _integer(material['id'])
                ? context.palette.materialBlue : null),
            child: ListTile(dense: true, contentPadding: const EdgeInsets.only(left: 24, right: 8),
              leading: const Icon(Icons.insert_drive_file_outlined, size: 18),
              title: Text(_string(material['title']), maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text('${material['draft'] == true ? 'BOZZA · ' : ''}${_string(material['visibility_state']).toUpperCase()} · ${_string(material['audience_type'])}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => setState(() { _selectedId = _integer(material['id']); _compactPane = 2; }))),
        ],
        for (final folder in folderRows.where((f) => !groups.containsKey(
            _path(f['path_segments']).join(' / '))))
          ListTile(leading: const Icon(Icons.folder_outlined, color: AppColors.adminCyan),
            title: Text(_path(folder['path_segments']).join(' / ')),
            subtitle: Text(folder['draft'] == true ? 'CARTELLA IN BOZZA' : 'Cartella vuota')),
        for (final file in importRows) ListTile(
          leading: const Icon(Icons.pending_outlined, color: AppColors.adminAmber),
          title: Text(_string(file['name'])),
          subtitle: Text('FILE IN BOZZA · ${_path(file['path_segments']).join(' / ')}'),
          onTap: () => showDriveFilePreview(context,
            load: () => _api.downloadDriveFilePreview(_string(file['drive_file_id'])),
            name: _string(file['name']), mimeType: _string(file['mime_type']))),
        ])),
      if (_draftCount > 0) Container(width: double.infinity,
        padding: const EdgeInsets.all(12), color: context.palette.eleganceSoftNight,
        child: Text('BOZZA · $_draftCount modifiche\n${_draft.map((d) => '• File ${d['material_id']} → ${_path(d['path_segments']).join(' / ')}').join('\n')}',
          maxLines: 7, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: AppColors.adminAmber))),
    ]));
  }

  Widget _detailsPane() {
    final matches = _materials.where((m) => _integer(m['id']) == _selectedId);
    if (matches.isEmpty) {
      return _panel(child: const Center(child: Padding(
        padding: EdgeInsets.all(22),
        child: Text('Seleziona un file per vedere i dettagli e gestire il suo percorso.'),
      )));
    }
    final row = _effective(matches.first);
    final id = _integer(row['id']);
    return _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ListTile(leading: const Icon(Icons.description_outlined, color: AppColors.materialSky),
        title: Text(_string(row['title']), maxLines: 3),
        subtitle: Text('${_string(row['visibility_state']).toUpperCase()}  ·  ${row['draft'] == true ? 'IN BOZZA' : 'NEL CATALOGO'}')),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Wrap(spacing: 8, children: [
        OutlinedButton.icon(icon: const Icon(Icons.visibility_outlined, size: 17),
          onPressed: () => showDriveFilePreview(context,
            load: () => _api.downloadPublicMaterialPreview(id),
            name: _string(row['original_name']), mimeType: _string(row['mime_type'])),
          label: const Text('Anteprima')),
        if (row['drive_file_id'] != null) const Chip(label: Text('Su Drive')),
      ])),
      const Divider(),
      _detail('PROVENIENZA', 'Materiale ${_string(row['source'])}'),
      _detail('FILE', '${_string(row['original_name'])}\n${_string(row['size'])} byte'),
      _detail('POSIZIONE DRIVE', _path(row['drive_path_segments']).join(' / ').isEmpty
        ? 'Il file rimane nella sua posizione originaria' : _path(row['drive_path_segments']).join(' / ')),
      _detail('POSIZIONE NELLE DISPENSE', _path(row['path_segments']).join(' / ').isEmpty
        ? 'Direttamente nella materia' : _path(row['path_segments']).join(' / ')),
      _detail('VISIBILITÀ', '${_string(row['visibility_state'])} · ${_string(row['audience_type'])}'),
      const Spacer(),
      Padding(padding: const EdgeInsets.all(12), child: FilledButton.icon(
        onPressed: _busy ? null : () => _stage(matches.first),
        icon: const Icon(Icons.drive_file_move_outline), label: const Text('Percorso e permessi'))),
    ]));
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10, letterSpacing: 1.2,
        color: AppColors.materialSky, fontWeight: FontWeight.bold)),
      const SizedBox(height: 5), Text(value),
    ]));

  Widget _previewPane() {
    final items = (_preview?['files'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final visible = items.where((e) => e['allowed'] == true).toList();
    return _panel(child: Column(children: [
      ListTile(leading: const Icon(Icons.visibility_outlined, color: AppColors.adminCyan),
        title: Text(_viewerId == null ? 'Anteprima guest' : 'Anteprima studente $_viewerId'),
        subtitle: const Text('Permessi calcolati dal server, incluse le bozze'),
        trailing: IconButton(onPressed: _setViewer, tooltip: 'Cambia studente',
          icon: const Icon(Icons.person_search_outlined))),
      const Divider(),
      Expanded(child: visible.isEmpty ? const Center(child: Text('Nessun file visibile per questo utente.'))
        : ListView(children: [for (final file in visible) ListTile(
          leading: const Icon(Icons.description_outlined, color: AppColors.adminGreen),
          title: Text(_string(file['title'])),
          subtitle: Text('${_path(file['path_segments']).join(' / ')}${file['draft'] == true ? ' · BOZZA' : ''}'))])),
      Padding(padding: const EdgeInsets.all(12), child: Text(
        '${visible.length} visibili · ${items.length - visible.length} esclusi',
        style: const TextStyle(color: AppColors.materialSky))),
    ]));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(backgroundColor: palette.darkElegance,
      appBar: AppBar(backgroundColor: palette.brandNightBlue,
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ADMIN / MATERIALI E STORAGE', style: TextStyle(fontSize: 10, letterSpacing: 1.5)),
          Text('Catalogo Drive', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))]),
        actions: [IconButton(onPressed: _busy ? null : _reload,
          tooltip: 'Aggiorna', icon: const Icon(Icons.refresh))]),
      body: _loading ? const Center(child: CircularProgressIndicator()) :
        LayoutBuilder(builder: (context, box) {
          final wide = box.maxWidth >= 900;
          return Column(children: [
            Padding(padding: const EdgeInsets.all(12), child: _panel(child: Padding(
              padding: const EdgeInsets.all(10), child: Wrap(spacing: 8, runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center, children: [
                  const Icon(Icons.shield_outlined, color: AppColors.adminCyan, size: 18),
                  const Text('Le modifiche riguardano solo il catalogo StudentLab. Drive resta invariato.',
                    style: TextStyle(fontSize: 12)),
                  if (_draftCount > 0) Chip(label: Text('$_draftCount MODIFICHE IN BOZZA')),
                  OutlinedButton(onPressed: _draftCount == 0 || _busy ? null : _discard,
                    child: const Text('Scarta bozza')),
                  FilledButton(onPressed: _draftCount == 0 || _busy ? null : _publish,
                    child: const Text('Pubblica struttura')),
                  SegmentedButton<bool>(segments: const [ButtonSegment(value: false,
                    label: Text('Struttura')), ButtonSegment(value: true,
                    label: Text('Anteprima studente'))],
                    selected: {_previewMode}, onSelectionChanged: (v) {
                      setState(() => _previewMode = v.first);
                      if (_previewMode) _loadPreview();
                    }),
                ])))),
            if (_error != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _panel(child: ListTile(leading: const Icon(Icons.error_outline,
                color: AppColors.adminCoral), title: Text(_error!),
                trailing: IconButton(onPressed: () => setState(() => _error = null),
                  icon: const Icon(Icons.close))))),
            if (!wide) NavigationBar(selectedIndex: _compactPane,
              onDestinationSelected: (i) => setState(() => _compactPane = i),
              destinations: const [NavigationDestination(icon: Icon(Icons.cloud_outlined), label: 'Drive'),
                NavigationDestination(icon: Icon(Icons.layers_outlined), label: 'Struttura'),
                NavigationDestination(icon: Icon(Icons.description_outlined), label: 'Dettaglio')]),
            Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: wide ? Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Expanded(flex: 26, child: _drivePane()), const SizedBox(width: 12),
                Expanded(flex: 46, child: _previewMode ? _previewPane() : _catalogPane()),
                const SizedBox(width: 12), Expanded(flex: 28, child: _detailsPane()),
              ]) : _compactPane == 0 ? _drivePane() : _compactPane == 1
                ? (_previewMode ? _previewPane() : _catalogPane()) : _detailsPane())),
          ]);
        }));
  }
}
