# CycleApp Complete UI/UX Redesign & Feature Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the application from a basic template into a premium, world-class menstrual cycle tracking and partner synchronization app ("CycleApp") with a Modern Soft Wellness aesthetic, branded auth/onboarding, interactive Hero Cycle Dial, rich visual health logging, 4-phase educational insights, and 4-tab navigation.

**Architecture:** 
- **Visual Design System (`CycleTheme`):** Soft UI Evolution tokens with semantic light (Blush Rose `#BE185D`, Lavender `#7C3AED`, warm white `#FDF8FA`) and dark (Deep Velvet Plum `#160F1A`, Surface `#24182B`) modes, custom circular cycle dial painter, soft shadows, and rounded cards.
- **Domain & State Layer:** Enhanced `CyclePredictor` with phase detection (`menstrual`, `follicular`, `ovulation`, `luteal`), cycle day count, daily wellness tips, and extended `DayEntry` (adding cervical mucus and intimacy tracking with backward compatibility).
- **Presentation Layer:** 
  1. Branded `LoginScreen` & `OnboardingScreen` with logo and role cards.
  2. 4-Tab `HomeShell` featuring:
     - `HomeScreen`: Hero Cycle Dial + phase status + daily tips card + quick log CTA.
     - `CalendarScreen`: Redesigned visual calendar with phase markers and day detail card.
     - `InsightsScreen`: Cycle statistics, cycle history, and 4-phase educational guide.
     - `SettingsScreen`: Profile, partner sync with copyable code, and theme toggle.
  3. `DayLogScreen`: Categorized icon grid for comprehensive daily tracking.

**Tech Stack:** Flutter 3.x, Flutter Riverpod 2.6.1, TableCalendar, Firebase Auth/Firestore, Intl.

**Spec:** Requirements gathered and approved via `/grill-me` interviews:
- App Name: "CycleApp".
- Theme: Modern Soft Wellness with Light & Dark mode support.
- Full Flow: Login & Onboarding -> Home -> Calendar -> Insights -> Settings -> Day Log.

## Global Constraints
- All 51 existing unit tests must remain passing or be updated for enhanced models.
- No raw emojis used as system icons; use Flutter's Material / Cupertino vector icons.
- Backward compatibility: Existing Firestore `day_entries` must deserialize without errors even when new optional fields are absent.
- Indonesian localization (`id_ID`) maintained for all user-facing copy.

---

### Task 1: Rebrand App to CycleApp & Setup Modern Soft Wellness Theme Tokens

**Files:**
- Create: `lib/theme/cycle_theme.dart`
- Modify: `lib/app.dart`
- Modify: `web/index.html`
- Modify: `web/manifest.json`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Create: `test/theme/cycle_theme_test.dart`

**Interfaces:**
- Produces: `CycleTheme.lightTheme`, `CycleTheme.darkTheme`, `CycleColors` semantic palette.
- Renames: App display title to "CycleApp".

- [ ] **Step 1: Write failing test for CycleTheme and app title**

```dart
// test/theme/cycle_theme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/theme/cycle_theme.dart';

void main() {
  test('CycleTheme provides distinct light and dark themes with custom colors', () {
    final light = CycleTheme.lightTheme;
    final dark = CycleTheme.darkTheme;

    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    expect(light.colorScheme.primary, const Color(0xFFBE185D));
    expect(dark.colorScheme.primary, const Color(0xFFF472B6));
    expect(CycleColors.phaseMenstrual, const Color(0xFFE11D48));
    expect(CycleColors.phaseOvulation, const Color(0xFF7C3AED));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\src\flutter\bin\flutter.bat" test test/theme/cycle_theme_test.dart`
Expected: FAIL with compilation error (file not found)

- [ ] **Step 3: Implement CycleTheme and update branding files**

