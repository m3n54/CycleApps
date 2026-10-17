import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/domain/couple_interaction.dart';
import 'package:siklus/domain/cycle_profile.dart';
import 'package:siklus/features/couple/couple_space_screen.dart';
import 'package:siklus/features/couple/widgets/add_custom_sticker_dialog.dart';
import 'package:siklus/features/couple/widgets/care_sticker_tray.dart';
import 'package:siklus/features/couple/widgets/love_header_badge.dart';
import 'package:siklus/features/couple/widgets/love_timeline_card.dart';
import 'package:siklus/state/providers.dart';
import 'package:siklus/theme/cycle_theme.dart';

void main() {
  late FakeFirebaseFirestore db;
  late MockFirebaseAuth auth;

  setUp(() async {
    db = FakeFirebaseFirestore();
    auth = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'u2', email: 'cowok@test.com'));
    await db.doc('users/u2').set({'activeProfileId': 'p1'});
    await db.doc('profiles/p1').set({
      'name': 'Nata',
      'ownerUid': 'u1',
      'memberUids': ['u1', 'u2'],
    });
  });

  testWidgets('CoupleSpaceScreen renders love header, sticker tray, and timeline cards', (tester) async {
    // Add existing interaction
    await db.collection('profiles/p1/interactions').doc('i1').set({
      'senderUid': 'u1',
      'senderName': 'Nata',
      'emoji': '🧸',
      'text': 'Puk-puk kepala & peluk eratt 🤗',
      'createdAt': DateTime.now().toIso8601String(),
      'isRead': false,
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
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
        ],
        child: MaterialApp(
          theme: CycleTheme.lightTheme,
          home: const CoupleSpaceScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CareStickerTray), findsOneWidget);
    expect(find.byType(LoveTimelineCard), findsOneWidget);
    expect(find.textContaining('Puk-puk kepala'), findsOneWidget);

    // Tap quick reply button on the card
    expect(find.textContaining('Benerannn mawuuuu'), findsOneWidget);
    await tester.tap(find.textContaining('Benerannn mawuuuu'));
    await tester.pumpAndSettle();

    final doc = await db.doc('profiles/p1/interactions/i1').get();
    expect(doc.data()?['replyText'], contains('Benerannn mawuuuu'));
  });

  testWidgets('CoupleSpaceScreen unlinked state shows invitation guidance', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
          firestoreProvider.overrideWithValue(db),
          activeProfileIdProvider.overrideWith((ref) => Stream.value('p_solo')),
          activeProfileProvider.overrideWith(
            (ref) => Stream.value(
              const CycleProfile(
                id: 'p_solo',
                name: 'Menza',
                ownerUid: 'u2',
                memberUids: ['u2'],
              ),
            ),
          ),
        ],
        child: MaterialApp(
          theme: CycleTheme.lightTheme,
          home: const CoupleSpaceScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Belum Terhubung dengan Pasangan'), findsOneWidget);
    expect(find.text('Buat Kode Undangan'), findsOneWidget);
    expect(find.text('Gabung dengan Kode'), findsOneWidget);
  });

  testWidgets('Sending care sticker with custom note writes to Firestore', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
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
        ],
        child: MaterialApp(
          theme: CycleTheme.lightTheme,
          home: const CoupleSpaceScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Enter custom note
    await tester.enterText(
      find.byKey(const Key('quickLoveNoteInput')),
      'Semangat kerjanya yaa sayang ❤️',
    );
    await tester.pumpAndSettle();

    // Tap first sticker chip (default_care_1)
    await tester.tap(find.byKey(const Key('sticker_chip_default_care_1')));
    await tester.pumpAndSettle();

    final snapshot = await db.collection('profiles/p1/interactions').get();
    expect(snapshot.docs.length, 1);
    final sentData = snapshot.docs.first.data();
    expect(sentData['text'], contains('Puk-puk kepala'));
    expect(sentData['customNote'], 'Semangat kerjanya yaa sayang ❤️');
    expect(sentData['senderUid'], 'u2');
  });

  testWidgets('Adding custom sticker via dialog persists to profile', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
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
        ],
        child: MaterialApp(
          theme: CycleTheme.lightTheme,
          home: const CoupleSpaceScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap + Tambah
    await tester.tap(find.byKey(const Key('addStickerBtn')));
    await tester.pumpAndSettle();

    expect(find.byType(AddCustomStickerDialog), findsOneWidget);

    // Pick emoji 💌
    await tester.tap(find.byKey(const Key('emoji_picker_💌')));
    await tester.pumpAndSettle();

    // Enter text
    await tester.enterText(
      find.byKey(const Key('customStickerTextInput')),
      'Surat cinta rahasia 💌',
    );
    await tester.pumpAndSettle();

    // Save
    await tester.tap(find.byKey(const Key('saveCustomStickerBtn')));
    await tester.pumpAndSettle();

    final profileDoc = await db.doc('profiles/p1').get();
    final customStickers = profileDoc.data()?['customStickers'] as List?;
    expect(customStickers, isNotNull);
    expect(customStickers!.length, 1);
    expect(customStickers.first['text'], 'Surat cinta rahasia 💌');
    expect(customStickers.first['emoji'], '💌');
  });

  testWidgets('LoveTimelineCard displays nested reply when already replied', (tester) async {
    final now = DateTime.now();
    await tester.pumpWidget(
      MaterialApp(
        theme: CycleTheme.lightTheme,
        home: Scaffold(
          body: ProviderScope(
            overrides: [
              firebaseAuthProvider.overrideWithValue(auth),
              firestoreProvider.overrideWithValue(db),
            ],
            child: LoveTimelineCard(
              interaction: CoupleInteraction(
                id: 'i2',
                senderUid: 'u1',
                senderName: 'Nata',
                emoji: '🍫',
                text: 'Camilan manis anti-badmood buat kamu 🍫💖',
                customNote: 'Udah di meja kerja yaa',
                replyEmoji: '🥰',
                replyText: 'Makasih banyaakk sayangkuuu 🥰',
                repliedAt: now,
                createdAt: now.subtract(const Duration(minutes: 10)),
                isRead: true,
              ),
              profile: const CycleProfile(
                id: 'p1',
                name: 'Nata',
                ownerUid: 'u1',
                memberUids: ['u1', 'u2'],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Balasan Manis:'), findsOneWidget);
    expect(find.text('Makasih banyaakk sayangkuuu 🥰'), findsOneWidget);
    expect(find.textContaining('Udah di meja kerja'), findsOneWidget);
  });

  testWidgets('unreadCoupleInteractionsCountProvider counts only incoming unread messages', (tester) async {
    final container = ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWithValue(auth),
        firestoreProvider.overrideWithValue(db),
        authStateProvider.overrideWith((ref) => Stream.value(auth.currentUser)),
        activeProfileIdProvider.overrideWith((ref) => Stream.value('p1')),
        coupleInteractionsProvider.overrideWith(
          (ref) => Stream.value([
            CoupleInteraction(
              id: '1',
              senderUid: 'u1', // incoming from partner
              senderName: 'Nata',
              emoji: '🧸',
              text: 'Peluk',
              createdAt: DateTime.now(),
              isRead: false, // unread -> +1
            ),
            CoupleInteraction(
              id: '2',
              senderUid: 'u2', // outgoing from myself
              senderName: 'Cowok',
              emoji: '🍫',
              text: 'Coklat',
              createdAt: DateTime.now(),
              isRead: false, // not incoming -> ignored
            ),
            CoupleInteraction(
              id: '3',
              senderUid: 'u1', // incoming from partner
              senderName: 'Nata',
              emoji: '🧋',
              text: 'Boba',
              createdAt: DateTime.now(),
              isRead: true, // already read -> ignored
            ),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authStateProvider.future);
    await container.read(coupleInteractionsProvider.future);

    final unreadCount = container.read(unreadCoupleInteractionsCountProvider);
    expect(unreadCount, 1);
  });

  testWidgets('CoupleSpaceScreen renders without overflow on 320px narrow mobile viewport', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
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
          coupleInteractionsProvider.overrideWith(
            (ref) => Stream.value([
              CoupleInteraction(
                id: 'i1',
                senderUid: 'u1',
                senderName: 'Nata',
                emoji: '🧸',
                text: 'Puk-puk kepala & peluk eratt 🤗',
                customNote: 'Semangat terus yaa gantengku ❤️',
                replyEmoji: '🧋',
                replyText: 'Benerannn mawuuuu 🧋✨',
                createdAt: DateTime.now(),
              ),
            ]),
          ),
        ],
        child: MaterialApp(
          theme: CycleTheme.lightTheme,
          home: const CoupleSpaceScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(LoveHeaderBadge), findsOneWidget);
    expect(find.byType(CareStickerTray), findsOneWidget);
    expect(find.byType(LoveTimelineCard), findsOneWidget);
  });
}
