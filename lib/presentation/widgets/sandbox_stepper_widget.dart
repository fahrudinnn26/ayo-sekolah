import 'package:ayo_sekolah/core/constants/app_theme.dart';
import 'package:ayo_sekolah/core/constants/ppdb_constants.dart';
import 'package:material_ui/material_ui.dart';

/// Komponen stepper 4 tahap progres kesiapan & seleksi simulasi PPDB Sandbox
/// sesuai field `statusSeleksi` pada `RegistrationDraftModel`:
/// 1. Draf Tersimpan
/// 2. Kelengkapan Berkas
/// 3. Siap Verifikasi
/// 4. Terkirim Simulasi
///
/// Mendukung pembaruan tahapan secara interaktif melalui tombol aksi maupun
/// ketukan langsung pada node tahapan.
class SandboxStepperWidget extends StatelessWidget {
  const SandboxStepperWidget({
    super.key,
    required this.currentStatus,
    this.onStatusChanged,
    this.isUpdating = false,
  });

  /// Tahap aktif saat ini (`1` hingga `4`).
  final int currentStatus;

  /// Dipanggil saat pengguna memperbarui/menaikkan tahap status seleksi (`1`–`4`).
  final ValueChanged<int>? onStatusChanged;

  /// Menandakan proses pembaruan status sedang berlangsung.
  final bool isUpdating;

  static const List<_StepInfo> _steps = <_StepInfo>[
    _StepInfo(
      stepNumber: PpdbConstants.statusDrafTersimpan,
      shortTitle: 'Draf',
      fullTitle: 'Draf Tersimpan',
      description: 'Data awal siswa dan sekolah tujuan telah tercatat.',
      icon: Icons.edit_note_rounded,
    ),
    _StepInfo(
      stepNumber: PpdbConstants.statusKelengkapanBerkas,
      shortTitle: 'Berkas',
      fullTitle: 'Kelengkapan Berkas',
      description: 'Periksa dan lengkapi seluruh dokumen wajib sesuai jalur.',
      icon: Icons.folder_copy_outlined,
    ),
    _StepInfo(
      stepNumber: PpdbConstants.statusSiapVerifikasi,
      shortTitle: 'Verifikasi',
      fullTitle: 'Siap Verifikasi',
      description: 'Data & berkas siap diperiksa di posko atau portal resmi.',
      icon: Icons.fact_check_outlined,
    ),
    _StepInfo(
      stepNumber: PpdbConstants.statusTerkirimSimulasi,
      shortTitle: 'Terkirim',
      fullTitle: 'Terkirim Simulasi',
      description:
          'Latihan pendaftaran tuntas! Lanjutkan pendaftaran di portal resmi.',
      icon: Icons.task_alt_rounded,
    ),
  ];

  int get _clampedStatus => currentStatus.clamp(
        PpdbConstants.statusDrafTersimpan,
        PpdbConstants.statusTerkirimSimulasi,
      );

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int activeStep = _clampedStatus;
    final _StepInfo activeInfo = _steps[activeStep - 1];
    final bool isFinalStep =
        activeStep >= PpdbConstants.statusTerkirimSimulasi;
    final bool canGoBack = activeStep > PpdbConstants.statusDrafTersimpan;
    final _StepInfo? nextInfo = !isFinalStep ? _steps[activeStep] : null;
    final bool interactive = onStatusChanged != null && !isUpdating;