Create `lib/theme/cycle_theme.dart`:
```dart
import 'package:flutter/material.dart';

class CycleColors {
  static const primary = Color(0xFFBE185D); // Blush Rose
  static const secondary = Color(0xFFEC4899); // Soft Berry
  static const accent = Color(0xFF7C3AED); // Fertility Lavender
  static const backgroundLight = Color(0xFFFDF8FA);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const borderLight = Color(0xFFFCE7F0);

  static const backgroundDark = Color(0xFF160F1A);
  static const surfaceDark = Color(0xFF24182B);
  static const borderDark = Color(0xFF3B2844);

  // Cycle Phase Colors
  static const phaseMenstrual = Color(0xFFE11D48); // Rose red
  static const phaseFollicular = Color(0xFFFB7185); // Warm pink
  static const phaseOvulation = Color(0xFF7C3AED); // Deep lavender
  static const phaseLuteal = Color(0xFFF43F5E); // Soft coral
}

class CycleTheme {
  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: CycleColors.primary,
        secondary: CycleColors.secondary,
        surface: CycleColors.surfaceLight,
        error: Color(0xFFDC2626),
      ),
      scaffoldBackgroundColor: CycleColors.backgroundLight,
      cardTheme: CardTheme(
        color: CycleColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: CycleColors.borderLight),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: CycleColors.backgroundLight,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    return base;
  }

  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFF472B6),
        secondary: Color(0xFFFB7185),
        surface: CycleColors.surfaceDark,
        error: Color(0xFFEF4444),
      ),
      scaffoldBackgroundColor: CycleColors.backgroundDark,
      cardTheme: CardTheme(
        color: CycleColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: CycleColors.borderDark),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: CycleColors.backgroundDark,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    return base;
  }
}
```

Update `lib/app.dart` to use `title: 'CycleApp'`, `theme: CycleTheme.lightTheme`, `darkTheme: CycleTheme.darkTheme`.
Update `web/index.html` title to "CycleApp".
Update `web/manifest.json` name and short_name to "CycleApp".
Update `android/app/src/main/AndroidManifest.xml` android:label to "CycleApp".

- [ ] **Step 4: Run test to verify it passes**

Run: `& "C:\src\flutter\bin\flutter.bat" test test/theme/cycle_theme_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/theme/ lib/app.dart web/ android/ test/theme/
git commit -m "feat(theme): rebrand to CycleApp and implement Modern Soft Wellness theme tokens"
```

---

### Task 2: Extend Domain Models for Cycle Phases, Tips, & Rich Logging

**Files:**
- Create: `lib/domain/cycle_phase.dart`
- Create: `lib/domain/cycle_phase_info.dart`
- Modify: `lib/domain/cycle_predictor.dart`
- Modify: `lib/domain/day_entry.dart`
- Modify: `lib/domain/labels.dart`
- Create: `test/domain/cycle_phase_test.dart`
- Modify: `test/domain/day_entry_test.dart`

**Interfaces:**
- Produces: `enum CyclePhase { menstrual, follicular, ovulation, luteal }`
- Produces: `CyclePrediction.currentPhase(DateTime day)`, `CyclePrediction.cycleDayNumber(DateTime day)`
- Produces: `CyclePhaseInfo` containing title, subtitle, hormoneDescription, energyLevel, workoutRecommendation, nutritionRecommendation.
- Extends: `DayEntry` with `cervicalMucus` (`CervicalMucus?`) and `sexualActivity` (`SexualActivity?`).

- [ ] **Step 1: Write failing test for CyclePhase and extended DayEntry**

```dart
// test/domain/cycle_phase_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/domain/cycle_phase.dart';
import 'package:siklus/domain/cycle_phase_info.dart';
import 'package:siklus/domain/cycle_predictor.dart';
import 'package:siklus/domain/day_entry.dart';

void main() {
  test('CyclePredictor identifies current cycle day and phase correctly', () {
    final today = DateTime(2026, 10, 15);
    final entries = [
      const DayEntry(date: '2026-10-01', flow: FlowLevel.medium),
      const DayEntry(date: '2026-10-02', flow: FlowLevel.medium),
      const DayEntry(date: '2026-10-03', flow: FlowLevel.light),
    ];
    final prediction = CyclePredictor.predict(entries: entries, today: today);
    expect(prediction.cycleDayNumber(today), 15);
    expect(prediction.currentPhase(today), CyclePhase.ovulation);

    final info = CyclePhaseInfo.forPhase(CyclePhase.ovulation);
    expect(info.title, 'Fase Ovulasi');
    expect(info.energyLevel, isNotEmpty);
    expect(info.nutritionRecommendation, isNotEmpty);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\src\flutter\bin\flutter.bat" test test/domain/cycle_phase_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement CyclePhase, CyclePhaseInfo, and extend DayEntry**

Create `lib/domain/cycle_phase.dart`:
```dart
enum CyclePhase { menstrual, follicular, ovulation, luteal }
```

Create `lib/domain/cycle_phase_info.dart`:
```dart
import 'cycle_phase.dart';

