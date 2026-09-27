import 'package:flutter/material.dart';

import 'package:fe/theme/app_palette.dart';
import 'package:fe/widgets/studentlab_ui/studentlab_ui.dart';
import 'package:fe/quiz/exercises/exercise_models.dart';

/// Editor dei dati specifici di ogni tipo. Ogni editor riceve i dati salvati
/// (anche nella forma già validata dal server) e restituisce la forma di
/// scrittura che il server valida di nuovo (services/exercise_types.py).
typedef DataChanged = void Function(Map<String, dynamic> data);

Widget typeEditor({
  required String type,
  required Map<String, dynamic> initial,
  required List<Map<String, dynamic>> attachments,
  required DataChanged onChanged,
}) {
  final Key key = ValueKey<String>('editor-$type');
  return switch (type) {
    'scelta' => SceltaEditor(key: key, initial: initial, attachments: attachments, onChanged: onChanged),
    'ordina' => OrdinaEditor(key: key, initial: initial, onChanged: onChanged),
    'abbina' => AbbinaEditor(key: key, initial: initial, onChanged: onChanged),
    'completa' => CompletaEditor(key: key, initial: initial, onChanged: onChanged),
    'errore' => ErroreEditor(key: key, initial: initial, onChanged: onChanged),
    'diagramma' => DiagrammaEditor(key: key, initial: initial, attachments: attachments, onChanged: onChanged),
    'grafo' => GrafoEditor(key: key, initial: initial, onChanged: onChanged),
    'flashcard' => FlashcardEditor(key: key, initial: initial, onChanged: onChanged),
    'traccia' => TracciaEditor(key: key, initial: initial, onChanged: onChanged),
    'numerica' => NumericaEditor(key: key, initial: initial, onChanged: onChanged),
    'codice' => CodiceEditor(key: key, initial: initial, onChanged: onChanged),
    _ => const SizedBox.shrink(),
  };
}

InputDecoration _dec(String label, {String? hint, bool dense = true}) =>
    InputDecoration(labelText: label, hintText: hint, isDense: dense, border: const OutlineInputBorder());

List<String> _splitList(String text) =>
    text.split(RegExp(r'[,;\n]')).map((String s) => s.trim()).where((String s) => s.isNotEmpty).toList();

/// Una riga di testo con controller proprio (liste modificabili).
class _Row {
  final String key;
  final TextEditingController a;
  final TextEditingController b;
  bool flag;
  _Row(this.key, {String a = '', String b = '', this.flag = false})
      : a = TextEditingController(text: a),
        b = TextEditingController(text: b);
  void dispose() {
    a.dispose();
    b.dispose();
  }
}

int _seq = 0;
String _newKey() => 'k${DateTime.now().microsecondsSinceEpoch}${_seq++}';

Widget _section(BuildContext context, String title, List<Widget> children, {String? help}) {
  final p = context.palette;
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: p.eleganceMidnight,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: p.pureWhite.withValues(alpha: 0.07)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
      SlOverline(title),
      if (help != null) ...<Widget>[
        const SizedBox(height: 4),
        Text(help, style: SlText.muted(p).copyWith(fontSize: 12)),
      ],
      const SizedBox(height: 10),
      ...children,
    ]),
  );
}

// ------------------------------------------------------------------- scelta
class SceltaEditor extends StatefulWidget {
  final Map<String, dynamic> initial;
  final List<Map<String, dynamic>> attachments;
  final DataChanged onChanged;
  const SceltaEditor({super.key, required this.initial, required this.attachments, required this.onChanged});
  @override
  State<SceltaEditor> createState() => _SceltaEditorState();
}

class _SceltaEditorState extends State<SceltaEditor> {
  final List<_Row> _options = <_Row>[];
  final Map<String, String?> _images = <String, String?>{};

  @override
  void initState() {
    super.initState();
    final Set<String> correct = asStringList(widget.initial['correct']).toSet();
    for (final Map<String, dynamic> o in asMapList(widget.initial['options'])) {
      final _Row row = _Row(o['id']?.toString() ?? _newKey(), a: o['text']?.toString() ?? '', flag: correct.contains(o['id']?.toString()));
      _images[row.key] = o['attachment_id']?.toString();
      _options.add(row);
    }
    while (_options.length < 4) {
      _options.add(_Row(String.fromCharCode(65 + _options.length)));
    }
    for (final _Row r in _options) {
      r.a.addListener(_emit);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
  }

  @override
  void dispose() {
    for (final _Row r in _options) {
      r.dispose();
    }
    super.dispose();
  }

  void _emit() {
    final List<_Row> used = _options.where((_Row r) => r.a.text.trim().isNotEmpty || _images[r.key] != null).toList();
    widget.onChanged(<String, dynamic>{
      'options': <Map<String, dynamic>>[
        for (final _Row r in used)
          <String, dynamic>{'id': r.key, 'text': r.a.text.trim(), if (_images[r.key] != null) 'attachment_id': _images[r.key]},
      ],
      'correct': used.where((_Row r) => r.flag).map((_Row r) => r.key).toList(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> images = widget.attachments
        .where((Map<String, dynamic> a) => (a['mime_type']?.toString() ?? '').startsWith('image/'))
        .toList();
    return _section(context, 'RISPOSTE', help: 'Segna una o più risposte giuste. Una risposta può avere un’immagine (caricala negli allegati).', <Widget>[
      for (final _Row r in _options)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: <Widget>[
            Checkbox(value: r.flag, onChanged: (bool? v) {
              setState(() => r.flag = v == true);
              _emit();
            }),
            Expanded(child: TextField(controller: r.a, decoration: _dec('Risposta ${r.key}'))),
            if (images.isNotEmpty) ...<Widget>[
              const SizedBox(width: 6),
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<String?>(
                  value: images.any((Map<String, dynamic> a) => a['id'] == _images[r.key]) ? _images[r.key] : null,
                  isExpanded: true,
                  decoration: _dec('Immagine'),
                  items: <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(value: null, child: Text('Nessuna')),
                    for (final Map<String, dynamic> a in images)
                      DropdownMenuItem<String?>(value: a['id'].toString(), child: Text('${a['original_name']}', overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (String? v) {
                    setState(() => _images[r.key] = v);
                    _emit();
                  },
                ),
              ),
            ],
            IconButton(
              tooltip: 'Togli',
              onPressed: _options.length <= 2
                  ? null
                  : () {
                      setState(() {
                        _options.remove(r);
                        r.dispose();
                      });
                      _emit();
                    },
              icon: const Icon(Icons.remove_circle_outline_rounded),
            ),
          ]),
        ),
      if (_options.length < 12)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              String id = String.fromCharCode(65 + _options.length);
              while (_options.any((_Row r) => r.key == id)) {
                id = _newKey();
              }
              final _Row row = _Row(id)..a.addListener(_emit);
              setState(() => _options.add(row));
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Aggiungi risposta'),
          ),
        ),
    ]);
  }
}

// ------------------------------------------------------------------- ordina
class OrdinaEditor extends StatefulWidget {
  final Map<String, dynamic> initial;
  final DataChanged onChanged;
  const OrdinaEditor({super.key, required this.initial, required this.onChanged});
  @override
  State<OrdinaEditor> createState() => _OrdinaEditorState();
}

class _OrdinaEditorState extends State<OrdinaEditor> {
  final List<_Row> _steps = <_Row>[];

