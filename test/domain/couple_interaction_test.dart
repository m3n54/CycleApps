// test/domain/couple_interaction_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/domain/couple_interaction.dart';

void main() {
  test('CoupleInteraction serializes and deserializes correctly', () {
    final now = DateTime(2026, 10, 17, 10, 30);
    final interaction = CoupleInteraction(
      id: 'i1',
      senderUid: 'u1',
      senderName: 'Nata',
      emoji: '🧋',
      text: 'Boba favorit meluncuurr! 🛵💨',
      customNote: 'Jangan lupa senyum yaa',
      replyEmoji: '🧋',
      replyText: 'Benerannn mawuuuu 🧋✨',
      repliedAt: now.add(const Duration(minutes: 5)),
      createdAt: now,
      isRead: false,
    );

    final map = interaction.toMap();
    expect(map['senderUid'], 'u1');
    expect(map['emoji'], '🧋');

    final reconstructed = CoupleInteraction.fromMap('i1', map);
    expect(reconstructed.id, 'i1');
    expect(reconstructed.text, 'Boba favorit meluncuurr! 🛵💨');
    expect(reconstructed.replyEmoji, '🧋');
    expect(reconstructed.customNote, 'Jangan lupa senyum yaa');
  });

  test('CoupleCareCatalog contains warm and cute default stickers and replies', () {
    expect(CoupleCareCatalog.defaultCareStickers.isNotEmpty, isTrue);
    expect(CoupleCareCatalog.defaultReplyStickers.isNotEmpty, isTrue);
    expect(
      CoupleCareCatalog.defaultReplyStickers.any((s) => s.text.contains('Benerannn mawuuuu')),
      isTrue,
    );
    expect(
      CoupleCareCatalog.defaultReplyStickers.any((s) => s.text.contains('mauu ditemenin')),
      isTrue,
    );
  });
}
