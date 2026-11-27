import 'package:ayo_sekolah/core/constants/ppdb_constants.dart';
import 'package:ayo_sekolah/data/models/registration_draft_model.dart';
import 'package:ayo_sekolah/data/models/school_model.dart';
import 'package:ayo_sekolah/data/services/firestore_service.dart';
import 'package:flutter/foundation.dart';

/// State provider untuk mengelola daftar draf simulasi pendaftaran PPDB Sandbox
/// (`RegistrationDraftModel`) yang terhubung ke [FirestoreService].
class SandboxProvider extends ChangeNotifier {
  SandboxProvider({
    FirestoreService? firestoreService,
  }) : _firestoreService = firestoreService ?? FirestoreService();

  final FirestoreService _firestoreService;

  final List<RegistrationDraftModel> _drafts = <RegistrationDraftModel>[];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  /// Seluruh daftar draf pendaftaran simulasi, terurut dari yang terbaru.
  List<RegistrationDraftModel> get drafts =>
      List<RegistrationDraftModel>.unmodifiable(_drafts);

  /// Jumlah total draf simulasi yang tersimpan.
  int get totalDrafts => _drafts.length;

  /// Menandakan proses pembacaan daftar draf sedang berlangsung.
  bool get isLoading => _isLoading;

  /// Menandakan proses tambah, ubah, atau hapus draf sedang berlangsung.
  bool get isSaving => _isSaving;

  /// Pesan galat terakhir apabila operasi CRUD gagal.
  String? get errorMessage => _errorMessage;

  /// Bernilai `true` apabila penyimpanan menggunakan mode fallback in-memory.
  bool get isUsingLocalFallback => _firestoreService.isUsingLocalFallback;

  /// Bernilai `true` apabila penyimpanan aktif terhubung ke Cloud Firestore.
  bool get isCloudConnected => _firestoreService.isCloudConnected;

  /// Mengembalikan `projectId` Firebase aktif jika terhubung ke Cloud.
  String? get firebaseProjectId => _firestoreService.firebaseProjectId;

  /// Memfilter daftar draf berdasarkan tahapan [statusSeleksi] (1–4).
  List<RegistrationDraftModel> draftsByStatus(int statusSeleksi) {
    return List<RegistrationDraftModel>.unmodifiable(
      _drafts.where(
        (RegistrationDraftModel draft) => draft.statusSeleksi == statusSeleksi,
      ),
    );
  }

  /// Mencari draf pendaftaran berdasarkan [idRegistrasi].
  RegistrationDraftModel? getDraftById(String idRegistrasi) {
    for (final RegistrationDraftModel draft in _drafts) {
      if (draft.idRegistrasi == idRegistrasi) return draft;
    }
    return null;
  }

