import 'dart:async';

import 'package:ayo_sekolah/core/constants/ppdb_constants.dart';
import 'package:geolocator/geolocator.dart';

/// Status hasil pengambilan lokasi GPS perangkat.
enum LocationStatus {
  /// Lokasi GPS perangkat berhasil didapatkan.
  success,

  /// Layanan GPS / lokasi perangkat dalam kondisi nonaktif.
  serviceDisabled,

  /// Izin akses lokasi ditolak sementara oleh pengguna.
  permissionDenied,

  /// Izin akses lokasi ditolak permanen oleh pengguna.
  permissionDeniedForever,

  /// Terjadi kendala teknis, timeout, atau platform tidak mendukung GPS.
  error,
}

/// Objek hasil pengambilan lokasi perangkat dari [LocationService].
class LocationResult {
  const LocationResult({
    required this.status,
    required this.pesan,
    this.koordinat,
  });

  final LocationStatus status;
  final String pesan;
  final KoordinatLokasi? koordinat;

  /// Bernilai `true` apabila koordinat GPS berhasil diperoleh.
  bool get isSuccess => status == LocationStatus.success && koordinat != null;

  /// Bernilai `true` apabila UI disarankan menggunakan koordinat fallback kecamatan.
  bool get requiresFallback => !isSuccess;

  /// Mengembalikan koordinat GPS jika tersedia, atau koordinat fallback
  /// untuk [kecamatanFallback] dari [PpdbConstants].
  KoordinatLokasi koordinatAtauFallback({
    String kecamatanFallback = PpdbConstants.defaultKecamatanFallback,
  }) {
    return koordinat ?? PpdbConstants.getKoordinatFallback(kecamatanFallback);
  }
}

/// Layanan pengambilan posisi GPS perangkat dengan penanganan permission aman
/// dan dukungan fallback kecamatan Bandar Lampung.
class LocationService {
  const LocationService();

  /// Mengambil koordinat GPS perangkat saat ini secara aman tanpa melempar error
  /// ke pemanggil. Apabila GPS nonaktif atau izin ditolak, mengembalikan
  /// [LocationResult] dengan status terkait agar UI dapat memakai koordinat
  /// fallback kecamatan dari [PpdbConstants].
  Future<LocationResult> getCurrentLocation({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(
          status: LocationStatus.serviceDisabled,
          pesan:
              'Layanan GPS perangkat sedang nonaktif. Gunakan titik kecamatan fallback atau aktifkan GPS.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const LocationResult(
            status: LocationStatus.permissionDenied,
            pesan:
                'Izin akses lokasi ditolak. Menggunakan titik kecamatan fallback untuk estimasi jarak.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(
          status: LocationStatus.permissionDeniedForever,
          pesan:
              'Izin lokasi ditolak permanen. Anda dapat memilih kecamatan fallback atau mengaktifkan izin di Pengaturan.',
        );
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );

      return LocationResult(
        status: LocationStatus.success,
        koordinat: KoordinatLokasi(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
        pesan: 'Lokasi GPS perangkat berhasil dideteksi.',
      );
    } on TimeoutException {
      return const LocationResult(
        status: LocationStatus.error,
        pesan:
            'Waktu deteksi sinyal GPS habis. Menggunakan koordinat kecamatan fallback.',
      );
    } on LocationServiceDisabledException {
      return const LocationResult(
        status: LocationStatus.serviceDisabled,
        pesan:
            'Layanan GPS tidak aktif. Menggunakan koordinat kecamatan fallback.',
      );
    } catch (_) {
      return const LocationResult(
        status: LocationStatus.error,
        pesan:
            'Gagal mengambil lokasi GPS perangkat. Menggunakan koordinat kecamatan fallback.',
      );
    }
  }

  /// Mengambil koordinat fallback kecamatan dari [PpdbConstants].
  KoordinatLokasi getFallbackLocation(String kecamatan) {
    return PpdbConstants.getKoordinatFallback(kecamatan);
  }

  /// Membuka pengaturan lokasi sistem perangkat secara aman.
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }

  /// Membuka halaman pengaturan izin aplikasi di sistem perangkat secara aman.
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }
}
