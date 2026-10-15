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
    expect(find.text('2 anggota'), findsOneWidget);
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

  testWidgets('sign out clears the user', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    expect(auth.currentUser, isNull);
  });
}
