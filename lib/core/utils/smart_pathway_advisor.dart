import 'dart:math' as math;

import 'package:ayo_sekolah/core/constants/ppdb_constants.dart';
import 'package:ayo_sekolah/core/utils/haversine_calculator.dart';
import 'package:ayo_sekolah/data/models/school_model.dart';

/// Kategori tingkat peluang diterima pada suatu jalur PPDB.
enum TingkatPeluang {
  tinggi('Tinggi'),
  sedang('Sedang'),
  rendah('Rendah');

  const TingkatPeluang(this.label);

  final String label;

  /// Mengonversi nilai skor (0–100) menjadi kategori [TingkatPeluang].
  static TingkatPeluang fromSkor(double skor) {
    if (skor >= 75.0) return TingkatPeluang.tinggi;
    if (skor >= 45.0) return TingkatPeluang.sedang;
    return TingkatPeluang.rendah;
  }
}

/// Hasil evaluasi peluang untuk satu jalur PPDB tertentu pada sebuah sekolah.
class EvaluasiJalur {
  const EvaluasiJalur({
    required this.jalur,
    required this.skor,
    required this.tingkatPeluang,
    required this.memenuhiSyarat,
    required this.kuotaJalur,
    required this.alasan,
  });

  /// Nama jalur PPDB (Zonasi, Prestasi, Afirmasi, atau Mutasi).
  final String jalur;

  /// Skor estimasi peluang dalam rentang 0.0 hingga 100.0.
  final double skor;

  /// Kategori peluang (Tinggi, Sedang, atau Rendah).
  final TingkatPeluang tingkatPeluang;

  /// Menandakan apakah siswa memenuhi syarat administratif dan kuota tersedia.
  final bool memenuhiSyarat;

  /// Jumlah kuota daya tampung pada jalur ini di sekolah tujuan.
  final int kuotaJalur;

  /// Penjelasan singkat hasil evaluasi dalam Bahasa Indonesia.
  final String alasan;

  @override
  String toString() {
    return 'EvaluasiJalur(jalur: $jalur, skor: ${skor.toStringAsFixed(1)}, '
        'tingkatPeluang: ${tingkatPeluang.label}, memenuhiSyarat: $memenuhiSyarat)';
  }
}

/// Hasil rekomendasi keseluruhan dari [SmartPathwayAdvisor] untuk satu sekolah.
class RekomendasiJalurResult {
  const RekomendasiJalurResult({
    required this.jalurTerbaik,
    required this.skorTerbaik,
    required this.tingkatPeluang,
    required this.alasan,
    required this.rincianJalur,
    required this.jarakMeter,
    required this.statusZonasi,
  });

  /// Jalur PPDB terbaik yang direkomendasikan.
  final String jalurTerbaik;

  /// Skor peluang tertinggi (0.0–100.0) milik [jalurTerbaik].
  final double skorTerbaik;

  /// Kategori peluang [jalurTerbaik] (Tinggi, Sedang, atau Rendah).
  final TingkatPeluang tingkatPeluang;

  /// Penjelasan alasan singkat dalam Bahasa Indonesia.
  final String alasan;

  /// Rincian evaluasi keempat jalur PPDB terurut dari peluang tertinggi.
  final List<EvaluasiJalur> rincianJalur;

  /// Jarak domisili ke sekolah dalam satuan meter.
  final double jarakMeter;

  /// Status zonasi berdasarkan jarak domisili ke sekolah.
  final StatusZonasi statusZonasi;

  /// Mengambil rincian evaluasi untuk [namaJalur] tertentu bila tersedia.
  EvaluasiJalur? getEvaluasi(String namaJalur) {
    for (final EvaluasiJalur item in rincianJalur) {
      if (item.jalur == namaJalur) return item;
    }
    return null;
  }

  @override
  String toString() {
    return 'RekomendasiJalurResult(jalurTerbaik: $jalurTerbaik, '
        'skorTerbaik: ${skorTerbaik.toStringAsFixed(1)}, '
        'tingkatPeluang: ${tingkatPeluang.label})';
  }
}

/// Algoritma evaluasi dan rekomendasi 4 jalur PPDB (Zonasi, Prestasi, Afirmasi,
/// dan Mutasi) untuk sebuah [SchoolModel].
class SmartPathwayAdvisor {
  SmartPathwayAdvisor._();

