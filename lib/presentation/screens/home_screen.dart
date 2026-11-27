import 'package:ayo_sekolah/core/constants/app_theme.dart';
import 'package:ayo_sekolah/core/constants/ppdb_constants.dart';
import 'package:ayo_sekolah/data/models/school_model.dart';
import 'package:ayo_sekolah/data/services/location_service.dart';
import 'package:ayo_sekolah/logic/providers/school_provider.dart';
import 'package:ayo_sekolah/presentation/screens/school_detail_screen.dart';
import 'package:ayo_sekolah/presentation/widgets/cloud_status_badge.dart';
import 'package:ayo_sekolah/presentation/widgets/school_card.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// Layar 1 — Beranda & Radar Sekolah.
///
/// Menampilkan status lokasi aktif (GPS atau Fallback Kecamatan Bandar Lampung),
/// pencarian nama sekolah, filter jenjang (`Semua`, `SD`, `SMP`, `SMA`, `SMK`),
/// daftar kartu sekolah terurut otomatis dari jarak terdekat, serta banner
/// ringkas komparasi di bagian bawah ketika ada sekolah yang dipilih.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.onNavigateToCompare,
    this.onStartSandboxSimulation,
  });

  /// Callback untuk langsung berpindah ke tab Komparasi.
  final VoidCallback? onNavigateToCompare;

  /// Callback saat pengguna menekan "Simulasi Daftar di Sekolah Ini" di detail.
  final ValueChanged<SchoolModel>? onStartSandboxSimulation;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefreshList(SchoolProvider provider) async {
    await provider.loadSchools();
  }

  Future<void> _handleRefreshGps(SchoolProvider provider) async {
    final LocationResult result = await provider.detectUserLocation();
    if (!mounted) return;

    final ScaffoldMessengerState? messenger =
        ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(result.pesan),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleResetFilters(SchoolProvider provider) {
    _searchController.clear();
    provider.resetFilters();
  }

  void _openSchoolDetail(SchoolModel school) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => SchoolDetailScreen(
          school: school,
          onStartSandboxSimulation: widget.onStartSandboxSimulation,
        ),
      ),
    );
  }

  Future<void> _showKecamatanPickerSheet(SchoolProvider provider) async {
    final List<MapEntry<String, KoordinatLokasi>> entries =
        PpdbConstants.koordinatFallbackKecamatan.entries.toList();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        final ThemeData theme = Theme.of(sheetContext);

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.45,
          maxChildSize: 0.88,
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
                        'Pilih Kecamatan Manual',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gunakan koordinat pusat kecamatan di '
                        '${PpdbConstants.wilayahPilot} sebagai acuan jarak zonasi.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: entries.length + 1,
                    separatorBuilder: (BuildContext context, int index) =>
                        const Divider(indent: 16, endIndent: 16),
                    itemBuilder: (BuildContext context, int index) {
                      if (index == 0) {
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.my_location_rounded,
                              color: AppTheme.secondaryDark,
                              size: 20,
                            ),
                          ),
                          title: const Text(
                            'Deteksi Lokasi GPS Perangkat',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text(
                            'Gunakan titik GPS terkini secara otomatis',
                          ),
                          trailing: provider.isUsingGps
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppTheme.secondaryGreen,
                                )
                              : const Icon(Icons.chevron_right_rounded),
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            _handleRefreshGps(provider);
                          },
                        );
                      }

                      final MapEntry<String, KoordinatLokasi> entry =
                          entries[index - 1];
                      final String kecamatan = entry.key;
                      final KoordinatLokasi coord = entry.value;
                      final bool isSelected = !provider.isUsingGps &&
                          provider.selectedFallbackKecamatan == kecamatan;

                      return ListTile(
                        selected: isSelected,
                        selectedTileColor:
                            AppTheme.primaryContainer.withValues(alpha: 0.45),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryBlue
                                : AppTheme.surfaceBackground,
                            borderRadius: BorderRadius.circular(10),
                            border: isSelected
                                ? null
                                : Border.all(color: AppTheme.dividerColor),
                          ),
                          child: Icon(
                            Icons.location_city_rounded,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.primaryBlue,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          'Kecamatan $kecamatan',
                          style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Lat ${coord.latitude.toStringAsFixed(4)}, '
                          'Lng ${coord.longitude.toStringAsFixed(4)}',
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppTheme.primaryBlue,
                              )
                            : null,
                        onTap: () {
                          provider.setFallbackKecamatan(kecamatan);
                          Navigator.of(sheetContext).pop();
                          final ScaffoldMessengerState? messenger =
                              ScaffoldMessenger.maybeOf(this.context);
                          messenger?.hideCurrentSnackBar();
                          messenger?.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Titik lokasi diubah ke Kecamatan $kecamatan.',
                              ),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final SchoolProvider provider = context.watch<SchoolProvider>();
    final List<SchoolModel> schools = provider.filteredSchools;
    final bool hasActiveFilters = provider.searchQuery.trim().isNotEmpty ||
        provider.selectedJenjang != SchoolProvider.filterSemua;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Ayo Sekolah'),
            Text(
              'Radar Zonasi • ${PpdbConstants.wilayahPilot}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primaryBlue,
              onRefresh: () => _handleRefreshList(provider),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                children: <Widget>[
                  // 1. Header Lokasi Aktif (GPS / Fallback Kecamatan)
                  _ActiveLocationCard(
                    provider: provider,
                    onSelectKecamatan: () =>
                        _showKecamatanPickerSheet(provider),
                    onRefreshGps: () => _handleRefreshGps(provider),
                  ),
                  const SizedBox(height: 14),

                  // 2. Search Bar Nama Sekolah
                  TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onChanged: provider.setSearchQuery,
                    decoration: InputDecoration(
                      hintText: 'Cari nama sekolah atau wilayah...',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppTheme.primaryBlue,
                      ),
                      suffixIcon: provider.searchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                provider.setSearchQuery('');
                              },
                              tooltip: 'Hapus pencarian',
                              icon: const Icon(Icons.close_rounded),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. Deretan Filter Chip Jenjang
                  SizedBox(
                    height: 48,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: SchoolProvider.daftarFilterJenjang.length,
                      separatorBuilder: (BuildContext context, int index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (BuildContext context, int index) {
                        final String jenjang =
                            SchoolProvider.daftarFilterJenjang[index];
                        final bool isSelected =
                            provider.selectedJenjang == jenjang;

                        return ChoiceChip(
                          label: Text(jenjang),
                          selected: isSelected,
                          showCheckmark: false,
                          materialTapTargetSize:
                              MaterialTapTargetSize.padded,
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
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textPrimary,
                          ),
                          onSelected: (_) =>
                              provider.setJenjangFilter(jenjang),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. Bar Ringkasan Jumlah & Urutan
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          '${schools.length} sekolah ditemukan',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(color: AppTheme.textPrimary),
                        ),
                      ),
                      const Icon(
                        Icons.near_me_outlined,
                        size: 15,
                        color: AppTheme.secondaryGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Urut: Terdekat',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.secondaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 5. Konten Daftar Sekolah (Loading / Error / Empty / Data)
                  if (provider.isLoadingSchools && provider.allSchools.isEmpty)
                    const _LoadingSchoolsView()
                  else if (provider.errorMessage != null &&
                      provider.allSchools.isEmpty)
                    _ErrorSchoolsView(
                      message: provider.errorMessage!,
                      onRetry: () => provider.loadSchools(),
                    )
                  else if (schools.isEmpty)
                    _EmptySchoolsView(
                      hasActiveFilters: hasActiveFilters,
                      searchQuery: provider.searchQuery,
                      selectedJenjang: provider.selectedJenjang,
                      onResetFilters: () => _handleResetFilters(provider),
                    )
                  else
                    ...schools.map((SchoolModel school) {
                      final double jarakMeter =
                          provider.getDistanceMeters(school);
                      return SchoolCard(
                        key: ValueKey<String>(school.idSchool),
                        school: school,
                        jarakMeter: jarakMeter,
                        onTap: () => _openSchoolDetail(school),
                      );
                    }),
                ],
              ),
            ),
          ),

          // 6. Banner Ringkas Komparasi (muncul jika 1 atau 2 sekolah dipilih)
          if (provider.comparedCount > 0)
            _CompareBottomBanner(
              comparedSchools: provider.comparedSchools,
              onClear: provider.clearComparedSchools,
              onOpenCompare: widget.onNavigateToCompare,
            ),
        ],
      ),
    );
  }
}

