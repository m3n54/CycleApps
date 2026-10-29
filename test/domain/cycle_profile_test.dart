import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/domain/cycle_mascot.dart';
import 'package:siklus/domain/cycle_profile.dart';

void main() {
  group('CycleProfile', () {
    test('constructs with defaults and fromMap deserializes correctly', () {
      const direct = CycleProfile(
        id: 'p0',
        ownerUid: 'user-0',
        memberUids: ['user-0'],
        name: 'Default Profile',
      );
      expect(direct.defaultCycleLength, 28);
      expect(direct.defaultPeriodLength, 5);
      expect(direct.partnerName, '');
      expect(direct.selectedMascot, MascotCharacter.mochiKitten);
      expect(direct.anniversaryDate, isNull);

      final profile = CycleProfile.fromMap('p1', {
        'ownerUid': 'user-1',
        'memberUids': ['user-1', 'user-2'],
        'name': 'My Cycle',
        'partnerName': 'Love',
        'defaultCycleLength': 30,
        'defaultPeriodLength': 6,
        'selectedMascot': 'babyDino',
        'anniversaryDate': '2024-05-20',
      });

      expect(profile.id, 'p1');
      expect(profile.ownerUid, 'user-1');
      expect(profile.memberUids, ['user-1', 'user-2']);
      expect(profile.name, 'My Cycle');
      expect(profile.partnerName, 'Love');
      expect(profile.defaultCycleLength, 30);
      expect(profile.defaultPeriodLength, 6);
      expect(profile.selectedMascot, MascotCharacter.babyDino);
      expect(profile.anniversaryDate, DateTime(2024, 5, 20));
    });

    test('fromMap uses defaults when optional fields missing', () {
      final profile = CycleProfile.fromMap('p2', {
        'ownerUid': 'user-3',
      });

      expect(profile.id, 'p2');
      expect(profile.ownerUid, 'user-3');
      expect(profile.memberUids, isEmpty);
      expect(profile.name, '');
      expect(profile.partnerName, '');
      expect(profile.defaultCycleLength, 28);
      expect(profile.defaultPeriodLength, 5);
      expect(profile.selectedMascot, MascotCharacter.mochiKitten);
      expect(profile.anniversaryDate, isNull);
    });

    test('copyWith updates new fields properly', () {
      const base = CycleProfile(
        id: 'p3',
        ownerUid: 'u3',
        memberUids: ['u3'],
        name: 'Profile',
      );
      final updated = base.copyWith(
        partnerName: 'Dear',
        selectedMascot: MascotCharacter.chibiGirl,
        anniversaryDate: DateTime(2023, 1, 1),
      );
      expect(updated.partnerName, 'Dear');
      expect(updated.selectedMascot, MascotCharacter.chibiGirl);
      expect(updated.anniversaryDate, DateTime(2023, 1, 1));
    });
  });
}
