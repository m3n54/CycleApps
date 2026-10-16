import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/features/settings/settings_screen.dart';
import 'package:siklus/state/providers.dart';

void main() {
  late FakeFirebaseFirestore db;
  late MockFirebaseAuth auth;

  setUp(() async {
    db = FakeFirebaseFirestore();
    auth = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'u1', email: 'a@b.co'));
    await db.doc('users/u1').set({'activeProfileId': 'p1'});
    await db.doc('profiles/p1').set({'ownerUid': 'u1', 'memberUids': ['u1', 'u2'], 'name': 'Sari'});
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        firebaseAuthProvider.overrideWithValue(auth),
        firestoreProvider.overrideWithValue(db),
      ],
      child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('shows profile name and member count', (tester) async {
    await pump(tester);
    expect(find.text('Sari'), findsOneWidget);
    expect(find.textContaining('2 anggota'), findsOneWidget);
  });

  testWidgets('invite creates a code and shows it', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Undang pasangan'));
    await tester.pumpAndSettle();
    final invites = await db.collection('invites').get();
    expect(invites.docs.length, 1);
    final code = invites.docs.single.id;
    expect(invites.docs.single.data()['profileId'], 'p1');
    expect(find.text(code), findsOneWidget);
    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();
    expect(find.text(code), findsNothing);
  });

  testWidgets('join with code updates active profile and members', (tester) async {
    await db.doc('profiles/p2').set({'ownerUid': 'u2', 'memberUids': ['u2'], 'name': 'Nata'});
    await db.doc('invites/NATA99').set({
      'profileId': 'p2',
      'createdBy': 'u2',
      'expiresAt': DateTime.now().add(const Duration(hours: 12)),
    });

    await pump(tester);
    expect(find.text('Gabung dengan kode undangan'), findsOneWidget);
    await tester.tap(find.text('Gabung dengan kode undangan'));
    await tester.pumpAndSettle();

    expect(find.text('Gabung Profil Pasangan'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('joinCodeInput')), 'NATA99');
    await tester.tap(find.byKey(const Key('submitJoinCodeBtn')));
    await tester.pumpAndSettle();

    final userDoc = await db.doc('users/u1').get();
    expect(userDoc.data()?['activeProfileId'], 'p2');
    final p2Doc = await db.doc('profiles/p2').get();
    expect((p2Doc.data()?['memberUids'] as List).contains('u1'), isTrue);
  });

  testWidgets('sign out clears the user', (tester) async {
    await pump(tester);
    await tester.scrollUntilVisible(find.text('Keluar'), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    expect(auth.currentUser, isNull);
  });
}
