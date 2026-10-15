import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/data/profile_repository.dart';

void main() {
  late FakeFirebaseFirestore db;
  late ProfileRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = ProfileRepository(db, random: Random(42));
  });

  test('createProfile creates profile with owner as sole member and sets active profile', () async {
    final id = await repo.createProfile(uid: 'alice', name: '  Alice ');
    final profile = await db.collection('profiles').doc(id).get();
    expect(profile.data()!['ownerUid'], 'alice');
    expect(profile.data()!['memberUids'], ['alice']);
    expect(profile.data()!['name'], 'Alice');
    expect(profile.data()!['defaultCycleLength'], 28);
    expect(await repo.watchActiveProfileId('alice').first, id);
    final model = await repo.watchProfile(id).first;
    expect(model!.memberUids, ['alice']);
  });

  test('createInvite stores a 24h invite pointing at the profile', () async {
    final now = DateTime(2026, 10, 15, 10);
    final code = await repo.createInvite(uid: 'alice', profileId: 'p1', now: now);
    final invite = await db.collection('invites').doc(code).get();
    expect(code.length, 6);
    expect(invite.data()!['profileId'], 'p1');
    expect(invite.data()!['createdBy'], 'alice');
    expect((invite.data()!['expiresAt'] as Timestamp).toDate(), now.add(const Duration(hours: 24)));
  });

  test('joinWithCode adds the user and switches their active profile', () async {
    final id = await repo.createProfile(uid: 'alice', name: 'Alice');
    final now = DateTime(2026, 10, 15, 10);
    final code = await repo.createInvite(uid: 'alice', profileId: id, now: now);

    await repo.joinWithCode(uid: 'bob', rawCode: code.toLowerCase(), now: now);

    final profile = await db.collection('profiles').doc(id).get();
    expect(profile.data()!['memberUids'], ['alice', 'bob']);
    expect(profile.data()!['joinedWithCode'], code);
    expect(await repo.watchActiveProfileId('bob').first, id);
  });

  test('joinWithCode rejects unknown codes', () async {
    expect(
      () => repo.joinWithCode(uid: 'bob', rawCode: 'ZZZZZZ'),
      throwsA(isA<JoinException>().having((e) => e.message, 'message', 'Kode undangan tidak ditemukan.')),
    );
  });

  test('joinWithCode rejects expired codes', () async {
    final created = DateTime(2026, 10, 15, 10);
    final code = await repo.createInvite(uid: 'alice', profileId: 'p1', now: created);
    expect(
      () => repo.joinWithCode(uid: 'bob', rawCode: code, now: created.add(const Duration(hours: 25))),
      throwsA(isA<JoinException>().having((e) => e.message, 'message', 'Kode undangan sudah kedaluwarsa.')),
    );
  });
}