  @override
  void initState() {
    super.initState();
    final List<Map<String, dynamic>> items = asMapList(widget.initial['items']);
    final Map<String, String> texts = {for (final i in items) i['id'].toString(): i['text']?.toString() ?? ''};
    final List<String> order = asStringList(widget.initial['order']);
    for (final String id in order.isNotEmpty ? order : texts.keys.toList()) {
      _steps.add(_Row(_newKey(), a: texts[id] ?? ''));
    }
    while (_steps.length < 3) {
      _steps.add(_Row(_newKey()));
    }
    for (final _Row r in _steps) {
      r.a.addListener(_emit);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
  }

  @override
  void dispose() {
    for (final _Row r in _steps) {
      r.dispose();
    }
    super.dispose();
  }

  void _emit() => widget.onChanged(<String, dynamic>{
        'items': _steps.map((_Row r) => r.a.text.trim()).where((String t) => t.isNotEmpty).toList(),
      });

  @override
  Widget build(BuildContext context) {
    return _section(context, 'PASSAGGI NELL’ORDINE GIUSTO', help: 'Lo studente li vedrà mescolati.', <Widget>[
      for (int i = 0; i < _steps.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: <Widget>[
            SizedBox(width: 26, child: Text('${i + 1}.')),
            Expanded(child: TextField(controller: _steps[i].a, decoration: _dec('Passaggio ${i + 1}'))),
            IconButton(
              tooltip: 'Su',
              onPressed: i == 0 ? null : () => setState(() {
                final _Row r = _steps.removeAt(i);
                _steps.insert(i - 1, r);
                _emit();
              }),
              icon: const Icon(Icons.arrow_upward_rounded, size: 18),
            ),
            IconButton(
              tooltip: 'Togli',
              onPressed: _steps.length <= 2 ? null : () => setState(() {
                _steps.removeAt(i).dispose();
                _emit();
              }),
              icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
            ),
          ]),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _steps.length >= 15 ? null : () => setState(() => _steps.add(_Row(_newKey())..a.addListener(_emit))),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Aggiungi passaggio'),
        ),
      ),
    ]);
  }
}

// ------------------------------------------------------------------- abbina
class AbbinaEditor extends StatefulWidget {
  final Map<String, dynamic> initial;
  final DataChanged onChanged;
  const AbbinaEditor({super.key, required this.initial, required this.onChanged});
  @override
  State<AbbinaEditor> createState() => _AbbinaEditorState();
}

class _AbbinaEditorState extends State<AbbinaEditor> {
  final List<_Row> _pairs = <_Row>[];
  late final TextEditingController _distractors;

