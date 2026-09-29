import 'package:flutter/material.dart';

import 'package:fe/theme/app_palette.dart';

/// Sorgente dei file del catalogo. La struttura per gli studenti è una sola;
/// la sorgente dice solo dove stanno fisicamente i byte.
enum CatalogSource { drive, mega }

extension CatalogSourceInfo on CatalogSource {
  String get label => switch (this) {
        CatalogSource.drive => 'Google Drive',
        CatalogSource.mega => 'MEGA',
      };

  String get shortLabel => switch (this) {
        CatalogSource.drive => 'Drive',
        CatalogSource.mega => 'MEGA',
      };

  /// Lettera dell'etichetta: la sorgente non si riconosce mai dal solo colore.
  String get letter => switch (this) {
        CatalogSource.drive => 'G',
        CatalogSource.mega => 'M',
      };

  /// Valore che viaggia verso il server (campo `storage_provider`).
  String get apiValue => name;

  /// Colore di sorgente: tenue, diverso dai colori di stato (visibile/errore)
  /// e dall'azzurro dei comandi. Sul tema chiaro si usa una tinta più scura per il contrasto.
  Color color(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return switch (this) {
      CatalogSource.drive => dark ? const Color(0xFF7FD1AE) : const Color(0xFF2E7D5B),
      CatalogSource.mega => dark ? const Color(0xFFF2A0A6) : const Color(0xFFB23A48),
    };
  }

  static CatalogSource? fromApi(Object? value) => switch ('$value') {
        'drive' => CatalogSource.drive,
        'mega' => CatalogSource.mega,
        _ => null,
      };
}

/// Sorgente di un materiale del catalogo: `storage_provider` se il server lo manda,
/// altrimenti Drive quando c'è `drive_file_id` (catalogo attuale).
CatalogSource? sourceOfMaterial(Map<String, dynamic> row) =>
    CatalogSourceInfo.fromApi(row['storage_provider']) ??
    ('${row['drive_file_id'] ?? ''}'.trim().isNotEmpty ? CatalogSource.drive : null);

/// Etichetta quadrata "G" / "M" accanto al nome del file.
class CatalogSourceBadge extends StatelessWidget {
  final CatalogSource source;
  final double size;

  const CatalogSourceBadge({super.key, required this.source, this.size = 20});

  @override
  Widget build(BuildContext context) {
    final Color c = source.color(context);
    return Semantics(
      label: 'Sorgente ${source.label}',
      child: Tooltip(
        message: source.label,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: c.withValues(alpha: 0.55)),
          ),
          child: ExcludeSemantics(
            child: Text(source.letter,
                style: TextStyle(color: c, fontSize: size * 0.52, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
          ),
        ),
      ),
    );
  }
}

/// Tasto "Google Drive | MEGA": si vede una sorgente alla volta.
class CatalogSourceSwitch extends StatelessWidget {
  final CatalogSource value;
  final ValueChanged<CatalogSource> onChanged;

  /// Numero di file nel catalogo per sorgente (facoltativo).
  final Map<CatalogSource, int> counts;

  /// A tutta larghezza (telefono) invece che compatto (barra del PC).
  final bool expand;

  const CatalogSourceSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.counts = const <CatalogSource, int>{},
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget item(CatalogSource s) {
      final bool on = s == value;
      final Widget label = Text(s.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            color: on ? p.pureWhite : p.pureWhite.withValues(alpha: 0.72),
            fontWeight: on ? FontWeight.w700 : FontWeight.w500,
          ));
      return Padding(
        padding: const EdgeInsets.all(2),
        child: Semantics(
          button: true,
          selected: on,
          label: 'Mostra ${s.label}',
          child: Material(
            color: on ? p.skyBlue.withValues(alpha: 0.14) : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
              side: BorderSide(color: on ? p.skyBlue.withValues(alpha: 0.40) : Colors.transparent),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: on ? null : () => onChanged(s),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 40),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: s.color(context), shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    // Flexible solo a tutta larghezza: nella barra del PC la larghezza non è limitata
                    if (expand) Flexible(child: label) else label,
                    if (counts[s] != null) ...<Widget>[
                      const SizedBox(width: 6),
                      Text('${counts[s]}',
                          style: TextStyle(fontSize: 10.5, fontFamily: 'monospace', color: p.pureWhite.withValues(alpha: 0.56))),
                    ],
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final Widget row = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: <Widget>[
        for (final CatalogSource s in CatalogSource.values) expand ? Expanded(child: item(s)) : item(s),
      ],
    );
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: p.darkElegance,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.pureWhite.withValues(alpha: 0.08)),
      ),
      child: row,
    );
  }
}

/// Barra di utilizzo (spazio o traffico).
class SourceUsageBar extends StatelessWidget {
  final String label;
  final int? used;
  final int? limit;
  final Color color;

  const SourceUsageBar({super.key, required this.label, required this.used, required this.limit, required this.color});

  /// Il server può mandare i byte come intero, decimale o testo.
  static int? toInt(Object? value) => value is num ? value.toInt() : int.tryParse('${value ?? ''}');

  static String bytes(int? value) {
    if (value == null) return '—';
    const List<String> units = <String>['B', 'KB', 'MB', 'GB', 'TB'];
    double v = value.toDouble();
    int i = 0;
    while (v >= 1024 && i < units.length - 1) {
      v /= 1024;
      i++;
    }
    return '${v >= 100 || i == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1).replaceAll('.', ',')} ${units[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final double? ratio = used != null && limit != null && limit! > 0 ? (used! / limit!).clamp(0.0, 1.0) : null;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: <Widget>[
      Row(children: <Widget>[
        Expanded(child: Text(label, style: TextStyle(fontSize: 11.5, color: p.pureWhite.withValues(alpha: 0.66)))),
        Text(limit == null ? bytes(used) : '${bytes(used)} / ${bytes(limit)}',
            style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: p.pureWhite.withValues(alpha: 0.66))),
      ]),
      const SizedBox(height: 5),
      ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          value: ratio ?? 0,
          minHeight: 6,
          color: (ratio ?? 0) > 0.9 ? p.adminCoral : color,
          backgroundColor: p.pureWhite.withValues(alpha: 0.08),
          semanticsLabel: label,
        ),
      ),
    ]);
  }
}
