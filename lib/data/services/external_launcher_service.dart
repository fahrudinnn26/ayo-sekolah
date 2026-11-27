import 'package:ayo_sekolah/data/models/school_model.dart';
import 'package:url_launcher/url_launcher.dart';

/// Hasil eksekusi peluncuran tautan eksternal (browser / WhatsApp).
class ExternalLaunchResult {
  const ExternalLaunchResult({
    required this.success,
    required this.message,
    this.uri,
  });

  final bool success;
  final String message;
  final Uri? uri;
}

/// Layanan peluncur tautan eksternal menggunakan `url_launcher` untuk
/// membuka portal resmi PPDB di browser dan menghubungi panitia via WhatsApp.
class ExternalLauncherService {
  const ExternalLauncherService();

  /// Menormalisasi nomor telepon Indonesia menjadi format internasional `628...`
  /// yang valid untuk tautan `https://wa.me/`.
  String normalizeWhatsAppNumber(String rawNumber) {
    final String digitsOnly = rawNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return '';

    if (digitsOnly.startsWith('0')) {
      return '62${digitsOnly.substring(1)}';
    }
    if (digitsOnly.startsWith('8')) {
      return '62$digitsOnly';
    }
    return digitsOnly;
  }

  /// Menyusun template pesan WhatsApp otomatis dalam Bahasa Indonesia
  /// untuk menanyakan jadwal, syarat berkas, dan alur verifikasi PPDB.
  String buildWhatsAppMessage({
    required String namaSekolah,
    String? jenjang,
    String? jalurPilihan,
  }) {
    final String namaBersih = namaSekolah.trim().isEmpty
        ? 'sekolah tujuan'
        : namaSekolah.trim();
    final StringBuffer buffer = StringBuffer()
      ..write('Halo Panitia PPDB $namaBersih');

    if (jenjang != null && jenjang.trim().isNotEmpty) {
      buffer.write(' (${jenjang.trim()})');
    }

    buffer.write(', saya ingin menanyakan informasi jadwal pendaftaran, '
        'persyaratan berkas, dan prosedur verifikasi PPDB');

    if (jalurPilihan != null && jalurPilihan.trim().isNotEmpty) {
      buffer.write(' khususnya untuk jalur ${jalurPilihan.trim()}');
    }

    buffer.write(' tahun ajaran ini. Terima kasih.');
    return buffer.toString();
  }

  /// Membentuk [Uri] valid untuk tautan portal resmi PPDB.
  Uri? buildPortalUri(String rawUrl) {
    final String trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return null;

    final String normalizedUrl =
        trimmed.startsWith('http://') || trimmed.startsWith('https://')
            ? trimmed
            : 'https://$trimmed';

    final Uri? parsed = Uri.tryParse(normalizedUrl);
    if (parsed == null || !parsed.hasScheme || parsed.host.isEmpty) {
      return null;
    }
    return parsed;
  }

  /// Membentuk [Uri] `https://wa.me/...` lengkap dengan template pesan otomatis.
  Uri? buildWhatsAppUri({
    required String kontakWa,
    required String namaSekolah,
    String? jenjang,
    String? jalurPilihan,
    String? customMessage,
  }) {
    final String normalizedNumber = normalizeWhatsAppNumber(kontakWa);
    if (normalizedNumber.length < 10) return null;

    final String message =
        (customMessage != null && customMessage.trim().isNotEmpty)
            ? customMessage.trim()
            : buildWhatsAppMessage(
                namaSekolah: namaSekolah,
                jenjang: jenjang,
                jalurPilihan: jalurPilihan,
              );

    return Uri.https(
      'wa.me',
      '/$normalizedNumber',
      <String, String>{'text': message},
    );
  }

  /// Membuka tautan portal resmi PPDB di aplikasi browser eksternal.
  Future<ExternalLaunchResult> openPortalPpdb(String urlPortal) async {
    final Uri? uri = buildPortalUri(urlPortal);
    if (uri == null) {
      return const ExternalLaunchResult(
        success: false,
        message: 'Tautan portal resmi PPDB tidak valid atau belum tersedia.',
      );
    }

    try {
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        return ExternalLaunchResult(
          success: true,
          message: 'Membuka portal resmi PPDB di browser.',
          uri: uri,
        );
      }
      return ExternalLaunchResult(
        success: false,
        message:
            'Tidak dapat membuka browser eksternal untuk tautan portal PPDB.',
        uri: uri,
      );
    } catch (_) {
      return ExternalLaunchResult(
        success: false,
        message: 'Terjadi kendala saat membuka portal resmi PPDB.',
        uri: uri,
      );
    }
  }

  /// Membuka chat WhatsApp panitia PPDB (`https://wa.me/...`) dengan template
  /// pesan otomatis menanyakan jadwal dan syarat PPDB.
  Future<ExternalLaunchResult> openWhatsAppPanitia({
    required String kontakWa,
    required String namaSekolah,
    String? jenjang,
    String? jalurPilihan,
    String? customMessage,
  }) async {
    final Uri? uri = buildWhatsAppUri(
      kontakWa: kontakWa,
      namaSekolah: namaSekolah,
      jenjang: jenjang,
      jalurPilihan: jalurPilihan,
      customMessage: customMessage,
    );

    if (uri == null) {
      return const ExternalLaunchResult(
        success: false,
        message: 'Nomor WhatsApp panitia sekolah tidak valid.',
      );
    }

    try {
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        return ExternalLaunchResult(
          success: true,
          message: 'Membuka chat WhatsApp panitia $namaSekolah.',
          uri: uri,
        );
      }
      return ExternalLaunchResult(
        success: false,
        message:
            'Tidak dapat membuka aplikasi WhatsApp atau browser untuk menghubungi panitia.',
        uri: uri,
      );
    } catch (_) {
      return ExternalLaunchResult(
        success: false,
        message: 'Terjadi kendala saat membuka WhatsApp panitia sekolah.',
        uri: uri,
      );
    }
  }

  /// Helper praktis untuk membuka portal resmi PPDB dari objek [SchoolModel].
  Future<ExternalLaunchResult> openSchoolPortal(SchoolModel school) {
    return openPortalPpdb(school.urlPortalPpdb);
  }

  /// Helper praktis untuk menghubungi panitia PPDB dari objek [SchoolModel].
  Future<ExternalLaunchResult> contactSchoolCommittee(
    SchoolModel school, {
    String? jalurPilihan,
    String? customMessage,
  }) {
    return openWhatsAppPanitia(
      kontakWa: school.kontakWa,
      namaSekolah: school.namaSekolah,
      jenjang: school.jenjang,
      jalurPilihan: jalurPilihan,
      customMessage: customMessage,
    );
  }
}
