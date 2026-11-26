/// Representasi titik koordinat geografis (lintang dan bujur).
class KoordinatLokasi {
  const KoordinatLokasi({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KoordinatLokasi &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() =>
      'KoordinatLokasi(latitude: $latitude, longitude: $longitude)';
}

/// Kategori status peluang berdasarkan jarak zonasi ke sekolah tujuan.
enum StatusZonasi {
  sangatAman(PpdbConstants.labelZonasiSangatAman),
  waspada(PpdbConstants.labelZonasiWaspada),
  berisiko(PpdbConstants.labelZonasiBerisiko);

  const StatusZonasi(this.label);

  final String label;
}

/// Konstanta aturan PPDB, jalur pendaftaran, dan koordinat fallback
/// untuk pilot wilayah Kota Bandar Lampung.
class PpdbConstants {
  PpdbConstants._();

  /// Wilayah pilot aplikasi Ayo Sekolah.
  static const String wilayahPilot = 'Kota Bandar Lampung';

  // Aturan Batas Jarak Zonasi (dalam meter)
  /// Batas maksimal kategori "Sangat Aman" (<= 800 meter).
  static const double batasJarakSangatAmanMeter = 800.0;

  /// Batas bawah referensi kategori "Waspada" (801–1500 meter).
  static const double batasBawahWaspadaMeter = 801.0;

  /// Batas maksimal kategori "Waspada" (<= 1500 meter); > 1500 meter "Berisiko".
  static const double batasJarakWaspadaMeter = 1500.0;

  static const String labelZonasiSangatAman = 'Sangat Aman';
  static const String labelZonasiWaspada = 'Waspada';
  static const String labelZonasiBerisiko = 'Berisiko';

  // Daftar Jalur PPDB
  static const String jalurZonasi = 'Zonasi';
  static const String jalurPrestasi = 'Prestasi';
  static const String jalurAfirmasi = 'Afirmasi';
  static const String jalurMutasi = 'Mutasi';

  static const List<String> daftarJalurPpdb = <String>[
    jalurZonasi,
    jalurPrestasi,
    jalurAfirmasi,
    jalurMutasi,
  ];

  // Referensi Jenjang & Status Sekolah
  static const List<String> daftarJenjangSekolah = <String>[
    'SD',
    'SMP',
    'SMA',
    'SMK',
  ];

  static const List<String> daftarStatusSekolah = <String>[
    'Negeri',
    'Swasta',
  ];

  // Tahapan Status Seleksi Simulasi (1–4)
  static const int statusDrafTersimpan = 1;
  static const int statusKelengkapanBerkas = 2;
  static const int statusSiapVerifikasi = 3;
  static const int statusTerkirimSimulasi = 4;

  static const Map<int, String> labelStatusSeleksi = <int, String>{
    statusDrafTersimpan: 'Draf Tersimpan',
    statusKelengkapanBerkas: 'Kelengkapan Berkas',
    statusSiapVerifikasi: 'Siap Verifikasi',
    statusTerkirimSimulasi: 'Terkirim Simulasi',
  };

  /// Nama kecamatan default saat GPS perangkat tidak tersedia atau ditolak.
  static const String defaultKecamatanFallback = 'Tanjung Karang Pusat';

  /// Peta koordinat fallback (latitude, longitude) untuk kecamatan-kecamatan
  /// utama di Kota Bandar Lampung ketika GPS mati atau izin lokasi ditolak.
  static const Map<String, KoordinatLokasi> koordinatFallbackKecamatan =
      <String, KoordinatLokasi>{
    'Kedaton': KoordinatLokasi(
      latitude: -5.3900,
      longitude: 105.2597,
    ),
    'Rajabasa': KoordinatLokasi(
      latitude: -5.3609,
      longitude: 105.2343,
    ),
    'Tanjung Karang Pusat': KoordinatLokasi(
      latitude: -5.4150,
      longitude: 105.2570,
    ),
    'Sukarame': KoordinatLokasi(
      latitude: -5.3760,
      longitude: 105.2852,
    ),
    'Kemiling': KoordinatLokasi(
      latitude: -5.4080,
      longitude: 105.2210,
    ),
    'Way Halim': KoordinatLokasi(
      latitude: -5.3878,
      longitude: 105.2765,
    ),
    'Teluk Betung Selatan': KoordinatLokasi(
      latitude: -5.4410,
      longitude: 105.2600,
    ),
  };

  /// Mengevaluasi status zonasi berdasarkan [jarakMeter]:
  /// - `<= 800` meter -> [StatusZonasi.sangatAman] ("Sangat Aman")
  /// - `> 800` hingga `<= 1500` meter (801–1500 m) -> [StatusZonasi.waspada] ("Waspada")
  /// - `> 1500` meter -> [StatusZonasi.berisiko] ("Berisiko")
  static StatusZonasi evaluasiStatusZonasi(double jarakMeter) {
    if (jarakMeter <= batasJarakSangatAmanMeter) {
      return StatusZonasi.sangatAman;
    }
    if (jarakMeter <= batasJarakWaspadaMeter) {
      return StatusZonasi.waspada;
    }
    return StatusZonasi.berisiko;
  }

  /// Mengembalikan label status zonasi untuk [jarakMeter] tertentu.
  static String getLabelZonasi(double jarakMeter) {
    return evaluasiStatusZonasi(jarakMeter).label;
  }

  /// Mengembalikan label teks untuk [statusSeleksi] (1–4).
  static String getLabelStatusSeleksi(int statusSeleksi) {
    return labelStatusSeleksi[statusSeleksi] ?? 'Tidak Diketahui';
  }

  /// Mengembalikan koordinat fallback berdasarkan nama [kecamatan].
  /// Jika [kecamatan] tidak ditemukan, mengembalikan koordinat
  /// [defaultKecamatanFallback].
  static KoordinatLokasi getKoordinatFallback(String kecamatan) {
    return koordinatFallbackKecamatan[kecamatan] ??
        koordinatFallbackKecamatan[defaultKecamatanFallback]!;
  }
}