class CyclePhaseInfo {
  const CyclePhaseInfo({
    required this.phase,
    required this.title,
    required this.subtitle,
    required this.hormoneDescription,
    required this.energyLevel,
    required this.workoutRecommendation,
    required this.nutritionRecommendation,
  });

  final CyclePhase phase;
  final String title;
  final String subtitle;
  final String hormoneDescription;
  final String energyLevel;
  final String workoutRecommendation;
  final String nutritionRecommendation;

  static CyclePhaseInfo forPhase(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstrual:
        return const CyclePhaseInfo(
          phase: CyclePhase.menstrual,
          title: 'Fase Menstruasi',
          subtitle: 'Waktu Istirahat & Pemulihan',
          hormoneDescription: 'Kadar estrogen dan progesteron berada di titik terendah.',
          energyLevel: 'Rendah - Sedang',
          workoutRecommendation: 'Yoga lembut, jalan santai, peregangan ringan.',
          nutritionRecommendation: 'Makanan kaya zat besi, sup hangat, teh herbal jahe.',
        );
      case CyclePhase.follicular:
        return const CyclePhaseInfo(
          phase: CyclePhase.follicular,
          title: 'Fase Folikular',
          subtitle: 'Energi Baru & Optimisme',
          hormoneDescription: 'Estrogen mulai meningkat, folikel indung telur berkembang.',
          energyLevel: 'Tinggi & Segar',
          workoutRecommendation: 'Latihan beban ringan, kardio dinamis, hiking.',
          nutritionRecommendation: 'Sayuran berdaun hijau, buah berry, protein tanpa lemak.',
        );
      case CyclePhase.ovulation:
        return const CyclePhaseInfo(
          phase: CyclePhase.ovulation,
          title: 'Fase Ovulasi',
          subtitle: 'Masa Subur & Percaya Diri Puncak',
          hormoneDescription: 'Lonjakan hormon LH dan estrogen mencapai puncaknya.',
          energyLevel: 'Sangat Tinggi / Maksimal',
          workoutRecommendation: 'HIIT, lari intensif, kelas tari atau kekuatan penuh.',
          nutritionRecommendation: 'Makanan kaya antioksidan, serat, asam lemak omega-3.',
        );
      case CyclePhase.luteal:
        return const CyclePhaseInfo(
          phase: CyclePhase.luteal,
          title: 'Fase Luteal',
          subtitle: 'Persiapan Tubuh & Self-Care',
          hormoneDescription: 'Progesteron mendominasi dan kemudian perlahan menurun.',
          energyLevel: 'Menurun bertahap',
          workoutRecommendation: 'Pilates, renang santai, latihan kekuatan ritme lambat.',
          nutritionRecommendation: 'Karbohidrat kompleks, magnesium (dark chocolate), alpukat.',
        );
    }
  }
}
```

Update `lib/domain/cycle_predictor.dart` adding `cycleDayNumber` and `currentPhase`:
```dart
int? cycleDayNumber(DateTime today) {
  if (periods.isEmpty) return null;
  final diff = daysBetween(periods.last.start, today);
  return diff >= 0 ? diff + 1 : null;
}