    return Material(
      color: AppTheme.surfaceBackground,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Header Stepper
          Row(
            children: <Widget>[
              const Icon(
                Icons.timeline_rounded,
                size: 16,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Progres Simulasi (Tahap $activeStep/4)',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.primaryDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isFinalStep
                      ? AppTheme.statusAmanBackground
                      : AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  activeInfo.fullTitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isFinalStep
                        ? AppTheme.statusAman
                        : AppTheme.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Horizontal 4-step Visual Track
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List<Widget>.generate(_steps.length * 2 - 1, (int index) {
              if (index.isOdd) {
                final int leftStepNumber = (index ~/ 2) + 1;
                final bool isConnectorCompleted = activeStep > leftStepNumber;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: isConnectorCompleted
                            ? AppTheme.secondaryGreen
                            : AppTheme.dividerColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                );
              }

              final _StepInfo step = _steps[index ~/ 2];
              final bool isCompleted = activeStep > step.stepNumber;
              final bool isCurrent = activeStep == step.stepNumber;

              return _StepNode(
                step: step,
                isCompleted: isCompleted,
                isCurrent: isCurrent,
                onTap: interactive && step.stepNumber != activeStep
                    ? () => onStatusChanged!(step.stepNumber)
                    : null,
              );
            }),
          ),
          const SizedBox(height: 10),

          // Keterangan Tahap Aktif
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isFinalStep
                  ? AppTheme.statusAmanBackground
                  : AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isFinalStep
                    ? AppTheme.statusAman.withValues(alpha: 0.3)
                    : AppTheme.dividerColor,
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  activeInfo.icon,
                  size: 16,
                  color:
                      isFinalStep ? AppTheme.statusAman : AppTheme.primaryBlue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    activeInfo.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isFinalStep
                          ? AppTheme.statusAman
                          : AppTheme.textPrimary,
                      fontWeight:
                          isFinalStep ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tombol Aksi Interaktif Pembaruan Status
          if (onStatusChanged != null) ...<Widget>[
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                if (canGoBack) ...<Widget>[
                  OutlinedButton(
                    onPressed: interactive
                        ? () => onStatusChanged!(activeStep - 1)
                        : null,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(
                        AppTheme.minTouchTargetSize,
                        AppTheme.minTouchTargetSize,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('Mundur'),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: isFinalStep
                      ? OutlinedButton.icon(
                          onPressed: interactive
                              ? () => onStatusChanged!(
                                    PpdbConstants.statusDrafTersimpan,
                                  )
                              : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.statusAman,
                            side: const BorderSide(color: AppTheme.statusAman),
                            minimumSize: const Size(
                              AppTheme.minTouchTargetSize,
                              AppTheme.minTouchTargetSize,
                            ),
                          ),
                          icon: const Icon(Icons.replay_rounded, size: 18),
                          label: const Text(
                            'Simulasi Selesai • Ulangi',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      : FilledButton.icon(
                          onPressed: interactive
                              ? () => onStatusChanged!(activeStep + 1)
                              : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.secondaryGreen,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(
                              AppTheme.minTouchTargetSize,
                              AppTheme.minTouchTargetSize,
                            ),
                          ),
                          icon: isUpdating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                ),
                          label: Text(
                            'Lanjut: ${nextInfo!.fullTitle}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ],
      ),
      ),
    );
  }
}

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.step,
    required this.isCompleted,
    required this.isCurrent,
    this.onTap,
  });

  final _StepInfo step;
  final bool isCompleted;
  final bool isCurrent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color circleColor;
    final Color borderColor;
    final Color contentColor;

    if (isCompleted) {
      circleColor = AppTheme.secondaryGreen;
      borderColor = AppTheme.secondaryGreen;
      contentColor = Colors.white;
    } else if (isCurrent) {
      circleColor = AppTheme.primaryBlue;
      borderColor = AppTheme.primaryBlue;
      contentColor = Colors.white;
    } else {
      circleColor = AppTheme.surfaceCard;
      borderColor = AppTheme.borderColor;
      contentColor = AppTheme.textSecondary;
    }

    return Semantics(
      button: onTap != null,
      label: 'Tahap ${step.stepNumber}: ${step.fullTitle}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: SizedBox(
            width: 58,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: circleColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor, width: 1.5),
                    boxShadow: isCurrent
                        ? <BoxShadow>[
                            BoxShadow(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: isCompleted
                      ? Icon(Icons.check_rounded, size: 17, color: contentColor)
                      : Text(
                          '${step.stepNumber}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: contentColor,
                          ),
                        ),
                ),
                const SizedBox(height: 5),
                Text(
                  step.shortTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isCurrent || isCompleted
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: isCurrent
                        ? AppTheme.primaryDark
                        : (isCompleted
                            ? AppTheme.secondaryDark
                            : AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepInfo {
  const _StepInfo({
    required this.stepNumber,
    required this.shortTitle,
    required this.fullTitle,
    required this.description,
    required this.icon,
  });

  final int stepNumber;
  final String shortTitle;
  final String fullTitle;
  final String description;
  final IconData icon;
}