  /// Memuat ulang seluruh daftar draf pendaftaran dari [FirestoreService].
  Future<void> loadDrafts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<RegistrationDraftModel> loaded =
          await _firestoreService.getRegistrationDrafts();
      _drafts
        ..clear()
        ..addAll(loaded);
      _sortDraftsNewestFirst();
    } catch (error) {
      _errorMessage = 'Gagal memuat daftar draf simulasi: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Menambahkan draf pendaftaran baru dari objek [RegistrationDraftModel]
  /// ke [FirestoreService] dan memperbarui state lokal.
  Future<RegistrationDraftModel?> addDraft(RegistrationDraftModel draft) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final RegistrationDraftModel created =
          await _firestoreService.createRegistrationDraft(draft);
      _drafts.removeWhere(
        (RegistrationDraftModel item) =>
            item.idRegistrasi == created.idRegistrasi,
      );
      _drafts.insert(0, created);
      _sortDraftsNewestFirst();
      return created;
    } catch (error) {
      _errorMessage = 'Gagal menyimpan draf pendaftaran: $error';
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Helper praktis untuk membuat dan menyimpan draf simulasi baru langsung
  /// dari input formulir beserta objek [SchoolModel] tujuan.
  Future<RegistrationDraftModel?> createDraft({
    required SchoolModel school,
    required String namaSiswa,
    required String nisn,
    required String jalurPilihan,
    required double rataRataRapor,
    required double jarakMeter,
    int statusSeleksi = PpdbConstants.statusDrafTersimpan,
  }) {
    final int clampedStatus = statusSeleksi.clamp(
      PpdbConstants.statusDrafTersimpan,
      PpdbConstants.statusTerkirimSimulasi,
    );

    final RegistrationDraftModel newDraft = RegistrationDraftModel(
      idRegistrasi: '',
      idSchool: school.idSchool,
      namaSekolah: school.namaSekolah,
      namaSiswa: namaSiswa.trim(),
      nisn: nisn.trim(),
      jalurPilihan: jalurPilihan,
      rataRataRapor: rataRataRapor,
      jarakMeter: jarakMeter,
      statusSeleksi: clampedStatus,
      createdAt: DateTime.now(),
    );

    return addDraft(newDraft);
  }

  /// Memperbarui data draf simulasi yang sudah ada di [FirestoreService].
  Future<RegistrationDraftModel?> updateDraft(
    RegistrationDraftModel updatedDraft,
  ) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final RegistrationDraftModel saved =
          await _firestoreService.updateRegistrationDraft(updatedDraft);
      final int index = _drafts.indexWhere(
        (RegistrationDraftModel item) =>
            item.idRegistrasi == saved.idRegistrasi,
      );
      if (index >= 0) {
        _drafts[index] = saved;
      } else {
        _drafts.insert(0, saved);
      }
      _sortDraftsNewestFirst();
      return saved;
    } catch (error) {
      _errorMessage = 'Gagal memperbarui draf pendaftaran: $error';
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Mengubah tahapan [statusSeleksi] (1–4) untuk draf dengan [idRegistrasi].
  Future<RegistrationDraftModel?> updateDraftStatus({
    required String idRegistrasi,
    required int statusSeleksi,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final RegistrationDraftModel? updated =
          await _firestoreService.updateRegistrationStatus(
        idRegistrasi: idRegistrasi,
        statusSeleksi: statusSeleksi,
      );

      if (updated != null) {
        final int index = _drafts.indexWhere(
          (RegistrationDraftModel item) =>
              item.idRegistrasi == updated.idRegistrasi,
        );
        if (index >= 0) {
          _drafts[index] = updated;
        }
      }
      return updated;
    } catch (error) {
      _errorMessage = 'Gagal memperbarui status draf simulasi: $error';
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Menaikkan tahapan `statusSeleksi` sebanyak 1 langkah (maksimal tahap 4:
  /// Terkirim Simulasi) untuk draf dengan [idRegistrasi].
  Future<RegistrationDraftModel?> advanceDraftStatus(String idRegistrasi) async {
    final RegistrationDraftModel? current = getDraftById(idRegistrasi);
    if (current == null) return null;

    final int nextStatus = (current.statusSeleksi + 1).clamp(
      PpdbConstants.statusDrafTersimpan,
      PpdbConstants.statusTerkirimSimulasi,
    );
    if (nextStatus == current.statusSeleksi) return current;

    return updateDraftStatus(
      idRegistrasi: idRegistrasi,
      statusSeleksi: nextStatus,
    );
  }

  /// Menghapus draf simulasi dengan [idRegistrasi] dari [FirestoreService]
  /// dan daftar lokal.
  Future<bool> deleteDraft(String idRegistrasi) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.deleteRegistrationDraft(idRegistrasi);
      _drafts.removeWhere(
        (RegistrationDraftModel item) => item.idRegistrasi == idRegistrasi,
      );
      return true;
    } catch (error) {
      _errorMessage = 'Gagal menghapus draf pendaftaran: $error';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Menghapus pesan galat terakhir pada state provider.
  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  void _sortDraftsNewestFirst() {
    _drafts.sort(
      (RegistrationDraftModel a, RegistrationDraftModel b) =>
          b.createdAt.compareTo(a.createdAt),
    );
  }
}
