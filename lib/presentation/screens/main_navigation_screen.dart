import 'package:ayo_sekolah/core/constants/app_theme.dart';
import 'package:ayo_sekolah/data/models/school_model.dart';
import 'package:ayo_sekolah/logic/providers/sandbox_provider.dart';
import 'package:ayo_sekolah/logic/providers/school_provider.dart';
import 'package:ayo_sekolah/presentation/screens/compare_advisor_screen.dart';
import 'package:ayo_sekolah/presentation/screens/home_screen.dart';
import 'package:ayo_sekolah/presentation/screens/tracking_sandbox_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// Shell navigasi utama aplikasi Ayo Sekolah menggunakan Material 3
/// `NavigationBar` dengan 3 tab utama:
/// 1. Beranda (`HomeScreen`)
/// 2. Komparasi & Smart Advisor (`CompareAdvisorScreen`)
/// 3. PPDB Sandbox (`TrackingSandboxScreen`)
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  static const int _homeTabIndex = 0;
  static const int _compareTabIndex = 1;
  static const int _sandboxTabIndex = 2;

  final GlobalKey<TrackingSandboxScreenState> _sandboxScreenKey =
      GlobalKey<TrackingSandboxScreenState>();

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

  void _handleStartSandboxSimulation(
    SchoolModel school, {
    String? initialJalur,
    double? initialRapor,
  }) {
    _selectTab(_sandboxTabIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _sandboxScreenKey.currentState?.openDraftForm(
        preselectedSchool: school,
        initialJalur: initialJalur,
        initialRapor: initialRapor,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final int comparedCount = context.select<SchoolProvider, int>(
      (SchoolProvider provider) => provider.comparedCount,
    );
    final int draftCount = context.select<SandboxProvider, int>(
      (SandboxProvider provider) => provider.totalDrafts,
    );

    final List<Widget> pages = <Widget>[
      HomeScreen(
        onNavigateToCompare: () => _selectTab(_compareTabIndex),
        onStartSandboxSimulation: (SchoolModel school) =>
            _handleStartSandboxSimulation(school),
      ),
      CompareAdvisorScreen(
        onBackToHome: () => _selectTab(_homeTabIndex),
        onStartSandboxSimulation: _handleStartSandboxSimulation,
      ),
      TrackingSandboxScreen(
        key: _sandboxScreenKey,
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
          NavigationDestination(
            icon: Badge.count(
              isLabelVisible: draftCount > 0,
              count: draftCount,
              backgroundColor: AppTheme.primaryBlue,
              child: const Icon(Icons.assignment_outlined),
            ),
            selectedIcon: Badge.count(
              isLabelVisible: draftCount > 0,
              count: draftCount,
              backgroundColor: AppTheme.primaryBlue,
              child: const Icon(Icons.assignment_rounded),
            ),
            label: 'PPDB Sandbox',
          ),
        ],
      ),
    );
  }
}
