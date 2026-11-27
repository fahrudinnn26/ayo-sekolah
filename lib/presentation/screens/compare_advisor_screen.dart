import 'package:ayo_sekolah/core/constants/app_theme.dart';
import 'package:ayo_sekolah/core/constants/ppdb_constants.dart';
import 'package:ayo_sekolah/core/utils/haversine_calculator.dart';
import 'package:ayo_sekolah/core/utils/smart_pathway_advisor.dart';
import 'package:ayo_sekolah/data/models/school_model.dart';
import 'package:ayo_sekolah/logic/providers/school_provider.dart';
import 'package:ayo_sekolah/presentation/widgets/zonasi_badge.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// Callback untuk memulai simulasi pendaftaran PPDB Sandbox dari hasil
/// rekomendasi Smart Pathway Advisor dengan parameter awal opsional.
typedef StartSandboxWithAdvisorCallback = void Function(
  SchoolModel school, {
  String? initialJalur,
  double? initialRapor,
});

/// Layar 3 — Komparasi Sekolah Side-by-Side & Smart Multi-Pathway Advisor.
///
/// Menyediakan:
/// 1. Perbandingan berdampingan maksimal 2 sekolah terpilih dari
///    [SchoolProvider] lengkap dengan penanda warna hijau pada nilai lebih unggul,
///    pilihan hapus/ganti sekolah, serta pemilih sekolah via `ModalBottomSheet`.
/// 2. Formulir interaktif **Smart Multi-Pathway Advisor** untuk mengevaluasi
///    peluang 4 jalur PPDB (`Zonasi`, `Prestasi`, `Afirmasi`, `Mutasi`) secara
///    otomatis menggunakan [SmartPathwayAdvisor].
class CompareAdvisorScreen extends StatefulWidget {
  const CompareAdvisorScreen({
    super.key,
    this.onBackToHome,
    this.onStartSandboxSimulation,
  });

  /// Callback untuk kembali ke Tab 1 (Beranda).
  final VoidCallback? onBackToHome;

  /// Callback opsional untuk langsung membuka form simulasi PPDB Sandbox.
  final StartSandboxWithAdvisorCallback? onStartSandboxSimulation;

  @override
  State<CompareAdvisorScreen> createState() => _CompareAdvisorScreenState();
}

class _CompareAdvisorScreenState extends State<CompareAdvisorScreen> {
  static const double _defaultRataRataRapor = 85.0;

  double _rataRataRapor = _defaultRataRataRapor;
  bool _memilikiDokumenAfirmasi = false;
  bool _memilikiSuratMutasi = false;
  String? _selectedDropdownSchoolId;

  late final TextEditingController _raporController;

