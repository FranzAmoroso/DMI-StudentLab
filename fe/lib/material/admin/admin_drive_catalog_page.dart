import 'package:flutter/material.dart';

import '../../social/admin/admin_material_storage_api_service.dart';
import '../../theme/nightTheme.dart';
import 'drive_file_preview.dart';

/// Esplora le risorse esistenti. Solo un'importazione esplicita le pubblica.
class AdminDriveCatalogPage extends StatefulWidget {
  const AdminDriveCatalogPage({super.key});

  @override
  State<AdminDriveCatalogPage> createState() => _AdminDriveCatalogPageState();
}

class _AdminDriveCatalogPageState extends State<AdminDriveCatalogPage> {
  final _api = AdminMaterialStorageApiService();
  final List<(String?, String)> _trail = [(null, 'Drive StudentLab')];
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _nextPage;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _api.getDriveTree(_trail.last.$1);
      if (!mounted) return;
      final values = result['items'] as List? ?? [];
      setState(() { _items = values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _nextPage = result['next_page_token']?.toString(); _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Impossibile leggere questa cartella Drive. $e\nSe il server risponde 404, pubblica il backend aggiornato.';
        _loading = false; });
    }
  }

  Future<void> _more() async {
    final token = _nextPage;
    if (token == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final result = await _api.getDriveTree(_trail.last.$1, token);
      if (!mounted) return;
      setState(() {
        _items.addAll((result['items'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map)));
        _nextPage = result['next_page_token']?.toString();
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _import(Map<String, dynamic> file) async {
    List<Map<String, dynamic>> subjects;
    try {
      subjects = await _api.getDriveImportOptions();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      return;
    }
    if (!mounted) return;
    final target = TextEditingController();
    int? subjectId;
    String subjectQuery = '';
    String audience = 'public';
    final selected = await showDialog<(int, String, int?)>(context: context,
      builder: (context) => StatefulBuilder(builder: (context, update) => AlertDialog(
        title: const Text('Registra in StudentLab'),
        content: SizedBox(width: 440, child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(file['name']?.toString() ?? '', maxLines: 2,
              overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            const Text('Scegli la materia del catalogo e chi potrà vedere il file.'),
            TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search),
              labelText: 'Cerca materia o corso'),
              onChanged: (value) => update(() => subjectQuery = value)),
            SizedBox(height: 170, child: ListView(children: [
              for (final option in subjects.where((option) =>
                '${option['name']} ${option['course']} ${option['department']}'
                  .toLowerCase().contains(subjectQuery.toLowerCase())))
                RadioListTile<int>(dense: true,
                  title: Text(option['name']?.toString() ?? ''),
                  subtitle: Text('${option['course']} · anno ${option['year'] ?? '—'}'),
                  value: int.parse(option['id'].toString()),
                  groupValue: subjectId,
                  onChanged: (value) => update(() => subjectId = value)),
            ])),
            DropdownButtonFormField<String>(value: audience,
              items: const [
                DropdownMenuItem(value: 'public', child: Text('Tutti, anche guest')),
                DropdownMenuItem(value: 'course', child: Text('Studenti del corso')),
                DropdownMenuItem(value: 'subject', child: Text('Studenti della materia')),
                DropdownMenuItem(value: 'group', child: Text('Un gruppo')),
                DropdownMenuItem(value: 'user', child: Text('Uno studente')),
              ], onChanged: (value) { if (value != null) update(() => audience = value); }),
            if (audience == 'group' || audience == 'user')
              TextField(controller: target, keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: audience == 'group'
                  ? 'ID gruppo' : 'ID studente')),
          ],
        ))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
          FilledButton(onPressed: () {
            final id = subjectId;
            final recipient = int.tryParse(target.text.trim());
            if (id == null || id <= 0 ||
              ((audience == 'group' || audience == 'user') &&
                (recipient == null || recipient <= 0))) return;
            Navigator.pop(context, (id, audience, recipient));
          }, child: const Text('Pubblica nel catalogo')),
        ],
      )));
    target.dispose();
    if (selected == null || !mounted) return;
    try {
      await _api.importDriveFile(fileId: file['id'].toString(),
        subjectId: selected.$1, audienceType: selected.$2, audienceId: selected.$3);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('File registrato: ora segue i permessi scelti.')));
      await _load();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Importazione non riuscita. Controlla materia, permessi e dimensione (massimo 20 MB).')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final shown = _items.where((e) => (e['name']?.toString() ?? '')
      .toLowerCase().contains(_query.toLowerCase())).toList();
    return Scaffold(
      backgroundColor: AppColors.darkElegance,
      appBar: AppBar(title: const Text('File esistenti su Drive'),
        backgroundColor: AppColors.brandNightBlue,
        foregroundColor: AppColors.pureWhite,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)]),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: Column(children: [
          Text(_trail.map((e) => e.$2).join(' / '),
            style: const TextStyle(color: AppColors.pureWhite),
            overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          const Text('I file esistenti restano privati finché non li registri nel catalogo.',
            style: TextStyle(color: Colors.white70)),
          TextField(style: const TextStyle(color: AppColors.pureWhite),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search),
              hintText: 'Cerca in questa cartella'),
            onChanged: (text) => setState(() => _query = text)),
        ])),
        if (_trail.length > 1)
          ListTile(leading: const Icon(Icons.arrow_upward, color: Colors.white70),
            title: const Text('Cartella precedente', style: TextStyle(color: Colors.white70)),
            onTap: () { _trail.removeLast(); _query = ''; _load(); }),
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
            ? Center(child: Padding(padding: const EdgeInsets.all(20),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!, style: const TextStyle(color: Colors.white70)),
                  TextButton(onPressed: _load, child: const Text('Riprova')),
                ])))
            : shown.isEmpty
              ? const Center(child: Text('Nessun file in questa cartella.',
                style: TextStyle(color: Colors.white70)))
              : ListView.builder(itemCount: shown.length + (_nextPage != null ? 1 : 0), itemBuilder: (context, index) {
                if (index == shown.length) return Center(child: TextButton(
                  onPressed: _loadingMore ? null : _more,
                  child: Text(_loadingMore ? 'Caricamento…' : 'Carica altri file')));
                final item = shown[index];
                final folder = item['mime_type'] == 'application/vnd.google-apps.folder';
                final indexed = item['indexed'] == true;
                return Card(color: AppColors.eleganceMidnight, child: ListTile(
                  leading: Icon(folder ? Icons.folder_outlined : Icons.insert_drive_file_outlined,
                    color: AppColors.materialSky),
                  title: Text(item['name']?.toString() ?? 'Senza nome',
                    style: const TextStyle(color: AppColors.pureWhite)),
                  subtitle: Text(folder ? 'Cartella' : indexed ? 'Già nel catalogo'
                    : 'Solo su Drive · non visibile agli studenti',
                    style: const TextStyle(color: Colors.white70)),
                  onTap: folder ? () { _trail.add((item['id'].toString(),
                    item['name'].toString())); _query = ''; _load(); } : null,
                  trailing: folder ? const Icon(Icons.chevron_right, color: Colors.white70)
                    : Wrap(children: [
                      IconButton(tooltip: 'Anteprima', icon: const Icon(Icons.visibility_outlined),
                        onPressed: () => showDriveFilePreview(context,
                          load: () => _api.downloadDriveFilePreview(item['id'].toString()),
                          name: item['name']?.toString() ?? 'File',
                          mimeType: item['mime_type']?.toString() ?? 'application/octet-stream')),
                      if (!indexed) IconButton(tooltip: 'Classifica e pubblica',
                        icon: const Icon(Icons.library_add_outlined),
                        onPressed: () => _import(item)),
                    ]),
                ));
              })),
      ]),
    );
  }
}
