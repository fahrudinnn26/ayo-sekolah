import 'package:ayo_sekolah/data/services/firestore_service.dart';
import 'package:ayo_sekolah/data/services/location_service.dart';
import 'package:ayo_sekolah/main.dart';
import 'package:ayo_sekolah/presentation/widgets/school_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _FallbackLocationService extends LocationService {
  const _FallbackLocationService();

  @override
  Future<LocationResult> getCurrentLocation({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    return const LocationResult(
      status: LocationStatus.serviceDisabled,
      pesan: 'GPS nonaktif pada lingkungan pengujian. Menggunakan fallback.',
    );
  }
}

void main() {
  testWidgets(
    'AyoSekolahApp menampilkan 3 tab, radar sekolah, komparasi banner, dan detail sekolah',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        AyoSekolahApp(
          firestoreService: FirestoreService(forceLocalFallback: true),
          locationService: const _FallbackLocationService(),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi AppBar, lokasi fallback default, dan 3 tab Material 3
      expect(find.text('Ayo Sekolah'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Komparasi'), findsOneWidget);
      expect(find.text('PPDB Sandbox'), findsOneWidget);
      expect(find.text('Fallback Kecamatan'), findsOneWidget);
      expect(find.text('10 sekolah ditemukan'), findsOneWidget);

      // Verifikasi ModalBottomSheet pilih kecamatan manual
      await tester.tap(find.text('Pilih Kecamatan'));
      await tester.pumpAndSettle();
      expect(find.text('Pilih Kecamatan Manual'), findsOneWidget);
      await tester.tap(find.text('Kecamatan Kedaton'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Kec. Kedaton'), findsOneWidget);

      // Verifikasi filter jenjang SD
      await tester.tap(find.widgetWithText(ChoiceChip, 'SD'));
      await tester.pumpAndSettle();
      expect(find.text('2 sekolah ditemukan'), findsOneWidget);

      // Kembali ke filter Semua
      await tester.tap(find.widgetWithText(ChoiceChip, 'Semua'));
      await tester.pumpAndSettle();
      expect(find.text('10 sekolah ditemukan'), findsOneWidget);

      // Toggle komparasi pada kartu pertama dan verifikasi banner muncul
      final Finder compareButton =
          find.widgetWithText(OutlinedButton, 'Bandingkan').first;
      await tester.ensureVisible(compareButton);
      await tester.pumpAndSettle();
      await tester.tap(compareButton);
      await tester.pumpAndSettle();
      expect(find.text('1/2'), findsOneWidget);

      // Pindah ke tab Komparasi melalui tombol di banner bawah
      await tester.tap(find.widgetWithText(FilledButton, 'Bandingkan'));
      await tester.pumpAndSettle();
      expect(
        find.text('Halaman Komparasi & Smart Advisor - Tahap 4'),
        findsOneWidget,
      );

      // Kembali ke Beranda dan buka Detail Profil Sekolah pertama
      await tester.tap(find.text('Beranda'));
      await tester.pumpAndSettle();
      final Finder firstSchoolCard = find.byType(SchoolCard).first;
      await tester.ensureVisible(firstSchoolCard);
      await tester.pumpAndSettle();
      await tester.tap(firstSchoolCard);
      await tester.pumpAndSettle();

      expect(find.text('Detail Profil Sekolah'), findsOneWidget);
      expect(find.text('Alokasi Kuota per Jalur'), findsOneWidget);
      expect(find.text('Chat WA Panitia'), findsOneWidget);
      expect(find.text('Buka Portal Resmi PPDB'), findsOneWidget);
      expect(find.text('Simulasi Daftar di Sekolah Ini'), findsOneWidget);

      // Klik Simulasi Daftar untuk menuju tab PPDB Sandbox
      await tester.ensureVisible(
        find.text('Simulasi Daftar di Sekolah Ini'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simulasi Daftar di Sekolah Ini'));
      await tester.pumpAndSettle();

      expect(
        find.text('Halaman Simulasi PPDB Sandbox - Tahap 4'),
        findsOneWidget,
      );
    },
  );
}
