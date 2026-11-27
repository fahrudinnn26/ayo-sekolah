import 'package:ayo_sekolah/core/constants/app_theme.dart';
import 'package:ayo_sekolah/core/constants/ppdb_constants.dart';
import 'package:ayo_sekolah/core/utils/haversine_calculator.dart';
import 'package:ayo_sekolah/data/models/registration_draft_model.dart';
import 'package:ayo_sekolah/data/models/school_model.dart';
import 'package:ayo_sekolah/data/services/external_launcher_service.dart';
import 'package:ayo_sekolah/data/services/sample_schools_data.dart';
import 'package:ayo_sekolah/logic/providers/sandbox_provider.dart';
import 'package:ayo_sekolah/logic/providers/school_provider.dart';
import 'package:ayo_sekolah/presentation/widgets/sandbox_stepper_widget.dart';
import 'package:ayo_sekolah/presentation/widgets/zonasi_badge.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// Membuka modal formulir pembuatan (Create) atau penyuntingan (Edit) draf
/// simulasi pendaftaran PPDB Sandbox.
///
/// Mengembalikan [RegistrationDraftModel] yang berhasil disimpan atau `null`
/// jika pengguna membatalkan modal.
Future<RegistrationDraftModel?> showSandboxDraftFormSheet(
  BuildContext context, {
  RegistrationDraftModel? existingDraft,
  SchoolModel? preselectedSchool,
  String? initialJalur,
  double? initialRapor,
}) {
  return showModalBottomSheet<RegistrationDraftModel>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext sheetContext) {
      return _SandboxDraftFormSheet(
        existingDraft: existingDraft,
        preselectedSchool: preselectedSchool,
        initialJalur: initialJalur,
        initialRapor: initialRapor,
      );
    },
  );
}

/// Daftar dokumen kesiapan berkas dinamis sesuai jalur PPDB yang dipilih.
List<String> getChecklistBerkasByJalur(String jalurPilihan) {
  switch (jalurPilihan) {
    case PpdbConstants.jalurPrestasi:
      return const <String>[
        'Rapor 5 semester terakhir (terlegalisir sekolah asal)',
        'Surat Keterangan Peringkat Nilai Rapor dari Kepala Sekolah',
        'Sertifikat / Piagam Prestasi akademik atau non-akademik (opsional)',
        'Kartu Keluarga (KK) & Akta Kelahiran calon siswa',
      ];
    case PpdbConstants.jalurAfirmasi:
      return const <String>[
        'Kartu Indonesia Pintar (KIP) / PKH / bukti terdaftar DTKS aktif',
        'Surat Pernyataan Keabsahan Dokumen dari Orang Tua/Wali',
        'Kartu Keluarga (KK) & Akta Kelahiran calon siswa',
        'Dokumen pendukung SKTM / penyandang disabilitas (bila relevan)',
      ];
    case PpdbConstants.jalurMutasi:
      return const <String>[
        'SK / Surat Penugasan perpindahan tugas resmi orang tua/wali',
        'Surat Keterangan Domisili dari RT/RW/Kelurahan setempat',
        'Kartu Keluarga (KK) & Akta Kelahiran calon siswa',
        'Surat Keterangan Anak Guru/GTK (khusus jalur anak pendidik)',
      ];
    case PpdbConstants.jalurZonasi:
    default:
      return const <String>[
        'Kartu Keluarga (KK) asli (diterbitkan min. 1 tahun sebelum PPDB)',
        'Akta Kelahiran / Surat Keterangan Lahir calon siswa',
        'Surat Keterangan Lulus (SKL) / Ijazah jenjang sebelumnya',
        'Titik koordinat domisili terverifikasi sesuai alamat KK',
      ];
  }
}

/// Layar 4 — PPDB Sandbox & Simulasi Pendaftaran Mandiri.
///
/// Menyediakan banner edukatif bahwa fitur ini adalah simulasi mandiri (bukan
/// portal pendaftaran resmi pemerintah), manajemen draf CRUD penuh (Create,
/// Read, Update, Delete), [SandboxStepperWidget] 4 tahap interaktif, checklist
/// kesiapan berkas dinamis sesuai jalur pilihan, serta tautan cepat membuka
/// portal resmi PPDB sekolah terkait.
class TrackingSandboxScreen extends StatefulWidget {
  const TrackingSandboxScreen({
    super.key,
    this.onBackToHome,
    this.launcherService = const ExternalLauncherService(),
  });

