import 'package:ayo_sekolah/core/constants/app_theme.dart';
import 'package:ayo_sekolah/data/services/firestore_service.dart';
import 'package:ayo_sekolah/data/services/location_service.dart';
import 'package:ayo_sekolah/logic/providers/sandbox_provider.dart';
import 'package:ayo_sekolah/logic/providers/school_provider.dart';
import 'package:ayo_sekolah/presentation/screens/main_navigation_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebaseSafely();
  runApp(const AyoSekolahApp());
}

/// Menginisialisasi Firebase secara aman dalam blok `try-catch`.
///
/// Jika `google-services.json` belum terpasang atau konfigurasi Firebase belum
/// tersedia, aplikasi tetap berjalan normal menggunakan mode fallback lokal
/// in-memory di [FirestoreService].
Future<void> _initializeFirebaseSafely() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (error) {
    debugPrint(
      'Inisialisasi Firebase dilewati (berjalan pada mode fallback lokal): $error',
    );
  }
}

/// Widget root aplikasi **Ayo Sekolah** (Pilot Kota Bandar Lampung).
class AyoSekolahApp extends StatelessWidget {
  const AyoSekolahApp({
    super.key,
    this.firestoreService,
    this.locationService,
  });

  final FirestoreService? firestoreService;
  final LocationService? locationService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FirestoreService>(
          create: (_) => firestoreService ?? FirestoreService(),
        ),
        ChangeNotifierProvider<SchoolProvider>(
          create: (BuildContext context) => SchoolProvider(
            firestoreService: context.read<FirestoreService>(),
            locationService: locationService,
          ),
        ),
        ChangeNotifierProvider<SandboxProvider>(
          create: (BuildContext context) => SandboxProvider(
            firestoreService: context.read<FirestoreService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Ayo Sekolah',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MainNavigationScreen(),
      ),
    );
  }
}
