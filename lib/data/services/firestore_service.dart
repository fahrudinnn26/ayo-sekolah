import 'package:ayo_sekolah/core/constants/ppdb_constants.dart';
import 'package:ayo_sekolah/data/models/registration_draft_model.dart';
import 'package:ayo_sekolah/data/models/school_model.dart';
import 'package:ayo_sekolah/data/services/sample_schools_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Layanan akses data Cloud Firestore untuk koleksi `schools` dan
/// `ppdb_registrations`, dilengkapi mode fallback lokal (in-memory) yang aman
/// apabila `Firebase.apps.isEmpty`.
class FirestoreService {
  FirestoreService({
    FirebaseFirestore? firestore,
    this.forceLocalFallback = false,
  }) : _injectedFirestore = firestore;

  static const String schoolsCollection = 'schools';
  static const String registrationsCollection = 'ppdb_registrations';

  final FirebaseFirestore? _injectedFirestore;

  /// Jika `true`, seluruh operasi dipaksa menggunakan penyimpanan lokal
  /// in-memory meskipun Firebase sudah diinisialisasi.
  final bool forceLocalFallback;

  // Penyimpanan in-memory lokal saat Firebase belum terkonfigurasi.
  final List<SchoolModel> _localSchools = <SchoolModel>[];
  final List<RegistrationDraftModel> _localRegistrations =
      <RegistrationDraftModel>[];
  bool _localSchoolsSeeded = false;
  int _localIdCounter = 0;

  /// Bernilai `true` jika layanan sedang berjalan pada mode fallback lokal
  /// (misalnya saat `Firebase.apps.isEmpty` atau `forceLocalFallback` aktif).
  bool get isUsingLocalFallback {
    if (forceLocalFallback) return true;
    if (_injectedFirestore != null) return false;
    try {
      return Firebase.apps.isEmpty;
    } catch (_) {
      return true;
    }
  }

  FirebaseFirestore? get _db {
    if (isUsingLocalFallback) return null;
    return _injectedFirestore ?? FirebaseFirestore.instance;
  }

  // ===========================================================================
  // KOLEKSI `schools`
  // ===========================================================================

  /// Mengisi data awal 10 sekolah sampel Bandar Lampung secara otomatis apabila
  /// koleksi `schools` masih kosong.
  Future<void> seedSampleSchoolsIfEmpty() async {
    final FirebaseFirestore? db = _db;
    if (db == null) {
      if (_localSchools.isEmpty && !_localSchoolsSeeded) {
        _localSchools.addAll(SampleSchoolsData.schools);
        _localSchoolsSeeded = true;
      }
      return;
    }

    final CollectionReference<Map<String, dynamic>> colRef =
        db.collection(schoolsCollection);
    final QuerySnapshot<Map<String, dynamic>> existing =
        await colRef.limit(1).get();

    if (existing.docs.isNotEmpty) return;

    final WriteBatch batch = db.batch();
    for (final SchoolModel school in SampleSchoolsData.schools) {
      final DocumentReference<Map<String, dynamic>> docRef =
          colRef.doc(school.idSchool);
      batch.set(docRef, school.toMap());
    }
    await batch.commit();
  }

