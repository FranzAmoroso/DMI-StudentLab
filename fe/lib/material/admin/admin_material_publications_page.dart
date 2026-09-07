import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/nightTheme.dart';

class AdminMaterialPublicationsPage extends StatefulWidget {
  const AdminMaterialPublicationsPage({super.key});

  @override
  State<AdminMaterialPublicationsPage> createState() =>
      _AdminMaterialPublicationsPageState();
}

class _AdminMaterialPublicationsPageState
    extends State<AdminMaterialPublicationsPage> {
  final ApiService _api = ApiService();
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _api.getAdminMaterialPublications(status: 'pending');
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(Map<String, dynamic> item) async {
    final int? id = int.tryParse(item['id']?.toString() ?? '');
    if (id == null) return;
    bool forceAnonymous = false;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.eleganceDeepNavy,
          title: const Text(
            'Approva materiale',
            style: TextStyle(color: AppColors.pureWhite),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['attribution_mode'] == 'named'
                    ? 'Lo studente ha richiesto la pubblicazione con nome e cognome.'
                    : 'Lo studente ha richiesto la pubblicazione anonima.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: forceAnonymous,
                title: const Text(
                  'Forza anonimizzazione',
                  style: TextStyle(color: AppColors.pureWhite),
                ),
                subtitle: const Text(
                  'Usalo se il materiale è valido ma l’attribuzione pubblica non è appropriata.',
                  style: TextStyle(color: Colors.white38, fontSize: 9),
                ),
                onChanged: (value) =>
                    setDialogState(() => forceAnonymous = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Approva'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    await _api.approveAdminMaterialPublication(
      requestId: id,
      data: {
        'approved_action': 'publish_new',
        'force_anonymous': forceAnonymous,
      },
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkElegance,
      appBar: AppBar(
        backgroundColor: AppColors.brandNightBlue,
        foregroundColor: AppColors.pureWhite,
        title: const Text('Proposte materiali'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  ..._items.map(
                    (item) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.eleganceMidnight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 7,
                            children: [
                              const _PublicationBadge(
                                text: 'PROPOSTA STUDENTE',
                              ),
                              _PublicationBadge(
                                text: item['attribution_mode'] == 'named'
                                    ? 'CON NOME'
                                    : 'ANONIMO',
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item['title']?.toString() ?? 'Materiale',
                            style: const TextStyle(
                              color: AppColors.pureWhite,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['original_name']?.toString() ?? '',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              onPressed: () => _approve(item),
                              icon: const Icon(Icons.check_rounded),
                              label: const Text('Revisiona e approva'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _PublicationBadge extends StatelessWidget {
  final String text;
  const _PublicationBadge({required this.text});

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
