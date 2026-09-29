import 'temporary_transfer_page.dart';
import 'package:flutter/material.dart';

import 'package:fe/theme/app_palette.dart';
import '../../social/admin/admin_material_storage_api_service.dart';
import 'admin_drive_catalog_page.dart';
import 'catalog_source.dart';
import 'mega_storage_api_service.dart';

/// Admin › Materiali e storage › Sorgenti: Google Drive e MEGA, con spazio,
/// traffico e permessi verificati dal server. Su telefono le schede vanno in colonna,
/// su tablet in due colonne, su PC in tre.
class AdminStorageSourcesPage extends StatefulWidget {
  /// Aperta dal catalogo: "Esplora" torna al catalogo con la sorgente scelta invece di aprirne un altro.
  final bool returnSource;

  const AdminStorageSourcesPage({super.key, this.returnSource = false});

  @override
  State<AdminStorageSourcesPage> createState() => _AdminStorageSourcesPageState();
}

class _AdminStorageSourcesPageState extends State<AdminStorageSourcesPage> {
  final AdminMaterialStorageApiService _drive = AdminMaterialStorageApiService();
  final MegaStorageApiService _mega = MegaStorageApiService();
  Map<String, dynamic>? _driveStatus;
  Map<String, dynamic>? _megaStatus;
  String? _driveError;
  String? _megaError;
  bool _megaMissing = false;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await Future.wait<void>(<Future<void>>[_loadDrive(), _loadMega()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadDrive() async {
    try {
      final Map<String, dynamic> value = await _drive.getDriveStatus();
      if (mounted) setState(() { _driveStatus = value; _driveError = null; });
    } catch (error) {
      if (mounted) setState(() => _driveError = _clean(error, 'Stato di Google Drive non disponibile.'));
    }
  }

  Future<void> _loadMega() async {
    try {
      final Map<String, dynamic> value = await _mega.status();
      if (mounted) setState(() { _megaStatus = value; _megaError = null; _megaMissing = false; });
    } on MegaNotAvailable catch (error) {
      if (mounted) setState(() { _megaStatus = null; _megaMissing = true; _megaError = error.message; });
    } catch (error) {
      if (mounted) setState(() { _megaStatus = null; _megaMissing = false; _megaError = _clean(error, 'Stato di MEGA non disponibile.'); });
    }
  }

  String _clean(Object error, String fallback) {
    final String text = error.toString().replaceFirst('Exception: ', '').trim();
    return text.isEmpty ? fallback : text;
  }

  int? _int(Object? value) => SourceUsageBar.toInt(value);

  Future<void> _verifyMega() async {
    setState(() => _busy = true);
    try {
      final Map<String, dynamic> result = await _mega.verify();
      if (!mounted) return;
      await _showChecks(result);
      await _loadMega();
    } catch (error) {
      _snack(_clean(error, 'Verifica non riuscita.'));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _disconnectMega() async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        title: const Text('Scollegare MEGA?'),
        content: const Text('La sessione sul server viene chiusa. I file su MEGA non vengono toccati; '
            'le copie già su Drive restano disponibili.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Scollega')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _mega.disconnect();
      await _loadMega();
    } catch (error) {
      _snack(_clean(error, 'Scollegamento non riuscito.'));
    }
    if (mounted) setState(() => _busy = false);
  }

  void _snack(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _connectPublic() async {
    final controller = TextEditingController();
    final link = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Collega cartella MEGA'),
      content: SizedBox(width: 460, child: TextField(controller: controller,
        decoration: const InputDecoration(labelText: 'Link completo, inclusa la chiave dopo #'), maxLines: 3)),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
        FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Collega'))],
    ));
    controller.dispose();
    if (link == null || link.isEmpty || !mounted) return;
    setState(() => _busy = true);
    try { await _mega.connectPublic(link); await _loadMega(); }
    catch (e) { _snack(_clean(e, 'Cartella MEGA non collegata.')); }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _connectMega() async {
    final Map<String, dynamic>? result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ConnectMegaDialog(api: _mega),
    );
    if (result == null || !mounted) return;
    await _showChecks(result);
    await _loadMega();
  }

  Future<void> _showChecks(Map<String, dynamic> result) async {
    final List<Map<String, dynamic>> checks = (result['checks'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((Map e) => Map<String, dynamic>.from(e))
        .toList();
    if (checks.isEmpty || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        title: const Text('Verifica dei permessi'),
        content: SizedBox(width: 520, child: _ChecksList(checks: checks)),
        actions: <Widget>[FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Chiudi'))],
      ),
    );
  }

  void _openCatalog(CatalogSource source) {
    if (widget.returnSource) {
      Navigator.of(context).pop(source);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AdminDriveCatalogPage(initialSource: source)));
  }

  Widget _driveCard() {
    final Map<String, dynamic>? s = _driveStatus;
    final bool configured = s?['configured'] == true;
    return _SourceCard(
      source: CatalogSource.drive,
      title: 'Google Drive',
      subtitle: _driveError ??
          (configured ? '${s?['account'] ?? '—'} · cartella StudentLab' : 'Non configurato sul server (variabili Drive).'),
      state: _driveError != null ? _CardState.error : (configured ? _CardState.ok : _CardState.off),
      usage: <Widget>[
        if (configured)
          SourceUsageBar(label: 'Spazio', used: _int(s?['used_bytes']), limit: _int(s?['limit_bytes']),
              color: CatalogSource.drive.color(context)),
      ],
      // /drive/status risponde "configured" solo dopo aver letto account e quota e aver
      // controllato che la cartella radice accetti nuovi file (canAddChildren): è una verifica vera.
      permissions: <(String, bool?)>[
        if (configured) ...<(String, bool?)>[
          ('Lettura della cartella StudentLab', true),
          ('Scrittura nella cartella radice', true),
        ],
      ],
      actions: <Widget>[
        OutlinedButton.icon(onPressed: _busy ? null : _loadDrive, icon: const Icon(Icons.verified_user_outlined, size: 18),
            label: const Text('Verifica')),
        OutlinedButton.icon(onPressed: configured ? () => _openCatalog(CatalogSource.drive) : null,
            icon: const Icon(Icons.folder_open_outlined, size: 18), label: const Text('Esplora')),
      ],
    );
  }

  Widget _megaCard() {
    final Map<String, dynamic>? s = _megaStatus;
    final bool configured = s?['configured'] == true;
    final Map<String, dynamic> perms = s?['permissions'] is Map ? Map<String, dynamic>.from(s!['permissions'] as Map) : const <String, dynamic>{};
    bool? flag(String key) => perms.containsKey(key) ? perms[key] == true : null;
    final int? publicLinks = _int(s?['public_links']);
    return _SourceCard(
      source: CatalogSource.mega,
      title: 'MEGA',
      subtitle: _megaMissing
          ? 'Il server non ha ancora il servizio MEGA: va installato insieme a questa pagina.'
          : (_megaError ?? (configured ? '${s?['account'] ?? '—'} · ${s?['root_folder'] ?? '/StudentLab'}' : 'Nessun account collegato.')),
      state: _megaMissing ? _CardState.off : (_megaError != null ? _CardState.error : (configured ? _CardState.ok : _CardState.off)),
      usage: <Widget>[
        if (configured) ...<Widget>[
          SourceUsageBar(label: 'Spazio', used: _int(s?['used_bytes']), limit: _int(s?['limit_bytes']),
              color: CatalogSource.mega.color(context)),
          const SizedBox(height: 10),
          SourceUsageBar(label: 'Traffico di download (quota di trasferimento)', used: _int(s?['transfer_used_bytes']),
              limit: _int(s?['transfer_limit_bytes']), color: context.palette.adminAmber),
        ],
      ],
      permissions: <(String, bool?)>[
        if (configured) ...<(String, bool?)>[
          ('Lettura', flag('read')),
          ('Sorgente in sola lettura: originali conservati', true),
          if (publicLinks != null) (publicLinks == 0 ? 'Nessun link pubblico attivo' : '$publicLinks link pubblici attivi', publicLinks == 0),
        ],
      ],
      actions: <Widget>[
        OutlinedButton.icon(onPressed: _busy || _megaMissing ? null : _connectPublic, icon: const Icon(Icons.link), label: const Text('Collega cartella condivisa')),
        FilledButton.icon(onPressed: _busy || _megaMissing ? null : _connectMega, icon: const Icon(Icons.link_rounded, size: 18),
              label: Text(configured ? 'Ricollega account MEGA' : 'Collega MEGA')),
        if (configured) ...<Widget>[
          OutlinedButton.icon(onPressed: _busy ? null : _verifyMega, icon: const Icon(Icons.verified_user_outlined, size: 18),
              label: const Text('Verifica')),
          OutlinedButton.icon(onPressed: () => _openCatalog(CatalogSource.mega), icon: const Icon(Icons.folder_open_outlined, size: 18),
              label: const Text('Esplora')),
          TextButton(onPressed: _busy ? null : _disconnectMega, child: const Text('Scollega')),
        ],
      ],
    );
  }

  Widget _rulesCard() {
    final p = context.palette;
    Widget line(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Icon(icon, size: 17, color: p.skyBlue),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: TextStyle(fontSize: 13, height: 1.35, color: p.pureWhite))),
          ]),
        );
    return _Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
        Text('COME FUNZIONANO LE SORGENTI', style: TextStyle(fontSize: 10.5, letterSpacing: 1.2, fontWeight: FontWeight.w700,
            color: p.pureWhite.withValues(alpha: 0.66))),
        const SizedBox(height: 12),
        line(Icons.layers_outlined, 'La struttura per gli studenti è una sola. I materiali provenienti da MEGA vengono prima copiati su Drive.'),
        line(Icons.lock_outline_rounded, 'Solo admin e creator collegano le sorgenti e pubblicano la struttura.'),
        line(Icons.download_outlined, 'Gli studenti scaricano sempre tramite StudentLab e non vedono da quale sorgente arriva il file.'),
        line(Icons.link_off_rounded, 'La sorgente MEGA è visibile agli admin; gli originali sono conservati e i link non vengono mostrati agli studenti.'),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.darkElegance,
      appBar: AppBar(
        backgroundColor: p.brandNightBlue,
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text('ADMIN / MATERIALI E STORAGE', style: TextStyle(fontSize: 10, letterSpacing: 1.5), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('Sorgenti del catalogo', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ]),
        actions: <Widget>[
          IconButton(tooltip: 'Carica su Drive o MEGA', icon: const Icon(Icons.upload_file), onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TemporaryTransferPage()))),
          IconButton(tooltip: 'Aggiorna', onPressed: _loading || _busy ? null : _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: p.skyBlue))
          : LayoutBuilder(builder: (BuildContext context, BoxConstraints box) {
              final int columns = box.maxWidth >= 1100 ? 3 : (box.maxWidth >= 640 ? 2 : 1);
              final double gap = columns == 1 ? 12 : 16;
              final double width = (box.maxWidth - 32 - gap * (columns - 1)) / columns;
              return ListView(padding: const EdgeInsets.all(16), children: <Widget>[
                if (_busy) Padding(padding: const EdgeInsets.only(bottom: 8), child: LinearProgressIndicator(minHeight: 2, color: p.skyBlue)),
                Wrap(spacing: gap, runSpacing: gap, children: <Widget>[
                  SizedBox(width: width, child: _driveCard()),
                  SizedBox(width: width, child: _megaCard()),
                  SizedBox(width: columns == 3 ? width : box.maxWidth - 32, child: _rulesCard()),
                ]),
              ]);
            }),
    );
  }
}