class _ActiveLocationCard extends StatelessWidget {
  const _ActiveLocationCard({
    required this.provider,
    required this.onSelectKecamatan,
    required this.onRefreshGps,
  });

  final SchoolProvider provider;
  final VoidCallback onSelectKecamatan;
  final VoidCallback onRefreshGps;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isGps = provider.isUsingGps;
    final Color statusFg =
        isGps ? AppTheme.statusAman : AppTheme.statusWaspada;
    final Color statusBg =
        isGps ? AppTheme.statusAmanBackground : AppTheme.statusWaspadaBackground;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isGps
                        ? AppTheme.secondaryContainer
                        : AppTheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isGps
                        ? Icons.gps_fixed_rounded
                        : Icons.location_city_rounded,
                    color: isGps ? AppTheme.secondaryDark : AppTheme.primaryBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              isGps ? 'GPS Aktif' : 'Fallback Kecamatan',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusFg,
                              ),
                            ),
                          ),
                          CloudStatusBadge(
                            key: const Key('home_cloud_status_badge'),
                            isCloudConnected: provider.isCloudConnected,
                            projectId: provider.firebaseProjectId,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isGps
                            ? 'Lokasi GPS Perangkat'
                            : 'Kec. ${provider.selectedFallbackKecamatan}, Bandar Lampung',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Titik acuan: '
                        '${provider.currentLocation.latitude.toStringAsFixed(4)}, '
                        '${provider.currentLocation.longitude.toStringAsFixed(4)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSelectKecamatan,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(
                        AppTheme.minTouchTargetSize,
                        AppTheme.minTouchTargetSize,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text(
                      'Pilih Kecamatan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed:
                        provider.isLoadingLocation ? null : onRefreshGps,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.secondaryGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(
                        AppTheme.minTouchTargetSize,
                        AppTheme.minTouchTargetSize,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    icon: provider.isLoadingLocation
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.my_location_rounded, size: 18),
                    label: Text(
                      provider.isLoadingLocation
                          ? 'Mendeteksi...'
                          : 'Refresh GPS',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompareBottomBanner extends StatelessWidget {
  const _CompareBottomBanner({
    required this.comparedSchools,
    required this.onClear,
    required this.onOpenCompare,
  });

  final List<SchoolModel> comparedSchools;
  final VoidCallback onClear;
  final VoidCallback? onOpenCompare;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int count = comparedSchools.length;
    final String selectedNames =
        comparedSchools.map((SchoolModel s) => s.namaSekolah).join(' vs ');
    final String subtitle = count == SchoolProvider.maxCompareSchools
        ? '2 sekolah siap dibandingkan di Smart Advisor'
        : 'Pilih 1 sekolah lagi atau langsung buka Komparasi';

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        border: Border(
          top: BorderSide(color: AppTheme.primaryBlue, width: 1.5),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count/${SchoolProvider.maxCompareSchools}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppTheme.primaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  selectedNames,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClear,
            tooltip: 'Hapus pilihan komparasi',
            icon: const Icon(
              Icons.close_rounded,
              color: AppTheme.textSecondary,
            ),
          ),
          FilledButton(
            onPressed: onOpenCompare,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size(
                AppTheme.minTouchTargetSize,
                AppTheme.minTouchTargetSize,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: const Text('Bandingkan'),
          ),
        ],
      ),
    );
  }
}

