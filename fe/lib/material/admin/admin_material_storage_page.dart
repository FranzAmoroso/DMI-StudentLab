import 'package:flutter/material.dart';

import '../../theme/nightTheme.dart';
import '../../social/admin/admin_material_storage_api_service.dart';

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
  Map<String, dynamic> _overview = {};
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final overview = await _api.getOverview();
      final items = await _api.getItems(
        source: _source == 'all' ? null : _source,
      );
      if (!mounted) return;
      setState(() {
        _overview = overview;
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

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
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final source in const [
                          'all',
                          'publication_request',
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
                  const SizedBox(height: 18),
                  ..._items.map(_card),
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

  Widget _card(Map<String, dynamic> item) {
    final bool privateContent = item['private_content'] == true;
    final String source = item['source']?.toString() ?? '';
    final String title = privateContent
        ? (source == 'shared_user'
              ? 'Condivisione privata'
              : 'Materiale personale')
        : (item['title']?.toString() ??
              item['original_name']?.toString() ??
              'Materiale');
    final String owner = privateContent
        ? (item['owner_ref']?.toString() ?? 'Utente anonimizzato')
        : (item['user_id']?.toString().isNotEmpty == true
              ? 'Utente #${item['user_id']}'
              : '');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.eleganceMidnight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.skyBlue.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _StorageBadge(text: _label(source).toUpperCase()),
              if (privateContent) const _StorageBadge(text: 'PRIVATO'),
              _StorageBadge(
                text: (item['status']?.toString() ?? '—').toUpperCase(),
              ),
              if (item['retention_status'] != null)
                _StorageBadge(
                  text:
                      'RETENTION ${(item['retention_status']?.toString() ?? '').toUpperCase()}',
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.pureWhite,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          if (owner.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              owner,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              Text(
                _bytes(item['blob_size'] ?? item['size']),
                style: const TextStyle(color: Colors.white60, fontSize: 10),
              ),
              Text(
                'Caricato: ${_date(item['created_at'] ?? item['updated_at'])}',
                style: const TextStyle(color: Colors.white60, fontSize: 10),
              ),
              if (item['cloud_expires_at'] != null)
                Text(
                  'Scadenza: ${_date(item['cloud_expires_at'])}',
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
          if (privateContent) ...[
            const SizedBox(height: 10),
            const Text(
              'Contenuto non accessibile dall’area amministrativa. Sono visibili solo metadati tecnici e stato retention.',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 9,
                height: 1.35,
              ),
            ),
          ],
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
