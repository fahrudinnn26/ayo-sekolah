import 'dart:math' as math;

import 'package:ayo_sekolah/core/constants/ppdb_constants.dart';

/// Utilitas perhitungan jarak geografis menggunakan rumus Haversine
/// serta evaluasi kategori status zonasi PPDB.
class HaversineCalculator {
  HaversineCalculator._();

  /// Jari-jari rata-rata bumi dalam satuan meter.
  static const double earthRadiusMeters = 6371000.0;

  /// Menghitung jarak garis lurus akurat (dalam meter) antara dua koordinat GPS
  /// menggunakan rumus Haversine.
  static double hitungJarakMeter({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    final double dLat = _derajatKeRadian(endLat - startLat);
    final double dLng = _derajatKeRadian(endLng - startLng);

    final double lat1Rad = _derajatKeRadian(startLat);
    final double lat2Rad = _derajatKeRadian(endLat);

    final double sinHalfLat = math.sin(dLat / 2.0);
    final double sinHalfLng = math.sin(dLng / 2.0);

    final double a = (sinHalfLat * sinHalfLat) +
        (math.cos(lat1Rad) * math.cos(lat2Rad) * sinHalfLng * sinHalfLng);
    final double clampedA = a.clamp(0.0, 1.0);
    final double c =
        2.0 * math.atan2(math.sqrt(clampedA), math.sqrt(1.0 - clampedA));

    return earthRadiusMeters * c;
  }

  /// Menghitung jarak (dalam meter) antara dua objek [KoordinatLokasi].
  static double hitungJarakAntarKoordinatMeter(
    KoordinatLokasi asal,
    KoordinatLokasi tujuan,
  ) {
    return hitungJarakMeter(
      startLat: asal.latitude,
      startLng: asal.longitude,
      endLat: tujuan.latitude,
      endLng: tujuan.longitude,
    );
  }

  /// Menghitung jarak akurat (dalam kilometer) antara dua koordinat GPS
  /// menggunakan rumus Haversine.
  static double hitungJarakKilometer({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return meterKeKilometer(
      hitungJarakMeter(
        startLat: startLat,
        startLng: startLng,
        endLat: endLat,
        endLng: endLng,
      ),
    );
  }

  /// Menghitung jarak (dalam kilometer) antara dua objek [KoordinatLokasi].
  static double hitungJarakAntarKoordinatKilometer(
    KoordinatLokasi asal,
    KoordinatLokasi tujuan,
  ) {
    return meterKeKilometer(hitungJarakAntarKoordinatMeter(asal, tujuan));
  }

  /// Mengonversi nilai jarak dari satuan meter ke kilometer.
  static double meterKeKilometer(double jarakMeter) {
    return jarakMeter / 1000.0;
  }

  /// Menentukan kategori [StatusZonasi] berdasarkan konstanta di [PpdbConstants]:
  /// - `<= 800` meter -> [StatusZonasi.sangatAman] ("Sangat Aman")
  /// - `801–1500` meter -> [StatusZonasi.waspada] ("Waspada")
  /// - `> 1500` meter -> [StatusZonasi.berisiko] ("Berisiko")
  static StatusZonasi tentukanStatusZonasi(double jarakMeter) {
    return PpdbConstants.evaluasiStatusZonasi(jarakMeter);
  }

  /// Mengembalikan label status zonasi dalam Bahasa Indonesia untuk [jarakMeter].
  static String tentukanLabelZonasi(double jarakMeter) {
    return PpdbConstants.getLabelZonasi(jarakMeter);
  }

  /// Memformat jarak ke teks yang mudah dibaca (meter untuk `< 1000 m`,
  /// kilometer untuk `>= 1000 m`).
  static String formatJarak(double jarakMeter) {
    final double sanitized = jarakMeter < 0 ? 0.0 : jarakMeter;
    if (sanitized < 1000.0) {
      return '${sanitized.round()} m';
    }
    final String kmText =
        meterKeKilometer(sanitized).toStringAsFixed(2).replaceAll('.', ',');
    return '$kmText km';
  }

  static double _derajatKeRadian(double derajat) {
    return derajat * (math.pi / 180.0);
  }
}
