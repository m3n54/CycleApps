# Karakter Maskot Dinamis, Care Streak & Anniversary, dan Penyempurnaan UX Ruang Pasangan Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Membangun sistem Karakter Maskot Pendamping Dinamis (4 karakter vector/canvas animasi yang berubah sesuai fase siklus & mood), menambahkan fitur Nama Pasangan, Penghitung Hari Bersama (Anniversary), dan Care Streak otomatis di Ruang Pasangan, serta menyempurnakan UX Ruang Pasangan (Auto-Read pesan masuk, hapus stiker kustom via long-press, dan tombol kirim catatan manis mandiri).

**Architecture:** Domain layer diperluas dengan `CycleMascot` (karakter, state ekspresi, dan dialog interaktif) serta `CoupleStreakCalculator` (perhitungan deterministik streak & anniversary dari data yang ada). `CycleProfile` dan `ProfileRepository` diperbarui untuk menyimpan `selectedMascot`, `partnerName`, `anniversaryDate`, serta operasi batch `markInteractionsAsRead`. Di UI layer, `MascotCompanionCard` dirender di `HomeScreen` dengan `CustomPainter` vector pastel & animasi mengambang, sementara `LoveHeaderBadge`, `CareStickerTray`, dan `CoupleSpaceScreen` diperkaya dengan fitur interaktif baru.

**Tech Stack:** Flutter 3.47+, Dart 3.13+, Flutter Riverpod 2.6.1, Cloud Firestore, Firebase Auth, Material 3 (`CycleTheme` & `CycleColors`).