CyclePhase currentPhase(DateTime today) {
  if (periods.isNotEmpty && _within(today, periods.last.start, periods.last.end)) {
    return CyclePhase.menstrual;
  }
  if (isFertile(today) || isOvulation(today)) {
    return CyclePhase.ovulation;
  }
  if (periods.isNotEmpty && fertileStart != null) {
    if (daysBetween(periods.last.end, today) > 0 && daysBetween(today, fertileStart!) < 0) {
      return CyclePhase.follicular;
    }
  }
  return CyclePhase.luteal;
}
```

Add `CervicalMucus` and `SexualActivity` enums to `lib/domain/day_entry.dart` and labels to `lib/domain/labels.dart`:
```dart
enum CervicalMucus { dry, sticky, creamy, eggWhite }
enum SexualActivity { none, protected, unprotected, highDrive }
```
Extend `DayEntry` with `cervicalMucus` and `sexualActivity`, maintaining `toMap` / `fromMap` backward compatibility.

- [ ] **Step 4: Run all domain tests to verify they pass**

Run: `& "C:\src\flutter\bin\flutter.bat" test test/domain/`
Expected: PASS (all tests pass)

- [ ] **Step 5: Commit**

```bash
git add lib/domain/ test/domain/
git commit -m "feat(domain): add cycle phase detection, wellness tips, and extended log categories"
```

---

### Task 3: Redesign Login & Onboarding with Modern Soft Wellness Visuals

**Files:**
- Create: `lib/features/common/widgets/cycle_logo.dart`
- Modify: `lib/features/auth/login_screen.dart`
- Modify: `lib/features/onboarding/onboarding_screen.dart`
- Modify: `test/features/auth_flow_test.dart`
- Modify: `test/features/onboarding_screen_test.dart`

**Interfaces:**
- Produces: `CycleLogo` widget featuring a modern stylized circular cycle emblem.
- Updates: `LoginScreen` and `OnboardingScreen` with branded typography, soft elevated cards, role selection cards, and Indonesian copy.

- [ ] **Step 1: Write widget test for CycleLogo and updated LoginScreen branding**

Update `test/features/auth_flow_test.dart` to expect `find.text('CycleApp')` instead of `'Siklus'`.

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\src\flutter\bin\flutter.bat" test test/features/auth_flow_test.dart`
Expected: FAIL (found 'Siklus' instead of 'CycleApp')

- [ ] **Step 3: Implement CycleLogo, redesign LoginScreen and OnboardingScreen**

Create `lib/features/common/widgets/cycle_logo.dart` (vector icon with layered rose gradient and flower/cycle shape).
Redesign `LoginScreen`:
- Centered elegant header with `CycleLogo` and title "CycleApp"
- Subtitle: "Lacak siklus bulanan & terhubung harmonis dengan pasangan"
- Rounded text fields with prefix icons (`Icons.email_outlined`, `Icons.lock_outline`)
- Gradient elevated `FilledButton` ("Masuk") and `OutlinedButton` ("Daftar Akun Baru")
Redesign `OnboardingScreen`:
- Two modern interactive selectable role cards:
  1. "Mencatat Siklus Sendiri" (dengan ikon kalender bunga)
  2. "Bergabung dengan Pasangan" (dengan ikon hati & kode undangan)

- [ ] **Step 4: Run tests to verify they pass**

Run: `& "C:\src\flutter\bin\flutter.bat" test test/features/auth_flow_test.dart test/features/onboarding_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/common/ lib/features/auth/ lib/features/onboarding/ test/features/
git commit -m "feat(auth): redesign Login and Onboarding with Modern Soft Wellness branding"
```

---

### Task 4: Build Hero Cycle Dial & Today Hub on Home Screen

**Files:**
- Create: `lib/features/home/widgets/cycle_dial.dart`
- Create: `lib/features/home/widgets/phase_card.dart`
- Create: `lib/features/home/widgets/today_summary_card.dart`
- Create: `lib/features/home/home_screen.dart`
- Modify: `lib/features/home/home_shell.dart`
- Create: `test/features/home_screen_test.dart`

**Interfaces:**
- Consumes: `predictionProvider`, `dayEntriesProvider`, `todayProvider`
- Produces: `HomeScreen` widget displaying Hero Cycle Dial, Cycle Phase status badge, daily wellness tips, and quick log action.

- [ ] **Step 1: Write failing widget test for HomeScreen**