  /// Mengambil seluruh daftar sekolah dari koleksi `schools`.
  /// Jika [autoSeed] bernilai `true` dan koleksi kosong, data sampel akan
  /// di-seed secara otomatis terlebih dahulu.
  Future<List<SchoolModel>> getSchools({bool autoSeed = true}) async {
    if (autoSeed) {
      await seedSampleSchoolsIfEmpty();
    }

    final FirebaseFirestore? db = _db;
    if (db == null) {
      return List<SchoolModel>.unmodifiable(_localSchools);
    }

    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await db.collection(schoolsCollection).get();

    return snapshot.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
            SchoolModel.fromFirestore(doc))
        .toList();
  }

  /// Mengambil satu sekolah berdasarkan [idSchool], atau `null` jika tidak ada.
  Future<SchoolModel?> getSchoolById(String idSchool) async {
    final String trimmedId = idSchool.trim();
    if (trimmedId.isEmpty) return null;

    final FirebaseFirestore? db = _db;
    if (db == null) {
      for (final SchoolModel school in _localSchools) {
        if (school.idSchool == trimmedId) return school;
      }
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>> doc =
        await db.collection(schoolsCollection).doc(trimmedId).get();
    if (!doc.exists) return null;
    return SchoolModel.fromFirestore(doc);
  }

  /// Menambahkan atau memperbarui data sekolah pada koleksi `schools`.
  Future<SchoolModel> upsertSchool(SchoolModel school) async {
    final FirebaseFirestore? db = _db;
    final String resolvedId = school.idSchool.trim().isNotEmpty
        ? school.idSchool.trim()
        : _generateId(db, schoolsCollection, 'local_sch');
    final SchoolModel savedSchool = school.copyWith(idSchool: resolvedId);

    if (db == null) {
      final int existingIndex = _localSchools.indexWhere(
        (SchoolModel item) => item.idSchool == resolvedId,
      );
      if (existingIndex >= 0) {
        _localSchools[existingIndex] = savedSchool;
      } else {
        _localSchools.add(savedSchool);
      }
      return savedSchool;
    }

    await db
        .collection(schoolsCollection)
        .doc(resolvedId)
        .set(savedSchool.toMap(), SetOptions(merge: true));
    return savedSchool;
  }

  /// Menghapus dokumen sekolah berdasarkan [idSchool] dari koleksi `schools`.
  Future<void> deleteSchool(String idSchool) async {
    final String trimmedId = idSchool.trim();
    if (trimmedId.isEmpty) return;

    final FirebaseFirestore? db = _db;
    if (db == null) {
      _localSchools
          .removeWhere((SchoolModel item) => item.idSchool == trimmedId);
      return;
    }

    await db.collection(schoolsCollection).doc(trimmedId).delete();
  }

  // ===========================================================================
  // KOLEKSI `ppdb_registrations` (CRUD Penuh Simulasi PPDB Sandbox)
  // ===========================================================================

  /// Membuat (Create) draf simulasi pendaftaran baru di `ppdb_registrations`.
  /// Jika `draft.idRegistrasi` kosong, ID dokumen unik akan dibuat otomatis.
  Future<RegistrationDraftModel> createRegistrationDraft(
    RegistrationDraftModel draft,
  ) async {
    final FirebaseFirestore? db = _db;
    final String resolvedId = draft.idRegistrasi.trim().isNotEmpty
        ? draft.idRegistrasi.trim()
        : _generateId(db, registrationsCollection, 'local_reg');
    final RegistrationDraftModel savedDraft =
        draft.copyWith(idRegistrasi: resolvedId);

    if (db == null) {
      final int existingIndex = _localRegistrations.indexWhere(
        (RegistrationDraftModel item) => item.idRegistrasi == resolvedId,
      );
      if (existingIndex >= 0) {
        _localRegistrations[existingIndex] = savedDraft;
      } else {
        _localRegistrations.add(savedDraft);
      }
      return savedDraft;
    }

    await db
        .collection(registrationsCollection)
        .doc(resolvedId)
        .set(savedDraft.toMap());
    return savedDraft;
  }

  /// Membaca (Read) seluruh draf simulasi pendaftaran dari `ppdb_registrations`,
  /// diurutkan dari waktu pembuatan terbaru.
  Future<List<RegistrationDraftModel>> getRegistrationDrafts() async {
    final FirebaseFirestore? db = _db;
    if (db == null) {
      final List<RegistrationDraftModel> sorted =
          List<RegistrationDraftModel>.from(_localRegistrations)
            ..sort((RegistrationDraftModel a, RegistrationDraftModel b) =>
                b.createdAt.compareTo(a.createdAt));
      return List<RegistrationDraftModel>.unmodifiable(sorted);
    }

    final QuerySnapshot<Map<String, dynamic>> snapshot = await db
        .collection(registrationsCollection)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
            RegistrationDraftModel.fromFirestore(doc))
        .toList();
  }

  /// Membaca (Read) satu draf simulasi pendaftaran berdasarkan [idRegistrasi].
  Future<RegistrationDraftModel?> getRegistrationDraftById(
    String idRegistrasi,
  ) async {
    final String trimmedId = idRegistrasi.trim();
    if (trimmedId.isEmpty) return null;

    final FirebaseFirestore? db = _db;
    if (db == null) {
      for (final RegistrationDraftModel draft in _localRegistrations) {
        if (draft.idRegistrasi == trimmedId) return draft;
      }
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>> doc =
        await db.collection(registrationsCollection).doc(trimmedId).get();
    if (!doc.exists) return null;
    return RegistrationDraftModel.fromFirestore(doc);
  }

  /// Memperbarui (Update) seluruh data draf simulasi pendaftaran yang sudah ada.
  Future<RegistrationDraftModel> updateRegistrationDraft(
    RegistrationDraftModel draft,
  ) async {
    final String trimmedId = draft.idRegistrasi.trim();
    if (trimmedId.isEmpty) {
      throw ArgumentError('idRegistrasi wajib diisi untuk memperbarui draf.');
    }

    final RegistrationDraftModel normalizedDraft =
        draft.copyWith(idRegistrasi: trimmedId);

    final FirebaseFirestore? db = _db;
    if (db == null) {
      final int index = _localRegistrations.indexWhere(
        (RegistrationDraftModel item) => item.idRegistrasi == trimmedId,
      );
      if (index >= 0) {
        _localRegistrations[index] = normalizedDraft;
      } else {
        _localRegistrations.add(normalizedDraft);
      }
      return normalizedDraft;
    }

    await db
        .collection(registrationsCollection)
        .doc(trimmedId)
        .set(normalizedDraft.toMap(), SetOptions(merge: true));
    return normalizedDraft;
  }

  /// Memperbarui (Update) tahapan `statusSeleksi` (1–4) untuk satu draf
  /// berdasarkan [idRegistrasi].
  Future<RegistrationDraftModel?> updateRegistrationStatus({
    required String idRegistrasi,
    required int statusSeleksi,
  }) async {
    final String trimmedId = idRegistrasi.trim();
    if (trimmedId.isEmpty) return null;

    final int clampedStatus = statusSeleksi.clamp(
      PpdbConstants.statusDrafTersimpan,
      PpdbConstants.statusTerkirimSimulasi,
    );

    final FirebaseFirestore? db = _db;
    if (db == null) {
      final int index = _localRegistrations.indexWhere(
        (RegistrationDraftModel item) => item.idRegistrasi == trimmedId,
      );
      if (index < 0) return null;
      final RegistrationDraftModel updated =
          _localRegistrations[index].copyWith(statusSeleksi: clampedStatus);
      _localRegistrations[index] = updated;
      return updated;
    }

    final DocumentReference<Map<String, dynamic>> docRef =
        db.collection(registrationsCollection).doc(trimmedId);
    await docRef.update(<String, dynamic>{'statusSeleksi': clampedStatus});

    final DocumentSnapshot<Map<String, dynamic>> updatedDoc =
        await docRef.get();
    if (!updatedDoc.exists) return null;
    return RegistrationDraftModel.fromFirestore(updatedDoc);
  }

  /// Menghapus (Delete) draf simulasi pendaftaran berdasarkan [idRegistrasi].
  Future<void> deleteRegistrationDraft(String idRegistrasi) async {
    final String trimmedId = idRegistrasi.trim();
    if (trimmedId.isEmpty) return;

    final FirebaseFirestore? db = _db;
    if (db == null) {
      _localRegistrations.removeWhere(
        (RegistrationDraftModel item) => item.idRegistrasi == trimmedId,
      );
      return;
    }

    await db.collection(registrationsCollection).doc(trimmedId).delete();
  }

  String _generateId(
    FirebaseFirestore? db,
    String collectionName,
    String localPrefix,
  ) {
    if (db != null) {
      return db.collection(collectionName).doc().id;
    }
    _localIdCounter += 1;
    return '${localPrefix}_${DateTime.now().millisecondsSinceEpoch}_$_localIdCounter';
  }
}