  /// Callback opsional untuk kembali ke Tab 1 (Beranda).
  final VoidCallback? onBackToHome;

  final ExternalLauncherService launcherService;

  @override
  State<TrackingSandboxScreen> createState() => TrackingSandboxScreenState();
}

/// State publik untuk [TrackingSandboxScreen] agar shell navigasi utama dapat
/// membuka modal formulir simulasi pendaftaran secara langsung dengan sekolah
/// yang sudah terpilih (`preselectedSchool`).
class TrackingSandboxScreenState extends State<TrackingSandboxScreen> {
  final Map<String, Set<int>> _checkedDocsByDraftKey = <String, Set<int>>{};
  String? _updatingStatusDraftId;
  String? _launchingPortalDraftId;

  /// Membuka modal formulir draf simulasi baru atau mode edit.
  Future<void> openDraftForm({
    RegistrationDraftModel? existingDraft,
    SchoolModel? preselectedSchool,
    String? initialJalur,
    double? initialRapor,
  }) async {
    if (!mounted) return;
    final SchoolProvider schoolProvider = context.read<SchoolProvider>();
    if (schoolProvider.allSchools.isEmpty && !schoolProvider.isLoadingSchools) {
      await schoolProvider.loadSchools();
    }
    if (!mounted) return;

    final RegistrationDraftModel? savedDraft = await showSandboxDraftFormSheet(
      context,
      existingDraft: existingDraft,
      preselectedSchool: preselectedSchool,
      initialJalur: initialJalur,
      initialRapor: initialRapor,
    );

    if (!mounted || savedDraft == null) return;
    final bool isEditing = existingDraft != null;
    _showSnackBar(
      isEditing
          ? 'Draf simulasi ${savedDraft.namaSiswa} berhasil diperbarui.'
          : 'Draf simulasi untuk ${savedDraft.namaSekolah} berhasil disimpan.',
    );
  }

  String _checklistKey(RegistrationDraftModel draft) =>
      '${draft.idRegistrasi}::${draft.jalurPilihan}';

  Set<int> _getCheckedIndices(RegistrationDraftModel draft) {
    return _checkedDocsByDraftKey[_checklistKey(draft)] ?? <int>{};
  }

  void _toggleChecklistItem(RegistrationDraftModel draft, int index) {
    final String key = _checklistKey(draft);
    setState(() {
      final Set<int> current = Set<int>.from(
        _checkedDocsByDraftKey[key] ?? <int>{},
      );
      if (current.contains(index)) {
        current.remove(index);
      } else {
        current.add(index);
      }
      _checkedDocsByDraftKey[key] = current;
    });
  }

  Future<void> _handleUpdateStatus(
    RegistrationDraftModel draft,
    int newStatus,
  ) async {
    if (_updatingStatusDraftId != null) return;
    setState(() => _updatingStatusDraftId = draft.idRegistrasi);

    final SandboxProvider sandboxProvider = context.read<SandboxProvider>();
    final RegistrationDraftModel? updated =
        await sandboxProvider.updateDraftStatus(
      idRegistrasi: draft.idRegistrasi,
      statusSeleksi: newStatus,
    );

    if (!mounted) return;
    setState(() => _updatingStatusDraftId = null);

    if (updated != null) {
      _showSnackBar(
        'Status "${updated.namaSiswa}" diperbarui ke Tahap '
        '${updated.statusSeleksi}: ${updated.statusSeleksiLabel}.',
      );
    } else if (sandboxProvider.errorMessage != null) {
      _showSnackBar(sandboxProvider.errorMessage!, isError: true);
    }
  }