```dart
// test/features/home_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/domain/day_entry.dart';
import 'package:siklus/features/home/home_screen.dart';
import 'package:siklus/state/providers.dart';

void main() {
  testWidgets('HomeScreen renders cycle dial, phase card, and quick log button', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayProvider.overrideWithValue(DateTime(2026, 10, 15)),
          dayEntriesProvider.overrideWith((ref) => Stream.value([
                const DayEntry(date: '2026-10-01', flow: FlowLevel.medium),
              ])),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Siklus'), findsWidgets);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Catat Hari Ini'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\src\flutter\bin\flutter.bat" test test/features/home_screen_test.dart`
Expected: FAIL (HomeScreen not found)

- [ ] **Step 3: Implement CycleDial, PhaseCard, TodaySummaryCard, and HomeScreen**

Create `lib/features/home/widgets/cycle_dial.dart`:
CustomPainter drawing an interactive circular arc with gradient phase highlights:
- Background subtle track
- Active arc showing progress of the current cycle length (e.g. day 15 of 28)
- Center content: "Hari ke-15", Phase Badge ("Fase Ovulasi"), Subtext ("Haid berikutnya ~13 hari").
Create `lib/features/home/widgets/phase_card.dart`:
Displaying current phase hormone description, energy meter, and lifestyle advice.
Create `lib/features/home/home_screen.dart`:
Greeting header ("Halo, selamat pagi" + Profile Name), CycleDial, Quick Action bar, PhaseCard, and TodaySummaryCard.

- [ ] **Step 4: Run test to verify it passes**

Run: `& "C:\src\flutter\bin\flutter.bat" test test/features/home_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/ test/features/home_screen_test.dart
git commit -m "feat(home): build Hero Cycle Dial and Today Hub home screen"
```

---

### Task 5: Redesign Day Log Screen with Rich Visual Categories

**Files:**
- Create: `lib/features/log/widgets/category_section.dart`
- Create: `lib/features/log/widgets/selectable_tile.dart`
- Modify: `lib/features/log/day_log_screen.dart`
- Modify: `test/features/day_log_screen_test.dart`

**Interfaces:**
- Consumes: `DayEntry`, `dayRepositoryProvider`, `activeProfileIdProvider`
- Produces: Redesigned `DayLogScreen` featuring categorized cards with icons, selection state, and smooth save experience.

- [ ] **Step 1: Update day_log_screen_test.dart with new tracking categories**

Test that selecting CervicalMucus and SexualActivity alongside Flow and Symptoms saves all fields in the entry.

- [ ] **Step 2: Run test to verify failure/coverage**

Run: `& "C:\src\flutter\bin\flutter.bat" test test/features/day_log_screen_test.dart`

- [ ] **Step 3: Overhaul DayLogScreen**

Replace plain chips with categorized modern sections:
1. Aliran Darah (Spotting, Ringan, Sedang, Deras) with drop icons and soft pink/rose tint
2. Tingkat Energi (Rendah, Normal, Tinggi) with lightning icons
3. Suasana Hati (Bahagia, Tenang, Sensitif, Sedih, Cemas, Mudah Marah, Lelah) with expressive mood badges
4. Gejala Fisik (Kram, Sakit Kepala, Sakit Punggung, Kembung, Kelelahan, Mual, Jerawat)
5. Cairan Serviks (Kering, Lengket, Krimi, Bening/Licin)
6. Aktivitas Seksual (Terproteksi, Tanpa Proteksi, Libido Tinggi)
7. Catatan Pribadi (Clean TextField with soft border)
Sticky bottom bar with elevated "Simpan Catatan" button.

- [ ] **Step 4: Run tests to verify they pass**

Run: `& "C:\src\flutter\bin\flutter.bat" test test/features/day_log_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/log/ test/features/day_log_screen_test.dart
git commit -m "feat(log): overhaul DayLogScreen with modern visual category cards"
```

---

### Task 6: Build Insights & Analytics Screen

**Files:**
- Create: `lib/features/insights/insights_screen.dart`
- Create: `lib/features/insights/widgets/cycle_stats_card.dart`
- Create: `lib/features/insights/widgets/phase_guide_sheet.dart`
- Create: `lib/features/insights/widgets/symptoms_frequency_card.dart`
- Create: `test/features/insights_screen_test.dart`

