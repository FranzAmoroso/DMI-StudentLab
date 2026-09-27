import 'package:flutter/material.dart';

import 'package:fe/theme/app_palette.dart';
import 'package:fe/widgets/studentlab_ui/studentlab_ui.dart';
import 'package:fe/quiz/exercises/exercise_api_service.dart';
import 'package:fe/quiz/exercises/exercise_models.dart';
import 'package:fe/quiz/exercises/exercise_session_page.dart';
import 'package:fe/quiz/exercises/flashcard_session_page.dart';

/// Scelta degli esercizi di una materia (canvas: Esercizi · catalogo dei tipi).
class ExerciseCatalogPage extends StatefulWidget {
  final String department;
  final String course;
  final String subject;
  final String? subjectLabel;
  final List<String> initialArguments;

  const ExerciseCatalogPage({
    super.key,
    required this.department,
    required this.course,
    required this.subject,
    this.subjectLabel,
    this.initialArguments = const <String>[],
  });

  @override
  State<ExerciseCatalogPage> createState() => _ExerciseCatalogPageState();
}

class _ExerciseCatalogPageState extends State<ExerciseCatalogPage> {
  final ExerciseApiService _api = ExerciseApiService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _types = <Map<String, dynamic>>[];
  List<String> _arguments = <String>[];
  final Set<String> _selectedTypes = <String>{};
  late final Set<String> _selectedArguments = widget.initialArguments.toSet();
  int _count = 10;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final Map<String, dynamic> data = await _api.catalog(widget.department, widget.course, widget.subject);
      _types = asMapList(data['types']).where((Map<String, dynamic> t) => kExerciseTypes.contains(t['type'])).toList();
      _arguments = asStringList(data['arguments']);
      _selectedArguments.removeWhere((String a) => !_arguments.contains(a));
      if (_selectedTypes.isEmpty) {
        _selectedTypes.addAll(_types
            .where((Map<String, dynamic> t) => t['available'] == true && t['type'] != 'flashcard')
            .map((Map<String, dynamic> t) => t['type'].toString()));
      }
    } catch (error) {
      _error = cleanError(error, 'Catalogo non disponibile.');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _start() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ExerciseSessionPage.practice(
        department: widget.department,
        course: widget.course,
        subject: widget.subject,
        title: widget.subjectLabel ?? 'Esercizi',
        types: _selectedTypes.toList(),
        arguments: _selectedArguments.toList(),
        count: _count,
      ),
    ));
  }

  void _flashcards() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => FlashcardSessionPage(
        department: widget.department,
        course: widget.course,
        subject: widget.subject,
        subjectLabel: widget.subjectLabel,
        arguments: _selectedArguments.toList(),
      ),
    ));
  }

  Widget _typeCard(BuildContext context, Map<String, dynamic> type) {
    final p = context.palette;
    final String id = type['type'].toString();
    final ExerciseTypeInfo info = exerciseInfo(id);
    final bool available = type['available'] == true;
    final bool selected = _selectedTypes.contains(id);
    final Color color = categoryColor(context, info.category);
    final int count = int.tryParse('${type['count'] ?? 0}') ?? 0;
    return Opacity(
      opacity: available ? 1 : 0.45,
      child: Material(
        color: selected ? color.withValues(alpha: 0.12) : p.eleganceMidnight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: selected ? color.withValues(alpha: 0.6) : p.pureWhite.withValues(alpha: 0.08)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: !available
              ? () {
                  final String reason = type['unavailable_reason']?.toString() ?? 'Nessun esercizio di questo tipo per la materia.';
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(reason)));
                }
              : () => setState(() => selected ? _selectedTypes.remove(id) : _selectedTypes.add(id)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Icon(info.icon, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Text(info.label, style: TextStyle(color: p.pureWhite, fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(info.purpose, maxLines: 2, overflow: TextOverflow.ellipsis, style: SlText.muted(p).copyWith(fontSize: 11.5)),
                  const SizedBox(height: 6),
                  Row(children: <Widget>[
                    Text(categoryLabel(info.category),
                        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    const SizedBox(width: 8),
                    Text(type['generated'] == true ? 'sempre nuovi' : '$count',
                        style: SlText.muted(p).copyWith(fontSize: 11, fontFamily: 'monospace')),
                  ]),
                ]),
              ),
              Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: selected ? color : p.pureWhite.withValues(alpha: 0.3), size: 20),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final Map<String, dynamic>? flash =
        _types.where((Map<String, dynamic> t) => t['type'] == 'flashcard').firstOrNull;
    return Scaffold(
      backgroundColor: p.darkElegance,
      appBar: AppBar(
        backgroundColor: p.eleganceMidnight,
        foregroundColor: p.pureWhite,
        title: Text(widget.subjectLabel ?? 'Esercizi'),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: p.skyBlue))
          : _error != null
              ? Padding(padding: const EdgeInsets.all(16), child: SlErrorCard(title: 'Attenzione', message: _error!, onRetry: _load))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: ListView(padding: const EdgeInsets.all(16), children: <Widget>[
                      if (flash != null && flash['available'] == true)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF08CFF).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF08CFF).withValues(alpha: 0.35)),
                          ),
                          child: Row(children: <Widget>[
                            const Icon(Icons.style_outlined, color: Color(0xFFF08CFF)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                                Text('Flashcard', style: TextStyle(color: p.pureWhite, fontWeight: FontWeight.w700)),
                                Text(
                                  '${flash['count']} schede · ripassi quelle che stai per dimenticare'
                                  '${_api.isLoggedIn ? '' : ' (salvato su questo telefono)'}',
                                  style: SlText.muted(p).copyWith(fontSize: 12),
                                ),
                              ]),
                            ),
                            FilledButton(onPressed: _flashcards, child: const Text('Ripassa')),
                          ]),
                        ),
                      SlOverline('TIPI DI ESERCIZIO'),
                      const SizedBox(height: 8),
                      LayoutBuilder(builder: (BuildContext context, BoxConstraints box) {
                        final int columns = box.maxWidth >= 620 ? 2 : 1;
                        final double width = (box.maxWidth - (columns - 1) * 10) / columns;
                        return Wrap(spacing: 10, runSpacing: 10, children: <Widget>[
                          for (final Map<String, dynamic> t in _types.where((Map<String, dynamic> t) => t['type'] != 'flashcard'))
                            SizedBox(width: width, child: _typeCard(context, t)),
                        ]);
                      }),
                      if (_arguments.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 20),
                        Row(children: <Widget>[
                          SlOverline('ARGOMENTI'),
                          const Spacer(),
                          TextButton(
                            onPressed: () => setState(_selectedArguments.clear),
                            child: Text(_selectedArguments.isEmpty ? 'Tutti' : 'Tutti gli argomenti'),
                          ),
                        ]),
                        Wrap(spacing: 8, runSpacing: 8, children: <Widget>[
                          for (final String a in _arguments)
                            FilterChip(
                              label: Text(a),
                              selected: _selectedArguments.contains(a),
                              onSelected: (bool v) => setState(() => v ? _selectedArguments.add(a) : _selectedArguments.remove(a)),
                            ),
                        ]),
                      ],
                      const SizedBox(height: 20),
                      SlOverline('QUANTI'),
                      const SizedBox(height: 4),
                      Row(children: <Widget>[
                        IconButton(
                          tooltip: 'Meno',
                          onPressed: _count <= 3 ? null : () => setState(() => _count -= 1),
                          icon: const Icon(Icons.remove_rounded),
                        ),
                        Text('$_count', style: TextStyle(color: p.pureWhite, fontSize: 20, fontWeight: FontWeight.w700)),
                        IconButton(
                          tooltip: 'Più',
                          onPressed: _count >= 30 ? null : () => setState(() => _count += 1),
                          icon: const Icon(Icons.add_rounded),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _api.isLoggedIn
                                ? 'Salvati nello storico: gli errori vanno nel tuo Ripasso.'
                                : 'Senza account i risultati restano su questo telefono.',
                            style: SlText.muted(p).copyWith(fontSize: 12),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: _selectedTypes.isEmpty ? null : _start,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text(_selectedTypes.isEmpty ? 'Scegli almeno un tipo' : 'Inizia $_count esercizi'),
                        ),
                      ),
                    ]),
                  ),
                ),
    );
  }
}
