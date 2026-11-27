import 'package:ayo_sekolah/core/constants/ppdb_constants.dart';
import 'package:ayo_sekolah/core/utils/haversine_calculator.dart';
import 'package:ayo_sekolah/core/utils/smart_pathway_advisor.dart';
import 'package:ayo_sekolah/data/models/school_model.dart';
import 'package:ayo_sekolah/data/services/firestore_service.dart';
import 'package:ayo_sekolah/data/services/location_service.dart';
import 'package:flutter/foundation.dart';

/// State provider untuk mengelola daftar sekolah, filter jenjang, pencarian,
/// lokasi pengguna (GPS atau fallback kecamatan), pengurutan jarak terdekat,
/// serta komparasi maksimal 2 sekolah.
class SchoolProvider extends ChangeNotifier {
  SchoolProvider({
    FirestoreService? firestoreService,
    LocationService? locationService,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        _locationService = locationService ?? const LocationService(),
        _selectedFallbackKecamatan = PpdbConstants.defaultKecamatanFallback,
        _currentLocation = PpdbConstants.getKoordinatFallback(
          PpdbConstants.defaultKecamatanFallback,
        );

  /// Nilai filter untuk menampilkan seluruh jenjang sekolah.
  static const String filterSemua = 'Semua';

  /// Batas maksimal jumlah sekolah yang dapat dipilih untuk dikomparasi.
  static const int maxCompareSchools = 2;

  /// Daftar opsi filter jenjang yang tersedia untuk UI.
  static const List<String> daftarFilterJenjang = <String>[
    filterSemua,
    ...PpdbConstants.daftarJenjangSekolah,
  ];

  final FirestoreService _firestoreService;
  final LocationService _locationService;

  final List<SchoolModel> _schools = <SchoolModel>[];
  final List<SchoolModel> _comparedSchools = <SchoolModel>[];

  String _selectedJenjang = filterSemua;
  String _searchQuery = '';

  KoordinatLokasi _currentLocation;
  String _selectedFallbackKecamatan;
  bool _isUsingGps = false;
  LocationStatus? _lastLocationStatus;
  String? _locationMessage;

  bool _isLoadingSchools = false;
  bool _isLoadingLocation = false;
  String? _errorMessage;

  /// Seluruh daftar sekolah yang sudah terurut dari jarak terdekat.
  List<SchoolModel> get allSchools => List<SchoolModel>.unmodifiable(_schools);

  /// Daftar sekolah hasil filter jenjang dan pencarian nama, terurut dari
  /// jarak terdekat terhadap [currentLocation].
  List<SchoolModel> get filteredSchools {
    final String normalizedQuery = _searchQuery.trim().toLowerCase();
    final List<SchoolModel> filtered = _schools.where((SchoolModel school) {
      final bool matchesJenjang = _selectedJenjang == filterSemua ||
          school.jenjang.toUpperCase() == _selectedJenjang.toUpperCase();
      if (!matchesJenjang) return false;

      if (normalizedQuery.isEmpty) return true;
      return school.namaSekolah.toLowerCase().contains(normalizedQuery) ||
          school.alamatPosko.toLowerCase().contains(normalizedQuery) ||
          school.jenjang.toLowerCase().contains(normalizedQuery);
    }).toList();

    return List<SchoolModel>.unmodifiable(filtered);
  }

  /// Filter jenjang aktif (`Semua`, `SD`, `SMP`, `SMA`, atau `SMK`).
  String get selectedJenjang => _selectedJenjang;

  /// Kata kunci pencarian nama sekolah aktif.
  String get searchQuery => _searchQuery;

  /// Koordinat lokasi pengguna saat ini (hasil GPS atau fallback kecamatan).
  KoordinatLokasi get currentLocation => _currentLocation;

  /// Nama kecamatan fallback yang sedang dipilih.
  String get selectedFallbackKecamatan => _selectedFallbackKecamatan;

  /// Bernilai `true` jika lokasi aktif berasal dari GPS perangkat.
  bool get isUsingGps => _isUsingGps;

  /// Label ringkas sumber lokasi aktif untuk ditampilkan pada UI.
  String get locationLabel => _isUsingGps
      ? 'GPS Perangkat'
      : 'Kecamatan $_selectedFallbackKecamatan (Fallback)';

  /// Status terakhir percobaan pengambilan GPS.
  LocationStatus? get lastLocationStatus => _lastLocationStatus;

  /// Pesan status lokasi terbaru dalam Bahasa Indonesia.
  String? get locationMessage => _locationMessage;

  /// Menandakan proses pemuatan daftar sekolah sedang berlangsung.
  bool get isLoadingSchools => _isLoadingSchools;

  /// Menandakan proses deteksi sinyal GPS sedang berlangsung.
  bool get isLoadingLocation => _isLoadingLocation;

  /// Pesan galat terakhir apabila pemuatan data gagal.
  String? get errorMessage => _errorMessage;

  /// Bernilai `true` apabila data sekolah bersumber dari fallback in-memory.
  bool get isUsingLocalFallback => _firestoreService.isUsingLocalFallback;

  /// Daftar sekolah yang dipilih untuk dikomparasi (maksimal 2 sekolah).
  List<SchoolModel> get comparedSchools =>
      List<SchoolModel>.unmodifiable(_comparedSchools);

  /// Jumlah sekolah yang sedang dipilih untuk komparasi (0–2).
  int get comparedCount => _comparedSchools.length;

  /// Bernilai `true` apabila sudah terpilih tepat 2 sekolah untuk dibandingkan.
  bool get canCompare => _comparedSchools.length == maxCompareSchools;

  /// Bernilai `true` apabila slot komparasi (maksimal 2 sekolah) telah penuh.
  bool get isCompareFull => _comparedSchools.length >= maxCompareSchools;

  /// Memeriksa apakah sekolah dengan [idSchool] sedang masuk daftar komparasi.
  bool isSchoolCompared(String idSchool) {
    return _comparedSchools.any(
      (SchoolModel item) => item.idSchool == idSchool,
    );
  }

  /// Mencari sekolah berdasarkan [idSchool] pada daftar yang sudah dimuat.
  SchoolModel? getSchoolById(String idSchool) {
    for (final SchoolModel school in _schools) {
      if (school.idSchool == idSchool) return school;
    }
    return null;
  }

  /// Menginisialisasi data sekolah dan mendeteksi lokasi GPS (dengan fallback
  /// otomatis ke kecamatan apabila GPS nonaktif atau izin ditolak).
  Future<void> initialize() async {
    await Future.wait<void>(<Future<void>>[
      loadSchools(),
      detectUserLocation().then((_) {}),
    ]);
  }

  /// Memuat daftar sekolah dari [FirestoreService] (auto-seed bila kosong)
  /// dan langsung mengurutkannya dari jarak terdekat.
  Future<void> loadSchools({bool autoSeed = true}) async {
    _isLoadingSchools = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<SchoolModel> loaded =
          await _firestoreService.getSchools(autoSeed: autoSeed);
      _schools
        ..clear()
        ..addAll(loaded);
      _sortSchoolsByDistance();
      _syncComparedSchools();
    } catch (error) {
      _errorMessage = 'Gagal memuat data sekolah: $error';
    } finally {
      _isLoadingSchools = false;
      notifyListeners();
    }
  }

  /// Mencoba mengambil lokasi GPS perangkat. Jika gagal/ditolak/GPS nonaktif,
  /// otomatis menggunakan koordinat fallback [_selectedFallbackKecamatan]
  /// tanpa crash dan memperbarui urutan jarak sekolah.
  Future<LocationResult> detectUserLocation() async {
    _isLoadingLocation = true;
    notifyListeners();

    final LocationResult result = await _locationService.getCurrentLocation();
    _lastLocationStatus = result.status;
    _locationMessage = result.pesan;

    if (result.isSuccess && result.koordinat != null) {
      _currentLocation = result.koordinat!;
      _isUsingGps = true;
    } else {
      _currentLocation = PpdbConstants.getKoordinatFallback(
        _selectedFallbackKecamatan,
      );
      _isUsingGps = false;
    }

    _sortSchoolsByDistance();
    _isLoadingLocation = false;
    notifyListeners();
    return result;
  }

  /// Mengatur lokasi pengguna menggunakan titik koordinat fallback kecamatan
  /// dari [PpdbConstants.koordinatFallbackKecamatan] dan mengurutkan ulang sekolah.
  void setFallbackKecamatan(String kecamatan) {
    final String resolvedKecamatan =
        PpdbConstants.koordinatFallbackKecamatan.containsKey(kecamatan)
            ? kecamatan
            : PpdbConstants.defaultKecamatanFallback;

    _selectedFallbackKecamatan = resolvedKecamatan;
    _currentLocation = PpdbConstants.getKoordinatFallback(resolvedKecamatan);
    _isUsingGps = false;
    _locationMessage =
        'Menggunakan koordinat fallback Kecamatan $resolvedKecamatan.';

    _sortSchoolsByDistance();
    notifyListeners();
  }

  /// Mengatur koordinat lokasi pengguna secara manual dan mengurutkan ulang sekolah.
  void setCustomLocation(
    KoordinatLokasi koordinat, {
    bool isGps = false,
    String? message,
  }) {
    _currentLocation = koordinat;
    _isUsingGps = isGps;
    if (message != null) {
      _locationMessage = message;
    }
    _sortSchoolsByDistance();
    notifyListeners();
  }

  /// Mengubah filter jenjang aktif (`Semua`, `SD`, `SMP`, `SMA`, atau `SMK`).
  void setJenjangFilter(String jenjang) {
    final String normalized = daftarFilterJenjang.firstWhere(
      (String option) => option.toUpperCase() == jenjang.trim().toUpperCase(),
      orElse: () => filterSemua,
    );
    if (_selectedJenjang == normalized) return;
    _selectedJenjang = normalized;
    notifyListeners();
  }

  /// Mengubah kata kunci pencarian nama sekolah.
  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  /// Mengatur ulang filter jenjang dan pencarian ke kondisi awal.
  void resetFilters() {
    if (_selectedJenjang == filterSemua && _searchQuery.isEmpty) return;
    _selectedJenjang = filterSemua;
    _searchQuery = '';
    notifyListeners();
  }

  /// Menambahkan atau menghapus [school] dari daftar komparasi (maksimal 2).
  /// Mengembalikan `true` jika perubahan berhasil dilakukan, atau `false` jika
  /// gagal menambahkan karena batas maksimal 2 sekolah telah tercapai.
  bool toggleCompareSchool(SchoolModel school) {
    final int existingIndex = _comparedSchools.indexWhere(
      (SchoolModel item) => item.idSchool == school.idSchool,
    );
    if (existingIndex >= 0) {
      _comparedSchools.removeAt(existingIndex);
      notifyListeners();
      return true;
    }

    if (_comparedSchools.length >= maxCompareSchools) {
      return false;
    }

    _comparedSchools.add(school);
    notifyListeners();
    return true;
  }

  /// Menambahkan [school] ke daftar komparasi jika belum ada dan slot < 2.
  bool addSchoolToCompare(SchoolModel school) {
    if (isSchoolCompared(school.idSchool)) return true;
    if (_comparedSchools.length >= maxCompareSchools) return false;
    _comparedSchools.add(school);
    notifyListeners();
    return true;
  }

  /// Mengganti sekolah dengan [oldIdSchool] pada daftar komparasi dengan
  /// [newSchool] tanpa mengubah urutan slotnya. Mengembalikan `false` jika
  /// [newSchool] sudah berada di slot komparasi lain.
  bool replaceComparedSchool(String oldIdSchool, SchoolModel newSchool) {
    if (oldIdSchool == newSchool.idSchool) return true;
    if (isSchoolCompared(newSchool.idSchool)) return false;

    final int index = _comparedSchools.indexWhere(
      (SchoolModel item) => item.idSchool == oldIdSchool,
    );
    if (index < 0) {
      return addSchoolToCompare(newSchool);
    }

    _comparedSchools[index] = newSchool;
    notifyListeners();
    return true;
  }

  /// Menghapus sekolah berdasarkan [idSchool] dari daftar komparasi.
  void removeSchoolFromCompare(String idSchool) {
    final int beforeLength = _comparedSchools.length;
    _comparedSchools.removeWhere(
      (SchoolModel item) => item.idSchool == idSchool,
    );
    if (_comparedSchools.length != beforeLength) {
      notifyListeners();
    }
  }

  /// Mengosongkan daftar sekolah yang dipilih untuk dikomparasi.
  void clearComparedSchools() {
    if (_comparedSchools.isEmpty) return;
    _comparedSchools.clear();
    notifyListeners();
  }

  /// Menghitung jarak (dalam meter) dari [currentLocation] ke [school].
  double getDistanceMeters(SchoolModel school) {
    return HaversineCalculator.hitungJarakMeter(
      startLat: _currentLocation.latitude,
      startLng: _currentLocation.longitude,
      endLat: school.latitude,
      endLng: school.longitude,
    );
  }

  /// Menghitung jarak (dalam kilometer) dari [currentLocation] ke [school].
  double getDistanceKilometers(SchoolModel school) {
    return HaversineCalculator.meterKeKilometer(getDistanceMeters(school));
  }

  /// Menentukan kategori [StatusZonasi] untuk [school] berdasarkan jarak saat ini.
  StatusZonasi getStatusZonasi(SchoolModel school) {
    return HaversineCalculator.tentukanStatusZonasi(getDistanceMeters(school));
  }

  /// Mengembalikan teks jarak terformat (m / km) dari [currentLocation] ke [school].
  String getFormattedDistance(SchoolModel school) {
    return HaversineCalculator.formatJarak(getDistanceMeters(school));
  }

  /// Menjalankan evaluasi [SmartPathwayAdvisor] untuk [school] menggunakan
  /// jarak dari lokasi pengguna saat ini.
  RekomendasiJalurResult evaluatePathway({
    required SchoolModel school,
    required double rataRataRapor,
    required bool memilikiDokumenAfirmasi,
    required bool memilikiSuratMutasi,
  }) {
    return SmartPathwayAdvisor.evaluasi(
      sekolah: school,
      jarakMeter: getDistanceMeters(school),
      rataRataRapor: rataRataRapor,
      memilikiDokumenAfirmasi: memilikiDokumenAfirmasi,
      memilikiSuratMutasi: memilikiSuratMutasi,
    );
  }

  void _sortSchoolsByDistance() {
    _schools.sort((SchoolModel a, SchoolModel b) {
      final double distanceA = getDistanceMeters(a);
      final double distanceB = getDistanceMeters(b);
      final int compareDistance = distanceA.compareTo(distanceB);
      if (compareDistance != 0) return compareDistance;
      return a.namaSekolah.compareTo(b.namaSekolah);
    });
  }

  void _syncComparedSchools() {
    if (_comparedSchools.isEmpty) return;
    final List<SchoolModel> synced = <SchoolModel>[];
    for (final SchoolModel selected in _comparedSchools) {
      final SchoolModel? latest = getSchoolById(selected.idSchool);
      if (latest != null) {
        synced.add(latest);
      }
    }
    _comparedSchools
      ..clear()
      ..addAll(synced.take(maxCompareSchools));
  }
}
