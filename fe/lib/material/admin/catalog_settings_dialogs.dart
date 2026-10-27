import 'package:flutter/material.dart';

import '../../services/user_facing_error.dart';
import '../../social/admin/admin_material_storage_api_service.dart';

// ---------------------------------------------------------------------------
// v30: «Cosa vedono gli ospiti» — da dove partono le Dispense senza account.
// ---------------------------------------------------------------------------

Future<bool?> showGuestEntryDialog(BuildContext context,
        {required AdminMaterialStorageApiService api, required List<Map<String, dynamic>> subjects}) =>
    showDialog<bool>(context: context, builder: (_) => _GuestEntryDialog(api: api, subjects: subjects));

class _GuestEntryDialog extends StatefulWidget {
  final AdminMaterialStorageApiService api;
  final List<Map<String, dynamic>> subjects;
  const _GuestEntryDialog({required this.api, required this.subjects});
  @override
  State<_GuestEntryDialog> createState() => _GuestEntryDialogState();
}

class _GuestEntryDialogState extends State<_GuestEntryDialog> {
  String _level = 'university';
  String? _university;
  String? _department;
  String? _course;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  static const _levels = <(String, String, String)>[
    ('university', 'Intero percorso', 'Ateneo › Dipartimento › Corso › Materia: per ospiti di atenei diversi'),
    ('department', 'Dai dipartimenti', 'I dipartimenti dell’ateneo scelto'),
    ('course', 'Dai corsi', 'I corsi del dipartimento scelto'),
    ('subject', 'Dalle materie', 'Le materie del corso scelto'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final v = await widget.api.getGuestEntry();
      if (!mounted) return;
      setState(() {
        _level = '${v['level'] ?? 'university'}';
        _university = v['university']?.toString();
        _department = v['department']?.toString();
        _course = v['course']?.toString();
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = friendlyError(e, 'Impostazione non disponibile.'); });
    }
  }

  List<String> _values(String key, {String? university, String? department}) {
    final out = <String>{
      for (final s in widget.subjects)
        if ((university == null || '${s['university']}' == university) &&
            (department == null || '${s['department']}' == department) &&
            '${s[key] ?? ''}'.trim().isNotEmpty)
          '${s[key]}',
    }.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return out;
  }

  int get _needed => switch (_level) { 'department' => 1, 'course' => 2, 'subject' => 3, _ => 0 };

