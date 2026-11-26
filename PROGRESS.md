# Progres Pengembangan — Ayo Sekolah

Aplikasi Flutter **Ayo Sekolah** (Direktori Sekolah, Rekomendasi Jalur, dan Simulasi PPDB Sandbox) untuk pilot wilayah **Kota Bandar Lampung**.

---

## Ringkasan Progres

- [x] **Tahap 1: Konfigurasi Android, Konstanta, & Model Data** (Selesai)
- [ ] **Tahap 2:** Layanan (Lokasi/GPS + Fallback, Firestore Repository, Peluncur URL/WhatsApp) & State Management (`provider`)
- [ ] **Tahap 3:** Integrasi Firebase & UI Halaman (Direktori, Rekomendasi Jalur, Simulasi PPDB Sandbox)

> **Catatan Batasan Tahap 1:** `lib/main.dart` dan halaman UI belum diubah/dibuat pada tahap ini.

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

## Daftar File Baru & Termodifikasi

| Status | Path File | Deskripsi |
| --- | --- | --- |
| Dimodifikasi | `android/app/build.gradle.kts` | Pengaturan `minSdk = 21` |
| Dimodifikasi | `android/app/src/main/AndroidManifest.xml` | Izin lokasi/internet dan `<queries>` HTTPS & WhatsApp |
| Baru | `lib/core/constants/app_theme.dart` | Tema Material Design 3 biru-hijau edukatif & touch target >= 48dp |
| Baru | `lib/core/constants/ppdb_constants.dart` | Aturan jarak zonasi, jalur PPDB, status seleksi, & koordinat fallback Bandar Lampung |
| Baru | `lib/data/models/school_model.dart` | Model data sekolah + serialisasi Firestore |
| Baru | `lib/data/models/registration_draft_model.dart` | Model data draf pendaftaran simulasi + serialisasi Firestore |
| Baru | `PROGRESS.md` | Dokumentasi ringkasan progres proyek |

---

## Verifikasi

- Analisis statis dijalankan dengan `flutter analyze` untuk memastikan tidak ada error atau peringatan pada seluruh file baru.
