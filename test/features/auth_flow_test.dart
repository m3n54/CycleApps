import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:siklus/features/auth/auth_gate.dart';
import 'package:siklus/features/auth/login_screen.dart';
import 'package:siklus/features/common/widgets/cycle_logo.dart';
import 'package:siklus/features/home/home_shell.dart';
import 'package:siklus/features/onboarding/onboarding_screen.dart';
import 'package:siklus/state/providers.dart';

Widget harness(MockFirebaseAuth auth, FakeFirebaseFirestore db, Widget child) => ProviderScope(
      overrides: [
        firebaseAuthProvider.overrideWithValue(auth),
        firestoreProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(DateTime(2026, 10, 15)),
      ],
      child: MaterialApp(home: child),
    );

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  testWidgets('signed out → LoginScreen with CycleApp branding', (tester) async {
    await tester.pumpWidget(harness(MockFirebaseAuth(), FakeFirebaseFirestore(), const AuthGate()));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('CycleApp'), findsOneWidget);
    expect(find.byType(CycleLogo), findsOneWidget);
    expect(find.text('Lacak siklus bulanan & terhubung harmonis dengan pasangan'), findsOneWidget);
  });

  testWidgets('signed in without profile → OnboardingScreen', (tester) async {
    final auth = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'u1', email: 'a@b.co'));
    await tester.pumpWidget(harness(auth, FakeFirebaseFirestore(), const AuthGate()));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('signed in with profile → HomeShell', (tester) async {
    final auth = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'u1', email: 'a@b.co'));
    final db = FakeFirebaseFirestore();
    await db.doc('users/u1').set({'activeProfileId': 'p1'});
    await db.doc('profiles/p1').set({'ownerUid': 'u1', 'memberUids': ['u1'], 'name': 'A'});
    await tester.pumpWidget(harness(auth, db, const AuthGate()));
    await tester.pumpAndSettle();
    expect(find.byType(HomeShell), findsOneWidget);
  });

  testWidgets('login screen validates empty fields', (tester) async {
    await tester.pumpWidget(harness(MockFirebaseAuth(), FakeFirebaseFirestore(), const LoginScreen()));
    await tester.tap(find.text('Masuk'));
    await tester.pump();
    expect(find.text('Email dan password wajib diisi.'), findsOneWidget);
  });

  testWidgets('register from login screen signs the user in', (tester) async {
    final auth = MockFirebaseAuth();
    await tester.pumpWidget(harness(auth, FakeFirebaseFirestore(), const LoginScreen()));
    await tester.enterText(find.byKey(const Key('email')), 'a@b.co');
    await tester.enterText(find.byKey(const Key('password')), 'rahasia1');
    await tester.tap(find.text('Daftar akun baru'));
    await tester.pumpAndSettle();
    expect(auth.currentUser?.email, 'a@b.co');
  });
}