  /// Mengevaluasi peluang 4 jalur PPDB untuk [sekolah] berdasarkan:
  /// - [jarakMeter]: jarak domisili calon siswa ke sekolah dalam meter.
  /// - [rataRataRapor]: rata-rata nilai rapor calon siswa (skala 0–100).
  /// - [memilikiDokumenAfirmasi]: kepemilikan dokumen KIP/PKH/DTKS resmi.
  /// - [memilikiSuratMutasi]: kepemilikan surat perpindahan tugas orang tua.
  static RekomendasiJalurResult evaluasi({
    required SchoolModel sekolah,
    required double jarakMeter,
    required double rataRataRapor,
    required bool memilikiDokumenAfirmasi,
    required bool memilikiSuratMutasi,
  }) {
    final double safeJarak = jarakMeter < 0 ? 0.0 : jarakMeter;
    final double safeRapor = rataRataRapor.clamp(0.0, 100.0);
    final StatusZonasi statusZonasi =
        HaversineCalculator.tentukanStatusZonasi(safeJarak);

    final List<EvaluasiJalur> evaluasiSemuaJalur = <EvaluasiJalur>[
      _evaluasiZonasi(
        sekolah: sekolah,
        jarakMeter: safeJarak,
        statusZonasi: statusZonasi,
      ),
      _evaluasiPrestasi(
        sekolah: sekolah,
        rataRataRapor: safeRapor,
      ),
      _evaluasiAfirmasi(
        sekolah: sekolah,
        jarakMeter: safeJarak,
        memilikiDokumenAfirmasi: memilikiDokumenAfirmasi,
      ),
      _evaluasiMutasi(
        sekolah: sekolah,
        jarakMeter: safeJarak,
        memilikiSuratMutasi: memilikiSuratMutasi,
      ),
    ];

    evaluasiSemuaJalur.sort((EvaluasiJalur a, EvaluasiJalur b) {
      if (a.memenuhiSyarat != b.memenuhiSyarat) {
        return a.memenuhiSyarat ? -1 : 1;
      }
      final int compareSkor = b.skor.compareTo(a.skor);
      if (compareSkor != 0) return compareSkor;
      return b.kuotaJalur.compareTo(a.kuotaJalur);
    });

    final EvaluasiJalur terbaik = evaluasiSemuaJalur.first;

    return RekomendasiJalurResult(
      jalurTerbaik: terbaik.jalur,
      skorTerbaik: terbaik.skor,
      tingkatPeluang: terbaik.tingkatPeluang,
      alasan: _bangunAlasanUtama(
        sekolah: sekolah,
        terbaik: terbaik,
      ),
      rincianJalur: List<EvaluasiJalur>.unmodifiable(evaluasiSemuaJalur),
      jarakMeter: safeJarak,
      statusZonasi: statusZonasi,
    );
  }

  static EvaluasiJalur _evaluasiZonasi({
    required SchoolModel sekolah,
    required double jarakMeter,
    required StatusZonasi statusZonasi,
  }) {
    final int kuota = sekolah.kuota[PpdbConstants.jalurZonasi] ?? 0;
    final String jarakText = HaversineCalculator.formatJarak(jarakMeter);

    if (kuota <= 0) {
      return EvaluasiJalur(
        jalur: PpdbConstants.jalurZonasi,
        skor: 0.0,
        tingkatPeluang: TingkatPeluang.rendah,
        memenuhiSyarat: false,
        kuotaJalur: 0,
        alasan: '${sekolah.namaSekolah} tidak membuka kuota jalur Zonasi.',
      );
    }

    final double rasioKuota =
        sekolah.totalKuota > 0 ? kuota / sekolah.totalKuota : 0.0;
    final double bonusKuota = rasioKuota >= 0.45 ? 2.0 : 0.0;

    double skor;
    String alasan;

    switch (statusZonasi) {
      case StatusZonasi.sangatAman:
        final double rasioDalamZona =
            jarakMeter / PpdbConstants.batasJarakSangatAmanMeter;
        skor = (98.0 - (rasioDalamZona * 13.0) + bonusKuota).clamp(80.0, 100.0);
        alasan = 'Jarak rumah ($jarakText) masuk kategori Sangat Aman '
            '(<= 800 m) dengan daya tampung Zonasi $kuota kursi.';
      case StatusZonasi.waspada:
        final double rentangWaspada = PpdbConstants.batasJarakWaspadaMeter -
            PpdbConstants.batasJarakSangatAmanMeter;
        final double progres =
            (jarakMeter - PpdbConstants.batasJarakSangatAmanMeter) /
                rentangWaspada;
        skor = (72.0 - (progres * 22.0) + bonusKuota).clamp(48.0, 74.0);
        alasan = 'Jarak rumah ($jarakText) berada di zona Waspada (801–1500 m); '
            'peluang masih terbuka dengan kuota Zonasi $kuota kursi.';
      case StatusZonasi.berisiko:
        final double kelebihanMeter =
            jarakMeter - PpdbConstants.batasJarakWaspadaMeter;
        skor = math.max(10.0, 40.0 - (kelebihanMeter / 2000.0) * 30.0);
        alasan = 'Jarak rumah ($jarakText) melebihi 1500 m (kategori Berisiko), '
            'sehingga persaingan jalur Zonasi sangat ketat.';
    }

    return EvaluasiJalur(
      jalur: PpdbConstants.jalurZonasi,
      skor: skor,
      tingkatPeluang: TingkatPeluang.fromSkor(skor),
      memenuhiSyarat: true,
      kuotaJalur: kuota,
      alasan: alasan,
    );
  }