  @override
  void initState() {
    super.initState();
    final dynamic rawPairs = widget.initial['pairs'];
    final List<String> extra = <String>[];
    if (rawPairs is Map) {
      final Map<String, String> right = {
        for (final r in asMapList(widget.initial['right'])) r['id'].toString(): r['text']?.toString() ?? ''
      };
      for (final Map<String, dynamic> l in asMapList(widget.initial['left'])) {
        _pairs.add(_Row(_newKey(), a: l['text']?.toString() ?? '', b: right[rawPairs[l['id'].toString()]?.toString()] ?? ''));
      }
      final Set<String> used = rawPairs.values.map((dynamic v) => v.toString()).toSet();
      extra.addAll(right.entries.where((MapEntry<String, String> e) => !used.contains(e.key)).map((e) => e.value));
    } else {
      for (final Map<String, dynamic> p in asMapList(rawPairs)) {
        _pairs.add(_Row(_newKey(), a: p['left']?.toString() ?? '', b: p['right']?.toString() ?? ''));
      }
      extra.addAll(asStringList(widget.initial['distractors']));
    }
    while (_pairs.length < 3) {
      _pairs.add(_Row(_newKey()));
    }
    _distractors = TextEditingController(text: extra.join('\n'))..addListener(_emit);
    for (final _Row r in _pairs) {
      r.a.addListener(_emit);
      r.b.addListener(_emit);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
  }

  @override
  void dispose() {
    for (final _Row r in _pairs) {
      r.dispose();
    }
    _distractors.dispose();
    super.dispose();
  }

  void _emit() => widget.onChanged(<String, dynamic>{
        'pairs': <Map<String, String>>[
          for (final _Row r in _pairs)
            if (r.a.text.trim().isNotEmpty || r.b.text.trim().isNotEmpty) <String, String>{'left': r.a.text.trim(), 'right': r.b.text.trim()},
        ],
        'distractors': _distractors.text.split('\n').map((String s) => s.trim()).where((String s) => s.isNotEmpty).toList(),
      });

  @override
  Widget build(BuildContext context) {
    return _section(context, 'COPPIE', help: 'A sinistra il termine, a destra ciò che gli corrisponde.', <Widget>[
      for (int i = 0; i < _pairs.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: <Widget>[
            Expanded(flex: 2, child: TextField(controller: _pairs[i].a, decoration: _dec('Sinistra ${i + 1}'))),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.arrow_forward_rounded, size: 18)),
            Expanded(flex: 3, child: TextField(controller: _pairs[i].b, decoration: _dec('Destra ${i + 1}'))),
            IconButton(
              tooltip: 'Togli',
              onPressed: _pairs.length <= 2 ? null : () => setState(() {
                _pairs.removeAt(i).dispose();
                _emit();
              }),
              icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
            ),
          ]),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _pairs.length >= 12
              ? null
              : () => setState(() => _pairs.add(_Row(_newKey())
                ..a.addListener(_emit)
                ..b.addListener(_emit))),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Aggiungi coppia'),
        ),
      ),
      const SizedBox(height: 6),
      TextField(controller: _distractors, minLines: 1, maxLines: 4,
          decoration: _dec('Elementi di disturbo a destra (uno per riga, facoltativi)')),
    ]);
  }
}

// ------------------------------------------------------------------- completa
class CompletaEditor extends StatefulWidget {
  final Map<String, dynamic> initial;
  final DataChanged onChanged;
  const CompletaEditor({super.key, required this.initial, required this.onChanged});
  @override
  State<CompletaEditor> createState() => _CompletaEditorState();
}

class _CompletaEditorState extends State<CompletaEditor> {
  static final RegExp _blank = RegExp(r'\[\[([A-Za-z0-9_-]{1,20})\]\]');
  late final TextEditingController _text = TextEditingController(text: widget.initial['text']?.toString() ?? '');
  late final TextEditingController _bank = TextEditingController(text: asStringList(widget.initial['bank']).join(', '));
  final Map<String, _Row> _blanks = <String, _Row>{};
  final Map<String, TextEditingController> _tolerance = <String, TextEditingController>{};
  bool _caseSensitive = false;

  @override
  void initState() {
    super.initState();
    _caseSensitive = widget.initial['case_sensitive'] == true;
    for (final Map<String, dynamic> b in asMapList(widget.initial['blanks'])) {
      final String id = b['id'].toString();
      _blanks[id] = _Row(id, a: asStringList(b['accepted']).join(', '), flag: b['numeric'] == true);
      _tolerance[id] = TextEditingController(text: '${b['tolerance'] ?? ''}' == '0.0' ? '' : '${b['tolerance'] ?? ''}');
    }
    _text.addListener(_sync);
    _bank.addListener(_emit);
    _sync();
  }

  @override
  void dispose() {
    _text.dispose();
    _bank.dispose();
    for (final _Row r in _blanks.values) {
      r.dispose();
    }
    for (final TextEditingController c in _tolerance.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _sync() {
    final List<String> ids = _blank.allMatches(_text.text).map((RegExpMatch m) => m.group(1)!).toList();
    bool changed = false;
    for (final String id in ids) {
      if (!_blanks.containsKey(id)) {
        _blanks[id] = _Row(id)..a.addListener(_emit);
        _tolerance[id] = TextEditingController()..addListener(_emit);
        changed = true;
      } else {
        _blanks[id]!.a.removeListener(_emit);
        _blanks[id]!.a.addListener(_emit);
        _tolerance[id]!.removeListener(_emit);
        _tolerance[id]!.addListener(_emit);
      }
    }
    if (changed && mounted) setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
      _emit();
    });
  }

  void _insertBlank() {
    int n = 1;
    while (_text.text.contains('[[$n]]')) {
      n++;
    }
    final TextSelection selection = _text.selection;
    final String marker = '[[$n]]';
    final int at = selection.isValid ? selection.start : _text.text.length;
    _text.value = TextEditingValue(
      text: _text.text.replaceRange(at, selection.isValid ? selection.end : at, marker),
      selection: TextSelection.collapsed(offset: at + marker.length),
    );
  }

