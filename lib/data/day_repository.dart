import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/day_entry.dart';

class DayRepository {
  DayRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _days(String profileId) =>
      _db.collection('profiles').doc(profileId).collection('days');

  Stream<List<DayEntry>> watchAll(String profileId) => _days(profileId)
      .snapshots()
      .map((q) => q.docs.map((d) => DayEntry.fromMap(d.data())).toList());

  /// Satu dokumen per tanggal, ditulis utuh → last-write-wins.
  /// PENTING: saat offline Future ini baru selesai setelah tersinkron;
  /// pemanggil di UI harus memakai `unawaited(...)`.
  Future<void> saveDay({required String profileId, required String uid, required DayEntry entry}) {
    final ref = _days(profileId).doc(entry.date);
    if (entry.isEmpty) return ref.delete();
    return ref.set({
      ...entry.toMap(),
      'updatedBy': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
