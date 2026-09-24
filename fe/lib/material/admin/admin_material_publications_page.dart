import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../social/admin/admin_material_storage_api_service.dart';
import '../../theme/nightTheme.dart';
import 'drive_file_preview.dart';
import 'drive_placement_dialog.dart';

class AdminMaterialPublicationsPage extends StatefulWidget {
  const AdminMaterialPublicationsPage({super.key});

  @override
  State<AdminMaterialPublicationsPage> createState() =>
      _AdminMaterialPublicationsPageState();
}

class _AdminMaterialPublicationsPageState
    extends State<AdminMaterialPublicationsPage> {
  final ApiService _api = ApiService();
  final AdminMaterialStorageApiService _storage = AdminMaterialStorageApiService();
  final Set<int> _processing = <int>{};
  String _status = 'pending';
  String _query = '';
  String? _error;
  bool _loading = true;
  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  int? _id(Map<String, dynamic> item) =>
      int.tryParse(item['id']?.toString() ?? '');

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _api.getAdminMaterialPublications(
        status: _status == 'all' ? null : _status,
      );
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossibile caricare le proposte. Riprova.';
      });
    }
  }

  void _message(String message) {
    if (mounted) ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _run(int id, Future<void> Function() action) async {
    if (_processing.contains(id)) return;
    setState(() => _processing.add(id));
    try {
      await action();
      await _load();
    } catch (_) {
      _message('Operazione non riuscita. La proposta non è stata modificata.');
    } finally {
      if (mounted) setState(() => _processing.remove(id));
    }
  }

  Future<void> _approve(Map<String, dynamic> item) async {
    final int? id = _id(item);
    if (id == null || _processing.contains(id)) return;
    DrivePlacement? placement;
    try {
      final drive = await _storage.getDriveStatus();
      if (!mounted) return;
      if (drive['configured'] == true) {
        placement = await showDialog<DrivePlacement>(context: context,
          builder: (_) => DrivePlacementDialog(
            inspect: (path) => _api.previewAdminPublicationDrive(requestId: id, path: path),
            previewProposed: () async {
              if (int.tryParse(item['size']?.toString() ?? '') != null &&
                  int.parse(item['size'].toString()) > 20 * 1024 * 1024) {
                _message('Anteprima disponibile per file fino a 20 MB.'); return;
              }
              await showDriveFilePreview(context,
                load: () => _api.downloadAdminMaterialPublicationFile(id),
                name: item['original_name']?.toString() ?? 'Materiale',
                mimeType: item['mime_type']?.toString() ?? 'application/octet-stream');
            },
            previewExisting: (driveId, fileName, mimeType) => showDriveFilePreview(context,
              load: () => _storage.downloadDriveFilePreview(driveId),
              name: fileName, mimeType: mimeType)));
        if (placement == null || !mounted) return;
      }
    } catch (_) {
      _message('Non posso controllare il percorso Drive. Riprova prima di approvare.');
      return;
    }
    bool forceAnonymous = false;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          backgroundColor: AppColors.eleganceDeepNavy,
          title: const Text('Approva materiale',
            style: TextStyle(color: AppColors.pureWhite)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(item['title']?.toString() ?? 'Materiale',
              style: const TextStyle(color: AppColors.pureWhite)),
            const SizedBox(height: 8),
            const Text('La proposta sarà pubblicata nel catalogo selezionato.',
              style: TextStyle(color: Colors.white70)),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: forceAnonymous,
              title: const Text('Forza anonimizzazione',
                style: TextStyle(color: AppColors.pureWhite)),
              onChanged: (value) => update(() => forceAnonymous = value),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annulla')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Approva')),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    await _run(id, () async {
      await _api.approveAdminMaterialPublication(requestId: id, data: {
        'approved_action': 'publish_new',
        'force_anonymous': forceAnonymous,
        if (placement != null) 'drive_path_segments': placement.path,
        if (placement != null) 'allow_drive_duplicate': placement.allowDuplicate,
      });
      _message('Materiale approvato. Se Drive è momentaneamente indisponibile resta in attesa, senza perdere il file.');
    });
  }

  Future<void> _reject(Map<String, dynamic> item) async {
    final int? id = _id(item);
    if (id == null || _processing.contains(id)) return;
    final controller = TextEditingController();
    final String? reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          backgroundColor: AppColors.eleganceDeepNavy,
          title: const Text('Rifiuta proposta',
            style: TextStyle(color: AppColors.pureWhite)),
          content: TextField(
            controller: controller,
            onChanged: (_) => update(() {}),
            maxLines: 3,
            maxLength: 500,
            style: const TextStyle(color: AppColors.pureWhite),
            decoration: const InputDecoration(labelText: 'Motivo del rifiuto'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annulla')),
            FilledButton(
              onPressed: controller.text.trim().isEmpty ? null :
                () => Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Rifiuta'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (reason == null || !mounted) return;
    await _run(id, () async {
      await _api.rejectAdminMaterialPublication(
        requestId: id, data: {'rejection_reason': reason});
      _message('Proposta rifiutata.');
    });
  }

  Future<void> _details(Map<String, dynamic> item) async {
    final int? id = _id(item);
    if (id == null) return;
    try {
      final details = await _api.getAdminMaterialPublication(id);
      if (!mounted) return;
      await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.eleganceDeepNavy,
        title: Text(details['title']?.toString() ?? 'Proposta',
          style: const TextStyle(color: AppColors.pureWhite)),
        content: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detail('File', details['original_name']),
            _detail('Stato', details['status']),
            _detail('Descrizione', details['description']),
            _detail('Corso', details['course_name'] ?? details['course']),
            _detail('Materia', details['subject_name']),
            _detail('Hash SHA-256', details['sha256'] ?? details['file_hash']),
            _detail('Dimensione in byte', details['file_size'] ?? details['size']),
            _detail('Motivo del rifiuto', details['rejection_reason']),
          ],
        )),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Chiudi'))],
      ));
    } catch (_) {
      _message('Dettagli della proposta non disponibili.');
    }
  }

  Widget _detail(String name, Object? value) {
    if (value == null || value.toString().trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(padding: const EdgeInsets.only(bottom: 9), child: Text(
      '$name: $value', style: const TextStyle(color: Colors.white70)));
  }

  List<Map<String, dynamic>> get _visibleItems => _items.where((item) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    return <Object?>[item['title'], item['original_name'],
      item['subject_name'], item['status']]
      .any((value) => (value?.toString() ?? '').toLowerCase().contains(query));
  }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkElegance,
      appBar: AppBar(
        backgroundColor: AppColors.brandNightBlue,
        foregroundColor: AppColors.pureWhite,
        title: const Text('Proposte materiali'),
        actions: [IconButton(tooltip: 'Aggiorna', onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh_rounded))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!, style: const TextStyle(color: AppColors.pureWhite)),
                  TextButton(onPressed: _load, child: const Text('Riprova')),
                ]))
              : RefreshIndicator(onRefresh: _load, child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: [
                    Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(
                      color: AppColors.eleganceMidnight,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.materialSky.withValues(alpha: 0.28)),
                    ), child: const Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Revisione materiali', style: TextStyle(
                          color: AppColors.pureWhite, fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 5),
                        Text('Controlla percorso e dettagli prima di pubblicare.',
                          style: TextStyle(color: Colors.white60)),
                      ])),
                    const SizedBox(height: 16),
                    SingleChildScrollView(scrollDirection: Axis.horizontal,
                      child: Row(children: [for (final status in const [
                        'pending', 'approved', 'rejected', 'all'
                      ]) Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
                        label: Text(status == 'all' ? 'Tutte' : status),
                        selected: _status == status,
                        onSelected: (_) {setState(() => _status = status); _load();},
                      ))])),
                    const SizedBox(height: 14),
                    TextField(onChanged: (value) => setState(() => _query = value),
                      style: const TextStyle(color: AppColors.pureWhite),
                      decoration: const InputDecoration(labelText: 'Cerca proposta',
                        prefixIcon: Icon(Icons.search_rounded), border: OutlineInputBorder())),
                    const SizedBox(height: 14),
                    Text('${_visibleItems.length} proposte',
                      style: const TextStyle(color: Colors.white60)),
                    const SizedBox(height: 10),
                    if (_visibleItems.isEmpty)
                      const Padding(padding: EdgeInsets.all(24), child: Text(
                        'Nessuna proposta per i filtri selezionati.',
                        style: TextStyle(color: Colors.white60)))
                    else ..._visibleItems.map(_card),
                  ],
                )),
    );
  }

  Widget _card(Map<String, dynamic> item) {
    final id = _id(item);
    final pending = item['status']?.toString().toLowerCase() == 'pending';
    final busy = id != null && _processing.contains(id);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.eleganceMidnight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.skyBlue.withValues(alpha: 0.14))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 7, runSpacing: 7, children: [
          const _PublicationBadge(text: 'PROPOSTA STUDENTE'),
          _PublicationBadge(text: (item['status']?.toString() ?? '—').toUpperCase()),
          _PublicationBadge(text: item['attribution_mode'] == 'named'
              ? 'CON NOME' : 'ANONIMO'),
        ]),
        const SizedBox(height: 10),
        Text(item['title']?.toString() ?? 'Materiale',
          style: const TextStyle(color: AppColors.pureWhite,
            fontWeight: FontWeight.bold, fontSize: 15)),
        _detail('File', item['original_name']),
        _detail('Materia', item['subject_name']),
        _detail('Dimensione in byte', item['file_size'] ?? item['size']),
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(onPressed: busy ? null : () => _details(item),
            icon: const Icon(Icons.info_outline_rounded),
            label: const Text('Dettagli')),
          if (pending) ...[
            FilledButton.icon(onPressed: busy ? null : () => _approve(item),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Accetta')),
            OutlinedButton.icon(onPressed: busy ? null : () => _reject(item),
              icon: const Icon(Icons.close_rounded),
              label: const Text('Rifiuta')),
          ],
        ]),
      ]),
    );
  }
}

class _PublicationBadge extends StatelessWidget {
  final String text;
  const _PublicationBadge({required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: AppColors.brandNightBlue,
      borderRadius: BorderRadius.circular(8)),
    child: Text(text, style: const TextStyle(color: AppColors.materialSky,
      fontSize: 9, fontWeight: FontWeight.bold)),
  );
}