enum _CardState { ok, off, error }

class _Panel extends StatelessWidget {
  final Widget child;
  final Color? border;
  const _Panel({required this.child, this.border});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.eleganceMidnight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border ?? p.surfaceBorder),
      ),
      child: child,
    );
  }
}

class _SourceCard extends StatelessWidget {
  final CatalogSource source;
  final String title;
  final String subtitle;
  final _CardState state;
  final List<Widget> usage;
  final List<(String, bool?)> permissions;
  final List<Widget> actions;

  const _SourceCard({
    required this.source,
    required this.title,
    required this.subtitle,
    required this.state,
    required this.usage,
    required this.permissions,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final Color c = source.color(context);
    final (String, Color) badge = switch (state) {
      _CardState.ok => ('COLLEGATO', p.adminGreen),
      _CardState.off => ('NON COLLEGATO', p.pureWhite.withValues(alpha: 0.6)),
      _CardState.error => ('DA CONTROLLARE', p.adminCoral),
    };
    return _Panel(
      border: c.withValues(alpha: 0.4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: c.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.cloud_outlined, color: c),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: p.pureWhite)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 12.5, color: p.pureWhite.withValues(alpha: 0.66))),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: badge.$2.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: badge.$2.withValues(alpha: 0.35)),
            ),
            child: Text(badge.$1, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, fontFamily: 'monospace', color: badge.$2)),
          ),
        ]),
        if (usage.isNotEmpty) ...<Widget>[const SizedBox(height: 14), ...usage],
        if (permissions.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          for (final (String label, bool? ok) in permissions)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(children: <Widget>[
                Icon(ok == null ? Icons.help_outline_rounded : (ok ? Icons.check_rounded : Icons.error_outline_rounded),
                    size: 16, color: ok == null ? p.pureWhite.withValues(alpha: 0.5) : (ok ? p.adminGreen : p.adminAmber)),
                const SizedBox(width: 6),
                Expanded(child: Text(ok == null ? '$label · non verificato' : label, style: TextStyle(fontSize: 12.5, color: p.pureWhite))),
              ]),
            ),
        ],
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: actions),
      ]),
    );
  }
}

