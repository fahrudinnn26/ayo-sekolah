import 'package:ayo_sekolah/core/constants/app_theme.dart';
import 'package:ayo_sekolah/data/models/school_model.dart';
import 'package:ayo_sekolah/logic/providers/school_provider.dart';
import 'package:ayo_sekolah/presentation/widgets/zonasi_badge.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// Kartu informasi sekolah Material Design 3 yang menampilkan profil ringkas,
/// status zonasi (`ZonasiBadge`), informasi total kuota, serta tombol toggle
/// "Bandingkan" yang terhubung langsung ke [SchoolProvider].
class SchoolCard extends StatelessWidget {
  const SchoolCard({
    super.key,
    required this.school,
    required this.jarakMeter,
    required this.onTap,
  });

  final SchoolModel school;
  final double jarakMeter;
  final VoidCallback onTap;

  Color _jenjangBackgroundColor(String jenjang) {
    switch (jenjang.toUpperCase()) {
      case 'SD':
        return const Color(0xFFE0F2FE);
      case 'SMP':
        return const Color(0xFFD6EEF5);
      case 'SMA':
        return const Color(0xFFD2F4EE);
      case 'SMK':
        return const Color(0xFFEDE9FE);
      default:
        return AppTheme.primaryContainer;
    }
  }

  Color _jenjangForegroundColor(String jenjang) {
    switch (jenjang.toUpperCase()) {
      case 'SD':
        return const Color(0xFF0369A1);
      case 'SMP':
        return AppTheme.primaryDark;
      case 'SMA':
        return AppTheme.secondaryDark;
      case 'SMK':
        return const Color(0xFF5B21B6);
      default:
        return AppTheme.primaryDark;
    }
  }

  void _handleToggleCompare(BuildContext context) {
    final SchoolProvider provider = context.read<SchoolProvider>();
    final bool changed = provider.toggleCompareSchool(school);
    if (changed) return;

    final ScaffoldMessengerState? messenger =
        ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Maksimal 2 sekolah dapat dibandingkan sekaligus. '
          'Hapus salah satu pilihan terlebih dahulu.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isCompared = context.select<SchoolProvider, bool>(
      (SchoolProvider provider) => provider.isSchoolCompared(school.idSchool),
    );
    final bool isCompareFull = context.select<SchoolProvider, bool>(
      (SchoolProvider provider) => provider.isCompareFull,
    );

    final Color jenjangBg = _jenjangBackgroundColor(school.jenjang);
    final Color jenjangFg = _jenjangForegroundColor(school.jenjang);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCompared ? AppTheme.primaryBlue : AppTheme.dividerColor,
          width: isCompared ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Baris badge jenjang, status, dan akreditasi
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  _MetaPill(
                    label: school.jenjang,
                    backgroundColor: jenjangBg,
                    foregroundColor: jenjangFg,
                    fontWeight: FontWeight.w700,
                  ),
                  _MetaPill(
                    label: school.status,
                    backgroundColor: AppTheme.surfaceBackground,
                    foregroundColor: AppTheme.textSecondary,
                    borderColor: AppTheme.dividerColor,
                  ),
                  _MetaPill(
                    label: 'Akreditasi ${school.akreditasi}',
                    icon: Icons.verified_outlined,
                    backgroundColor: AppTheme.statusInfoBackground,
                    foregroundColor: AppTheme.statusInfo,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Nama sekolah
              Text(
                school.namaSekolah,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),

              // Ringkasan lokasi posko
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      school.alamatPosko,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Badge indikator jarak & status zonasi
              ZonasiBadge(jarakMeter: jarakMeter),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 10),

              // Baris bawah: Total Kuota & Tombol Toggle Bandingkan
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(
                              Icons.groups_2_outlined,
                              size: 16,
                              color: AppTheme.primaryBlue,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Total Kuota: ${school.totalKuota} kursi',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          school.passingGrade > 0
                              ? 'Passing Grade: ${school.passingGrade.toStringAsFixed(1)}'
                              : 'Seleksi utama via Zonasi & Afirmasi',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _CompareToggleButton(
                    isCompared: isCompared,
                    isLimitReached: isCompareFull && !isCompared,
                    onPressed: () => _handleToggleCompare(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.icon,
    this.borderColor,
    this.fontWeight = FontWeight.w600,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData? icon;
  final Color? borderColor;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 13, color: foregroundColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: fontWeight,
              color: foregroundColor,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompareToggleButton extends StatelessWidget {
  const _CompareToggleButton({
    required this.isCompared,
    required this.isLimitReached,
    required this.onPressed,
  });

  final bool isCompared;
  final bool isLimitReached;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (isCompared) {
      return FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.secondaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(
            AppTheme.minTouchTargetSize,
            AppTheme.minTouchTargetSize,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        icon: const Icon(Icons.check_rounded, size: 18),
        label: const Text('Dipilih'),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor:
            isLimitReached ? AppTheme.textSecondary : AppTheme.primaryBlue,
        side: BorderSide(
          color: isLimitReached ? AppTheme.borderColor : AppTheme.primaryBlue,
          width: 1.25,
        ),
        minimumSize: const Size(
          AppTheme.minTouchTargetSize,
          AppTheme.minTouchTargetSize,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      icon: const Icon(Icons.compare_arrows_rounded, size: 18),
      label: const Text('Bandingkan'),
    );
  }
}
