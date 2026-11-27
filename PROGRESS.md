# Progres Pengembangan — Ayo Sekolah

Aplikasi Flutter **Ayo Sekolah** (Direktori Sekolah, Rekomendasi Jalur, dan Simulasi PPDB Sandbox) untuk pilot wilayah **Kota Bandar Lampung**.

---

## Ringkasan Progres

- [x] **Tahap 1: Konfigurasi Android, Konstanta, & Model Data** (Selesai)
- [x] **Tahap 2: Logika Inti, Services, Data Sampel Sekolah Bandar Lampung, & State Provider** (Selesai)
- [x] **Tahap 3: Konfigurasi `main.dart`, Navigasi Utama, Reusable Widgets, Layar Beranda & Radar Sekolah, & Detail Profil Sekolah** (Selesai)
- [ ] **Tahap 4:** Halaman Komparasi & Smart Advisor serta Halaman Simulasi PPDB Sandbox

> **Catatan Progres Tahap 3:** Tab Komparasi dan PPDB Sandbox saat ini menggunakan placeholder rapi yang akan diimplementasikan penuh pada Tahap 4.

---

## Rincian Pekerjaan Tahap 1

### 1. Konfigurasi Android
- **`android/app/build.gradle.kts`** *(Dimodifikasi)*
  - Mengatur `minSdk = 21` pada blok `defaultConfig`.
- **`android/app/src/main/AndroidManifest.xml`** *(Dimodifikasi)*
  - Menambahkan izin `android.permission.INTERNET`, `android.permission.ACCESS_FINE_LOCATION`, dan `android.permission.ACCESS_COARSE_LOCATION`.
  - Menambahkan blok `<queries>` untuk mendukung intent URL `https` (portal web resmi PPDB), tautan `https://wa.me`, serta skema `whatsapp`.

### 2. Konstanta & Tema (`lib/core/constants/`)
- **`lib/core/constants/app_theme.dart`** *(Baru)*
  - Definisi `AppTheme.lightTheme` berbasis Material Design 3 (`useMaterial3: true`).
  - Palet warna biru-hijau edukatif yang bersih (`primaryBlue: #0B6E8F`, `secondaryGreen: #0F9D8A`, latar `#F5F9FA`) dilengkapi warna semantik status zonasi (Aman, Waspada, Berisiko).
  - Hierarki tipografi yang jelas serta standar ukuran target sentuh (*touch target*) tombol minimal `48dp` (`AppTheme.minTouchTargetSize = 48.0`) pada `ElevatedButton`, `FilledButton`, `OutlinedButton`, `TextButton`, `IconButton`, dan `ListTile`.
- **`lib/core/constants/ppdb_constants.dart`** *(Baru)*
  - Aturan batas jarak zonasi: `<= 800` meter (`"Sangat Aman"`), `801–1500` meter (`"Waspada"`), dan `> 1500` meter (`"Berisiko"`), disertai enum `StatusZonasi` dan helper `PpdbConstants.evaluasiStatusZonasi(...)`.
  - Daftar jalur PPDB: `Zonasi`, `Prestasi`, `Afirmasi`, `Mutasi`.
  - Referensi jenjang sekolah (`SD`, `SMP`, `SMA`, `SMK`), status sekolah (`Negeri`, `Swasta`), dan label tahapan status seleksi simulasi (`1`–`4`).
  - Peta koordinat fallback (`KoordinatLokasi` dengan `latitude` dan `longitude`) untuk kecamatan utama di Kota Bandar Lampung (`Kedaton`, `Rajabasa`, `Tanjung Karang Pusat`, `Sukarame`, `Kemiling`, `Way Halim`, `Teluk Betung Selatan`) saat GPS mati atau izin lokasi ditolak.

### 3. Model Data Firestore (`lib/data/models/`)
- **`lib/data/models/school_model.dart`** *(Baru)*
  - Class `SchoolModel` dengan field: `idSchool`, `namaSekolah`, `jenjang`, `status`, `akreditasi`, `latitude`, `longitude`, `kontakWa`, `kuota` (`Map<String, int>`), `passingGrade`, `fasilitas` (`List<String>`), `urlPortalPpdb`, dan `alamatPosko`.
  - Dilengkapi `fromFirestore`, `fromMap`, `toMap`, `copyWith`, getter `totalKuota`, serta implementasi `==` dan `hashCode`.
- **`lib/data/models/registration_draft_model.dart`** *(Baru)*
  - Class `RegistrationDraftModel` dengan field: `idRegistrasi`, `idSchool`, `namaSekolah`, `namaSiswa`, `nisn`, `jalurPilihan`, `rataRataRapor`, `jarakMeter`, `statusSeleksi` (`1`–`4`: 1 Draf Tersimpan, 2 Kelengkapan Berkas, 3 Siap Verifikasi, 4 Terkirim Simulasi), dan `createdAt` (`DateTime`).
  - Dilengkapi `fromFirestore`, `fromMap`, `toMap` (menggunakan `Timestamp` Firestore), `copyWith`, getter `statusSeleksiLabel`, serta implementasi `==` dan `hashCode`.