  void _emit() {
    final List<String> ids = _blank.allMatches(_text.text).map((RegExpMatch m) => m.group(1)!).toList();
    widget.onChanged(<String, dynamic>{
      'text': _text.text,
      'blanks': <Map<String, dynamic>>[
        for (final String id in ids)
          if (_blanks[id] != null)
            <String, dynamic>{
              'id': id,
              'accepted': _splitList(_blanks[id]!.a.text),
              'numeric': _blanks[id]!.flag,
              'tolerance': double.tryParse(_tolerance[id]!.text.replaceAll(',', '.')) ?? 0,
            },
      ],
      'bank': _splitList(_bank.text),
      'case_sensitive': _caseSensitive,
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<String> ids = _blank.allMatches(_text.text).map((RegExpMatch m) => m.group(1)!).toList();
    return _section(context, 'TESTO CON GLI SPAZI', help: 'Scrivi il testo e metti [[1]], [[2]]… dove lo studente deve completare.', <Widget>[
      TextField(controller: _text, minLines: 3, maxLines: 8, decoration: _dec('Testo', hint: 'Un /26 lascia [[1]] bit per gli host')),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(onPressed: _insertBlank, icon: const Icon(Icons.add_box_outlined), label: const Text('Inserisci uno spazio')),
      ),
      for (final String id in ids)
        if (_blanks[id] != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: <Widget>[
              SizedBox(width: 52, child: Text('[[$id]]', style: const TextStyle(fontFamily: 'monospace'))),
              Expanded(child: TextField(controller: _blanks[id]!.a, decoration: _dec('Risposte ammesse (separate da virgola)'))),
              const SizedBox(width: 6),
              FilterChip(
                label: const Text('Numero'),
                selected: _blanks[id]!.flag,
                onSelected: (bool v) {
                  setState(() => _blanks[id]!.flag = v);
                  _emit();
                },
              ),
              if (_blanks[id]!.flag) ...<Widget>[
                const SizedBox(width: 6),
                SizedBox(width: 90, child: TextField(controller: _tolerance[id], decoration: _dec('± tolleranza'))),
              ],
            ]),
          ),
      const SizedBox(height: 6),
      TextField(controller: _bank, decoration: _dec('Parole da trascinare (facoltative, separate da virgola)')),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _caseSensitive,
        title: const Text('Distingui maiuscole e minuscole'),
        onChanged: (bool v) {
          setState(() => _caseSensitive = v);
          _emit();
        },
      ),
    ]);
  }
}

// ------------------------------------------------------------------- errore
class ErroreEditor extends StatefulWidget {
  final Map<String, dynamic> initial;
  final DataChanged onChanged;
  const ErroreEditor({super.key, required this.initial, required this.onChanged});
  @override
  State<ErroreEditor> createState() => _ErroreEditorState();
}

class _ErroreEditorState extends State<ErroreEditor> {
  late final TextEditingController _lines = TextEditingController(text: asStringList(widget.initial['lines']).join('\n'));
  late final TextEditingController _errors = TextEditingController(text: asStringList(widget.initial['error_lines']).join(', '));
  late final TextEditingController _language = TextEditingController(text: widget.initial['language']?.toString() ?? '');
  late final TextEditingController _fix = TextEditingController(text: widget.initial['fix']?.toString() ?? '');
  final List<_Row> _reasons = <_Row>[];

  @override
  void initState() {
    super.initState();
    final String? correct = widget.initial['correct_reason']?.toString();
    for (final Map<String, dynamic> r in asMapList(widget.initial['reasons'])) {
      _reasons.add(_Row(r['id'].toString(), a: r['text']?.toString() ?? '', flag: r['id'].toString() == correct));
    }
    for (final TextEditingController c in <TextEditingController>[_lines, _errors, _language, _fix]) {
      c.addListener(_emit);
    }
    for (final _Row r in _reasons) {
      r.a.addListener(_emit);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
  }

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[_lines, _errors, _language, _fix]) {
      c.dispose();
    }
    for (final _Row r in _reasons) {
      r.dispose();
    }
    super.dispose();
  }

  void _emit() {
    final List<_Row> reasons = _reasons.where((_Row r) => r.a.text.trim().isNotEmpty).toList();
    widget.onChanged(<String, dynamic>{
      'lines': _lines.text.split('\n'),
      'language': _language.text.trim(),
      'error_lines': _splitList(_errors.text).map(int.tryParse).whereType<int>().toList(),
      'reasons': <Map<String, String>>[for (final _Row r in reasons) <String, String>{'id': r.key, 'text': r.a.text.trim()}],
      if (reasons.any((_Row r) => r.flag)) 'correct_reason': reasons.firstWhere((_Row r) => r.flag).key,
      'fix': _fix.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return _section(context, 'RIGHE E ERRORE', help: 'Una riga per riga di codice o di calcolo. Le righe si contano da 1.', <Widget>[
      TextField(controller: _language, decoration: _dec('Linguaggio (facoltativo: c, python, pseudocodice…)')),
      const SizedBox(height: 8),
      TextField(
        controller: _lines,
        minLines: 5,
        maxLines: 16,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        decoration: _dec('Righe', dense: false),
      ),
      const SizedBox(height: 8),
      TextField(controller: _errors, decoration: _dec('Numero delle righe con l’errore (es. 3 oppure 3, 5)')),
      const SizedBox(height: 12),
      Text('Motivi (facoltativi): lo studente sceglie perché è sbagliata', style: SlText.muted(context.palette).copyWith(fontSize: 12)),
      const SizedBox(height: 6),
      for (final _Row r in _reasons)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: <Widget>[
            Radio<String>(
              value: r.key,
              groupValue: _reasons.where((_Row x) => x.flag).map((_Row x) => x.key).firstOrNull,
              onChanged: (String? v) {
                setState(() {
                  for (final _Row x in _reasons) {
                    x.flag = x.key == v;
                  }
                });
                _emit();
              },
            ),
            Expanded(child: TextField(controller: r.a, decoration: _dec('Motivo'))),
            IconButton(
              tooltip: 'Togli',
              onPressed: () => setState(() {
                _reasons.remove(r);
                r.dispose();
                _emit();
              }),
              icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
            ),
          ]),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _reasons.length >= 6
              ? null
              : () => setState(() => _reasons.add(_Row(String.fromCharCode(97 + _reasons.length))..a.addListener(_emit))),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Aggiungi motivo'),
        ),
      ),
      TextField(controller: _fix, decoration: _dec('Riga corretta (mostrata dopo la risposta)')),
    ]);
  }
}

// ------------------------------------------------------------------- flashcard
class FlashcardEditor extends StatefulWidget {
  final Map<String, dynamic> initial;
  final DataChanged onChanged;
  const FlashcardEditor({super.key, required this.initial, required this.onChanged});
  @override
  State<FlashcardEditor> createState() => _FlashcardEditorState();
}