class _LoadingSchoolsView extends StatelessWidget {
  const _LoadingSchoolsView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: <Widget>[
          const CircularProgressIndicator(color: AppTheme.primaryBlue),
          const SizedBox(height: 16),
          Text(
            'Memuat daftar sekolah Bandar Lampung...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorSchoolsView extends StatelessWidget {
  const _ErrorSchoolsView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: AppTheme.statusBerisiko,
            ),
            const SizedBox(height: 12),
            Text(
              'Gagal Memuat Data Sekolah',
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

class _EmptySchoolsView extends StatelessWidget {
  const _EmptySchoolsView({
    required this.hasActiveFilters,
    required this.searchQuery,
    required this.selectedJenjang,
    required this.onResetFilters,
  });

  final bool hasActiveFilters;
  final String searchQuery;
  final String selectedJenjang;
  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String trimmedQuery = searchQuery.trim();

    String detailMessage;
    if (trimmedQuery.isNotEmpty &&
        selectedJenjang != SchoolProvider.filterSemua) {
      detailMessage =
          'Tidak ditemukan sekolah jenjang $selectedJenjang yang cocok dengan '
          '"$trimmedQuery". Coba kata kunci lain atau ubah filter jenjang.';
    } else if (trimmedQuery.isNotEmpty) {
      detailMessage =
          'Tidak ditemukan sekolah yang cocok dengan "$trimmedQuery". '
          'Pastikan ejaan sudah sesuai atau reset pencarian.';
    } else if (selectedJenjang != SchoolProvider.filterSemua) {
      detailMessage =
          'Belum ada data sekolah untuk jenjang $selectedJenjang saat ini.';
    } else {
      detailMessage =
          'Belum ada data sekolah yang tersedia. Tarik ke bawah untuk memuat ulang.';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: AppTheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 36,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Sekolah Tidak Ditemukan',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              detailMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasActiveFilters) ...<Widget>[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onResetFilters,
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Reset Pencarian & Filter'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