class _ChecksList extends StatelessWidget {
  final List<Map<String, dynamic>> checks;
  const _ChecksList({required this.checks});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
      for (final Map<String, dynamic> check in checks)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: p.darkElegance, borderRadius: BorderRadius.circular(12)),
          child: Row(children: <Widget>[
            Icon(
              check['ok'] == true && check['warning'] != true ? Icons.check_circle_outline_rounded
                  : (check['warning'] == true ? Icons.info_outline_rounded : Icons.cancel_outlined),
              size: 18,
              color: check['ok'] == true && check['warning'] != true ? p.adminGreen
                  : (check['warning'] == true ? p.adminAmber : p.adminCoral),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text('${check['label'] ?? ''}', style: TextStyle(fontSize: 13.5, color: p.pureWhite))),
            if ((check['detail']?.toString() ?? '').isNotEmpty)
              Flexible(
                child: Text('${check['detail']}',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: p.pureWhite.withValues(alpha: 0.6))),
              ),
          ]),
        ),
    ]);
  }
}

/// Collega MEGA: account dedicato, password e codice 2FA usati solo per aprire la sessione.
class _ConnectMegaDialog extends StatefulWidget {
  final MegaStorageApiService api;
  const _ConnectMegaDialog({required this.api});

  @override
  State<_ConnectMegaDialog> createState() => _ConnectMegaDialogState();
}

