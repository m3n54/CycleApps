# CycleApp Phase 2: Personal & Interactive Features Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add two-way Couple Care signals/reactions, contextual memory greetings with a smart hormonal body explainer card, and an automatic phase-based daily self-care checklist to CycleApp.

**Architecture:** We extend the pure domain layer (`DayEntry`, `CycleProfile`, and new domain helpers `CoupleCareInfo`, `PersonalCareAdvisor`) with zero external dependencies, persist `selfCareCompleted` inside `profiles/{profileId}/days/{date}` and `activeSignal`/`signalReaction` inside `profiles/{profileId}`, and surface interactive cards in `HomeScreen` tailored to whether the signed-in user is the cycle owner or partner.

**Tech Stack:** Flutter (Material 3), `flutter_riverpod`, `cloud_firestore`, `fake_cloud_firestore` (tests).

**Spec:** `docs/superpowers/specs/2026-10-16-personal-interactive-features-design.md`

## Global Constraints

- Flutter CLI path on Windows: `& "C:\src\flutter\bin\flutter.bat"`
- All user-facing copy MUST be in natural, warm Indonesian.
- Maintain offline-first behavior: Firestore mutations triggered from UI must use `unawaited(...)` with `.catchError(...)`.
- Preserve backward compatibility in `DayEntry.fromMap` and `CycleProfile.fromMap` when new fields are absent or `null`.
- Support both Light and Dark themes (`CycleColors`) and narrow viewports (`ResponsiveBounds` / `Expanded` / `Flexible`).

---

### Task 1: Domain & Data Layer for Self-Care Checklist and Couple Signals

**Files:**
- Create: `lib/domain/couple_care.dart`
- Modify: `lib/domain/day_entry.dart`
- Modify: `lib/domain/cycle_profile.dart`
- Modify: `lib/data/profile_repository.dart`
- Test: `test/domain/couple_care_and_models_test.dart`

**Interfaces:**
- Consumes: `CyclePhase` from `lib/domain/cycle_phase.dart`
- Produces:
  - `enum CoupleSignal { cravingSweet, needHug, needRest, sensitiveMood, qualityTime }`
  - `enum PartnerReaction { hugSent, onTheWay, takeRest, hereForYou }`
  - `CoupleCareCatalog` with labels, icons, and partner tips per `CyclePhase`
  - `DayEntry.selfCareCompleted` (`Set<String>`) and `DayEntry.copyWith({...})`
  - `CycleProfile.activeSignal` (`CoupleSignal?`), `CycleProfile.signalReaction` (`PartnerReaction?`), `CycleProfile.isOwner(String? uid)`
  - `ProfileRepository.sendSignal({required String profileId, required CoupleSignal? signal})`
  - `ProfileRepository.sendReaction({required String profileId, required PartnerReaction? reaction})`

- [ ] **Step 1: Write the failing test**

Create `test/domain/couple_care_and_models_test.dart`:

```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/data/profile_repository.dart';
import 'package:siklus/domain/couple_care.dart';
import 'package:siklus/domain/cycle_phase.dart';
import 'package:siklus/domain/cycle_profile.dart';
import 'package:siklus/domain/day_entry.dart';

void main() {
  test('DayEntry serializes and deserializes selfCareCompleted and supports copyWith', () {
    const entry = DayEntry(
      date: '2026-10-16',
      selfCareCompleted: {'warm_drink', 'early_sleep'},
    );
    expect(entry.isEmpty, isFalse);

    final map = entry.toMap();
    expect(map['selfCareCompleted'], ['early_sleep', 'warm_drink']);

    final restored = DayEntry.fromMap(map);
    expect(restored.selfCareCompleted, {'warm_drink', 'early_sleep'});

    final updated = restored.copyWith(selfCareCompleted: {'warm_drink'});
    expect(updated.selfCareCompleted, {'warm_drink'});
  });

  test('CycleProfile parses activeSignal, signalReaction, and checks isOwner', () {
    final profile = CycleProfile.fromMap('p1', {
      'ownerUid': 'alice',
      'memberUids': ['alice', 'bob'],
      'name': 'Alice',
      'defaultCycleLength': 28,
      'defaultPeriodLength': 5,
      'activeSignal': 'cravingSweet',
      'signalReaction': 'onTheWay',
    });

    expect(profile.isOwner('alice'), isTrue);
    expect(profile.isOwner('bob'), isFalse);
    expect(profile.activeSignal, CoupleSignal.cravingSweet);
    expect(profile.signalReaction, PartnerReaction.onTheWay);
  });

  test('ProfileRepository sendSignal and sendReaction update Firestore profile doc', () async {
    final db = FakeFirebaseFirestore();
    final repo = ProfileRepository(db);
    final profileId = await repo.createProfile(uid: 'alice', name: 'Alice');

    await repo.sendSignal(profileId: profileId, signal: CoupleSignal.needHug);
    var current = await repo.watchProfile(profileId).first;
    expect(current?.activeSignal, CoupleSignal.needHug);
    expect(current?.signalReaction, isNull);

    await repo.sendReaction(profileId: profileId, reaction: PartnerReaction.hugSent);
    current = await repo.watchProfile(profileId).first;
    expect(current?.signalReaction, PartnerReaction.hugSent);
  });

  test('CoupleCareCatalog returns partner tips for all 4 cycle phases', () {
    for (final phase in CyclePhase.values) {
      final tip = CoupleCareCatalog.partnerTipForPhase(phase);
      expect(tip.title, isNotEmpty);
      expect(tip.actionSuggestion, isNotEmpty);
    }
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\src\flutter\bin\flutter.bat" test test/domain/couple_care_and_models_test.dart`
Expected: FAIL with `Target of URI doesn't exist: 'package:siklus/domain/couple_care.dart'`

- [ ] **Step 3: Write minimal implementation**

Create `lib/domain/couple_care.dart`, update `lib/domain/day_entry.dart`, `lib/domain/cycle_profile.dart`, and `lib/data/profile_repository.dart`.

- [ ] **Step 4: Run test to verify it passes**

Run: `& "C:\src\flutter\bin\flutter.bat" test test/domain/couple_care_and_models_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/domain/couple_care.dart lib/domain/day_entry.dart lib/domain/cycle_profile.dart lib/data/profile_repository.dart test/domain/couple_care_and_models_test.dart
git commit -m "feat(domain): add couple care signals, reactions, and selfCareCompleted model"
```

---

### Task 2: Domain Logic for Contextual Greeting, Smart Body Explainer & Daily Self-Care Missions

**Files:**
- Create: `lib/domain/personal_care_advisor.dart`
- Test: `test/domain/personal_care_advisor_test.dart`

**Interfaces:**
- Consumes: `CyclePhase`, `DayEntry`, `Symptom`, `Mood`
- Produces:
  - `PersonalCareAdvisor.contextualGreeting({required String profileName, required CyclePhase phase, DayEntry? todayEntry, DayEntry? yesterdayEntry, required bool isPartner})`
  - `BodyExplanation? PersonalCareAdvisor.explainToday({required CyclePhase phase, DayEntry? todayEntry})`
  - `List<SelfCareMission> PersonalCareAdvisor.missionsForPhase(CyclePhase phase)`

- [ ] **Step 1: Write the failing test**