**Interfaces:**
- Consumes: `predictionProvider`, `dayEntriesProvider`
- Produces: `InsightsScreen` tab showing cycle history, average length stats, 4-phase educational guide with collapsible sheets, and symptom frequency rankings.

- [ ] **Step 1: Write failing test for InsightsScreen**

```dart
// test/features/insights_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/domain/day_entry.dart';
import 'package:siklus/features/insights/insights_screen.dart';
import 'package:siklus/state/providers.dart';

void main() {
  testWidgets('InsightsScreen renders stats and 4 phase educational cards', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayProvider.overrideWithValue(DateTime(2026, 10, 15)),
          dayEntriesProvider.overrideWith((ref) => Stream.value([
                const DayEntry(date: '2026-10-01', flow: FlowLevel.medium, symptoms: {Symptom.cramps}),
              ])),
        ],
        child: const MaterialApp(home: InsightsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Analisis & Insight'), findsOneWidget);
    expect(find.textContaining('Rata-rata Siklus'), findsOneWidget);
    expect(find.text('Panduan 4 Fase Siklus'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\src\flutter\bin\flutter.bat" test test/features/insights_screen_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement InsightsScreen and widget components**

Build `CycleStatsCard` displaying average cycle length and period length with trend indicators.
Build `PhaseGuideSheet` displaying expandable rich guides for Menstruasi, Folikular, Ovulasi, and Luteal phases.
Build `SymptomsFrequencyCard` aggregating symptom counts from past entries and displaying visual progress bars.

- [ ] **Step 4: Run test to verify it passes**

Run: `& "C:\src\flutter\bin\flutter.bat" test test/features/insights_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/insights/ test/features/insights_screen_test.dart
git commit -m "feat(insights): implement cycle analytics and 4-phase educational hub"
```

---

### Task 7: Polish Calendar & Settings Screens and Integrate 4-Tab Navigation

**Files:**
- Modify: `lib/features/calendar/calendar_screen.dart`
- Modify: `lib/features/calendar/day_marker.dart`
- Modify: `lib/features/settings/settings_screen.dart`
- Modify: `lib/features/home/home_shell.dart`
- Modify: `test/features/calendar_logic_test.dart`
- Modify: `test/features/settings_screen_test.dart`

**Interfaces:**
- Updates: `HomeShell` with 4 tabs: (1) Beranda, (2) Kalender, (3) Insight, (4) Pengaturan.
- Adds: Theme toggle (Light / Dark / System) in Settings.
- Polishes: Calendar day markers and date selection card.

- [ ] **Step 1: Write test for 4-tab HomeShell and theme switcher**

Verify `HomeShell` contains all 4 destinations and switches tabs without losing state.

- [ ] **Step 2: Update CalendarScreen, SettingsScreen, and HomeShell**

Polish `CalendarScreen`:
- Month header with elegant navigation buttons
- Day markers with soft rounded circles, rose dots for period, lavender tint for fertile window
- Legend pills: Haid (rose), Masa Subur (lavender), Prediksi (outline)
- Selected day detail sheet below calendar with quick "Buka / Edit Catatan" button
Update `SettingsScreen`:
- Profile card with avatar/initials
- Partner sync card with one-click copy invite code
- Theme selection card (Sistem, Terang, Gelap)
- Logout button
Connect `HomeScreen`, `CalendarScreen`, `InsightsScreen`, and `SettingsScreen` in `HomeShell`.

- [ ] **Step 3: Run all project tests**

Run: `& "C:\src\flutter\bin\flutter.bat" test`
Expected: ALL PASS

- [ ] **Step 4: Run flutter analyze**

Run: `& "C:\src\flutter\bin\flutter.bat" analyze`
Expected: 0 issues found

- [ ] **Step 5: Verify web build and Hot Reload**

Run: `& "C:\src\flutter\bin\flutter.bat" build web`
Expected: Build successful

- [ ] **Step 6: Commit**

```bash
git add lib/ test/
git commit -m "feat(nav): complete 4-tab navigation shell and UI polish"
```
