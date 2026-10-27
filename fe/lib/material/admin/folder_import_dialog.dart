import 'package:flutter/material.dart';

import 'subject_hierarchy_filter.dart';

/// Scelte per aggiungere una cartella (con sottocartelle) alla struttura (v27).
class FolderImportChoice {
  final int subjectId;
  final String audience;
  final int? audienceId;
  /// Cartella nelle Dispense dove mettere il contenuto.
  final List<String> destination;
  /// true: si crea anche la cartella scelta; false: solo il suo contenuto.
  final bool includeRoot;
  /// File scelti, con le cartelle relative (la prima è la cartella scelta).
  final List<(Map<String, dynamic>, List<String>)> files;
  /// Cartelle scelte (anche vuote), relative come sopra.
  final List<List<String>> folders;

  const FolderImportChoice({
    required this.subjectId,
    required this.audience,
    required this.audienceId,
    required this.destination,
    required this.includeRoot,
    required this.files,
    required this.folders,
  });

  /// Percorso nelle Dispense per una cartella relativa.
  List<String> catalogPath(List<String> relative) =>
      [...destination, ...(includeRoot ? relative : relative.skip(1))];
}

String _key(List<String> path) => path.join('\u0000');

Future<FolderImportChoice?> showFolderImportDialog(
  BuildContext context, {
  required String title,
  required String rootName,
  required List<(Map<String, dynamic>, List<String>)> files,
  required List<List<String>> folders,
  required int excluded,
  required List<Map<String, dynamic>> subjects,
  required int? initialSubjectId,
  List<String> initialDestination = const <String>[],
  String note = '',
}) =>
    showDialog<FolderImportChoice>(
      context: context,
      builder: (_) => _FolderImportDialog(
        title: title,
        rootName: rootName,
        files: files,
        folders: folders,
        excluded: excluded,
        subjects: subjects,
        initialSubjectId: initialSubjectId,
        initialDestination: initialDestination,
        note: note,
      ),
    );

class _FolderImportDialog extends StatefulWidget {
  final String title;
  final String rootName;
  final List<(Map<String, dynamic>, List<String>)> files;
  final List<List<String>> folders;
  final int excluded;
  final List<Map<String, dynamic>> subjects;
  final int? initialSubjectId;
  final List<String> initialDestination;
  final String note;
  const _FolderImportDialog({
    required this.title,
    required this.rootName,
    required this.files,
    required this.folders,
    required this.excluded,
    required this.subjects,
    required this.initialSubjectId,
    required this.initialDestination,
    required this.note,
  });
  @override
  State<_FolderImportDialog> createState() => _FolderImportDialogState();
}

class _FolderImportDialogState extends State<_FolderImportDialog> {
  late int? _subjectId = widget.initialSubjectId;
  String _audience = 'course';
  final _audienceId = TextEditingController();
  late final _destination = TextEditingController(text: widget.initialDestination.join(' / '));
  late bool _includeRoot = !_sameAsSubject;
  late final Set<int> _files = {for (var i = 0; i < widget.files.length; i++) i};
  late final Set<String> _folders = {for (final f in widget.folders) _key(f)};
  final Set<String> _collapsed = {};
  String? _error;

  @override
  void dispose() {
    _audienceId.dispose();
    _destination.dispose();
    super.dispose();
  }

  Map<String, dynamic>? get _subject {
    for (final s in widget.subjects) {
      if (int.tryParse('${s['id']}') == _subjectId) return s;
    }
    return null;
  }

