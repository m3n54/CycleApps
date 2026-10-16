import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/data/day_repository.dart';
import 'package:siklus/data/profile_repository.dart';
import 'package:siklus/domain/couple_care.dart';
import 'package:siklus/domain/day_entry.dart';
import 'package:siklus/features/home/home_screen.dart';
import 'package:siklus/features/home/widgets/body_explainer_card.dart';
import 'package:siklus/features/home/widgets/couple_care_card.dart';
import 'package:siklus/features/home/widgets/self_care_checklist_card.dart';
import 'package:siklus/state/providers.dart';
import 'package:siklus/theme/cycle_theme.dart';

void main() {
  testWidgets(
      'Owner HomeScreen shows contextual greeting from yesterday, BodyExplainerCard, SelfCareChecklistCard, and sends CoupleSignal',
      (tester) async {
    final db = FakeFirebaseFirestore();
    final profileRepo = ProfileRepository(db);
    final dayRepo = DayRepository(db);
    final profileId = await profileRepo.createProfile(uid: 'alice', name: 'Alice');

    final mockUser = MockUser(uid: 'alice', email: 'alice@example.com');
    final today = DateTime(2026, 10, 16);

    await dayRepo.saveDay(
      profileId: profileId,
      uid: 'alice',
      entry: const DayEntry(
        date: '2026-10-15',
        flow: FlowLevel.medium,
        symptoms: {Symptom.cramps},
      ),
    );
    await dayRepo.saveDay(
      profileId: profileId,
      uid: 'alice',
      entry: const DayEntry(
        date: '2026-10-16',
        flow: FlowLevel.medium,
        symptoms: {Symptom.cramps, Symptom.bloating},
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayProvider.overrideWithValue(today),
          firestoreProvider.overrideWithValue(db),
          authStateProvider.overrideWith((_) => Stream.value(mockUser)),
          activeProfileIdProvider.overrideWith((_) => Stream.value(profileId)),
        ],
        child: MaterialApp(
          theme: CycleTheme.lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Contextual greeting remembers yesterday's cramps
    expect(find.textContaining('Halo, Alice'), findsOneWidget);
    expect(find.textContaining('kram'), findsWidgets);

    // 2. BodyExplainerCard is shown because today has symptoms
    expect(find.byType(BodyExplainerCard), findsOneWidget);
    expect(find.text('Kenapa Tubuhmu Merasa Begini?'), findsOneWidget);

    // 3. SelfCareChecklistCard is shown with 0/3 progress and can toggle a mission
    expect(find.byType(SelfCareChecklistCard), findsOneWidget);
    expect(find.text('0/3 selesai'), findsOneWidget);

    final missionFinder = find.text('Minum air hangat / teh herbal');
    expect(missionFinder, findsOneWidget);
    await tester.ensureVisible(missionFinder);
    await tester.tap(missionFinder);
    await tester.pumpAndSettle();

    expect(find.text('1/3 selesai'), findsOneWidget);

    // 4. CoupleCareCard in Owner mode sends signal
    expect(find.byType(CoupleCareCard), findsOneWidget);
    final signalChip = find.text('Pengen yang manis 🍫');
    expect(signalChip, findsOneWidget);
    await tester.ensureVisible(signalChip);
    await tester.tap(signalChip);
    await tester.pumpAndSettle();

    final updatedDoc = await db.doc('profiles/$profileId').get();
    expect(updatedDoc.data()?['activeSignal'], CoupleSignal.cravingSweet.name);
  });

  testWidgets(
      'Partner HomeScreen shows Partner Greeting, Partner Phase Guide, active signal from owner, and sends PartnerReaction',
      (tester) async {
    final db = FakeFirebaseFirestore();
    final profileRepo = ProfileRepository(db);
    final profileId = await profileRepo.createProfile(uid: 'alice', name: 'Alice');
    await db.doc('profiles/$profileId').update({
      'memberUids': ['alice', 'bob'],
      'activeSignal': CoupleSignal.cravingSweet.name,
    });

    final partnerUser = MockUser(uid: 'bob', email: 'bob@example.com');
    final today = DateTime(2026, 10, 16);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayProvider.overrideWithValue(today),
          firestoreProvider.overrideWithValue(db),
          authStateProvider.overrideWith((_) => Stream.value(partnerUser)),
          activeProfileIdProvider.overrideWith((_) => Stream.value(profileId)),
        ],
        child: MaterialApp(
          theme: CycleTheme.lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Partner greeting
    expect(find.textContaining('Mendampingi Alice'), findsOneWidget);

    // Partner guide & active signal from Alice
    expect(find.text('Panduan Pasangan Hari Ini'), findsOneWidget);
    expect(find.textContaining('Pengen yang manis 🍫'), findsOneWidget);

    // Send 1-click reaction
    final reactionChip = find.text('Siap, meluncur bawain! 🛵🍫');
    expect(reactionChip, findsOneWidget);
    await tester.ensureVisible(reactionChip);
    await tester.tap(reactionChip);
    await tester.pumpAndSettle();

    final updatedDoc = await db.doc('profiles/$profileId').get();
    expect(updatedDoc.data()?['signalReaction'], PartnerReaction.onTheWay.name);
  });
}