class _FlashcardEditorState extends State<FlashcardEditor> {
  late final TextEditingController _front = TextEditingController(text: widget.initial['front']?.toString() ?? '')..addListener(_emit);
  late final TextEditingController _back = TextEditingController(text: widget.initial['back']?.toString() ?? '')..addListener(_emit);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
  }

  @override
  void dispose() {
    _front.dispose();
    _back.dispose();
    super.dispose();
  }

  void _emit() => widget.onChanged(<String, dynamic>{'front': _front.text.trim(), 'back': _back.text.trim()});

  @override
  Widget build(BuildContext context) {
    return _section(context, 'SCHEDA',
        help: 'Le flashcard si creano da sole dai termini approvati del Dizionario: qui puoi aggiungerne di tue.', <Widget>[
      TextField(controller: _front, decoration: _dec('Fronte')),
      const SizedBox(height: 8),
      TextField(controller: _back, minLines: 3, maxLines: 8, decoration: _dec('Retro', dense: false)),
    ]);
  }
}

// ------------------------------------------------------------------- numerica
class NumericaEditor extends StatefulWidget {
  final Map<String, dynamic> initial;
  final DataChanged onChanged;
  const NumericaEditor({super.key, required this.initial, required this.onChanged});
  @override
  State<NumericaEditor> createState() => _NumericaEditorState();
}

class _NumericaEditorState extends State<NumericaEditor> {
  final List<List<TextEditingController>> _steps = <List<TextEditingController>>[];
  static const List<String> _fields = <String>['label', 'answer', 'tolerance', 'unit', 'hint', 'check'];

  @override
  void initState() {
    super.initState();
    for (final Map<String, dynamic> s in asMapList(widget.initial['steps'])) {
      _add(s);
    }
    if (_steps.isEmpty) _add(const <String, dynamic>{});
    WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
  }

  void _add(Map<String, dynamic> s) {
    _steps.add(<TextEditingController>[
      for (final String f in _fields)
        TextEditingController(text: s[f] == null || '${s[f]}' == '0.0' && f == 'tolerance' ? '' : _fmt(s[f]))..addListener(_emit),
    ]);
  }

  String _fmt(dynamic v) {
    if (v is double && v == v.roundToDouble()) return v.toInt().toString();
    return '$v';
  }

  @override
  void dispose() {
    for (final List<TextEditingController> s in _steps) {
      for (final TextEditingController c in s) {
        c.dispose();
      }
    }
    super.dispose();
  }

  void _emit() => widget.onChanged(<String, dynamic>{
        'steps': <Map<String, dynamic>>[
          for (int i = 0; i < _steps.length; i++)
            <String, dynamic>{
              'id': 's${i + 1}',
              'label': _steps[i][0].text.trim(),
              'answer': _steps[i][1].text.trim(),
              'tolerance': double.tryParse(_steps[i][2].text.replaceAll(',', '.')) ?? 0,
              'unit': _steps[i][3].text.trim(),
              'hint': _steps[i][4].text.trim(),
              'check': _steps[i][5].text.trim(),
            },
        ],
      });

  @override
  Widget build(BuildContext context) {
    return _section(context, 'PASSAGGI', help: 'Uno o più valori da calcolare. La tolleranza è assoluta (es. 0,01).', <Widget>[
      for (int i = 0; i < _steps.length; i++)
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: context.palette.pureWhite.withValues(alpha: 0.08)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: <Widget>[
            Row(children: <Widget>[
              Expanded(child: TextField(controller: _steps[i][0], decoration: _dec('Passaggio ${i + 1}: cosa calcolare'))),
              IconButton(
                tooltip: 'Togli',
                onPressed: _steps.length <= 1 ? null : () => setState(() {
                  for (final TextEditingController c in _steps.removeAt(i)) {
                    c.dispose();
                  }
                  _emit();
                }),
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: <Widget>[
              Expanded(child: TextField(controller: _steps[i][1], decoration: _dec('Risultato'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _steps[i][2], decoration: _dec('± tolleranza'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _steps[i][3], decoration: _dec('Unità'))),
            ]),
            const SizedBox(height: 8),
            TextField(controller: _steps[i][4], decoration: _dec('Suggerimento (facoltativo)')),
            const SizedBox(height: 8),
            TextField(controller: _steps[i][5], decoration: _dec('Verifica mostrata se giusto (es. 2³ = 8 ≥ 6)')),
          ]),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _steps.length >= 8 ? null : () => setState(() => _add(const <String, dynamic>{})),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Aggiungi passaggio'),
        ),
      ),
    ]);
  }
}

// ------------------------------------------------------------------- codice
class CodiceEditor extends StatefulWidget {
  final Map<String, dynamic> initial;
  final DataChanged onChanged;
  const CodiceEditor({super.key, required this.initial, required this.onChanged});
  @override
  State<CodiceEditor> createState() => _CodiceEditorState();
}

class _CodiceEditorState extends State<CodiceEditor> {
  late final TextEditingController _function = TextEditingController(text: widget.initial['function']?.toString() ?? '');
  late final TextEditingController _starter = TextEditingController(text: widget.initial['starter']?.toString() ?? '');
  late final TextEditingController _forbidden =
      TextEditingController(text: asStringList(widget.initial['forbidden']).join(', '));
  final List<_Row> _tests = <_Row>[];

  @override
  void initState() {
    super.initState();
    for (final Map<String, dynamic> t in asMapList(widget.initial['tests'])) {
      _tests.add(_Row(_newKey(), a: t['call']?.toString() ?? '', b: t['expected']?.toString() ?? '', flag: t['hidden'] == true));
    }
    while (_tests.length < 2) {
      _tests.add(_Row(_newKey(), flag: _tests.isNotEmpty));
    }
    for (final TextEditingController c in <TextEditingController>[_function, _starter, _forbidden]) {
      c.addListener(_emit);
    }
    for (final _Row r in _tests) {
      r.a.addListener(_emit);
      r.b.addListener(_emit);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
  }

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[_function, _starter, _forbidden]) {
      c.dispose();
    }
    for (final _Row r in _tests) {
      r.dispose();
    }
    super.dispose();
  }