---

## Rincian Pekerjaan Tahap 2

### 1. Utilitas & Algoritma (`lib/core/utils/`)
- **`lib/core/utils/haversine_calculator.dart`** *(Baru)*
  - Menghitung jarak garis lurus akurat dalam satuan meter (`hitungJarakMeter`, `hitungJarakAntarKoordinatMeter`) dan kilometer (`hitungJarakKilometer`, `hitungJarakAntarKoordinatKilometer`, `meterKeKilometer`) menggunakan rumus Haversine.
  - Menentukan status zonasi (`tentukanStatusZonasi`, `tentukanLabelZonasi`) berdasarkan konstanta di `PpdbConstants` (`<= 800m`: Sangat Aman, `801–1500m`: Waspada, `> 1500m`: Berisiko) serta helper `formatJarak`.
- **`lib/core/utils/smart_pathway_advisor.dart`** *(Baru)*
  - Algoritma evaluasi peluang 4 jalur PPDB (`Zonasi`, `Prestasi`, `Afirmasi`, `Mutasi`) untuk sebuah `SchoolModel` berdasarkan jarak domisili (meter), rata-rata nilai rapor dibandingkan `passingGrade`, kepemilikan dokumen Afirmasi (KIP/PKH/DTKS), dan kepemilikan surat Mutasi orang tua.
  - Mengembalikan objek `RekomendasiJalurResult` berisi jalur terbaik (`jalurTerbaik`), skor (`skorTerbaik`), tingkat peluang (`TingkatPeluang`: Tinggi/Sedang/Rendah), penjelasan alasan singkat dalam Bahasa Indonesia, serta rincian `EvaluasiJalur` seluruh jalur terurut dari peluang tertinggi.

### 2. Data Sampel & Layanan (`lib/data/services/`)
- **`lib/data/services/sample_schools_data.dart`** *(Baru)*
  - Menyediakan 10 data sampel sekolah negeri realistis di Kota Bandar Lampung mencakup jenjang SD, SMP, SMA, dan SMK: SMAN 2 Bandar Lampung, SMAN 9 Bandar Lampung, SMAN 1 Bandar Lampung, SMPN 1 Bandar Lampung, SMPN 2 Bandar Lampung, SMPN 22 Bandar Lampung, SMKN 2 Bandar Lampung, SMKN 4 Bandar Lampung, SDN 2 Rawa Laut, dan SDN 1 Sukarame.
  - Lengkap dengan koordinat akurat area Bandar Lampung, kuota per jalur, passing grade, daftar fasilitas, kontak WA panitia format `628...`, alamat posko verifikasi, serta URL portal resmi PPDB.
- **`lib/data/services/location_service.dart`** *(Baru)*
  - Layanan pengambilan posisi GPS perangkat menggunakan `geolocator` dengan penanganan status layanan dan izin yang aman (`LocationStatus` & `LocationResult`), sehingga tidak crash bila GPS mati, izin ditolak, atau timeout, serta mendukung fallback koordinat kecamatan dari `PpdbConstants`.
- **`lib/data/services/external_launcher_service.dart`** *(Baru)*
  - Layanan menggunakan `url_launcher` untuk membuka portal resmi PPDB di browser eksternal (`LaunchMode.externalApplication`) dan membuka chat WhatsApp panitia (`https://wa.me/...`) lengkap dengan normalisasi nomor `628...` dan template pesan otomatis menanyakan jadwal/syarat PPDB.
- **`lib/data/services/firestore_service.dart`** *(Baru)*
  - Layanan CRUD Cloud Firestore untuk koleksi `schools` (termasuk fungsi seeding otomatis `seedSampleSchoolsIfEmpty` dari `SampleSchoolsData.schools` jika koleksi masih kosong) dan CRUD penuh (Create, Read, Update, Delete, serta pembaruan status seleksi) untuk koleksi `ppdb_registrations` (`RegistrationDraftModel`).
  - Dilengkapi mode fallback lokal (*in-memory*) yang aktif otomatis saat `Firebase.apps.isEmpty` sehingga aplikasi tetap dapat diuji dengan aman sebelum konfigurasi Firebase selesai.

### 3. State Management (`lib/logic/providers/`)
- **`lib/logic/providers/school_provider.dart`** *(Baru)*
  - Mengelola daftar sekolah, filter jenjang (`Semua`/`SD`/`SMP`/`SMA`/`SMK`), pencarian nama sekolah, deteksi lokasi GPS atau pemilihan kecamatan fallback, pengurutan otomatis berdasarkan jarak terdekat (`HaversineCalculator`), helper evaluasi `SmartPathwayAdvisor`, serta pengelolaan komparasi maksimal 2 sekolah.
