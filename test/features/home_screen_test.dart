import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:siklus/features/home/home_screen.dart';
import 'package:siklus/features/home/widgets/cycle_dial.dart';
import 'package:siklus/features/home/widgets/mascot_companion_card.dart';
import 'package:siklus/features/home/widgets/phase_card.dart';
import 'package:siklus/features/home/widgets/today_summary_card.dart';
import 'package:siklus/features/log/day_log_screen.dart';
import 'package:siklus/state/providers.dart';
import 'package:siklus/theme/cycle_theme.dart';

void main() {
  late FakeFirebaseFirestore db;
  late MockFirebaseAuth auth;
  final fixedToday = DateTime(2026, 10, 15);

  setUpAll(() => initializeDateFormatting('id_ID'));

  setUp(() async {
    auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'u1', email: 'siti@example.com'),
    );
    db = FakeFirebaseFirestore();
    await db.doc('users/u1').set({'activeProfileId': 'p1'});
    await db.doc('profiles/p1').set({
      'ownerUid': 'u1',
      'memberUids': ['u1'],
      'name': 'Siti',
    });
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        firebaseAuthProvider.overrideWithValue(auth),
        firestoreProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(fixedToday),
      ],
      child: MaterialApp(
        theme: CycleTheme.lightTheme,
        home: const HomeScreen(),
      ),
    );
  }

  testWidgets('renders CycleDial, PhaseCard, TodaySummaryCard, and Catat Hari Ini button (empty state)',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byType(CycleDial), findsOneWidget);
    expect(find.byType(MascotCompanionCard), findsOneWidget);
    expect(find.byType(PhaseCard), findsOneWidget);
    expect(find.byType(TodaySummaryCard), findsOneWidget);
    expect(find.text('Catat Hari Ini'), findsOneWidget);
    expect(find.byIcon(Icons.edit_calendar_rounded), findsOneWidget);

    expect(find.text('Halo, Siti'), findsOneWidget);
    expect(find.text('Mulai Siklus'), findsOneWidget);
    expect(find.text('Belum ada catatan haid'), findsOneWidget);
    expect(
      find.text('Belum ada catatan hari ini. Luangkan 1 menit untuk mencatat kondisi tubuh Anda.'),
      findsOneWidget,
    );
  });

  testWidgets('renders active cycle day, phase info, and today summary chips when entries exist',
      (tester) async {
    await db.doc('profiles/p1/days/2026-10-14').set({
      'date': '2026-10-14',
      'flow': 'medium',
      'symptoms': <String>[],
      'moods': <String>[],
      'energy': 'normal',
      'note': '',
      'updatedBy': 'u1',
    });
    await db.doc('profiles/p1/days/2026-10-15').set({
      'date': '2026-10-15',
      'flow': 'heavy',
      'symptoms': ['cramps'],
      'moods': ['calm'],
      'energy': 'low',
      'note': 'Istirahat di rumah',
      'updatedBy': 'u1',
    });

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Hari ke-2'), findsOneWidget);
    expect(find.text('Menstruasi'), findsOneWidget);
    expect(find.text('Fase Menstruasi'), findsOneWidget);
    expect(find.text('Haid berikutnya ~27 hari'), findsOneWidget);

    // TodaySummaryCard chips
    expect(find.text('Berat'), findsOneWidget);
    expect(find.text('Kram'), findsOneWidget);
    expect(find.text('Tenang'), findsOneWidget);
    expect(find.text('Lemas'), findsOneWidget);
    expect(find.text('Istirahat di rumah'), findsOneWidget);
  });

  testWidgets('tapping Catat Hari Ini opens DayLogScreen', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Catat Hari Ini'));
    await tester.pumpAndSettle();

    expect(find.byType(DayLogScreen), findsOneWidget);
  });

  testWidgets('changing mascot on HomeScreen updates profile in Firestore', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byType(MascotCompanionCard), findsOneWidget);
    expect(find.textContaining('Mochi Kitten'), findsOneWidget);

    // Open mascot picker
    await tester.tap(find.byKey(const Key('changeMascotButton')));
    await tester.pumpAndSettle();

    expect(find.text('Baby Dino'), findsOneWidget);
    await tester.tap(find.text('Baby Dino'));
    await tester.pumpAndSettle();

    final profileSnap = await db.doc('profiles/p1').get();
    expect(profileSnap.data()?['selectedMascot'], 'babyDino');
  });
}
