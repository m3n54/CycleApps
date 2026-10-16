import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/data/profile_repository.dart';
import 'package:siklus/domain/couple_care.dart';
import 'package:siklus/domain/cycle_phase.dart';
import 'package:siklus/domain/cycle_profile.dart';
import 'package:siklus/domain/day_entry.dart';

void main() {
  test('DayEntry serializes and deserializes selfCareCompleted and supports copyWith', () {
    const entry = DayEntry(
      date: '2026-10-16',
      selfCareCompleted: {'warm_drink', 'early_sleep'},
    );
    expect(entry.isEmpty, isFalse);

    final map = entry.toMap();
    expect(map['selfCareCompleted'], ['early_sleep', 'warm_drink']);

    final restored = DayEntry.fromMap(map);
    expect(restored.selfCareCompleted, {'warm_drink', 'early_sleep'});

    final updated = restored.copyWith(selfCareCompleted: {'warm_drink'});
    expect(updated.selfCareCompleted, {'warm_drink'});
  });

  test('CycleProfile parses activeSignal, signalReaction, and checks isOwner', () {
    final profile = CycleProfile.fromMap('p1', {
      'ownerUid': 'alice',
      'memberUids': ['alice', 'bob'],
      'name': 'Alice',
      'defaultCycleLength': 28,
      'defaultPeriodLength': 5,
      'activeSignal': 'cravingSweet',
      'signalReaction': 'onTheWay',
    });

    expect(profile.isOwner('alice'), isTrue);
    expect(profile.isOwner('bob'), isFalse);
    expect(profile.hasPartner, isTrue);
    expect(profile.activeSignal, CoupleSignal.cravingSweet);
    expect(profile.signalReaction, PartnerReaction.onTheWay);
  });

  test('ProfileRepository sendSignal and sendReaction update Firestore profile doc', () async {
    final db = FakeFirebaseFirestore();
    final repo = ProfileRepository(db);
    final profileId = await repo.createProfile(uid: 'alice', name: 'Alice');

    await repo.sendSignal(profileId: profileId, signal: CoupleSignal.needHug);
    var current = await repo.watchProfile(profileId).first;
    expect(current?.activeSignal, CoupleSignal.needHug);
    expect(current?.signalReaction, isNull);

    await repo.sendReaction(profileId: profileId, reaction: PartnerReaction.hugSent);
    current = await repo.watchProfile(profileId).first;
    expect(current?.signalReaction, PartnerReaction.hugSent);
  });

  test('CoupleCareCatalog returns partner tips for all 4 cycle phases', () {
    for (final phase in CyclePhase.values) {
      final tip = CoupleCareCatalog.partnerTipForPhase(phase);
      expect(tip.title, isNotEmpty);
      expect(tip.actionSuggestion, isNotEmpty);
    }
  });
}
