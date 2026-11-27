# Progres Pengembangan — Ayo Sekolah

Aplikasi Flutter **Ayo Sekolah** (Direktori Sekolah, Rekomendasi Jalur, dan Simulasi PPDB Sandbox) untuk pilot wilayah **Kota Bandar Lampung**.

---

## Ringkasan Progres

- [x] **Tahap 1: Konfigurasi Android, Konstanta, & Model Data** (Selesai)
- [x] **Tahap 2: Logika Inti, Services, Data Sampel Sekolah Bandar Lampung, & State Provider** (Selesai)
- [x] **Tahap 3: Konfigurasi `main.dart`, Navigasi Utama, Reusable Widgets, Layar Beranda & Radar Sekolah, & Detail Profil Sekolah** (Selesai)
- [x] **Tahap 4: Layar Komparasi & Smart Pathway Advisor, Progress Stepper, Layar PPDB Sandbox (CRUD Penuh), & Integrasi Navigasi Antar Layar** (Selesai)
- [x] **Tahap 5: Integrasi Gradle Firebase Android, Seeding Otomatis Cloud Firestore, & Indikator Status Koneksi Cloud** (Selesai)
- [x] **Tahap 6: Hotfix UTS — Perbaikan UI/UX, Pemangkasan Teks Duplikat, Pengamanan Demo WhatsApp, & Label Transparansi Pilot** (Selesai)

> **Catatan Progres Tahap 6 (Hotfix UTS):** Seluruh perbaikan siap rilis Beta UTS telah diselesaikan: ruang bawah `ListView` PPDB Sandbox diperlebar (`>= 112dp + safe area bottom`) agar FAB **"+ Simulasi Baru"** tidak lagi menimpa tombol **"Buka Portal Resmi PPDB"**, label tombol tahap 4 stepper dipersingkat menjadi **"Ulangi"** dengan ikon refresh, kotak ringkasan **Smart Multi-Pathway Advisor** dipadatkan (judul jalur terbaik, badge persentase peluang, 1 kalimat kesimpulan non-duplikat) dengan tombol ringkas **"Simulasi Jalur \<Jalur\>"**, fitur **"Chat WA Panitia"** diamankan lewat dialog konfirmasi **Mode Pilot UTS** (**Salin Pesan** & **Buka WhatsApp** ke `https://wa.me/?text=...` tanpa nomor acak), serta label transparansi data sampel pilot ditambahkan di Beranda & Detail Sekolah.

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

## Rincian Pekerjaan Tahap 4

### 1. Layar 3 — Komparasi Sekolah & Smart Pathway Advisor
- **`lib/presentation/screens/compare_advisor_screen.dart`** *(Baru)*
  - **Bagian Komparasi Side-by-Side:** Mengambil maksimal 2 sekolah terpilih dari `SchoolProvider`. Menampilkan empty state informatif saat 0 atau baru 1 sekolah dipilih, lengkap dengan tombol untuk memilih sekolah melalui `ModalBottomSheet` (berfitur pencarian dan urutan jarak terdekat) atau kembali ke Beranda.
  - Membandingkan berdampingan: **Akreditasi**, **Jarak Haversine & `ZonasiBadge`**, **Passing Grade**, **Total Kuota & rincian kuota 4 jalur (`Zonasi`, `Prestasi`, `Afirmasi`, `Mutasi`)**, serta **jumlah & ringkasan fasilitas** dengan penanda visual warna hijau (`AppTheme.statusAman` / `AppTheme.statusAmanBackground`) pada nilai yang lebih unggul, disertai tombol **Ganti** dan **Hapus** untuk setiap slot sekolah.
  - **Bagian Smart Multi-Pathway Advisor (Interaktif):** Form input ringkas dengan `Slider` + `TextField` tersinkronisasi untuk **Rata-Rata Nilai Rapor (0–100)**, `SwitchListTile` kepemilikan **Dokumen Afirmasi (KIP/PKH/DTKS)**, dan `SwitchListTile` kepemilikan **Surat Mutasi/Perpindahan Tugas Orang Tua**.
  - Mengevaluasi otomatis menggunakan `SmartPathwayAdvisor` untuk seluruh sekolah yang sedang dikomparasi (atau menyediakan dropdown pilih sekolah apabila daftar komparasi kosong), menampilkan kartu rekomendasi jalur terbaik, badge tingkat peluang (**Tinggi/Sedang/Rendah**), penjelasan alasan, rincian peluang 4 jalur, serta tombol pintas simulasi ke PPDB Sandbox.
