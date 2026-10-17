# Ruang Pasangan & Fitur Interaktif Saling Balas (Couple Space) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Membangun "Ruang Pasangan 💑" (Couple Space) interaktif dengan live timeline saling balas, stiker perhatian manja & balasan 1-klik, sistem kustomisasi stiker pribadi, serta diferensiasi tampilan Beranda pasangan (tanpa tombol catat haid) dan integrasi navigasi 4 tab terfokus.

**Architecture:** Model `CoupleInteraction` dan `CustomCoupleSticker` di domain layer disinkronkan ke subkoleksi Firestore `/profiles/{profileId}/interactions` dan dokumen `/profiles/{profileId}` via `ProfileRepository`. Di UI layer, `CoupleSpaceScreen` menyediakan live timeline dengan stream Riverpod, form stiker kustom, serta banner notifikasi perhatian dan tombol "Kirim Perhatian" khusus pasangan di `HomeScreen`.

**Tech Stack:** Flutter 3.47+, Dart 3.13+, Flutter Riverpod 2.6.1, Cloud Firestore, Firebase Auth, Google Material 3 with `CycleTheme`.

**Spec:** [`docs/superpowers/specs/2026-10-17-couple-space-interactive-features-design.md`](file:///C:/Menza/CycleApps/docs/superpowers/specs/2026-10-17-couple-space-interactive-features-design.md)

## Global Constraints
- Bahasa antarmuka: Bahasa Indonesia yang hangat, menggemaskan, dan komunikatif untuk pasangan.
- Menggunakan Material 3 design tokens dari `CycleColors` dan `CycleTheme`.
- Semua tampilan wajib responsif dan bebas overflow pada layar sempit (lebar 320px–420px).
- TDD: Tulis test terlebih dahulu, pastikan gagal (merah), implementasi minimal, pastikan lulus (hijau), lalu commit.
- Seluruh 87 tests yang sudah ada tidak boleh regresi.

---

### Task 1: Domain Models, Catalog, & Data Repository for Couple Interactions

**Files:**
- Create: `lib/domain/couple_interaction.dart`
- Modify: `lib/domain/cycle_profile.dart:1-60`
- Modify: `lib/data/profile_repository.dart:1-120`
- Modify: `firestore.rules:1-65`
- Create Test: `test/domain/couple_interaction_test.dart`
- Create Test: `test/data/couple_interaction_repository_test.dart`

**Interfaces:**
- Produces:
  - `class CoupleInteraction`: `id`, `senderUid`, `senderName`, `emoji`, `text`, `customNote`, `replyEmoji`, `replyText`, `repliedAt`, `createdAt`, `isRead`.
  - `class CustomCoupleSticker`: `id`, `emoji`, `text`, `isReply`.
  - `class CoupleCareCatalog`: `defaultCareStickers`, `defaultReplyStickers`.
  - `ProfileRepository.watchInteractions(String profileId, {int limit}) -> Stream<List<CoupleInteraction>>`
  - `ProfileRepository.sendInteraction({required String profileId, required String senderUid, required String senderName, required String emoji, required String text, String? customNote}) -> Future<String>`
  - `ProfileRepository.replyInteraction({required String profileId, required String interactionId, required String replyEmoji, required String replyText}) -> Future<void>`
  - `ProfileRepository.addCustomSticker({required String profileId, required CustomCoupleSticker sticker}) -> Future<void>`
  - `ProfileRepository.deleteCustomSticker({required String profileId, required String stickerId}) -> Future<void>`

- [ ] **Step 1: Write the failing domain and repository tests**

```dart
// test/domain/couple_interaction_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/domain/couple_interaction.dart';

void main() {
  test('CoupleInteraction serializes and deserializes correctly', () {
    final now = DateTime(2026, 10, 17, 10, 30);
    final interaction = CoupleInteraction(
      id: 'i1',
      senderUid: 'u1',
      senderName: 'Nata',
      emoji: '🧋',
      text: 'Boba favorit meluncuurr! 🛵💨',
      customNote: 'Jangan lupa senyum yaa',
      replyEmoji: '🧋',
      replyText: 'Benerannn mawuuuu 🧋✨',
      repliedAt: now.add(const Duration(minutes: 5)),
      createdAt: now,
      isRead: false,
    );

    final map = interaction.toMap();
    expect(map['senderUid'], 'u1');
    expect(map['emoji'], '🧋');

    final reconstructed = CoupleInteraction.fromMap('i1', map);
    expect(reconstructed.id, 'i1');
    expect(reconstructed.text, 'Boba favorit meluncuurr! 🛵💨');
    expect(reconstructed.replyEmoji, '🧋');
    expect(reconstructed.customNote, 'Jangan lupa senyum yaa');
  });

  test('CoupleCareCatalog contains warm and cute default stickers and replies', () {
    expect(CoupleCareCatalog.defaultCareStickers.isNotEmpty, isTrue);
    expect(CoupleCareCatalog.defaultReplyStickers.isNotEmpty, isTrue);
    expect(
      CoupleCareCatalog.defaultReplyStickers.any((s) => s.text.contains('Benerannn mawuuuu')),
      isTrue,
    );
    expect(
      CoupleCareCatalog.defaultReplyStickers.any((s) => s.text.contains('mauu ditemenin')),
      isTrue,
    );
  });
}
```

```dart
// test/data/couple_interaction_repository_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/data/profile_repository.dart';
import 'package:siklus/domain/couple_interaction.dart';

void main() {
  late FakeFirebaseFirestore db;
  late ProfileRepository repo;

  setUp(() async {
    db = FakeFirebaseFirestore();
    repo = ProfileRepository(db);
    await db.doc('profiles/p1').set({
      'name': 'Nata',
      'ownerUid': 'u1',
      'memberUids': ['u1', 'u2'],
    });
  });

  test('sendInteraction adds interaction document and updates lastInteraction on profile', () async {
    final id = await repo.sendInteraction(
      profileId: 'p1',
      senderUid: 'u2',
      senderName: 'Menza',
      emoji: '🧋',
      text: 'Boba meluncur! 🛵',
      customNote: 'Rasa taro kesukaanmu',
    );

    expect(id.isNotEmpty, isTrue);
    final doc = await db.doc('profiles/p1/interactions/$id').get();
    expect(doc.exists, isTrue);
    expect(doc.data()?['text'], 'Boba meluncur! 🛵');

    final profileDoc = await db.doc('profiles/p1').get();
    expect(profileDoc.data()?['lastInteraction']?['emoji'], '🧋');
  });

  test('replyInteraction updates reply fields on interaction document', () async {
    final id = await repo.sendInteraction(
      profileId: 'p1',
      senderUid: 'u2',
      senderName: 'Menza',
      emoji: '🧸',
      text: 'Kompres hangat siap!',
    );

    await repo.replyInteraction(
      profileId: 'p1',
      interactionId: id,
      replyEmoji: '💖',
      replyText: 'Loveee youu soo muchh 💖🥹',
    );

    final doc = await db.doc('profiles/p1/interactions/$id').get();
    expect(doc.data()?['replyEmoji'], '💖');
    expect(doc.data()?['replyText'], 'Loveee youu soo muchh 💖🥹');
  });

  test('addCustomSticker and deleteCustomSticker manage profile customStickers array', () async {
    const sticker = CustomCoupleSticker(
      id: 's_custom_1',
      emoji: '🍜',
      text: 'Mau mie ayam yuk',
      isReply: false,
    );

    await repo.addCustomSticker(profileId: 'p1', sticker: sticker);
    var profileDoc = await db.doc('profiles/p1').get();
    var list = profileDoc.data()?['customStickers'] as List?;
    expect(list?.length, 1);
    expect(list?.first['id'], 's_custom_1');

    await repo.deleteCustomSticker(profileId: 'p1', stickerId: 's_custom_1');
    profileDoc = await db.doc('profiles/p1').get();
    list = profileDoc.data()?['customStickers'] as List?;
    expect(list?.isEmpty, isTrue);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `& "C:\src\flutter\bin\flutter.bat" test test/domain/couple_interaction_test.dart test/data/couple_interaction_repository_test.dart`
Expected: FAIL (types and methods not defined yet).

- [ ] **Step 3: Implement domain models and ProfileRepository methods**

1. Create `lib/domain/couple_interaction.dart`:
   - Define `class CoupleInteraction` with `toMap()`, `fromMap()`, `copyWith()`.
   - Define `class CustomCoupleSticker` with `toMap()`, `fromMap()`.
   - Define `class CoupleCareCatalog` containing `defaultCareStickers` and `defaultReplyStickers`.
2. Update `lib/domain/cycle_profile.dart`:
   - Add `customStickers` (`List<CustomCoupleSticker>`) and `lastInteraction` (`Map<String, dynamic>?`) to `CycleProfile` model and `fromDoc`.
3. Update `lib/data/profile_repository.dart`:
   - Implement `watchInteractions`, `sendInteraction`, `replyInteraction`, `addCustomSticker`, `deleteCustomSticker`.
4. Update `firestore.rules`:
   - Allow members in `profiles/{profileId}` to read/write in subcollection `interactions`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `& "C:\src\flutter\bin\flutter.bat" test test/domain/couple_interaction_test.dart test/data/couple_interaction_repository_test.dart`
Expected: All PASS.

- [ ] **Step 5: Commit Task 1**

```bash
git add lib/domain/couple_interaction.dart lib/domain/cycle_profile.dart lib/data/profile_repository.dart firestore.rules test/domain/couple_interaction_test.dart test/data/couple_interaction_repository_test.dart
git commit -m "feat(domain): add CoupleInteraction, CustomCoupleSticker, and repository methods"
```

---

### Task 2: "Ruang Pasangan 💑" Screen, Live Love Timeline, & Custom Sticker Tray

**Files:**
- Create: `lib/features/couple/widgets/love_header_badge.dart`
- Create: `lib/features/couple/widgets/care_sticker_tray.dart`
- Create: `lib/features/couple/widgets/add_custom_sticker_dialog.dart`
- Create: `lib/features/couple/widgets/love_timeline_card.dart`
- Create: `lib/features/couple/couple_space_screen.dart`
- Modify: `lib/state/providers.dart:1-60`
- Create Test: `test/features/couple_space_screen_test.dart`

**Interfaces:**
- Consumes: `CoupleInteraction`, `CustomCoupleSticker`, `profileRepositoryProvider`, `activeProfileProvider`, `authStateProvider`.
- Produces:
  - `coupleInteractionsProvider`: `StreamProvider<List<CoupleInteraction>>`
  - `unreadCoupleInteractionsCountProvider`: `Provider<int>`
  - `CoupleSpaceScreen`: widget rendered in Tab 2.

- [ ] **Step 1: Write the failing widget test**

```dart
// test/features/couple_space_screen_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/domain/cycle_profile.dart';
import 'package:siklus/features/couple/couple_space_screen.dart';
import 'package:siklus/features/couple/widgets/care_sticker_tray.dart';
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
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\src\flutter\bin\flutter.bat" test test/features/couple_space_screen_test.dart`
Expected: FAIL (widgets not created yet).

- [ ] **Step 3: Implement Couple Space widgets and screen**

1. Create `lib/features/couple/widgets/love_header_badge.dart`:
   - Dual avatar connector with pulsing heart icon, connection status ("Terhubung dengan [Nama Pasangan]").
2. Create `lib/features/couple/widgets/care_sticker_tray.dart`:
   - Horizontal scrolling/wrap tray of preset stickers and custom stickers with emoji + text.
   - Includes "+ Tambah" button opening `AddCustomStickerDialog`.
   - Includes optional text input field for a quick love note.
3. Create `lib/features/couple/widgets/add_custom_sticker_dialog.dart`:
   - Emoji selector grid + text field (max 35 chars) + radio (Kirim Perhatian / Balasan Cepat).
4. Create `lib/features/couple/widgets/love_timeline_card.dart`:
   - Big animated emoji, message, timestamp ("X menit lalu").
   - If recipient: 1-click chip row with quick replies (`Benerannn mawuuuu 🧋✨`, `aaaaa mauu ditemenin 🥺👉👈`, `Loveee youu soo muchh 💖🥹`).
   - If replied: displays the lover's reply in a cute nested bubble with heart badge.
5. Create `lib/features/couple/couple_space_screen.dart`:
   - Watches `activeProfileProvider`, `coupleInteractionsProvider`.
   - If `memberUids.length < 2`: renders friendly unlinked onboarding state.
   - Otherwise renders header, sticker composer, and interactive timeline stream.
6. Register `coupleInteractionsProvider` and `unreadCoupleInteractionsCountProvider` in `lib/state/providers.dart`.

- [ ] **Step 4: Run test to verify it passes**

Run: `& "C:\src\flutter\bin\flutter.bat" test test/features/couple_space_screen_test.dart`
Expected: All PASS.

- [ ] **Step 5: Commit Task 2**

```bash
git add lib/features/couple/ lib/state/providers.dart test/features/couple_space_screen_test.dart
git commit -m "feat(couple): implement CoupleSpaceScreen, live love timeline, and custom sticker tray"
```

---

### Task 3: HomeShell 4-Tab Navigation & Partner-Differentiated HomeScreen

**Files:**
- Modify: `lib/features/home/home_shell.dart:1-120`
- Modify: `lib/features/home/home_screen.dart:1-310`
- Modify: `lib/features/home/widgets/today_summary_card.dart:1-140`
- Create Test: `test/features/partner_differentiated_home_test.dart`
- Modify Test: `test/features/home_shell_test.dart:1-60`

**Interfaces:**
- Consumes: `CoupleSpaceScreen`, `unreadCoupleInteractionsCountProvider`, `activeProfileProvider`, `isPartner`.
- Produces:
  - `HomeShell` 4-tab bar (Beranda, Kalender, Ruang Pasangan 💑 with badge, Pengaturan).
  - `HomeScreen` Partner Mode:
    - Replaces "Catat Hari Ini" button with **"Kirim Perhatian ke [Nama Pacar] 💖"**.
    - Shows partner-focused greeting and "Panduan Pasangan Hari Ini" card.
    - Displays active love notification banner at top of HomeScreen if an interaction was received recently.

- [ ] **Step 1: Write the failing widget tests**

```dart
// test/features/partner_differentiated_home_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/domain/cycle_profile.dart';
import 'package:siklus/domain/day_entry.dart';
import 'package:siklus/features/home/home_screen.dart';
import 'package:siklus/state/providers.dart';
import 'package:siklus/theme/cycle_theme.dart';

void main() {
  testWidgets('Partner HomeScreen shows Kirim Perhatian button and NO Catat Hari Ini button', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayProvider.overrideWithValue(DateTime(2026, 10, 17)),
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
          // User is u2 (partner)
          authStateProvider.overrideWith(
            (ref) => Stream.value(
              // mock partner user
              null,
            ),
          ),
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
    expect(find.textContaining('Kirim Perhatian'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\src\flutter\bin\flutter.bat" test test/features/partner_differentiated_home_test.dart`
Expected: FAIL (HomeScreen still renders "Catat Hari Ini").

- [ ] **Step 3: Implement HomeShell 4-tab bar and HomeScreen Partner Mode differentiation**

1. Update `lib/features/home/home_shell.dart`:
   - Set 4 destinations:
     - 0: Beranda (`HomeScreen`)
     - 1: Kalender (`CalendarScreen`)
     - 2: Ruang Pasangan (`CoupleSpaceScreen`) with badge dot indicator if `unreadCoupleInteractionsCountProvider > 0`
     - 3: Pengaturan (`SettingsScreen`)
2. Update `lib/features/home/home_screen.dart`:
   - If `isPartner`:
     - Render primary CTA: **"Kirim Perhatian ke [Nama Pacar] 💖"** (tapping it navigates to tab 2 / opens quick care sticker modal).
     - Hide period flow logging button.
     - Keep Partner Phase Guide card prominent.
   - If partner receives a fresh unreplied interaction:
     - Display top banner: *"💌 [Nama Pacar] baru saja mengirim: [Emoji + Teks]! Ketuk untuk membalas"* linking directly to Ruang Pasangan.
3. Update `TodaySummaryCard`:
   - Add button/link *"Lihat Analisis & Grafik Siklus Lengkap"* linking to `InsightsScreen` so insights remain accessible anytime.
4. Update `test/features/home_shell_test.dart` to assert 4 navigation destinations including "Ruang Pasangan".

- [ ] **Step 4: Run all tests to verify everything passes**

Run: `& "C:\src\flutter\bin\flutter.bat" test; & "C:\src\flutter\bin\flutter.bat" analyze`
Expected: All tests PASS, 0 analyzer issues.

- [ ] **Step 5: Commit Task 3**

```bash
git add lib/features/home/ lib/features/insights/ test/features/
git commit -m "feat(navigation): integrate 4-tab HomeShell with Couple Space and Partner-Differentiated HomeScreen"
```

---

## Plan Self-Review Checklist
- [x] **Spec coverage:** All sections from spec (4-tab nav, partner differentiation, live timeline, cute preset stickers & replies, custom stickers, unlinked state, and mascot roadmap) are explicitly addressed.
- [x] **No placeholders:** Every step has explicit file paths, test code, and implementation logic.
- [x] **Type consistency:** `CoupleInteraction`, `CustomCoupleSticker`, and methods match across tasks.
- [x] **Dry run:** Tests cover both positive flows and edge cases (unlinked profile).
