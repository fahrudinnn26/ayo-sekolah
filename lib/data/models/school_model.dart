import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Model data sekolah untuk direktori dan rekomendasi PPDB Ayo Sekolah.
class SchoolModel {
  const SchoolModel({
    required this.idSchool,
    required this.namaSekolah,
    required this.jenjang,
    required this.status,
    required this.akreditasi,
    required this.latitude,
    required this.longitude,
    required this.kontakWa,
    required this.kuota,
    required this.passingGrade,
    required this.fasilitas,
    required this.urlPortalPpdb,
    required this.alamatPosko,
  });

  final String idSchool;
  final String namaSekolah;

  /// Jenjang pendidikan: SD, SMP, SMA, atau SMK.
  final String jenjang;

  /// Status sekolah: Negeri atau Swasta.
  final String status;

  final String akreditasi;
  final double latitude;
  final double longitude;
  final String kontakWa;

  /// Peta kuota penerimaan per jalur PPDB (misal: {'Zonasi': 150, 'Prestasi': 45}).
  final Map<String, int> kuota;

  final double passingGrade;
  final List<String> fasilitas;
  final String urlPortalPpdb;
  final String alamatPosko;

  /// Total keseluruhan kuota dari seluruh jalur PPDB pada sekolah ini.
  int get totalKuota =>
      kuota.values.fold<int>(0, (int sum, int jumlah) => sum + jumlah);

  /// Membuat [SchoolModel] dari [DocumentSnapshot] Cloud Firestore.
  factory SchoolModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return SchoolModel.fromMap(data, documentId: doc.id);
  }

  /// Membuat [SchoolModel] dari [Map] key-value dengan fallback [documentId].
  factory SchoolModel.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    final String rawId = (map['idSchool'] as String?)?.trim() ?? '';
    final String resolvedId = rawId.isNotEmpty ? rawId : (documentId ?? '');

    final Map<String, int> parsedKuota = <String, int>{};
    final Object? rawKuota = map['kuota'];
    if (rawKuota is Map) {
      rawKuota.forEach((Object? key, Object? value) {
        if (key != null) {
          parsedKuota[key.toString()] = _parseInt(value);
        }
      });
    }

    final List<String> parsedFasilitas = <String>[];
    final Object? rawFasilitas = map['fasilitas'];
    if (rawFasilitas is Iterable) {
      for (final Object? item in rawFasilitas) {
        if (item != null) {
          parsedFasilitas.add(item.toString());
        }
      }
    }

    return SchoolModel(
      idSchool: resolvedId,
      namaSekolah: (map['namaSekolah'] as String?) ?? '',
      jenjang: (map['jenjang'] as String?) ?? '',
      status: (map['status'] as String?) ?? '',
      akreditasi: (map['akreditasi'] as String?) ?? '',
      latitude: _parseDouble(map['latitude']),
      longitude: _parseDouble(map['longitude']),
      kontakWa: (map['kontakWa'] as String?) ?? '',
      kuota: parsedKuota,
      passingGrade: _parseDouble(map['passingGrade']),
      fasilitas: parsedFasilitas,
      urlPortalPpdb: (map['urlPortalPpdb'] as String?) ?? '',
      alamatPosko: (map['alamatPosko'] as String?) ?? '',
    );
  }

  /// Mengonversi [SchoolModel] ke [Map] untuk disimpan ke Cloud Firestore.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'idSchool': idSchool,
      'namaSekolah': namaSekolah,
      'jenjang': jenjang,
      'status': status,
      'akreditasi': akreditasi,
      'latitude': latitude,
      'longitude': longitude,
      'kontakWa': kontakWa,
      'kuota': Map<String, int>.from(kuota),
      'passingGrade': passingGrade,
      'fasilitas': List<String>.from(fasilitas),
      'urlPortalPpdb': urlPortalPpdb,
      'alamatPosko': alamatPosko,
    };
  }

  /// Membuat salinan [SchoolModel] dengan beberapa properti yang diperbarui.
  SchoolModel copyWith({
    String? idSchool,
    String? namaSekolah,
    String? jenjang,
    String? status,
    String? akreditasi,
    double? latitude,
    double? longitude,
    String? kontakWa,
    Map<String, int>? kuota,
    double? passingGrade,
    List<String>? fasilitas,
    String? urlPortalPpdb,
    String? alamatPosko,
  }) {
    return SchoolModel(
      idSchool: idSchool ?? this.idSchool,
      namaSekolah: namaSekolah ?? this.namaSekolah,
      jenjang: jenjang ?? this.jenjang,
      status: status ?? this.status,
      akreditasi: akreditasi ?? this.akreditasi,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      kontakWa: kontakWa ?? this.kontakWa,
      kuota: kuota ?? Map<String, int>.from(this.kuota),
      passingGrade: passingGrade ?? this.passingGrade,
      fasilitas: fasilitas ?? List<String>.from(this.fasilitas),
      urlPortalPpdb: urlPortalPpdb ?? this.urlPortalPpdb,
      alamatPosko: alamatPosko ?? this.alamatPosko,
    );
  }

  static double _parseDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SchoolModel &&
        other.idSchool == idSchool &&
        other.namaSekolah == namaSekolah &&
        other.jenjang == jenjang &&
        other.status == status &&
        other.akreditasi == akreditasi &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.kontakWa == kontakWa &&
        mapEquals(other.kuota, kuota) &&
        other.passingGrade == passingGrade &&
        listEquals(other.fasilitas, fasilitas) &&
        other.urlPortalPpdb == urlPortalPpdb &&
        other.alamatPosko == alamatPosko;
  }

  @override
  int get hashCode => Object.hash(
        idSchool,
        namaSekolah,
        jenjang,
        status,
        akreditasi,
        latitude,
        longitude,
        kontakWa,
        Object.hashAllUnordered(
          kuota.entries.map((MapEntry<String, int> e) => Object.hash(e.key, e.value)),
        ),
        passingGrade,
        Object.hashAll(fasilitas),
        urlPortalPpdb,
        alamatPosko,
      );

  @override
  String toString() {
    return 'SchoolModel(idSchool: $idSchool, namaSekolah: $namaSekolah, '
        'jenjang: $jenjang, status: $status, akreditasi: $akreditasi)';
  }
}