- **`lib/logic/providers/school_provider.dart`** *(Dimodifikasi)*
  - Menambahkan helper `replaceComparedSchool(oldIdSchool, newSchool)` untuk mengganti sekolah pada slot komparasi tertentu tanpa mengubah urutan tampilan kiri-kanan.

### 2. Widget Progress Stepper 4 Tahap
- **`lib/presentation/widgets/sandbox_stepper_widget.dart`** *(Baru)*
  - Komponen horizontal stepper 4 tahap sesuai `statusSeleksi` pada `RegistrationDraftModel` (`1`: Draf Tersimpan, `2`: Kelengkapan Berkas, `3`: Siap Verifikasi, `4`: Terkirim Simulasi).
  - Dilengkapi indikator progres visual, keterangan tahapan aktif, ketukan langsung pada node tahapan, serta tombol aksi interaktif untuk menaikkan, memundurkan, atau mengulang tahap seleksi.

### 3. Layar 4 — PPDB Sandbox & Simulasi Pendaftaran (CRUD Penuh)
- **`lib/presentation/screens/tracking_sandbox_screen.dart`** *(Baru)*
  - **Banner Edukatif:** Menegaskan bahwa fitur ini adalah **PPDB Sandbox (Simulasi Mandiri)** untuk latihan dan cek kesiapan berkas, bukan portal pendaftaran resmi pemerintah.
  - **Manajemen Draf CRUD Penuh (`SandboxProvider`):**
    - **Read:** Daftar kartu draf simulasi menampilkan nama siswa, NISN, sekolah tujuan, jalur pilihan, jarak (`ZonasiBadge`), rata-rata nilai rapor, `SandboxStepperWidget`, **checklist kesiapan berkas dinamis** sesuai jalur pilihan (`Zonasi`/`Prestasi`/`Afirmasi`/`Mutasi`), tombol **Edit**, tombol **Hapus** dengan `AlertDialog` konfirmasi, serta tombol pintas **"Buka Portal Resmi PPDB"** (`ExternalLauncherService`).
    - **Create & Update:** `FloatingActionButton.extended` ("Simulasi Baru") dan tombol Edit membuka modal formulir terpadu (`showSandboxDraftFormSheet`) dengan dropdown pilih sekolah dari `SchoolProvider`, input Nama Siswa, input NISN bervalidasi tepat **10 digit angka**, pilihan Jalur PPDB beserta informasi kuota jalur, input Rata-Rata Nilai Rapor (0–100), serta perhitungan otomatis `jarakMeter` secara langsung dari lokasi aktif user.
    - **Delete:** Konfirmasi dialog sebelum menghapus draf melalui `SandboxProvider.deleteDraft`.

### 4. Integrasi Navigasi & Alur Antar Layar
- **`lib/presentation/screens/main_navigation_screen.dart`** *(Dimodifikasi)*
  - Menghapus seluruh placeholder Tahap 4; Tab 2 kini menampilkan `CompareAdvisorScreen` dan Tab 3 menampilkan `TrackingSandboxScreen` (dengan badge jumlah draf pada `NavigationBar`).
  - Menghubungkan alur lintas layar: banner **"Bandingkan"** pada `HomeScreen` langsung berpindah ke Tab 2 (Komparasi), dan tombol simulasi dari `SchoolDetailScreen` maupun `CompareAdvisorScreen` langsung berpindah ke Tab 3 dan membuka formulir pembuatan draf dengan sekolah otomatis terpilih (*pre-selected*).
- **`lib/presentation/screens/school_detail_screen.dart`** *(Dimodifikasi)*
  - Menghubungkan tombol **"Simulasi Daftar di Sekolah Ini"** ke callback navigasi sandbox dan fallback langsung `showSandboxDraftFormSheet(preselectedSchool: widget.school)` sehingga form pembuatan simulasi langsung terbuka dengan sekolah tersebut otomatis terpilih.

### 5. Pengujian Widget Terintegrasi
- **`test/widget_test.dart`** *(Dimodifikasi)*
  - Memperluas widget test end-to-end mencakup alur Beranda, pemilihan sekolah komparasi via banner & `ModalBottomSheet`, verifikasi komparasi side-by-side & Smart Advisor, perpindahan dari Detail Sekolah ke form Sandbox *pre-selected*, validasi NISN 10 digit, CRUD lengkap (Create, Read, Update, Delete), serta interaksi `SandboxStepperWidget`.

---

## Rincian Pekerjaan Tahap 5

