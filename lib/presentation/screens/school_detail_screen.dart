import 'package:ayo_sekolah/core/constants/app_theme.dart';
import 'package:ayo_sekolah/core/constants/ppdb_constants.dart';
import 'package:ayo_sekolah/core/utils/haversine_calculator.dart';
import 'package:ayo_sekolah/data/models/registration_draft_model.dart';
import 'package:ayo_sekolah/data/models/school_model.dart';
import 'package:ayo_sekolah/data/services/external_launcher_service.dart';
import 'package:ayo_sekolah/logic/providers/school_provider.dart';
import 'package:ayo_sekolah/presentation/screens/tracking_sandbox_screen.dart';
import 'package:ayo_sekolah/presentation/widgets/zonasi_badge.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// Layar 2 — Detail Profil Sekolah.
///
/// Menampilkan profil lengkap sekolah (nama, jenjang, status, akreditasi,
/// jarak Haversine & `ZonasiBadge`, passing grade, alamat posko verifikasi),
/// rincian kuota per jalur PPDB, daftar fasilitas, serta tombol aksi utama
/// (Chat WA Panitia, Portal Resmi PPDB, dan Simulasi Daftar).
class SchoolDetailScreen extends StatefulWidget {
  const SchoolDetailScreen({
    super.key,
    required this.school,
    this.onStartSandboxSimulation,
    this.launcherService = const ExternalLauncherService(),
  });

  final SchoolModel school;

  /// Callback opsional untuk berpindah ke tab PPDB Sandbox setelah menutup
  /// halaman detail.
  final ValueChanged<SchoolModel>? onStartSandboxSimulation;

  final ExternalLauncherService launcherService;

  @override
  State<SchoolDetailScreen> createState() => _SchoolDetailScreenState();
}

class _SchoolDetailScreenState extends State<SchoolDetailScreen> {
  bool _isLaunchingWa = false;
  bool _isLaunchingPortal = false;

  Future<void> _handleOpenWhatsApp() async {
    if (_isLaunchingWa) return;
    setState(() => _isLaunchingWa = true);

    final ExternalLaunchResult result =
        await widget.launcherService.contactSchoolCommittee(widget.school);

    if (!mounted) return;
    setState(() => _isLaunchingWa = false);

    if (!result.success) {
      _showSnackBar(result.message, isError: true);
    }
  }

  Future<void> _handleOpenPortal() async {
    if (_isLaunchingPortal) return;
    setState(() => _isLaunchingPortal = true);

    final ExternalLaunchResult result =
        await widget.launcherService.openSchoolPortal(widget.school);

    if (!mounted) return;
    setState(() => _isLaunchingPortal = false);

    if (!result.success) {
      _showSnackBar(result.message, isError: true);
    }
  }

  Future<void> _handleStartSandboxSimulation() async {
    if (widget.onStartSandboxSimulation != null) {
      Navigator.of(context).pop();
      widget.onStartSandboxSimulation!(widget.school);
      return;
    }

    final RegistrationDraftModel? savedDraft = await showSandboxDraftFormSheet(
      context,
      preselectedSchool: widget.school,
    );
    if (!mounted || savedDraft == null) return;

    _showSnackBar(
      'Draf simulasi untuk ${savedDraft.namaSekolah} berhasil disimpan di PPDB Sandbox.',
    );
  }

