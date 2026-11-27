import 'package:ayo_sekolah/core/constants/app_theme.dart';
import 'package:material_ui/material_ui.dart';

/// Indikator chip/badge ringkas status koneksi Cloud Firestore.
///
/// Menampilkan **"Cloud Terhubung"** (warna hijau) saat aplikasi tersambung ke
/// Cloud Firestore sungguhan, atau **"Mode Lokal"** (warna abu-abu) saat
/// berjalan pada mode fallback in-memory.
class CloudStatusBadge extends StatelessWidget {
  const CloudStatusBadge({
    super.key,
    required this.isCloudConnected,
    this.projectId,
  });

  /// Bernilai `true` apabila layanan terhubung ke Cloud Firestore.
  final bool isCloudConnected;

  /// Opsional: `projectId` Firebase untuk ditampilkan pada tooltip.
  final String? projectId;

  static const Color _localBackground = Color(0xFFF1F5F9);
  static const Color _localBorder = AppTheme.borderColor;
  static const Color _localForeground = AppTheme.textSecondary;

  @override
  Widget build(BuildContext context) {
    final String label = isCloudConnected ? 'Cloud Terhubung' : 'Mode Lokal';
    final IconData icon =
        isCloudConnected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded;
    final Color backgroundColor =
        isCloudConnected ? AppTheme.statusAmanBackground : _localBackground;
    final Color borderColor = isCloudConnected
        ? AppTheme.statusAman.withValues(alpha: 0.35)
        : _localBorder;
    final Color foregroundColor =
        isCloudConnected ? AppTheme.statusAman : _localForeground;

    final String trimmedProjectId = projectId?.trim() ?? '';
    final String tooltipMessage = isCloudConnected
        ? (trimmedProjectId.isNotEmpty
            ? 'Terhubung ke Cloud Firestore ($trimmedProjectId)'
            : 'Terhubung ke Cloud Firestore')
        : 'Berjalan pada mode fallback penyimpanan lokal sementara';

    return Semantics(
      label: 'Status koneksi database: $label',
      child: Tooltip(
        message: tooltipMessage,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                size: 13,
                color: foregroundColor,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: foregroundColor,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
