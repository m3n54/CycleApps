import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/couple_care.dart';
import '../domain/cycle_profile.dart';
import 'invite_code.dart';

class JoinException implements Exception {
  const JoinException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ProfileRepository {
  ProfileRepository(this._db, {this.random});

  final FirebaseFirestore _db;
  final Random? random;

  static const inviteValidity = Duration(hours: 24);

  DocumentReference<Map<String, dynamic>> _user(String uid) => _db.collection('users').doc(uid);
  DocumentReference<Map<String, dynamic>> _profile(String id) => _db.collection('profiles').doc(id);

  Stream<String?> watchActiveProfileId(String uid) =>
      _user(uid).snapshots().map((s) => s.data()?['activeProfileId'] as String?);

  Stream<CycleProfile?> watchProfile(String profileId) => _profile(profileId)
      .snapshots()
      .map((s) => s.exists ? CycleProfile.fromMap(s.id, s.data()!) : null);

  Future<String> createProfile({required String uid, required String name}) async {
    final ref = _db.collection('profiles').doc();
    final batch = _db.batch()
      ..set(ref, {
        'ownerUid': uid,
        'memberUids': [uid],
        'name': name.trim(),
        'defaultCycleLength': 28,
        'defaultPeriodLength': 5,
        'createdAt': FieldValue.serverTimestamp(),
      })
      ..set(_user(uid), {'activeProfileId': ref.id}, SetOptions(merge: true));
    await batch.commit();
    return ref.id;
  }

  Future<String> createInvite({required String uid, required String profileId, DateTime? now}) async {
    final code = generateInviteCode(random: random);
    final expiresAt = (now ?? DateTime.now()).add(inviteValidity);
    await _db.collection('invites').doc(code).set({
      'profileId': profileId,
      'createdBy': uid,
      'expiresAt': Timestamp.fromDate(expiresAt),
    });
    return code;
  }

  Future<void> joinWithCode({required String uid, required String rawCode, DateTime? now}) async {
    final code = normalizeInviteCode(rawCode);
    if (code.isEmpty) throw const JoinException('Kode undangan tidak ditemukan.');
    final invite = await _db.collection('invites').doc(code).get();
    if (!invite.exists) throw const JoinException('Kode undangan tidak ditemukan.');

    final data = invite.data()!;
    final expiresAt = (data['expiresAt'] as Timestamp).toDate();
    if ((now ?? DateTime.now()).isAfter(expiresAt)) {
      throw const JoinException('Kode undangan sudah kedaluwarsa.');
    }

    final profileId = data['profileId'] as String;
    final batch = _db.batch()
      ..update(_profile(profileId), {
        'memberUids': FieldValue.arrayUnion([uid]),
        'joinedWithCode': code, // dibaca Security Rules untuk validasi
      })
      ..set(_user(uid), {'activeProfileId': profileId}, SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> sendSignal({required String profileId, required CoupleSignal? signal}) =>
      _profile(profileId).update({
        'activeSignal': signal?.name,
        'signalUpdatedAt': FieldValue.serverTimestamp(),
        'signalReaction': null,
      });

  Future<void> sendReaction({required String profileId, required PartnerReaction? reaction}) =>
      _profile(profileId).update({
        'signalReaction': reaction?.name,
      });
}
