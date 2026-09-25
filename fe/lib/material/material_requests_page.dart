import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/picked_file_bridge.dart';
import '../social/social_models.dart';
import '../theme/nightTheme.dart';
import '../developer/theme/developer_ui_style.dart';
import '../developer/widgets/developer_section_card.dart';

class MaterialRequestsPage extends StatefulWidget {
  final int? initialSubjectId;
  final String? initialSubjectName;
  final bool hasTeacherMaterials;

  /// Azione da avviare all'apertura: 'teacher' (docenti; StudentLab se la
  /// materia non ne ha), 'studentlab' oppure 'student'. `null` apre solo l'elenco.
  final String? initialAction;

  const MaterialRequestsPage({
    super.key,
    this.initialSubjectId,
    this.initialSubjectName,
    this.hasTeacherMaterials = false,
    this.initialAction,
  });

  @override
  State<MaterialRequestsPage> createState() => _MaterialRequestsPageState();
}

class _MaterialRequestsPageState extends State<MaterialRequestsPage>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  final PickedFileBridge _fileBridge = PickedFileBridge();
  late final TabController _tabs;

  bool _loading = true;
  bool _busy = false;
  String? _error;
  String? _notice;
  bool _noticeIsError = false;
  List<Map<String, dynamic>> _teacherRequests = [];
  List<Map<String, dynamic>> _sentStudentRequests = [];
  List<Map<String, dynamic>> _receivedStudentRequests = [];
  List<SocialUser> _students = [];
  int? _subjectId;
  String? _subjectName;
  bool _hasTeacherMaterials = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _subjectId = widget.initialSubjectId;
    _subjectName = widget.initialSubjectName;
    _hasTeacherMaterials = widget.hasTeacherMaterials;
    _load().then((_) => _runInitialAction());
  }

  /// Apre subito il modulo scelto dal pannello "Richiedi o pubblica".
  Future<void> _runInitialAction() async {
    final String? action = widget.initialAction;
    if (!mounted || action == null || _busy) return;
    if (!await _ensureSubject() || !mounted) return;
    if (action == 'teacher') {
      await _createTeacherRequest();
    } else if (action == 'studentlab') {
      await _createTeacherRequest(recipientKind: 'studentlab');
    } else if (action == 'student') {
      await _createStudentRequest();
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait<dynamic>([
        _api.getMyTeacherMaterialRequests(),
        _api.getMyStudentMaterialRequests(),
        _api.getReceivedStudentMaterialRequests(),
        _api.getSocialUsers().catchError((Object _) => <SocialUser>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _teacherRequests = List<Map<String, dynamic>>.from(results[0] as List);
        _sentStudentRequests = List<Map<String, dynamic>>.from(
          results[1] as List,
        );
        _receivedStudentRequests = List<Map<String, dynamic>>.from(
          results[2] as List,
        );
        _students =
            (results[3] as List<SocialUser>)
                .where((user) => user.isStudent && user.isActive)
                .toList()
              ..sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              );
      });
    } catch (e) {
      if (mounted) setState(() => _error = _friendly(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _ensureSubject() async {
    if (_subjectId != null) return true;
    try {
      final options = await _api.getMaterialRequestSubjects();
      if (!mounted) return false;
      if (options.isEmpty) {
        _message('Nessuna materia disponibile nel tuo percorso accademico.');
        return false;
      }
      final chosen = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        backgroundColor: AppColors.eleganceDeepNavy,
        isScrollControlled: true,
        builder: (context) => SafeArea(child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .65,
          child: Column(children: [
            const Padding(padding: EdgeInsets.all(18), child: Text('Scegli la materia',
              style: TextStyle(color: Colors.white, fontSize: 19))),
            Expanded(child: ListView.builder(itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                return ListTile(
                  title: Text(option['subject_name']?.toString() ?? 'Materia',
                    style: const TextStyle(color: Colors.white)),
                  subtitle: Text('${option['course'] ?? ''} · anno ${option['study_year'] ?? '—'} · ${option['recipient_kind'] == 'teachers' ? 'Docenti' : 'StudentLab'}',
                    style: const TextStyle(color: Colors.white70)),
                  onTap: () => Navigator.pop(context, option),
                );
              })),
          ]))),
      );
      if (chosen == null || !mounted) return false;
      setState(() {
        _subjectId = int.tryParse(chosen['subject_id'].toString());
        _subjectName = chosen['subject_name']?.toString();
        _hasTeacherMaterials = false;
      });
      return _subjectId != null;
    } catch (e) {
      if (mounted) _showNotice(_friendly(e), isError: true);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkElegance,
      appBar: AppBar(
        backgroundColor: AppColors.brandNightBlue,
        foregroundColor: AppColors.pureWhite,
        title: const Text('Richieste materiali'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Le mie richieste'),
            Tab(text: 'Ricevute'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loading || _busy ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorState(message: _error!, onRetry: _load)
          : Center(child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: DeveloperUiStyle.maxContentWidth),
              child: Column(children: [
                if (_notice != null) Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Semantics(liveRegion: true, child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                    decoration: BoxDecoration(
                      color: _noticeIsError
                          ? const Color(0xFF472F39)
                          : AppColors.eleganceMidnight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _noticeIsError
                          ? const Color(0xFFD58C95)
                          : AppColors.materialSky),
                    ),
                    child: Row(children: [
                      Icon(_noticeIsError ? Icons.info_outline_rounded : Icons.check_circle_outline,
                        color: _noticeIsError ? const Color(0xFFFFC2C6) : AppColors.materialSky),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_notice!, style: const TextStyle(color: Colors.white))),
                      IconButton(tooltip: 'Chiudi avviso',
                        onPressed: () => setState(() => _notice = null),
                        icon: const Icon(Icons.close_rounded, color: Colors.white70)),
                    ]),
                  )),
                ),
                Padding(padding: const EdgeInsets.all(16),
                  child: DeveloperSectionCard(
                    title: 'Richiedi e condividi',
                    subtitle: _subjectId == null
                        ? 'Scegli una materia del tuo corso per inviare una richiesta. Puoi consultare subito quelle ricevute.'
                        : 'Materia: ${_subjectName ?? 'selezionata'}. Consulta e gestisci le richieste qui sotto.',
                    icon: Icons.people_outline_rounded,
                    child: Wrap(spacing: 8, runSpacing: 8, children: [
                      FilledButton.icon(onPressed: _busy ? null : () async {
                        if (await _ensureSubject()) await _createTeacherRequest();
                      },
                        icon: const Icon(Icons.school_outlined),
                        label: const Text('Chiedi a un docente')),
                      OutlinedButton.icon(onPressed: _busy ? null : () async {
                        if (await _ensureSubject()) await _createStudentRequest();
                      },
                        icon: const Icon(Icons.person_search_rounded),
                        label: const Text('Chiedi a uno studente')),
                      if (_subjectId != null) TextButton.icon(
                        onPressed: _busy ? null : () { setState(() => _subjectId = null); _ensureSubject(); },
                        icon: const Icon(Icons.swap_horiz), label: const Text('Cambia materia')),
                    ]))),
                Expanded(child: TabBarView(controller: _tabs,
                  children: [_buildSent(), _buildReceived()])),
              ]))),
    );
  }

  Widget _buildSent() {
    final items =
        <_RequestViewItem>[
          ..._teacherRequests.map((e) => _RequestViewItem('teacher', e)),
          ..._sentStudentRequests.map((e) => _RequestViewItem('student', e)),
        ]..sort(
          (a, b) => _date(
            b.data['created_at'],
          ).compareTo(_date(a.data['created_at'])),
        );

    if (items.isEmpty) {
      return const _EmptyState(
        icon: Icons.outbox_outlined,
        title: 'Nessuna richiesta inviata',
        subtitle:
            'Le richieste ai docenti e agli altri studenti compariranno qui.',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final data = item.data;
          final status = data['status']?.toString() ?? 'pending';
          final pending = status == 'pending';
          return _RequestCard(
            title: item.kind == 'teacher'
                ? (data['recipient_kind'] == 'studentlab' ? 'Richiesta a StudentLab' : 'Richiesta ai docenti')
                : 'Richiesta a studente',
            topic: data['topic']?.toString(),
            message: '${data['message']?.toString() ?? ''}${data['staff_response'] == null ? '' : '\n\nRisposta StudentLab: ${data['staff_response']}'}',
            status: status,
            date: _dateLabel(data['created_at']),
            trailing: pending
                ? TextButton(
                    onPressed: _busy ? null : () => _cancel(item),
                    child: const Text('Annulla'),
                  )
                : null,
          );
        },
      ),
    );
  }

  Widget _buildReceived() {
    if (_receivedStudentRequests.isEmpty) {
      return const _EmptyState(
        icon: Icons.inbox_outlined,
        title: 'Nessuna richiesta ricevuta',
        subtitle:
            'Quando uno studente ti chiede del materiale, la richiesta comparirà qui.',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _receivedStudentRequests.length,
        itemBuilder: (context, index) {
          final data = _receivedStudentRequests[index];
          final status = data['status']?.toString() ?? 'pending';
          final requesterId = _toInt(data['requester_user_id']);
          final requester = _userName(requesterId);
          return _RequestCard(
            title: requester == null
                ? 'Richiesta ricevuta'
                : '$requester ti ha richiesto un materiale',
            topic: data['topic']?.toString(),
            message: data['message']?.toString() ?? '',
            status: status,
            date: _dateLabel(data['created_at']),
            trailing: status == 'pending'
                ? Wrap(
                    spacing: 6,
                    children: [
                      TextButton(
                        onPressed: _busy ? null : () => _decline(data),
                        child: const Text('Non ce l’ho'),
                      ),
                      FilledButton.icon(
                        onPressed: _busy ? null : () => _fulfill(data),
                        icon: const Icon(Icons.upload_file_rounded, size: 18),
                        label: const Text('Condividi'),
                      ),
                    ],
                  )
                : null,
          );
        },
      ),
    );
  }

  Future<void> _createStudentRequest() async {
    if (_students.isEmpty || _subjectId == null) {
      _message('Non ci sono studenti disponibili a cui inviare la richiesta.');
      return;
    }

    int? recipientId;
    final topic = TextEditingController();
    final message = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.eleganceDeepNavy,
          title: const Text(
            'Chiedi materiale a uno studente',
            style: TextStyle(color: AppColors.pureWhite),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if ((_subjectName ?? '').trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _subjectName!,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                DropdownButtonFormField<int>(
                  value: recipientId,
                  dropdownColor: AppColors.eleganceDeepNavy,
                  decoration: const InputDecoration(
                    labelText: 'Studente destinatario',
                  ),
                  items: _students
                      .map(
                        (user) => DropdownMenuItem(
                          value: user.id,
                          child: Text(user.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => recipientId = value),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: topic,
                  decoration: const InputDecoration(
                    labelText: 'Argomento facoltativo',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: message,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Di quale materiale hai bisogno?',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Invia'),
            ),
          ],
        ),
      ),
    );

    if (ok != true || recipientId == null || message.text.trim().isEmpty) {
      topic.dispose();
      message.dispose();
      return;
    }

    await _run(() async {
      await _api.createStudentMaterialRequest(
        recipientUserId: recipientId!,
        subjectId: _subjectId,
        topic: topic.text.trim(),
        message: message.text.trim(),
      );
      _message('Richiesta inviata allo studente.');
      await _load();
    });
    topic.dispose();
    message.dispose();
  }

  Future<void> _createTeacherRequest({String? recipientKind}) async {
    final bool toStudentLab = recipientKind == 'studentlab';
    final subjectId = _subjectId;
    if (subjectId == null) return;
    if (_hasTeacherMaterials && !toStudentLab) {
      final proceed = await showDialog<bool>(context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppColors.eleganceDeepNavy,
          title: const Text('Materiale docente già disponibile',
            style: TextStyle(color: AppColors.pureWhite)),
          content: const Text('Per questa materia ci sono già materiali del docente. Controlla la cartella prima di richiederne altri.',
            style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Vedi materiali')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Richiedi comunque')),
          ]));
      if (proceed != true || !mounted) return;
    }
    final topic = TextEditingController();
    final message = TextEditingController();
    final send = await showDialog<bool>(context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.eleganceDeepNavy,
        title: Text(toStudentLab ? 'Richiedi materiale a StudentLab' : 'Richiedi materiale al docente',
          style: const TextStyle(color: AppColors.pureWhite)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          if (_subjectName != null) Text(_subjectName!,
            style: const TextStyle(color: Colors.white70)),
          TextField(controller: topic, decoration: const InputDecoration(
            labelText: 'Argomento (facoltativo)')),
          TextField(controller: message, minLines: 3, maxLines: 5,
            decoration: const InputDecoration(labelText: 'Materiale richiesto')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Invia richiesta')),
        ]));
    final topicText = topic.text.trim();
    final messageText = message.text.trim();
    topic.dispose(); message.dispose();
    if (send != true) return;
    if (messageText.isEmpty) {
      _message('Descrivi il materiale che vuoi richiedere.');
      return;
    }
    await _run(() async {
      final response = await _api.createTeacherMaterialRequest(subjectId: subjectId,
        topic: topicText, message: messageText, recipientKind: recipientKind);
      _message(response['recipient_kind'] == 'studentlab'
        ? (toStudentLab
            ? 'Richiesta inviata a StudentLab.'
            : 'Nessun docente registrato: richiesta inviata a StudentLab.')
        : 'Richiesta inviata ai docenti registrati.');
      await _load();
    });
  }

  Future<void> _cancel(_RequestViewItem item) async {
    final id = _toInt(item.data['id']);
    if (id == null) return;
    await _run(() async {
      if (item.kind == 'teacher') {
        await _api.cancelTeacherMaterialRequest(id);
      } else {
        await _api.cancelStudentMaterialRequest(id);
      }
      await _load();
    });
  }

  Future<void> _decline(Map<String, dynamic> data) async {
    final id = _toInt(data['id']);
    if (id == null) return;
    await _run(() async {
      await _api.resolveStudentMaterialRequest(
        requestId: id,
        action: 'declined',
      );
      await _load();
    });
  }

  Future<void> _fulfill(Map<String, dynamic> data) async {
    final requestId = _toInt(data['id']);
    final requesterId = _toInt(data['requester_user_id']);
    if (requestId == null || requesterId == null) return;

    final result = await FilePicker.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const [
        'pdf',
        'txt',
        'zip',
        'docx',
        'pptx',
        'png',
        'jpg',
        'jpeg',
      ],
    );
    if (result == null || result.files.isEmpty) return;

    await _run(() async {
      final file = result.files.single;
      final path = await _fileBridge.materialize(file);
      final share = await _api.shareMaterialWithUser(
        filePath: path,
        recipientUserId: requesterId,
        subjectId: _toInt(data['subject_id']),
        message: 'Materiale condiviso in risposta alla tua richiesta.',
      );
      final shareId = _toInt(share['id']);
      if (shareId == null) {
        throw StateError(
          'La condivisione non ha restituito un identificativo valido.',
        );
      }
      await _api.resolveStudentMaterialRequest(
        requestId: requestId,
        action: 'fulfilled',
        fulfilledShareId: shareId,
      );
      _message('Materiale condiviso. La richiesta è stata soddisfatta.');
      await _load();
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      _showNotice(_friendly(e), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _userName(int? id) {
    if (id == null) return null;
    for (final user in _students) {
      if (user.id == id) return user.name;
    }
    return null;
  }

  DateTime _date(dynamic value) =>
      DateTime.tryParse(value?.toString() ?? '') ??
      DateTime.fromMillisecondsSinceEpoch(0);

  String _dateLabel(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return '—';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  String _friendly(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('404') || text.contains('not found') || text.contains('non disponibile')) {
      return 'Questa funzione è temporaneamente non disponibile. Riprova più tardi.';
    }
    if (text.contains('socket') || text.contains('network') ||
        text.contains('connection') || text.contains('timeout') ||
        text.contains('host lookup')) {
      return 'Non riusciamo a contattare StudentLab. Controlla la connessione e riprova.';
    }
    if (text.contains('materia del tuo corso') || text.contains('percorso accademico')) {
      return 'Scegli una materia del tuo percorso accademico e riprova.';
    }
    if (text.contains('sessione') || text.contains('401') || text.contains('token')) {
      return 'La sessione è scaduta. Accedi di nuovo per continuare.';
    }
    return 'Non è stato possibile completare l’operazione. Riprova.';
  }

  void _message(String text) {
    _showNotice(text);
  }

  void _showNotice(String text, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _notice = text;
      _noticeIsError = isError;
    });
  }
}

class _RequestViewItem {
  final String kind;
  final Map<String, dynamic> data;
  const _RequestViewItem(this.kind, this.data);
}

class _RequestCard extends StatelessWidget {
  final String title;
  final String? topic;
  final String message;
  final String status;
  final String date;
  final Widget? trailing;

  const _RequestCard({
    required this.title,
    required this.topic,
    required this.message,
    required this.status,
    required this.date,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: DeveloperUiStyle.panelDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.pureWhite,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _StatusChip(status: status),
              ],
            ),
            if ((topic ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                topic!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  date,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      'pending' => 'In attesa',
      'fulfilled' => 'Soddisfatta',
      'rejected' || 'declined' => 'Rifiutata',
      'cancelled' => 'Annullata',
      _ => status,
    };
    return Chip(label: Text(label, style: const TextStyle(fontSize: 10)));
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.white38),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.pureWhite,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onRetry, child: const Text('Riprova')),
          ],
        ),
      ),
    );
  }
}