  Widget _pick(String label, String? value, List<String> options, ValueChanged<String?> onChanged) =>
      DropdownButtonFormField<String>(
        key: ValueKey('$label-$value-${options.length}'),
        initialValue: options.contains(value) ? value : null,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [for (final o in options) DropdownMenuItem(value: o, child: Text(o, overflow: TextOverflow.ellipsis))],
        onChanged: onChanged,
      );

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    try {
      await widget.api.setGuestEntry(
        level: _level,
        university: _needed >= 1 ? _university : null,
        department: _needed >= 2 ? _department : null,
        course: _needed >= 3 ? _course : null,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() { _saving = false; _error = friendlyError(e, 'Impostazione non salvata.'); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return AlertDialog(
      title: const Text('Cosa vedono gli ospiti'),
      content: SizedBox(
        width: width < 560 ? width - 48 : 500,
        child: _loading
            ? const Padding(padding: EdgeInsets.all(24), child: LinearProgressIndicator())
            : SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Text('Da dove partono le Dispense per chi non ha fatto l’accesso. È solo una vista: '
                      'file e cartelle non cambiano, e puoi modificarla quando vuoi. L’ospite può sempre risalire '
                      'e scegliere un altro ateneo, dipartimento o corso.'),
                  const SizedBox(height: 12),
                  for (final (value, title, subtitle) in _levels)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(_level == value ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: _level == value ? Theme.of(context).colorScheme.primary : null),
                      title: Text(title),
                      subtitle: Text(subtitle),
                      onTap: () => setState(() => _level = value),
                    ),
                  if (_needed >= 1)
                    _pick('Ateneo', _university, _values('university'), (v) => setState(() {
                          _university = v;
                          _department = null;
                          _course = null;
                        })),
                  if (_needed >= 2)
                    _pick('Dipartimento', _department, _values('department', university: _university), (v) => setState(() {
                          _department = v;
                          _course = null;
                        })),
                  if (_needed >= 3)
                    _pick('Corso', _course,
                        _values('course', university: _university, department: _department),
                        (v) => setState(() => _course = v)),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ),
                ]),
              ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Annulla')),
        FilledButton(onPressed: _saving || _loading ? null : _save, child: const Text('Salva')),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// v30: materie doppie (stesso corso con due nomi, materie scritte in due modi).
// ---------------------------------------------------------------------------

Future<bool?> showSubjectMergeDialog(BuildContext context, {required AdminMaterialStorageApiService api}) =>
    showDialog<bool>(context: context, builder: (_) => _SubjectMergeDialog(api: api));

class _SubjectMergeDialog extends StatefulWidget {
  final AdminMaterialStorageApiService api;
  const _SubjectMergeDialog({required this.api});
  @override
  State<_SubjectMergeDialog> createState() => _SubjectMergeDialogState();
}

class _SubjectMergeDialogState extends State<_SubjectMergeDialog> {
  List<Map<String, dynamic>>? _items;
  /// id materia doppia -> id materia da tenere (0 = solo disattiva, null = non toccare)
  final Map<int, int?> _choice = {};
  final _confirm = TextEditingController();
  String? _error;
  String? _report;
  bool _busy = false;
  bool _changed = false;

  static int _id(Object? v) => int.tryParse('$v') ?? 0;

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
    try {
      final data = await widget.api.subjectDuplicates();
      final items = (data['items'] as List? ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      if (!mounted) return;
      setState(() {
        _items = items;
        _choice.clear();
        for (final it in items) {
          final suggested = it['suggested'];
          _choice[_id((it['duplicate'] as Map)['id'])] = suggested is Map ? _id(suggested['id']) : null;
        }
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e, 'Elenco delle materie doppie non disponibile.'));
    }
  }

  String _linked(Map<String, dynamic> dup) {
    final linked = (dup['linked'] as Map? ?? const {});
    if (linked.isEmpty) return 'nessun elemento collegato';
    const names = {
      'public_materials': 'file', 'calendar_events': 'eventi del calendario', 'quiz_assignments': 'quiz assegnati',
      'study_groups': 'gruppi', 'faq_questions': 'domande', 'dictionary_entries': 'voci del dizionario',
    };
    return linked.entries.map((e) => '${e.value} ${names[e.key] ?? 'altri elementi'}').join(', ');
  }

  Future<void> _merge() async {
    final pairs = <Map<String, dynamic>>[
      for (final e in _choice.entries)
        if (e.value != null) {'from_id': e.key, 'into_id': e.value == 0 ? null : e.value},
    ];
    if (pairs.isEmpty) return;
    setState(() { _busy = true; _error = null; });
    try {
      final r = await widget.api.mergeSubjects(pairs, _confirm.text.trim());
      final merged = (r['merged'] as List? ?? const []).length;
      final errors = (r['errors'] as List? ?? const []).whereType<Map>().toList();
      _changed = merged > 0;
      _report = '$merged materie sistemate.'
          '${errors.isEmpty ? '' : ' ${errors.length} non sistemate: ${errors.first['reason']}'}';
      _confirm.clear();
      await _load();
    } catch (e) {
      _error = friendlyError(e, 'Unione delle materie non riuscita.');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final items = _items;
    final selected = _choice.values.where((v) => v != null).length;
    return AlertDialog(
      title: const Text('Materie doppie'),
      content: SizedBox(
        width: width < 760 ? width - 48 : 700,
        child: items == null && _error == null
            ? const Padding(padding: EdgeInsets.all(24), child: LinearProgressIndicator())
            : SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Text('Stesso corso registrato con due nomi. Per ogni materia scegli in quale materia unirla: '
                      'file, quiz, calendario e dizionario passano alla materia scelta e la doppia viene disattivata. '
                      'Se un elemento esiste già in entrambe, quella materia non viene toccata.'),
                  if (_busy) const LinearProgressIndicator(),
                  if (_report != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_report!)),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ),
                  if (items != null && items.isEmpty)
                    const Padding(padding: EdgeInsets.all(16), child: Text('Nessuna materia doppia: è tutto in ordine.')),
                  for (final it in items ?? const <Map<String, dynamic>>[]) ...[
                    const Divider(),
                    Builder(builder: (context) {
                      final dup = Map<String, dynamic>.from(it['duplicate'] as Map);
                      final id = _id(dup['id']);
                      final options = (it['options'] as List? ?? const []).whereType<Map>().toList();
                      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Text('${dup['name']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text('${it['other_course']} (${it['course_code']}) · ${_linked(dup)}',
                            style: Theme.of(context).textTheme.bodySmall),
                        DropdownButtonFormField<int?>(
                          key: ValueKey('merge-$id-${_choice[id]}'),
                          initialValue: _choice[id],
                          isExpanded: true,
                          decoration: InputDecoration(labelText: 'Unisci in (${it['main_course']})'),
                          items: [
                            const DropdownMenuItem<int?>(value: null, child: Text('Non toccare')),
                            if ((dup['linked'] as Map? ?? const {}).isEmpty)
                              const DropdownMenuItem<int?>(value: 0, child: Text('Solo disattiva (non ha nulla di collegato)')),
                            for (final o in options)
                              DropdownMenuItem<int?>(
                                value: _id(o['id']),
                                child: Text('${o['name']}${o['study_year'] == null ? '' : ' · ${o['study_year']}° anno'}',
                                    overflow: TextOverflow.ellipsis),
                              ),
                          ],
                          onChanged: _busy ? null : (v) => setState(() => _choice[id] = v),
                        ),
                      ]);
                    }),
                  ],
                  if (selected > 0) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirm,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(labelText: 'Scrivi UNISCI per sistemare $selected materie'),
                    ),
                  ],
                ]),
              ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context, _changed), child: const Text('Chiudi')),
        FilledButton(
          onPressed: _busy || selected == 0 || _confirm.text.trim() != 'UNISCI' ? null : _merge,
          child: Text('Unisci $selected'),
        ),
      ],
    );
  }
}
