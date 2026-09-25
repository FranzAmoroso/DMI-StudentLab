import 'package:flutter/material.dart';

import '../../theme/nightTheme.dart';
import '../../social/admin/admin_material_storage_api_service.dart';
import 'admin_material_publications_page.dart';
import 'admin_material_course_proposals_page.dart';
import 'admin_drive_catalog_page.dart';
import 'admin_studentlab_material_requests_page.dart';
import 'drive_file_preview.dart';
import 'drive_placement_dialog.dart';

class AdminMaterialStoragePage extends StatefulWidget {
  const AdminMaterialStoragePage({super.key});

  @override
  State<AdminMaterialStoragePage> createState() =>
      _AdminMaterialStoragePageState();
}

class _AdminMaterialStoragePageState extends State<AdminMaterialStoragePage> {
  final AdminMaterialStorageApiService _api = AdminMaterialStorageApiService();
  bool _loading = true;
  String _source = 'all';
  String _query = '';
  String? _error;
  Map<String, dynamic> _overview = {};
  Map<String, dynamic> _driveStatus = {};
  String? _driveError;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    Map<String, dynamic> overview = {};
    List<Map<String, dynamic>> items = [];
    Map<String, dynamic> driveStatus = {};
    String? error;
    String? driveError;
    try {
      overview = await _api.getOverview();
    } catch (_) { /* Metrics are optional. */ }
    try {
      items = await _api.getItems(source: _source == 'all' ? null : _source);
    } catch (e) { error = 'Inventario non disponibile: $e'; }
    try {
      driveStatus = await _api.getDriveStatus();
    } catch (e) { driveError = 'Stato Drive non disponibile: $e'; }
    if (mounted) {
      setState(() {
        _overview = overview;
        _items = items;
        _driveStatus = driveStatus;
        _driveError = driveError;
        _error = error;
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _visibleItems => _items.where((item) {
    // Moderation requests have their dedicated queue above; avoid showing
    // the same student proposal twice in the storage inventory.
    if (item['source'] == 'publication_request') return false;
    if (_query.trim().isEmpty) return true;
    // Never search private titles or filenames in the admin view.
    final privateContent = item['private_content'] == true;
    final fields = privateContent
        ? <Object?>[item['owner_ref'], item['source'], item['status']]
        : <Object?>[item['title'], item['original_name'], item['source'],
            item['subject_name'], item['course'], item['status']];
    return fields.any((value) => (value?.toString() ?? '')
        .toLowerCase().contains(_query.trim().toLowerCase()));
  }).toList();

  String _bytes(dynamic value) {
    final int size = int.tryParse(value?.toString() ?? '') ?? 0;
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024)
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _date(dynamic value) {
    final d = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final summary = _overview['summary'] is Map
        ? Map<String, dynamic>.from(_overview['summary'])
        : <String, dynamic>{};
    return Scaffold(
      backgroundColor: AppColors.darkElegance,
      appBar: AppBar(
        backgroundColor: AppColors.brandNightBlue,
        foregroundColor: AppColors.pureWhite,
        title: const Text('Materiali e Storage'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.eleganceMidnight,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.materialSky.withValues(alpha: 0.28)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Controllo materiali', style: TextStyle(
                        color: AppColors.pureWhite, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      const Text('Spazio e file pubblicati. Le richieste hanno una coda separata.',
                        style: TextStyle(color: Colors.white60)),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await Navigator.of(context).push(MaterialPageRoute<void>(
                            builder: (_) => const AdminMaterialPublicationsPage()));
                          if (mounted) await _load();
                        },
                        icon: const Icon(Icons.fact_check_outlined),
                        label: const Text('Esamina proposte')),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await Navigator.of(context).push(MaterialPageRoute<void>(
                            builder: (_) => const AdminMaterialCourseProposalsPage()));
                          if (mounted) await _load();
                        },
                        icon: const Icon(Icons.school_outlined),
                        label: const Text('Approva corsi aggiuntivi')),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => const AdminStudentLabMaterialRequestsPage())),
                        icon: const Icon(Icons.mark_email_unread_outlined),
                        label: const Text('Richieste di materiale a StudentLab')),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Metric(
                        label: 'Blob',
                        value: '${summary['blob_count'] ?? 0}',
                      ),
                      _Metric(
                        label: 'Storage',
                        value: _bytes(summary['total_bytes']),
                      ),
                      _Metric(
                        label: 'Recuperabile',
                        value: _bytes(summary['reclaimable_bytes']),
                      ),
                      _Metric(
                        label: 'Orfani',
                        value: '${summary['orphan_blob_count'] ?? 0}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(width: double.infinity, padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.eleganceMidnight,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.skyBlue.withValues(alpha: 0.15))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Google Drive · risorse esistenti e materiali pubblicati',
                        style: TextStyle(color: AppColors.pureWhite, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(_driveError ?? (_driveStatus['configured'] == true
                        ? 'Account: ${_driveStatus['account'] ?? '—'} · Utilizzato: ${_bytes(_driveStatus['used_bytes'])} / ${_driveStatus['limit_bytes'] == null ? 'limite non disponibile' : _bytes(_driveStatus['limit_bytes'])}'
                        : 'La copia su Drive richiede permessi di scrittura. Puoi comunque provare a esplorare i file esistenti.'),
                        style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await Navigator.of(context).push(MaterialPageRoute<void>(
                            builder: (_) => const AdminDriveCatalogPage()));
                          if (mounted) await _load();
                        },
                        icon: const Icon(Icons.folder_open_outlined),
                        label: const Text('Esplora e classifica file già su Drive')),
                    ])),
                  const SizedBox(height: 18),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final source in const [
                          'all',
                          'public',
                          'teacher',
                          'group',
                          'personal_sync',
                          'shared_user',
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(_label(source)),
                              selected: _source == source,
                              onSelected: (_) async {
                                setState(() => _source = source);
                                await _load();
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (value) => setState(() => _query = value),
                    style: const TextStyle(color: AppColors.pureWhite),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      labelText: 'Cerca nei materiali',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_error != null) Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: ListTile(
                      title: Text(_error!, style: const TextStyle(color: Colors.white70)),
                      trailing: TextButton(onPressed: _load, child: const Text('Riprova')),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('${_visibleItems.length} elementi', style: const TextStyle(color: Colors.white60)),
                  const SizedBox(height: 8),
                  if (_visibleItems.isEmpty)
                    const Padding(padding: EdgeInsets.all(20), child: Text(
                      'Nessun materiale per i filtri selezionati.',
                      style: TextStyle(color: Colors.white60)))
                  else ..._visibleItems.map(_card),
                ],
              ),
            ),
    );
  }

  String _label(String source) {
    switch (source) {
      case 'publication_request':
        return 'Proposte';
      case 'public':
        return 'StudentLab';
      case 'teacher':
        return 'Docenti';
      case 'group':
        return 'Gruppi';
      case 'personal_sync':
        return 'Privati';
      case 'shared_user':
        return 'Condivisioni';
      default:
        return 'Tutti';
    }
  }

  Future<void> _changeVisibility(Map<String, dynamic> item, String state) async {
    final id = int.tryParse(item['id']?.toString() ?? '');
    if (id == null) return;
    try {
      await _api.setPublicVisibility(materialId: id, state: state);
      if (mounted) await _load();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Non è stato possibile modificare la visibilità.')));
    }
  }

  Future<void> _copyToDrive(Map<String, dynamic> item) async {
    final materialId = int.tryParse(item['id']?.toString() ?? '');
    if (materialId == null) return;
    try {
      final placement = await showDialog<DrivePlacement>(context: context,
        builder: (_) => DrivePlacementDialog(
          inspect: (path) => _api.previewPublicDrive(materialId, path: path),
          previewProposed: () async {
            if ((int.tryParse(item['size']?.toString() ?? '') ?? 0) > 20 * 1024 * 1024) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Anteprima disponibile per file fino a 20 MB.')));
              return;
            }
            await showDriveFilePreview(context,
              load: () => _api.downloadPublicMaterialPreview(materialId),
              name: item['original_name']?.toString() ?? 'Materiale',
              mimeType: item['mime_type']?.toString() ?? 'application/octet-stream');
          },
          previewExisting: (driveId, fileName, mimeType) =>
              showDriveFilePreview(context,
                load: () => _api.downloadDriveFilePreview(driveId),
                name: fileName, mimeType: mimeType)));
      if (placement == null || !mounted) return;
      await _api.copyPublicToDrive(materialId, path: placement.path,
        allowDuplicate: placement.allowDuplicate);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Copia Drive verificata. Il file Blob rimane disponibile.')));
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Copia Drive non completata. Controlla l’accesso e riprova.')));
    }
  }

  Future<void> _deleteDriveCopy(Map<String, dynamic> item) async {
    final materialId = int.tryParse(item['id']?.toString() ?? '');
    if (materialId == null) return;
    final answer = TextEditingController();
    final confirmed = await showDialog<bool>(context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.eleganceDeepNavy,
        title: const Text('Elimina solo la copia Drive',
          style: TextStyle(color: AppColors.pureWhite)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Il file Blob e i file locali degli studenti non saranno eliminati. Scrivi ELIMINA per confermare.',
            style: TextStyle(color: Colors.white70)),
          TextField(controller: answer, decoration: const InputDecoration(
            labelText: 'Conferma')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Elimina copia')),
        ]));
    final valid = answer.text.trim() == 'ELIMINA';
    answer.dispose();
    if (confirmed != true || !valid || !mounted) return;
    try {
      await _api.deletePublicDriveCopy(materialId);
      if (mounted) await _load();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Non è stato possibile eliminare la copia Drive.')));
    }
  }

  Future<void> _changeAudience(Map<String, dynamic> item) async {
    final materialId = int.tryParse(item['id']?.toString() ?? '');
    if (materialId == null) return;
    final recipient = TextEditingController(text: item['audience_id']?.toString() ?? '');
    String audience = item['audience_type']?.toString() ?? 'public';
    final confirmed = await showDialog<bool>(context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (context, update) => AlertDialog(
        backgroundColor: AppColors.eleganceDeepNavy,
        title: const Text('Destinatari del materiale',
          style: TextStyle(color: AppColors.pureWhite)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(value: audience,
            dropdownColor: AppColors.eleganceDeepNavy,
            decoration: const InputDecoration(labelText: 'Visibile a'),
            items: const [
              DropdownMenuItem(value: 'public', child: Text('Tutti')),
              DropdownMenuItem(value: 'course', child: Text('Studenti del corso')),
              DropdownMenuItem(value: 'subject', child: Text('Studenti della materia')),
              DropdownMenuItem(value: 'group', child: Text('Gruppo specifico')),
              DropdownMenuItem(value: 'user', child: Text('Studente specifico')),
            ], onChanged: (v) { if (v != null) update(() => audience = v); }),
          if (audience == 'group' || audience == 'user')
            TextField(controller: recipient, keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: audience == 'group'
                ? 'ID del gruppo' : 'ID dello studente')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Salva destinatari')),
        ])));
    final id = int.tryParse(recipient.text.trim());
    recipient.dispose();
    if (confirmed != true || !mounted) return;
    if ((audience == 'group' || audience == 'user') && id == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Indica un ID valido per il destinatario.')));
      return;
    }
    try {
      await _api.setPublicAudience(materialId: materialId,
        audienceType: audience, audienceId: id);
      if (mounted) await _load();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Destinatario non valido per questo materiale.')));
    }
  }

  Future<void> _placeFile(Map<String, dynamic> item) async {
    final materialId = int.tryParse(item['id']?.toString() ?? '');
    if (materialId == null) return;
    final subjectId = TextEditingController(text: item['subject_id']?.toString() ?? '');
    final rawPath = item['path_segments'];
    final folder = TextEditingController(text: rawPath is List ? rawPath.join(' / ') : '');
    final bool? confirmed = await showDialog<bool>(context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.eleganceDeepNavy,
        title: const Text('Classifica materiale',
          style: TextStyle(color: AppColors.pureWhite)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Modifica la posizione nel catalogo. Il file fisico non viene spostato.',
            style: TextStyle(color: Colors.white70)),
          TextField(controller: subjectId, keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.pureWhite),
            decoration: const InputDecoration(labelText: 'ID materia')),
          TextField(controller: folder, style: const TextStyle(color: AppColors.pureWhite),
            decoration: const InputDecoration(labelText: 'Cartelle (facoltative)',
              helperText: 'Esempio: Livello trasporto / TCP')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Salva percorso')),
        ],
      ));
    final targetId = int.tryParse(subjectId.text.trim());
    final segments = folder.text.split('/').map((v) => v.trim())
        .where((v) => v.isNotEmpty).toList();
    subjectId.dispose(); folder.dispose();
    if (confirmed != true || targetId == null || !mounted) return;
    try {
      await _api.placePublicFile(materialId: materialId,
        subjectId: targetId, pathSegments: segments);
      if (mounted) await _load();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Non è stato possibile aggiornare il percorso.')));
    }
  }

  Future<void> _moveFolder(Map<String, dynamic> item) async {
    final subjectId = int.tryParse(item['subject_id']?.toString() ?? '');
    final rawPath = item['path_segments'];
    if (subjectId == null || rawPath is! List || rawPath.isEmpty) return;
    final sourceFolder = TextEditingController(
      text: rawPath.map((part) => part.toString()).join(' / '));
    final destinationSubject = TextEditingController(text: '$subjectId');
    final destinationFolder = TextEditingController();
    final bool? confirmed = await showDialog<bool>(context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.eleganceDeepNavy,
        title: const Text('Sposta intera cartella',
          style: TextStyle(color: AppColors.pureWhite)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Tutti i file e le sottocartelle seguiranno la cartella.',
            style: TextStyle(color: Colors.white70)),
          TextField(controller: sourceFolder,
            style: const TextStyle(color: AppColors.pureWhite),
            decoration: const InputDecoration(labelText: 'Cartella da spostare',
              helperText: 'Puoi scegliere anche una cartella superiore')),
          TextField(controller: destinationSubject,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.pureWhite),
            decoration: const InputDecoration(labelText: 'ID materia di destinazione')),
          TextField(controller: destinationFolder,
            style: const TextStyle(color: AppColors.pureWhite),
            decoration: const InputDecoration(
              labelText: 'Cartella di destinazione (facoltativa)',
              helperText: 'Esempio: Modulo 1 / Dispense')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sposta')),
        ],
      ));
    final targetId = int.tryParse(destinationSubject.text.trim());
    final sourcePath = sourceFolder.text.split('/')
        .map((segment) => segment.trim()).where((segment) => segment.isNotEmpty).toList();
    final targetPath = destinationFolder.text.split('/')
        .map((segment) => segment.trim()).where((segment) => segment.isNotEmpty).toList();
    destinationSubject.dispose();
    destinationFolder.dispose();
    sourceFolder.dispose();
    if (confirmed != true || targetId == null || sourcePath.isEmpty || !mounted) return;
    try {
      final result = await _api.movePublicFolder(
        sourceSubjectId: subjectId, sourcePath: sourcePath,
        destinationSubjectId: targetId, destinationPath: targetPath);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Spostati ${result['moved_files'] ?? 0} file.')));
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Impossibile spostare la cartella. Controlla materia e percorso.')));
    }
  }

  Widget _card(Map<String, dynamic> item) {
    final privateContent = item['private_content'] == true;
    final source = item['source']?.toString() ?? '';
    final title = privateContent
        ? (source == 'shared_user' ? 'Condivisione privata' : 'Materiale personale')
        : (item['title']?.toString() ?? item['original_name']?.toString() ?? 'Materiale');
    final editable = !privateContent && source == 'public' && item['status'] != 'removed';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.eleganceMidnight,
      child: ExpansionTile(
        leading: Icon(privateContent ? Icons.lock_outline : Icons.description_outlined,
          color: AppColors.materialSky),
        title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.pureWhite, fontWeight: FontWeight.w600)),
        subtitle: Text('${_label(source)} · ${item['status'] ?? '—'} · ${_bytes(item['blob_size'] ?? item['size'])}',
          style: const TextStyle(color: Colors.white60)),
        iconColor: AppColors.materialSky,
        collapsedIconColor: Colors.white70,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(alignment: Alignment.centerLeft, child: Text(
            privateContent
                ? 'Contenuto privato: solo metadati e stato di conservazione.'
                : '${item['course'] ?? ''} · ${item['subject_name'] ?? ''}\nCaricato: ${_date(item['created_at'] ?? item['updated_at'])}${item['path_segments'] is List ? '\nCartella: ${(item['path_segments'] as List).join(' / ')}' : ''}',
            style: const TextStyle(color: Colors.white70))),
          if (editable) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 4, children: [
              PopupMenuButton<String>(
                tooltip: 'Visibilità', color: AppColors.eleganceDeepNavy,
                onSelected: (value) => _changeVisibility(item, value),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'visible', child: Text('Visibile')),
                  PopupMenuItem(value: 'hidden', child: Text('Nascosto')),
                  PopupMenuItem(value: 'in_review', child: Text('In revisione')),
                  PopupMenuItem(value: 'archived', child: Text('Archiviato')),
                ],
                child: const Padding(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.visibility_outlined, color: AppColors.materialSky),
                    SizedBox(width: 6), Text('Visibilità', style: TextStyle(color: AppColors.materialSky)),
                  ])),
              ),
              TextButton.icon(onPressed: () => _changeAudience(item),
                icon: const Icon(Icons.groups_outlined), label: const Text('Destinatari')),
              TextButton.icon(onPressed: () => _placeFile(item),
                icon: const Icon(Icons.edit_location_alt_outlined), label: const Text('Percorso')),
              if (item['path_segments'] is List && (item['path_segments'] as List).isNotEmpty)
                TextButton.icon(onPressed: () => _moveFolder(item),
                  icon: const Icon(Icons.drive_file_move_outline), label: const Text('Sposta cartella')),
              if (item['drive_copied'] != true)
                TextButton.icon(onPressed: _driveStatus['configured'] == true
                    ? () => _copyToDrive(item) : null,
                  icon: const Icon(Icons.add_to_drive_outlined), label: const Text('Copia su Drive')),
            ]),
          ],
          if (!privateContent && source == 'public' && item['status'] == 'removed' &&
              item['drive_copied'] == true)
            TextButton.icon(onPressed: () => _deleteDriveCopy(item),
              icon: const Icon(Icons.delete_outline), label: const Text('Rimuovi copia Drive')),
        ],
      ),
    );
  }

}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.eleganceMidnight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 9),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.pureWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _StorageBadge extends StatelessWidget {
  final String text;
  const _StorageBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.brandNightBlue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.materialSky,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
