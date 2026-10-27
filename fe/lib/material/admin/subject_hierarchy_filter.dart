import 'package:flutter/material.dart';

/// Filtro materie a cascata: Ateneo → Dipartimento → Corso → Livello → Anno → Materia.
///
/// Ogni livello mostra solo le voci compatibili con le scelte precedenti;
/// cambiando un livello, quelli successivi tornano a «Tutti». Se un livello ha
/// una sola voce possibile, viene mostrata già scelta.
/// I dati arrivano da GET /admin/material-storage/drive/import-options
/// (campi: id, name, university, department, course, level, year).
class SubjectHierarchyFilter extends StatefulWidget {
  final List<Map<String, dynamic>> subjects;
  final int? subjectId;
  final ValueChanged<int?> onChanged;
  /// In un dialog conviene una colonna; nella pagina una griglia.
  final bool forceColumn;

  const SubjectHierarchyFilter({
    super.key,
    required this.subjects,
    required this.subjectId,
    required this.onChanged,
    this.forceColumn = false,
  });

  @override
  State<SubjectHierarchyFilter> createState() => _SubjectHierarchyFilterState();
}

String subjectLevelLabel(String level) => switch (level) {
      'triennale' => 'Triennale',
      'magistrale' => 'Magistrale',
      'ciclo_unico' => 'Magistrale a ciclo unico',
      _ => 'Non indicato',
    };

String subjectYearLabel(int year) => switch (year) {
      1 => 'Primo anno',
      2 => 'Secondo anno',
      3 => 'Terzo anno',
      4 => 'Quarto anno',
      5 => 'Quinto anno',
      6 => 'Sesto anno',
      0 => 'Anno non indicato',
      _ => '$year° anno',
    };

/// Descrizione breve di una materia (per righe e campi).
String subjectSummary(Map<String, dynamic>? s) {
  if (s == null) return 'Scegli una materia';
  final year = int.tryParse('${s['year']}') ?? 0;
  return [
    '${s['name'] ?? ''}',
    '${s['course'] ?? ''}',
    if (year > 0) subjectYearLabel(year),
  ].where((x) => x.trim().isNotEmpty).join(' · ');
}

class _SubjectHierarchyFilterState extends State<SubjectHierarchyFilter> {
  String? _university;
  String? _department;
  String? _course;
  String? _level;
  int? _year;

  static String _s(Object? v) => (v ?? '').toString().trim();
  static int _y(Object? v) => int.tryParse('$v') ?? 0;

  @override
  void initState() {
    super.initState();
    _syncFromSubject();
  }