class _ConnectMegaDialogState extends State<_ConnectMegaDialog> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _code = TextEditingController();
  final TextEditingController _root = TextEditingController(text: '/StudentLab');
  bool _hide = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _code.dispose();
    _root.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty || !_root.text.trim().startsWith('/')) {
      setState(() => _error = 'Servono email, password e una cartella che inizi con /.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final Map<String, dynamic> result = await widget.api.connect(
          email: _email.text, password: _password.text, secondFactorCode: _code.text, rootFolder: _root.text);
      _password.clear();
      if (mounted) Navigator.pop(context, result);
    } catch (error) {
      _password.clear();
      if (mounted) {
        setState(() {
          _busy = false;
          _error = error.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AlertDialog(
      title: Row(children: <Widget>[
        Icon(Icons.cloud_outlined, color: CatalogSource.mega.color(context)),
        const SizedBox(width: 10),
        const Text('Collega MEGA'),
      ]),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: p.skyBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: p.skyBlue.withValues(alpha: 0.3)),
              ),
              child: Text('Usa un account MEGA dedicato a StudentLab, con verifica in due passaggi. '
                  'Sul server resta solo la sessione cifrata: password e codice non vengono salvati.',
                  style: TextStyle(fontSize: 12.5, height: 1.4, color: p.pureWhite)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _email,
              enabled: !_busy,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const <String>[AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email dell’account MEGA'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _password,
              enabled: !_busy,
              obscureText: _hide,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  tooltip: _hide ? 'Mostra' : 'Nascondi',
                  onPressed: () => setState(() => _hide = !_hide),
                  icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _code,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(labelText: 'Codice di verifica (2FA)', counterText: ''),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _root,
              enabled: !_busy,
              decoration: const InputDecoration(labelText: 'Cartella radice', helperText: 'StudentLab legge e scrive solo qui dentro'),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: p.adminCoral, fontSize: 13)),
            ],
          ]),
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Annulla')),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(_busy ? 'Verifico i permessi…' : 'Collega e verifica'),
        ),
      ],
    );
  }
}