  void _emit() => widget.onChanged(<String, dynamic>{
        'language': 'python',
        'function': _function.text.trim(),
        'starter': _starter.text,
        'forbidden': _splitList(_forbidden.text),
        'tests': <Map<String, dynamic>>[
          for (final _Row r in _tests)
            if (r.a.text.trim().isNotEmpty) <String, dynamic>{'call': r.a.text.trim(), 'expected': r.b.text.trim(), 'hidden': r.flag},
        ],
      });

  @override
  Widget build(BuildContext context) {
    return _section(context, 'CODICE E TEST (PYTHON)',
        help: 'Il codice dello studente gira solo nel servizio isolato. Almeno un test visibile; i test nascosti evitano soluzioni “su misura”.',
        <Widget>[
          TextField(controller: _function, decoration: _dec('Nome della funzione (es. massimo)')),
          const SizedBox(height: 8),
          TextField(
            controller: _starter,
            minLines: 4,
            maxLines: 12,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            decoration: _dec('Codice di partenza', dense: false),
          ),
          const SizedBox(height: 8),
          TextField(controller: _forbidden, decoration: _dec('Da non usare (es. max(, sorted()')),
          const SizedBox(height: 12),
          for (final _Row r in _tests)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: <Widget>[
                Expanded(flex: 3, child: TextField(controller: r.a, style: const TextStyle(fontFamily: 'monospace'),
                    decoration: _dec('Chiamata (es. massimo([3, 9, 2]))'))),
                const SizedBox(width: 6),
                Expanded(flex: 2, child: TextField(controller: r.b, style: const TextStyle(fontFamily: 'monospace'),
                    decoration: _dec('Risultato atteso'))),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('Nascosto'),
                  selected: r.flag,
                  onSelected: (bool v) {
                    setState(() => r.flag = v);
                    _emit();
                  },
                ),
                IconButton(
                  tooltip: 'Togli',
                  onPressed: _tests.length <= 1 ? null : () => setState(() {
                    _tests.remove(r);
                    r.dispose();
                    _emit();
                  }),
                  icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
                ),
              ]),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _tests.length >= 20
                  ? null
                  : () => setState(() => _tests.add(_Row(_newKey())
                    ..a.addListener(_emit)
                    ..b.addListener(_emit))),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Aggiungi test'),
            ),
          ),
        ]);
  }
}

// ------------------------------------------------------------------- grafo
class GrafoEditor extends StatefulWidget {
  final Map<String, dynamic> initial;
  final DataChanged onChanged;
  const GrafoEditor({super.key, required this.initial, required this.onChanged});
  @override
  State<GrafoEditor> createState() => _GrafoEditorState();
}

class _GrafoEditorState extends State<GrafoEditor> {
  String _task = 'dijkstra';
  late final TextEditingController _nodes;
  late final TextEditingController _edges;
  late final TextEditingController _source;

  @override
  void initState() {
    super.initState();
    _task = widget.initial['task']?.toString() ?? 'dijkstra';
    _nodes = TextEditingController(
        text: asMapList(widget.initial['nodes']).map((Map<String, dynamic> n) => '${n['id']} ${n['x']} ${n['y']}').join('\n'))
      ..addListener(_emit);
    _edges = TextEditingController(
        text: asMapList(widget.initial['edges']).map((Map<String, dynamic> e) => '${e['from']} ${e['to']} ${e['w'] ?? 1}').join('\n'))
      ..addListener(_emit);
    _source = TextEditingController(text: widget.initial['source']?.toString() ?? '')..addListener(_emit);
    WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
  }

  @override
  void dispose() {
    _nodes.dispose();
    _edges.dispose();
    _source.dispose();
    super.dispose();
  }

  void _emit() {
    final List<Map<String, dynamic>> nodes = <Map<String, dynamic>>[];
    for (final String line in _nodes.text.split('\n')) {
      final List<String> parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length >= 3) {
        nodes.add(<String, dynamic>{
          'id': parts[0],
          'label': parts[0],
          'x': double.tryParse(parts[1].replaceAll(',', '.')) ?? 0.5,
          'y': double.tryParse(parts[2].replaceAll(',', '.')) ?? 0.5,
        });
      }
    }
    final List<Map<String, dynamic>> edges = <Map<String, dynamic>>[];
    for (final String line in _edges.text.split('\n')) {
      final List<String> parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        edges.add(<String, dynamic>{'from': parts[0], 'to': parts[1], 'w': parts.length > 2 ? int.tryParse(parts[2]) ?? 1 : 1});
      }
    }
    widget.onChanged(<String, dynamic>{
      'task': _task,
      'directed': false,
      'nodes': nodes,
      'edges': edges,
      'source': _source.text.trim().isEmpty && nodes.isNotEmpty ? nodes.first['id'] : _source.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return _section(context, 'GRAFO', help: 'Più semplice con “Genera varianti”: ogni studente riceve un grafo diverso. Qui puoi disegnarne uno fisso.', <Widget>[
      SegmentedButton<String>(
        segments: const <ButtonSegment<String>>[
          ButtonSegment<String>(value: 'dijkstra', label: Text('Dijkstra')),
          ButtonSegment<String>(value: 'bfs', label: Text('BFS')),
          ButtonSegment<String>(value: 'dfs', label: Text('DFS')),
        ],
        selected: <String>{_task},
        onSelectionChanged: (Set<String> v) {
          setState(() => _task = v.first);
          _emit();
        },
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _nodes,
        minLines: 3,
        maxLines: 10,
        style: const TextStyle(fontFamily: 'monospace'),
        decoration: _dec('Nodi: nome x y (x e y tra 0 e 1), uno per riga', hint: 'u 0.1 0.5\nv 0.4 0.2', dense: false),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _edges,
        minLines: 3,
        maxLines: 12,
        style: const TextStyle(fontFamily: 'monospace'),
        decoration: _dec('Archi: da a peso, uno per riga', hint: 'u v 2\nv w 1', dense: false),
      ),
      const SizedBox(height: 8),
      TextField(controller: _source, decoration: _dec('Nodo di partenza (vuoto = il primo)')),
    ]);
  }
}

