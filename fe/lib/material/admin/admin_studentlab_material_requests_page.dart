import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_palette.dart';
import '../../widgets/studentlab_ui/studentlab_ui.dart';

/// Richieste di materiale indirizzate a StudentLab.
///
/// Desktop: colonne "Da gestire" / "Chiuse" + pannello di risposta a destra.
/// Mobile: filtro + elenco, la risposta si apre in una pagina dedicata.
/// Le richieste con stessa materia e stesso argomento vengono segnalate
/// ("+N studenti") così una risposta può soddisfarle tutte.
class AdminStudentLabMaterialRequestsPage extends StatefulWidget {
  const AdminStudentLabMaterialRequestsPage({super.key});

  @override
  State<AdminStudentLabMaterialRequestsPage> createState() =>
      _AdminStudentLabMaterialRequestsPageState();
}

class _AdminStudentLabMaterialRequestsPageState extends State<AdminStudentLabMaterialRequestsPage> {
  static const double _wideBreakpoint = 1100;

  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  String _filter = 'pending';
  int? _selectedId;
  int? _busyId;
  final TextEditingController _reply = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  int? _id(Map<String, dynamic> item) => int.tryParse(item['id']?.toString() ?? '');
  bool _isOpen(Map<String, dynamic> item) => (item['status']?.toString() ?? 'pending') == 'pending';

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final items = await _api.getStudentLabMaterialRequests();
      items.sort((a, b) => (b['created_at']?.toString() ?? '').compareTo(a['created_at']?.toString() ?? ''));
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
        if (_selectedId == null || !items.any((i) => _id(i) == _selectedId)) {
          final open = items.where(_isOpen);
          _selectedId = open.isNotEmpty ? _id(open.first) : (items.isNotEmpty ? _id(items.first) : null);
          _reply.clear();
        }
      });
    } catch (_) {
      if (mounted) setState(() { _error = 'Impossibile caricare le richieste.'; _loading = false; });
    }
  }

  String _groupKey(Map<String, dynamic> item) =>
      '${item['recipient_kind'] ?? 'studentlab'}|${item['subject_id'] ?? item['subject_name'] ?? ''}|${(item['topic']?.toString() ?? '').trim().toLowerCase()}';

  /// Altre richieste aperte uguali (stessa materia e argomento).
  List<Map<String, dynamic>> _similar(Map<String, dynamic> item) {
    final key = _groupKey(item);
    if ((item['topic']?.toString() ?? '').trim().isEmpty) return const [];
    return _items.where((i) => _id(i) != _id(item) && _isOpen(i) && _groupKey(i) == key).toList();
  }

  String _relative(dynamic value) {
    final d = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes.clamp(1, 59)} min fa';
    if (diff.inHours < 24) return '${diff.inHours} h fa';
    if (diff.inDays == 1) return 'ieri';
    if (diff.inDays < 7) return '${diff.inDays} gg fa';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  void _message(String text) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentMaterialBanner();
    messenger.showMaterialBanner(MaterialBanner(
      content: Text(text), leading: const Icon(Icons.info_outline),
      actions: [TextButton(onPressed: () => messenger.hideCurrentMaterialBanner(),
        child: const Text('Chiudi'))]));
  }

  Future<int?> _choosePublicMaterial(int subjectId, String recipientKind) async {
    try {
      final materials = (await _api.getAdminPublishedMaterials()).where((m) =>
        int.tryParse('${m['subject_id']}') == subjectId &&
        m['visibility_state'] == 'visible' &&
        m['audience_type'] == (recipientKind == 'teachers' ? 'course' : 'public') &&
        m['is_visible'] == true && m['drive_activation_pending'] != true &&
        (m['drive_file_id']?.toString().isNotEmpty ?? false)).toList();
      if (!mounted) return null;
      if (materials.isEmpty) {
        _message('Prima pubblica su Drive un materiale della materia visibile al corso o a tutti, secondo la richiesta.');
        return null;
      }
      return showModalBottomSheet<int>(context: context, isScrollControlled: true,
        builder: (sheetContext) => SafeArea(child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * .55,
          child: Column(children: [
            ListTile(title: Text(recipientKind == 'teachers' ? 'Materiale per tutto il corso' : 'Materiale pubblico su Drive'),
              subtitle: Text('Il file scelto sarà indicato nella risposta allo studente.')),
            Expanded(child: ListView(children: [for (final m in materials)
              ListTile(leading: const Icon(Icons.insert_drive_file_outlined),
                title: Text(m['title']?.toString() ?? m['original_name']?.toString() ?? 'Materiale'),
                subtitle: Text(m['original_name']?.toString() ?? ''),
                onTap: () => Navigator.pop(sheetContext,
                  int.tryParse('${m['id']}'))),
            ])),
          ]))));
    } catch (_) {
      _message('Impossibile caricare i materiali pubblicati. Riprova.');
      return null;
    }
  }

  Future<bool> _send(Map<String, dynamic> item, String action) async {
    final id = _id(item);
    final text = _reply.text.trim();
    if (id == null) return false;
    if (text.isEmpty) {
      _message('Scrivi una risposta per lo studente.');
      return false;
    }
    int? publicMaterialId;
    if (action == 'fulfilled') {
      final subjectId = int.tryParse('${item['subject_id']}');
      if (subjectId == null) return false;
      publicMaterialId = await _choosePublicMaterial(subjectId, item['recipient_kind']?.toString() ?? 'studentlab');
      if (publicMaterialId == null || !mounted) return false;
    }
    setState(() => _busyId = id);
    try {
      await _api.replyStudentLabMaterialRequest(id, action: action,
        message: text, publicMaterialId: publicMaterialId);
      _message(action == 'fulfilled' ? 'Richiesta soddisfatta.' : 'Richiesta chiusa come non disponibile.');
      _reply.clear();
      await _load();
      return true;
    } catch (error) {
      _message(slErrorMessage(error, fallback: 'Impossibile inviare la risposta. Riprova.'));
      return false;
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final open = _items.where(_isOpen).toList();
    final closed = _items.where((i) => !_isOpen(i)).toList();
    return Scaffold(
      backgroundColor: p.darkElegance,
      appBar: slAdminAppBar(context, title: 'Richieste a StudentLab', actions: <Widget>[
        IconButton(tooltip: 'Aggiorna', onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh_rounded)),
      ]),
      body: SafeArea(
        child: _loading && _items.isEmpty
            ? Center(child: CircularProgressIndicator(color: p.skyBlue))
            : _error != null
                ? Padding(padding: const EdgeInsets.all(16), child: SlErrorCard(title: _error!, message: 'Controlla la connessione e riprova.', onRetry: _load))
                : LayoutBuilder(builder: (context, constraints) {
                    final wide = constraints.maxWidth >= _wideBreakpoint;
                    if (!wide) return _narrow(open, closed);
                    final matches = _items.where((i) => _id(i) == _selectedId);
                    final Map<String, dynamic>? selected = matches.isNotEmpty ? matches.first : null;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
                        Expanded(child: _column('Da gestire', SlTone.warning, open)),
                        const SizedBox(width: 14),
                        Expanded(child: _column('Chiuse', SlTone.success, closed)),
                        const SizedBox(width: 14),
                        SizedBox(
                          width: 440,
                          child: selected == null
                              ? const SlEmptyState(icon: Icons.mark_email_read_outlined, title: 'Nessuna richiesta selezionata', message: 'Scegli una richiesta per rispondere.')
                              : _detail(selected),
                        ),
                      ]),
                    );
                  }),
      ),
    );
  }

  Widget _column(String title, SlTone tone, List<Map<String, dynamic>> items) {
    final p = context.palette;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
        child: Row(children: <Widget>[
          Container(width: 8, height: 8, decoration: BoxDecoration(color: tone.resolve(p), shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(color: p.pureWhite, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Text('${items.length}', style: SlText.mono(p, size: 12, color: p.pureWhite.withValues(alpha: 0.56))),
        ]),
      ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: <Widget>[
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(title == 'Da gestire' ? 'Nessuna richiesta da gestire.' : 'Nessuna richiesta chiusa.', style: SlText.muted(p)),
                )
              else
                for (final item in items) _card(item, wide: true),
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _narrow(List<Map<String, dynamic>> open, List<Map<String, dynamic>> closed) {
    final shown = _filter == 'pending' ? open : closed;
    return Column(children: <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: SlFilterBar<String>(
          selected: _filter,
          options: <SlFilterOption<String>>[
            SlFilterOption(value: 'pending', label: 'Da gestire', count: open.length),
            SlFilterOption(value: 'closed', label: 'Chiuse', count: closed.length),
          ],
          onSelected: (value) => setState(() => _filter = value),
        ),
      ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              if (shown.isEmpty)
                SlEmptyState(
                  icon: Icons.mark_email_read_outlined,
                  title: _filter == 'pending' ? 'Tutto gestito' : 'Nessuna richiesta chiusa',
                  message: _filter == 'pending' ? 'Non ci sono richieste in attesa di risposta.' : 'Le richieste a cui rispondi finiscono qui.',
                )
              else
                for (final item in shown) _card(item, wide: false),
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _card(Map<String, dynamic> item, {required bool wide}) {
    final p = context.palette;
    final id = _id(item);
    final selected = wide && id == _selectedId;
    final similar = _isOpen(item) ? _similar(item).length : 0;
    final status = item['status']?.toString();
    final fromTeacher = item['recipient_kind'] == 'teachers';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? p.eleganceDeepNavy : p.eleganceMidnight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: selected ? p.skyBlue.withValues(alpha: 0.40) : p.pureWhite.withValues(alpha: 0.08)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            setState(() { _selectedId = id; _reply.clear(); });
            if (!wide) {
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => Scaffold(
                backgroundColor: context.palette.darkElegance,
                appBar: slAdminAppBar(context, title: 'Richiesta', breadcrumb: 'ADMIN / RICHIESTE A STUDENTLAB'),
                body: SafeArea(child: Padding(padding: const EdgeInsets.all(12), child: _detail(item, popOnDone: true))),
              )));
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Text((item['topic']?.toString().trim().isNotEmpty ?? false) ? item['topic'].toString() : 'Materiale richiesto',
                  style: TextStyle(color: _isOpen(item) ? p.pureWhite : p.pureWhite.withValues(alpha: 0.80), fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(item['subject_name']?.toString() ?? 'Materia', style: SlText.muted(p)),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: <Widget>[
                if (status == 'fulfilled') const SlStatusBadge(label: 'Soddisfatta', tone: SlTone.success)
                else if (status == 'rejected') const SlStatusBadge(label: 'Non disponibile'),
                if (fromTeacher) SlStatusBadge(label: item['teacher_declined_at'] != null ? 'Docente non disponibile' : 'Anche al docente', tone: SlTone.violet),
                if (similar > 0) SlStatusBadge(label: '+$similar studenti', tone: SlTone.cyan),
                Text(<String>[
                  if ((item['student_name']?.toString() ?? '').isNotEmpty) item['student_name'].toString(),
                  _relative(item['created_at']),
                ].where((v) => v.isNotEmpty).join(' · '), style: SlText.mono(p, size: 11, color: p.pureWhite.withValues(alpha: 0.56))),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _detail(Map<String, dynamic> item, {bool popOnDone = false}) {
    final p = context.palette;
    final id = _id(item);
    final busy = id != null && _busyId == id;
    final open = _isOpen(item);
    final similar = open ? _similar(item) : const <Map<String, dynamic>>[];
    final student = item['student_name']?.toString() ?? 'Studente';
    Future<void> run(String action) async {
      final ok = await _send(item, action);
      if (ok && popOnDone && mounted) Navigator.of(context).pop();
    }

    return Container(
      decoration: BoxDecoration(
        color: p.eleganceDeepNavy,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.skyBlue.withValues(alpha: 0.18)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Text((item['topic']?.toString().trim().isNotEmpty ?? false) ? item['topic'].toString() : 'Materiale richiesto',
                style: TextStyle(color: p.pureWhite, fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(<String>[
              if (item['course'] != null) item['course'].toString(),
              item['subject_name']?.toString() ?? 'Materia',
            ].join(' › '), style: SlText.mono(p, size: 11)),
          ]),
        ),
        Divider(height: 1, color: p.pureWhite.withValues(alpha: 0.07)),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _bubble(name: student, time: _relative(item['created_at']), text: item['message']?.toString() ?? '', mine: false),
              if (item['staff_response'] != null) ...<Widget>[
                const SizedBox(height: 12),
                _bubble(name: 'StudentLab', time: '', text: item['staff_response'].toString(), mine: true),
              ],
              if (similar.isNotEmpty) ...<Widget>[
                const SizedBox(height: 14),
                Row(children: <Widget>[
                  Icon(Icons.groups_outlined, size: 16, color: p.adminCyan),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      similar.length == 1
                          ? 'Un altro studente ha chiesto la stessa cosa.'
                          : 'Altri ${similar.length} studenti hanno chiesto la stessa cosa.',
                      style: SlText.muted(p),
                    ),
                  ),
                ]),
              ],
            ],
          ),
        ),
        if (open) ...<Widget>[
          Divider(height: 1, color: p.pureWhite.withValues(alpha: 0.07)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
              Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(
                item['recipient_kind'] == 'teachers'
                    ? 'Per soddisfarla scegli un file già pubblicato su Drive per tutto il corso. La risposta del docente resta privata.'
                    : 'Per soddisfarla scegli un file già pubblicato per tutti su Drive.',
                style: TextStyle(fontSize: 12))),
              TextField(
                controller: _reply,
                minLines: 3,
                maxLines: 6,
                style: TextStyle(color: p.pureWhite, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Risposta allo studente',
                  hintText: 'Es. Abbiamo pubblicato gli esercizi svolti in Reti › Livello rete.',
                  fillColor: p.darkElegance,
                ),
              ),
              const SizedBox(height: 10),
              Row(children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : () => run('rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: p.pureWhite.withValues(alpha: 0.86),
                      minimumSize: const Size(0, 44),
                      side: BorderSide(color: p.pureWhite.withValues(alpha: 0.14)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                    ),
                    child: const Text('Non disponibile'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: busy ? null : () => run('fulfilled'),
                    style: FilledButton.styleFrom(
                      backgroundColor: p.skyBlue,
                      foregroundColor: p.darkElegance,
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    child: busy
                        ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: p.darkElegance))
                        : const Text('Soddisfa'),
                  ),
                ),
              ]),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _bubble({required String name, required String time, required String text, required bool mine}) {
    final p = context.palette;
    final initials = name.trim().split(RegExp(r'\s+')).where((v) => v.isNotEmpty).take(2).map((v) => v[0].toUpperCase()).join();
    final avatar = CircleAvatar(
      radius: 16,
      backgroundColor: mine ? p.brandNightBlue : p.studentBlue,
      child: mine
          ? Icon(Icons.support_agent_rounded, size: 16, color: p.adminAmber)
          : Text(initials.isEmpty ? '?' : initials, style: TextStyle(color: p.pureWhite, fontSize: 11, fontWeight: FontWeight.w700)),
    );
    final bubble = Flexible(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: mine ? p.skyBlue.withValues(alpha: 0.10) : p.eleganceMidnight,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(mine ? 12 : 4),
            topRight: Radius.circular(mine ? 4 : 12),
            bottomLeft: const Radius.circular(12),
            bottomRight: const Radius.circular(12),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text(time.isEmpty ? name : '$name · $time',
              style: TextStyle(color: p.pureWhite.withValues(alpha: 0.80), fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(text, style: SlText.body(p).copyWith(color: p.pureWhite)),
        ]),
      ),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: mine
          ? <Widget>[bubble, const SizedBox(width: 10), avatar]
          : <Widget>[avatar, const SizedBox(width: 10), bubble],
    );
  }
}