- **`lib/logic/providers/sandbox_provider.dart`** *(Baru)*
  - Mengelola daftar draf simulasi pendaftaran (`RegistrationDraftModel`) dengan fungsi muat, tambah, ubah data/status tahapan (1–4), dan hapus yang terhubung langsung ke `FirestoreService`.

---

## Rincian Pekerjaan Tahap 3

### 1. Konfigurasi Entrypoint & Shell Navigasi Utama
- **`lib/main.dart`** *(Dimodifikasi)*
  - Menambahkan inisialisasi Firebase secara aman di dalam blok `try-catch` (`Firebase.initializeApp()`), sehingga aplikasi tidak crash jika `google-services.json` belum terpasang dan otomatis berjalan menggunakan fallback lokal in-memory di `FirestoreService`.
  - Membungkus aplikasi (`AyoSekolahApp`) dengan `MultiProvider` (`FirestoreService`, `SchoolProvider`, dan `SandboxProvider`) serta menerapkan tema `AppTheme.lightTheme`.
- **`lib/presentation/screens/main_navigation_screen.dart`** *(Baru)*
  - Menyediakan shell navigasi Material Design 3 (`NavigationBar`) dengan 3 tab utama menggunakan `IndexedStack`:
    - Tab 1: **Beranda** (`HomeScreen`).
    - Tab 2: **Komparasi** (placeholder rapi bertuliskan *"Halaman Komparasi & Smart Advisor - Tahap 4"*, lengkap dengan badge jumlah sekolah terpilih).
    - Tab 3: **PPDB Sandbox** (placeholder rapi bertuliskan *"Halaman Simulasi PPDB Sandbox - Tahap 4"*).
  - Menginisialisasi data sekolah dan draf simulasi secara aman melalui `WidgetsBinding.instance.addPostFrameCallback`.

### 2. Komponen Reusable (`lib/presentation/widgets/`)
- **`lib/presentation/widgets/zonasi_badge.dart`** *(Baru)*
  - Badge indikator status zonasi berbasis warna semantik (`<= 800 m` Hijau *Sangat Aman*, `801–1500 m` Oranye/Kuning *Waspada*, `> 1500 m` Merah *Berisiko*) lengkap dengan ikon status dan jarak Haversine terformat (`m`/`km`).
- **`lib/presentation/widgets/school_card.dart`** *(Baru)*
  - Kartu sekolah Material 3 menampilkan badge jenjang/status/akreditasi, nama sekolah, ringkasan alamat posko, `ZonasiBadge`, total kuota & passing grade, serta tombol toggle **"Bandingkan"** (minimal 48dp) yang terhubung ke batas komparasi maks. 2 sekolah di `SchoolProvider`.

### 3. Layar 1 — Beranda & Radar Sekolah (`lib/presentation/screens/home_screen.dart`)
- **`lib/presentation/screens/home_screen.dart`** *(Baru)*
  - Header lokasi aktif menampilkan status titik acuan (**GPS Aktif** atau **Fallback Kecamatan Bandar Lampung**) disertai tombol **"Pilih Kecamatan"** (membuka `ModalBottomSheet` seluruh kecamatan fallback dari `PpdbConstants`) dan **"Refresh GPS"**.
  - Search bar pencarian nama/wilayah sekolah serta deretan `ChoiceChip` filter jenjang (`Semua`, `SD`, `SMP`, `SMA`, `SMK`).
  - Daftar `SchoolCard` terurut otomatis dari jarak terdekat via `SchoolProvider`, mendukung *pull-to-refresh* (`RefreshIndicator`), state loading/error, serta tampilan ramah saat pencarian kosong lengkap dengan tombol reset filter.
  - Banner ringkas komparasi di bagian bawah yang muncul otomatis saat 1–2 sekolah dipilih untuk langsung berpindah ke tab Komparasi.

### 4. Layar 2 — Detail Profil Sekolah (`lib/presentation/screens/school_detail_screen.dart`)
- **`lib/presentation/screens/school_detail_screen.dart`** *(Baru)*
  - Menampilkan profil lengkap sekolah: nama, badge jenjang/status/akreditasi, `ZonasiBadge`, jarak garis lurus Haversine terhadap lokasi aktif, passing grade, total kuota, serta kartu alamat posko verifikasi beserta koordinat.
  - Grid kartu 2x2 responsif untuk rincian alokasi kuota 4 jalur PPDB (`Zonasi`, `Prestasi`, `Afirmasi`, `Mutasi`) beserta persentase dan indikator progres, serta daftar fasilitas sekolah menggunakan `Wrap`.
  - Tombol aksi utama bertarget sentuh >= 48dp (52dp): **"Simulasi Daftar di Sekolah Ini"** (mengarahkan ke tab PPDB Sandbox + SnackBar), **"Chat WA Panitia"** (`ExternalLauncherService`), dan **"Buka Portal Resmi PPDB"** (`ExternalLauncherService`).

