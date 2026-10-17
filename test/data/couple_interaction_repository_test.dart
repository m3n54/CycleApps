// test/data/couple_interaction_repository_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/data/profile_repository.dart';
import 'package:siklus/domain/couple_interaction.dart';

void main() {
  late FakeFirebaseFirestore db;
  late ProfileRepository repo;

  setUp(() async {
    db = FakeFirebaseFirestore();
    repo = ProfileRepository(db);
    await db.doc('profiles/p1').set({
      'name': 'Nata',
      'ownerUid': 'u1',
      'memberUids': ['u1', 'u2'],
    });
  });

  test('sendInteraction adds interaction document and updates lastInteraction on profile', () async {
    final id = await repo.sendInteraction(
      profileId: 'p1',
      senderUid: 'u2',
      senderName: 'Menza',
      emoji: '🧋',
      text: 'Boba meluncur! 🛵',
      customNote: 'Rasa taro kesukaanmu',
    );

    expect(id.isNotEmpty, isTrue);
    final doc = await db.doc('profiles/p1/interactions/$id').get();
    expect(doc.exists, isTrue);
    expect(doc.data()?['text'], 'Boba meluncur! 🛵');

    final profileDoc = await db.doc('profiles/p1').get();
    expect(profileDoc.data()?['lastInteraction']?['emoji'], '🧋');
  });

  test('replyInteraction updates reply fields on interaction document', () async {
    final id = await repo.sendInteraction(
      profileId: 'p1',
      senderUid: 'u2',
      senderName: 'Menza',
      emoji: '🧸',
      text: 'Kompres hangat siap!',
    );

    await repo.replyInteraction(
      profileId: 'p1',
      interactionId: id,
      replyEmoji: '💖',
      replyText: 'Loveee youu soo muchh 💖🥹',
    );

    final doc = await db.doc('profiles/p1/interactions/$id').get();
    expect(doc.data()?['replyEmoji'], '💖');
    expect(doc.data()?['replyText'], 'Loveee youu soo muchh 💖🥹');
  });

  test('addCustomSticker and deleteCustomSticker manage profile customStickers array', () async {
    const sticker = CustomCoupleSticker(
      id: 's_custom_1',
      emoji: '🍜',
      text: 'Mau mie ayam yuk',
      isReply: false,
    );

    await repo.addCustomSticker(profileId: 'p1', sticker: sticker);
    var profileDoc = await db.doc('profiles/p1').get();
    var list = profileDoc.data()?['customStickers'] as List?;
    expect(list?.length, 1);
    expect(list?.first['id'], 's_custom_1');

    await repo.deleteCustomSticker(profileId: 'p1', stickerId: 's_custom_1');
    profileDoc = await db.doc('profiles/p1').get();
    list = profileDoc.data()?['customStickers'] as List?;
    expect(list?.isEmpty, isTrue);
  });

  test('watchInteractions streams interaction documents ordered by createdAt descending', () async {
    final stream = repo.watchInteractions('p1');
    final initialList = await stream.first;
    expect(initialList.isEmpty, isTrue);

    await repo.sendInteraction(
      profileId: 'p1',
      senderUid: 'u2',
      senderName: 'Menza',
      emoji: '🧋',
      text: 'Pesan 1',
    );
    await repo.sendInteraction(
      profileId: 'p1',
      senderUid: 'u1',
      senderName: 'Nata',
      emoji: '🧸',
      text: 'Pesan 2',
    );

    final updatedList = await repo.watchInteractions('p1').first;
    expect(updatedList.length, 2);
    expect(updatedList.first.text, 'Pesan 2');
    expect(updatedList.last.text, 'Pesan 1');
  });
}

