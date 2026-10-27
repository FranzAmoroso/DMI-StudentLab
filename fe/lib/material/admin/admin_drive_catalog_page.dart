import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../social/admin/admin_material_storage_api_service.dart';
import '../../theme/app_palette.dart';
import '../../widgets/studentlab_ui/studentlab_ui.dart';
import 'admin_material_upload_page.dart';
import 'drive_file_preview.dart';
import 'catalog_source.dart';
import 'mega_storage_api_service.dart';
import 'mega_transfer_jobs_page.dart';
import 'package:file_picker/file_picker.dart';
import 'admin_storage_sources_page.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../../services/user_facing_error.dart';
import '../upload/upload_items.dart';
import 'catalog_upload_page.dart';
import 'drive_destination_dialog.dart';
import 'drive_diagnostics.dart';
import 'mega_batch_copy_dialog.dart';
import 'subject_hierarchy_filter.dart';
import 'duplicate_compare_dialog.dart';
import 'folder_import_dialog.dart';
import 'structure_upload_dialog.dart';
import 'catalog_settings_dialogs.dart';

/// La struttura StudentLab è indipendente dai percorsi fisici su Drive.
class AdminDriveCatalogPage extends StatefulWidget {
  final CatalogSource initialSource;
  const AdminDriveCatalogPage({super.key, this.initialSource = CatalogSource.drive});

  @override
  State<AdminDriveCatalogPage> createState() => _AdminDriveCatalogPageState();
}

class _AdminDriveCatalogPageState extends State<AdminDriveCatalogPage> {
  final _api = AdminMaterialStorageApiService();
  final _mega = MegaStorageApiService();
  late CatalogSource _source = widget.initialSource;
  String? _sourceError;
  bool _sourceMissing = false;
  bool _sourceLoading = false;
  int _treeRequest = 0;
  int _sourceGeneration = 0;
  Map<String, dynamic>? _megaStatus;
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

  /// Cartelle Drive aperte nell'albero: id -> figli (caricati quando si aprono).
  final Map<String, List<Map<String, dynamic>>> _driveChildren = {};
  final Set<String> _driveOpen = <String>{};
  final Set<String> _driveLoading = <String>{};

  /// Mostra anche i file nascosti, in revisione o archiviati nella struttura.
  bool _showHidden = true;

  /// Cartella della struttura sotto il cursore durante il trascinamento.
  String? _dropTarget;

  /// v26: elementi MEGA selezionati per la copia su Drive (id -> elemento).
  final Map<String, Map<String, dynamic>> _megaSelected = {};

  /// v26: file o cartelle trascinati dal computer sopra il pannello della sorgente.
  bool _osDragging = false;

  /// v26: mostra la sezione «Tolti dalla struttura».
  bool _showRemoved = false;

  /// v26: filtro materie a cascata aperto.
  bool _filtersOpen = false;

  /// v27: cartelle chiuse nella struttura (chiave: percorso).
  final Set<String> _collapsed = <String>{};

  /// v27: file in arrivo su Drive che entreranno da soli nella bozza.
  int _waitingFiles = 0;

  /// v27: doppioni emersi dalle aggiunte automatiche, da decidere.
  final List<Map<String, dynamic>> _pendingConflicts = [];

