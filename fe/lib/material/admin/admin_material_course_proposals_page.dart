import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/auth_session.dart';
import '../../theme/nightTheme.dart';

class AdminMaterialCourseProposalsPage extends StatefulWidget {
  const AdminMaterialCourseProposalsPage({super.key});

  @override
  State<AdminMaterialCourseProposalsPage> createState() =>
      _AdminMaterialCourseProposalsPageState();
}

class _AdminMaterialCourseProposalsPageState
    extends State<AdminMaterialCourseProposalsPage> {
  static const _base = 'https://dmi-student-lab.vercel.app';
  List<Map<String, dynamic>> _items = [];
  String? _error;
  bool _loading = true;
  int? _busyId;

  Map<String, String> get _headers {
    final token = AuthSession.instance.accessToken;
    if (token == null || token.isEmpty) {
      throw StateError('Sessione amministrativa non disponibile.');
    }
    return {'Authorization': 'Bearer $token',
      'Content-Type': 'application/json', 'Accept': 'application/json'};
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _detail(http.Response response) {
    try {
      final value = jsonDecode(response.body);
      if (value is Map && value['detail'] != null) {
        return value['detail'].toString();
      }
    } catch (_) {}
    return 'Operazione non riuscita (${response.statusCode}).';
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final response = await http.get(Uri.parse('$_base/materials/course-proposals/admin'),
        headers: _headers);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(_detail(response));
      }
      final values = jsonDecode(response.body) as List;
      if (mounted) setState(() {
        _items = values.whereType<Map>().map((v) => Map<String, dynamic>.from(v)).toList();
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _decide(Map<String, dynamic> item, bool approve) async {
    final universityCode = TextEditingController();
    final departmentCode = TextEditingController();
    final courseCode = TextEditingController();
    final reason = TextEditingController();
    try {
      final accepted = await showDialog<bool>(context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppColors.eleganceDeepNavy,
          title: Text(approve ? 'Approva corso' : 'Rifiuta proposta',
            style: const TextStyle(color: AppColors.pureWhite)),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
            children: [
              Text('${item['university']} / ${item['department']} / ${item['course']}',
                style: const TextStyle(color: Colors.white70)),
              if (approve) ...[
                TextField(controller: universityCode, decoration: const InputDecoration(
                  labelText: 'Codice ateneo'), style: const TextStyle(color: Colors.white)),
                TextField(controller: departmentCode, decoration: const InputDecoration(
                  labelText: 'Codice dipartimento'), style: const TextStyle(color: Colors.white)),
                TextField(controller: courseCode, decoration: const InputDecoration(
                  labelText: 'Codice corso'), style: const TextStyle(color: Colors.white)),
              ] else TextField(controller: reason, minLines: 2, maxLines: 4,
                decoration: const InputDecoration(labelText: 'Motivo del rifiuto'),
                style: const TextStyle(color: Colors.white)),
            ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annulla')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(approve ? 'Approva' : 'Rifiuta')),
          ],
        ));
      if (accepted != true || !mounted) return;
      final body = approve ? {
        'university_code': universityCode.text.trim(),
        'department_code': departmentCode.text.trim(),
        'course_code': courseCode.text.trim(),
      } : {'reason': reason.text.trim()};
      if (body.values.any((value) => value.length < (approve ? 2 : 3))) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Completa tutti i campi richiesti.')));
        return;
      }
      final id = item['id'] as int;
      setState(() => _busyId = id);
      final response = await http.post(Uri.parse(
        '$_base/materials/course-proposals/admin/$id/${approve ? 'approve' : 'reject'}'),
        headers: _headers, body: jsonEncode(body));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(_detail(response));
      }
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())));
    } finally {
      universityCode.dispose(); departmentCode.dispose();
      courseCode.dispose(); reason.dispose();
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.darkElegance,
    appBar: AppBar(title: const Text('Corsi aggiuntivi'),
      backgroundColor: AppColors.brandNightBlue,
      foregroundColor: AppColors.pureWhite,
      actions: [IconButton(onPressed: _load,
        icon: const Icon(Icons.refresh_rounded))]),
    body: _loading ? const Center(child: CircularProgressIndicator())
      : _error != null ? Center(child: Text(_error!,
          style: const TextStyle(color: AppColors.pureWhite)))
      : RefreshIndicator(onRefresh: _load,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            const Text('Proposte di percorsi accademici', style: TextStyle(
              color: AppColors.pureWhite, fontSize: 21, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            for (final item in _items) Card(
              color: AppColors.eleganceMidnight,
              child: Padding(padding: const EdgeInsets.all(16), child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item['course']?.toString() ?? '', style: const TextStyle(
                    color: AppColors.pureWhite, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('${item['university']} / ${item['department']}',
                    style: const TextStyle(color: Colors.white70)),
                  Text('Stato: ${item['status']}',
                    style: const TextStyle(color: Colors.white70)),
                  if (item['status'] == 'pending') Wrap(spacing: 8, children: [
                    OutlinedButton(onPressed: _busyId == null
                        ? () => _decide(item, true) : null,
                      child: const Text('Approva')),
                    OutlinedButton(onPressed: _busyId == null
                        ? () => _decide(item, false) : null,
                      child: const Text('Rifiuta')),
                  ]),
                ]))),
          ])),
  );
}