  void _handleToggleCompare(SchoolProvider provider) {
    final bool wasCompared = provider.isSchoolCompared(widget.school.idSchool);
    final bool changed = provider.toggleCompareSchool(widget.school);

    if (!changed) {
      _showSnackBar(
        'Maksimal 2 sekolah dapat dibandingkan sekaligus. '
        'Hapus salah satu pilihan terlebih dahulu.',
        isError: true,
      );
      return;
    }

    _showSnackBar(
      wasCompared
          ? '${widget.school.namaSekolah} dihapus dari daftar komparasi.'
          : '${widget.school.namaSekolah} ditambahkan ke daftar komparasi '
              '(${provider.comparedCount}/${SchoolProvider.maxCompareSchools}).',
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final ScaffoldMessengerState? messenger =
        ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.statusBerisiko : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SchoolProvider schoolProvider = context.watch<SchoolProvider>();
    final SchoolModel school = widget.school;
    final double distanceMeters = schoolProvider.getDistanceMeters(school);
    final String formattedDistance =
        HaversineCalculator.formatJarak(distanceMeters);
    final bool isCompared = schoolProvider.isSchoolCompared(school.idSchool);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Profil Sekolah'),
        actions: <Widget>[
          IconButton(
            onPressed: () => _handleToggleCompare(schoolProvider),
            tooltip: isCompared
                ? 'Hapus dari daftar komparasi'
                : 'Tambahkan ke komparasi',
            icon: Icon(
              isCompared
                  ? Icons.compare_arrows_rounded
                  : Icons.add_chart_rounded,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // 1. Kartu Header Profil Utama
            _ProfileHeaderCard(
              school: school,
              distanceMeters: distanceMeters,
              formattedDistance: formattedDistance,
              locationLabel: schoolProvider.locationLabel,
            ),
            const SizedBox(height: 12),

            // 2. Ringkasan Passing Grade & Total Kuota
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: _HighlightMetricCard(
                      icon: Icons.school_outlined,
                      iconColor: AppTheme.tertiaryAccent,
                      iconBackground: const Color(0xFFDBEAFE),
                      label: 'Passing Grade',
                      value: school.passingGrade > 0
                          ? school.passingGrade.toStringAsFixed(1)
                          : 'Tidak Berlaku',
                      caption: school.passingGrade > 0
                          ? 'Acuan rata-rata nilai rapor'
                          : 'Jenjang ${school.jenjang} tanpa passing grade',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HighlightMetricCard(
                      icon: Icons.groups_2_outlined,
                      iconColor: AppTheme.primaryBlue,
                      iconBackground: AppTheme.primaryContainer,
                      label: 'Total Daya Tampung',
                      value: '${school.totalKuota} Kursi',
                      caption: 'Akumulasi seluruh jalur PPDB',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Alamat Posko Verifikasi
            _SectionTitle(
              title: 'Alamat Posko Verifikasi',
              subtitle: 'Lokasi pelayanan verifikasi berkas PPDB resmi sekolah',
              theme: theme,
            ),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppTheme.primaryBlue,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            school.alamatPosko,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Koordinat: ${school.latitude.toStringAsFixed(4)}, '
                            '${school.longitude.toStringAsFixed(4)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 4. Rincian Alokasi Kuota per Jalur (Grid 2x2 responsif)
            _SectionTitle(
              title: 'Alokasi Kuota per Jalur',
              subtitle:
                  'Distribusi kursi penerimaan untuk jalur Zonasi, Prestasi, Afirmasi, & Mutasi',
              theme: theme,
            ),
            const SizedBox(height: 8),
            _QuotaAllocationGrid(school: school),
            const SizedBox(height: 20),

            // 5. Daftar Fasilitas Sekolah (Wrap / Chip)
            _SectionTitle(
              title: 'Fasilitas Sekolah',
              subtitle: 'Sarana penunjang kegiatan belajar dan ekstrakurikuler',
              theme: theme,
            ),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: school.fasilitas.isEmpty
                    ? Text(
                        'Informasi fasilitas sekolah belum tersedia.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: school.fasilitas.map((String facility) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceBackground,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.dividerColor),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 16,
                                  color: AppTheme.secondaryGreen,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    facility,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // 6. Tombol Aksi Utama (tinggi minimal >= 48dp)
            _SectionTitle(
              title: 'Layanan & Aksi Cepat',
              subtitle:
                  'Hubungi panitia, kunjungi portal resmi, atau mulai simulasi pendaftaran',
              theme: theme,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _handleStartSandboxSimulation,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
              ),
              icon: const Icon(Icons.assignment_turned_in_rounded),
              label: const Text('Simulasi Daftar di Sekolah Ini'),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _isLaunchingWa ? null : _handleOpenWhatsApp,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.secondaryGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
              ),
              icon: _isLaunchingWa
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.chat_rounded),
              label: const Text('Chat WA Panitia'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _isLaunchingPortal ? null : _handleOpenPortal,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryBlue,
                minimumSize: const Size.fromHeight(52),
              ),
              icon: _isLaunchingPortal
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppTheme.primaryBlue,
                      ),
                    )
                  : const Icon(Icons.open_in_new_rounded),
              label: const Text('Buka Portal Resmi PPDB'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.school,
    required this.distanceMeters,
    required this.formattedDistance,
    required this.locationLabel,
  });

  final SchoolModel school;
  final double distanceMeters;
  final String formattedDistance;
  final String locationLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _InfoTag(
                  label: school.jenjang,
                  backgroundColor: AppTheme.primaryContainer,
                  foregroundColor: AppTheme.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
                _InfoTag(
                  label: school.status,
                  backgroundColor: AppTheme.secondaryContainer,
                  foregroundColor: AppTheme.secondaryDark,
                ),
                _InfoTag(
                  label: 'Akreditasi ${school.akreditasi}',
                  icon: Icons.verified_rounded,
                  backgroundColor: AppTheme.statusInfoBackground,
                  foregroundColor: AppTheme.statusInfo,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              school.namaSekolah,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ZonasiBadge(jarakMeter: distanceMeters),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(
                    Icons.straighten_rounded,
                    size: 18,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Jarak Garis Lurus (Haversine): $formattedDistance '
                          '(${distanceMeters.round()} meter)',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Titik acuan aktif: $locationLabel',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.icon,
    this.fontWeight = FontWeight.w600,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData? icon;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 14, color: foregroundColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: fontWeight,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightMetricCard extends StatelessWidget {
  const _HighlightMetricCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.value,
    required this.caption,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(height: 10),
            Text(label, style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              caption,
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuotaAllocationGrid extends StatelessWidget {
  const _QuotaAllocationGrid({required this.school});

  final SchoolModel school;

  @override
  Widget build(BuildContext context) {
    const List<String> jalurList = PpdbConstants.daftarJalurPpdb;
    final int totalKuota = school.totalKuota;

    return Column(
      children: <Widget>[
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: _QuotaJalurCard(
                  jalur: jalurList[0],
                  kuota: school.kuota[jalurList[0]] ?? 0,
                  totalKuota: totalKuota,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuotaJalurCard(
                  jalur: jalurList[1],
                  kuota: school.kuota[jalurList[1]] ?? 0,
                  totalKuota: totalKuota,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: _QuotaJalurCard(
                  jalur: jalurList[2],
                  kuota: school.kuota[jalurList[2]] ?? 0,
                  totalKuota: totalKuota,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuotaJalurCard(
                  jalur: jalurList[3],
                  kuota: school.kuota[jalurList[3]] ?? 0,
                  totalKuota: totalKuota,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuotaJalurCard extends StatelessWidget {
  const _QuotaJalurCard({
    required this.jalur,
    required this.kuota,
    required this.totalKuota,
  });

  final String jalur;
  final int kuota;
  final int totalKuota;

  IconData _iconForJalur(String namaJalur) {
    switch (namaJalur) {
      case PpdbConstants.jalurZonasi:
        return Icons.radar_rounded;
      case PpdbConstants.jalurPrestasi:
        return Icons.emoji_events_outlined;
      case PpdbConstants.jalurAfirmasi:
        return Icons.volunteer_activism_outlined;
      case PpdbConstants.jalurMutasi:
        return Icons.swap_horiz_rounded;
      default:
        return Icons.confirmation_number_outlined;
    }
  }

  Color _accentForJalur(String namaJalur) {
    switch (namaJalur) {
      case PpdbConstants.jalurZonasi:
        return AppTheme.primaryBlue;
      case PpdbConstants.jalurPrestasi:
        return AppTheme.tertiaryAccent;
      case PpdbConstants.jalurAfirmasi:
        return AppTheme.secondaryGreen;
      case PpdbConstants.jalurMutasi:
        return AppTheme.statusWaspada;
      default:
        return AppTheme.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = _accentForJalur(jalur);
    final double ratio =
        totalKuota > 0 ? (kuota / totalKuota).clamp(0.0, 1.0) : 0.0;
    final int percentage = (ratio * 100).round();
    final bool isAvailable = kuota > 0;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _iconForJalur(jalur),
                    size: 18,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    jalur,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isAvailable ? '$kuota kursi' : 'Tidak dibuka',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isAvailable
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isAvailable ? '$percentage% dari total kuota' : '0% kuota',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: AppTheme.dividerColor,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.theme,
  });

  final String title;
  final String subtitle;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
