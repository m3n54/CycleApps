import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:siklus/domain/couple_interaction.dart';
import 'package:siklus/features/calendar/calendar_screen.dart';
import 'package:siklus/features/couple/couple_space_screen.dart';
import 'package:siklus/features/home/home_screen.dart';
import 'package:siklus/features/home/home_shell.dart';
import 'package:siklus/features/settings/settings_screen.dart';
import 'package:siklus/state/providers.dart';
import 'package:siklus/theme/cycle_theme.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  testWidgets('HomeShell renders all 4 navigation destinations and switches tabs', (tester) async {
    final db = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'u1', email: 'a@b.co'));
    await db.doc('users/u1').set({'activeProfileId': 'p1'});
    await db.doc('profiles/p1').set({'ownerUid': 'u1', 'memberUids': ['u1'], 'name': 'Sari'});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
          firestoreProvider.overrideWithValue(db),
          todayProvider.overrideWithValue(DateTime(2026, 10, 15)),
        ],
        child: MaterialApp(
          theme: CycleTheme.lightTheme,
          home: const HomeShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Kalender'), findsOneWidget);
    expect(find.text('Ruang Pasangan'), findsOneWidget);
    expect(find.text('Pengaturan'), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.text('Kalender'));
    await tester.pumpAndSettle();
    expect(find.byType(CalendarScreen), findsOneWidget);

    await tester.tap(find.text('Ruang Pasangan'));
    await tester.pumpAndSettle();
    expect(find.byType(CoupleSpaceScreen), findsOneWidget);

    await tester.tap(find.text('Pengaturan'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('HomeShell shows Badge on Ruang Pasangan when unread interactions exist', (tester) async {
    final db = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'u2', email: 'partner@b.co'));
    await db.doc('users/u2').set({'activeProfileId': 'p1'});
    await db.doc('profiles/p1').set({'ownerUid': 'u1', 'memberUids': ['u1', 'u2'], 'name': 'Sari'});

    final unreadInteraction = CoupleInteraction(
      id: 'i1',
      senderUid: 'u1',
      senderName: 'Sari',
      emoji: '💖',
      text: 'Semangat kerjanya yaa',
      createdAt: DateTime.now(),
      isRead: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
          firestoreProvider.overrideWithValue(db),
          todayProvider.overrideWithValue(DateTime(2026, 10, 15)),
          coupleInteractionsProvider.overrideWith((ref) => Stream.value([unreadInteraction])),
        ],
        child: MaterialApp(
          theme: CycleTheme.lightTheme,
          home: const HomeShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Badge), findsWidgets);
  });
}