**Spec:** [`docs/superpowers/specs/2026-10-29-mascot-and-couple-depth-design.md`](file:///C:/Menza/CycleApps/docs/superpowers/specs/2026-10-29-mascot-and-couple-depth-design.md)

## Global Constraints

- Bahasa antarmuka: Bahasa Indonesia yang hangat, menggemaskan, dan empatik untuk pasangan.
- Menggunakan design tokens dari `CycleColors` dan `CycleTheme` (mendukung Light Mode & Dark Mode).
- Bebas overflow pada layar sempit (lebar 320px–420px).
- TDD: Tulis test terlebih dahulu, jalankan hingga gagal (RED), implementasikan kode minimal hingga lulus (GREEN), lalu commit.
- Seluruh test yang sudah ada wajib tetap lulus tanpa regresi.

---

### Task 1: Domain Models (`CycleMascot` & `CoupleStreakCalculator`) & `CycleProfile` Extension

**Files:**
- Create: `lib/domain/cycle_mascot.dart`
- Create: `lib/domain/couple_streak_calculator.dart`
- Modify: `lib/domain/cycle_profile.dart:1-95`
- Create Test: `test/domain/cycle_mascot_and_streak_test.dart`
- Modify Test: `test/domain/cycle_profile_test.dart`

**Interfaces:**
- Produces:
  - `enum MascotCharacter { mochiKitten, fluffyBunny, babyDino, chibiGirl }`
  - `enum MascotMoodState { comfyRest, sparklingHappy, glowingLove, cravingPouty }`
  - `class CycleMascotAdvisor`:
    - `static MascotMoodState resolveMoodState({required CyclePhase phase, DayEntry? todayEntry})`
    - `static List<String> bubbleMessages({required MascotCharacter character, required MascotMoodState state, required bool isPartner, required String partnerName})`
  - `class CoupleStreakCalculator`:
    - `static int? daysTogether({required DateTime? anniversaryDate, required DateTime today})`
    - `static int calculateStreak({required List<CoupleInteraction> interactions, required DateTime today})`
  - `CycleProfile` fields: `selectedMascot`, `partnerName`, `anniversaryDate`.

- [ ] **Step 1: Write the failing unit tests for `CycleMascot`, `CoupleStreakCalculator`, and `CycleProfile`**

```dart
// test/domain/cycle_mascot_and_streak_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/domain/couple_interaction.dart';
import 'package:siklus/domain/couple_streak_calculator.dart';
import 'package:siklus/domain/cycle_mascot.dart';
import 'package:siklus/domain/cycle_phase.dart';
import 'package:siklus/domain/cycle_profile.dart';
import 'package:siklus/domain/day_entry.dart';

void main() {
  group('CycleMascotAdvisor', () {
    test('resolves comfyRest during menstrual phase or cramps symptom', () {
      expect(
        CycleMascotAdvisor.resolveMoodState(
          phase: CyclePhase.menstrual,
          todayEntry: null,
        ),
        MascotMoodState.comfyRest,
      );

      expect(
        CycleMascotAdvisor.resolveMoodState(
          phase: CyclePhase.follicular,
          todayEntry: const DayEntry(
            date: '2026-10-29',
            symptoms: {Symptom.cramps},
          ),
        ),
        MascotMoodState.comfyRest,
      );
    });

    test('resolves cravingPouty on luteal phase or sensitive/sad mood', () {
      expect(
        CycleMascotAdvisor.resolveMoodState(
          phase: CyclePhase.luteal,
          todayEntry: null,
        ),
        MascotMoodState.cravingPouty,
      );

      expect(
        CycleMascotAdvisor.resolveMoodState(
          phase: CyclePhase.follicular,
          todayEntry: const DayEntry(
            date: '2026-10-29',
            moods: {Mood.sensitive},
          ),
        ),
        MascotMoodState.cravingPouty,
      );
    });

    test('returns non-empty owner and partner bubble messages for all characters', () {
      for (final character in MascotCharacter.values) {
        final ownerQuotes = CycleMascotAdvisor.bubbleMessages(
          character: character,
          state: MascotMoodState.glowingLove,
          isPartner: false,
          partnerName: 'Nata',
        );
        final partnerQuotes = CycleMascotAdvisor.bubbleMessages(
          character: character,
          state: MascotMoodState.comfyRest,
          isPartner: true,
          partnerName: 'Nata',
        );
        expect(ownerQuotes.length, greaterThanOrEqualTo(3));
        expect(partnerQuotes.length, greaterThanOrEqualTo(3));
        expect(partnerQuotes.first, contains('Nata'));
      }
    });
  });

  group('CoupleStreakCalculator', () {
    test('calculates daysTogether accurately including day 1', () {
      final today = DateTime(2026, 10, 29);
      expect(
        CoupleStreakCalculator.daysTogether(
          anniversaryDate: DateTime(2026, 10, 20),
          today: today,
        ),
        10,
      );
      expect(
        CoupleStreakCalculator.daysTogether(
          anniversaryDate: null,
          today: today,
        ),
        isNull,
      );
    });

    test('calculates consecutive care streak across days', () {
      final today = DateTime(2026, 10, 29, 14, 0);
      final interactions = [
        CoupleInteraction(
          id: '1',
          senderUid: 'u1',
          senderName: 'Nata',
          emoji: '🧋',
          text: 'Boba',
          createdAt: DateTime(2026, 10, 29, 10, 0),
          isRead: false,
        ),
        CoupleInteraction(
          id: '2',
          senderUid: 'u2',
          senderName: 'Menza',
          emoji: '🧸',
          text: 'Peluk',
          createdAt: DateTime(2026, 10, 28, 20, 0),
          isRead: true,
        ),
        CoupleInteraction(
          id: '3',
          senderUid: 'u1',
          senderName: 'Nata',
          emoji: '🍫',
          text: 'Cokelat',
          createdAt: DateTime(2026, 10, 27, 9, 0),
          isRead: true,
        ),
      ];

      expect(
        CoupleStreakCalculator.calculateStreak(
          interactions: interactions,
          today: today,
        ),
        3,
      );
    });

    test('preserves streak if no interaction today yet but yesterday had one', () {
      final today = DateTime(2026, 10, 29, 8, 0);
      final interactions = [
        CoupleInteraction(
          id: '1',
          senderUid: 'u2',
          senderName: 'Menza',
          emoji: '🧸',
          text: 'Peluk',
          createdAt: DateTime(2026, 10, 28, 21, 0),
          isRead: true,
        ),
        CoupleInteraction(
          id: '2',
          senderUid: 'u1',
          senderName: 'Nata',
          emoji: '🍫',
          text: 'Cokelat',
          createdAt: DateTime(2026, 10, 27, 15, 0),
          isRead: true,
        ),
      ];

      expect(
        CoupleStreakCalculator.calculateStreak(
          interactions: interactions,
          today: today,
        ),
        2,
      );
    });
  });

  group('CycleProfile new fields serialization', () {
    test('parses selectedMascot, partnerName, and anniversaryDate from map', () {
      final profile = CycleProfile.fromMap('p1', {
        'ownerUid': 'u1',
        'memberUids': ['u1', 'u2'],
        'name': 'Nata',
        'partnerName': 'Menza',
        'selectedMascot': 'fluffyBunny',
        'anniversaryDate': '2025-02-14',
      });

      expect(profile.partnerName, 'Menza');
      expect(profile.selectedMascot, MascotCharacter.fluffyBunny);
      expect(profile.anniversaryDate, DateTime(2025, 2, 14));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/domain/cycle_mascot_and_streak_test.dart`
Expected: FAIL with missing imports `cycle_mascot.dart` and `couple_streak_calculator.dart`.

- [ ] **Step 3: Implement `CycleMascot`, `CoupleStreakCalculator`, and update `CycleProfile`**

Create `lib/domain/cycle_mascot.dart`:

```dart
import 'cycle_phase.dart';
import 'day_entry.dart';

enum MascotCharacter {
  mochiKitten(
    emoji: '🐱',
    displayName: 'Mochi Kitten',
    tagline: 'Kucing mochi manja & suka dipeluk',
  ),
  fluffyBunny(
    emoji: '🐰',
    displayName: 'Fluffy Bunny',
    tagline: 'Kelinci lembut penuh perhatian',
  ),
  babyDino(
    emoji: '🦕',
    displayName: 'Baby Dino',
    tagline: 'Dino mungil ceria penjaga mood',
  ),
  chibiGirl(
    emoji: '👧',
    displayName: 'Chibi Girl',
    tagline: 'Sahabat ekspresif cerminan hatimu',
  );

  const MascotCharacter({
    required this.emoji,
    required this.displayName,
    required this.tagline,
  });

  final String emoji;
  final String displayName;
  final String tagline;
}

enum MascotMoodState {
  comfyRest(
    badgeEmoji: '🧸',
    statusLabel: 'Mode Istirahat & Kompres Hangat',
  ),
  sparklingHappy(
    badgeEmoji: '✨',
    statusLabel: 'Mode Ceria & Penuh Semangat',
  ),
  glowingLove(
    badgeEmoji: '💖',
    statusLabel: 'Mode Berbinar & Penuh Cinta',
  ),
  cravingPouty(
    badgeEmoji: '🍫',
    statusLabel: 'Mode Manja & Pengen Jajan Manis',
  );

  const MascotMoodState({
    required this.badgeEmoji,
    required this.statusLabel,
  });

  final String badgeEmoji;
  final String statusLabel;
}

class CycleMascotAdvisor {
  const CycleMascotAdvisor._();

  static MascotMoodState resolveMoodState({
    required CyclePhase phase,
    DayEntry? todayEntry,
  }) {
    if (todayEntry != null) {
      if (todayEntry.flow != null ||
          todayEntry.symptoms.contains(Symptom.cramps) ||
          todayEntry.symptoms.contains(Symptom.backache) ||
          todayEntry.energy == Energy.low) {
        return MascotMoodState.comfyRest;
      }
      if (todayEntry.moods.contains(Mood.sensitive) ||
          todayEntry.moods.contains(Mood.anxious) ||
          todayEntry.moods.contains(Mood.irritable) ||
          todayEntry.moods.contains(Mood.sad)) {
        return MascotMoodState.cravingPouty;
      }
      if (todayEntry.moods.contains(Mood.happy) ||
          todayEntry.energy == Energy.high) {
        return MascotMoodState.sparklingHappy;
      }
    }

    switch (phase) {
      case CyclePhase.menstrual:
        return MascotMoodState.comfyRest;
      case CyclePhase.follicular:
      case CyclePhase.unknown:
        return MascotMoodState.sparklingHappy;
      case CyclePhase.ovulation:
      case CyclePhase.fertile:
        return MascotMoodState.glowingLove;
      case CyclePhase.luteal:
        return MascotMoodState.cravingPouty;
    }
  }

  static List<String> bubbleMessages({
    required MascotCharacter character,
    required MascotMoodState state,
    required bool isPartner,
    required String partnerName,
  }) {
    final targetName = partnerName.trim().isEmpty ? 'Sayang' : partnerName.trim();
    final prefix = character.emoji;

    if (isPartner) {
      switch (state) {
        case MascotMoodState.comfyRest:
          return [
            '$prefix Psst! $targetName lagi butuh istirahat ekstra & pelukan hangat darimu~',
            '$prefix Jangan lupa tanyain perut $targetName masih kram atau nggak yaa 🧸',
            '$prefix Kirim stiker kompres hangat atau boba pasti bikin $targetName senyum! 💖',
          ];
        case MascotMoodState.sparklingHappy:
          return [
            '$prefix Energi $targetName lagi cerah banget hari ini! Ajak ngobrol seru yuk ✨',
            '$prefix Hari yang pas buat jalan bareng atau kirim pujian manis ke $targetName 🌸',
            '$prefix Mood $targetName lagi bagus, jangan lupa kirim stiker cinta hari ini yaa 💕',
          ];
        case MascotMoodState.glowingLove:
          return [
            '$prefix $targetName lagi di fase paling glowing & penuh cinta! Kirim perhatian yuk 💖',
            '$prefix Waktu terbaik buat quality time romantis bareng $targetName 🥰',
            '$prefix Bilang ke $targetName kalau dia kelihatan cantik banget hari ini! ✨',
          ];
        case MascotMoodState.cravingPouty:
          return [
            '$prefix $targetName lagi mode sensitif & manja, sabar ekstra dan peluk erat yaa 🥺',
            '$prefix Sedia camilan manis atau cokelat buat $targetName biar anti-badmood 🍫',
            '$prefix Kalau $targetName tiba-tiba cemberut, itu hormonnya lagi naik turun~ usap kepalanya ya! 🫂',
          ];
      }
    }

    switch (state) {
      case MascotMoodState.comfyRest:
        return [
          '$prefix Tubuhmu lagi bekerja keras hari ini, rebahan & minum yang hangat dulu yaa 🧸',
          '$prefix Jangan paksakan diri! Minta pelukan atau kompres hangat ke pasanganmu yuk 💕',
          '$prefix Peluk hangat dari ${character.displayName}! Kamu hebat banget hari ini 🌸',
        ];
      case MascotMoodState.sparklingHappy:
        return [
          '$prefix Yay! Energimu lagi bersinar cerah hari ini, semangat jalani harimu yaa ✨',
          '$prefix ${character.displayName} ikut senang lihat aura positifmu hari ini! 🌟',
          '$prefix Jangan lupa bagi senyum manismu ke pasangan di Ruang Pasangan yaa 💌',
        ];
      case MascotMoodState.glowingLove:
        return [
          '$prefix Kamu lagi glowing banget hari ini! Saatnya kirim kode manja ke si dia 💖',
          '$prefix Rasanya hati lagi berbunga-bunga ya? ${character.displayName} siap nemenin kamu! 🥰',
          '$prefix Jangan lupa minum air putih yang cukup biar makin segar seharian ✨',
        ];
      case MascotMoodState.cravingPouty:
        return [
          '$prefix Lagi pengen yang manis-manis atau tiba-tiba baper? Wajar banget kok, sini peluk! 🍫',
          '$prefix Kalau lagi capek atau sensitif, langsung kirim stiker kode ke pasanganmu yaa 🥺',
          '$prefix Tarik napas pelan-pelan... kamu berhak istirahat & dimanja hari ini 🤍',
        ];
    }
  }
}
```

Create `lib/domain/couple_streak_calculator.dart`:

```dart
import 'couple_interaction.dart';
import 'date_key.dart';

class CoupleStreakCalculator {
  const CoupleStreakCalculator._();

  /// Menghitung jumlah hari bersama sejak [anniversaryDate] hingga [today] (hari ke-1 dihitung).
  static int? daysTogether({
    required DateTime? anniversaryDate,
    required DateTime today,
  }) {
    if (anniversaryDate == null) return null;
    final start = dateOnly(anniversaryDate);
    final current = dateOnly(today);
    final diff = current.difference(start).inDays;
    if (diff < 0) return 1;
    return diff + 1;
  }

  /// Menghitung berapa hari berturut-turut pasangan saling mengirim perhatian.
  /// Jika hari ini belum ada interaksi tetapi kemarin ada, streak tetap bertahan dari kemarin.
  static int calculateStreak({
    required List<CoupleInteraction> interactions,
    required DateTime today,
  }) {
    if (interactions.isEmpty) return 0;

    final activeDates = <String>{
      for (final item in interactions) dateKey(item.createdAt),
    };

    var cursor = dateOnly(today);
    if (!activeDates.contains(dateKey(cursor))) {
      final yesterday = addDays(cursor, -1);
      if (!activeDates.contains(dateKey(yesterday))) {
        return 0;
      }
      cursor = yesterday;
    }

    var streak = 0;
    while (activeDates.contains(dateKey(cursor))) {
      streak++;
      cursor = addDays(cursor, -1);
    }
    return streak;
  }
}
```

Update `lib/domain/cycle_profile.dart` to include `selectedMascot`, `partnerName`, and `anniversaryDate`:

```dart
import 'couple_care.dart';
import 'couple_interaction.dart';
import 'cycle_mascot.dart';

class CycleProfile {
  const CycleProfile({
    required this.id,
    required this.ownerUid,
    required this.memberUids,
    required this.name,
    this.partnerName = '',
    this.defaultCycleLength = 28,
    this.defaultPeriodLength = 5,
    this.activeSignal,
    this.signalReaction,
    this.customStickers = const [],
    this.lastInteraction,
    this.selectedMascot = MascotCharacter.mochiKitten,
    this.anniversaryDate,
  });

  final String id;
  final String ownerUid;
  final List<String> memberUids;
  final String name;
  final String partnerName;
  final int defaultCycleLength;
  final int defaultPeriodLength;
  final CoupleSignal? activeSignal;
  final PartnerReaction? signalReaction;
  final List<CustomCoupleSticker> customStickers;
  final Map<String, dynamic>? lastInteraction;
  final MascotCharacter selectedMascot;
  final DateTime? anniversaryDate;

  bool isOwner(String? uid) => uid != null && uid == ownerUid;

  bool get hasPartner => memberUids.length > 1;

  CycleProfile copyWith({
    String? id,
    String? ownerUid,
    List<String>? memberUids,
    String? name,
    String? partnerName,
    int? defaultCycleLength,
    int? defaultPeriodLength,
    CoupleSignal? activeSignal,
    PartnerReaction? signalReaction,
    List<CustomCoupleSticker>? customStickers,
    Map<String, dynamic>? lastInteraction,
    MascotCharacter? selectedMascot,
    DateTime? anniversaryDate,
  }) =>
      CycleProfile(
        id: id ?? this.id,
        ownerUid: ownerUid ?? this.ownerUid,
        memberUids: memberUids ?? this.memberUids,
        name: name ?? this.name,
        partnerName: partnerName ?? this.partnerName,
        defaultCycleLength: defaultCycleLength ?? this.defaultCycleLength,
        defaultPeriodLength: defaultPeriodLength ?? this.defaultPeriodLength,
        activeSignal: activeSignal ?? this.activeSignal,
        signalReaction: signalReaction ?? this.signalReaction,
        customStickers: customStickers ?? this.customStickers,
        lastInteraction: lastInteraction ?? this.lastInteraction,
        selectedMascot: selectedMascot ?? this.selectedMascot,
        anniversaryDate: anniversaryDate ?? this.anniversaryDate,
      );

  factory CycleProfile.fromMap(String id, Map<String, dynamic> map) {
    final rawStickers = map['customStickers'] as List?;
    final customStickers = rawStickers != null
        ? rawStickers
            .whereType<Map>()
            .map((e) => CustomCoupleSticker.fromMap(Map<String, dynamic>.from(e)))
            .toList()
        : const <CustomCoupleSticker>[];

    final rawLastInteraction = map['lastInteraction'];
    final lastInteraction = rawLastInteraction is Map
        ? Map<String, dynamic>.from(rawLastInteraction)
        : null;

    DateTime? parsedAnniversary;
    final rawAnniversary = map['anniversaryDate'];
    if (rawAnniversary is String && rawAnniversary.isNotEmpty) {
      parsedAnniversary = DateTime.tryParse(rawAnniversary);
    }

    return CycleProfile(
      id: id,
      ownerUid: (map['ownerUid'] as String?) ?? '',
      memberUids: List<String>.from(map['memberUids'] as List? ?? const []),
      name: (map['name'] as String?) ?? '',
      partnerName: (map['partnerName'] as String?) ?? '',
      defaultCycleLength: (map['defaultCycleLength'] as num?)?.toInt() ?? 28,
      defaultPeriodLength: (map['defaultPeriodLength'] as num?)?.toInt() ?? 5,
      activeSignal: _enumOrNull(CoupleSignal.values, map['activeSignal']),
      signalReaction: _enumOrNull(PartnerReaction.values, map['signalReaction']),
      customStickers: customStickers,
      lastInteraction: lastInteraction,
      selectedMascot: _enumOrNull(MascotCharacter.values, map['selectedMascot']) ??
          MascotCharacter.mochiKitten,
      anniversaryDate: parsedAnniversary,
    );
  }

  factory CycleProfile.fromDoc(dynamic doc) =>
      CycleProfile.fromMap(doc.id as String, (doc.data() as Map<String, dynamic>?) ?? {});
}

T? _enumOrNull<T extends Enum>(List<T> values, Object? name) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return null;
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/domain/cycle_mascot_and_streak_test.dart test/domain/cycle_profile_test.dart`
Expected: PASS

- [ ] **Step 5: Commit Task 1**

```bash
git add lib/domain/cycle_mascot.dart lib/domain/couple_streak_calculator.dart lib/domain/cycle_profile.dart test/domain/cycle_mascot_and_streak_test.dart
git commit -m "feat(domain): add CycleMascot, CoupleStreakCalculator, and profile relationship fields"
```

---

### Task 2: Repository Methods (`updateMascot`, `updateCoupleMetadata`, `markInteractionsAsRead`) & Firestore Security Rules

**Files:**
- Modify: `lib/data/profile_repository.dart:80-212`
- Modify: `firestore.rules:36-50`
- Modify Test: `test/data/couple_interaction_repository_test.dart`

**Interfaces:**
- Consumes: `MascotCharacter`, `CycleProfile`, `CoupleInteraction`
- Produces:
  - `ProfileRepository.updateMascot({required String profileId, required MascotCharacter mascot}) -> Future<void>`
  - `ProfileRepository.updateCoupleMetadata({required String profileId, String? partnerName, DateTime? anniversaryDate}) -> Future<void>`
  - `ProfileRepository.markInteractionsAsRead({required String profileId, required String readerUid}) -> Future<int>`

- [ ] **Step 1: Write the failing repository tests in `test/data/couple_interaction_repository_test.dart`**

Append to `test/data/couple_interaction_repository_test.dart`:

```dart
  test('updateMascot and updateCoupleMetadata persist to profile document', () async {
    await repo.updateMascot(
      profileId: 'p1',
      mascot: MascotCharacter.babyDino,
    );
    await repo.updateCoupleMetadata(
      profileId: 'p1',
      partnerName: 'Menza Sayang',
      anniversaryDate: DateTime(2024, 5, 10),
    );

    final doc = await db.doc('profiles/p1').get();
    expect(doc.data()?['selectedMascot'], 'babyDino');
    expect(doc.data()?['partnerName'], 'Menza Sayang');
    expect(doc.data()?['anniversaryDate'], '2024-05-10');
  });

  test('markInteractionsAsRead marks only incoming unread interactions as read', () async {
    await repo.sendInteraction(
      profileId: 'p1',
      senderUid: 'u1',
      senderName: 'Nata',
      emoji: '🧋',
      text: 'Mau boba',
    );
    await repo.sendInteraction(
      profileId: 'p1',
      senderUid: 'u2',
      senderName: 'Menza',
      emoji: '🧸',
      text: 'Peluk hangat',
    );

    // Reader is u2 -> should mark u1's message as read, leaving u2's own message unread for u1
    final updatedCount = await repo.markInteractionsAsRead(
      profileId: 'p1',
      readerUid: 'u2',
    );
    expect(updatedCount, 1);

    final snap = await db.collection('profiles/p1/interactions').get();
    for (final doc in snap.docs) {
      if (doc.data()['senderUid'] == 'u1') {
        expect(doc.data()['isRead'], isTrue);
      } else {
        expect(doc.data()['isRead'], isFalse);
      }
    }
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/couple_interaction_repository_test.dart`
Expected: FAIL (methods `updateMascot`, `updateCoupleMetadata`, and `markInteractionsAsRead` not defined).

- [ ] **Step 3: Implement repository methods in `lib/data/profile_repository.dart` and update `firestore.rules`**

Add to `lib/data/profile_repository.dart`:

```dart
  Future<void> updateMascot({
    required String profileId,
    required MascotCharacter mascot,
  }) =>
      _profile(profileId).update({
        'selectedMascot': mascot.name,
      });

  Future<void> updateCoupleMetadata({
    required String profileId,
    String? partnerName,
    DateTime? anniversaryDate,
  }) {
    final updates = <String, dynamic>{};
    if (partnerName != null) {
      updates['partnerName'] = partnerName.trim();
    }
    if (anniversaryDate != null) {
      final y = anniversaryDate.year.toString().padLeft(4, '0');
      final m = anniversaryDate.month.toString().padLeft(2, '0');
      final d = anniversaryDate.day.toString().padLeft(2, '0');
      updates['anniversaryDate'] = '$y-$m-$d';
    }
    return _profile(profileId).update(updates);
  }

  Future<int> markInteractionsAsRead({
    required String profileId,
    required String readerUid,
  }) async {
    final snapshot = await _db
        .collection('profiles')
        .doc(profileId)
        .collection('interactions')
        .where('isRead', isEqualTo: false)
        .get();

    final unreadFromPartner = snapshot.docs
        .where((doc) => doc.data()['senderUid'] != readerUid)
        .toList();

    if (unreadFromPartner.isEmpty) return 0;

    final batch = _db.batch();
    for (final doc in unreadFromPartner) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
    return unreadFromPartner.length;
  }
```

Update `firestore.rules` lines 38-48 to include `'partnerName'`, `'selectedMascot'`, and `'anniversaryDate'`:

```javascript
          && request.resource.data.diff(resource.data).affectedKeys().hasOnly([
            'name',
            'partnerName',
            'defaultCycleLength',
            'defaultPeriodLength',
            'activeSignal',
            'signalUpdatedAt',
            'signalReaction',
            'customStickers',
            'lastInteraction',
            'selectedMascot',
            'anniversaryDate'
          ]))
```

- [ ] **Step 4: Run repository tests to verify they pass**

Run: `flutter test test/data/couple_interaction_repository_test.dart`
Expected: PASS

- [ ] **Step 5: Commit Task 2**

```bash
git add lib/data/profile_repository.dart firestore.rules test/data/couple_interaction_repository_test.dart
git commit -m "feat(data): add mascot, couple metadata, and auto-read repository methods"
```

---

### Task 3: Interactive Vector Mascot Widget (`MascotCompanionCard`) & HomeScreen Integration

**Files:**
- Create: `lib/features/home/widgets/mascot_companion_card.dart`
- Modify: `lib/features/home/home_screen.dart:118-320`
- Create Test: `test/features/mascot_companion_card_test.dart`

**Interfaces:**
- Consumes: `MascotCharacter`, `MascotMoodState`, `CycleMascotAdvisor`
- Produces:
  - `MascotCompanionCard`:
    - Renders custom-painted pastel mascot avatar (`_MascotVectorPainter`) with cute ears/horns/hair, dynamic eyes (`comfyRest` closed arcs, `sparklingHappy` starry eyes, `glowingLove` heart blush, `cravingPouty` pleading eyes), and animated floating/bounce.
    - Tapping the mascot or speech bubble cycles through `bubbleMessages`.
    - Tapping "Ganti Maskot ✨" opens bottom sheet picker (`MascotCharacter.values`) and calls `onSelectMascot`.

- [ ] **Step 1: Write the failing widget test for `MascotCompanionCard` and `HomeScreen` integration**

```dart
// test/features/mascot_companion_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/domain/cycle_mascot.dart';
import 'package:siklus/domain/cycle_phase.dart';
import 'package:siklus/features/home/widgets/mascot_companion_card.dart';
import 'package:siklus/theme/cycle_theme.dart';

void main() {
  testWidgets('MascotCompanionCard renders character, cycles bubble quote on tap, and opens character picker', (tester) async {
    MascotCharacter? selected;

    await tester.pumpWidget(
      MaterialApp(
        theme: CycleTheme.lightTheme,
        home: Scaffold(
          body: MascotCompanionCard(
            character: MascotCharacter.mochiKitten,
            phase: CyclePhase.menstrual,
            todayEntry: null,
            isPartner: false,
            partnerName: 'Nata',
            onSelectMascot: (next) => selected = next,
          ),
        ),
      ),
    );

    expect(find.textContaining('Mochi Kitten'), findsOneWidget);
    expect(find.textContaining('Mode Istirahat'), findsOneWidget);

    final quotes = CycleMascotAdvisor.bubbleMessages(
      character: MascotCharacter.mochiKitten,
      state: MascotMoodState.comfyRest,
      isPartner: false,
      partnerName: 'Nata',
    );
    expect(find.text(quotes[0]), findsOneWidget);

    // Tap mascot card to cycle speech bubble
    await tester.tap(find.byKey(const Key('mascotTapArea')));
    await tester.pump();
    expect(find.text(quotes[1]), findsOneWidget);

    // Open mascot picker sheet
    await tester.tap(find.byKey(const Key('changeMascotButton')));
    await tester.pumpAndSettle();

    expect(find.text('Fluffy Bunny'), findsOneWidget);
    await tester.tap(find.text('Fluffy Bunny'));
    await tester.pumpAndSettle();

    expect(selected, MascotCharacter.fluffyBunny);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/mascot_companion_card_test.dart`
Expected: FAIL (`mascot_companion_card.dart` does not exist yet).

- [ ] **Step 3: Implement `MascotCompanionCard` with custom vector illustration and wire into `HomeScreen`**

Create `lib/features/home/widgets/mascot_companion_card.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../domain/cycle_mascot.dart';
import '../../../domain/cycle_phase.dart';
import '../../../domain/day_entry.dart';
import '../../../theme/cycle_theme.dart';

class MascotCompanionCard extends StatefulWidget {
  const MascotCompanionCard({
    super.key,
    required this.character,
    required this.phase,
    required this.todayEntry,
    required this.isPartner,
    required this.partnerName,
    required this.onSelectMascot,
  });

  final MascotCharacter character;
  final CyclePhase phase;
  final DayEntry? todayEntry;
  final bool isPartner;
  final String partnerName;
  final ValueChanged<MascotCharacter> onSelectMascot;

  @override
  State<MascotCompanionCard> createState() => _MascotCompanionCardState();
}

class _MascotCompanionCardState extends State<MascotCompanionCard>
    with SingleTickerProviderStateMixin {
  int _quoteIndex = 0;
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    final bindingName = WidgetsBinding.instance.runtimeType.toString();
    if (!bindingName.contains('Test')) {
      _floatController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  void _cycleQuote() {
    setState(() {
      _quoteIndex++;
    });
  }

  Future<void> _openMascotPicker(BuildContext context) async {
    final chosen = await showModalBottomSheet<MascotCharacter>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        final theme = Theme.of(sheetCtx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilih Maskot Pendamping ✨',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Karakter pilihanmu akan tampil di Beranda kalian berdua dan berekspresi sesuai fase siklus.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 14),
                for (final item in MascotCharacter.values)
                  ListTile(
                    key: Key('mascot_option_${item.name}'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundColor: CycleColors.primary.withValues(alpha: 0.12),
                      child: Text(item.emoji, style: const TextStyle(fontSize: 22)),
                    ),
                    title: Text(
                      item.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      item.tagline,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: item == widget.character
                        ? const Icon(Icons.check_circle_rounded, color: CycleColors.primary)
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    onTap: () => Navigator.of(sheetCtx).pop(item),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (chosen != null && chosen != widget.character) {
      widget.onSelectMascot(chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final moodState = CycleMascotAdvisor.resolveMoodState(
      phase: widget.phase,
      todayEntry: widget.todayEntry,
    );
    final messages = CycleMascotAdvisor.bubbleMessages(
      character: widget.character,
      state: moodState,
      isPartner: widget.isPartner,
      partnerName: widget.partnerName,
    );
    final activeQuote = messages[_quoteIndex % messages.length];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  CycleColors.surfaceDark,
                  CycleColors.primary.withValues(alpha: 0.14),
                ]
              : [
                  Colors.white,
                  CycleColors.secondary.withValues(alpha: 0.16),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: CycleColors.primary.withValues(alpha: isDark ? 0.3 : 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: CycleColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${moodState.badgeEmoji} ${widget.character.displayName} • ${moodState.statusLabel}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: CycleColors.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                key: const Key('changeMascotButton'),
                onPressed: () => _openMascotPicker(context),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                ),
                icon: const Icon(Icons.auto_awesome_rounded, size: 14, color: CycleColors.primary),
                label: const Text(
                  'Ganti',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: CycleColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            key: const Key('mascotTapArea'),
            borderRadius: BorderRadius.circular(16),
            onTap: _cycleQuote,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _floatController,
                    builder: (context, child) {
                      final dy = (_floatController.value - 0.5) * 6.0;
                      return Transform.translate(
                        offset: Offset(0, dy),
                        child: child,
                      );
                    },
                    child: SizedBox(
                      width: 68,
                      height: 68,
                      child: CustomPaint(
                        painter: _MascotVectorPainter(
                          character: widget.character,
                          moodState: moodState,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: CycleColors.primary.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeQuote,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.38,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ketuk maskot untuk sapaan lainnya 💬',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MascotVectorPainter extends CustomPainter {
  const _MascotVectorPainter({
    required this.character,
    required this.moodState,
  });

  final MascotCharacter character;
  final MascotMoodState moodState;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 4);
    final radius = size.width * 0.34;

    final bodyColor = switch (character) {
      MascotCharacter.mochiKitten => const Color(0xFFFFF1F5),
      MascotCharacter.fluffyBunny => const Color(0xFFFDF2F8),
      MascotCharacter.babyDino => const Color(0xFFECFDF5),
      MascotCharacter.chibiGirl => const Color(0xFFFFF7ED),
    };

    final accentColor = switch (character) {
      MascotCharacter.mochiKitten => CycleColors.primary,
      MascotCharacter.fluffyBunny => CycleColors.secondary,
      MascotCharacter.babyDino => const Color(0xFF10B981),
      MascotCharacter.chibiGirl => const Color(0xFFF43F5E),
    };

    final earPaint = Paint()..color = accentColor.withValues(alpha: 0.35);
    final bodyPaint = Paint()..color = bodyColor;
    final outlinePaint = Paint()
      ..color = accentColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Ears / Horns / Hair buns based on character
    if (character == MascotCharacter.fluffyBunny) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx - 11, center.dy - radius - 8),
          width: 10,
          height: 22,
        ),
        earPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx + 11, center.dy - radius - 8),
          width: 10,
          height: 22,
        ),
        earPaint,
      );
    } else if (character == MascotCharacter.mochiKitten) {
      final leftEar = Path()
        ..moveTo(center.dx - 18, center.dy - 10)
        ..lineTo(center.dx - 22, center.dy - radius - 8)
        ..lineTo(center.dx - 4, center.dy - 18)
        ..close();
      final rightEar = Path()
        ..moveTo(center.dx + 18, center.dy - 10)
        ..lineTo(center.dx + 22, center.dy - radius - 8)
        ..lineTo(center.dx + 4, center.dy - 18)
        ..close();
      canvas.drawPath(leftEar, earPaint);
      canvas.drawPath(rightEar, earPaint);
    } else if (character == MascotCharacter.babyDino) {
      canvas.drawCircle(Offset(center.dx, center.dy - radius - 5), 5, earPaint);
      canvas.drawCircle(Offset(center.dx - 12, center.dy - radius - 1), 4, earPaint);
      canvas.drawCircle(Offset(center.dx + 12, center.dy - radius - 1), 4, earPaint);
    } else {
      canvas.drawCircle(Offset(center.dx - 18, center.dy - 14), 8, earPaint);
      canvas.drawCircle(Offset(center.dx + 18, center.dy - 14), 8, earPaint);
    }

    // Face circle
    canvas.drawCircle(center, radius, bodyPaint);
    canvas.drawCircle(center, radius, outlinePaint);

    // Rosy cheeks
    final cheekPaint = Paint()..color = const Color(0xFFFB7185).withValues(alpha: 0.45);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx - 12, center.dy + 3), width: 9, height: 5),
      cheekPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx + 12, center.dy + 3), width: 9, height: 5),
      cheekPaint,
    );

    // Eyes & Mouth based on MascotMoodState
    final featurePaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final eyeFillPaint = Paint()..color = const Color(0xFF334155);

    if (moodState == MascotMoodState.comfyRest) {
      // Closed comfy eyes
      canvas.drawArc(
        Rect.fromCenter(center: Offset(center.dx - 9, center.dy - 3), width: 8, height: 5),
        0,
        3.14,
        false,
        featurePaint,
      );
      canvas.drawArc(
        Rect.fromCenter(center: Offset(center.dx + 9, center.dy - 3), width: 8, height: 5),
        0,
        3.14,
        false,
        featurePaint,
      );
    } else {
      canvas.drawCircle(Offset(center.dx - 9, center.dy - 3), 2.8, eyeFillPaint);
      canvas.drawCircle(Offset(center.dx + 9, center.dy - 3), 2.8, eyeFillPaint);
    }

    // Mouth
    if (moodState == MascotMoodState.cravingPouty) {
      canvas.drawArc(
        Rect.fromCenter(center: Offset(center.dx, center.dy + 7), width: 7, height: 4),
        3.14,
        3.14,
        false,
        featurePaint,
      );
    } else {
      canvas.drawArc(
        Rect.fromCenter(center: Offset(center.dx, center.dy + 4), width: 8, height: 6),
        0,
        3.14,
        false,
        featurePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MascotVectorPainter oldDelegate) {
    return oldDelegate.character != character || oldDelegate.moodState != moodState;
  }
}
```

Update `lib/features/home/home_screen.dart` to render `MascotCompanionCard` right above `CycleDial` and add helper `_updateMascot`:

```dart
  void _updateMascot({
    required WidgetRef ref,
    required String? profileId,
    required MascotCharacter mascot,
  }) {
    if (profileId == null) return;
    unawaited(
      ref
          .read(profileRepositoryProvider)
          .updateMascot(profileId: profileId, mascot: mascot)
          .catchError((Object e) {
        debugPrint('Gagal mengubah maskot: $e');
      }),
    );
  }
```

And inside `HomeScreen.build` column (above `CycleDial`):

```dart
                // Mascot Companion Card
                MascotCompanionCard(
                  character: profile?.selectedMascot ?? MascotCharacter.mochiKitten,
                  phase: phase,
                  todayEntry: todayEntry,
                  isPartner: isPartner,
                  partnerName: profileName,
                  onSelectMascot: (mascot) => _updateMascot(
                    ref: ref,
                    profileId: profileId ?? profile?.id,
                    mascot: mascot,
                  ),
                ),
                const SizedBox(height: 16),
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/mascot_companion_card_test.dart test/features/home_screen_test.dart test/features/partner_differentiated_home_test.dart`
Expected: PASS

- [ ] **Step 5: Commit Task 3**

```bash
git add lib/features/home/widgets/mascot_companion_card.dart lib/features/home/home_screen.dart test/features/mascot_companion_card_test.dart
git commit -m "feat(home): add interactive vector MascotCompanionCard synchronized across couple profile"
```

---

### Task 4: `LoveHeaderBadge` 2.0 (Partner Name, Anniversary Counter, Care Streak) & `CoupleSpaceScreen` UX Refinements

**Files:**
- Modify: `lib/features/couple/widgets/love_header_badge.dart:1-217`
- Modify: `lib/features/couple/widgets/care_sticker_tray.dart:1-256`
- Modify: `lib/features/couple/couple_space_screen.dart:356-441`
- Modify Test: `test/features/couple_space_screen_test.dart`

**Interfaces:**
- Consumes: `CoupleStreakCalculator`, `coupleInteractionsProvider`, `todayProvider`, `profileRepositoryProvider`.
- Produces:
  - `LoveHeaderBadge`:
    - Displays real `partnerName` (if configured), `💕 X Hari Bersama` (or `'Atur Tanggal Jadian 💕'`), and `🔥 X Hari Streak`.
    - Tapping header / edit icon opens dialog to set `partnerName` and pick `anniversaryDate`.
  - `CareStickerTray`:
    - Adds `IconButton(key: const Key('sendQuickNoteBtn'), icon: const Icon(Icons.send_rounded))` inside `quickLoveNoteInput` so users can send a direct love note (`💌`) without tapping a sticker chip.
    - Custom stickers support `onLongPress` / delete confirmation to call `deleteCustomSticker`.
  - `CoupleSpaceScreen`:
    - Automatically triggers `markInteractionsAsRead` when incoming unread messages exist.

- [ ] **Step 1: Write the failing widget tests in `test/features/couple_space_screen_test.dart`**

Add to `test/features/couple_space_screen_test.dart`:

```dart
  testWidgets('LoveHeaderBadge displays anniversary days together and care streak', (tester) async {
    await db.collection('profiles/p1/interactions').doc('i_streak').set({
      'senderUid': 'u1',
      'senderName': 'Nata',
      'emoji': '🧋',
      'text': 'Boba favorit',
      'createdAt': DateTime(2026, 10, 29, 9, 0).toIso8601String(),
      'isRead': false,
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayProvider.overrideWithValue(DateTime(2026, 10, 29)),
          firebaseAuthProvider.overrideWithValue(auth),
          firestoreProvider.overrideWithValue(db),
          activeProfileIdProvider.overrideWith((ref) => Stream.value('p1')),
          activeProfileProvider.overrideWith(
            (ref) => Stream.value(
              CycleProfile(
                id: 'p1',
                name: 'Nata',
                partnerName: 'Menza',
                ownerUid: 'u1',
                memberUids: const ['u1', 'u2'],
                anniversaryDate: DateTime(2026, 10, 20),
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

    expect(find.textContaining('10 Hari Bersama'), findsOneWidget);
    expect(find.textContaining('1 Hari Streak'), findsOneWidget);
  });

  testWidgets('CareStickerTray allows sending standalone love note via send button', (tester) async {
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
                partnerName: 'Menza',
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

    await tester.enterText(
      find.byKey(const Key('quickLoveNoteInput')),
      'Semangat kerjanya hari ini sayang!',
    );
    await tester.tap(find.byKey(const Key('sendQuickNoteBtn')));
    await tester.pumpAndSettle();

    final interactions = await db.collection('profiles/p1/interactions').get();
    expect(interactions.docs.length, 1);
    expect(interactions.docs.first.data()['text'], 'Semangat kerjanya hari ini sayang!');
    expect(interactions.docs.first.data()['emoji'], '💌');
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/couple_space_screen_test.dart`
Expected: FAIL (`10 Hari Bersama`, `1 Hari Streak`, and `sendQuickNoteBtn` not found yet).

- [ ] **Step 3: Implement `LoveHeaderBadge` 2.0, `CareStickerTray` standalone send & delete custom sticker, and `CoupleSpaceScreen` auto-read**

1. Update `lib/features/couple/widgets/love_header_badge.dart`:
   - Read `today = ref.watch(todayProvider)` and `interactions = ref.watch(coupleInteractionsProvider).valueOrNull ?? const []`.
   - Compute `daysTogether = CoupleStreakCalculator.daysTogether(anniversaryDate: widget.profile.anniversaryDate, today: today)`.
   - Compute `streak = CoupleStreakCalculator.calculateStreak(interactions: interactions, today: today)`.
   - Resolve `partnerDisplayName`: for owner, `widget.profile.partnerName.trim().isNotEmpty ? widget.profile.partnerName.trim() : 'Pasangan'`; for partner, `widget.profile.name.trim().isNotEmpty ? widget.profile.name.trim() : 'Pasangan'`.
   - Render pill badges for `💕 ${daysTogether} Hari Bersama` (or `'Atur Tanggal Jadian 💕'`) and `🔥 $streak Hari Streak`.
   - Add `_openCoupleMetadataDialog(BuildContext context)` on tap to edit `partnerName` and `anniversaryDate` via `ref.read(profileRepositoryProvider).updateCoupleMetadata(...)`.

2. Update `lib/features/couple/widgets/care_sticker_tray.dart`:
   - Add `_sendStandaloneNote()` method that sends an interaction with `emoji: '💌'` and `text: _noteController.text.trim()` when the note input is non-empty.
   - Add `suffixIcon: IconButton(key: const Key('sendQuickNoteBtn'), icon: const Icon(Icons.send_rounded, size: 18, color: CycleColors.primary), onPressed: _isSending ? null : _sendStandaloneNote)` to `quickLoveNoteInput`.
   - Wrap custom stickers (`!sticker.id.startsWith('default_')`) with `onDeleted` on `InputChip` (or long-press confirmation dialog) calling `ref.read(profileRepositoryProvider).deleteCustomSticker(profileId: widget.profile.id, stickerId: sticker.id)`.

3. Update `lib/features/couple/couple_space_screen.dart`:
   - In `_buildConnectedView`, check if `interactions` contains any item where `!i.isRead && user != null && i.senderUid != user.uid`. If so, schedule a post-frame call to `ref.read(profileRepositoryProvider).markInteractionsAsRead(profileId: profile.id, readerUid: user.uid)`.

- [ ] **Step 4: Run full test suite and analyzer to verify everything passes**

Run: `flutter test; flutter analyze`
Expected: All unit & widget tests PASS, 0 analyzer issues.

- [ ] **Step 5: Commit Task 4**

```bash
git add lib/features/couple/ test/features/couple_space_screen_test.dart
git commit -m "feat(couple): add Anniversary & Care Streak badges, standalone love note send, custom sticker deletion, and auto-read"
```