  @override
  void didUpdateWidget(covariant SubjectHierarchyFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subjectId != widget.subjectId && widget.subjectId != null) {
      final current = _selectedSubject;
      // Se la materia scelta altrove non rientra nei filtri attuali, i filtri la seguono.
      if (current == null || !_matches(current)) _syncFromSubject();
    }
  }

  Map<String, dynamic>? get _selectedSubject {
    for (final s in widget.subjects) {
      if (_y(s['id']) == widget.subjectId) return s;
    }
    return null;
  }

  void _syncFromSubject() {
    final s = _selectedSubject;
    if (s == null) return;
    _university = _s(s['university']);
    _department = _s(s['department']);
    _course = _s(s['course']);
    _level = _s(s['level']);
    _year = _y(s['year']);
  }

  bool _matches(Map<String, dynamic> s, {int depth = 5}) =>
      (depth < 1 || _university == null || _s(s['university']) == _university) &&
      (depth < 2 || _department == null || _s(s['department']) == _department) &&
      (depth < 3 || _course == null || _s(s['course']) == _course) &&
      (depth < 4 || _level == null || _s(s['level']) == _level) &&
      (depth < 5 || _year == null || _y(s['year']) == _year);

  List<String> _options(int depth, String Function(Map<String, dynamic>) read) {
    final values = <String>{
      for (final s in widget.subjects)
        if (_matches(s, depth: depth)) read(s),
    }.toList();
    values.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return values;
  }

  void _pick(void Function() change) {
    setState(change);
    final candidates = widget.subjects.where((s) => _matches(s)).toList();
    final current = _selectedSubject;
    if (current != null && _matches(current)) return;
    // La materia scelta non è più compatibile: se ne resta una sola la si sceglie, altrimenti nessuna.
    widget.onChanged(candidates.length == 1 ? _y(candidates.first['id']) : null);
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<T> options,
    required String Function(T) text,
    required ValueChanged<T?> onChanged,
    bool allowAll = true,
    String allLabel = 'Tutti',
  }) {
    T? shown;
    if (value != null && options.contains(value)) {
      shown = value;
    } else if (allowAll && options.length == 1) {
      shown = options.first;
    }
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          isDense: true,
          value: shown,
          hint: Text(allowAll ? allLabel : 'Scegli', overflow: TextOverflow.ellipsis),
          items: [
            if (allowAll && options.length > 1)
              DropdownMenuItem<T>(value: null, child: Text(allLabel, overflow: TextOverflow.ellipsis)),
            for (final option in options)
              DropdownMenuItem<T>(value: option, child: Text(text(option), overflow: TextOverflow.ellipsis)),
          ],
          onChanged: options.isEmpty ? null : onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final universities = _options(0, (s) => _s(s['university']));
    final departments = _options(1, (s) => _s(s['department']));
    final courses = _options(2, (s) => _s(s['course']));
    final levels = _options(3, (s) => _s(s['level']));
    final years = {
      for (final s in widget.subjects)
        if (_matches(s, depth: 4)) _y(s['year']),
    }.toList()
      ..sort();
    final subjects = widget.subjects.where((s) => _matches(s)).toList()
      ..sort((a, b) => _s(a['name']).toLowerCase().compareTo(_s(b['name']).toLowerCase()));
    final selected = subjects.any((s) => _y(s['id']) == widget.subjectId) ? widget.subjectId : null;

    final fields = <Widget>[
      _dropdown<String>(
        label: 'Ateneo',
        value: _university,
        options: universities,
        text: (v) => v.isEmpty ? 'Non indicato' : v,
        onChanged: (v) => _pick(() {
          _university = v;
          _department = _course = _level = null;
          _year = null;
        }),
      ),
      _dropdown<String>(
        label: 'Dipartimento',
        value: _department,
        options: departments,
        text: (v) => v.isEmpty ? 'Non indicato' : v,
        onChanged: (v) => _pick(() {
          _department = v;
          _course = _level = null;
          _year = null;
        }),
      ),
      _dropdown<String>(
        label: 'Corso',
        value: _course,
        options: courses,
        text: (v) => v.isEmpty ? 'Non indicato' : v,
        onChanged: (v) => _pick(() {
          _course = v;
          _level = null;
          _year = null;
        }),
      ),
      _dropdown<String>(
        label: 'Livello',
        value: _level,
        options: levels,
        text: subjectLevelLabel,
        onChanged: (v) => _pick(() {
          _level = v;
          _year = null;
        }),
      ),
      _dropdown<int>(
        label: 'Anno',
        value: _year,
        options: years,
        text: subjectYearLabel,
        onChanged: (v) => _pick(() => _year = v),
      ),
      _dropdown<int>(
        label: 'Materia',
        value: selected,
        options: [for (final s in subjects) _y(s['id'])],
        text: (id) => _s(subjects.firstWhere((s) => _y(s['id']) == id)['name']),
        allowAll: false,
        onChanged: (v) => widget.onChanged(v),
      ),
    ];

    return LayoutBuilder(builder: (context, box) {
      if (widget.forceColumn || box.maxWidth < 520) {
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var i = 0; i < fields.length; i++) ...[if (i > 0) const SizedBox(height: 8), fields[i]],
        ]);
      }
      final columns = box.maxWidth >= 1000 ? 3 : 2;
      final width = (box.maxWidth - 8 * (columns - 1)) / columns;
      return Wrap(spacing: 8, runSpacing: 8, children: [
        for (final f in fields) SizedBox(width: width, child: f),
      ]);
    });
  }
}

/// Campo «Materia» che apre il filtro a cascata in un dialog.
class SubjectPickerField extends StatelessWidget {
  final List<Map<String, dynamic>> subjects;
  final int? value;
  final ValueChanged<int> onChanged;
  final String label;

  const SubjectPickerField({
    super.key,
    required this.subjects,
    required this.value,
    required this.onChanged,
    this.label = 'Materia',
  });

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? current;
    for (final s in subjects) {
      if (int.tryParse('${s['id']}') == value) current = s;
    }
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final chosen = await showSubjectPicker(context, subjects: subjects, initial: value);
        if (chosen != null) onChanged(chosen);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          suffixIcon: const Icon(Icons.filter_list_rounded),
        ),
        child: Text(subjectSummary(current), maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

Future<int?> showSubjectPicker(BuildContext context,
    {required List<Map<String, dynamic>> subjects, int? initial}) {
  int? selected = initial;
  return showDialog<int>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, update) {
        final width = MediaQuery.sizeOf(ctx).width;
        return AlertDialog(
          title: const Text('Scegli la materia'),
          content: SizedBox(
            width: width < 560 ? width - 48 : 480,
            child: SingleChildScrollView(
              child: SubjectHierarchyFilter(
                subjects: subjects,
                subjectId: selected,
                forceColumn: true,
                onChanged: (v) => update(() => selected = v),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
            FilledButton(
              onPressed: selected == null ? null : () => Navigator.pop(ctx, selected),
              child: const Text('Usa questa materia'),
            ),
          ],
        );
      },
    ),
  );
}