  Future<void> _confirmAndDeleteDraft(RegistrationDraftModel draft) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Draf Simulasi?'),
          content: Text(
            'Draf pendaftaran simulasi atas nama "${draft.namaSiswa}" '
            '(${draft.namaSekolah} • Jalur ${draft.jalurPilihan}) akan '
            'dihapus permanen dari daftar Sandbox.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.statusBerisiko,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final SandboxProvider sandboxProvider = context.read<SandboxProvider>();
    final bool deleted = await sandboxProvider.deleteDraft(draft.idRegistrasi);
    if (!mounted) return;

    if (deleted) {
      setState(() {
        _checkedDocsByDraftKey.removeWhere(
          (String key, Set<int> _) =>
              key.startsWith('${draft.idRegistrasi}::'),
        );
      });
      _showSnackBar('Draf simulasi "${draft.namaSiswa}" berhasil dihapus.');
    } else if (sandboxProvider.errorMessage != null) {
      _showSnackBar(sandboxProvider.errorMessage!, isError: true);
    }
  }

  Future<void> _handleOpenOfficialPortal(
    RegistrationDraftModel draft,
    SchoolModel? school,
  ) async {
    if (_launchingPortalDraftId != null) return;
    setState(() => _launchingPortalDraftId = draft.idRegistrasi);

    final ExternalLaunchResult result;
    if (school != null) {
      result = await widget.launcherService.openSchoolPortal(school);
    } else {
      final String upperName = draft.namaSekolah.toUpperCase();
      final String fallbackUrl =
          upperName.contains('SD') || upperName.contains('SMP')
              ? SampleSchoolsData.portalPpdbBandarLampungSdSmp
              : SampleSchoolsData.portalPpdbLampungSmaSmk;
      result = await widget.launcherService.openPortalPpdb(fallbackUrl);
    }

    if (!mounted) return;
    setState(() => _launchingPortalDraftId = null);

    if (!result.success) {
      _showSnackBar(result.message, isError: true);
    }
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
    final SandboxProvider sandboxProvider = context.watch<SandboxProvider>();
    final SchoolProvider schoolProvider = context.watch<SchoolProvider>();
    final List<RegistrationDraftModel> drafts = sandboxProvider.drafts;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('PPDB Sandbox'),
            Text(
              'Simulasi Mandiri & Kesiapan Berkas • ${drafts.length} draf',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('sandbox_new_simulation_fab'),
        onPressed: () => openDraftForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Simulasi Baru'),
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryBlue,
        onRefresh: sandboxProvider.loadDrafts,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: <Widget>[
            // 1. Banner Edukatif PPDB Sandbox
            _SandboxEducationalBanner(
              isUsingLocalFallback: sandboxProvider.isUsingLocalFallback,
            ),
            const SizedBox(height: 14),

            // 2. Konten Daftar Draf (Loading / Error / Empty / Data)
            if (sandboxProvider.isLoading && drafts.isEmpty)
              const _LoadingDraftsView()
            else if (sandboxProvider.errorMessage != null && drafts.isEmpty)
              _ErrorDraftsView(
                message: sandboxProvider.errorMessage!,
                onRetry: sandboxProvider.loadDrafts,
              )
            else if (drafts.isEmpty)
              _EmptyDraftsView(
                onCreateFirst: () => openDraftForm(),
                onExploreSchools: widget.onBackToHome,
              )
            else ...<Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Daftar Draf Simulasi (${drafts.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const Icon(
                    Icons.schedule_rounded,
                    size: 15,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Terbaru',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...drafts.map((RegistrationDraftModel draft) {
                final SchoolModel? school =
                    schoolProvider.getSchoolById(draft.idSchool);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _DraftSandboxCard(
                    key: ValueKey<String>(draft.idRegistrasi),
                    draft: draft,
                    school: school,
                    checkedDocIndices: _getCheckedIndices(draft),
                    isUpdatingStatus:
                        _updatingStatusDraftId == draft.idRegistrasi,
                    isLaunchingPortal:
                        _launchingPortalDraftId == draft.idRegistrasi,
                    onToggleChecklist: (int docIndex) =>
                        _toggleChecklistItem(draft, docIndex),
                    onStatusChanged: (int newStatus) =>
                        _handleUpdateStatus(draft, newStatus),
                    onEdit: () => openDraftForm(existingDraft: draft),
                    onDelete: () => _confirmAndDeleteDraft(draft),
                    onOpenPortal: () =>
                        _handleOpenOfficialPortal(draft, school),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _SandboxEducationalBanner extends StatelessWidget {
  const _SandboxEducationalBanner({
    required this.isUsingLocalFallback,
  });

  final bool isUsingLocalFallback;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.statusInfoBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.statusInfo.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.science_outlined,
              size: 22,
              color: AppTheme.statusInfo,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(
                      'PPDB Sandbox (Simulasi Mandiri)',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                    if (isUsingLocalFallback)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Mode Lokal',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.statusInfo,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Halaman ini digunakan untuk latihan pengisian data dan cek '
                  'kesiapan berkas secara mandiri, BUKAN portal pendaftaran '
                  'resmi pemerintah. Gunakan tombol "Buka Portal Resmi PPDB" '
                  'untuk mendaftar pada situs resmi dinas pendidikan.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textPrimary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftSandboxCard extends StatelessWidget {
  const _DraftSandboxCard({
    super.key,
    required this.draft,
    required this.school,
    required this.checkedDocIndices,
    required this.isUpdatingStatus,
    required this.isLaunchingPortal,
    required this.onToggleChecklist,
    required this.onStatusChanged,
    required this.onEdit,
    required this.onDelete,
    required this.onOpenPortal,
  });

  final RegistrationDraftModel draft;
  final SchoolModel? school;
  final Set<int> checkedDocIndices;
  final bool isUpdatingStatus;
  final bool isLaunchingPortal;
  final ValueChanged<int> onToggleChecklist;
  final ValueChanged<int> onStatusChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onOpenPortal;

  static const List<String> _bulanSingkat = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  String _formatDateTime(DateTime dt) {
    final String bulan = _bulanSingkat[dt.month - 1];
    final String jam = dt.hour.toString().padLeft(2, '0');
    final String menit = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} $bulan ${dt.year} • $jam:$menit';
  }

  Color _jalurColor(String jalur) {
    switch (jalur) {
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
    final Color jalurColor = _jalurColor(draft.jalurPilihan);
    final List<String> requiredDocs =
        getChecklistBerkasByJalur(draft.jalurPilihan);
    final int checkedCount = checkedDocIndices
        .where((int idx) => idx >= 0 && idx < requiredDocs.length)
        .length;
    final bool allDocsChecked =
        requiredDocs.isNotEmpty && checkedCount == requiredDocs.length;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Header: Nama Siswa, NISN, & Badge Jalur
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: jalurColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: jalurColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        draft.namaSiswa,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'NISN: ${draft.nisn}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: jalurColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: jalurColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Jalur ${draft.jalurPilihan}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: jalurColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Informasi Sekolah Tujuan, Jarak, & Nilai Rapor
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.school_rounded,
                        size: 18,
                        color: AppTheme.primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          draft.namaSekolah,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (school != null)
                        Text(
                          school!.jenjang,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      ZonasiBadge(
                        jarakMeter: draft.jarakMeter,
                        compact: true,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppTheme.dividerColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(
                              Icons.grade_outlined,
                              size: 14,
                              color: AppTheme.tertiaryAccent,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Nilai Rapor: ${draft.rataRataRapor.toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dibuat pada ${_formatDateTime(draft.createdAt)}',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Progress Stepper 4 Tahap Interaktif
            SandboxStepperWidget(
              currentStatus: draft.statusSeleksi,
              isUpdating: isUpdatingStatus,
              onStatusChanged: onStatusChanged,
            ),
            const SizedBox(height: 12),

            // Checklist Kesiapan Berkas Dinamis Sesuai Jalur
            Material(
              color: AppTheme.surfaceCard,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: allDocsChecked
                      ? AppTheme.statusAman.withValues(alpha: 0.45)
                      : AppTheme.dividerColor,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          allDocsChecked
                              ? Icons.check_circle_rounded
                              : Icons.checklist_rtl_rounded,
                          size: 18,
                          color: allDocsChecked
                              ? AppTheme.statusAman
                              : AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Checklist Berkas Jalur ${draft.jalurPilihan}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: allDocsChecked
                                ? AppTheme.statusAmanBackground
                                : AppTheme.primaryContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$checkedCount/${requiredDocs.length} siap',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: allDocsChecked
                                  ? AppTheme.statusAman
                                  : AppTheme.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  ...requiredDocs.asMap().entries.map(
                    (MapEntry<int, String> entry) {
                      final int index = entry.key;
                      final String docTitle = entry.value;
                      final bool isChecked = checkedDocIndices.contains(index);

                      return CheckboxListTile(
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppTheme.secondaryGreen,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        value: isChecked,
                        onChanged: (_) => onToggleChecklist(index),
                        title: Text(
                          docTitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isChecked
                                ? AppTheme.textSecondary
                                : AppTheme.textPrimary,
                            decoration: isChecked
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tombol Edit, Hapus, & Pintasan Buka Portal Resmi PPDB
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(
                        AppTheme.minTouchTargetSize,
                        AppTheme.minTouchTargetSize,
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.statusBerisiko,
                      side: const BorderSide(color: AppTheme.statusBerisiko),
                      minimumSize: const Size(
                        AppTheme.minTouchTargetSize,
                        AppTheme.minTouchTargetSize,
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Hapus'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: isLaunchingPortal ? null : onOpenPortal,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(AppTheme.minTouchTargetSize),
              ),
              icon: isLaunchingPortal
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Buka Portal Resmi PPDB'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SandboxDraftFormSheet extends StatefulWidget {
  const _SandboxDraftFormSheet({
    this.existingDraft,
    this.preselectedSchool,
    this.initialJalur,
    this.initialRapor,
  });

  final RegistrationDraftModel? existingDraft;
  final SchoolModel? preselectedSchool;
  final String? initialJalur;
  final double? initialRapor;

  @override
  State<_SandboxDraftFormSheet> createState() => _SandboxDraftFormSheetState();
}

class _SandboxDraftFormSheetState extends State<_SandboxDraftFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _namaSiswaController;
  late final TextEditingController _nisnController;
  late final TextEditingController _raporController;

  String? _selectedSchoolId;
  late String _selectedJalur;
  bool _isSubmitting = false;

  bool get _isEditMode => widget.existingDraft != null;

  @override
  void initState() {
    super.initState();
    final RegistrationDraftModel? draft = widget.existingDraft;
    final SchoolProvider schoolProvider = context.read<SchoolProvider>();
    final List<SchoolModel> allSchools = schoolProvider.allSchools;

    _namaSiswaController = TextEditingController(
      text: draft?.namaSiswa ?? '',
    );
    _nisnController = TextEditingController(
      text: draft?.nisn ?? '',
    );

    final double? defaultRapor = draft?.rataRataRapor ?? widget.initialRapor;
    _raporController = TextEditingController(
      text: defaultRapor != null ? defaultRapor.toStringAsFixed(1) : '',
    );

    if (draft != null) {
      _selectedSchoolId = draft.idSchool;
      _selectedJalur = PpdbConstants.daftarJalurPpdb.contains(draft.jalurPilihan)
          ? draft.jalurPilihan
          : PpdbConstants.jalurZonasi;
    } else {
      _selectedSchoolId = widget.preselectedSchool?.idSchool ??
          (allSchools.isNotEmpty ? allSchools.first.idSchool : null);
      _selectedJalur = (widget.initialJalur != null &&
              PpdbConstants.daftarJalurPpdb.contains(widget.initialJalur))
          ? widget.initialJalur!
          : PpdbConstants.jalurZonasi;
    }
  }

  @override
  void dispose() {
    _namaSiswaController.dispose();
    _nisnController.dispose();
    _raporController.dispose();
    super.dispose();
  }

  SchoolModel? _resolveSelectedSchool(SchoolProvider provider) {
    if (_selectedSchoolId != null) {
      final SchoolModel? found = provider.getSchoolById(_selectedSchoolId!);
      if (found != null) return found;
    }
    if (widget.preselectedSchool != null &&
        widget.preselectedSchool!.idSchool == _selectedSchoolId) {
      return widget.preselectedSchool;
    }
    return provider.allSchools.isNotEmpty ? provider.allSchools.first : null;
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final SchoolProvider schoolProvider = context.read<SchoolProvider>();
    final SandboxProvider sandboxProvider = context.read<SandboxProvider>();
    final SchoolModel? selectedSchool = _resolveSelectedSchool(schoolProvider);

    if (selectedSchool == null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('Pilih sekolah tujuan terlebih dahulu.'),
          backgroundColor: AppTheme.statusBerisiko,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final double parsedRapor = double.parse(
      _raporController.text.trim().replaceAll(',', '.'),
    );
    final double computedDistanceMeters =
        schoolProvider.getDistanceMeters(selectedSchool);

    setState(() => _isSubmitting = true);

    RegistrationDraftModel? saved;
    if (_isEditMode) {
      final RegistrationDraftModel updatedModel =
          widget.existingDraft!.copyWith(
        idSchool: selectedSchool.idSchool,
        namaSekolah: selectedSchool.namaSekolah,
        namaSiswa: _namaSiswaController.text.trim(),
        nisn: _nisnController.text.trim(),
        jalurPilihan: _selectedJalur,
        rataRataRapor: parsedRapor,
        jarakMeter: computedDistanceMeters,
      );
      saved = await sandboxProvider.updateDraft(updatedModel);
    } else {
      saved = await sandboxProvider.createDraft(
        school: selectedSchool,
        namaSiswa: _namaSiswaController.text.trim(),
        nisn: _nisnController.text.trim(),
        jalurPilihan: _selectedJalur,
        rataRataRapor: parsedRapor,
        jarakMeter: computedDistanceMeters,
      );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (saved != null) {
      Navigator.of(context).pop(saved);
    } else if (sandboxProvider.errorMessage != null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(sandboxProvider.errorMessage!),
          backgroundColor: AppTheme.statusBerisiko,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SchoolProvider schoolProvider = context.watch<SchoolProvider>();
    final List<SchoolModel> allSchools = schoolProvider.allSchools;
    final SchoolModel? selectedSchool = _resolveSelectedSchool(schoolProvider);

    final double? liveDistanceMeters = selectedSchool != null
        ? schoolProvider.getDistanceMeters(selectedSchool)
        : null;
    final int selectedJalurQuota =
        selectedSchool?.kuota[_selectedJalur] ?? 0;

    final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                _isEditMode
                    ? 'Edit Draf Simulasi PPDB'
                    : 'Simulasi Pendaftaran Baru',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Isi data latihan calon siswa untuk menghitung jarak zonasi '
                'otomatis dan memantau kesiapan berkas.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),

              // 1. Pilihan Sekolah Tujuan
              DropdownButtonFormField<String>(
                key: const Key('sandbox_school_dropdown'),
                initialValue: allSchools.any(
                  (SchoolModel s) => s.idSchool == selectedSchool?.idSchool,
                )
                    ? selectedSchool?.idSchool
                    : null,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Sekolah Tujuan',
                  prefixIcon: Icon(
                    Icons.school_outlined,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                items: allSchools.map((SchoolModel school) {
                  return DropdownMenuItem<String>(
                    value: school.idSchool,
                    child: Text(
                      '${school.namaSekolah} (${school.jenjang})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (String? value) {
                  setState(() => _selectedSchoolId = value);
                },
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Sekolah tujuan wajib dipilih.';
                  }
                  return null;
                },
              ),

              // Preview Otomatis Jarak Haversine dari Lokasi Aktif
              if (selectedSchool != null && liveDistanceMeters != null) ...<Widget>[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.straighten_rounded,
                            size: 16,
                            color: AppTheme.primaryBlue,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Jarak Otomatis: '
                              '${HaversineCalculator.formatJarak(liveDistanceMeters)} '
                              '(${liveDistanceMeters.round()} m)',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          ZonasiBadge(
                            jarakMeter: liveDistanceMeters,
                            compact: true,
                          ),
                          Text(
                            'Dari: ${schoolProvider.locationLabel}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // 2. Input Nama Siswa
              TextFormField(
                key: const Key('sandbox_nama_siswa_field'),
                controller: _namaSiswaController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap Siswa',
                  hintText: 'Contoh: Budi Santoso',
                  prefixIcon: Icon(
                    Icons.person_outline_rounded,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                validator: (String? value) {
                  final String trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return 'Nama siswa wajib diisi.';
                  }
                  if (trimmed.length < 3) {
                    return 'Nama siswa minimal 3 karakter.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // 3. Input NISN (Validasi tepat 10 digit angka)
              TextFormField(
                key: const Key('sandbox_nisn_field'),
                controller: _nisnController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                maxLength: 10,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'NISN (10 Digit Angka)',
                  hintText: 'Contoh: 0091234567',
                  prefixIcon: Icon(
                    Icons.badge_outlined,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                validator: (String? value) {
                  final String trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return 'NISN wajib diisi.';
                  }
                  if (!RegExp(r'^\d{10}$').hasMatch(trimmed)) {
                    return 'NISN harus terdiri dari tepat 10 digit angka.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // 4. Pilihan Jalur PPDB
              Text(
                'Pilih Jalur PPDB',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PpdbConstants.daftarJalurPpdb.map((String jalur) {
                  final bool isSelected = _selectedJalur == jalur;
                  final int kuotaJalur = selectedSchool?.kuota[jalur] ?? 0;
                  final String labelText = selectedSchool != null
                      ? '$jalur ($kuotaJalur)'
                      : jalur;

                  return ChoiceChip(
                    key: Key('sandbox_jalur_chip_$jalur'),
                    label: Text(labelText),
                    selected: isSelected,
                    showCheckmark: false,
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    backgroundColor: AppTheme.surfaceCard,
                    selectedColor: AppTheme.primaryBlue,
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.primaryBlue
                          : AppTheme.borderColor,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                    ),
                    onSelected: (_) => setState(() => _selectedJalur = jalur),
                  );
                }).toList(),
              ),
              if (selectedSchool != null && selectedJalurQuota <= 0) ...<Widget>[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.statusWaspadaBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: AppTheme.statusWaspada,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${selectedSchool.namaSekolah} tidak membuka kuota '
                          'jalur $_selectedJalur (0 kursi). Pertimbangkan jalur lain.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.statusWaspada,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // 5. Input Rata-Rata Nilai Rapor (0–100)
              TextFormField(
                key: const Key('sandbox_rapor_field'),
                controller: _raporController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Rata-Rata Nilai Rapor (0 – 100)',
                  hintText: 'Contoh: 87.5',
                  prefixIcon: Icon(
                    Icons.grade_outlined,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                validator: (String? value) {
                  final String normalized =
                      (value ?? '').trim().replaceAll(',', '.');
                  if (normalized.isEmpty) {
                    return 'Rata-rata nilai rapor wajib diisi.';
                  }
                  final double? parsed = double.tryParse(normalized);
                  if (parsed == null) {
                    return 'Masukkan angka yang valid (contoh: 87.5).';
                  }
                  if (parsed < 0 || parsed > 100) {
                    return 'Nilai rapor harus berada di antara 0 hingga 100.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 6. Tombol Simpan & Batal
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      key: const Key('sandbox_submit_draft_button'),
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.secondaryGreen,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(
                        _isEditMode
                            ? 'Simpan Perubahan'
                            : 'Simpan Draf Simulasi',
                      ),
                    ),
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

class _LoadingDraftsView extends StatelessWidget {
  const _LoadingDraftsView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: <Widget>[
          const CircularProgressIndicator(color: AppTheme.primaryBlue),
          const SizedBox(height: 14),
          Text(
            'Memuat daftar draf simulasi PPDB...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorDraftsView extends StatelessWidget {
  const _ErrorDraftsView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            const Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: AppTheme.statusBerisiko,
            ),
            const SizedBox(height: 12),
            Text(
              'Gagal Memuat Draf Simulasi',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDraftsView extends StatelessWidget {
  const _EmptyDraftsView({
    required this.onCreateFirst,
    this.onExploreSchools,
  });

  final VoidCallback onCreateFirst;
  final VoidCallback? onExploreSchools;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_turned_in_outlined,
                size: 38,
                color: AppTheme.secondaryDark,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Belum Ada Draf Simulasi',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Mulai buat draf simulasi pendaftaran untuk menghitung jarak '
              'zonasi otomatis, memeriksa daftar berkas wajib per jalur, dan '
              'melacak progres kesiapan 4 tahap sebelum mendaftar resmi.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: onCreateFirst,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.secondaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Buat Simulasi Pertama'),
                ),
                if (onExploreSchools != null)
                  OutlinedButton.icon(
                    onPressed: onExploreSchools,
                    icon: const Icon(Icons.explore_outlined),
                    label: const Text('Jelajahi Sekolah'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
