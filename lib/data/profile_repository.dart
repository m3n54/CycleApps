import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/couple_care.dart';
import '../domain/couple_interaction.dart';
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

  Stream<List<CoupleInteraction>> watchInteractions(String profileId, {int limit = 50}) {
    return _db
        .collection('profiles')
        .doc(profileId)
        .collection('interactions')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CoupleInteraction.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<String> sendInteraction({
    required String profileId,
    required String senderUid,
    required String senderName,
    required String emoji,
    required String text,
    String? customNote,
    DateTime? now,
  }) async {
    final interactionRef = _db
        .collection('profiles')
        .doc(profileId)
        .collection('interactions')
        .doc();
    final timestamp = (now ?? DateTime.now()).toIso8601String();
    final interactionMap = <String, dynamic>{
      'senderUid': senderUid,
      'senderName': senderName,
      'emoji': emoji,
      'text': text,
      'customNote': customNote,
      'replyEmoji': null,
      'replyText': null,
      'repliedAt': null,
      'createdAt': timestamp,
      'isRead': false,
    };
    final lastInteractionMap = <String, dynamic>{
      'id': interactionRef.id,
      'senderUid': senderUid,
      'senderName': senderName,
      'emoji': emoji,
      'text': text,
      'customNote': ?customNote,
      'createdAt': timestamp,
    };

    final batch = _db.batch()
      ..set(interactionRef, interactionMap)
      ..update(_profile(profileId), {
        'lastInteraction': lastInteractionMap,
      });
    await batch.commit();

    return interactionRef.id;
  }

  Future<void> replyInteraction({
    required String profileId,
    required String interactionId,
    required String replyEmoji,
    required String replyText,
    DateTime? now,
  }) async {
    final repliedAtStr = (now ?? DateTime.now()).toIso8601String();
    final interactionRef = _db
        .collection('profiles')
        .doc(profileId)
        .collection('interactions')
        .doc(interactionId);
    await interactionRef.update({
      'replyEmoji': replyEmoji,
      'replyText': replyText,
      'repliedAt': repliedAtStr,
      'isRead': true,
    });

    try {
      final profileDoc = await _profile(profileId).get();
      final lastInteraction = profileDoc.data()?['lastInteraction'];
      if (lastInteraction is Map && lastInteraction['id'] == interactionId) {
        final updated = Map<String, dynamic>.from(lastInteraction)
          ..['replyEmoji'] = replyEmoji
          ..['replyText'] = replyText
          ..['repliedAt'] = repliedAtStr;
        await _profile(profileId).update({'lastInteraction': updated});
      }
    } catch (_) {
      // Best effort update on cached lastInteraction in profile doc
    }
  }

  Future<void> addCustomSticker({
    required String profileId,
    required CustomCoupleSticker sticker,
  }) =>
      _profile(profileId).update({
        'customStickers': FieldValue.arrayUnion([sticker.toMap()]),
      });

  Future<void> deleteCustomSticker({
    required String profileId,
    required String stickerId,
  }) async {
    final doc = await _profile(profileId).get();
    final list = List<Map<String, dynamic>>.from(
      (doc.data()?['customStickers'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e)),
    );
    list.removeWhere((item) => item['id'] == stickerId);
    await _profile(profileId).update({'customStickers': list});
  }
}