  /// La cartella ha lo stesso nome della materia: di solito non va ricreata come argomento.
  bool get _sameAsSubject {
    String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9àèéìòù]+'), ' ').trim();
    final name = norm('${_subject?['name'] ?? ''}');
    return name.isNotEmpty && norm(widget.rootName) == name;
  }

  bool _inside(List<String> path, List<String> folder) =>
      path.length >= folder.length && _key(path.take(folder.length).toList()) == _key(folder);

  List<int> _filesUnder(List<String> folder) =>
      [for (var i = 0; i < widget.files.length; i++) if (_inside(widget.files[i].$2, folder)) i];

  bool? _folderState(List<String> folder) {
    final under = _filesUnder(folder);
    final subFolders = widget.folders.where((f) => _inside(f, folder)).map(_key).toList();
    final chosen = under.where(_files.contains).length + subFolders.where(_folders.contains).length;
    final total = under.length + subFolders.length;
    if (chosen == 0) return false;
    if (chosen == total) return true;
    return null;
  }

  void _toggleFolder(List<String> folder, bool select) {
    setState(() {
      for (final i in _filesUnder(folder)) {
        select ? _files.add(i) : _files.remove(i);
      }
      for (final f in widget.folders.where((f) => _inside(f, folder))) {
        select ? _folders.add(_key(f)) : _folders.remove(_key(f));
      }
    });
  }

  String _bytes(Object? value) {
    final size = int.tryParse('$value') ?? 0;
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  List<Widget> _tree(List<String> folder, int depth) {
    final rows = <Widget>[];
    final children = widget.folders.where((f) => f.length == folder.length + 1 && _inside(f, folder)).toList()
      ..sort((a, b) => a.last.toLowerCase().compareTo(b.last.toLowerCase()));
    for (final child in children) {
      final collapsed = _collapsed.contains(_key(child));
      rows.add(Padding(
        padding: EdgeInsets.only(left: 16.0 * depth),
        child: Row(children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(collapsed ? Icons.chevron_right : Icons.expand_more, size: 18),
            onPressed: () => setState(() => collapsed ? _collapsed.remove(_key(child)) : _collapsed.add(_key(child))),
          ),
          Checkbox(
            tristate: true,
            value: _folderState(child),
            onChanged: (_) => _toggleFolder(child, _folderState(child) != true),
          ),
          const Icon(Icons.folder_outlined, size: 18),
          const SizedBox(width: 6),
          Expanded(child: Text(child.last, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600))),
          Text('${_filesUnder(child).length} file', style: Theme.of(context).textTheme.bodySmall),
        ]),
      ));
      if (!collapsed) rows.addAll(_tree(child, depth + 1));
    }
    final files = [for (var i = 0; i < widget.files.length; i++) if (_key(widget.files[i].$2) == _key(folder)) i]
      ..sort((a, b) => '${widget.files[a].$1['name']}'.toLowerCase().compareTo('${widget.files[b].$1['name']}'.toLowerCase()));
    for (final i in files) {
      rows.add(Padding(
        padding: EdgeInsets.only(left: 16.0 * depth + 40),
        child: Row(children: [
          Checkbox(value: _files.contains(i), onChanged: (v) => setState(() => v == true ? _files.add(i) : _files.remove(i))),
          const Icon(Icons.insert_drive_file_outlined, size: 18),
          const SizedBox(width: 6),
          Expanded(child: Text('${widget.files[i].$1['name']}', overflow: TextOverflow.ellipsis)),
          Text(_bytes(widget.files[i].$1['size']), style: Theme.of(context).textTheme.bodySmall),
        ]),
      ));
    }
    return rows;
  }

  void _confirm() {
    final destination = _destination.text.trim().isEmpty
        ? <String>[]
        : _destination.text.split('/').map((s) => s.trim()).toList();
    final id = int.tryParse(_audienceId.text.trim());
    if (_subjectId == null) {
      setState(() => _error = 'Scegli la materia.');
      return;
    }
    if (destination.any((s) => s.isEmpty || s == '.' || s == '..')) {
      setState(() => _error = 'Scrivi nomi di cartella validi, separati da «/».');
      return;
    }
    if ((_audience == 'group' || _audience == 'user') && (id == null || id <= 0)) {
      setState(() => _error = _audience == 'group' ? 'Indica il gruppo.' : 'Indica lo studente.');
      return;
    }
    final choice = FolderImportChoice(
      subjectId: _subjectId!,
      audience: _audience,
      audienceId: _audience == 'group' || _audience == 'user' ? id : null,
      destination: destination,
      includeRoot: _includeRoot,
      files: [for (final i in _files.toList()..sort()) widget.files[i]],
      folders: [for (final f in widget.folders) if (_folders.contains(_key(f))) f],
    );
    if (choice.files.isEmpty && choice.folders.length <= (_includeRoot ? 0 : 1)) {
      setState(() => _error = 'Scegli almeno un file o una cartella.');
      return;
    }
    if ([...choice.files.map((f) => f.$2), ...choice.folders].any((p) => choice.catalogPath(p).length > 8)) {
      setState(() => _error = 'Alcune cartelle superano 8 livelli: scegli una destinazione meno profonda '
          'o togli la spunta da «Crea anche la cartella».');
      return;
    }
    Navigator.pop(context, choice);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.sizeOf(context).height;
    final root = [widget.rootName];
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: width < 640 ? width - 48 : 580,
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
            Text('${widget.files.length} file in ${widget.folders.length} cartelle'
                '${widget.excluded > 0 ? ' · ${widget.excluded} già nel catalogo o non compatibili (non elencati)' : ''}.'),
            if (widget.note.isNotEmpty) ...[const SizedBox(height: 4), Text(widget.note)],
            const SizedBox(height: 12),
            SubjectPickerField(
              subjects: widget.subjects,
              value: _subjectId,
              onChanged: (v) => setState(() {
                _subjectId = v;
                if (_sameAsSubject) _includeRoot = false;
              }),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _audience,
              decoration: const InputDecoration(labelText: 'Destinatari'),
              items: const [
                DropdownMenuItem(value: 'public', child: Text('Tutti, anche guest')),
                DropdownMenuItem(value: 'course', child: Text('Studenti del corso')),
                DropdownMenuItem(value: 'subject', child: Text('Studenti della materia')),
                DropdownMenuItem(value: 'group', child: Text('Un gruppo')),
                DropdownMenuItem(value: 'user', child: Text('Uno studente')),
              ],
              onChanged: (v) => setState(() => _audience = v ?? _audience),
            ),
            if (_audience == 'group' || _audience == 'user')
              TextField(
                controller: _audienceId,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: _audience == 'group' ? 'ID gruppo' : 'ID studente'),
              ),
            TextField(
              controller: _destination,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Dentro la cartella delle Dispense (facoltativa)',
                hintText: 'Esercizi / 2025-26',
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _includeRoot,
              onChanged: (v) => setState(() => _includeRoot = v),
              title: Text('Crea anche la cartella «${widget.rootName}»'),
              subtitle: Text(_sameAsSubject
                  ? 'Ha lo stesso nome della materia: di solito va disattivato, così non diventa un argomento.'
                  : 'Disattiva per mettere direttamente il suo contenuto.'),
            ),
            Text(
              'Risultato: ${[subjectSummary(_subject), ..._destination.text.split('/').map((s) => s.trim()).where((s) => s.isNotEmpty), if (_includeRoot) widget.rootName].join(' / ')} / …',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(),
            Row(children: [
              Checkbox(tristate: true, value: _folderState(root), onChanged: (_) => _toggleFolder(root, _folderState(root) != true)),
              Expanded(child: Text(widget.rootName, style: const TextStyle(fontWeight: FontWeight.w700))),
            ]),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: height * 0.4),
              child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _tree(root, 0))),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
        FilledButton(onPressed: _confirm, child: Text('Aggiungi ${_files.length} file alla bozza')),
      ],
    );
  }
}
