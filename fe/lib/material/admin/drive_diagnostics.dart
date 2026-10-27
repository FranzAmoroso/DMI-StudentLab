import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../services/user_facing_error.dart';
import '../../social/admin/admin_material_storage_api_service.dart';

/// «Verifica collegamento Drive»: mostra i controlli passo per passo con frasi
/// semplici e suggerimenti. I dettagli tecnici restano nel registro diagnostico.
Future<void> showDriveDiagnostics(BuildContext context, AdminMaterialStorageApiService api) async {
  await showDialog<void>(context: context, builder: (_) => _DriveDiagnosticsDialog(api: api));
}

/// Salva il registro diagnostico (ultimi giorni) come file di testo.
Future<void> downloadDiagnosticLog(BuildContext context, AdminMaterialStorageApiService api, {int days = 7}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final bytes = await api.downloadDiagnosticLog(days: days);
    final now = DateTime.now();
    final stamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final saved = await FilePicker.saveFile(
      dialogTitle: 'Salva il registro diagnostico',
      fileName: 'studentlab-diagnostica-$stamp.txt',
      bytes: bytes,
    );
    if (!kIsWeb && saved == null) return; // salvataggio annullato
    messenger.showSnackBar(const SnackBar(content: Text('Registro diagnostico salvato.')));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(friendlyError(e, 'Registro non disponibile. Riprova tra poco.'))));
  }
}

class _DriveDiagnosticsDialog extends StatefulWidget {
  final AdminMaterialStorageApiService api;
  const _DriveDiagnosticsDialog({required this.api});
  @override
  State<_DriveDiagnosticsDialog> createState() => _DriveDiagnosticsDialogState();
}

class _DriveDiagnosticsDialogState extends State<_DriveDiagnosticsDialog> {
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() { _result = null; _error = null; });
    try {
      final value = await widget.api.diagnoseDrive();
      if (mounted) setState(() => _result = value);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e, 'Verifica non riuscita. Riprova tra poco.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final checks = (_result?['checks'] as List? ?? const []).whereType<Map>().toList();
    final width = MediaQuery.sizeOf(context).width;
    return AlertDialog(
      title: const Text('Verifica collegamento Drive'),
      content: SizedBox(
        width: width < 560 ? width - 48 : 480,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (_result == null && _error == null) const LinearProgressIndicator(),
            if (_error != null) Text(_error!, style: TextStyle(color: scheme.error)),
            if (_result != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_result!['ok'] == true
                    ? 'Tutto funziona: StudentLab può leggere e caricare su Drive.'
                    : 'C’è un problema. Segui il suggerimento del primo controllo non riuscito.'),
              ),
            for (final c in checks)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(c['ok'] == true ? Icons.check_circle_outline : Icons.error_outline,
                    color: c['ok'] == true ? Colors.green : scheme.error),
                title: Text('${c['label']}'),
                subtitle: Text([
                  if ('${c['message'] ?? ''}'.isNotEmpty) '${c['message']}',
                  if ('${c['suggestion'] ?? ''}'.isNotEmpty) '${c['suggestion']}',
                  if (c['ok'] != true && c['code'] != null) 'Codice ${c['code']}',
                ].join('\n')),
              ),
          ]),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => downloadDiagnosticLog(context, widget.api),
          child: const Text('Scarica registro'),
        ),
        TextButton(onPressed: _run, child: const Text('Ripeti')),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Chiudi')),
      ],
    );
  }
}
