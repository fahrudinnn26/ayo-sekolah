import 'package:ayo_sekolah/core/constants/app_theme.dart';
import 'package:ayo_sekolah/data/services/firestore_service.dart';
import 'package:ayo_sekolah/data/services/location_service.dart';
import 'package:ayo_sekolah/main.dart';
import 'package:ayo_sekolah/presentation/screens/compare_advisor_screen.dart';
import 'package:ayo_sekolah/presentation/screens/tracking_sandbox_screen.dart';
import 'package:ayo_sekolah/presentation/widgets/cloud_status_badge.dart';
import 'package:ayo_sekolah/presentation/widgets/sandbox_stepper_widget.dart';
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
    'Alur lengkap Ayo Sekolah: Beranda, Komparasi & Smart Advisor, Detail, dan PPDB Sandbox CRUD',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        AyoSekolahApp(
          firestoreService: FirestoreService(forceLocalFallback: true),
          locationService: const _FallbackLocationService(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verifikasi AppBar, lokasi fallback default, dan 3 tab Material 3
      expect(find.text('Ayo Sekolah'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Komparasi'), findsOneWidget);
      expect(find.text('PPDB Sandbox'), findsOneWidget);
      expect(find.text('Fallback Kecamatan'), findsOneWidget);
      expect(find.byKey(const Key('home_cloud_status_badge')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('home_cloud_status_badge')),
          matching: find.text('Mode Lokal'),
        ),
        findsOneWidget,
      );
      expect(find.text('10 sekolah ditemukan'), findsOneWidget);

      // 2. Verifikasi ModalBottomSheet pilih kecamatan manual
      await tester.tap(find.text('Pilih Kecamatan'));
      await tester.pumpAndSettle();
      expect(find.text('Pilih Kecamatan Manual'), findsOneWidget);
      await tester.tap(find.text('Kecamatan Kedaton'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Kec. Kedaton'), findsOneWidget);

      // 3. Verifikasi filter jenjang SD lalu kembali ke Semua
      await tester.tap(find.widgetWithText(ChoiceChip, 'SD'));
      await tester.pumpAndSettle();
      expect(find.text('2 sekolah ditemukan'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Semua'));
      await tester.pumpAndSettle();
      expect(find.text('10 sekolah ditemukan'), findsOneWidget);

      // 4. Pilih 1 sekolah untuk komparasi & buka Tab 2 lewat banner "Bandingkan"
      final Finder compareButton =
          find.widgetWithText(OutlinedButton, 'Bandingkan').first;
      await tester.ensureVisible(compareButton);
      await tester.pumpAndSettle();
      await tester.tap(compareButton);
      await tester.pumpAndSettle();
      expect(find.text('1/2'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Bandingkan'));
      await tester.pumpAndSettle();
      expect(find.text('Komparasi & Smart Advisor'), findsOneWidget);

      final Finder compareScrollable = find
          .descendant(
            of: find.byType(CompareAdvisorScreen),
            matching: find.byType(Scrollable),
          )
          .first;

      // 5. Pilih sekolah ke-2 melalui ModalBottomSheet dan verifikasi komparasi side-by-side
      final Finder pickSecondBtn = find.text('Pilih Sekolah ke-2');
      await tester.scrollUntilVisible(
        pickSecondBtn,
        150,
        scrollable: compareScrollable,
      );
      await tester.pumpAndSettle();
      await tester.tap(pickSecondBtn);
      await tester.pumpAndSettle();

      expect(find.text('Pilih Sekolah untuk Komparasi'), findsOneWidget);
      final Finder pickerAddIcon = find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byIcon(Icons.add_circle_outline_rounded),
          )
          .first;
      await tester.ensureVisible(pickerAddIcon);
      await tester.pumpAndSettle();
      await tester.tap(pickerAddIcon);
      await tester.pumpAndSettle();

      expect(find.text('Akreditasi Sekolah'), findsOneWidget);
      expect(find.text('Jarak Haversine & Status Zonasi'), findsOneWidget);

      final Finder quotaDetailTitle = find.text('Rincian Kuota per Jalur PPDB');
      await tester.scrollUntilVisible(
        quotaDetailTitle,
        200,
        scrollable: compareScrollable,
      );
      await tester.pumpAndSettle();
      expect(quotaDetailTitle, findsOneWidget);

      // 6. Verifikasi Smart Multi-Pathway Advisor interaktif
      final Finder afirmasiSwitch = find.byKey(
        const Key('advisor_afirmasi_switch'),
      );
      await tester.scrollUntilVisible(
        afirmasiSwitch,
        250,
        scrollable: compareScrollable,
      );
      await tester.pumpAndSettle();
      await tester.tap(afirmasiSwitch);
      await tester.pumpAndSettle();

      final Finder advisorRecommendation =
          find.textContaining('Rekomendasi Terbaik: Jalur');
      await tester.scrollUntilVisible(
        advisorRecommendation.first,
        250,
        scrollable: compareScrollable,
      );
      await tester.pumpAndSettle();
      expect(advisorRecommendation, findsWidgets);

      // 7. Kembali ke Beranda, buka Detail Sekolah, lalu klik "Simulasi Daftar di Sekolah Ini"
      await tester.tap(find.text('Beranda'));
      await tester.pumpAndSettle();
      final Finder firstSchoolCard = find.byType(SchoolCard).first;
      await tester.ensureVisible(firstSchoolCard);
      await tester.pumpAndSettle();
      await tester.tap(firstSchoolCard);
      await tester.pumpAndSettle();

      expect(find.text('Detail Profil Sekolah'), findsOneWidget);
      final Finder startSandboxBtn =
          find.text('Simulasi Daftar di Sekolah Ini');
      await tester.ensureVisible(startSandboxBtn);
      await tester.pumpAndSettle();
      await tester.tap(startSandboxBtn);
      await tester.pumpAndSettle();

      // 8. Verifikasi otomatis pindah ke PPDB Sandbox & form modal langsung terbuka (pre-selected)
      expect(find.text('Simulasi Pendaftaran Baru'), findsOneWidget);

      // Uji validasi NISN < 10 digit
      await tester.enterText(
        find.byKey(const Key('sandbox_nama_siswa_field')),
        'Budi Santoso',
      );
      await tester.enterText(
        find.byKey(const Key('sandbox_nisn_field')),
        '12345',
      );
      await tester.enterText(
        find.byKey(const Key('sandbox_rapor_field')),
        '88.5',
      );
      final Finder submitDraftButton = find.byKey(
        const Key('sandbox_submit_draft_button'),
      );
      await tester.ensureVisible(submitDraftButton);
      await tester.pumpAndSettle();
      await tester.tap(submitDraftButton);
      await tester.pumpAndSettle();
      expect(
        find.text('NISN harus terdiri dari tepat 10 digit angka.'),
        findsOneWidget,
      );

      // Isi NISN valid 10 digit dan simpan (Create)
      await tester.enterText(
        find.byKey(const Key('sandbox_nisn_field')),
        '0091234567',
      );
      await tester.ensureVisible(submitDraftButton);
      await tester.pumpAndSettle();
      await tester.tap(submitDraftButton);
      await tester.pumpAndSettle();

      // 9. Verifikasi Read: banner edukatif, status koneksi, data siswa, stepper, checklist berkas, & portal
      expect(find.text('PPDB Sandbox (Simulasi Mandiri)'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('sandbox_cloud_status_badge')),
          matching: find.text('Mode Lokal'),
        ),
        findsOneWidget,
      );
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('NISN: 0091234567'), findsOneWidget);
      expect(find.byType(SandboxStepperWidget), findsOneWidget);
      expect(find.text('Progres Simulasi (Tahap 1/4)'), findsOneWidget);

      final Finder sandboxScrollable = find
          .descendant(
            of: find.byType(TrackingSandboxScreen),
            matching: find.byType(Scrollable),
          )
          .first;

      // 10. Verifikasi Stepper interaktif naik tahap 1 -> 2
      final Finder nextStepButton = find.text('Lanjut: Kelengkapan Berkas');
      await tester.scrollUntilVisible(
        nextStepButton,
        150,
        scrollable: sandboxScrollable,
      );
      await tester.pumpAndSettle();
      await tester.tap(nextStepButton);
      await tester.pumpAndSettle();
      expect(find.text('Progres Simulasi (Tahap 2/4)'), findsOneWidget);

      // 11. Verifikasi tombol Portal Resmi & Update (Edit draf)
      final Finder portalBtn = find.text('Buka Portal Resmi PPDB');
      await tester.scrollUntilVisible(
        portalBtn,
        150,
        scrollable: sandboxScrollable,
      );
      await tester.drag(sandboxScrollable, const Offset(0, -140));
      await tester.pumpAndSettle();
      expect(portalBtn, findsOneWidget);

      final Finder editButton = find.widgetWithText(OutlinedButton, 'Edit');
      await tester.tap(editButton);
      await tester.pumpAndSettle();
      expect(find.text('Edit Draf Simulasi PPDB'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('sandbox_nama_siswa_field')),
        'Budi Santoso Pratama',
      );
      await tester.ensureVisible(submitDraftButton);
      await tester.pumpAndSettle();
      await tester.tap(submitDraftButton);
      await tester.pumpAndSettle();

      await tester.drag(sandboxScrollable, const Offset(0, 600));
      await tester.pumpAndSettle();
      expect(find.text('Budi Santoso Pratama'), findsOneWidget);

      // 12. Verifikasi Delete dengan dialog konfirmasi
      await tester.scrollUntilVisible(
        portalBtn,
        150,
        scrollable: sandboxScrollable,
      );
      await tester.drag(sandboxScrollable, const Offset(0, -140));
      await tester.pumpAndSettle();
      final Finder deleteButton = find.widgetWithText(OutlinedButton, 'Hapus');
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();
      expect(find.text('Hapus Draf Simulasi?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
      await tester.pumpAndSettle();
      expect(find.text('Belum Ada Draf Simulasi'), findsOneWidget);
    },
  );

  testWidgets(
    'CloudStatusBadge menampilkan status Cloud Terhubung (hijau) dan Mode Lokal (abu-abu)',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Column(
              children: <Widget>[
                CloudStatusBadge(
                  key: Key('cloud_connected_badge'),
                  isCloudConnected: true,
                  projectId: 'ayo-sekolah-908f4',
                ),
                CloudStatusBadge(
                  key: Key('local_mode_badge'),
                  isCloudConnected: false,
                ),
              ],
            ),
          ),
        ),
      );

      final Finder cloudTextFinder = find.descendant(
        of: find.byKey(const Key('cloud_connected_badge')),
        matching: find.text('Cloud Terhubung'),
      );
      final Finder localTextFinder = find.descendant(
        of: find.byKey(const Key('local_mode_badge')),
        matching: find.text('Mode Lokal'),
      );

      expect(cloudTextFinder, findsOneWidget);
      expect(localTextFinder, findsOneWidget);

      final Text cloudText = tester.widget<Text>(cloudTextFinder);
      final Text localText = tester.widget<Text>(localTextFinder);

      expect(cloudText.style?.color, AppTheme.statusAman);
      expect(localText.style?.color, AppTheme.textSecondary);
    },
  );
}