// ------------------------------------------------------------------- traccia
class TracciaEditor extends StatefulWidget {
  final Map<String, dynamic> initial;
  final DataChanged onChanged;
  const TracciaEditor({super.key, required this.initial, required this.onChanged});
  @override
  State<TracciaEditor> createState() => _TracciaEditorState();
}

/// Tabella: una cella che inizia con "?" è da completare.
///   ?SYN_SENT                         risposta libera
///   ?SYN_SENT | LISTEN, ESTABLISHED   a scelta (la prima è quella giusta)
class _TracciaEditorState extends State<TracciaEditor> {
  late final TextEditingController _columns;
  late final TextEditingController _rows;
  bool _rowByRow = true;

  @override
  void initState() {
    super.initState();
    _rowByRow = widget.initial['row_by_row'] != false;
    _columns = TextEditingController(text: asStringList(widget.initial['columns']).join(' ; '))..addListener(_emit);
    final List<String> lines = <String>[];
    for (final dynamic row in (widget.initial['rows'] as List?) ?? const <dynamic>[]) {
      if (row is! List) continue;
      lines.add(row.map((dynamic cell) {
        if (cell is Map) {
          final List<String> accepted = asStringList(cell['accepted']);
          final List<String> others = asStringList(cell['options']).where((String o) => !accepted.contains(o)).toList();
          return '?${accepted.join(' / ')}${others.isEmpty ? '' : ' | ${others.join(', ')}'}';
        }
        return '$cell';
      }).join(' ; '));
    }
    _rows = TextEditingController(text: lines.join('\n'))..addListener(_emit);
    WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
  }

  @override
  void dispose() {
    _columns.dispose();
    _rows.dispose();
    super.dispose();
  }

  void _emit() {
    final List<String> columns = _columns.text.split(';').map((String s) => s.trim()).where((String s) => s.isNotEmpty).toList();
    final List<List<dynamic>> rows = <List<dynamic>>[];
    for (final String line in _rows.text.split('\n')) {
      if (line.trim().isEmpty) continue;
      rows.add(line.split(';').map((String raw) {
        final String cell = raw.trim();
        if (!cell.startsWith('?')) return cell;
        final List<String> parts = cell.substring(1).split('|');
        final List<String> accepted = parts.first.split('/').map((String s) => s.trim()).where((String s) => s.isNotEmpty).toList();
        final List<String> others = parts.length > 1 ? _splitList(parts[1]) : <String>[];
        return <String, dynamic>{
          'blank': true,
          'accepted': accepted,
          'options': others.isEmpty ? <String>[] : <String>[...accepted.take(1), ...others],
        };
      }).toList());
    }
    widget.onChanged(<String, dynamic>{'columns': columns, 'rows': rows, 'row_by_row': _rowByRow});
  }

  @override
  Widget build(BuildContext context) {
    return _section(context, 'TABELLA', help: 'Separa le celle con “;”. Una cella che inizia con “?” è da completare: '
        '“?SYN_SENT” (risposta libera) oppure “?SYN_SENT | LISTEN, ESTABLISHED” (a scelta).', <Widget>[
      TextField(controller: _columns, decoration: _dec('Colonne', hint: 'T ; Ricevuto ; Inviato ; Stato')),
      const SizedBox(height: 8),
      TextField(
        controller: _rows,
        minLines: 4,
        maxLines: 16,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        decoration: _dec('Righe (una per riga)', hint: '0 ; – ; SYN ; ?SYN_SENT | LISTEN, ESTABLISHED', dense: false),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _rowByRow,
        title: const Text('Una riga alla volta (ogni riga giusta sblocca la successiva)'),
        onChanged: (bool v) {
          setState(() => _rowByRow = v);
          _emit();
        },
      ),
    ]);
  }
}

// ------------------------------------------------------------------- diagramma
class DiagrammaEditor extends StatefulWidget {
  final Map<String, dynamic> initial;
  final List<Map<String, dynamic>> attachments;
  final DataChanged onChanged;
  const DiagrammaEditor({super.key, required this.initial, required this.attachments, required this.onChanged});
  @override
  State<DiagrammaEditor> createState() => _DiagrammaEditorState();
}

/// Due modi: un diagramma disegnato dall'app (nodi e collegamenti) oppure
/// un'immagine caricata con le zone da toccare (coordinate tra 0 e 1).
class _DiagrammaEditorState extends State<DiagrammaEditor> {
  bool _image = false;
  String? _imageId;
  late final TextEditingController _nodes;
  late final TextEditingController _edges;
  late final TextEditingController _regions;
  late final TextEditingController _correct;
  late final TextEditingController _ratio;

  static const String _shapesHelp = 'Forme: rect, circle, cloud, device. Icone: computer, switch, router, cloud, server, phone, database, firewall, cpu.';

