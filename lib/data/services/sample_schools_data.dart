import 'package:ayo_sekolah/core/constants/ppdb_constants.dart';
import 'package:ayo_sekolah/data/models/school_model.dart';

/// Data sampel 10 sekolah negeri realistis di Kota Bandar Lampung
/// mencakup jenjang SD, SMP, SMA, dan SMK untuk pilot aplikasi Ayo Sekolah.
class SampleSchoolsData {
  SampleSchoolsData._();

  /// URL portal resmi PPDB jenjang SMA/SMK Provinsi Lampung.
  static const String portalPpdbLampungSmaSmk =
      'https://lampung.siap-ppdb.com';

  /// URL portal resmi PPDB jenjang SD/SMP Kota Bandar Lampung.
  static const String portalPpdbBandarLampungSdSmp =
      'https://bandarlampung.siap-ppdb.com';

  /// Daftar 10 sekolah negeri sampel di Kota Bandar Lampung.
  static const List<SchoolModel> schools = <SchoolModel>[
    SchoolModel(
      idSchool: 'sch_sman2_bdl',
      namaSekolah: 'SMAN 2 Bandar Lampung',
      jenjang: 'SMA',
      status: 'Negeri',
      akreditasi: 'A',
      latitude: -5.4114,
      longitude: 105.2528,
      kontakWa: '6281272000102',
      kuota: <String, int>{
        PpdbConstants.jalurZonasi: 162,
        PpdbConstants.jalurPrestasi: 97,
        PpdbConstants.jalurAfirmasi: 49,
        PpdbConstants.jalurMutasi: 16,
      },
      passingGrade: 89.5,
      fasilitas: <String>[
        'Laboratorium IPA Terpadu',
        'Laboratorium Komputer & CBT',
        'Perpustakaan Digital',
        'Lapangan Basket & Futsal',
        'Masjid Sekolah',
        'Ruang UKS & Konseling',
      ],
      urlPortalPpdb: portalPpdbLampungSmaSmk,
      alamatPosko:
          'Ruang Posko PPDB SMAN 2, Jl. Amir Hamzah No. 01, Gotong Royong, Kec. Tanjung Karang Pusat, Kota Bandar Lampung',
    ),
    SchoolModel(
      idSchool: 'sch_sman9_bdl',
      namaSekolah: 'SMAN 9 Bandar Lampung',
      jenjang: 'SMA',
      status: 'Negeri',
      akreditasi: 'A',
      latitude: -5.4008,
      longitude: 105.2494,
      kontakWa: '6281272000109',
      kuota: <String, int>{
        PpdbConstants.jalurZonasi: 150,
        PpdbConstants.jalurPrestasi: 90,
        PpdbConstants.jalurAfirmasi: 45,
        PpdbConstants.jalurMutasi: 15,
      },
      passingGrade: 88.0,
      fasilitas: <String>[
        'Laboratorium Fisika, Kimia & Biologi',
        'Laboratorium Bahasa & Multimedia',
        'Perpustakaan Terakreditasi A',
        'Aula Serbaguna',
        'Lapangan Olahraga',
        'Kantin Sehat',
      ],
      urlPortalPpdb: portalPpdbLampungSmaSmk,
      alamatPosko:
          'Gedung Sekretariat PPDB SMAN 9, Jl. Panglima Polim No. 18, Segala Mider, Kec. Tanjung Karang Barat, Kota Bandar Lampung',
    ),
    SchoolModel(
      idSchool: 'sch_sman1_bdl',
      namaSekolah: 'SMAN 1 Bandar Lampung',
      jenjang: 'SMA',
      status: 'Negeri',
      akreditasi: 'A',
      latitude: -5.4216,
      longitude: 105.2654,
      kontakWa: '6281272000101',
      kuota: <String, int>{
        PpdbConstants.jalurZonasi: 144,
        PpdbConstants.jalurPrestasi: 86,
        PpdbConstants.jalurAfirmasi: 43,
        PpdbConstants.jalurMutasi: 15,
      },
      passingGrade: 86.5,
      fasilitas: <String>[
        'Laboratorium IPA & Komputer',
        'Perpustakaan & Ruang Baca',
        'Studio Musik & Seni',
        'Lapangan Upacara & Olahraga',
        'Mushola',
        'Wi-Fi Area Sekolah',
      ],
      urlPortalPpdb: portalPpdbLampungSmaSmk,
      alamatPosko:
          'Posko Verifikasi Berkas SMAN 1, Jl. Jenderal Sudirman No. 41, Rawa Laut, Kec. Enggal, Kota Bandar Lampung',
    ),
    SchoolModel(
      idSchool: 'sch_smpn1_bdl',
      namaSekolah: 'SMPN 1 Bandar Lampung',
      jenjang: 'SMP',
      status: 'Negeri',
      akreditasi: 'A',
      latitude: -5.4191,
      longitude: 105.2636,
      kontakWa: '6281272000201',
      kuota: <String, int>{
        PpdbConstants.jalurZonasi: 144,
        PpdbConstants.jalurPrestasi: 86,
        PpdbConstants.jalurAfirmasi: 43,
        PpdbConstants.jalurMutasi: 15,
      },
      passingGrade: 87.5,
      fasilitas: <String>[
        'Laboratorium IPA',
        'Laboratorium TIK & Komputer',
        'Perpustakaan Sekolah',
        'Ruang Kesenian & Ekstrakurikuler',
        'Lapangan Olahraga',
        'Ruang UKS',
      ],
      urlPortalPpdb: portalPpdbBandarLampungSdSmp,
      alamatPosko:
          'Posko Layanan PPDB SMPN 1, Jl. Mr. Gele Harun No. 32, Rawa Laut, Kec. Enggal, Kota Bandar Lampung',
    ),
    SchoolModel(
      idSchool: 'sch_smpn2_bdl',
      namaSekolah: 'SMPN 2 Bandar Lampung',
      jenjang: 'SMP',
      status: 'Negeri',
      akreditasi: 'A',
      latitude: -5.4143,
      longitude: 105.2535,
      kontakWa: '6281272000202',
      kuota: <String, int>{
        PpdbConstants.jalurZonasi: 160,
        PpdbConstants.jalurPrestasi: 96,
        PpdbConstants.jalurAfirmasi: 48,
        PpdbConstants.jalurMutasi: 16,
      },
      passingGrade: 88.5,
      fasilitas: <String>[
        'Laboratorium IPA & Bahasa',
        'Laboratorium Komputer',
        'Perpustakaan Digital',
        'Ruang Multimedia',
        'Masjid Sekolah',
        'Lapangan Basket & Voli',
      ],
      urlPortalPpdb: portalPpdbBandarLampungSdSmp,
      alamatPosko:
          'Loket Verifikasi PPDB SMPN 2, Jl. Khairil Anwar No. 79, Durian Payung, Kec. Tanjung Karang Pusat, Kota Bandar Lampung',
    ),
    SchoolModel(
      idSchool: 'sch_smpn22_bdl',
      namaSekolah: 'SMPN 22 Bandar Lampung',
      jenjang: 'SMP',
      status: 'Negeri',
      akreditasi: 'A',
      latitude: -5.3672,
      longitude: 105.2432,
      kontakWa: '6281272000222',
      kuota: <String, int>{
        PpdbConstants.jalurZonasi: 144,
        PpdbConstants.jalurPrestasi: 72,
        PpdbConstants.jalurAfirmasi: 42,
        PpdbConstants.jalurMutasi: 14,
      },
      passingGrade: 83.5,
      fasilitas: <String>[
        'Laboratorium IPA',
        'Laboratorium Komputer',
        'Perpustakaan & Pojok Literasi',
        'Lapangan Futsal & Basket',
        'Mushola',
        'Kantin Sekolah',
      ],
      urlPortalPpdb: portalPpdbBandarLampungSdSmp,
      alamatPosko:
          'Ruang Panitia PPDB SMPN 22, Jl. Zainal Abidin Pagar Alam No. 109, Gedong Meneng, Kec. Rajabasa, Kota Bandar Lampung',
    ),
    SchoolModel(
      idSchool: 'sch_smkn2_bdl',
      namaSekolah: 'SMKN 2 Bandar Lampung',
      jenjang: 'SMK',
      status: 'Negeri',
      akreditasi: 'A',
      latitude: -5.3646,
      longitude: 105.2464,
      kontakWa: '6281272000302',
      kuota: <String, int>{
        PpdbConstants.jalurZonasi: 60,
        PpdbConstants.jalurPrestasi: 390,
        PpdbConstants.jalurAfirmasi: 90,
        PpdbConstants.jalurMutasi: 30,
      },
      passingGrade: 84.0,
      fasilitas: <String>[
        'Bengkel Teknik Otomotif & Mesin',
        'Laboratorium TKJ & Rekayasa Perangkat Lunak',
        'Workshop Teknik Listrik & Elektronika',
        'Teaching Factory & Bursa Kerja Khusus',
        'Perpustakaan Teknis',
        'Masjid & Lapangan Olahraga',
      ],
      urlPortalPpdb: portalPpdbLampungSmaSmk,
      alamatPosko:
          'Gedung Utama Posko PPDB SMKN 2, Jl. Prof. Dr. Sumantri Brojonegoro No. 1, Gedong Meneng, Kec. Rajabasa, Kota Bandar Lampung',
    ),
    SchoolModel(
      idSchool: 'sch_smkn4_bdl',
      namaSekolah: 'SMKN 4 Bandar Lampung',
      jenjang: 'SMK',
      status: 'Negeri',
      akreditasi: 'A',
      latitude: -5.4241,
      longitude: 105.2630,
      kontakWa: '6281272000304',
      kuota: <String, int>{
        PpdbConstants.jalurZonasi: 55,
        PpdbConstants.jalurPrestasi: 360,
        PpdbConstants.jalurAfirmasi: 82,
        PpdbConstants.jalurMutasi: 28,
      },
      passingGrade: 85.0,
      fasilitas: <String>[
        'Laboratorium Akuntansi & Perbankan Mini',
        'Laboratorium Komputer & DKV',
        'Studio Praktik Perhotelan & Pariwisata',
        'Ruang Simulasi Perkantoran',
        'Perpustakaan & Auditorium',
        'Bursa Kerja Khusus (BKK)',
      ],
      urlPortalPpdb: portalPpdbLampungSmaSmk,
      alamatPosko:
          'Posko Verifikasi PPDB SMKN 4, Jl. Hos Cokroaminoto No. 102, Enggal, Kec. Enggal, Kota Bandar Lampung',
    ),
    SchoolModel(
      idSchool: 'sch_sdn2_rawalaut',
      namaSekolah: 'SDN 2 Rawa Laut',
      jenjang: 'SD',
      status: 'Negeri',
      akreditasi: 'A',
      latitude: -5.4202,
      longitude: 105.2662,
      kontakWa: '6281272000402',
      kuota: <String, int>{
        PpdbConstants.jalurZonasi: 84,
        PpdbConstants.jalurPrestasi: 0,
        PpdbConstants.jalurAfirmasi: 18,
        PpdbConstants.jalurMutasi: 6,
      },
      passingGrade: 0.0,
      fasilitas: <String>[
        'Ruang Kelas Ramah Anak',
        'Perpustakaan & Taman Baca',
        'Ruang Komputer Dasar',
        'Ruang UKS',
        'Halaman Bermain & Olahraga',
        'Mushola',
      ],
      urlPortalPpdb: portalPpdbBandarLampungSdSmp,
      alamatPosko:
          'Ruang Guru & Posko PPDB SDN 2 Rawa Laut, Jl. Cendana No. 23, Rawa Laut, Kec. Enggal, Kota Bandar Lampung',
    ),
    SchoolModel(
      idSchool: 'sch_sdn1_sukarame',
      namaSekolah: 'SDN 1 Sukarame',
      jenjang: 'SD',
      status: 'Negeri',
      akreditasi: 'A',
      latitude: -5.3782,
      longitude: 105.2838,
      kontakWa: '6281272000401',
      kuota: <String, int>{
        PpdbConstants.jalurZonasi: 78,
        PpdbConstants.jalurPrestasi: 0,
        PpdbConstants.jalurAfirmasi: 17,
        PpdbConstants.jalurMutasi: 5,
      },
      passingGrade: 0.0,
      fasilitas: <String>[
        'Ruang Kelas Nyaman',
        'Perpustakaan Anak',
        'Ruang UKS & Kantin Sehat',
        'Lapangan Upacara & Bermain',
        'Mushola',
        'Area Parkir Antar-Jemput',
      ],
      urlPortalPpdb: portalPpdbBandarLampungSdSmp,
      alamatPosko:
          'Sekretariat PPDB SDN 1 Sukarame, Jl. Pulau Sebesi No. 14, Sukarame, Kec. Sukarame, Kota Bandar Lampung',
    ),
  ];
}
