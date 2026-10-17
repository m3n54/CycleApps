import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:siklus/domain/couple_interaction.dart';
import 'package:siklus/domain/cycle_profile.dart';
import 'package:siklus/domain/day_entry.dart';
import 'package:siklus/features/couple/couple_space_screen.dart';
import 'package:siklus/features/home/home_screen.dart';
import 'package:siklus/features/insights/insights_screen.dart';
import 'package:siklus/state/providers.dart';
import 'package:siklus/theme/cycle_theme.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  testWidgets('Partner HomeScreen shows Kirim Perhatian button and NO Catat Hari Ini button', (tester) async {
    final db = FakeFirebaseFirestore();
    final partnerUser = MockUser(uid: 'u2', email: 'partner@example.com');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayProvider.overrideWithValue(DateTime(2026, 10, 17)),
          firestoreProvider.overrideWithValue(db),
          activeProfileIdProvider.overrideWith((ref) => Stream.value('p1')),
          activeProfileProvider.overrideWith(
            (ref) => Stream.value(
              const CycleProfile(
                id: 'p1',
                name: 'Nata',
                ownerUid: 'u1',
                memberUids: ['u1', 'u2'],
              ),
            ),
          ),
          dayEntriesProvider.overrideWith((ref) => Stream.value(const <DayEntry>[])),
          authStateProvider.overrideWith((ref) => Stream.value(partnerUser)),
        ],
        child: MaterialApp(
          theme: CycleTheme.lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Catat Hari Ini is NOT rendered for partner
    expect(find.text('Catat Hari Ini'), findsNothing);
    // Verify Kirim Perhatian IS rendered
    expect(find.textContaining('Kirim Perhatian'), findsOneWidget);
    expect(find.text('Panduan Pasangan Hari Ini'), findsOneWidget);

    // Tapping Kirim Perhatian navigates to CoupleSpaceScreen
    await tester.tap(find.textContaining('Kirim Perhatian'));
    await tester.pumpAndSettle();
    expect(find.byType(CoupleSpaceScreen), findsOneWidget);
  });

  testWidgets('Owner HomeScreen shows Catat Hari Ini and NO Kirim Perhatian button', (tester) async {
    final db = FakeFirebaseFirestore();
    final ownerUser = MockUser(uid: 'u1', email: 'owner@example.com');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayProvider.overrideWithValue(DateTime(2026, 10, 17)),
          firestoreProvider.overrideWithValue(db),
          activeProfileIdProvider.overrideWith((ref) => Stream.value('p1')),
          activeProfileProvider.overrideWith(
            (ref) => Stream.value(
              const CycleProfile(
                id: 'p1',
                name: 'Nata',
                ownerUid: 'u1',
                memberUids: ['u1', 'u2'],
              ),
            ),
          ),
          dayEntriesProvider.overrideWith((ref) => Stream.value(const <DayEntry>[])),
          authStateProvider.overrideWith((ref) => Stream.value(ownerUser)),
        ],
        child: MaterialApp(
          theme: CycleTheme.lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Catat Hari Ini'), findsOneWidget);
    expect(find.textContaining('Kirim Perhatian'), findsNothing);
  });

  testWidgets('Incoming unread love interaction shows top banner and tapping it opens CoupleSpaceScreen', (tester) async {
    final db = FakeFirebaseFirestore();
    final partnerUser = MockUser(uid: 'u2', email: 'partner@example.com');

    final interaction = CoupleInteraction(
      id: 'i1',
      senderUid: 'u1',
      senderName: 'Nata',
      emoji: '🧸',
      text: 'Peluk erat dari jauh 🤗',
      createdAt: DateTime(2026, 10, 17, 10, 0),
      isRead: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayProvider.overrideWithValue(DateTime(2026, 10, 17)),
          firestoreProvider.overrideWithValue(db),
          activeProfileIdProvider.overrideWith((ref) => Stream.value('p1')),
          activeProfileProvider.overrideWith(
            (ref) => Stream.value(
              const CycleProfile(
                id: 'p1',
                name: 'Nata',
                ownerUid: 'u1',
                memberUids: ['u1', 'u2'],
              ),
            ),
          ),
          coupleInteractionsProvider.overrideWith((ref) => Stream.value([interaction])),
          dayEntriesProvider.overrideWith((ref) => Stream.value(const <DayEntry>[])),
          authStateProvider.overrideWith((ref) => Stream.value(partnerUser)),
        ],
        child: MaterialApp(
          theme: CycleTheme.lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('baru saja mengirim:'), findsOneWidget);
    expect(find.textContaining('Peluk erat dari jauh'), findsOneWidget);

    await tester.tap(find.textContaining('baru saja mengirim:'));
    await tester.pumpAndSettle();
    expect(find.byType(CoupleSpaceScreen), findsOneWidget);
  });

  testWidgets('TodaySummaryCard has link to InsightsScreen and tapping opens it', (tester) async {
    final db = FakeFirebaseFirestore();
    final ownerUser = MockUser(uid: 'u1', email: 'owner@example.com');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayProvider.overrideWithValue(DateTime(2026, 10, 17)),
          firestoreProvider.overrideWithValue(db),
          activeProfileIdProvider.overrideWith((ref) => Stream.value('p1')),
          activeProfileProvider.overrideWith(
            (ref) => Stream.value(
              const CycleProfile(
                id: 'p1',
                name: 'Nata',
                ownerUid: 'u1',
                memberUids: ['u1'],
              ),
            ),
          ),
          dayEntriesProvider.overrideWith((ref) => Stream.value(const <DayEntry>[])),
          authStateProvider.overrideWith((ref) => Stream.value(ownerUser)),
        ],
        child: MaterialApp(
          theme: CycleTheme.lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final linkFinder = find.textContaining('Lihat Analisis & Grafik Siklus Lengkap');
    expect(linkFinder, findsOneWidget);
    await tester.ensureVisible(linkFinder);
    await tester.tap(linkFinder);
    await tester.pumpAndSettle();
    expect(find.byType(InsightsScreen), findsOneWidget);
  });

  testWidgets('Partner HomeScreen renders without overflow on 320px narrow mobile viewport', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final db = FakeFirebaseFirestore();
    final partnerUser = MockUser(uid: 'u2', email: 'partner@example.com');
    final interaction = CoupleInteraction(
      id: 'i1',
      senderUid: 'u1',
      senderName: 'Nata',
      emoji: '🧸',
      text: 'Peluk erat dari jauh 🤗',
      createdAt: DateTime(2026, 10, 17, 10, 0),
      isRead: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayProvider.overrideWithValue(DateTime(2026, 10, 17)),
          firestoreProvider.overrideWithValue(db),
          activeProfileIdProvider.overrideWith((ref) => Stream.value('p1')),
          activeProfileProvider.overrideWith(
            (ref) => Stream.value(
              const CycleProfile(
                id: 'p1',
                name: 'Nata Sangat Panjang Sekali Namanya',
                ownerUid: 'u1',
                memberUids: ['u1', 'u2'],
              ),
            ),
          ),
          coupleInteractionsProvider.overrideWith((ref) => Stream.value([interaction])),
          dayEntriesProvider.overrideWith((ref) => Stream.value(const <DayEntry>[])),
          authStateProvider.overrideWith((ref) => Stream.value(partnerUser)),
        ],
        child: MaterialApp(
          theme: CycleTheme.lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Kirim Perhatian'), findsOneWidget);
  });
}