  /// v27: file o cartelle del computer trascinati sopra la struttura.
  bool _pcDragging = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _treeRequest++;
    _sourceGeneration++;
    _search.dispose();
    super.dispose();
  }

  int _integer(Object? value) => int.tryParse('$value') ?? 0;
  int get _draftCount => _draft.length + _imports.length +
    _folders.where((folder) => folder['draft'] == true).length;
  String _string(Object? value) => value?.toString() ?? '';
  double _dialogWidth(BuildContext context, double preferred) {
    final available = MediaQuery.sizeOf(context).width - 80;
    return available < preferred ? available.clamp(160.0, preferred) : preferred;
  }
  List<String> _path(Object? value) => value is List ? value.map((e) => '$e').toList() : [];

  bool _isFolder(Map<String, dynamic> file) =>
    file['is_folder'] == true || file['mime_type'] == 'application/vnd.google-apps.folder';

  String _providerId(Map<String, dynamic> row) =>
      _string(row['provider_file_id']).isNotEmpty
          ? _string(row['provider_file_id']) : _string(row['drive_file_id']);

  List<String> _providerPath(Map<String, dynamic> row) =>
      _path(row['provider_path_segments'] ?? row['drive_path_segments']);

  Future<Map<String, dynamic>> _treeFor(CatalogSource source, String? folder, [String? token]) =>
      source == CatalogSource.drive ? _api.getDriveTree(folder, token) : _mega.getTree(folder, token);

  /// Albero della sorgente scelta (stessa forma dati per Drive e MEGA).


  Map<CatalogSource, int> get _sourceCounts {
    final counts = <CatalogSource, int>{for (final s in CatalogSource.values) s: 0};
    for (final m in _materials) {
      final source = sourceOfMaterial(m);
      if (source != null && _string(m['status']) != 'removed') counts[source] = counts[source]! + 1;
    }
    return counts;
  }

  void _switchSource(CatalogSource source) {
    if (source == _source) return;
    setState(() {
      _source = source;
      _trail..clear()..add((null, 'StudentLab'));
      _drive = [];
      _sourceGeneration++;
      _driveChildren.clear();
      _driveOpen.clear();
      _driveLoading.clear();
      _dropTarget = null;
      _megaSelected.clear();
      _nextPage = null;
      _sourceError = null;
      _sourceMissing = false;
      _search.clear();
    });
    _loadDrive();
  }

  Map<String, dynamic> _effective(Map<String, dynamic> item) {
    final id = _integer(item['id']);
    final change = _draft.where((d) => _integer(d['material_id']) == id);
    if (change.isEmpty) return item;
    final d = change.first;
    return {...item, 'subject_id': d['subject_id'], 'path_segments': d['path_segments'],
      'visibility_state': d['visibility_state'], 'audience_type': d['audience_type'],
      'audience_id': d['audience_id'], 'draft': true};
  }

  Future<void> _reload({bool intents = true}) async {
    setState(() { _loading = true; _error = null; });
    try {
      // La sorgente si carica a parte: se MEGA non risponde, il catalogo resta usabile.
      final data = await Future.wait<dynamic>([
        _api.getItems(source: 'public'),
        _api.getDriveImportOptions(),
        _api.getCatalogSnapshot(),
      ]);
      if (!mounted) return;
      final subjects = (data[1] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      final catalog = Map<String, dynamic>.from(data[2] as Map);
      setState(() {
        _materials = (data[0] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _subjects = subjects;
        _draft = (catalog['changes'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _folders = (catalog['folders'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _imports = (catalog['imports'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (_subjectId == null && subjects.isNotEmpty) _subjectId = _integer(subjects.first['id']);
        _loading = false;
      });
      final generation = _sourceGeneration;
      final source = _source;
      await _loadDrive();
      if (!mounted || generation != _sourceGeneration) return;
      final openFolders = _driveOpen.toList();
      _driveChildren.clear();
      for (final id in openFolders) {
        try {
          final children = await _folderChildren(source, id);
          if (!mounted || generation != _sourceGeneration) return;
          setState(() => _driveChildren[id] = children);
        } catch (_) {
          if (!mounted || generation != _sourceGeneration) return;
          setState(() => _driveOpen.remove(id));
        }
      }
      if (_previewMode) await _loadPreview();
      if (intents) _processIntents();
    } catch (error) {
      if (mounted) setState(() {
        _loading = false;
        _error = _reason(error, 'Il catalogo non è disponibile. Verifica la connessione e riprova.');
      });
    }
  }

  /// v27: aggiunge alla bozza i file arrivati su Drive (trascinati dal PC o copiati da MEGA).
  Future<void> _processIntents() async {
    Map<String, dynamic> result;
    try {
      result = await _api.processCatalogIntents();
    } catch (_) {
      return; // si riprova alla prossima apertura del catalogo
    }
    if (!mounted) return;
    final staged = _integer(result['staged']);
    final conflicts = (result['conflicts'] as List? ?? const [])
        .whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    final skipped = (result['skipped'] as List? ?? const []).whereType<Map>().toList();
    setState(() {
      _waitingFiles = _integer(result['waiting']);
      _pendingConflicts.addAll(conflicts);
    });
    if (staged > 0) {
      await _reload(intents: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
            '$staged file arrivati su Drive e aggiunti alla bozza, con le loro cartelle.')));
      }
    }
    if (skipped.isNotEmpty && mounted) {
      _showError('${skipped.length} file non aggiunti alla struttura. '
          'Per esempio «${skipped.first['name']}»: ${skipped.first['reason']}');
    }
  }

  /// v27: decide i doppioni emersi dalle aggiunte automatiche, uno alla volta.
  Future<void> _resolvePendingConflicts() async {
    while (_pendingConflicts.isNotEmpty && mounted) {
      final c = _pendingConflicts.first;
      final first = (c['conflicts'] as List? ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      final done = await _resolveConflictResult(
        fileId: _string(c['file_id']),
        name: _string(c['name']),
        result: {'conflicts': first},
        subjectId: _subjectId ?? _integer(first.isEmpty ? 0 : first.first['subject_id']),
        path: _path(c['path_segments']),
        audience: 'course',
      );
      if (done == null) break; // finestra chiusa: si riprende dopo
      setState(() => _pendingConflicts.removeAt(0));
    }
    if (mounted) await _reload(intents: false);
  }

  /// v27: il file nuovo somiglia a uno già nel catalogo (o è già nel catalogo).
  /// Ritorna null se l'admin chiude senza scegliere, altrimenti true.
  Future<bool?> _resolveConflictResult({
    required String fileId,
    required String name,
    required Map<String, dynamic> result,
    required int subjectId,
    required List<String> path,
    required String audience,
    int? audienceId,
  }) async {
    final already = result['already_in_catalog'];
    if (already is Map) {
      final known = Map<String, dynamic>.from(already);
      final restorable = result['restorable'] == true || _string(known['status']) == 'removed';
      final choice = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
        title: const Text('File già nel catalogo'),
        content: Text('«$name» è già nel catalogo in «${catalogPlace(known)}»'
            '${restorable ? ', ma è stato tolto dalla struttura.' : '.'}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, 'close'), child: const Text('Va bene così')),
          if (restorable)
            FilledButton(onPressed: () => Navigator.pop(ctx, 'restore'), child: const Text('Ripristina'))
          else
            FilledButton(onPressed: () => Navigator.pop(ctx, 'show'), child: const Text('Mostralo')),
        ],
      ));
      if (choice == null) return null;
      if (choice == 'restore') {
        await _api.restoreToStructure(_integer(known['id']));
        if (_integer(known['subject_id']) != subjectId || _path(known['path_segments']).join('/') != path.join('/')) {
          await _api.stageCatalogFile(materialId: _integer(known['id']), subjectId: subjectId,
              pathSegments: path, visibilityState: 'visible', audienceType: audience, audienceId: audienceId);
        }
      }
      if (choice == 'show') _revealMaterial(_integer(known['id']));
      return true;
    }
    final existing = (result['conflicts'] as List? ?? const [])
        .whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    if (existing.isEmpty) return true;
    final incoming = Map<String, dynamic>.from(result['incoming'] as Map? ?? {'name': name, 'size': existing.first['size']});
    incoming['drive_file_id'] = fileId;
    incoming['path_segments'] = path;
    incoming['subject_name'] ??= _subjectName(subjectId);
    final choice = await showDuplicateCompare(context, api: _api, incoming: incoming, existing: existing,
        pickFolder: (current) => _pickFolder(title: 'Dove mettere il file nuovo?', current: current));
    if (choice == null) return null;
    if (choice.action == DuplicateAction.keepExisting) return true;
    var target = path;
    if (choice.action == DuplicateAction.replace) {
      final old = choice.target!;
      await _api.removeFromStructure(materialIds: [_integer(old['id'])]);
      if (_integer(old['subject_id']) == subjectId) target = _path(old['path_segments']);
    } else {
      target = choice.path;
    }
    await _api.stageDriveImport(fileId: fileId, subjectId: subjectId, pathSegments: target,
        audienceType: audience, audienceId: audienceId, allowDuplicate: true);
    return true;
  }

  Future<void> _loadDrive() async {
    final source = _source;
    final request = ++_treeRequest;
    bool current() => mounted && request == _treeRequest;
    setState(() => _sourceLoading = true);
    try {
      final value = await _treeFor(source, _trail.last.$1);
      if (!current()) return;
      setState(() {
        _drive = (value['items'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _nextPage = value['next_page_token']?.toString();
        _sourceError = null;
        _sourceMissing = false;
        _search.clear();
      });
      if (source == CatalogSource.mega) {
        try {
          final status = await _mega.status();
          if (current()) setState(() => _megaStatus = status);
        } catch (_) {/* la quota è un'informazione in più: senza, l'albero resta usabile */}
      }
    } on MegaNotAvailable catch (error) {
      if (current()) setState(() { _drive = []; _nextPage = null; _sourceMissing = true; _sourceError = error.message; });
    } catch (error) {
      // v26: si mostra la frase del server (es. «L’accesso a Google Drive è scaduto…»), non un testo generico.
      if (current()) {
        setState(() {
          _drive = [];
          _nextPage = null;
          _sourceError = _reason(error, 'Impossibile aprire questa cartella ${source.shortLabel}. Riprova tra poco.');
        });
      }
    }
    if (current()) setState(() => _sourceLoading = false);
  }

  Future<void> _more() async {
    if (_nextPage == null || _busy) return;
    final token = _nextPage;
    final source = _source;
    final folder = _trail.last.$1;
    final generation = _sourceGeneration;
    final request = _treeRequest;
    bool current() => mounted && source == _source && generation == _sourceGeneration &&
        request == _treeRequest && folder == _trail.last.$1;
    setState(() => _busy = true);
    try {
      final value = await _treeFor(source, folder, token);
      if (current()) setState(() {
        _drive.addAll((value['items'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)));
        _nextPage = value['next_page_token']?.toString();
      });
    } catch (error) {
      if (current()) _showError(_reason(error, 'Non è stato possibile caricare gli altri file.'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Motivo leggibile restituito dal server (es. "Completa prima il
  /// caricamento su Drive."); se manca o è tecnico, il testo di riserva.
  String _reason(Object error, String fallback) => friendlyError(error, fallback);

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _error = message);
  }

  Future<void> _loadPreview() async {
    setState(() => _busy = true);
    try {
      final value = await _api.previewCatalog(userId: _viewerId);
      if (mounted) setState(() => _preview = value);
    } catch (e) { _showError(_reason(e, 'Anteprima non disponibile. Riprova tra poco.')); }
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
        content: SizedBox(width: _dialogWidth(ctx, 460), child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Le modifiche resteranno in bozza fino a «Pubblica struttura».'),
            const SizedBox(height: 16),
            SubjectPickerField(subjects: _subjects,
              value: _subjects.any((e) => _integer(e['id']) == subjectId) ? subjectId : null,
              onChanged: (v) => update(() => subjectId = v)),
            TextField(controller: path, decoration: const InputDecoration(
              labelText: 'Percorso nelle Dispense', hintText: 'Cartella / Sottocartella',
              helperText: 'Il percorso sulla sorgente non cambia')),
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
    } catch (e) { _showError(_reason(e, 'Modifica non salvata. Controlla materia, destinatari e percorso.')); }
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
        content: SizedBox(width: _dialogWidth(ctx, 400), child: Column(mainAxisSize: MainAxisSize.min,
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
    } catch (e) {
      _showError(_reason(e, 'Operazione sulla cartella incompleta. Controlla le modifiche in bozza prima di pubblicare.'));
      await _reload();
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _openMegaJobs() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const MegaTransferJobsPage()));
    if (mounted) await _reload();
  }

  Future<void> _downloadMega(Map<String, dynamic> file) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _mega.downloadPreview(_string(file['id']));
      if (!mounted) return;
      final name = _string(file['name']).replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      await FilePicker.saveFile(fileName: name.isEmpty ? 'materiale' : name, bytes: bytes);
    } catch (e) { if (mounted) _showError(_reason(e, 'Download non riuscito. Per file oltre 20 MB usa Copia su Drive.')); }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _copyMegaToDrive(Map<String, dynamic> file) async {
    final sourceId = _megaStatus?['source_id']?.toString();
    final destination = await showDialog<List<String>>(context: context,
      builder: (_) => DriveDestinationDialog(api: _api, title: 'Copia MEGA → Drive',
        intro: _isFolder(file)
          ? '${_string(file['name'])}: la cartella e le sottocartelle saranno copiate. Gli originali restano su MEGA finché non confermi.'
          : '${_string(file['name'])}: l’originale resta su MEGA finché non confermi.',
        confirmLabel: 'Avvia copia', initialPath: const ['Da MEGA']));
    if (!mounted || destination == null) return;
    setState(() => _busy = true);
    try {
      await _mega.copyToDrive(_string(file['id']), destination, sourceId: sourceId);
      if (mounted) {
        setState(() => _busy = false);
        await _openMegaJobs();
      }
    } catch (e) { if (mounted) _showError(_reason(e, 'Copia non avviata.')); }
    if (mounted) setState(() => _busy = false);
  }

  /// v26: copia di più elementi MEGA, ognuno con la sua cartella su Drive.
  Future<void> _copyMegaSelected() async {
    if (_megaSelected.isEmpty || _busy) return;
    final plan = await showDialog<List<(Map<String, dynamic>, List<String>)>>(context: context,
      builder: (_) => MegaBatchCopyDialog(api: _api, items: _megaSelected.values.toList()));
    if (plan == null || plan.isEmpty || !mounted) return;
    final sourceId = _megaStatus?['source_id']?.toString();
    setState(() => _busy = true);
    var started = 0;
    String? failure;
    for (final (item, path) in plan) {
      try {
        await _mega.copyToDrive(_string(item['id']), path, sourceId: sourceId);
        started++;
        _megaSelected.remove(_string(item['id']));
      } catch (e) {
        failure = _reason(e, 'Una copia non è stata avviata.');
      }
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure != null) _showError('$started copie avviate. $failure');
    if (started > 0) await _openMegaJobs();
  }

  Future<void> _import(Map<String, dynamic> file, {List<String>? initialPath}) async {
    final source = CatalogSourceInfo.fromApi(file['storage_provider']) ?? _source;
    if (_subjects.isEmpty) { _showError('Nessuna materia disponibile per classificare il file.'); return; }
    int subjectId = _subjectId ?? _integer(_subjects.first['id']);
    String audience = 'public';
    final recipient = TextEditingController();
    final pathController = TextEditingController(text: (initialPath ?? const <String>[]).join(' / '));
    final selected = await showDialog<(int, String, int?, List<String>)>(context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, update) => AlertDialog(
        title: Text('Aggiungi da ${source.shortLabel}'),
        content: SizedBox(width: _dialogWidth(ctx, 420), child: SingleChildScrollView(child:
          Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_string(file['name']), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          Text(source == CatalogSource.mega ? 'Il file verrà copiato su Drive. Completa la registrazione dalla pagina Copie; sarà visibile dopo «Pubblica struttura».' : 'Il file resta su Drive. Sarà visibile solo dopo «Pubblica struttura».'),
          SubjectPickerField(subjects: _subjects, value: subjectId,
            onChanged: (v) => update(() => subjectId = v)),
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
    List<String>? megaDrivePath;
    if (source == CatalogSource.mega) {
      final subjectName = _subjects.where((s) => _integer(s['id']) == selected.$1)
          .map((s) => _string(s['name'])).firstWhere((s) => s.isNotEmpty, orElse: () => 'Da MEGA');
      megaDrivePath = await showDialog<List<String>>(context: context,
        builder: (_) => DriveDestinationDialog(api: _api, title: 'Dove copiarlo su Drive',
          intro: 'Il file viene copiato su Drive; a copia finita lo aggiungi alla bozza dalla pagina Copie.',
          confirmLabel: 'Avvia copia',
          initialPath: [subjectName.replaceAll('/', '-'), ...selected.$4]));
      if (megaDrivePath == null || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      if (source == CatalogSource.mega) {
        // v27: copia su Drive e aggiunta automatica alla bozza a copia verificata.
        final job = await _mega.copyToDrive(_string(file['id']), megaDrivePath!,
            sourceId: _megaStatus?['source_id']?.toString());
        await _api.createCatalogIntent(kind: 'mega', subjectId: selected.$1, audienceType: selected.$2,
            audienceId: selected.$3, megaJobId: _string(job['id']), basePath: selected.$4);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(
              'Copia su Drive avviata. Il file entra nella bozza da solo appena la copia è verificata.')));
        }
      } else {
        final result = await _api.stageDriveImport(fileId: _string(file['id']),
            subjectId: selected.$1, pathSegments: selected.$4,
            audienceType: selected.$2, audienceId: selected.$3);
        if (result['staged'] != true) {
          await _resolveConflictResult(fileId: _string(file['id']), name: _string(file['name']),
              result: result, subjectId: selected.$1, path: selected.$4,
              audience: selected.$2, audienceId: selected.$3);
        }
      }
      await _reload();
    } catch (e) { _showError(_reason(e, 'File non aggiunto alla bozza. Verifica i permessi su Drive e riprova.')); }
    if (mounted) setState(() => _busy = false);
  }

  /// v27: aggiunge una cartella con tutte le sottocartelle e i file (da Drive o da MEGA).
  /// Prima mostra l'albero da spuntare; la cartella con il nome della materia non diventa un argomento.
  Future<void> _importFolder(Map<String, dynamic> folder, {List<String>? initialPath}) async {
    if (_busy) return;
    if (_subjects.isEmpty) { _showError('Nessuna materia disponibile per classificare i file.'); return; }
    final source = CatalogSourceInfo.fromApi(folder['storage_provider']) ?? _source;
    final rootName = _string(folder['name']);
    final files = <(Map<String, dynamic>, List<String>)>[];
    final folders = <List<String>>[[rootName]];
    final visited = <String>{};
    final alreadyIn = <String, int>{};
    var excluded = 0;
    Future<void> collect(String id, List<String> path) async {
      if (path.length > 12 || !visited.add(id)) throw StateError('Struttura della cartella non valida.');
      for (final item in await _folderChildren(source, id)) {
        if (_isFolder(item)) {
          final sub = [...path, _string(item['name'])];
          folders.add(sub);
          await collect(_string(item['id']), sub);
          continue;
        }
        final mime = _string(item['mime_type']);
        final size = _integer(item['size']);
        if (item['indexed'] == true) {
          excluded++;
          final where = _materialForSource(_string(item['copied_drive_file_id']).isNotEmpty
              ? _string(item['copied_drive_file_id']) : _string(item['id']));
          final name = where == null ? 'un’altra materia' : _subjectName(_integer(_effective(where)['subject_id']));
          alreadyIn[name] = (alreadyIn[name] ?? 0) + 1;
          continue;
        }
        if (mime.startsWith('application/vnd.google-apps.') || size <= 0) {
          excluded++;
          continue;
        }
        files.add((item, path));
        if (files.length > 2000) throw StateError('Seleziona una cartella con al massimo 2000 file.');
      }
    }
    setState(() => _busy = true);
    try {
      await collect(_string(folder['id']), [rootName]);
    } catch (error) {
      if (mounted) {
        _showError(_reason(error, 'Impossibile leggere questa cartella.'));
        setState(() => _busy = false);
      }
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    final present = alreadyIn.entries.map((e) => '${e.value} in «${e.key}»').join(', ');
    if (files.isEmpty && folders.length == 1) {
      _showError([
        'Questa cartella non ha file nuovi da aggiungere.',
        if (present.isNotEmpty) 'Sono già nel catalogo: $present. Tocca ⌖ accanto a un file per aprirlo nella struttura.',
        if (excluded > alreadyIn.values.fold<int>(0, (a, b) => a + b)) 'Alcuni file non sono compatibili (documenti Google o file vuoti).',
      ].join(' '));
      return;
    }
    final choice = await showFolderImportDialog(context,
        title: 'Aggiungi «$rootName» da ${source.shortLabel}',
        rootName: rootName,
        files: files,
        folders: folders,
        excluded: excluded,
        subjects: _subjects,
        initialSubjectId: _subjectId,
        initialDestination: initialPath ?? const <String>[],
        note: [
          if (present.isNotEmpty) 'Già nel catalogo: $present.',
          if (source == CatalogSource.mega) 'I file vengono prima copiati su Drive ed entrano nella bozza da soli a copia verificata.',
        ].join(' '));
    if (choice == null || !mounted) return;
    if (source == CatalogSource.mega) {
      await _importMegaFolder(folder, choice, allFiles: files.length);
      return;
    }
    setState(() => _busy = true);
    var staged = 0;
    var folderCount = 0;
    final conflicts = <(String, String, Map<String, dynamic>, List<String>)>[];
    String? failure;
    try {
      for (final f in _emptyFolders(choice)) {
        await _api.stageCatalogFolder(subjectId: choice.subjectId, pathSegments: f);
        folderCount++;
      }
      for (final entry in choice.files) {
        final path = choice.catalogPath(entry.$2);
        final result = await _api.stageDriveImport(fileId: _string(entry.$1['id']), subjectId: choice.subjectId,
            pathSegments: path, audienceType: choice.audience, audienceId: choice.audienceId);
        if (result['staged'] == true) {
          staged++;
        } else {
          conflicts.add((_string(entry.$1['id']), _string(entry.$1['name']), result, path));
        }
      }
    } catch (error) {
      failure = _reason(error, 'Aggiunta interrotta.');
    }
    if (!mounted) return;
    setState(() { _busy = false; _subjectId = choice.subjectId; });
    var decided = 0;
    for (final (fileId, name, result, path) in conflicts) {
      if (!mounted) break;
      try {
        final done = await _resolveConflictResult(fileId: fileId, name: name, result: result,
            subjectId: choice.subjectId, path: path, audience: choice.audience, audienceId: choice.audienceId);
        if (done == null) break;
        decided++;
      } catch (error) {
        failure = _reason(error, 'Un doppione non è stato sistemato.');
      }
    }
    await _reload();
    if (!mounted) return;
    final message = [
      '$staged file aggiunti alla bozza',
      if (folderCount > 0) '$folderCount cartelle vuote create',
      if (conflicts.isNotEmpty) '${conflicts.length} possibili doppioni (${conflicts.length - decided} da decidere)',
    ].join(' · ');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$message.${failure == null ? '' : ' $failure'}')));
  }

  /// Cartelle scelte che restano senza file: vanno create a parte nella struttura.
  List<List<String>> _emptyFolders(FolderImportChoice choice) {
    final withFiles = <String>{};
    for (final f in choice.files) {
      final path = choice.catalogPath(f.$2);
      for (var i = 1; i <= path.length; i++) {
        withFiles.add(path.take(i).join('\u0000'));
      }
    }
    final result = <List<String>>[];
    for (final f in choice.folders) {
      final path = choice.catalogPath(f);
      if (path.isNotEmpty && !withFiles.contains(path.join('\u0000'))) result.add(path);
    }
    return result;
  }

  /// v27: cartella da MEGA. Si copia su Drive e i file entrano da soli nella bozza a copia verificata.
  Future<void> _importMegaFolder(Map<String, dynamic> folder, FolderImportChoice choice, {required int allFiles}) async {
    final subjectName = _subjectName(choice.subjectId).split(' · ').first;
    final drivePath = await showDialog<List<String>>(context: context, builder: (_) => DriveDestinationDialog(
        api: _api, title: 'Dove copiarla su Drive',
        intro: 'Gli originali restano su MEGA finché non confermi. Su Drive vengono ricreate le stesse cartelle.',
        confirmLabel: 'Avvia copia',
        initialPath: [subjectName.replaceAll('/', '-'), ...choice.destination]));
    if (drivePath == null || !mounted) return;
    final sourceId = _megaStatus?['source_id']?.toString();
    setState(() => _busy = true);
    var jobs = 0;
    String? failure;
    try {
      for (final f in _emptyFolders(choice)) {
        await _api.stageCatalogFolder(subjectId: choice.subjectId, pathSegments: f);
      }
      if (choice.files.length == allFiles) {
        // Tutta la cartella: una sola copia, le sottocartelle si ricostruiscono dai percorsi.
        final job = await _mega.copyToDrive(_string(folder['id']), drivePath, sourceId: sourceId);
        await _api.createCatalogIntent(kind: 'mega', subjectId: choice.subjectId, audienceType: choice.audience,
            audienceId: choice.audienceId, megaJobId: _string(job['id']), basePath: choice.destination,
            skipFirst: !choice.includeRoot);
        jobs = 1;
      } else {
        if (choice.files.length > 20) {
          throw StateError('Con una scelta parziale si possono copiare al massimo 20 file alla volta. '
              'Scegli tutta la cartella oppure meno file.');
        }
        for (final entry in choice.files) {
          final job = await _mega.copyToDrive(_string(entry.$1['id']), [...drivePath, ...entry.$2], sourceId: sourceId);
          await _api.createCatalogIntent(kind: 'mega', subjectId: choice.subjectId, audienceType: choice.audience,
              audienceId: choice.audienceId, megaJobId: _string(job['id']), basePath: choice.catalogPath(entry.$2));
          jobs++;
        }
      }
    } catch (error) {
      failure = _reason(error, 'Copia non avviata.');
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure != null) _showError(jobs == 0 ? failure : '$jobs copie avviate. $failure');
    if (jobs > 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(
          'Copia su Drive avviata. Cartelle e file entrano nella bozza da soli appena la copia è verificata: '
          'riapri o aggiorna il catalogo tra qualche minuto.')));
      await _openMegaJobs();
    }
  }

  // ---------------------------------------------------------------------------
  // v26: correzioni della struttura
  // ---------------------------------------------------------------------------

  /// Annulla una sola modifica della bozza (file spostato, file aggiunto, cartella nuova).
  Future<void> _undoDraftItem(String kind, int id) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _api.discardCatalogDraftItem(kind, id);
      await _reload();
    } catch (e) {
      _showError(_reason(e, 'Modifica non annullata. Aggiorna la pagina e riprova.'));
    }
    if (mounted) setState(() => _busy = false);
  }

  /// «Togli dalla struttura»: il materiale esce dal catalogo; il file resta su Drive.
  Future<void> _removeFromStructure({List<int>? materialIds, List<String>? folder, required String label,
      int count = 1}) async {
    if (_busy) return;
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Togliere dalla struttura?'),
      content: Text(folder == null
          ? '«$label» non sarà più visibile agli studenti. Il file resta su Drive e puoi ripristinarlo da «Tolti dalla struttura».'
          : 'La cartella «$label» e i suoi $count file escono dalla struttura. I file restano su Drive e puoi ripristinarli da «Tolti dalla struttura».'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Togli dalla struttura'))]));
    if (confirm != true || !mounted) return;
    setState(() => _busy = true);
    try {
      // v27: si mandano i file che si vedono nella cartella (anche spostati in bozza);
      // il percorso serve solo per cartelle e file nuovi in bozza.
      final result = await _api.removeFromStructure(materialIds: materialIds,
          subjectId: folder == null ? null : _subjectId, pathSegments: folder, foldersOnly: folder != null);
      if (materialIds != null && materialIds.contains(_selectedId)) _selectedId = null;
      await _reload(intents: false);
      final removed = _integer(result['removed']);
      final folders = _integer(result['folders']);
      final drafts = _integer(result['drafts_discarded']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(removed + folders + drafts == 0
          ? 'Non c’era nulla da togliere: la cartella era già vuota o già tolta. Ho aggiornato la struttura.'
          : [
              if (removed > 0) '$removed file tolti dalla struttura (restano su Drive)',
              if (drafts > 0) '$drafts aggiunte in bozza annullate',
              if (folders > 0) '$folders cartelle tolte',
            ].join(' · '))));
      }
    } catch (e) {
      _showError(_reason(e, 'Non è stato possibile togliere dalla struttura.'));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _restore(Map<String, dynamic> material) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _api.restoreToStructure(_integer(material['id']));
      await _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(
          'File ripristinato come «Nascosto». Rendilo visibile quando vuoi.')));
      }
    } catch (e) {
      _showError(_reason(e, 'Ripristino non riuscito.'));
    }
    if (mounted) setState(() => _busy = false);
  }

  /// «Elimina da Drive»: conferma scritta (ELIMINA). Il file va nel cestino di Drive.
  Future<void> _deleteFromDrive(List<Map<String, dynamic>> materials, {required String label}) async {
    final onDrive = materials.where((m) => _providerId(m).isNotEmpty ||
        _string(m['stored_name']).startsWith('drive-import/')).toList();
    if (_busy) return;
    if (onDrive.isEmpty) {
      _showError('Nessuno di questi file è su Drive.');
      return;
    }
    final typed = TextEditingController();
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, update) => AlertDialog(
        title: const Text('Eliminare da Drive?'),
        content: SizedBox(width: _dialogWidth(ctx, 440), child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(onDrive.length == 1
                ? '«$label» viene tolto dalla struttura e spostato nel cestino di Google Drive.'
                : '${onDrive.length} file di «$label» vengono tolti dalla struttura e spostati nel cestino di Google Drive.'),
            const SizedBox(height: 8),
            const Text('Dal cestino di Drive si possono recuperare per 30 giorni. Gli studenti non li vedranno più, '
                'anche offline alla prossima sincronizzazione.'),
            const SizedBox(height: 12),
            TextField(controller: typed, autofocus: true, onChanged: (_) => update(() {}),
              decoration: const InputDecoration(labelText: 'Scrivi ELIMINA per confermare')),
          ])),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: typed.text.trim() == 'ELIMINA' ? () => Navigator.pop(ctx, true) : null,
            child: const Text('Elimina da Drive'))],
      )));
    final word = typed.text.trim();
    typed.dispose();
    if (confirm != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final result = await _api.deleteFromDrive([for (final m in onDrive) _integer(m['id'])], word);
      final deleted = (result['deleted'] as List? ?? const []).length;
      final skipped = (result['skipped'] as List? ?? const []).whereType<Map>().toList();
      if (onDrive.any((m) => _integer(m['id']) == _selectedId)) _selectedId = null;
      await _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(skipped.isEmpty
          ? '$deleted file spostati nel cestino di Drive.'
          : '$deleted file spostati nel cestino di Drive; ${skipped.length} non eliminati: ${skipped.first['reason']}')));
      }
    } catch (e) {
      _showError(_reason(e, 'Eliminazione da Drive non riuscita.'));
      await _reload();
    }
    if (mounted) setState(() => _busy = false);
  }

  /// Caricamento di più file o cartelle (anche trascinati dal computer).
  Future<void> _openUpload({UploadSelection? selection}) async {
    final destination = _source == CatalogSource.mega ? 'mega' : 'drive';
    final path = destination == 'drive' ? [for (final t in _trail.skip(1)) t.$2] : <String>[];
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CatalogUploadPage(
      initialDestination: destination, initialPath: path, initialSelection: selection,
      subjects: _subjects, initialSubjectId: _subjectId)));
    if (mounted) await _reload();
  }

  Future<void> _chooseUpload() async {
    final choice = await showModalBottomSheet<String>(context: context, showDragHandle: true,
      builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.upload_file_rounded), title: const Text('Un file, pubblicato subito'),
          subtitle: const Text('Titolo, materia e destinatari in un solo passaggio'),
          onTap: () => Navigator.pop(ctx, 'single')),
        ListTile(leading: const Icon(Icons.drive_folder_upload_outlined), title: const Text('Più file o cartelle intere'),
          subtitle: const Text('Anche trascinandoli dal computer; poi li aggiungi alla struttura'),
          onTap: () => Navigator.pop(ctx, 'bulk')),
        ListTile(leading: const Icon(Icons.account_tree_outlined), title: const Text('Dal computer direttamente nella struttura'),
          subtitle: const Text('File o cartelle con sottocartelle: entrano nella bozza da soli dopo la copia su Drive'),
          onTap: () => Navigator.pop(ctx, 'structureFiles')),
        if (canPickFolder)
          ListTile(leading: const Icon(Icons.create_new_folder_outlined), title: const Text('Una cartella del computer nella struttura'),
            onTap: () => Navigator.pop(ctx, 'structureFolder')),
      ])));
    if (!mounted || choice == null) return;
    if (choice == 'structureFiles' || choice == 'structureFolder') {
      final selection = choice == 'structureFolder' ? await pickUploadFolder(maxBytes: adminDriveMaxBytes) : await pickUploadFiles(maxBytes: adminDriveMaxBytes);
      if (selection != null && mounted) await _dropFromPc(selection);
      return;
    }
    if (choice == 'bulk') {
      await _openUpload();
      return;
    }
    final done = await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (_) => AdminMaterialUploadPage(initialSubjectId: _subjectId)));
    if (done == true && mounted) await _reload();
  }

  Future<void> _publish() async {
    if (_draftCount == 0 || _busy) return;
    setState(() => _busy = true);
    try {
      // v29: prima si controllano i file identici e si sceglie quale tenere.
      final check = await _api.checkCatalogDraft();
      final groups = [
        for (final g in (check['groups'] as List? ?? const []).whereType<Map>())
          (g['files'] as List? ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(),
      ];
      if (groups.isNotEmpty) {
        if (mounted) setState(() => _busy = false);
        final solved = await _chooseIdentical(groups);
        if (!solved || !mounted) return;
        setState(() => _busy = true);
      }
      try {
        await _api.publishCatalogDraft();
      } catch (e) {
        // v31: se la pubblicazione trova comunque file identici, si riapre la scelta
        // e si riprova una volta, invece di fermarsi con un messaggio.
        final again = await _api.checkCatalogDraft();
        final more = [
          for (final g in (again['groups'] as List? ?? const []).whereType<Map>())
            (g['files'] as List? ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(),
        ];
        if (more.isEmpty) rethrow;
        if (mounted) setState(() => _busy = false);
        final solved = await _chooseIdentical(more);
        if (!solved || !mounted) return;
        setState(() => _busy = true);
        await _api.publishCatalogDraft();
      }
      await _reload();
    } catch (e) {
      _showError(_reason(e, 'La pubblicazione non è riuscita. Aggiorna il catalogo e controlla la bozza.'));
    }
    if (mounted) setState(() => _busy = false);
  }

  /// v29: per ogni gruppo di file identici, l'admin sceglie quale tenere (o li tiene tutti).
  Future<bool> _chooseIdentical(List<List<Map<String, dynamic>>> groups) async {
    for (var g = 0; g < groups.length; g++) {
      final files = groups[g];
      String place(Map<String, dynamic> f) => [
            if (_string(f['subject_name']).isNotEmpty) _string(f['subject_name']),
            ..._path(f['path_segments']),
          ].join(' / ');
      final choice = await showDialog<Object>(context: context, builder: (ctx) => AlertDialog(
        title: Text('File identici (${g + 1} di ${groups.length})'),
        content: SizedBox(width: _dialogWidth(ctx, 560), child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Questi file hanno lo stesso contenuto. Scegli quale tenere: gli altri vengono tolti dalla bozza '
                '(se già pubblicati, escono dalla struttura ma restano su Drive).'),
            const SizedBox(height: 10),
            for (final f in files)
              Card(child: ListTile(
                title: Text(_string(f['title']).isEmpty ? _string(f['name']) : _string(f['title'])),
                subtitle: Text('${place(f)}\n${_bytes(f['size'])} · '
                    '${f['kind'] == 'published' ? 'già pubblicato' : 'nuovo, in bozza'}'),
                isThreeLine: true,
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(tooltip: 'Anteprima', icon: const Icon(Icons.visibility_outlined),
                    onPressed: () => showDriveFilePreview(ctx,
                      load: () => f['kind'] == 'published'
                          ? _api.downloadPublicMaterialPreview(_integer(f['id']))
                          : _api.downloadDriveFilePreview(_string(f['drive_file_id'])),
                      name: _string(f['name']), mimeType: _string(f['mime_type']))),
                  FilledButton(onPressed: () => Navigator.pop(ctx, f), child: const Text('Tieni questo')),
                ]),
              )),
          ]))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla pubblicazione')),
          TextButton(onPressed: () => Navigator.pop(ctx, 'all'), child: const Text('Tienili tutti')),
        ],
      ));
      if (choice == null || !mounted) return false;
      setState(() => _busy = true);
      try {
        if (choice == 'all') {
          for (final f in files.where((f) => f['kind'] == 'import')) {
            await _api.stageDriveImport(fileId: _string(f['drive_file_id']), subjectId: _integer(f['subject_id']),
                pathSegments: _path(f['path_segments']), audienceType: _string(_imports.firstWhere(
                    (i) => _integer(i['id']) == _integer(f['id']), orElse: () => const {'audience_type': 'course'})['audience_type']),
                allowDuplicate: true);
          }
        } else if (choice is Map) {
          for (final f in files.where((f) => !identical(f, choice))) {
            if (f['kind'] == 'import') {
              await _api.discardCatalogDraftItem('import', _integer(f['id']));
            } else {
              await _api.removeFromStructure(materialIds: [_integer(f['id'])]);
            }
          }
        }
      } catch (e) {
        _showError(_reason(e, 'Non è stato possibile sistemare i file identici.'));
        if (mounted) setState(() => _busy = false);
        return false;
      }
      if (mounted) setState(() => _busy = false);
    }
    return true;
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
    catch (e) { _showError(_reason(e, 'Non è stato possibile scartare la bozza.')); }
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
            helperText: 'Verrà creata nel catalogo StudentLab')),
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
    } catch (e) { _showError(_reason(e, 'Cartella non aggiunta. Controlla il percorso.')); }
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

  String _fileKindLabel(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return switch (ext) {
      'pdf' => 'PDF',
      'doc' || 'docx' => 'Documento Word',
      'ppt' || 'pptx' => 'Presentazione',
      'xls' || 'xlsx' || 'csv' => 'Foglio di calcolo',
      'png' || 'jpg' || 'jpeg' || 'webp' => 'Immagine',
      'zip' => 'Archivio ZIP',
      'txt' || 'md' => 'Testo',
      '' => 'File',
      _ => ext.toUpperCase(),
    };
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
                        child: Text('Cambia solo la posizione per gli studenti. Sulla sorgente i file restano dove sono.',
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
    } catch (e) {
      _showError(_reason(e, 'Modifica non salvata in bozza. Controlla materia, destinatari e percorso.'));
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

  /// Nome mostrato agli studenti. Su Drive il file mantiene il suo nome.
  /// Si applica subito (non passa dalla bozza), come la rinomina esistente.
  Future<void> _renameFile(Map<String, dynamic> item) async {
    final p = context.palette;
    final controller = TextEditingController(text: _string(item['title']));
    final String? name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: p.eleganceDeepNavy,
        title: const Text('Rinomina per gli studenti'),
        content: SizedBox(
          width: 420,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: 250,
              decoration: const InputDecoration(labelText: 'Nome nelle Dispense'),
            ),
            Text('Sulla sorgente il file mantiene il nome ${_string(item['original_name'])}. '
                'Il nuovo nome si applica subito, senza passare dalla bozza.',
                style: SlText.muted(p)),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annulla')),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: const Text('Rinomina'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name == _string(item['title']) || !mounted) return;
    setState(() => _busy = true);
    try {
      await _api.rename(source: 'public', materialId: _integer(item['id']), displayName: name);
      await _reload();
    } catch (e) {
      _showError(_reason(e, 'Nome non aggiornato. Riprova.'));
    }
    if (mounted) setState(() => _busy = false);
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
    return Container(
      decoration: BoxDecoration(
        color: elevated ? p.eleganceDeepNavy : p.eleganceMidnight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.skyBlue.withValues(alpha: elevated ? 0.18 : 0.12)),
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
    return LayoutBuilder(builder: (context, bounds) => Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          SlIconTile(icon: icon, tone: tone, size: 34),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: p.pureWhite, fontSize: 14, fontWeight: FontWeight.w700)),
            Text(subtitle, style: SlText.muted(p).copyWith(fontSize: 11)),
          ])),
          if (bounds.maxWidth >= 620) ...trailing,
        ]),
        if (bounds.maxWidth < 620 && trailing.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: trailing),
        ],
      ]),
    ));
  }

  Future<List<Map<String, dynamic>>> _folderChildren(CatalogSource source, String id) async {
    final items = <Map<String, dynamic>>[];
    String? token;
    final seen = <String>{};
    do {
      final value = await _treeFor(source, id, token);
      items.addAll((value['items'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)));
      token = value['next_page_token']?.toString();
      if (token != null && !seen.add(token)) throw StateError('Paginazione della cartella non valida.');
    } while (token != null);
    return items;
  }

  /// Materiale del catalogo collegato a un file della sorgente (id Drive).
  Map<String, dynamic>? _materialForSource(String sourceId) {
    if (sourceId.isEmpty) return null;
    for (final m in _materials) {
      if (_string(m['status']) == 'removed') continue;
      if (_providerId(m) == sourceId || _string(m['stored_name']) == 'drive-import/$sourceId') return m;
    }
    return null;
  }

  String _subjectName(int subjectId) {
    for (final s in _subjects) {
      if (_integer(s['id']) == subjectId) return subjectSummary(s);
    }
    return 'una materia non attiva';
  }

  /// Porta alla materia e al file nella struttura per gli studenti.
  void _revealMaterial(int materialId) {
    final found = _materials.where((m) => _integer(m['id']) == materialId);
    if (found.isEmpty) {
      _showError('Il file non è nell’elenco caricato. Premi Aggiorna e riprova.');
      return;
    }
    final material = found.first;
    final subjectId = _integer(_effective(material)['subject_id']);
    if (!_subjects.any((s) => _integer(s['id']) == subjectId)) {
      _showError('Il file è in una materia non più attiva. Riattiva la materia oppure spostalo da «Materia, destinatari e stato».');
      return;
    }
    final path = _path(_effective(material)['path_segments']);
    setState(() {
      _subjectId = subjectId;
      _selectedId = materialId;
      _showHidden = true;
      _filtersOpen = false;
      _compactPane = 2;
      for (var i = 1; i <= path.length; i++) {
        _collapsed.remove(path.take(i).join('\u0000'));
      }
    });
  }

  void _revealInStructure(String sourceId) {
    final material = _materialForSource(sourceId);
    if (material == null) {
      _showError('Il file risulta nel catalogo ma non è nell’elenco caricato. Premi Aggiorna e riprova.');
      return;
    }
    _revealMaterial(_integer(material['id']));
  }

  /// v27: «Porta il contenuto su di un livello»: la cartella sparisce, il contenuto sale (in bozza).
  Future<void> _flattenFolder(List<String> folder) async {
    if (_busy || folder.isEmpty) return;
    final parent = folder.take(folder.length - 1).toList();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text('Togliere il livello «${folder.last}»?'),
      content: Text('File e sottocartelle di «${folder.last}» passano in '
          '«${[_string(_currentSubject?['name']), ...parent].join(' / ')}». Le modifiche restano in bozza.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Porta su'))]));
    if (ok != true || !mounted) return;
    bool inside(List<String> p) => p.length >= folder.length && p.take(folder.length).join('\u0000') == folder.join('\u0000');
    List<String> lifted(List<String> p) => [...parent, ...p.skip(folder.length)];
    setState(() => _busy = true);
    try {
      for (final m in _materials.where((m) => _string(m['status']) != 'removed')) {
        final e = _effective(m);
        if (_integer(e['subject_id']) != _subjectId || !inside(_path(e['path_segments']))) continue;
        await _api.stageCatalogFile(materialId: _integer(m['id']), subjectId: _integer(e['subject_id']),
            pathSegments: lifted(_path(e['path_segments'])), visibilityState: _string(e['visibility_state']).isEmpty ? 'visible' : _string(e['visibility_state']),
            audienceType: _string(e['audience_type']).isEmpty ? 'public' : _string(e['audience_type']),
            audienceId: e['audience_id'] == null ? null : _integer(e['audience_id']));
      }
      for (final i in _imports.where((i) => _integer(i['subject_id']) == _subjectId && inside(_path(i['path_segments'])))) {
        await _api.stageDriveImport(fileId: _string(i['drive_file_id']), subjectId: _integer(i['subject_id']),
            pathSegments: lifted(_path(i['path_segments'])), audienceType: _string(i['audience_type']),
            audienceId: i['audience_id'] == null ? null : _integer(i['audience_id']), allowDuplicate: true);
      }
      for (final f in _folders.where((f) => _integer(f['subject_id']) == _subjectId && inside(_path(f['path_segments'])))) {
        final target = lifted(_path(f['path_segments']));
        if (target.isNotEmpty) await _api.stageCatalogFolder(subjectId: _subjectId!, pathSegments: target);
      }
      // Toglie le vecchie cartelle vuote (solo cartelle del catalogo, nessun file).
      await _api.removeFromStructure(subjectId: _subjectId, pathSegments: folder, foldersOnly: true);
      await _reload(intents: false);
    } catch (e) {
      _showError(_reason(e, 'Non tutto il contenuto è stato spostato. Controlla la bozza.'));
      await _reload(intents: false);
    }
    if (mounted) setState(() => _busy = false);
  }

  /// v27: file e cartelle del computer rilasciati sulla struttura.
  Future<void> _dropFromPc(UploadSelection selection) async {
    if (selection.items.isEmpty) {
      _showError(selection.note ?? 'Nessun file da caricare.');
      return;
    }
    final subject = _currentSubject;
    if (subject == null || _subjectId == null) {
      _showError('Scegli prima la materia nel filtro, poi trascina di nuovo i file.');
      return;
    }
    final ok = await showStructureUploadDialog(context,
        api: _api, selection: selection, subjectId: _subjectId!, subjectName: _string(subject['name']),
        initialFolder: const <String>[],
        pickFolder: (current) => _pickFolder(title: 'Dove metterli nella struttura?', current: current));
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(
          'File caricati su Drive e aggiunti alla bozza con le loro cartelle. '
          'Se qualcuno è passato dal trasferimento classico, arriva tra qualche minuto.')));
      await _reload();
    }
  }

  Widget _pcDropArea(Widget child) {
    final p = context.palette;
    return DropTarget(
      enable: !_busy && !_previewMode,
      onDragEntered: (_) => setState(() => _pcDragging = true),
      onDragExited: (_) => setState(() => _pcDragging = false),
      onDragDone: (details) async {
        setState(() => _pcDragging = false);
        final selection = await itemsFromDrop(details.files, maxBytes: adminDriveMaxBytes);
        if (mounted) await _dropFromPc(selection);
      },
      child: Stack(children: [
        Positioned.fill(child: child),
        if (_pcDragging)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: p.adminIndigo.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: p.adminIndigo.withValues(alpha: 0.7), width: 2),
                ),
                child: Center(child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Rilascia per aggiungere alla struttura di «${_string(_currentSubject?['name'])}»\n'
                      'cartelle e sottocartelle vengono conservate',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: p.adminIndigo, fontWeight: FontWeight.w700)),
                )),
              ),
            ),
          ),
      ]),
    );
  }

  Future<void> _toggleDriveFolder(String id) async {
    if (_driveOpen.contains(id)) {
      setState(() => _driveOpen.remove(id));
      return;
    }
    setState(() => _driveOpen.add(id));
    if (_driveChildren.containsKey(id) || _driveLoading.contains(id)) return;
    final source = _source;
    final generation = _sourceGeneration;
    setState(() => _driveLoading.add(id));
    try {
      final children = await _folderChildren(source, id);
      if (!mounted || generation != _sourceGeneration) return;
      setState(() => _driveChildren[id] = children);
    } catch (error) {
      if (!mounted || generation != _sourceGeneration) return;
      _showError(_reason(error, 'Impossibile aprire questa cartella ${source.shortLabel}.'));
      setState(() => _driveOpen.remove(id));
    } finally {
      if (mounted && generation == _sourceGeneration) setState(() => _driveLoading.remove(id));
    }
  }

  /// Righe dell'albero Drive, con le cartelle aperte espanse sul posto.
  List<Widget> _driveTreeRows(List<Map<String, dynamic>> items, int depth, String query, Set<String> draftImports) {
    final p = context.palette;
    final source = _source;
    final rows = <Widget>[];
    for (final file in items) {
      final String id = _string(file['id']);
      final bool isFolder = _isFolder(file);
      final bool matches = query.isEmpty || _string(file['name']).toLowerCase().contains(query);
      if (isFolder) {
        final bool open = _driveOpen.contains(id);
        final children = _driveChildren[id] ?? const <Map<String, dynamic>>[];
        final childRows = open ? _driveTreeRows(children, depth + 1, query, draftImports) : const <Widget>[];
        if (!matches && childRows.isEmpty && query.isNotEmpty) continue;
        final folderRow = _driveRow(
          depth: depth,
          icon: open ? Icons.folder_open_outlined : Icons.folder_outlined,
          iconColor: p.skyBlue,
          leadingChevron: open ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
          title: _string(file['name']),
          subtitle: file['modified_at'] == null ? null : 'Modificata ${_date(file['modified_at'])}',
          onTap: () => _toggleDriveFolder(id),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            if (source == CatalogSource.mega) _megaCheck(file),
            if (source == CatalogSource.mega) IconButton(tooltip: 'Copia cartella su Drive', onPressed: _busy ? null : () => _copyMegaToDrive(file), icon: const Icon(Icons.drive_file_move_outline, size: 20)),
            if (_driveLoading.contains(id))
              SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: p.skyBlue)),
            IconButton(tooltip: 'Aggiungi cartella e file alla struttura',
              onPressed: _busy ? null : () => _importFolder({...file, 'storage_provider': source.apiValue}),
              icon: Icon(Icons.add_circle_outline_rounded, color: p.skyBlue, size: 20)),
          ]),
        );
        rows.add(Draggable<_DragPayload>(
          data: _DragPayload.drive({...file, 'storage_provider': source.apiValue}),
          feedback: _dragGhost(_string(file['name']), 'CARTELLA'),
          childWhenDragging: Opacity(opacity: 0.4, child: folderRow),
          child: folderRow,
        ));
        rows.addAll(childRows);
        if (open && children.isEmpty && !_driveLoading.contains(id)) {
          rows.add(Padding(
            padding: EdgeInsets.only(
                left: (30.0 + 16 * (depth + 1)).clamp(30.0, MediaQuery.sizeOf(context).width * 0.25).toDouble(),
                bottom: 6),
            child: Text('Cartella vuota', style: SlText.muted(p).copyWith(fontSize: 11)),
          ));
        }
        continue;
      }
      if (!matches) continue;
      final bool indexed = file['indexed'] == true;
      final bool drafted = draftImports.contains(id);
      final row = _driveRow(
        depth: depth,
        icon: Icons.insert_drive_file_outlined,
        iconColor: indexed ? p.diamondDust : p.pureWhite.withValues(alpha: 0.72),
        title: _string(file['name']),
        subtitle: <String>[
          _bytes(file['size']),
          if (file['modified_at'] != null) _date(file['modified_at']),
          if (_string(file['last_modified_by']).isNotEmpty) _string(file['last_modified_by']),
        ].join(' · '),
        dot: indexed ? _DriveDot.catalog : (drafted ? _DriveDot.draft : _DriveDot.driveOnly),
        onTap: () => showDriveFilePreview(context,
            load: () => downloadSourcePreview(_api, _mega, source, id),
            name: _string(file['name']),
            mimeType: _string(file['mime_type'])),
        trailing: source == CatalogSource.mega ? Row(mainAxisSize: MainAxisSize.min, children: [_megaCheck(file), PopupMenuButton<String>(enabled: !_busy,
          tooltip: 'Azioni MEGA', onSelected: (action) {
            if (action == 'copy') _copyMegaToDrive(file);
            if (action == 'download') _downloadMega(file);
            if (action == 'import') _import({...file, 'storage_provider': 'mega'});
          }, itemBuilder: (_) => [
            const PopupMenuItem(value: 'copy', child: Text('Copia su Drive')),
            const PopupMenuItem(value: 'download', child: Text('Scarica sul dispositivo (max 20 MB)')),
            if (!indexed && !drafted) const PopupMenuItem(value: 'import', child: Text('Prepara per le Dispense')),
          ])]) : !indexed && !drafted
            ? IconButton(
                tooltip: 'Aggiungi alla struttura per gli studenti',
                onPressed: _busy ? null : () => _import(file),
                icon: Icon(Icons.add_circle_outline_rounded, color: p.skyBlue, size: 20),
              )
            : indexed
                ? IconButton(
                    tooltip: 'Mostra nella struttura',
                    onPressed: () => _revealInStructure(id),
                    icon: Icon(Icons.my_location_rounded, color: p.adminGreen, size: 19),
                  )
                : null,
      );
      // I file solo su Drive si possono trascinare in una cartella della struttura.
      rows.add(!indexed && !drafted
          ? Draggable<_DragPayload>(
              data: _DragPayload.drive({...file, 'storage_provider': source.apiValue}),
              feedback: _dragGhost(_string(file['name']), 'DA ${source.shortLabel.toUpperCase()}'),
              childWhenDragging: Opacity(opacity: 0.4, child: row),
              child: row,
            )
          : row);
    }
    return rows;
  }

  Widget _drivePane() {
    final p = context.palette;
    final query = _search.text.trim().toLowerCase();
    final draftImports = _imports.where((e) => (sourceOfMaterial(e) ?? CatalogSource.drive) == _source)
        .map(_providerId).toSet();
    final rows = _driveTreeRows(_drive, 0, query, draftImports);
    return _column(
      header: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (_sourceLoading) const LinearProgressIndicator(minHeight: 2),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
          child: Wrap(alignment: WrapAlignment.end, spacing: 4, runSpacing: 4, children: [
            TextButton.icon(onPressed: _busy ? null : () => _openUpload(),
              icon: const Icon(Icons.drive_folder_upload_outlined, size: 18),
              label: Text('Carica qui su ${_source.shortLabel}')),
            TextButton.icon(onPressed: _openMegaJobs, icon: const Icon(Icons.sync, size: 18), label: const Text('Copie MEGA → Drive')),
          ]),
        ),
        if (_source == CatalogSource.mega && _megaSelected.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: Row(children: [
              Expanded(child: Text('${_megaSelected.length} selezionati', style: SlText.muted(p))),
              TextButton(onPressed: _busy ? null : () => setState(_megaSelected.clear), child: const Text('Deseleziona')),
              FilledButton.icon(onPressed: _busy ? null : _copyMegaSelected,
                icon: const Icon(Icons.drive_file_move_outline, size: 18), label: const Text('Copia su Drive…')),
            ]),
          ),
        _columnHeader(
          icon: Icons.cloud_outlined,
          tone: SlTone.info,
          title: _source.label,
          subtitle: 'Struttura reale · ${_source.shortLabel}',
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
              hintText: 'Cerca nelle cartelle aperte',
              fillColor: p.darkElegance,
            ),
          ),
        ),
      ]),
      body: _osDropArea((_sourceMissing || (_sourceError != null && _drive.isEmpty))
          ? _sourceUnavailable(_source)
          : ListView(padding: const EdgeInsets.all(8), children: [
        _driveRow(
          depth: 0,
          icon: Icons.folder_open_outlined,
          iconColor: p.skyBlue,
          title: _trail.last.$2,
          subtitle: _trail.length > 1 ? 'Tocca per risalire' : 'Cartella principale di StudentLab',
          bold: true,
          onTap: _trail.length > 1
              ? () {
                  _trail.removeLast();
                  _driveOpen.clear();
                  _loadDrive();
                }
              : () {},
          leadingChevron: _trail.length > 1 ? Icons.arrow_upward_rounded : Icons.keyboard_arrow_down_rounded,
        ),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(query.isEmpty ? 'Cartella vuota.' : 'Nessun file corrisponde alla ricerca.',
                style: SlText.muted(p)),
          ),
        ...rows,
        if (_nextPage != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: SlActionButton(
              icon: Icons.expand_more_rounded,
              label: 'Carica altri file',
              onPressed: _busy ? null : _more,
            ),
          ),
      ])),
      footer: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _legend(_DriveDot.catalog, 'Nel catalogo e visibile agli studenti'),
          const SizedBox(height: 5),
          _legend(_DriveDot.draft, 'Aggiunto alla bozza, non ancora pubblicato'),
          const SizedBox(height: 5),
          _legend(_DriveDot.driveOnly, 'Solo su ${_source.shortLabel} · trascina nella struttura o usa +'),
          if (_source == CatalogSource.mega && _megaStatus != null) ...[
            const SizedBox(height: 10),
            SourceUsageBar(label: 'Traffico di download',
              used: SourceUsageBar.toInt(_megaStatus!['transfer_used_bytes']),
              limit: SourceUsageBar.toInt(_megaStatus!['transfer_limit_bytes']), color: p.adminAmber),
          ],
        ]),
      ),
    );
  }

  /// v26: rilascio di file e cartelle dal computer sopra il pannello della sorgente.
  Widget _osDropArea(Widget child) {
    final p = context.palette;
    return DropTarget(
      enable: !_busy && !_previewMode,
      onDragEntered: (_) => setState(() => _osDragging = true),
      onDragExited: (_) => setState(() => _osDragging = false),
      onDragDone: (details) async {
        setState(() => _osDragging = false);
        final selection = await itemsFromDrop(details.files, maxBytes: adminDriveMaxBytes);
        if (!mounted) return;
        if (selection.items.isEmpty) {
          _showError(selection.note ?? 'Nessun file da caricare.');
          return;
        }
        await _openUpload(selection: selection);
      },
      child: Stack(children: [
        Positioned.fill(child: child),
        if (_osDragging)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: p.adminCyan.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: p.adminCyan.withValues(alpha: 0.7), width: 2),
                ),
                child: Center(child: Text('Rilascia per caricare su ${_source.shortLabel}',
                  style: TextStyle(color: p.adminCyan, fontWeight: FontWeight.w700))),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _megaCheck(Map<String, dynamic> file) {
    final id = _string(file['id']);
    return Checkbox(
      value: _megaSelected.containsKey(id),
      visualDensity: VisualDensity.compact,
      onChanged: _busy ? null : (value) => setState(() {
        if (value == true) {
          _megaSelected[id] = file;
        } else {
          _megaSelected.remove(id);
        }
      }),
    );
  }

  Widget _sourceUnavailable(CatalogSource source) {
    final palette = context.palette;
    return Center(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(
      mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.cloud_off_outlined, size: 36, color: source.color(context)),
        const SizedBox(height: 10),
        Text(_sourceMissing ? '${source.label} non è collegato' : 'Sorgente non raggiungibile',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(_sourceError ?? '', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, color: palette.pureWhite.withValues(alpha: 0.66))),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
          OutlinedButton.icon(onPressed: _sourceLoading ? null : _loadDrive,
            icon: const Icon(Icons.refresh, size: 18), label: const Text('Riprova')),
          FilledButton.icon(onPressed: _openSources,
            icon: const Icon(Icons.settings_input_component_outlined, size: 18), label: const Text('Sorgenti')),
          if (source == CatalogSource.drive)
            TextButton.icon(onPressed: () => showDriveDiagnostics(context, _api),
              icon: const Icon(Icons.health_and_safety_outlined, size: 18), label: const Text('Verifica collegamento')),
        ]),
      ])));
  }

  Future<void> _openSources() async {
    final chosen = await Navigator.of(context).push<CatalogSource>(MaterialPageRoute<CatalogSource>(
      builder: (_) => const AdminStorageSourcesPage(returnSource: true)));
    if (!mounted) return;
    if (chosen != null && chosen != _source) {
      _switchSource(chosen);
    } else {
      await _loadDrive();
    }
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
    IconData? leadingChevron,
    Widget? trailing,
    bool bold = false,
    int depth = 0,
    required VoidCallback onTap,
  }) {
    final p = context.palette;
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              (6.0 + 16 * depth).clamp(6.0, MediaQuery.sizeOf(context).width * 0.25).toDouble(),
              5, 6, 5),
          child: Row(children: [
            SizedBox(
              width: 18,
              child: leadingChevron == null
                  ? null
                  : Icon(leadingChevron, size: 16, color: p.pureWhite.withValues(alpha: 0.56)),
            ),
            const SizedBox(width: 4),
            Icon(icon, size: 17, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: p.pureWhite, fontSize: 13, fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
                if (subtitle != null && subtitle.isNotEmpty)
                  Text(subtitle, style: SlText.mono(p, size: 10, color: p.pureWhite.withValues(alpha: 0.56))),
              ]),
            ),
            if (dot != null) ...[const SizedBox(width: 6), _dot(dot)],
            if (trailing != null) trailing,
          ]),
        ),
      ),
    );
  }

  /// Anteprima che segue il puntatore durante il trascinamento.
  Widget _dragGhost(String title, String tag) {
    final p = context.palette;
    return Material(
      color: Colors.transparent,
      child: Transform.rotate(
        angle: -0.025,
        child: Container(
          width: 280,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: p.brandNightBlue,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: p.adminCyan.withValues(alpha: 0.55)),
          ),
          child: Row(children: [
            Icon(Icons.insert_drive_file_outlined, size: 16, color: p.adminCyan),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.pureWhite, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            Text(tag, style: SlText.mono(p, size: 10, color: p.adminCyan)),
          ]),
        ),
      ),
    );
  }

  /// Rilascio su una cartella della struttura (o sulla materia, path vuoto).
  Future<void> _dropInto(_DragPayload payload, List<String> path) async {
    setState(() => _dropTarget = null);
    if (payload.material != null) {
      final current = _path(_effective(payload.material!)['path_segments']);
      if (current.join('\u0000') == path.join('\u0000')) return;
      await _stageChange(payload.material!, path: path);
    } else if (payload.driveFile != null) {
      if (_isFolder(payload.driveFile!)) {
        await _importFolder(payload.driveFile!, initialPath: path);
      } else {
        await _import(payload.driveFile!, initialPath: path);
      }
    }
  }

  Widget _dropZone({required List<String> path, required Widget child}) {
    final p = context.palette;
    final key = path.join('\u0000');
    return DragTarget<_DragPayload>(
      onWillAcceptWithDetails: (_) {
        if (_dropTarget != key) setState(() => _dropTarget = key);
        return !_busy;
      },
      onLeave: (_) {
        if (_dropTarget == key) setState(() => _dropTarget = null);
      },
      onAcceptWithDetails: (details) => _dropInto(details.data, path),
      builder: (context, candidates, _) {
        final bool active = candidates.isNotEmpty;
        return Container(
          decoration: BoxDecoration(
            color: active ? p.adminCyan.withValues(alpha: 0.06) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? p.adminCyan.withValues(alpha: 0.55) : Colors.transparent,
            ),
          ),
          child: Stack(children: [
            child,
            if (active)
              Positioned(
                right: 44,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Text('Rilascia qui',
                      style: TextStyle(color: p.adminCyan, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
          ]),
        );
      },
    );
  }

  Widget _catalogPane() {
    final p = context.palette;
    final subset = _materials
        .where((m) => _integer(_effective(m)['subject_id']) == _subjectId && _string(m['status']) != 'removed')
        .map(_effective)
        .toList();
    final folderRows = _folders.where((f) => _integer(f['subject_id']) == _subjectId).toList();
    final importRows = _imports.where((f) => _integer(f['subject_id']) == _subjectId).toList();
    final removedRows = _materials
        .where((m) => _integer(m['subject_id']) == _subjectId && _string(m['status']) == 'removed')
        .toList();
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
              icon: Icons.upload_file_rounded,
              label: 'Carica file',
              primary: true,
              onPressed: _busy ? null : _chooseUpload,
            ),
            const SizedBox(width: 8),
            SlActionButton(
              icon: Icons.create_new_folder_outlined,
              label: 'Nuova cartella',
              onPressed: _busy || _subjectId == null ? null : _addFolder,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
          child: LayoutBuilder(builder: (context, bounds) {
            final hint = Text('Trascina un file su una cartella per spostarlo, o usa + per aggiungerlo dalla sorgente.',
                style: SlText.muted(p).copyWith(fontSize: 11));
            final toggle = Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Mostra nascosti', style: SlText.muted(p)),
              Switch(value: _showHidden, onChanged: (value) => setState(() => _showHidden = value)),
            ]);
            return bounds.maxWidth < 450
                ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [hint, toggle])
                : Row(children: [Expanded(child: hint), toggle]);
          }),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          // v26: Ateneo → Dipartimento → Corso → Livello → Anno → Materia (si apre e si chiude).
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() => _filtersOpen = !_filtersOpen),
              child: Container(
                constraints: const BoxConstraints(minHeight: 40),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: p.darkElegance,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: p.pureWhite.withValues(alpha: 0.12)),
                ),
                child: Row(children: [
                  Text('Materia', style: SlText.muted(p)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(subjectSummary(subject), maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: p.pureWhite, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                  Text(_filtersOpen ? 'Chiudi filtri' : 'Filtra', style: SlText.muted(p)),
                  Icon(_filtersOpen ? Icons.keyboard_arrow_up_rounded : Icons.filter_list_rounded, size: 18),
                ]),
              ),
            ),
            if (_filtersOpen) ...[
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.4),
                child: SingleChildScrollView(
                  child: SubjectHierarchyFilter(
                    subjects: _subjects,
                    subjectId: _subjectId,
                    onChanged: (value) => setState(() {
                      _subjectId = value;
                      _selectedId = null;
                    }),
                  ),
                ),
              ),
            ],
          ]),
        ),
      ]),
      body: _pcDropArea(subset.isEmpty && folderRows.isEmpty && importRows.isEmpty && removedRows.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: SlEmptyState(
                icon: Icons.folder_open_outlined,
                title: 'Nessun materiale in questa materia',
                message: 'Aggiungi file dalla sorgente con il pulsante +, trascina qui file e cartelle dal computer oppure crea una cartella.',
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
                _dropZone(path: const <String>[], child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
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
                )),
              ..._structureTree(subset, folderRows, importRows),
              if (removedRows.isNotEmpty) ...[
                const SizedBox(height: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => _showRemoved = !_showRemoved),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
                    child: Row(children: [
                      Icon(_showRemoved ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                          size: 18, color: p.pureWhite.withValues(alpha: 0.6)),
                      const SizedBox(width: 6),
                      Expanded(child: Text('Tolti dalla struttura (${removedRows.length})',
                          style: SlText.muted(p).copyWith(fontWeight: FontWeight.w600))),
                    ]),
                  ),
                ),
                if (_showRemoved)
                  for (final m in removedRows)
                    _simpleRow(
                      icon: Icons.remove_circle_outline_rounded,
                      title: _string(m['title']),
                      subtitle: [
                        _path(m['path_segments']).join(' / '),
                        _providerId(m).isNotEmpty || _string(m['stored_name']).startsWith('drive-import/')
                            ? 'ancora su ${(sourceOfMaterial(m) ?? CatalogSource.drive).shortLabel}'
                            : 'non è su Drive',
                      ].where((x) => x.isNotEmpty).join(' · '),
                      badge: const SlStatusBadge(label: 'Tolto'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(tooltip: 'Ripristina nella struttura',
                          onPressed: _busy ? null : () => _restore(m),
                          icon: const Icon(Icons.restore_rounded, size: 18)),
                        if (_providerId(m).isNotEmpty)
                          IconButton(tooltip: 'Elimina da Drive',
                            onPressed: _busy ? null : () => _deleteFromDrive([m], label: _string(m['title'])),
                            icon: Icon(Icons.delete_forever_outlined, size: 18, color: p.adminCoral)),
                      ]),
                    ),
              ],
            ])),
      footer: _draftCount == 0 ? null : _changeLog(),
    );
  }

  /// v27: albero completo della materia. Cartelle (anche intermedie e vuote), file pubblicati
  /// e file nuovi in bozza stanno al loro posto, con le sottocartelle una dentro l'altra.
  List<Widget> _structureTree(List<Map<String, dynamic>> subset, List<Map<String, dynamic>> folderRows,
      List<Map<String, dynamic>> importRows) {
    const sep = '\u0000';
    final shown = subset.where((m) => _showHidden || _string(m['visibility_state']) == 'visible').toList();
    final folders = <String>{};
    void addPath(List<String> path) {
      for (var i = 1; i <= path.length; i++) {
        folders.add(path.take(i).join(sep));
      }
    }
    for (final m in shown) {
      addPath(_path(m['path_segments']));
    }
    for (final f in folderRows) {
      addPath(_path(f['path_segments']));
    }
    for (final i in importRows) {
      addPath(_path(i['path_segments']));
    }
    bool inside(List<String> path, List<String> folder) =>
        path.length >= folder.length && path.take(folder.length).join(sep) == folder.join(sep);
    final rows = <Widget>[];
    void visit(List<String> folder) {
      final depth = folder.length;
      final key = folder.join(sep);
      final children = folders
          .map((k) => k.split(sep))
          .where((parts) => parts.length == depth + 1 && inside(parts, folder))
          .toList()
        ..sort((a, b) => a.last.toLowerCase().compareTo(b.last.toLowerCase()));
      for (final child in children) {
        final childKey = child.join(sep);
        rows.add(_folderRow(
          child,
          files: subset.where((m) => inside(_path(m['path_segments']), child)).toList(),
          imports: importRows.where((i) => inside(_path(i['path_segments']), child)).toList(),
          catalogFolder: folderRows.where((f) => _path(f['path_segments']).join(sep) == childKey)
              .fold<Map<String, dynamic>?>(null, (found, f) => found ?? f),
          subset: subset,
        ));
        if (!_collapsed.contains(childKey)) visit(child);
      }
      for (final m in shown.where((m) => _path(m['path_segments']).join(sep) == key)) {
        rows.add(_fileRow(m, indent: depth + 1));
      }
      for (final i in importRows.where((i) => _path(i['path_segments']).join(sep) == key)) {
        rows.add(_importRow(i, depth + 1));
      }
    }
    visit(const <String>[]);
    return rows;
  }

  /// File aggiunto in bozza (non ancora pubblicato), al suo posto nell'albero.
  Widget _importRow(Map<String, dynamic> file, int indent) => _simpleRow(
        indent: indent,
        icon: Icons.insert_drive_file_outlined,
        title: _string(file['name']),
        subtitle: '${_bytes(file['size'])} · da ${(sourceOfMaterial(file) ?? CatalogSource.drive).shortLabel}',
        badge: const SlStatusBadge(label: 'Nuovo', tone: SlTone.warning),
        trailing: IconButton(tooltip: 'Togli dalla bozza (il file resta sulla sorgente)',
          onPressed: _busy ? null : () => _undoDraftItem('import', _integer(file['id'])),
          icon: const Icon(Icons.undo_rounded, size: 18)),
        onTap: () => showDriveFilePreview(context,
            load: () => downloadSourcePreview(_api, _mega, sourceOfMaterial(file) ?? CatalogSource.drive, _providerId(file)),
            name: _string(file['name']),
            mimeType: _string(file['mime_type'])),
      );

  Widget _folderRow(List<String> parts, {
    required List<Map<String, dynamic>> files,
    required List<Map<String, dynamic>> imports,
    required Map<String, dynamic>? catalogFolder,
    required List<Map<String, dynamic>> subset,
  }) {
    final p = context.palette;
    final key = parts.join(' / ');
    final collapseKey = parts.join('\u0000');
    final collapsed = _collapsed.contains(collapseKey);
    final hidden = files.where((f) => _string(f['visibility_state']) != 'visible').length;
    final allHidden = files.isNotEmpty && hidden == files.length;
    final drafted = files.any((f) => f['draft'] == true) || imports.isNotEmpty || catalogFolder?['draft'] == true;
    final onDrive = files.where((f) => _materials.any((m) => _integer(m['id']) == _integer(f['id']) &&
        (_providerId(m).isNotEmpty || _string(m['stored_name']).startsWith('drive-import/')))).toList();
    final String count = [
      if (files.isNotEmpty) '${files.length} file',
      if (imports.isNotEmpty) '${imports.length} nuovi',
      if (files.isEmpty && imports.isEmpty) 'vuota',
    ].join(' · ');
    return Padding(
      padding: EdgeInsets.only(left: 14.0 * (parts.length - 1), top: 2, bottom: 2),
      child: _dropZone(
        path: parts,
        child: Opacity(
          opacity: allHidden ? 0.62 : 1,
          child: SizedBox(
            height: 44,
            child: Row(children: [
              IconButton(
                tooltip: collapsed ? 'Apri la cartella' : 'Chiudi la cartella',
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => collapsed ? _collapsed.remove(collapseKey) : _collapsed.add(collapseKey)),
                icon: Icon(collapsed ? Icons.keyboard_arrow_right_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 18, color: p.pureWhite.withValues(alpha: 0.6)),
              ),
              Icon(allHidden ? Icons.folder_off_outlined : Icons.folder_outlined,
                  size: 18, color: allHidden ? p.pureWhite.withValues(alpha: 0.7) : p.skyBlue),
              const SizedBox(width: 8),
              Flexible(
                child: Text(parts.last,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: p.pureWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: allHidden ? TextDecoration.lineThrough : null,
                      decorationColor: p.pureWhite.withValues(alpha: 0.4),
                    )),
              ),
              const SizedBox(width: 8),
              Text(count, style: SlText.mono(p, size: 10, color: p.pureWhite.withValues(alpha: 0.5))),
              if (hidden > 0 && !allHidden) ...[const SizedBox(width: 6), SlStatusBadge(label: '$hidden nascosti')],
              if (drafted) ...[const SizedBox(width: 6), const SlStatusBadge(label: 'In bozza', tone: SlTone.warning)],
              const Spacer(),
              if (files.isNotEmpty)
                IconButton(
                  tooltip: allHidden ? 'Mostra la cartella agli studenti' : 'Nascondi la cartella agli studenti',
                  onPressed: _busy ? null : () => _setFolderVisibility(key, subset, allHidden),
                  icon: Icon(allHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 18, color: p.pureWhite.withValues(alpha: 0.72)),
                ),
              PopupMenuButton<String>(
                tooltip: 'Azioni sulla cartella',
                enabled: !_busy,
                icon: Icon(Icons.more_horiz_rounded, color: p.pureWhite.withValues(alpha: 0.66)),
                onSelected: (action) {
                  if (action == 'edit') _editFolder(key, subset);
                  if (action == 'flatten') _flattenFolder(parts);
                  if (action == 'undoFolder') _undoDraftItem('folder', _integer(catalogFolder!['id']));
                  if (action == 'remove') {
                    _removeFromStructure(
                        materialIds: [for (final f in files) _integer(f['id'])],
                        folder: parts, label: parts.last, count: files.length + imports.length);
                  }
                  if (action == 'delete') {
                    _deleteFromDrive([
                      for (final f in onDrive) ..._materials.where((m) => _integer(m['id']) == _integer(f['id'])),
                    ], label: parts.last);
                  }
                },
                itemBuilder: (_) => [
                  if (files.isNotEmpty)
                    const PopupMenuItem(value: 'edit', child: Text('Rinomina, sposta, mostra o nascondi')),
                  if (files.isNotEmpty || imports.isNotEmpty)
                    const PopupMenuItem(value: 'flatten', child: Text('Porta il contenuto su di un livello')),
                  if (catalogFolder?['draft'] == true)
                    const PopupMenuItem(value: 'undoFolder', child: Text('Annulla questa cartella (in bozza)')),
                  const PopupMenuItem(value: 'remove', child: Text('Togli dalla struttura (resta su Drive)')),
                  if (onDrive.isNotEmpty)
                    const PopupMenuItem(value: 'delete', child: Text('Elimina i file da Drive…')),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }

  /// Nasconde o mostra tutti i file di una cartella (in bozza).
  Future<void> _setFolderVisibility(String key, List<Map<String, dynamic>> subset, bool visible) async {
    final prefix = key.split(' / ');
    setState(() => _busy = true);
    try {
      for (final row in subset) {
        final path = _path(row['path_segments']);
        if (path.length < prefix.length || path.take(prefix.length).join('/') != prefix.join('/')) continue;
        final original = _materials.where((m) => _integer(m['id']) == _integer(row['id']));
        if (original.isEmpty) continue;
        await _api.stageCatalogFile(
          materialId: _integer(row['id']),
          subjectId: _integer(row['subject_id']),
          pathSegments: path,
          visibilityState: visible ? 'visible' : 'hidden',
          audienceType: _string(row['audience_type']).isEmpty ? 'public' : _string(row['audience_type']),
          audienceId: row['audience_id'] == null ? null : _integer(row['audience_id']),
        );
      }
      await _reload();
    } catch (e) {
      _showError(_reason(e, 'Non tutti i file della cartella sono stati aggiornati. Controlla la bozza.'));
      await _reload();
    }
    if (mounted) setState(() => _busy = false);
  }

  /// Cosa cambia per questo file rispetto al catalogo pubblicato.
  List<(String, SlTone)> _changeBadges(Map<String, dynamic> effective) {
    if (effective['draft'] != true) return const [];
    final original = _materials.where((m) => _integer(m['id']) == _integer(effective['id']));
    if (original.isEmpty) return const [('Bozza', SlTone.warning)];
    final before = original.first;
    final badges = <(String, SlTone)>[];
    if (_path(before['path_segments']).join('/') != _path(effective['path_segments']).join('/') ||
        _integer(before['subject_id']) != _integer(effective['subject_id'])) {
      badges.add(('Spostato', SlTone.warning));
    }
    if (_string(before['visibility_state']) != _string(effective['visibility_state'])) {
      badges.add((_string(effective['visibility_state']) == 'visible' ? 'Da mostrare' : 'Da nascondere', SlTone.warning));
    }
    if (_string(before['audience_type']) != _string(effective['audience_type'])) {
      badges.add(('Destinatari', SlTone.warning));
    }
    return badges.isEmpty ? const [('Bozza', SlTone.warning)] : badges;
  }

  Widget _fileRow(Map<String, dynamic> material, {required int indent}) {
    final p = context.palette;
    final id = _integer(material['id']);
    final bool selected = id == _selectedId;
    final state = _string(material['visibility_state']);
    final (visLabel, visTone) = _visibilityBadge(state);
    final (audLabel, audTone) = _audienceBadge(_string(material['audience_type']));
    final bool hidden = state != 'visible';
    final drivePath = _providerPath(material);
    final original = _materials.where((m) => _integer(m['id']) == id);
    final row = Padding(
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
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Row(children: [
              Icon(Icons.drag_indicator_rounded, size: 16, color: p.pureWhite.withValues(alpha: 0.40)),
              const SizedBox(width: 4),
              SlFileTile(kind: slFileKind(_string(material['mime_type']), _string(material['original_name'])), size: 32),
              if (sourceOfMaterial(material) != null) ...[
                const SizedBox(width: 5),
                CatalogSourceBadge(source: sourceOfMaterial(material)!, size: 18),
              ],
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
                    if (drivePath.isNotEmpty)
                      Text('↳ su ${(sourceOfMaterial(material) ?? CatalogSource.drive).shortLabel}: ${drivePath.join(' / ')}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SlText.mono(p, size: 10, color: p.pureWhite.withValues(alpha: 0.50))),
                    const SizedBox(height: 4),
                    Wrap(spacing: 5, runSpacing: 4, children: [
                      SlStatusBadge(label: visLabel, tone: visTone),
                      SlStatusBadge(label: audLabel, tone: audTone),
                      for (final (label, tone) in _changeBadges(material)) SlStatusBadge(label: label, tone: tone),
                    ]),
                  ]),
                ),
              ),
              IconButton(
                tooltip: hidden ? 'Mostra agli studenti' : 'Nascondi agli studenti',
                onPressed: _busy || original.isEmpty
                    ? null
                    : () => _stageChange(original.first, visibility: hidden ? 'visible' : 'hidden'),
                icon: Icon(hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 18, color: p.pureWhite.withValues(alpha: 0.72)),
              ),
              if (original.isNotEmpty)
                PopupMenuButton<String>(
                  tooltip: 'Altre azioni',
                  enabled: !_busy,
                  icon: Icon(Icons.more_vert_rounded, size: 18, color: p.pureWhite.withValues(alpha: 0.66)),
                  onSelected: (action) {
                    if (action == 'undo') _undoDraftItem('material', id);
                    if (action == 'remove') {
                      _removeFromStructure(materialIds: [id], label: _string(material['title']));
                    }
                    if (action == 'delete') _deleteFromDrive([original.first], label: _string(material['title']));
                  },
                  itemBuilder: (_) => [
                    if (material['draft'] == true)
                      const PopupMenuItem(value: 'undo', child: Text('Annulla le modifiche in bozza')),
                    const PopupMenuItem(value: 'remove', child: Text('Togli dalla struttura (resta su Drive)')),
                    if (_providerId(original.first).isNotEmpty)
                      const PopupMenuItem(value: 'delete', child: Text('Elimina da Drive…')),
                  ],
                ),
            ]),
          ),
        ),
      ),
    );
    if (original.isEmpty) return row;
    return Draggable<_DragPayload>(
      data: _DragPayload.material(original.first),
      feedback: _dragGhost(_string(material['title']), 'SPOSTA'),
      childWhenDragging: Opacity(opacity: 0.4, child: row),
      child: row,
    );
  }

  Widget _simpleRow({required IconData icon, required String title, String? subtitle,
      required Widget badge, VoidCallback? onTap, Widget? trailing, int indent = 0}) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: EdgeInsets.fromLTRB(indent > 0 ? 14.0 * indent + 8 : 22, 8, 8, 8),
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
          if (trailing != null) trailing,
        ]),
      ),
    );
  }

  /// Registro della bozza: cosa cambierà alla pubblicazione.
  /// v26: ogni riga si annulla da sola con ↺ (kind, id della voce di bozza).
  Widget _changeLog() {
    final p = context.palette;
    final lines = <(String, String, String, int)>[];
    for (final d in _draft) {
      final id = _integer(d['material_id']);
      final matches = _materials.where((m) => _integer(m['id']) == id);
      final before = matches.isEmpty ? null : matches.first;
      final name = before == null ? 'File in bozza' : _string(before['title']);
      final pathBefore = before == null ? '' : _path(before['path_segments']).join(' / ');
      final pathAfter = _path(d['path_segments']).join(' / ');
      final changes = <(String, String)>[];
      if (before != null && pathBefore != pathAfter) {
        changes.add(('SPOSTA', '“$name” → ${pathAfter.isEmpty ? 'materia' : pathAfter}'));
      }
      if (before != null && _string(before['visibility_state']) != _string(d['visibility_state'])) {
        changes.add((_string(d['visibility_state']) == 'visible' ? 'MOSTRA' : 'NASCONDI', '“$name”'));
      }
      if (before != null && _string(before['audience_type']) != _string(d['audience_type'])) {
        changes.add(('DESTINATARI', '“$name”: ${_audienceLabel(_string(d['audience_type']))}'));
      }
      if (before != null && _integer(before['subject_id']) != _integer(d['subject_id'])) {
        changes.add(('MATERIA', '“$name” cambia materia'));
      }
      if (changes.isEmpty) changes.add(('MODIFICA', '“$name”'));
      for (final (kind, text) in changes) {
        lines.add((kind, text, 'material', id));
      }
    }
    for (final i in _imports) {
      lines.add(('AGGIUNGI', '“${_string(i['name'])}” in ${_path(i['path_segments']).join(' / ').isEmpty ? 'materia' : _path(i['path_segments']).join(' / ')}',
          'import', _integer(i['id'])));
    }
    for (final f in _folders.where((f) => f['draft'] == true)) {
      lines.add(('CARTELLA', _path(f['path_segments']).join(' / '), 'folder', _integer(f['id'])));
    }
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      color: p.eleganceSoftNight,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 12),
        children: [
          Text('BOZZA · $_draftCount MODIFICHE',
              style: SlText.mono(p, size: 11, color: p.pureWhite.withValues(alpha: 0.56))),
          const SizedBox(height: 6),
          for (final (kind, text, draftKind, id) in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                SizedBox(width: 92, child: Text(kind, style: SlText.mono(p, size: 11, color: p.adminAmber))),
                Expanded(child: Text(text, style: SlText.body(p).copyWith(fontSize: 12))),
                IconButton(
                  tooltip: 'Annulla questa modifica',
                  visualDensity: VisualDensity.compact,
                  onPressed: _busy || id <= 0 ? null : () => _undoDraftItem(draftKind, id),
                  icon: Icon(Icons.undo_rounded, size: 16, color: p.pureWhite.withValues(alpha: 0.7)),
                ),
              ]),
            ),
          Text('↺ annulla una sola modifica; «Scarta bozza» le annulla tutte.',
              style: SlText.muted(p).copyWith(fontSize: 11)),
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
    final drivePath = _providerPath(row);
    final provider = sourceOfMaterial(row);
    final catalogPath = _path(row['path_segments']);
    final driveId = _providerId(row).isNotEmpty
        ? _providerId(row)
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
                if (provider != null) CatalogSourceBadge(source: provider, size: 18),
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
          if (driveId.isNotEmpty && provider == CatalogSource.drive)
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
                : (driveId.isNotEmpty ? 'Importato da ${provider?.label ?? 'StudentLab'}' : '—'),
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
          // v26: niente ID o impronte nell'interfaccia (restano nel registro diagnostico).
          SlKeyValue(label: 'Tipo', value: _fileKindLabel(_string(row['original_name']))),
          SlKeyValue(label: 'Dimensione', value: _bytes(row['size']), mono: true),
          SlKeyValue(label: 'Si trova', value: driveId.isNotEmpty ? 'Su ${provider?.label ?? 'Drive'}' : 'Su StudentLab'),
        ]),
        section('Posizione', [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: p.eleganceMidnight, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Su ${provider?.label ?? 'StudentLab'} · invariata', style: SlText.muted(p).copyWith(fontSize: 11)),
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
          SlKeyValue(
            label: 'Offline',
            value: state == 'visible'
                ? 'Sì, per chi può vederlo'
                : 'No: non arriva nelle Dispense finché è ${visLabel.toLowerCase()}',
          ),
          const SizedBox(height: 6),
          SlActionButton(
            icon: Icons.tune_rounded,
            label: 'Materia, destinatari e stato',
            onPressed: _busy ? null : () => _stage(original),
          ),
        ]),
      ]),
      footer: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(builder: (context, bounds) {
          final actions = <Widget>[
            SlActionButton(
              icon: Icons.drive_file_move_outline,
              label: 'Sposta in…',
              onPressed: _busy ? null : () => _moveFile(original),
            ),
            SlActionButton(
              icon: Icons.edit_outlined,
              label: 'Rinomina',
              onPressed: _busy ? null : () => _renameFile(original),
            ),
            SlActionButton(
              icon: state == 'visible' ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              label: state == 'visible' ? 'Nascondi' : 'Mostra',
              onPressed: _busy
                  ? null
                  : () => _stageChange(original, visibility: state == 'visible' ? 'hidden' : 'visible'),
            ),
          ];
          final corrections = Wrap(spacing: 8, runSpacing: 4, children: [
            if (row['draft'] == true)
              TextButton.icon(
                onPressed: _busy ? null : () => _undoDraftItem('material', id),
                icon: const Icon(Icons.undo_rounded, size: 18),
                label: const Text('Annulla modifiche'),
              ),
            TextButton.icon(
              onPressed: _busy ? null : () => _removeFromStructure(materialIds: [id], label: _string(row['title'])),
              icon: const Icon(Icons.playlist_remove_rounded, size: 18),
              label: const Text('Togli dalla struttura'),
            ),
            if (driveId.isNotEmpty)
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: p.adminCoral),
                onPressed: _busy ? null : () => _deleteFromDrive([original], label: _string(row['title'])),
                icon: const Icon(Icons.delete_forever_outlined, size: 18),
                label: const Text('Elimina da Drive…'),
              ),
          ]);
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
            if (bounds.maxWidth < 570)
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(height: 8), actions[i],
              ]
            else
              Row(children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8), Expanded(child: actions[i]),
                ],
              ]),
            const SizedBox(height: 8),
            corrections,
          ]);
        }),
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
          TextSpan(text: 'Cartelle e file sulle sorgenti restano invariati.',
              style: TextStyle(color: p.adminCyan, fontWeight: FontWeight.w600)),
        ]), style: const TextStyle(fontSize: 13)),
      ),
    ]);
    final actions = Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
      if (_draftCount > 0) SlStatusBadge(label: '$_draftCount modifiche in bozza', tone: SlTone.warning),
      if (_waitingFiles > 0)
        Tooltip(
          message: 'File in copia su Drive: entrano nella bozza da soli. Aggiorna tra qualche minuto.',
          child: SlStatusBadge(label: '$_waitingFiles file in arrivo', tone: SlTone.info),
        ),
      if (_pendingConflicts.isNotEmpty)
        TextButton.icon(
          onPressed: _busy ? null : _resolvePendingConflicts,
          icon: const Icon(Icons.difference_outlined, size: 18),
          label: Text('${_pendingConflicts.length} doppioni da decidere'),
        ),
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
      appBar: slAdminAppBar(context, title: 'Catalogo', actions: [
        if (MediaQuery.sizeOf(context).width >= 1180)
          CatalogSourceSwitch(value: _source, onChanged: _busy ? (_) {} : _switchSource, counts: _sourceCounts),
        IconButton(onPressed: _busy ? null : _openSources,
          tooltip: 'Sorgenti', icon: const Icon(Icons.storage_rounded)),
        PopupMenuButton<String>(
          tooltip: 'Strumenti del catalogo',
          icon: const Icon(Icons.health_and_safety_outlined),
          onSelected: (action) {
            if (action == 'check') showDriveDiagnostics(context, _api);
            if (action == 'log') downloadDiagnosticLog(context, _api);
            if (action == 'duplicates') {
              showCatalogDuplicates(context, _api).then((changed) {
                if (changed == true && mounted) _reload();
              });
            }
            if (action == 'guest') showGuestEntryDialog(context, api: _api, subjects: _subjects);
            if (action == 'subjects') {
              showSubjectMergeDialog(context, api: _api).then((changed) {
                if (changed == true && mounted) _reload();
              });
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'guest', child: Text('Cosa vedono gli ospiti')),
            PopupMenuItem(value: 'subjects', child: Text('Materie doppie')),
            PopupMenuItem(value: 'duplicates', child: Text('File identici nella struttura')),
            PopupMenuItem(value: 'check', child: Text('Verifica collegamento Drive')),
            PopupMenuItem(value: 'log', child: Text('Scarica registro diagnostico')),
          ],
        ),
        IconButton(
          onPressed: _busy ? null : _reload,
          tooltip: 'Aggiorna catalogo',
          icon: const Icon(Icons.refresh_rounded),
        ),
      ]),
      bottomNavigationBar: !_loading && MediaQuery.sizeOf(context).width < 900
          ? NavigationBar(selectedIndex: _compactPane.clamp(0, 2),
              onDestinationSelected: (index) => setState(() => _compactPane = index),
              destinations: _previewMode ? const [
                NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profilo'),
                NavigationDestination(icon: Icon(Icons.phone_android), label: 'Anteprima'),
                NavigationDestination(icon: Icon(Icons.visibility_off_outlined), label: 'Esclusi'),
              ] : [
                const NavigationDestination(icon: Icon(Icons.cloud_outlined), label: 'Sorgenti'),
                const NavigationDestination(icon: Icon(Icons.account_tree_outlined), label: 'Struttura'),
                const NavigationDestination(icon: Icon(Icons.description_outlined), label: 'Dettaglio'),
              ]) : null,
      body: _loading
          ? Center(child: CircularProgressIndicator(color: p.skyBlue))
          : LayoutBuilder(builder: (context, box) {
              final bool wide = box.maxWidth >= 900;
              final modeBar = SlFilterBar<bool>(
                selected: _previewMode,
                options: const [
                  SlFilterOption(value: false, label: 'Struttura'),
                  SlFilterOption(value: true, label: 'Anteprima studente'),
                ],
                onSelected: (value) {
                  setState(() { _previewMode = value; _compactPane = 0; });
                  if (value) _loadPreview();
                },
              );
              final Widget content;
              if (wide) {
                content = Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: _previewMode
                    ? [
                        Expanded(flex: 3, child: _viewAsPane()),
                        const SizedBox(width: 16),
                        Expanded(child: _phonePane()),
                        const SizedBox(width: 16),
                        Expanded(flex: 3, child: _excludedPane()),
                      ]
                    : [
                        Expanded(flex: 3, child: _drivePane()),
                        const SizedBox(width: 16),
                        Expanded(flex: 4, child: _catalogPane()),
                        const SizedBox(width: 16),
                        Expanded(flex: 3, child: _detailsPane()),
                      ]);
              } else {
                final panes = _previewMode
                    ? [_viewAsPane(), _phonePane(), _excludedPane()]
                    : [_drivePane(), _catalogPane(), _detailsPane()];
                content = panes[_compactPane.clamp(0, 2)];
              }
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (!wide && !_previewMode)
                  Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: CatalogSourceSwitch(value: _source, onChanged: _busy ? (_) {} : _switchSource,
                      counts: _sourceCounts, expand: true)),
                Padding(
                  padding: EdgeInsets.fromLTRB(wide ? 24 : 12, 12, wide ? 24 : 12, 0),
                  child: Align(alignment: Alignment.centerRight, child: modeBar),
                ),
                if (box.maxWidth >= 900 && box.maxWidth < 1180)
                  Padding(padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: Align(alignment: Alignment.centerLeft, child: CatalogSourceSwitch(
                      value: _source, onChanged: _busy ? (_) {} : _switchSource, counts: _sourceCounts))),
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

/// Elemento trascinato: un file del catalogo oppure un file di Drive.
class _DragPayload {
  final Map<String, dynamic>? material;
  final Map<String, dynamic>? driveFile;

  const _DragPayload.material(Map<String, dynamic> value)
      : material = value,
        driveFile = null;

  const _DragPayload.drive(Map<String, dynamic> value)
      : material = null,
        driveFile = value;
}
