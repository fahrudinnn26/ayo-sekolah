import 'package:ayo_sekolah/core/constants/ppdb_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Model data draf pendaftaran untuk Simulasi PPDB Sandbox.
class RegistrationDraftModel {
  const RegistrationDraftModel({
    required this.idRegistrasi,
    required this.idSchool,
    required this.namaSekolah,
    required this.namaSiswa,
    required this.nisn,
    required this.jalurPilihan,
    required this.rataRataRapor,
    required this.jarakMeter,
    required this.statusSeleksi,
    required this.createdAt,
  }) : assert(
          statusSeleksi >= PpdbConstants.statusDrafTersimpan &&
              statusSeleksi <= PpdbConstants.statusTerkirimSimulasi,
          'statusSeleksi harus bernilai antara 1 hingga 4.',
        );

  final String idRegistrasi;
  final String idSchool;
  final String namaSekolah;
  final String namaSiswa;
  final String nisn;

  /// Jalur PPDB yang dipilih (Zonasi, Prestasi, Afirmasi, atau Mutasi).
  final String jalurPilihan;

  final double rataRataRapor;
  final double jarakMeter;

  /// Status progres seleksi simulasi (1–4):
  /// - 1: Draf Tersimpan
  /// - 2: Kelengkapan Berkas
  /// - 3: Siap Verifikasi
  /// - 4: Terkirim Simulasi
  final int statusSeleksi;

  final DateTime createdAt;

  /// Label status seleksi yang mudah dibaca untuk ditampilkan di UI.
  String get statusSeleksiLabel =>
      PpdbConstants.getLabelStatusSeleksi(statusSeleksi);

  /// Membuat [RegistrationDraftModel] dari [DocumentSnapshot] Cloud Firestore.
  factory RegistrationDraftModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return RegistrationDraftModel.fromMap(data, documentId: doc.id);
  }

  /// Membuat [RegistrationDraftModel] dari [Map] key-value dengan fallback [documentId].
  factory RegistrationDraftModel.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    final String rawId = (map['idRegistrasi'] as String?)?.trim() ?? '';
    final String resolvedId = rawId.isNotEmpty ? rawId : (documentId ?? '');

    final int parsedStatus = _parseInt(
      map['statusSeleksi'],
      fallback: PpdbConstants.statusDrafTersimpan,
    ).clamp(
      PpdbConstants.statusDrafTersimpan,
      PpdbConstants.statusTerkirimSimulasi,
    );

    return RegistrationDraftModel(
      idRegistrasi: resolvedId,
      idSchool: (map['idSchool'] as String?) ?? '',
      namaSekolah: (map['namaSekolah'] as String?) ?? '',
      namaSiswa: (map['namaSiswa'] as String?) ?? '',
      nisn: (map['nisn'] as String?) ?? '',
      jalurPilihan: (map['jalurPilihan'] as String?) ?? '',
      rataRataRapor: _parseDouble(map['rataRataRapor']),
      jarakMeter: _parseDouble(map['jarakMeter']),
      statusSeleksi: parsedStatus,
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  /// Mengonversi [RegistrationDraftModel] ke [Map] untuk disimpan ke Cloud Firestore.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'idRegistrasi': idRegistrasi,
      'idSchool': idSchool,
      'namaSekolah': namaSekolah,
      'namaSiswa': namaSiswa,
      'nisn': nisn,
      'jalurPilihan': jalurPilihan,
      'rataRataRapor': rataRataRapor,
      'jarakMeter': jarakMeter,
      'statusSeleksi': statusSeleksi,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Membuat salinan [RegistrationDraftModel] dengan beberapa properti yang diperbarui.
  RegistrationDraftModel copyWith({
    String? idRegistrasi,
    String? idSchool,
    String? namaSekolah,
    String? namaSiswa,
    String? nisn,
    String? jalurPilihan,
    double? rataRataRapor,
    double? jarakMeter,
    int? statusSeleksi,
    DateTime? createdAt,
  }) {
    return RegistrationDraftModel(
      idRegistrasi: idRegistrasi ?? this.idRegistrasi,
      idSchool: idSchool ?? this.idSchool,
      namaSekolah: namaSekolah ?? this.namaSekolah,
      namaSiswa: namaSiswa ?? this.namaSiswa,
      nisn: nisn ?? this.nisn,
      jalurPilihan: jalurPilihan ?? this.jalurPilihan,
      rataRataRapor: rataRataRapor ?? this.rataRataRapor,
      jarakMeter: jarakMeter ?? this.jarakMeter,
      statusSeleksi: statusSeleksi ?? this.statusSeleksi,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static double _parseDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(Object? value, {required int fallback}) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static DateTime _parseDateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.now();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RegistrationDraftModel &&
        other.idRegistrasi == idRegistrasi &&
        other.idSchool == idSchool &&
        other.namaSekolah == namaSekolah &&
        other.namaSiswa == namaSiswa &&
        other.nisn == nisn &&
        other.jalurPilihan == jalurPilihan &&
        other.rataRataRapor == rataRataRapor &&
        other.jarakMeter == jarakMeter &&
        other.statusSeleksi == statusSeleksi &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
        idRegistrasi,
        idSchool,
        namaSekolah,
        namaSiswa,
        nisn,
        jalurPilihan,
        rataRataRapor,
        jarakMeter,
        statusSeleksi,
        createdAt,
      );

  @override
  String toString() {
    return 'RegistrationDraftModel(idRegistrasi: $idRegistrasi, '
        'namaSiswa: $namaSiswa, namaSekolah: $namaSekolah, '
        'jalurPilihan: $jalurPilihan, statusSeleksi: $statusSeleksi)';
  }
}
