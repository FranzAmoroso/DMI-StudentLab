import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/nightTheme.dart';

class TeacherMaterialRequestsPage extends StatefulWidget {
  const TeacherMaterialRequestsPage({super.key});

  @override
  State<TeacherMaterialRequestsPage> createState() =>
      _TeacherMaterialRequestsPageState();
}

class _TeacherMaterialRequestsPageState
    extends State<TeacherMaterialRequestsPage> {
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
      final values = await _api.getTeacherMaterialRequests();
      if (!mounted) return;
      setState(() {
        _items = values;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reject(Map<String, dynamic> item) async {
    final int? id = int.tryParse(item['id']?.toString() ?? '');
    if (id == null) return;
    await _api.resolveTeacherMaterialRequest(requestId: id, action: 'rejected');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkElegance,
      appBar: AppBar(
        backgroundColor: AppColors.brandNightBlue,
        foregroundColor: AppColors.pureWhite,
        title: const Text('Richieste materiali'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_items.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(30),
                        child: Text(
                          'Nessuna richiesta disponibile.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    )
                  else
                    ..._items.map(
                      (item) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.eleganceMidnight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.teacherIndigo.withValues(
                              alpha: 0.15,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              children: [
                                _Badge(text: 'RICHIESTA STUDENTE'),
                                _Badge(
                                  text:
                                      (item['status']?.toString() ?? 'pending')
                                          .toUpperCase(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if ((item['topic']?.toString().trim() ?? '')
                                .isNotEmpty)
                              Text(
                                item['topic'].toString(),
                                style: const TextStyle(
                                  color: AppColors.pureWhite,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            const SizedBox(height: 6),
                            Text(
                              item['message']?.toString() ?? '',
                              style: const TextStyle(
                                color: Colors.white70,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (item['status'] == 'pending')
                              Align(
                                alignment: Alignment.centerRight,
                                child: OutlinedButton(
                                  onPressed: () => _reject(item),
                                  child: const Text('Rifiuta richiesta'),
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

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

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
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