### 1. Integrasi Gradle Firebase Android
- **`android/settings.gradle.kts`** *(Dimodifikasi)*
  - Menambahkan deklarasi plugin `id("com.google.gms.google-services") version "4.4.4" apply false` yang kompatibel dengan Android Gradle Plugin `9.3.1` dan Gradle `9.5.0`.
- **`android/app/build.gradle.kts`** *(Dimodifikasi)*
  - Memverifikasi `applicationId = "com.ayosekolah.ayo_sekolah"` sesuai persis dengan `package_name` pada `android/app/google-services.json`.
  - Menerapkan plugin `id("com.google.gms.google-services")` pada modul `:app`.
  - Menyesuaikan `minSdk = 24` agar memenuhi kebutuhan SDK minimal `firebase_core` (`^5.2.0`) dan `cloud_firestore` (`^7.2.0`) saat manifest merge Android.

### 2. Inisialisasi Firebase & Seeding Otomatis Cloud Firestore
- **`lib/main.dart`** *(Dimodifikasi)*
  - Memastikan `Firebase.initializeApp()` berjalan lancar saat aplikasi dibuka di Android dengan pencatatan `projectId` aktif (`ayo-sekolah-908f4`) serta tetap aman bila konfigurasi tidak tersedia.
  - Memicu pemeriksaan & seeding awal koleksi `schools` (`FirestoreService.seedSampleSchoolsIfEmpty()`) tanpa menghambat rendering layar awal saat terhubung ke Cloud Firestore.
- **`lib/data/services/firestore_service.dart`** *(Dimodifikasi)*
  - Menambahkan getter `isCloudConnected` dan `firebaseProjectId` untuk memudahkan pemeriksaan status koneksi di lapisan state dan UI.
  - Memperkuat `seedSampleSchoolsIfEmpty()` dengan guard konkurensi (*single-flight*) agar pemanggilan bersamaan saat startup dan pemuatan `SchoolProvider` tidak menumpuk ketika melakukan seeding otomatis 10 data sekolah Bandar Lampung dari `SampleSchoolsData.schools` ke koleksi `schools` Cloud Firestore.
- **`lib/logic/providers/school_provider.dart` & `lib/logic/providers/sandbox_provider.dart`** *(Dimodifikasi)*
  - Mengekspos getter `isCloudConnected` dan `firebaseProjectId` dari `FirestoreService`.

### 3. Indikator Status Koneksi Cloud di UI
- **`lib/presentation/widgets/cloud_status_badge.dart`** *(Baru)*
  - Komponen chip/badge ringkas dan rapi yang menampilkan **"Cloud Terhubung"** (warna hijau, ikon `cloud_done_rounded`) saat aplikasi terhubung ke Cloud Firestore sungguhan, atau **"Mode Lokal"** (warna abu-abu, ikon `cloud_off_rounded`) saat berjalan pada mode fallback lokal, lengkap dengan `Tooltip` dan `Semantics`.
- **`lib/presentation/screens/home_screen.dart`** *(Dimodifikasi)*
  - Menampilkan `CloudStatusBadge` di sebelah badge status lokasi pada kartu lokasi aktif di bagian atas halaman **Beranda**.
- **`lib/presentation/screens/tracking_sandbox_screen.dart`** *(Dimodifikasi)*
  - Memperbarui banner edukatif **PPDB Sandbox** agar selalu menampilkan `CloudStatusBadge` (*Cloud Terhubung* hijau atau *Mode Lokal* abu-abu).

### 4. Pengujian & Verifikasi Build
- **`test/widget_test.dart`** *(Dimodifikasi)*
  - Menambahkan verifikasi `CloudStatusBadge` pada layar Beranda dan PPDB Sandbox serta pengujian khusus tampilan warna dan label **"Cloud Terhubung"** (hijau) dan **"Mode Lokal"** (abu-abu).
- Memverifikasi task Gradle `:app:processDebugGoogleServices` dan `:app:processDebugMainManifest` berhasil tanpa galat.

---

## Rincian Pekerjaan Tahap 6 (Hotfix UTS)

### 1. Perbaikan FAB Menimpa Tombol di PPDB Sandbox
- **`lib/presentation/screens/tracking_sandbox_screen.dart`** *(Dimodifikasi)*
  - Memperbarui padding bawah `ListView` daftar draf simulasi (`sandbox_draft_list_view`) menjadi `EdgeInsets.fromLTRB(16, 16, 16, 112 + MediaQuery.paddingOf(context).bottom)` agar saat di-scroll hingga paling bawah, tombol melayang **"+ Simulasi Baru"** tidak menimpa tombol **"Buka Portal Resmi PPDB"**.

