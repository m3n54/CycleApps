import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/data/profile_repository.dart';
import 'package:siklus/domain/cycle_profile.dart';
import 'package:siklus/features/couple/widgets/care_sticker_tray.dart';
import 'package:siklus/features/couple/widgets/love_header_badge.dart';
import 'package:siklus/state/providers.dart';
import 'package:siklus/theme/cycle_theme.dart';

void main() {
  group('Review Finding 1: ProfileRepository.updateCoupleMetadata', () {
    late FakeFirebaseFirestore db;
    late ProfileRepository repo;

    setUp(() async {
      db = FakeFirebaseFirestore();
      repo = ProfileRepository(db);
      await db.doc('profiles/p1').set({
        'name': 'Nata',
        'partnerName': 'Menza',
        'ownerUid': 'u1',
        'memberUids': ['u1', 'u2'],
      });
    });

    test('returns early without modifying firestore when updates map is empty', () async {
      await repo.updateCoupleMetadata(profileId: 'p1');

      final doc = await db.doc('profiles/p1').get();
      expect(doc.data()?['partnerName'], 'Menza');
      expect(doc.data()?['anniversaryDate'], isNull);
    });

    test('updates name, partnerName, and anniversaryDate when provided', () async {
      await repo.updateCoupleMetadata(
        profileId: 'p1',
        name: 'Nata Baru',
        partnerName: 'Menza Sayang',
        anniversaryDate: DateTime(2023, 11, 20),
      );

      final doc = await db.doc('profiles/p1').get();
      expect(doc.data()?['name'], 'Nata Baru');
      expect(doc.data()?['partnerName'], 'Menza Sayang');
      expect(doc.data()?['anniversaryDate'], '2023-11-20');
    });
  });

  group('Review Finding 2: LoveHeaderBadge metadata dialog and controller disposal', () {
    late FakeFirebaseFirestore db;

    setUp(() async {
      db = FakeFirebaseFirestore();
      await db.doc('profiles/p1').set({
        'name': 'Nata',
        'partnerName': 'Menza',
        'ownerUid': 'u1',
        'memberUids': ['u1', 'u2'],
      });
    });

    testWidgets('shows "Nama Panggilan Pasangan" when viewing as owner', (tester) async {
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'u1', email: 'owner@test.com'),
      );

      const profile = CycleProfile(
        id: 'p1',
        name: 'Nata',
        partnerName: 'Menza',
        ownerUid: 'u1',
        memberUids: ['u1', 'u2'],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todayProvider.overrideWithValue(DateTime(2026, 10, 29)),
            firebaseAuthProvider.overrideWithValue(auth),
            firestoreProvider.overrideWithValue(db),
          ],
          child: MaterialApp(
            theme: CycleTheme.lightTheme,
            home: const Scaffold(
              body: LoveHeaderBadge(profile: profile),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('editCoupleMetadataBtn')));
      await tester.pumpAndSettle();

      expect(find.text('Nama Panggilan Pasangan'), findsOneWidget);
      expect(find.text('Nama Panggilan Kamu'), findsNothing);

      // Dismiss dialog to ensure controller is cleanly disposed via finally block
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
    });

    testWidgets('shows "Nama Panggilan Kamu" when viewing as non-owner (partner)', (tester) async {
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'u2', email: 'partner@test.com'),
      );

      const profile = CycleProfile(
        id: 'p1',
        name: 'Nata',
        partnerName: 'Menza',
        ownerUid: 'u1',
        memberUids: ['u1', 'u2'],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todayProvider.overrideWithValue(DateTime(2026, 10, 29)),
            firebaseAuthProvider.overrideWithValue(auth),
            firestoreProvider.overrideWithValue(db),
          ],
          child: MaterialApp(
            theme: CycleTheme.lightTheme,
            home: const Scaffold(
              body: LoveHeaderBadge(profile: profile),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('editCoupleMetadataBtn')));
      await tester.pumpAndSettle();

      expect(find.text('Nama Panggilan Kamu'), findsOneWidget);
      expect(find.text('Nama Panggilan Pasangan'), findsNothing);

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
    });
  });

  group('Review Finding 3: CareStickerTray senderName fallback resolution', () {
    late FakeFirebaseFirestore db;

    setUp(() async {
      db = FakeFirebaseFirestore();
      await db.doc('profiles/p1').set({
        'name': 'Nata',
        'partnerName': 'Menza',
        'ownerUid': 'u1',
        'memberUids': ['u1', 'u2'],
      });
    });

    testWidgets('uses partnerName as senderName when non-owner has empty displayName', (tester) async {
      final user = MockUser(uid: 'u2', email: 'partner@test.com');
      final auth = MockFirebaseAuth(signedIn: true, mockUser: user);

      const profile = CycleProfile(
        id: 'p1',
        name: 'Nata',
        partnerName: 'Menza',
        ownerUid: 'u1',
        memberUids: ['u1', 'u2'],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todayProvider.overrideWithValue(DateTime(2026, 10, 29)),
            firebaseAuthProvider.overrideWithValue(auth),
            authStateProvider.overrideWith((ref) => Stream.value(user)),
            firestoreProvider.overrideWithValue(db),
          ],
          child: MaterialApp(
            theme: CycleTheme.lightTheme,
            home: const Scaffold(
              body: SingleChildScrollView(
                child: CareStickerTray(profile: profile),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Test _sendStandaloneNote
      await tester.enterText(
        find.byKey(const Key('quickLoveNoteInput')),
        'Pesan cinta dari Menza',
      );
      await tester.tap(find.byKey(const Key('sendQuickNoteBtn')));
      await tester.pumpAndSettle();

      final interactions = await db.collection('profiles/p1/interactions').get();
      expect(interactions.docs.length, 1);
      final data = interactions.docs.first.data();
      expect(data['senderName'], 'Menza');
      expect(data['senderUid'], 'u2');
      expect(data['text'], 'Pesan cinta dari Menza');

      // Test _sendSticker
      await tester.tap(find.textContaining('Peluk Erat'));
      await tester.pumpAndSettle();

      final updatedInteractions = await db.collection('profiles/p1/interactions').get();
      expect(updatedInteractions.docs.length, 2);
      final stickerDoc = updatedInteractions.docs.last.data();
      expect(stickerDoc['senderName'], 'Menza');
    });

    testWidgets('falls back to "Pasangan" when non-owner has empty displayName and empty partnerName', (tester) async {
      final user = MockUser(uid: 'u2', email: 'partner@test.com');
      final auth = MockFirebaseAuth(signedIn: true, mockUser: user);

      const profile = CycleProfile(
        id: 'p1',
        name: 'Nata',
        partnerName: '', // empty partnerName
        ownerUid: 'u1',
        memberUids: ['u1', 'u2'],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todayProvider.overrideWithValue(DateTime(2026, 10, 29)),
            firebaseAuthProvider.overrideWithValue(auth),
            authStateProvider.overrideWith((ref) => Stream.value(user)),
            firestoreProvider.overrideWithValue(db),
          ],
          child: MaterialApp(
            theme: CycleTheme.lightTheme,
            home: const Scaffold(
              body: SingleChildScrollView(
                child: CareStickerTray(profile: profile),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('quickLoveNoteInput')),
        'Pesan cinta anonim',
      );
      await tester.tap(find.byKey(const Key('sendQuickNoteBtn')));
      await tester.pumpAndSettle();

      final interactions = await db.collection('profiles/p1/interactions').get();
      expect(interactions.docs.first.data()['senderName'], 'Pasangan');
    });
  });
}