  @override
  void initState() {
    super.initState();
    final Map<String, dynamic> scene = asMap(widget.initial['scene']);
    _imageId = widget.initial['image_attachment_id']?.toString();
    _image = scene.isEmpty && _imageId != null;
    _nodes = TextEditingController(
        text: asMapList(scene['nodes'])
            .map((Map<String, dynamic> n) => '${n['id']} ; ${n['label']} ; ${n['x']} ; ${n['y']} ; ${n['shape'] ?? 'rect'} ; ${n['icon'] ?? ''}')
            .join('\n'))
      ..addListener(_emit);
    _edges = TextEditingController(
        text: asMapList(scene['edges']).map((Map<String, dynamic> e) => '${e['from']} ${e['to']}').join('\n'))
      ..addListener(_emit);
    _regions = TextEditingController(
        text: _image
            ? asMapList(widget.initial['regions'])
                .map((Map<String, dynamic> r) => '${r['id']} ; ${r['x']} ; ${r['y']} ; ${r['w']} ; ${r['h']} ; ${r['label'] ?? ''}')
                .join('\n')
            : '')
      ..addListener(_emit);
    _correct = TextEditingController(text: asStringList(widget.initial['correct']).join(', '))..addListener(_emit);
    _ratio = TextEditingController(text: '${scene['ratio'] ?? 1.6}')..addListener(_emit);
    WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
  }

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[_nodes, _edges, _regions, _correct, _ratio]) {
      c.dispose();
    }
    super.dispose();
  }

  double _d(String v) => double.tryParse(v.trim().replaceAll(',', '.')) ?? 0;

  void _emit() {
    final Map<String, dynamic> data = <String, dynamic>{'correct': _splitList(_correct.text)};
    if (_image) {
      data['image_attachment_id'] = _imageId;
      data['regions'] = <Map<String, dynamic>>[
        for (final String line in _regions.text.split('\n'))
          if (line.split(';').length >= 5)
            () {
              final List<String> p = line.split(';');
              return <String, dynamic>{
                'id': p[0].trim(), 'x': _d(p[1]), 'y': _d(p[2]), 'w': _d(p[3]), 'h': _d(p[4]),
                if (p.length > 5) 'label': p[5].trim(),
              };
            }(),
      ];
    } else {
      data['scene'] = <String, dynamic>{
        'ratio': _d(_ratio.text) <= 0 ? 1.6 : _d(_ratio.text),
        'nodes': <Map<String, dynamic>>[
          for (final String line in _nodes.text.split('\n'))
            if (line.split(';').length >= 4)
              () {
                final List<String> p = line.split(';');
                return <String, dynamic>{
                  'id': p[0].trim(), 'label': p[1].trim(), 'x': _d(p[2]), 'y': _d(p[3]),
                  'shape': p.length > 4 && p[4].trim().isNotEmpty ? p[4].trim() : 'rect',
                  'icon': p.length > 5 ? p[5].trim() : '',
                };
              }(),
        ],
        'edges': <Map<String, dynamic>>[
          for (final String line in _edges.text.split('\n'))
            if (line.trim().split(RegExp(r'\s+')).length >= 2)
              <String, dynamic>{'from': line.trim().split(RegExp(r'\s+'))[0], 'to': line.trim().split(RegExp(r'\s+'))[1]},
        ],
      };
    }
    widget.onChanged(data);
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> images = widget.attachments
        .where((Map<String, dynamic> a) => (a['mime_type']?.toString() ?? '').startsWith('image/'))
        .toList();
    return _section(context, 'DIAGRAMMA', <Widget>[
      SegmentedButton<bool>(
        segments: const <ButtonSegment<bool>>[
          ButtonSegment<bool>(value: false, label: Text('Disegnato'), icon: Icon(Icons.account_tree_outlined)),
          ButtonSegment<bool>(value: true, label: Text('Immagine'), icon: Icon(Icons.image_outlined)),
        ],
        selected: <bool>{_image},
        onSelectionChanged: (Set<bool> v) {
          setState(() => _image = v.first);
          _emit();
        },
      ),
      const SizedBox(height: 10),
      if (_image) ...<Widget>[
        if (images.isEmpty)
          Text('Carica prima un’immagine negli allegati (ruolo “diagramma”).', style: SlText.muted(context.palette))
        else
          DropdownButtonFormField<String?>(
            value: images.any((Map<String, dynamic> a) => a['id'] == _imageId) ? _imageId : null,
            isExpanded: true,
            decoration: _dec('Immagine'),
            items: <DropdownMenuItem<String?>>[
              for (final Map<String, dynamic> a in images)
                DropdownMenuItem<String?>(value: a['id'].toString(), child: Text('${a['original_name']}', overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (String? v) {
              setState(() => _imageId = v);
              _emit();
            },
          ),
        const SizedBox(height: 8),
        TextField(
          controller: _regions,
          minLines: 3,
          maxLines: 10,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          decoration: _dec('Zone: id ; x ; y ; larghezza ; altezza ; nome (valori tra 0 e 1)',
              hint: 'router ; 0.55 ; 0.40 ; 0.15 ; 0.20 ; Router', dense: false),
        ),
      ] else ...<Widget>[
        TextField(
          controller: _nodes,
          minLines: 3,
          maxLines: 12,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          decoration: _dec('Elementi: id ; nome ; x ; y ; forma ; icona', hint: 'rt ; Router ; 0.6 ; 0.5 ; circle ; router', dense: false),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Text(_shapesHelp, style: SlText.muted(context.palette).copyWith(fontSize: 11)),
        ),
        TextField(
          controller: _edges,
          minLines: 2,
          maxLines: 10,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          decoration: _dec('Collegamenti: id id, uno per riga', hint: 'sw rt', dense: false),
        ),
        const SizedBox(height: 8),
        TextField(controller: _ratio, decoration: _dec('Proporzione larghezza/altezza (es. 1.6)')),
      ],
      const SizedBox(height: 8),
      TextField(controller: _correct, decoration: _dec('Elementi o zone giusti (id separati da virgola)')),
    ]);
  }
}
