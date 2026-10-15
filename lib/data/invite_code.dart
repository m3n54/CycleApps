import 'dart:math';

/// Tanpa 0/O/1/I agar mudah dibacakan.
const inviteAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

String generateInviteCode({Random? random, int length = 6}) {
  final r = random ?? Random.secure();
  return List.generate(length, (_) => inviteAlphabet[r.nextInt(inviteAlphabet.length)]).join();
}

String normalizeInviteCode(String input) =>
    input.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
