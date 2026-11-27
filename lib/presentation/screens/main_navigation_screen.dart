import 'package:ayo_sekolah/core/constants/app_theme.dart';
import 'package:ayo_sekolah/data/models/school_model.dart';
import 'package:ayo_sekolah/logic/providers/sandbox_provider.dart';
import 'package:ayo_sekolah/logic/providers/school_provider.dart';
import 'package:ayo_sekolah/presentation/screens/home_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// Shell navigasi utama aplikasi Ayo Sekolah menggunakan Material 3
/// `NavigationBar` dengan 3 tab utama:
/// 1. Beranda (`HomeScreen`)
/// 2. Komparasi (placeholder Tahap 4)
/// 3. PPDB Sandbox (placeholder Tahap 4)
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  static const int _homeTabIndex = 0;
  static const int _compareTabIndex = 1;
  static const int _sandboxTabIndex = 2;

  int _selectedIndex = _homeTabIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final SchoolProvider schoolProvider = context.read<SchoolProvider>();
      if (schoolProvider.allSchools.isEmpty &&
          !schoolProvider.isLoadingSchools) {
        schoolProvider.initialize();
      }
      final SandboxProvider sandboxProvider = context.read<SandboxProvider>();
      if (sandboxProvider.drafts.isEmpty && !sandboxProvider.isLoading) {
        sandboxProvider.loadDrafts();
      }
    });
  }

  void _selectTab(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  void _handleStartSandboxSimulation(SchoolModel school) {
    _selectTab(_sandboxTabIndex);
    final ScaffoldMessengerState? messenger =
        ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Simulasi pendaftaran untuk ${school.namaSekolah} siap dilanjutkan '
          'pada halaman PPDB Sandbox (Tahap 4).',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int comparedCount = context.select<SchoolProvider, int>(
      (SchoolProvider provider) => provider.comparedCount,
    );

    final List<Widget> pages = <Widget>[
      HomeScreen(
        onNavigateToCompare: () => _selectTab(_compareTabIndex),
        onStartSandboxSimulation: _handleStartSandboxSimulation,
      ),
      _ComparePlaceholderScreen(
        onBackToHome: () => _selectTab(_homeTabIndex),
      ),
      _SandboxPlaceholderScreen(
        onBackToHome: () => _selectTab(_homeTabIndex),
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        destinations: <NavigationDestination>[
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Badge.count(
              isLabelVisible: comparedCount > 0,
              count: comparedCount,
              backgroundColor: AppTheme.secondaryGreen,
              child: const Icon(Icons.compare_arrows_outlined),
            ),
            selectedIcon: Badge.count(
              isLabelVisible: comparedCount > 0,
              count: comparedCount,
              backgroundColor: AppTheme.secondaryGreen,
              child: const Icon(Icons.compare_arrows_rounded),
            ),
            label: 'Komparasi',
          ),
          const NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded),
            label: 'PPDB Sandbox',
          ),
        ],
      ),
    );
  }
}

class _ComparePlaceholderScreen extends StatelessWidget {
  const _ComparePlaceholderScreen({
    required this.onBackToHome,
  });

  final VoidCallback onBackToHome;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<SchoolModel> comparedSchools =
        context.watch<SchoolProvider>().comparedSchools;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Komparasi'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.compare_arrows_rounded,
                      size: 40,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Halaman Komparasi & Smart Advisor - Tahap 4',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fitur perbandingan berdampingan maksimal 2 sekolah dan '
                    'rekomendasi 4 jalur PPDB akan tersedia pada Tahap 4.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (comparedSchools.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
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
                            'Sekolah terpilih (${comparedSchools.length}/'
                            '${SchoolProvider.maxCompareSchools}):',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppTheme.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...comparedSchools.map(
                            (SchoolModel school) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: <Widget>[
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: 16,
                                    color: AppTheme.secondaryGreen,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      school.namaSekolah,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: onBackToHome,
                    icon: const Icon(Icons.explore_outlined),
                    label: const Text('Kembali ke Beranda'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SandboxPlaceholderScreen extends StatelessWidget {
  const _SandboxPlaceholderScreen({
    required this.onBackToHome,
  });

  final VoidCallback onBackToHome;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PPDB Sandbox'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppTheme.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.assignment_turned_in_outlined,
                      size: 40,
                      color: AppTheme.secondaryDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Halaman Simulasi PPDB Sandbox - Tahap 4',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Formulir latihan pendaftaran, manajemen draf, dan pelacakan '
                    '4 tahap status seleksi simulasi akan tersedia pada Tahap 4.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: onBackToHome,
                    icon: const Icon(Icons.explore_outlined),
                    label: const Text('Jelajahi Sekolah'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