  static EvaluasiJalur _evaluasiPrestasi({
    required SchoolModel sekolah,
    required double rataRataRapor,
  }) {
    final int kuota = sekolah.kuota[PpdbConstants.jalurPrestasi] ?? 0;

    if (kuota <= 0) {
      return EvaluasiJalur(
        jalur: PpdbConstants.jalurPrestasi,
        skor: 0.0,
        tingkatPeluang: TingkatPeluang.rendah,
        memenuhiSyarat: false,
        kuotaJalur: 0,
        alasan:
            'Jenjang ${sekolah.jenjang} di ${sekolah.namaSekolah} tidak membuka jalur Prestasi.',
      );
    }

    final double acuanPassingGrade =
        sekolah.passingGrade > 0 ? sekolah.passingGrade : 75.0;
    final double selisih = rataRataRapor - acuanPassingGrade;
    final String raporText = rataRataRapor.toStringAsFixed(1);
    final String passingText = acuanPassingGrade.toStringAsFixed(1);

    double skor;
    String alasan;

    if (selisih >= 3.0) {
      skor = (88.0 + math.min(selisih - 3.0, 10.0)).clamp(88.0, 98.0);
      alasan = 'Rata-rata rapor ($raporText) melampaui passing grade sekolah '
          '($passingText) sebesar +${selisih.toStringAsFixed(1)} poin '
          'dengan kuota Prestasi $kuota kursi.';
    } else if (selisih >= 0.0) {
      skor = (76.0 + (selisih / 3.0) * 11.0).clamp(76.0, 87.0);
      alasan = 'Rata-rata rapor ($raporText) memenuhi passing grade sekolah '
          '($passingText) dengan kuota Prestasi $kuota kursi.';
    } else if (selisih >= -3.0) {
      skor = (71.0 + (selisih / 3.0) * 23.0).clamp(48.0, 71.0);
      alasan = 'Rata-rata rapor ($raporText) sedikit di bawah passing grade '
          '($passingText); peluang tetap ada namun perlu waspada persaingan.';
    } else {
      skor = math.max(12.0, 42.0 + (selisih + 3.0) * 4.0);
      alasan = 'Rata-rata rapor ($raporText) masih terpaut di bawah passing '
          'grade sekolah ($passingText).';
    }

    return EvaluasiJalur(
      jalur: PpdbConstants.jalurPrestasi,
      skor: skor,
      tingkatPeluang: TingkatPeluang.fromSkor(skor),
      memenuhiSyarat: true,
      kuotaJalur: kuota,
      alasan: alasan,
    );
  }

