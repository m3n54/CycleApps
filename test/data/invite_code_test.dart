import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/data/invite_code.dart';

void main() {
  test('generates 6 chars from the unambiguous alphabet', () {
    for (var i = 0; i < 200; i++) {
      final code = generateInviteCode();
      expect(code.length, 6);
      expect(code.split('').every(inviteAlphabet.contains), isTrue, reason: code);
    }
  });

  test('is deterministic for a seeded Random', () {
    expect(generateInviteCode(random: Random(1)), generateInviteCode(random: Random(1)));
  });

  test('normalize uppercases and strips spaces/dashes', () {
    expect(normalizeInviteCode(' ab-c 23x '), 'ABC23X');
  });
}