### 2. Perbaikan Teks Tombol Terpotong (`...`)
- **`lib/presentation/widgets/sandbox_stepper_widget.dart`** *(Dimodifikasi)*
  - Mengubah label tombol saat tahap 4 selesai menjadi teks ringkas **"Ulangi"** dengan ikon refresh (`Icons.refresh_rounded`) serta merapikan padding horizontal tombol stepper (`12dp`) agar tidak terpotong di layar ponsel.
- **`lib/presentation/screens/compare_advisor_screen.dart`** *(Dimodifikasi)*
  - Mempersingkat tombol aksi simulasi pada kartu rekomendasi menjadi **`"Simulasi Jalur ${result.jalurTerbaik}"`** (misal `"Simulasi Jalur Zonasi"`) tanpa mengulang nama panjang sekolah sehingga seluruh label tombol terbaca utuh.

### 3. Pemangkasan Teks Duplikat di Smart Multi-Pathway Advisor
- **`lib/presentation/screens/compare_advisor_screen.dart`** *(Dimodifikasi)*
  - Memadatkan kotak ringkasan rekomendasi utama di bagian atas kartu advisor agar hanya menampilkan judul jalur terbaik, badge kategori & persentase peluang (`Tinggi • 94%`), serta 1 kalimat kesimpulan singkat yang tidak mengulang teks penjelasan pada kartu rincian 4 jalur di bawahnya.

### 4. Pengamanan Fitur "Chat WA Panitia" (Mode Pilot UTS)
- **`lib/data/services/external_launcher_service.dart`** *(Dimodifikasi)*
  - Menambahkan `buildSchoolCommitteeMessage`, `buildWhatsAppShareUri` (membentuk tautan aman `https://wa.me/?text=<pesan_terencode>` tanpa nomor acak), `openWhatsAppShare`, dan `openSchoolCommitteePilotWhatsApp`.
  - Mengamankan `contactSchoolCommittee` dengan mode default `usePilotSafeMode = true`.
- **`lib/presentation/screens/school_detail_screen.dart`** *(Dimodifikasi)*
  - Menampilkan dialog konfirmasi **"Mode Pilot UTS"** saat tombol **"Chat WA Panitia"** ditekan, menjelaskan bahwa kontak sekolah masih berupa data sampel, menampilkan pratinjau template pesan, serta menyediakan 2 tombol aksi: **"Salin Pesan"** (ke clipboard) dan **"Buka WhatsApp"** (`https://wa.me/?text=<pesan_terencode>` agar pengguna/dosen memilih kontak uji coba sendiri dengan aman).

### 5. Label Transparansi Data Pilot
- **`lib/presentation/screens/home_screen.dart` & `lib/presentation/screens/school_detail_screen.dart`** *(Dimodifikasi)*
  - Menambahkan caption singkat yang rapi bertuliskan **`"Data pilot sampel UTS • Verifikasi data riil pada tahap lanjutan"`** di bagian bawah daftar sekolah pada halaman Beranda serta di bagian bawah halaman Detail Profil Sekolah.