  static EvaluasiJalur _evaluasiAfirmasi({
    required SchoolModel sekolah,
    required double jarakMeter,
    required bool memilikiDokumenAfirmasi,
  }) {
    final int kuota = sekolah.kuota[PpdbConstants.jalurAfirmasi] ?? 0;

    if (kuota <= 0) {
      return EvaluasiJalur(
        jalur: PpdbConstants.jalurAfirmasi,
        skor: 0.0,
        tingkatPeluang: TingkatPeluang.rendah,
        memenuhiSyarat: false,
        kuotaJalur: 0,
        alasan: '${sekolah.namaSekolah} tidak membuka kuota jalur Afirmasi.',
      );
    }

    if (!memilikiDokumenAfirmasi) {
      return EvaluasiJalur(
        jalur: PpdbConstants.jalurAfirmasi,
        skor: 0.0,
        tingkatPeluang: TingkatPeluang.rendah,
        memenuhiSyarat: false,
        kuotaJalur: kuota,
        alasan:
            'Memerlukan kepemilikan dokumen bantuan resmi (KIP/PKH/DTKS) yang aktif.',
      );
    }

    final String jarakText = HaversineCalculator.formatJarak(jarakMeter);
    double skor;
    if (jarakMeter <= PpdbConstants.batasJarakSangatAmanMeter) {
      skor = 92.0;
    } else if (jarakMeter <= PpdbConstants.batasJarakWaspadaMeter) {
      skor = 85.0;
    } else if (jarakMeter <= 3000.0) {
      skor = 78.0;
    } else {
      skor = 68.0;
    }

    if (kuota < 15) {
      skor = math.max(55.0, skor - 4.0);
    }

    final String alasan =
        'Memiliki dokumen Afirmasi (KIP/PKH/DTKS) dengan kuota khusus $kuota '
        'kursi dan jarak domisili $jarakText.';

    return EvaluasiJalur(
      jalur: PpdbConstants.jalurAfirmasi,
      skor: skor,
      tingkatPeluang: TingkatPeluang.fromSkor(skor),
      memenuhiSyarat: true,
      kuotaJalur: kuota,
      alasan: alasan,
    );
  }

  static EvaluasiJalur _evaluasiMutasi({
    required SchoolModel sekolah,
    required double jarakMeter,
    required bool memilikiSuratMutasi,
  }) {
    final int kuota = sekolah.kuota[PpdbConstants.jalurMutasi] ?? 0;

    if (kuota <= 0) {
      return EvaluasiJalur(
        jalur: PpdbConstants.jalurMutasi,
        skor: 0.0,
        tingkatPeluang: TingkatPeluang.rendah,
        memenuhiSyarat: false,
        kuotaJalur: 0,
        alasan: '${sekolah.namaSekolah} tidak membuka kuota jalur Mutasi.',
      );
    }

    if (!memilikiSuratMutasi) {
      return EvaluasiJalur(
        jalur: PpdbConstants.jalurMutasi,
        skor: 0.0,
        tingkatPeluang: TingkatPeluang.rendah,
        memenuhiSyarat: false,
        kuotaJalur: kuota,
        alasan:
            'Memerlukan surat penugasan atau perpindahan tugas resmi orang tua/wali.',
      );
    }

    final String jarakText = HaversineCalculator.formatJarak(jarakMeter);
    double skor;
    if (jarakMeter <= PpdbConstants.batasJarakWaspadaMeter && kuota >= 10) {
      skor = 82.0;
    } else if (jarakMeter <= 3000.0) {
      skor = kuota >= 15 ? 76.0 : 72.0;
    } else {
      skor = 60.0;
    }

    final String alasan =
        'Memiliki surat perpindahan tugas orang tua dengan kuota Mutasi $kuota '
        'kursi dan jarak domisili $jarakText.';

    return EvaluasiJalur(
      jalur: PpdbConstants.jalurMutasi,
      skor: skor,
      tingkatPeluang: TingkatPeluang.fromSkor(skor),
      memenuhiSyarat: true,
      kuotaJalur: kuota,
      alasan: alasan,
    );
  }

  static String _bangunAlasanUtama({
    required SchoolModel sekolah,
    required EvaluasiJalur terbaik,
  }) {
    if (!terbaik.memenuhiSyarat) {
      return 'Belum ditemukan jalur dengan syarat yang terpenuhi di '
          '${sekolah.namaSekolah}. Periksa kelengkapan dokumen atau '
          'pertimbangkan sekolah lain yang lebih dekat.';
    }

    return 'Jalur ${terbaik.jalur} paling direkomendasikan dengan peluang '
        '${terbaik.tingkatPeluang.label}. ${terbaik.alasan}';
  }
}
