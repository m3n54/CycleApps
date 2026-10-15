import 'package:flutter_test/flutter_test.dart';
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

      final profile = CycleProfile.fromMap('p1', {
        'ownerUid': 'user-1',
        'memberUids': ['user-1', 'user-2'],
        'name': 'My Cycle',
        'defaultCycleLength': 30,
        'defaultPeriodLength': 6,
      });

      expect(profile.id, 'p1');
      expect(profile.ownerUid, 'user-1');
      expect(profile.memberUids, ['user-1', 'user-2']);
      expect(profile.name, 'My Cycle');
      expect(profile.defaultCycleLength, 30);
      expect(profile.defaultPeriodLength, 6);
    });

    test('fromMap uses defaults when optional fields missing', () {
      final profile = CycleProfile.fromMap('p2', {
        'ownerUid': 'user-3',
      });

      expect(profile.id, 'p2');
      expect(profile.ownerUid, 'user-3');
      expect(profile.memberUids, isEmpty);
      expect(profile.name, '');
      expect(profile.defaultCycleLength, 28);
      expect(profile.defaultPeriodLength, 5);
    });
  });
}