### 6. Pengujian Hotfix UTS
- **`test/widget_test.dart`** *(Dimodifikasi)*
  - Menambahkan pengujian terdedikasi untuk memastikan FAB Sandbox tidak menimpa tombol portal, tombol tahap 4 stepper menampilkan `"Ulangi"` + ikon refresh, ringkasan Smart Advisor padat tanpa duplikasi teks dengan tombol `"Simulasi Jalur ..."`, dialog Mode Pilot UTS WhatsApp & URI `https://wa.me/?text=...` tanpa nomor acak, serta kemunculan label transparansi data pilot.

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
| Tahap 1–6 | Diperbarui | `PROGRESS.md` | Dokumentasi ringkasan progres proyek Tahap 1–6 (termasuk Hotfix UTS) |
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
| Tahap 4 | Dimodifikasi | `lib/logic/providers/school_provider.dart` | Menambahkan helper `replaceComparedSchool` untuk mengganti slot sekolah komparasi |
| Tahap 4 | Baru | `lib/presentation/screens/compare_advisor_screen.dart` | Layar 3: Komparasi side-by-side maks. 2 sekolah & Smart Multi-Pathway Advisor interaktif |
| Tahap 4 | Baru | `lib/presentation/widgets/sandbox_stepper_widget.dart` | Widget progress stepper 4 tahap interaktif untuk status seleksi simulasi PPDB |
| Tahap 4 | Baru | `lib/presentation/screens/tracking_sandbox_screen.dart` | Layar 4: PPDB Sandbox CRUD penuh, banner edukatif, checklist berkas dinamis, & portal resmi |
| Tahap 4 | Dimodifikasi | `lib/presentation/screens/main_navigation_screen.dart` | Integrasi Tab 2 (`CompareAdvisorScreen`), Tab 3 (`TrackingSandboxScreen`), & alur lintas layar |
| Tahap 4 | Dimodifikasi | `lib/presentation/screens/school_detail_screen.dart` | Integrasi tombol "Simulasi Daftar di Sekolah Ini" membuka form Sandbox dengan sekolah pre-selected |
| Tahap 4 | Dimodifikasi | `test/widget_test.dart` | Widget test end-to-end Tahap 1–4 (Komparasi, Smart Advisor, Validasi NISN, CRUD Sandbox, Stepper) |
| Tahap 5 | Dimodifikasi | `android/settings.gradle.kts` | Menambahkan plugin `com.google.gms.google-services` versi `4.4.4` |
| Tahap 5 | Dimodifikasi | `android/app/build.gradle.kts` | Menerapkan plugin Google Services, verifikasi `applicationId`, & `minSdk = 24` |
| Tahap 5 | Dimodifikasi | `lib/main.dart` | Inisialisasi aman `Firebase.initializeApp()` dengan log `projectId` & pemicu seeding awal `schools` |
| Tahap 5 | Dimodifikasi | `lib/data/services/firestore_service.dart` | Getter `isCloudConnected`/`firebaseProjectId` & guard konkurensi seeding otomatis 10 sekolah |
| Tahap 5 | Dimodifikasi | `lib/logic/providers/school_provider.dart` | Mengekspos `isCloudConnected` dan `firebaseProjectId` ke UI Beranda |
| Tahap 5 | Dimodifikasi | `lib/logic/providers/sandbox_provider.dart` | Mengekspos `isCloudConnected` dan `firebaseProjectId` ke UI PPDB Sandbox |
| Tahap 5 | Baru | `lib/presentation/widgets/cloud_status_badge.dart` | Chip/badge status koneksi "Cloud Terhubung" (hijau) / "Mode Lokal" (abu-abu) |
| Tahap 5 | Dimodifikasi | `lib/presentation/screens/home_screen.dart` | Menampilkan `CloudStatusBadge` pada header lokasi aktif di Beranda |
| Tahap 5 | Dimodifikasi | `lib/presentation/screens/tracking_sandbox_screen.dart` | Menampilkan `CloudStatusBadge` pada banner edukatif PPDB Sandbox |
| Tahap 5 | Dimodifikasi | `test/widget_test.dart` | Verifikasi `CloudStatusBadge` untuk mode lokal dan mode cloud terhubung |
| Tahap 6 | Dimodifikasi | `lib/presentation/screens/tracking_sandbox_screen.dart` | Menambah clearance padding bawah `ListView` (`112 + safe area`) agar FAB tidak menimpa tombol portal |
| Tahap 6 | Dimodifikasi | `lib/presentation/widgets/sandbox_stepper_widget.dart` | Mengubah tombol selesai tahap 4 menjadi `"Ulangi"` dengan ikon `Icons.refresh_rounded` |
| Tahap 6 | Dimodifikasi | `lib/presentation/screens/compare_advisor_screen.dart` | Memadatkan kotak ringkasan rekomendasi (persentase + 1 kalimat unik) & tombol `"Simulasi Jalur <Jalur>"` |
| Tahap 6 | Dimodifikasi | `lib/data/services/external_launcher_service.dart` | Menambahkan tautan aman `https://wa.me/?text=<encoded>` tanpa nomor acak untuk Mode Pilot UTS |
| Tahap 6 | Dimodifikasi | `lib/presentation/screens/school_detail_screen.dart` | Dialog konfirmasi Mode Pilot UTS (Salin Pesan & Buka WhatsApp) + label transparansi data pilot |
| Tahap 6 | Dimodifikasi | `lib/presentation/screens/home_screen.dart` | Menambahkan label transparansi `"Data pilot sampel UTS • Verifikasi data riil pada tahap lanjutan"` |
| Tahap 6 | Dimodifikasi | `test/widget_test.dart` | Menambahkan verifikasi unit & widget untuk seluruh 5 perbaikan Hotfix UTS |

---

## Verifikasi

- Analisis statis dijalankan dengan `flutter analyze` untuk memastikan 0 error dan 0 warning pada seluruh file proyek.
- Pengujian otomatis dijalankan dengan `flutter test` untuk memverifikasi seluruh alur aplikasi dan 5 perbaikan Hotfix UTS lulus 100%.