### 5. Pengujian Widget
- **`test/widget_test.dart`** *(Dimodifikasi)*
  - Memperbarui smoke test untuk memverifikasi `AyoSekolahApp` berjalan aman pada mode fallback lokal dan dapat berpindah antar 3 tab navigasi Material 3.

---

## Daftar File Baru & Termodifikasi

| Tahap | Status | Path File | Deskripsi |
| --- | --- | --- | --- |
| Tahap 1 | Dimodifikasi | `android/app/build.gradle.kts` | Pengaturan `minSdk = 21` |
| Tahap 1 | Dimodifikasi | `android/app/src/main/AndroidManifest.xml` | Izin lokasi/internet dan `<queries>` HTTPS & WhatsApp |
| Tahap 1 | Baru | `lib/core/constants/app_theme.dart` | Tema Material Design 3 biru-hijau edukatif & touch target >= 48dp |
| Tahap 1 | Baru | `lib/core/constants/ppdb_constants.dart` | Aturan jarak zonasi, jalur PPDB, status seleksi, & koordinat fallback Bandar Lampung |
| Tahap 1 | Baru | `lib/data/models/school_model.dart` | Model data sekolah + serialisasi Firestore |
| Tahap 1 | Baru | `lib/data/models/registration_draft_model.dart` | Model data draf pendaftaran simulasi + serialisasi Firestore |
| Tahap 1–3 | Diperbarui | `PROGRESS.md` | Dokumentasi ringkasan progres proyek |
| Tahap 2 | Baru | `lib/core/utils/haversine_calculator.dart` | Perhitungan jarak Haversine (meter/km) & evaluasi status zonasi |
| Tahap 2 | Baru | `lib/core/utils/smart_pathway_advisor.dart` | Algoritma rekomendasi 4 jalur PPDB & rincian peluang Bahasa Indonesia |
| Tahap 2 | Baru | `lib/data/services/sample_schools_data.dart` | 10 data sampel sekolah negeri Bandar Lampung (SD/SMP/SMA/SMK) |
| Tahap 2 | Baru | `lib/data/services/location_service.dart` | Layanan GPS aman berbasis `geolocator` dengan status fallback |
| Tahap 2 | Baru | `lib/data/services/external_launcher_service.dart` | Peluncur portal PPDB eksternal & WhatsApp panitia (`wa.me`) |
| Tahap 2 | Baru | `lib/data/services/firestore_service.dart` | Layanan CRUD Firestore (`schools` & `ppdb_registrations`) + fallback in-memory |
| Tahap 2 | Baru | `lib/logic/providers/school_provider.dart` | State provider daftar sekolah, filter, lokasi, pengurutan jarak, & komparasi (maks. 2) |
| Tahap 2 | Baru | `lib/logic/providers/sandbox_provider.dart` | State provider CRUD draf simulasi pendaftaran PPDB Sandbox |
| Tahap 3 | Dimodifikasi | `lib/main.dart` | Entrypoint aman Firebase `try-catch`, `MultiProvider`, & `AppTheme.lightTheme` |
| Tahap 3 | Baru | `lib/presentation/screens/main_navigation_screen.dart` | Shell navigasi Bottom Navigation Bar Material 3 (Beranda, Komparasi, PPDB Sandbox) |
| Tahap 3 | Baru | `lib/presentation/widgets/zonasi_badge.dart` | Badge status zonasi berbasis warna & jarak Haversine terformat |
| Tahap 3 | Baru | `lib/presentation/widgets/school_card.dart` | Kartu sekolah Material 3 + tombol toggle "Bandingkan" terhubung ke `SchoolProvider` |
| Tahap 3 | Baru | `lib/presentation/screens/home_screen.dart` | Layar 1: Beranda & Radar Sekolah (lokasi GPS/fallback, search, filter jenjang, banner komparasi) |
| Tahap 3 | Baru | `lib/presentation/screens/school_detail_screen.dart` | Layar 2: Detail Profil Sekolah (profil, kuota per jalur, fasilitas, & aksi WA/Portal/Simulasi) |
| Tahap 3 | Dimodifikasi | `test/widget_test.dart` | Smoke test `AyoSekolahApp` dengan mode fallback lokal & navigasi 3 tab |

---

## Verifikasi

- Analisis statis dijalankan dengan `flutter analyze` untuk memastikan 0 error dan 0 warning pada seluruh file proyek.
