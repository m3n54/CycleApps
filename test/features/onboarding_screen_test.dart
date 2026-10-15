import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/features/onboarding/onboarding_screen.dart';
import 'package:siklus/state/providers.dart';

void main() {
  late MockFirebaseAuth auth;
  late FakeFirebaseFirestore db;

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        firebaseAuthProvider.overrideWithValue(auth),
        firestoreProvider.overrideWithValue(db),
      ],
      child: const MaterialApp(home: OnboardingScreen()),
    ));
    await tester.pumpAndSettle();
  }

  setUp(() {
    auth = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'u1', email: 'a@b.co'));
    db = FakeFirebaseFirestore();
  });

  testWidgets('creating a profile sets activeProfileId', (tester) async {
    await pump(tester);
    await tester.enterText(find.byKey(const Key('profileName')), 'Sari');
    await tester.tap(find.text('Buat profil'));
    await tester.pumpAndSettle();
    final user = await db.doc('users/u1').get();
    final profileId = user.data()!['activeProfileId'] as String;
    final profile = await db.doc('profiles/$profileId').get();
    expect(profile.data()!['name'], 'Sari');
  });

  testWidgets('empty name shows a message', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Buat profil'));
    await tester.pump();
    expect(find.text('Isi nama profil.'), findsOneWidget);
  });

  testWidgets('joining with a valid code adds the user', (tester) async {
    await db.doc('profiles/p1').set({'ownerUid': 'alice', 'memberUids': ['alice'], 'name': 'A'});
    await db.doc('invites/ABC234').set({
      'profileId': 'p1',
      'createdBy': 'alice',
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 1))),
    });
    await pump(tester);
    await tester.enterText(find.byKey(const Key('inviteCode')), 'abc 234');
    await tester.tap(find.text('Gabung'));
    await tester.pumpAndSettle();
    final profile = await db.doc('profiles/p1').get();
    expect(profile.data()!['memberUids'], ['alice', 'u1']);
  });

  testWidgets('unknown code shows the JoinException message', (tester) async {
    await pump(tester);
    await tester.enterText(find.byKey(const Key('inviteCode')), 'ZZZZZZ');
    await tester.tap(find.text('Gabung'));
    await tester.pumpAndSettle();
    expect(find.text('Kode undangan tidak ditemukan.'), findsOneWidget);
  });
}