  @override
  void initState() {
    super.initState();
    _raporController = TextEditingController(
      text: _rataRataRapor.toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _raporController.dispose();
    super.dispose();
  }

  void _onRaporSliderChanged(double value) {
    final double rounded = (value * 2).round() / 2.0;
    final String formatted = rounded.toStringAsFixed(1);
    setState(() => _rataRataRapor = rounded);
    if (_raporController.text != formatted) {
      _raporController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _onRaporTextChanged(String rawText) {
    final String normalized = rawText.trim().replaceAll(',', '.');
    final double? parsed = double.tryParse(normalized);
    if (parsed == null) return;
    final double clamped = parsed.clamp(0.0, 100.0);
    setState(() => _rataRataRapor = clamped);
  }

  void _syncRaporTextOnComplete() {
    final String formatted = _rataRataRapor.toStringAsFixed(1);
    if (_raporController.text != formatted) {
      _raporController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
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

  Future<void> _showSchoolPickerSheet({
    required SchoolProvider provider,
    SchoolModel? replacingSchool,
  }) async {
    final List<SchoolModel> allSchools = provider.allSchools;
    if (allSchools.isEmpty) {
      _showSnackBar(
        'Daftar sekolah belum tersedia. Silakan muat ulang di Beranda.',
        isError: true,
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return _SchoolPickerBottomSheet(
          provider: provider,
          replacingSchool: replacingSchool,
          onSelected: (SchoolModel chosenSchool) {
            Navigator.of(sheetContext).pop();
            if (replacingSchool != null) {
              final bool replaced = provider.replaceComparedSchool(
                replacingSchool.idSchool,
                chosenSchool,
              );
              if (replaced) {
                _showSnackBar(
                  'Diganti menjadi ${chosenSchool.namaSekolah}.',
                );
              } else {
                _showSnackBar(
                  '${chosenSchool.namaSekolah} sudah berada di slot komparasi lain.',
                  isError: true,
                );
              }
            } else {
              final bool added = provider.addSchoolToCompare(chosenSchool);
              if (added) {
                _showSnackBar(
                  '${chosenSchool.namaSekolah} ditambahkan ke komparasi '
                  '(${provider.comparedCount}/${SchoolProvider.maxCompareSchools}).',
                );
              } else {
                _showSnackBar(
                  'Slot komparasi sudah penuh (maksimal 2 sekolah).',
                  isError: true,
                );
              }
            }
          },
        );
      },
    );
  }

  SchoolModel? _resolveDropdownSchool(SchoolProvider provider) {
    final List<SchoolModel> schools = provider.allSchools;
    if (schools.isEmpty) return null;

    if (_selectedDropdownSchoolId != null) {
      final SchoolModel? found =
          provider.getSchoolById(_selectedDropdownSchoolId!);
      if (found != null) return found;
    }
    return schools.first;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SchoolProvider provider = context.watch<SchoolProvider>();
    final List<SchoolModel> comparedSchools = provider.comparedSchools;

    final SchoolModel? fallbackAdvisorSchool =
        comparedSchools.isEmpty ? _resolveDropdownSchool(provider) : null;
    final List<SchoolModel> advisorTargets = comparedSchools.isNotEmpty
        ? comparedSchools
        : (fallbackAdvisorSchool != null
            ? <SchoolModel>[fallbackAdvisorSchool]
            : <SchoolModel>[]);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Komparasi & Smart Advisor'),
            Text(
              'Acuan: ${provider.locationLabel}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          if (comparedSchools.isNotEmpty)
            IconButton(
              onPressed: () {
                provider.clearComparedSchools();
                _showSnackBar('Daftar komparasi sekolah telah dikosongkan.');
              },
              tooltip: 'Kosongkan daftar komparasi',
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: <Widget>[
          // ===================================================================
          // BAGIAN 1: KOMPARASI SEKOLAH SIDE-BY-SIDE
          // ===================================================================
          _SectionHeader(
            icon: Icons.compare_arrows_rounded,
            title: 'Komparasi Sekolah Side-by-Side',
            subtitle:
                'Bandingkan maksimal 2 sekolah berdampingan berdasarkan jarak '
                'zonasi, akreditasi, passing grade, kuota, dan fasilitas.',
            trailing: comparedSchools.isNotEmpty
                ? _CountPill(
                    label:
                        '${comparedSchools.length}/${SchoolProvider.maxCompareSchools}',
                  )
                : null,
          ),
          const SizedBox(height: 12),

          if (comparedSchools.isEmpty)
            _CompareEmptyStateCard(
              title: 'Belum Ada Sekolah Dipilih',
              description:
                  'Pilih maksimal 2 sekolah di Kota Bandar Lampung untuk '
                  'membandingkan keunggulan akreditasi, jarak zonasi, kuota 4 '
                  'jalur, dan fasilitas secara berdampingan.',
              primaryButtonLabel: 'Pilih Sekolah',
              onPickSchool: () => _showSchoolPickerSheet(provider: provider),
              onBackToHome: widget.onBackToHome,
            )
          else if (comparedSchools.length == 1)
            _SingleSchoolCompareState(
              school: comparedSchools.first,
              distanceMeters: provider.getDistanceMeters(comparedSchools.first),
              onReplaceFirst: () => _showSchoolPickerSheet(
                provider: provider,
                replacingSchool: comparedSchools.first,
              ),
              onRemoveFirst: () => provider.removeSchoolFromCompare(
                comparedSchools.first.idSchool,
              ),
              onPickSecondSchool: () =>
                  _showSchoolPickerSheet(provider: provider),
              onBackToHome: widget.onBackToHome,
            )
          else
            _SideBySideComparisonSection(
              schoolA: comparedSchools[0],
              schoolB: comparedSchools[1],
              distanceA: provider.getDistanceMeters(comparedSchools[0]),
              distanceB: provider.getDistanceMeters(comparedSchools[1]),
              onReplaceA: () => _showSchoolPickerSheet(
                provider: provider,
                replacingSchool: comparedSchools[0],
              ),
              onRemoveA: () => provider.removeSchoolFromCompare(
                comparedSchools[0].idSchool,
              ),
              onReplaceB: () => _showSchoolPickerSheet(
                provider: provider,
                replacingSchool: comparedSchools[1],
              ),
              onRemoveB: () => provider.removeSchoolFromCompare(
                comparedSchools[1].idSchool,
              ),
            ),

          const SizedBox(height: 24),

          // ===================================================================
          // BAGIAN 2: SMART MULTI-PATHWAY ADVISOR (INTERAKTIF)
          // ===================================================================
          const _SectionHeader(
            icon: Icons.auto_awesome_rounded,
            title: 'Smart Multi-Pathway Advisor',
            subtitle:
                'Masukkan profil calon siswa untuk mendapatkan rekomendasi '
                'jalur PPDB terbaik secara otomatis.',
          ),
          const SizedBox(height: 12),

          _AdvisorInputCard(
            rataRataRapor: _rataRataRapor,
            raporController: _raporController,
            memilikiDokumenAfirmasi: _memilikiDokumenAfirmasi,
            memilikiSuratMutasi: _memilikiSuratMutasi,
            onSliderChanged: _onRaporSliderChanged,
            onTextChanged: _onRaporTextChanged,
            onTextEditingComplete: _syncRaporTextOnComplete,
            onAfirmasiChanged: (bool value) =>
                setState(() => _memilikiDokumenAfirmasi = value),
            onMutasiChanged: (bool value) =>
                setState(() => _memilikiSuratMutasi = value),
          ),
          const SizedBox(height: 14),

          if (comparedSchools.isEmpty && provider.allSchools.isNotEmpty) ...<Widget>[
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Sekolah yang Dievaluasi',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Karena belum ada sekolah di komparasi, pilih salah satu '
                      'sekolah di bawah untuk dianalisis otomatis.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: fallbackAdvisorSchool?.idSchool,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Sekolah Tujuan',
                        prefixIcon: Icon(
                          Icons.school_outlined,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      items: provider.allSchools.map((SchoolModel school) {
                        final String dist =
                            provider.getFormattedDistance(school);
                        return DropdownMenuItem<String>(
                          value: school.idSchool,
                          child: Text(
                            '${school.namaSekolah} (${school.jenjang} • $dist)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (String? selectedId) {
                        if (selectedId == null) return;
                        setState(() => _selectedDropdownSchoolId = selectedId);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          if (advisorTargets.isEmpty)
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Data sekolah sedang dimuat. Hasil Smart Pathway Advisor '
                  'akan tampil otomatis setelah daftar sekolah tersedia.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            )
          else
            ...advisorTargets.map((SchoolModel school) {
              final RekomendasiJalurResult result = provider.evaluatePathway(
                school: school,
                rataRataRapor: _rataRataRapor,
                memilikiDokumenAfirmasi: _memilikiDokumenAfirmasi,
                memilikiSuratMutasi: _memilikiSuratMutasi,
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AdvisorRecommendationCard(
                  school: school,
                  result: result,
                  onStartSandbox: widget.onStartSandboxSimulation != null
                      ? () => widget.onStartSandboxSimulation!(
                            school,
                            initialJalur: result.jalurTerbaik,
                            initialRapor: _rataRataRapor,
                          )
                      : null,
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppTheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: AppTheme.primaryBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
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
          ),
        ),
        if (trailing != null) ...<Widget>[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.secondaryDark,
        ),
      ),
    );
  }
}

class _CompareEmptyStateCard extends StatelessWidget {
  const _CompareEmptyStateCard({
    required this.title,
    required this.description,
    required this.primaryButtonLabel,
    required this.onPickSchool,
    this.onBackToHome,
  });

  final String title;
  final String description;
  final String primaryButtonLabel;
  final VoidCallback onPickSchool;
  final VoidCallback? onBackToHome;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: AppTheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.balance_rounded,
                size: 34,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
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
                  onPressed: onPickSchool,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: Text(primaryButtonLabel),
                ),
                if (onBackToHome != null)
                  OutlinedButton.icon(
                    onPressed: onBackToHome,
                    icon: const Icon(Icons.explore_outlined),
                    label: const Text('Kembali ke Beranda'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SingleSchoolCompareState extends StatelessWidget {
  const _SingleSchoolCompareState({
    required this.school,
    required this.distanceMeters,
    required this.onReplaceFirst,
    required this.onRemoveFirst,
    required this.onPickSecondSchool,
    this.onBackToHome,
  });

  final SchoolModel school;
  final double distanceMeters;
  final VoidCallback onReplaceFirst;
  final VoidCallback onRemoveFirst;
  final VoidCallback onPickSecondSchool;
  final VoidCallback? onBackToHome;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.primaryBlue, width: 1.4),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Sekolah 1 Terpilih',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: onReplaceFirst,
                      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                      label: const Text('Ganti'),
                    ),
                    IconButton(
                      onPressed: onRemoveFirst,
                      tooltip: 'Hapus sekolah dari komparasi',
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  school.namaSekolah,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    ZonasiBadge(jarakMeter: distanceMeters, compact: true),
                    Text(
                      '${school.jenjang} • Akreditasi ${school.akreditasi} • '
                      '${school.totalKuota} kursi',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _CompareEmptyStateCard(
          title: 'Pilih 1 Sekolah Lagi untuk Perbandingan',
          description:
              'Baru 1 sekolah dipilih. Tambahkan 1 sekolah pembanding lagi agar '
              'tabel komparasi side-by-side dan penanda nilai unggul muncul.',
          primaryButtonLabel: 'Pilih Sekolah ke-2',
          onPickSchool: onPickSecondSchool,
          onBackToHome: onBackToHome,
        ),
      ],
    );
  }
}

enum _ComparisonWinner { left, right, tie }

class _SideBySideComparisonSection extends StatelessWidget {
  const _SideBySideComparisonSection({
    required this.schoolA,
    required this.schoolB,
    required this.distanceA,
    required this.distanceB,
    required this.onReplaceA,
    required this.onRemoveA,
    required this.onReplaceB,
    required this.onRemoveB,
  });

  final SchoolModel schoolA;
  final SchoolModel schoolB;
  final double distanceA;
  final double distanceB;
  final VoidCallback onReplaceA;
  final VoidCallback onRemoveA;
  final VoidCallback onReplaceB;
  final VoidCallback onRemoveB;

  int _akreditasiScore(String akreditasi) {
    switch (akreditasi.trim().toUpperCase()) {
      case 'A':
        return 4;
      case 'B':
        return 3;
      case 'C':
        return 2;
      default:
        return 1;
    }
  }

  _ComparisonWinner _higherWins(num left, num right) {
    if (left > right) return _ComparisonWinner.left;
    if (right > left) return _ComparisonWinner.right;
    return _ComparisonWinner.tie;
  }

  _ComparisonWinner _lowerWins(num left, num right) {
    if (left < right) return _ComparisonWinner.left;
    if (right < left) return _ComparisonWinner.right;
    return _ComparisonWinner.tie;
  }

  _ComparisonWinner _passingGradeWinner(double left, double right) {
    if (left <= 0 || right <= 0) return _ComparisonWinner.tie;
    return _lowerWins(left, right);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final _ComparisonWinner akreditasiWinner = _higherWins(
      _akreditasiScore(schoolA.akreditasi),
      _akreditasiScore(schoolB.akreditasi),
    );
    final _ComparisonWinner distanceWinner = _lowerWins(distanceA, distanceB);
    final _ComparisonWinner passingGradeWinner = _passingGradeWinner(
      schoolA.passingGrade,
      schoolB.passingGrade,
    );
    final _ComparisonWinner totalKuotaWinner = _higherWins(
      schoolA.totalKuota,
      schoolB.totalKuota,
    );
    final _ComparisonWinner fasilitasWinner = _higherWins(
      schoolA.fasilitas.length,
      schoolB.fasilitas.length,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Header 2 Sekolah yang dibandingkan
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: _ComparedSchoolHeaderCard(
                  slotLabel: 'Sekolah 1',
                  school: schoolA,
                  accentColor: AppTheme.primaryBlue,
                  onReplace: onReplaceA,
                  onRemove: onRemoveA,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ComparedSchoolHeaderCard(
                  slotLabel: 'Sekolah 2',
                  school: schoolB,
                  accentColor: AppTheme.secondaryGreen,
                  onReplace: onReplaceB,
                  onRemove: onRemoveB,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Keterangan highlight hijau
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.statusAmanBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.statusAman.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: AppTheme.statusAman,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Kotak berwarna hijau menandakan nilai perbandingan yang '
                  'lebih unggul di antara kedua sekolah.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.statusAman,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Kartu metrik perbandingan utama
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _ComparisonMetricRow(
                  label: 'Akreditasi Sekolah',
                  icon: Icons.verified_outlined,
                  winner: akreditasiWinner,
                  leftValue: 'Akreditasi ${schoolA.akreditasi}',
                  rightValue: 'Akreditasi ${schoolB.akreditasi}',
                  winnerCaption: 'Lebih unggul',
                ),
                const Divider(height: 22),

                // Jarak Haversine & ZonasiBadge
                _ComparisonCustomRow(
                  label: 'Jarak Haversine & Status Zonasi',
                  icon: Icons.straighten_rounded,
                  winner: distanceWinner,
                  winnerCaption: 'Lebih dekat',
                  leftChild: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        HaversineCalculator.formatJarak(distanceA),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: distanceWinner == _ComparisonWinner.left
                              ? AppTheme.statusAman
                              : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ZonasiBadge(
                        jarakMeter: distanceA,
                        showDistance: false,
                        compact: true,
                      ),
                    ],
                  ),
                  rightChild: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        HaversineCalculator.formatJarak(distanceB),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: distanceWinner == _ComparisonWinner.right
                              ? AppTheme.statusAman
                              : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ZonasiBadge(
                        jarakMeter: distanceB,
                        showDistance: false,
                        compact: true,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 22),

                _ComparisonMetricRow(
                  label: 'Passing Grade (Acuan Rapor)',
                  icon: Icons.school_outlined,
                  winner: passingGradeWinner,
                  leftValue: schoolA.passingGrade > 0
                      ? schoolA.passingGrade.toStringAsFixed(1)
                      : 'Tidak Berlaku',
                  rightValue: schoolB.passingGrade > 0
                      ? schoolB.passingGrade.toStringAsFixed(1)
                      : 'Tidak Berlaku',
                  winnerCaption: 'Ambang lebih ringan',
                ),
                const Divider(height: 22),

                _ComparisonMetricRow(
                  label: 'Total Daya Tampung (Kuota)',
                  icon: Icons.groups_2_outlined,
                  winner: totalKuotaWinner,
                  leftValue: '${schoolA.totalKuota} kursi',
                  rightValue: '${schoolB.totalKuota} kursi',
                  winnerCaption: 'Lebih banyak',
                ),
                const SizedBox(height: 14),

                // Sub-bagian Rincian Kuota 4 Jalur
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
                      Text(
                        'Rincian Kuota per Jalur PPDB',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppTheme.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...PpdbConstants.daftarJalurPpdb.asMap().entries.map(
                        (MapEntry<int, String> entry) {
                          final String jalur = entry.value;
                          final int kuotaA = schoolA.kuota[jalur] ?? 0;
                          final int kuotaB = schoolB.kuota[jalur] ?? 0;
                          final _ComparisonWinner jalurWinner =
                              _higherWins(kuotaA, kuotaB);
                          final bool isLast = entry.key ==
                              PpdbConstants.daftarJalurPpdb.length - 1;

                          return Padding(
                            padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                            child: _ComparisonMetricRow(
                              label: 'Jalur $jalur',
                              winner: jalurWinner,
                              leftValue:
                                  kuotaA > 0 ? '$kuotaA kursi' : 'Tidak dibuka',
                              rightValue:
                                  kuotaB > 0 ? '$kuotaB kursi' : 'Tidak dibuka',
                              winnerCaption: 'Kuota lebih besar',
                              dense: true,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 22),

                // Jumlah Fasilitas & Ringkasan Daftar Fasilitas
                _ComparisonCustomRow(
                  label: 'Jumlah & Ringkasan Fasilitas',
                  icon: Icons.apartment_rounded,
                  winner: fasilitasWinner,
                  winnerCaption: 'Lebih lengkap',
                  leftChild: _FacilityComparisonCell(
                    fasilitas: schoolA.fasilitas,
                    isWinner: fasilitasWinner == _ComparisonWinner.left,
                  ),
                  rightChild: _FacilityComparisonCell(
                    fasilitas: schoolB.fasilitas,
                    isWinner: fasilitasWinner == _ComparisonWinner.right,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ComparedSchoolHeaderCard extends StatelessWidget {
  const _ComparedSchoolHeaderCard({
    required this.slotLabel,
    required this.school,
    required this.accentColor,
    required this.onReplace,
    required this.onRemove,
  });

  final String slotLabel;
  final SchoolModel school;
  final Color accentColor;
  final VoidCallback onReplace;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: accentColor.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$slotLabel • ${school.jenjang}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              school.namaSekolah,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              school.status,
              style: theme.textTheme.bodySmall,
            ),
            const Spacer(),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReplace,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, AppTheme.minTouchTargetSize),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text(
                      'Ganti',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: onRemove,
                  tooltip: 'Hapus ${school.namaSekolah}',
                  style: IconButton.styleFrom(
                    foregroundColor: AppTheme.statusBerisiko,
                    backgroundColor: AppTheme.statusBerisikoBackground,
                    minimumSize: const Size(
                      AppTheme.minTouchTargetSize,
                      AppTheme.minTouchTargetSize,
                    ),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonMetricRow extends StatelessWidget {
  const _ComparisonMetricRow({
    required this.label,
    required this.winner,
    required this.leftValue,
    required this.rightValue,
    required this.winnerCaption,
    this.icon,
    this.dense = false,
  });

  final String label;
  final IconData? icon;
  final _ComparisonWinner winner;
  final String leftValue;
  final String rightValue;
  final String winnerCaption;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? valueStyle =
        dense ? theme.textTheme.bodyMedium : theme.textTheme.titleSmall;

    return _ComparisonCustomRow(
      label: label,
      icon: icon,
      winner: winner,
      winnerCaption: winnerCaption,
      dense: dense,
      leftChild: Text(
        leftValue,
        style: valueStyle?.copyWith(
          fontWeight: FontWeight.w700,
          color: winner == _ComparisonWinner.left
              ? AppTheme.statusAman
              : AppTheme.textPrimary,
        ),
      ),
      rightChild: Text(
        rightValue,
        style: valueStyle?.copyWith(
          fontWeight: FontWeight.w700,
          color: winner == _ComparisonWinner.right
              ? AppTheme.statusAman
              : AppTheme.textPrimary,
        ),
      ),
    );
  }
}

class _ComparisonCustomRow extends StatelessWidget {
  const _ComparisonCustomRow({
    required this.label,
    required this.winner,
    required this.winnerCaption,
    required this.leftChild,
    required this.rightChild,
    this.icon,
    this.dense = false,
  });

  final String label;
  final IconData? icon;
  final _ComparisonWinner winner;
  final String winnerCaption;
  final Widget leftChild;
  final Widget rightChild;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 16, color: AppTheme.primaryBlue),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                label,
                style: (dense
                        ? theme.textTheme.labelMedium
                        : theme.textTheme.labelLarge)
                    ?.copyWith(color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: _ComparisonValueBox(
                  isWinner: winner == _ComparisonWinner.left,
                  winnerCaption: winnerCaption,
                  dense: dense,
                  child: leftChild,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ComparisonValueBox(
                  isWinner: winner == _ComparisonWinner.right,
                  winnerCaption: winnerCaption,
                  dense: dense,
                  child: rightChild,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ComparisonValueBox extends StatelessWidget {
  const _ComparisonValueBox({
    required this.isWinner,
    required this.winnerCaption,
    required this.child,
    this.dense = false,
  });

  final bool isWinner;
  final String winnerCaption;
  final Widget child;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(dense ? 8 : 10),
      decoration: BoxDecoration(
        color: isWinner
            ? AppTheme.statusAmanBackground
            : AppTheme.surfaceBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isWinner
              ? AppTheme.statusAman.withValues(alpha: 0.45)
              : AppTheme.dividerColor,
          width: isWinner ? 1.25 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          child,
          if (isWinner) ...<Widget>[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.check_circle_rounded,
                  size: 13,
                  color: AppTheme.statusAman,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    winnerCaption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.statusAman,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FacilityComparisonCell extends StatelessWidget {
  const _FacilityComparisonCell({
    required this.fasilitas,
    required this.isWinner,
  });

  final List<String> fasilitas;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<String> previewItems = fasilitas.take(3).toList();
    final int remainingCount = fasilitas.length - previewItems.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '${fasilitas.length} fasilitas',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: isWinner ? AppTheme.statusAman : AppTheme.textPrimary,
          ),
        ),
        if (previewItems.isNotEmpty) ...<Widget>[
          const SizedBox(height: 6),
          ...previewItems.map(
            (String item) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                '• $item',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
          if (remainingCount > 0)
            Text(
              '+$remainingCount fasilitas lainnya',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ],
    );
  }
}

class _AdvisorInputCard extends StatelessWidget {
  const _AdvisorInputCard({
    required this.rataRataRapor,
    required this.raporController,
    required this.memilikiDokumenAfirmasi,
    required this.memilikiSuratMutasi,
    required this.onSliderChanged,
    required this.onTextChanged,
    required this.onTextEditingComplete,
    required this.onAfirmasiChanged,
    required this.onMutasiChanged,
  });

  final double rataRataRapor;
  final TextEditingController raporController;
  final bool memilikiDokumenAfirmasi;
  final bool memilikiSuratMutasi;
  final ValueChanged<double> onSliderChanged;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onTextEditingComplete;
  final ValueChanged<bool> onAfirmasiChanged;
  final ValueChanged<bool> onMutasiChanged;

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
            // Input Nilai Rapor (Slider + TextField tersinkronisasi)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Rata-Rata Nilai Rapor',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Skala 0 – 100 (geser slider atau ketik angka)',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 92,
                  child: TextField(
                    key: const Key('advisor_rapor_textfield'),
                    controller: raporController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textAlign: TextAlign.center,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    onChanged: onTextChanged,
                    onEditingComplete: onTextEditingComplete,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      hintText: '85.0',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppTheme.primaryBlue,
                thumbColor: AppTheme.primaryBlue,
                overlayColor: AppTheme.primaryBlue.withValues(alpha: 0.14),
                valueIndicatorColor: AppTheme.primaryDark,
              ),
              child: Slider(
                key: const Key('advisor_rapor_slider'),
                value: rataRataRapor.clamp(0.0, 100.0),
                min: 0.0,
                max: 100.0,
                divisions: 200,
                label: rataRataRapor.toStringAsFixed(1),
                onChanged: onSliderChanged,
              ),
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('0', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                Text('50', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                Text('100', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
            const Divider(height: 20),

            // Switch Dokumen Afirmasi (KIP/PKH/DTKS)
            SwitchListTile(
              key: const Key('advisor_afirmasi_switch'),
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppTheme.secondaryGreen,
              title: Text(
                'Dokumen Afirmasi (KIP / PKH / DTKS)',
                style: theme.textTheme.titleSmall,
              ),
              subtitle: Text(
                'Kepemilikan kartu bantuan resmi dari pemerintah yang aktif',
                style: theme.textTheme.bodySmall,
              ),
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.volunteer_activism_outlined,
                  size: 20,
                  color: AppTheme.secondaryDark,
                ),
              ),
              value: memilikiDokumenAfirmasi,
              onChanged: onAfirmasiChanged,
            ),
            const Divider(height: 12),

            // Switch Surat Mutasi / Perpindahan Tugas Orang Tua
            SwitchListTile(
              key: const Key('advisor_mutasi_switch'),
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppTheme.primaryBlue,
              title: Text(
                'Surat Mutasi / Perpindahan Tugas Orang Tua',
                style: theme.textTheme.titleSmall,
              ),
              subtitle: Text(
                'SK pindah tugas resmi dari instansi, TNI/Polri, atau perusahaan',
                style: theme.textTheme.bodySmall,
              ),
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.statusWaspadaBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  size: 20,
                  color: AppTheme.statusWaspada,
                ),
              ),
              value: memilikiSuratMutasi,
              onChanged: onMutasiChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _AdvisorRecommendationCard extends StatelessWidget {
  const _AdvisorRecommendationCard({
    required this.school,
    required this.result,
    this.onStartSandbox,
  });

  final SchoolModel school;
  final RekomendasiJalurResult result;
  final VoidCallback? onStartSandbox;

  Color _peluangForeground(TingkatPeluang peluang) {
    switch (peluang) {
      case TingkatPeluang.tinggi:
        return AppTheme.statusAman;
      case TingkatPeluang.sedang:
        return AppTheme.statusWaspada;
      case TingkatPeluang.rendah:
        return AppTheme.statusBerisiko;
    }
  }

  Color _peluangBackground(TingkatPeluang peluang) {
    switch (peluang) {
      case TingkatPeluang.tinggi:
        return AppTheme.statusAmanBackground;
      case TingkatPeluang.sedang:
        return AppTheme.statusWaspadaBackground;
      case TingkatPeluang.rendah:
        return AppTheme.statusBerisikoBackground;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color fg = _peluangForeground(result.tingkatPeluang);
    final Color bg = _peluangBackground(result.tingkatPeluang);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header Sekolah
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        school.namaSekolah,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${school.jenjang} ${school.status} • Akreditasi ${school.akreditasi}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ZonasiBadge(jarakMeter: result.jarakMeter, compact: true),
              ],
            ),
            const SizedBox(height: 12),

            // Kotak Rekomendasi Jalur Terbaik
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: fg.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Icon(Icons.recommend_rounded, size: 20, color: fg),
                      Text(
                        'Rekomendasi Terbaik: Jalur ${result.jalurTerbaik}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: fg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Peluang ${result.tingkatPeluang.label}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.alasan,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Rincian Evaluasi 4 Jalur
            Text(
              'Rincian Peluang 4 Jalur PPDB',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            ...result.rincianJalur.map((EvaluasiJalur item) {
              final Color itemFg = item.memenuhiSyarat
                  ? _peluangForeground(item.tingkatPeluang)
                  : AppTheme.textSecondary;
              final Color itemBg = item.memenuhiSyarat
                  ? _peluangBackground(item.tingkatPeluang)
                  : AppTheme.surfaceBackground;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: item.jalur == result.jalurTerbaik &&
                              item.memenuhiSyarat
                          ? itemFg.withValues(alpha: 0.45)
                          : AppTheme.dividerColor,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'Jalur ${item.jalur} (${item.kuotaJalur} kursi)',
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
                              color: itemBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              item.memenuhiSyarat
                                  ? '${item.tingkatPeluang.label} (${item.skor.round()}%)'
                                  : 'Belum Memenuhi',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: itemFg,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: (item.skor / 100.0).clamp(0.0, 1.0),
                          minHeight: 5,
                          backgroundColor: AppTheme.dividerColor,
                          valueColor: AlwaysStoppedAnimation<Color>(itemFg),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.alasan,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            }),

            if (onStartSandbox != null) ...<Widget>[
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onStartSandbox,
                  icon: const Icon(Icons.assignment_turned_in_outlined),
                  label: Text(
                    'Simulasi Jalur ${result.jalurTerbaik} di ${school.namaSekolah}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SchoolPickerBottomSheet extends StatefulWidget {
  const _SchoolPickerBottomSheet({
    required this.provider,
    required this.onSelected,
    this.replacingSchool,
  });

  final SchoolProvider provider;
  final SchoolModel? replacingSchool;
  final ValueChanged<SchoolModel> onSelected;

  @override
  State<_SchoolPickerBottomSheet> createState() =>
      _SchoolPickerBottomSheetState();
}

class _SchoolPickerBottomSheetState extends State<_SchoolPickerBottomSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String normalizedQuery = _searchQuery.trim().toLowerCase();
    final List<SchoolModel> schools = widget.provider.allSchools
        .where((SchoolModel school) {
          if (normalizedQuery.isEmpty) return true;
          return school.namaSekolah.toLowerCase().contains(normalizedQuery) ||
              school.jenjang.toLowerCase().contains(normalizedQuery) ||
              school.alamatPosko.toLowerCase().contains(normalizedQuery);
        })
        .toList();

    final bool isReplacing = widget.replacingSchool != null;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.48,
      maxChildSize: 0.92,
      builder: (BuildContext context, ScrollController scrollController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    isReplacing
                        ? 'Ganti Sekolah Komparasi'
                        : 'Pilih Sekolah untuk Komparasi',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isReplacing
                        ? 'Mengganti ${widget.replacingSchool!.namaSekolah} dengan sekolah pilihan lain.'
                        : 'Urutan otomatis dari sekolah terdekat terhadap ${widget.provider.locationLabel}.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (String value) =>
                        setState(() => _searchQuery = value),
                    decoration: const InputDecoration(
                      hintText: 'Cari nama sekolah atau jenjang...',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: schools.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Tidak ada sekolah yang cocok dengan pencarian "$_searchQuery".',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: schools.length,
                      separatorBuilder: (BuildContext context, int index) =>
                          const Divider(indent: 16, endIndent: 16),
                      itemBuilder: (BuildContext context, int index) {
                        final SchoolModel school = schools[index];
                        final double distanceMeters =
                            widget.provider.getDistanceMeters(school);
                        final bool isCurrentTarget =
                            widget.replacingSchool?.idSchool == school.idSchool;
                        final bool isAlreadyCompared =
                            widget.provider.isSchoolCompared(school.idSchool);
                        final bool isDisabled =
                            isAlreadyCompared && !isCurrentTarget;

                        return ListTile(
                          enabled: !isDisabled,
                          selected: isAlreadyCompared,
                          selectedTileColor: AppTheme.primaryContainer
                              .withValues(alpha: 0.35),
                          title: Text(
                            school.namaSekolah,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDisabled
                                  ? AppTheme.textSecondary
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: <Widget>[
                                ZonasiBadge(
                                  jarakMeter: distanceMeters,
                                  compact: true,
                                ),
                                Text(
                                  '${school.jenjang} • Akreditasi ${school.akreditasi}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          trailing: isAlreadyCompared
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isCurrentTarget ? 'Saat Ini' : 'Dipilih',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.secondaryDark,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.add_circle_outline_rounded,
                                  color: AppTheme.primaryBlue,
                                ),
                          onTap: isDisabled
                              ? null
                              : () => widget.onSelected(school),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