Create `test/domain/personal_care_advisor_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/domain/cycle_phase.dart';
import 'package:siklus/domain/day_entry.dart';
import 'package:siklus/domain/personal_care_advisor.dart';

void main() {
  test('contextualGreeting remembers yesterday symptoms and adapts message', () {
    const yesterday = DayEntry(
      date: '2026-10-15',
      symptoms: {Symptom.cramps},
    );
    final greeting = PersonalCareAdvisor.contextualGreeting(
      profileName: 'Nata',
      phase: CyclePhase.menstrual,
      todayEntry: null,
      yesterdayEntry: yesterday,
      isPartner: false,
    );
    expect(greeting.headline, contains('Nata'));
    expect(greeting.message.toLowerCase(), contains('kram'));
  });

  test('explainToday returns hormonal explanation and relief tip when symptoms or moods logged', () {
    const today = DayEntry(
      date: '2026-10-16',
      symptoms: {Symptom.cramps, Symptom.bloating},
      moods: {Mood.sensitive},
    );
    final explanation = PersonalCareAdvisor.explainToday(
      phase: CyclePhase.menstrual,
      todayEntry: today,
    );
    expect(explanation, isNotNull);
    expect(explanation!.title, isNotEmpty);
    expect(explanation.whyItHappens, isNotEmpty);
    expect(explanation.quickRelief, isNotEmpty);
  });

  test('explainToday returns null when todayEntry is empty', () {
    final explanation = PersonalCareAdvisor.explainToday(
      phase: CyclePhase.follicular,
      todayEntry: const DayEntry(date: '2026-10-16'),
    );
    expect(explanation, isNull);
  });

  test('missionsForPhase returns 3 actionable missions for every phase', () {
    for (final phase in CyclePhase.values) {
      final missions = PersonalCareAdvisor.missionsForPhase(phase);
      expect(missions.length, 3);
      expect(missions.map((m) => m.id).toSet().length, 3);
    }
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\src\flutter\bin\flutter.bat" test test/domain/personal_care_advisor_test.dart`
Expected: FAIL with `Target of URI doesn't exist: 'package:siklus/domain/personal_care_advisor.dart'`

- [ ] **Step 3: Write minimal implementation**

Create `lib/domain/personal_care_advisor.dart` implementing `ContextualGreeting`, `BodyExplanation`, `SelfCareMission`, and `PersonalCareAdvisor`.

- [ ] **Step 4: Run test to verify it passes**

Run: `& "C:\src\flutter\bin\flutter.bat" test test/domain/personal_care_advisor_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/domain/personal_care_advisor.dart test/domain/personal_care_advisor_test.dart
git commit -m "feat(domain): add PersonalCareAdvisor for greeting, body explainer, and self-care missions"
```

---

### Task 3: UI Widgets & HomeScreen Integration for Personal & Interactive Features

**Files:**
- Create: `lib/features/home/widgets/body_explainer_card.dart`
- Create: `lib/features/home/widgets/self_care_checklist_card.dart`
- Create: `lib/features/home/widgets/couple_care_card.dart`
- Modify: `lib/features/home/home_screen.dart`
- Test: `test/features/personal_home_features_test.dart`

**Interfaces:**
- Consumes: `PersonalCareAdvisor`, `CoupleCareCatalog`, `DayEntry`, `CycleProfile`, `dayRepositoryProvider`, `profileRepositoryProvider`
- Produces:
  - `BodyExplainerCard`: displays hormonal explanation + quick relief tip when `todayEntry` has symptoms/moods
  - `SelfCareChecklistCard`: displays 3 phase missions with progress `X/3` and saves toggle directly via `dayRepositoryProvider`
  - `CoupleCareCard`: adapts to `isOwner` (send/clear 1-click signal + see partner reaction) vs `isPartner` (partner phase guide + see owner signal + send 1-click reaction)
  - Updated `HomeScreen` integrating contextual greeting banner, `CoupleCareCard`, `BodyExplainerCard`, and `SelfCareChecklistCard`

- [ ] **Step 1: Write the failing test**

Create `test/features/personal_home_features_test.dart` testing:
1. Owner view: contextual greeting from yesterday's cramps, `BodyExplainerCard` for today's symptoms, `SelfCareChecklistCard` toggling a mission, and `CoupleCareCard` sending a `CoupleSignal`.
2. Partner view (`uid != profile.ownerUid`): shows Partner Guide for current phase, shows active signal from owner, and allows tapping a 1-click `PartnerReaction`.

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\src\flutter\bin\flutter.bat" test test/features/personal_home_features_test.dart`
Expected: FAIL with missing widget files

- [ ] **Step 3: Write minimal implementation**

Create `body_explainer_card.dart`, `self_care_checklist_card.dart`, `couple_care_card.dart`, and integrate them into `lib/features/home/home_screen.dart`.

- [ ] **Step 4: Run test to verify it passes**

Run: `& "C:\src\flutter\bin\flutter.bat" test`
Expected: All tests pass, `flutter analyze` reports 0 issues.

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/ test/features/personal_home_features_test.dart
git commit -m "feat(home): integrate CoupleCareCard, BodyExplainerCard, SelfCareChecklistCard, and contextual greeting"
```
