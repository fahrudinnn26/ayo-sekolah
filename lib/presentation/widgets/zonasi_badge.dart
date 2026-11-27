import 'package:ayo_sekolah/core/constants/app_theme.dart';
import 'package:ayo_sekolah/core/constants/ppdb_constants.dart';
import 'package:ayo_sekolah/core/utils/haversine_calculator.dart';
import 'package:material_ui/material_ui.dart';

/// Badge indikator status zonasi berbasis warna beserta jarak terformat (m/km).
///
/// Aturan warna semantik sesuai [PpdbConstants]:
/// - `<= 800 m` -> Hijau (**Sangat Aman**)
/// - `801–1500 m` -> Oranye/Kuning (**Waspada**)
/// - `> 1500 m` -> Merah (**Berisiko**)
class ZonasiBadge extends StatelessWidget {
  const ZonasiBadge({
    super.key,
    required this.jarakMeter,
    this.showDistance = true,
    this.compact = false,
  });

  /// Jarak garis lurus (Haversine) dalam satuan meter.
  final double jarakMeter;

  /// Menampilkan jarak terformat (m/km) berdampingan dengan label status zonasi.
  final bool showDistance;

  /// Gunakan tampilan padding dan teks lebih ringkas untuk ruang terbatas.
  final bool compact;

  /// Mengembalikan warna teks/ikon sesuai [status].
  static Color foregroundColorFor(StatusZonasi status) {
    switch (status) {
      case StatusZonasi.sangatAman:
        return AppTheme.statusAman;
      case StatusZonasi.waspada:
        return AppTheme.statusWaspada;
      case StatusZonasi.berisiko:
        return AppTheme.statusBerisiko;
    }
  }

  /// Mengembalikan warna latar badge sesuai [status].
  static Color backgroundColorFor(StatusZonasi status) {
    switch (status) {
      case StatusZonasi.sangatAman:
        return AppTheme.statusAmanBackground;
      case StatusZonasi.waspada:
        return AppTheme.statusWaspadaBackground;
      case StatusZonasi.berisiko:
        return AppTheme.statusBerisikoBackground;
    }
  }

  /// Mengembalikan ikon indikator sesuai [status].
  static IconData iconFor(StatusZonasi status) {
    switch (status) {
      case StatusZonasi.sangatAman:
        return Icons.check_circle_rounded;
      case StatusZonasi.waspada:
        return Icons.warning_amber_rounded;
      case StatusZonasi.berisiko:
        return Icons.error_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final StatusZonasi status =
        HaversineCalculator.tentukanStatusZonasi(jarakMeter);
    final String jarakText = HaversineCalculator.formatJarak(jarakMeter);
    final Color foreground = foregroundColorFor(status);
    final Color background = backgroundColorFor(status);
    final IconData icon = iconFor(status);

    final String labelText =
        showDistance ? '$jarakText • ${status.label}' : status.label;

    return Semantics(
      label: 'Jarak $jarakText, status zonasi ${status.label}',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: foreground.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: compact ? 14 : 16,
              color: foreground,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                labelText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
