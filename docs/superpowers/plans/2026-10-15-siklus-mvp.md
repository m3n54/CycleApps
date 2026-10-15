# Siklus MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Membangun aplikasi Android Flutter untuk mencatat siklus menstruasi yang dipakai bersama oleh dua orang, dengan login email/password dan sinkronisasi offline-first lewat Firebase (gratis).

**Architecture:** Lapisan domain murni (model + prediksi siklus) tanpa dependensi Firebase, lapisan repository tipis di atas Firebase Auth & Cloud Firestore, state dengan Riverpod, dan layar Flutter. Offline & sinkronisasi memakai cache bawaan Firestore; konflik = last-write-wins per dokumen tanggal. Akses data bersama dijaga oleh Firestore Security Rules yang diuji di emulator.

**Tech Stack:** Flutter (Dart ≥ 3.5), firebase_core, firebase_auth, cloud_firestore, flutter_riverpod 2.x, table_calendar, intl; test: flutter_test, fake_cloud_firestore, firebase_auth_mocks; rules test: Node.js + @firebase/rules-unit-testing + Firebase CLI emulator.

**Spec:** `docs/superpowers/specs/2026-10-15-siklus-design.md`

## Global Constraints

- Root proyek: `C:\Menza\siklus` (semua path di plan ini relatif terhadap folder itu).
- Nama paket Dart: `siklus`; application id Android: `com.menza.siklus`.
- Platform: Android saja; `minSdk` minimal 23.
- `flutter_riverpod` dikunci ke `^2.6.1` (kode memakai API 2.x seperti `AsyncValue.valueOrNull`).
- Biaya: hanya Firebase paket **Spark**; jangan memakai Cloud Functions, Storage berbayar, atau fitur yang meminta paket Blaze.
- Region Firestore: `asia-southeast2` (Jakarta).
- Tanpa SDK analytics/iklan/crash-reporting pihak ketiga.
- Teks UI dalam Bahasa Indonesia; identifier kode dalam Bahasa Inggris.
- Format id dokumen hari: `yyyy-MM-dd`.
- `note` maks 2000 karakter; `memberUids` maks 5; kode undangan 6 karakter dari alfabet `ABCDEFGHJKLMNPQRSTUVWXYZ23456789`, berlaku 24 jam.
- Aturan prediksi persis seperti spec §7 (siklus valid 15–60 hari, maks 6 siklus terakhir, ovulasi = haid berikutnya − 14, masa subur = ovulasi − 5 s/d ovulasi + 1).
- Penulisan ke Firestore dari UI **tidak di-await** (pakai `unawaited`), kecuali operasi yang memang butuh online: buat profil, gabung, buat undangan.

---

## File Structure

```
siklus/
├── firebase.json                      # konfigurasi Firebase CLI (rules + emulator)
├── .firebaserc                        # project default (dibuat `firebase use --add`)
├── firestore.rules                    # Security Rules
├── firestore.indexes.json             # kosong
├── firestore-tests/
│   ├── package.json
│   └── rules.test.mjs                 # test rules di emulator
├── lib/
│   ├── main.dart                      # init Firebase, intl, ProviderScope
│   ├── app.dart                       # SiklusApp (MaterialApp + AuthGate)
│   ├── firebase_options.dart          # GENERATED oleh flutterfire configure
│   ├── domain/
│   │   ├── date_key.dart              # helper tanggal & id dokumen
│   │   ├── day_entry.dart             # enum + model catatan harian
│   │   ├── labels.dart                # label Bahasa Indonesia untuk enum
│   │   ├── cycle_profile.dart         # model profil
│   │   └── cycle_predictor.dart       # deteksi periode + prediksi (murni)
│   ├── data/
│   │   ├── invite_code.dart           # generator & normalisasi kode
│   │   ├── auth_repository.dart       # wrapper FirebaseAuth + pesan error
│   │   ├── profile_repository.dart    # profil, undangan, bergabung
│   │   └── day_repository.dart        # baca/tulis catatan harian
│   ├── state/
│   │   └── providers.dart             # semua provider Riverpod
│   └── features/
│       ├── auth/auth_gate.dart        # routing berdasarkan status login/profil
│       ├── auth/login_screen.dart
│       ├── onboarding/onboarding_screen.dart
│       ├── home/home_shell.dart       # NavigationBar Kalender | Pengaturan
│       ├── calendar/day_marker.dart   # markerFor() + DayCell
│       ├── calendar/prediction_summary.dart
│       ├── calendar/calendar_screen.dart
│       ├── log/day_log_screen.dart
│       └── settings/settings_screen.dart
└── test/
    ├── domain/date_key_test.dart
    ├── domain/day_entry_test.dart
    ├── domain/cycle_predictor_test.dart
    ├── data/invite_code_test.dart
    ├── data/auth_repository_test.dart
    ├── data/profile_repository_test.dart
    ├── data/day_repository_test.dart
    ├── features/calendar_logic_test.dart
    ├── features/auth_flow_test.dart
    ├── features/onboarding_screen_test.dart
    ├── features/day_log_screen_test.dart
    └── features/settings_screen_test.dart
```

---

### Task 0: Prasyarat, scaffold proyek, dan koneksi Firebase

**Files:**
- Create: seluruh scaffold `flutter create`
- Create: `lib/firebase_options.dart`, `android/app/google-services.json` (generated)
- Modify: `android/app/build.gradle.kts` (minSdk)
- Replace: `lib/main.dart`
- Create: `lib/app.dart` (placeholder, diganti di Task 8)
- Delete: `test/widget_test.dart`

**Interfaces:**
- Consumes: —
- Produces: `class SiklusApp extends StatelessWidget` di `lib/app.dart`; `DefaultFirebaseOptions.currentPlatform` di `lib/firebase_options.dart`.

- [x] **Step 1: Pasang tools (sekali saja)**

Pastikan tersedia (semua gratis):
- Flutter SDK stable + Android Studio (Android SDK, emulator) → cek `flutter doctor` tanpa error untuk Android.
- Node.js (sudah ada: v26) → `npm install -g firebase-tools`
- JDK 21 (untuk Firestore Emulator) → cek `java -version`
- FlutterFire CLI → `dart pub global activate flutterfire_cli`

Run: `flutter doctor; firebase --version; java -version; flutterfire --version`
Expected: semua perintah mencetak versi, `flutter doctor` menunjukkan ✓ untuk Android toolchain.

- [x] **Step 2: Buat proyek Firebase di console (manual)**

1. https://console.firebase.google.com → *Add project* → nama `siklus` → **matikan Google Analytics**.
2. *Build → Authentication → Get started → Sign-in method → Email/Password → Enable*.
3. *Build → Firestore Database → Create database → Production mode → lokasi `asia-southeast2`*.
4. Pastikan paket tetap **Spark** (gratis).

- [x] **Step 3: Scaffold Flutter**

Run (PowerShell, di `C:\Menza\siklus`):
```powershell
flutter create --org com.menza --project-name siklus --platforms android .
flutter pub add firebase_core firebase_auth cloud_firestore "flutter_riverpod:^2.6.1" table_calendar intl
flutter pub add --dev fake_cloud_firestore firebase_auth_mocks
Remove-Item test\widget_test.dart
```
Expected: `pubspec.yaml` berisi semua dependensi; tidak ada error resolusi versi.

- [x] **Step 4: Hubungkan ke Firebase**

Run:
```powershell
firebase login
flutterfire configure --platforms=android --android-package-name=com.menza.siklus
firebase use --add
```
Pilih proyek `siklus`; untuk `firebase use --add` beri alias `default`.
Expected: file `lib/firebase_options.dart`, `android/app/google-services.json`, dan `.firebaserc` terbentuk.

- [x] **Step 5: Set minSdk**

Di `android/app/build.gradle.kts`, dalam blok `defaultConfig`, ganti baris `minSdk = flutter.minSdkVersion` menjadi:
```kotlin
minSdk = maxOf(flutter.minSdkVersion, 23)
```

- [x] **Step 6: Tulis `lib/app.dart` placeholder**

```dart
import 'package:flutter/material.dart';

class SiklusApp extends StatelessWidget {
  const SiklusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('Siklus terhubung ke Firebase'))),
    );
  }
}
```

- [x] **Step 7: Tulis `lib/main.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  await initializeDateFormatting('id_ID');
  runApp(const ProviderScope(child: SiklusApp()));
}
```

- [x] **Step 8: Verifikasi build & jalan**

Run: `flutter analyze` lalu `flutter run` (emulator atau HP via USB).
Expected: analyze `No issues found!`; aplikasi menampilkan "Siklus terhubung ke Firebase" tanpa crash.

- [x] **Step 9: Commit**

```powershell
git init
git add -A
git commit -m "chore: scaffold flutter app and connect firebase"
```

---

### Task 1: Helper tanggal dan model `DayEntry`

**Files:**
- Create: `lib/domain/date_key.dart`
- Create: `lib/domain/day_entry.dart`
- Create: `lib/domain/labels.dart`
- Test: `test/domain/date_key_test.dart`, `test/domain/day_entry_test.dart`

**Interfaces:**
- Consumes: —
- Produces:
  - `String dateKey(DateTime d)`, `DateTime parseDateKey(String key)`, `DateTime dateOnly(DateTime d)`, `DateTime addDays(DateTime d, int n)`, `int daysBetween(DateTime from, DateTime to)`
  - `enum FlowLevel { spotting, light, medium, heavy }`, `enum Energy { low, medium, high }`, `enum Symptom { cramps, headache, breastTenderness, acne, backache, bloating, nausea }`, `enum Mood { happy, calm, sad, anxious, irritable, sensitive }`
  - `class DayEntry { String date; FlowLevel? flow; Set<Symptom> symptoms; Set<Mood> moods; Energy? energy; String note; String? updatedBy; bool get isPeriodDay; bool get isEmpty; Map<String, dynamic> toMap(); factory DayEntry.fromMap(Map<String, dynamic>) }`
  - `flowLabels`, `symptomLabels`, `moodLabels`, `energyLabels` (`Map<Enum, String>`)

- [x] **Step 1: Write the failing tests**

`test/domain/date_key_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/domain/date_key.dart';

void main() {
  test('dateKey pads month and day', () {
    expect(dateKey(DateTime(2026, 3, 7, 22, 15)), '2026-03-07');
  });

  test('parseDateKey is the inverse of dateKey', () {
    expect(parseDateKey('2026-12-31'), DateTime(2026, 12, 31));
  });

  test('addDays crosses month and year boundaries', () {
    expect(addDays(DateTime(2026, 12, 30), 3), DateTime(2027, 1, 2));
    expect(addDays(DateTime(2026, 3, 1), -1), DateTime(2026, 2, 28));
  });

  test('daysBetween ignores time of day', () {
    expect(daysBetween(DateTime(2026, 1, 1, 23), DateTime(2026, 1, 29, 1)), 28);
    expect(daysBetween(DateTime(2026, 1, 29), DateTime(2026, 1, 1)), -28);
  });
}
```

`test/domain/day_entry_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/domain/day_entry.dart';

void main() {
  test('toMap/fromMap round trip', () {
    const entry = DayEntry(
      date: '2026-10-15',
      flow: FlowLevel.medium,
      symptoms: {Symptom.cramps, Symptom.acne},
      moods: {Mood.calm},
      energy: Energy.low,
      note: 'capek',
    );
    final map = entry.toMap();
    expect(map['flow'], 'medium');
    expect(map['symptoms'], ['acne', 'cramps']);
    final back = DayEntry.fromMap({...map, 'updatedBy': 'u1'});
    expect(back.flow, FlowLevel.medium);
    expect(back.symptoms, {Symptom.cramps, Symptom.acne});
    expect(back.moods, {Mood.calm});
    expect(back.energy, Energy.low);
    expect(back.note, 'capek');
    expect(back.updatedBy, 'u1');
  });

  test('fromMap ignores unknown enum names and missing fields', () {
    final e = DayEntry.fromMap({
      'date': '2026-10-15',
      'flow': 'gushing',
      'symptoms': ['cramps', 'alienProbe'],
    });
    expect(e.flow, isNull);
    expect(e.symptoms, {Symptom.cramps});
    expect(e.moods, isEmpty);
    expect(e.note, '');
  });

  test('isPeriodDay excludes spotting', () {
    expect(const DayEntry(date: 'x', flow: FlowLevel.light).isPeriodDay, isTrue);
    expect(const DayEntry(date: 'x', flow: FlowLevel.spotting).isPeriodDay, isFalse);
    expect(const DayEntry(date: 'x').isPeriodDay, isFalse);
  });

  test('isEmpty is true only when nothing is recorded', () {
    expect(const DayEntry(date: 'x', note: '   ').isEmpty, isTrue);
    expect(const DayEntry(date: 'x', energy: Energy.high).isEmpty, isFalse);
  });
}
```

- [x] **Step 2: Run tests to verify they fail**

Run: `flutter test test/domain`
Expected: FAIL — `Target of URI doesn't exist: 'package:siklus/domain/date_key.dart'`.

- [x] **Step 3: Implement `lib/domain/date_key.dart`**

```dart
/// Id dokumen hari: yyyy-MM-dd (waktu lokal).
String dateKey(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

DateTime parseDateKey(String key) {
  final parts = key.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

/// Selisih hari kalender; dihitung di UTC agar kebal DST.
int daysBetween(DateTime from, DateTime to) {
  final a = DateTime.utc(from.year, from.month, from.day);
  final b = DateTime.utc(to.year, to.month, to.day);
  return b.difference(a).inDays;
}
```

- [x] **Step 4: Implement `lib/domain/day_entry.dart`**

```dart
enum FlowLevel { spotting, light, medium, heavy }

enum Energy { low, medium, high }

enum Symptom { cramps, headache, breastTenderness, acne, backache, bloating, nausea }

enum Mood { happy, calm, sad, anxious, irritable, sensitive }

class DayEntry {
  const DayEntry({
    required this.date,
    this.flow,
    this.symptoms = const {},
    this.moods = const {},
    this.energy,
    this.note = '',
    this.updatedBy,
  });

  final String date;
  final FlowLevel? flow;
  final Set<Symptom> symptoms;
  final Set<Mood> moods;
  final Energy? energy;
  final String note;
  final String? updatedBy;

  bool get isPeriodDay =>
      flow == FlowLevel.light || flow == FlowLevel.medium || flow == FlowLevel.heavy;

  bool get isEmpty =>
      flow == null && symptoms.isEmpty && moods.isEmpty && energy == null && note.trim().isEmpty;

  /// Tidak memuat updatedBy/updatedAt; keduanya diisi repository.
  Map<String, dynamic> toMap() => {
        'date': date,
        'flow': flow?.name,
        'symptoms': (symptoms.map((s) => s.name).toList()..sort()),
        'moods': (moods.map((m) => m.name).toList()..sort()),
        'energy': energy?.name,
        'note': note,
      };

  factory DayEntry.fromMap(Map<String, dynamic> map) => DayEntry(
        date: map['date'] as String,
        flow: _enumOrNull(FlowLevel.values, map['flow']),
        symptoms: _enumSet(Symptom.values, map['symptoms']),
        moods: _enumSet(Mood.values, map['moods']),
        energy: _enumOrNull(Energy.values, map['energy']),
        note: (map['note'] as String?) ?? '',
        updatedBy: map['updatedBy'] as String?,
      );
}

T? _enumOrNull<T extends Enum>(List<T> values, Object? name) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return null;
}

Set<T> _enumSet<T extends Enum>(List<T> values, Object? raw) {
  if (raw is! List) return <T>{};
  return raw.map((n) => _enumOrNull(values, n)).whereType<T>().toSet();
}
```

- [x] **Step 5: Implement `lib/domain/labels.dart`**

```dart
import 'day_entry.dart';

const flowLabels = <FlowLevel, String>{
  FlowLevel.spotting: 'Bercak',
  FlowLevel.light: 'Ringan',
  FlowLevel.medium: 'Sedang',
  FlowLevel.heavy: 'Berat',
};

const symptomLabels = <Symptom, String>{
  Symptom.cramps: 'Kram',
  Symptom.headache: 'Sakit kepala',
  Symptom.breastTenderness: 'Nyeri payudara',
  Symptom.acne: 'Jerawat',
  Symptom.backache: 'Sakit punggung',
  Symptom.bloating: 'Kembung',
  Symptom.nausea: 'Mual',
};

const moodLabels = <Mood, String>{
  Mood.happy: 'Senang',
  Mood.calm: 'Tenang',
  Mood.sad: 'Sedih',
  Mood.anxious: 'Cemas',
  Mood.irritable: 'Mudah marah',
  Mood.sensitive: 'Sensitif',
};

// Sengaja berbeda dari label flow agar tidak ada teks ganda di layar.
const energyLabels = <Energy, String>{
  Energy.low: 'Lemas',
  Energy.medium: 'Normal',
  Energy.high: 'Bertenaga',
};
```

- [x] **Step 6: Run tests to verify they pass**

Run: `flutter test test/domain`
Expected: PASS (8 tests).

- [x] **Step 7: Commit**

```powershell
git add lib/domain test/domain
git commit -m "feat: add date helpers and DayEntry model"
```

---

### Task 2: `CyclePredictor` dan `CycleProfile`

**Files:**
- Create: `lib/domain/cycle_predictor.dart`
- Create: `lib/domain/cycle_profile.dart`
- Test: `test/domain/cycle_predictor_test.dart`

**Interfaces:**
- Consumes: `DayEntry`, `dateKey`, `parseDateKey`, `addDays`, `daysBetween` (Task 1)
- Produces:
  - `class Period { final DateTime start; final DateTime end; int get length; }`
  - `class CyclePrediction { List<Period> periods; int avgCycleLength; int avgPeriodLength; DateTime? nextPeriodStart; DateTime? ovulationDay; DateTime? fertileStart; DateTime? fertileEnd; bool isPredictedPeriod(DateTime d); bool isFertile(DateTime d); bool isOvulation(DateTime d); int daysUntilNext(DateTime today); }`
  - `class CyclePredictor { static List<Period> detectPeriods(Iterable<DayEntry>); static CyclePrediction predict({required Iterable<DayEntry> entries, required DateTime today, int defaultCycleLength = 28, int defaultPeriodLength = 5}); }`
  - `class CycleProfile { String id; String ownerUid; List<String> memberUids; String name; int defaultCycleLength; int defaultPeriodLength; factory CycleProfile.fromMap(String id, Map<String, dynamic>) }`

- [x] **Step 1: Write the failing tests**

`test/domain/cycle_predictor_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/domain/cycle_predictor.dart';
import 'package:siklus/domain/date_key.dart';
import 'package:siklus/domain/day_entry.dart';

/// Membuat [days] hari haid berturut-turut mulai [start].
List<DayEntry> period(DateTime start, {int days = 3, FlowLevel flow = FlowLevel.medium}) => [
      for (var i = 0; i < days; i++) DayEntry(date: dateKey(addDays(start, i)), flow: flow),
    ];

void main() {
  group('detectPeriods', () {
    test('groups consecutive days and allows a single empty day', () {
      final entries = [
        DayEntry(date: '2026-01-01', flow: FlowLevel.heavy),
        DayEntry(date: '2026-01-02', flow: FlowLevel.medium),
        DayEntry(date: '2026-01-04', flow: FlowLevel.light), // jeda 1 hari
        DayEntry(date: '2026-01-29', flow: FlowLevel.medium),
      ];
      final periods = CyclePredictor.detectPeriods(entries);
      expect(periods.length, 2);
      expect(periods[0].start, DateTime(2026, 1, 1));
      expect(periods[0].end, DateTime(2026, 1, 4));
      expect(periods[0].length, 4);
      expect(periods[1].start, DateTime(2026, 1, 29));
    });

    test('ignores spotting and non-flow entries', () {
      final entries = [
        const DayEntry(date: '2026-01-01', flow: FlowLevel.spotting),
        const DayEntry(date: '2026-01-02', moods: {Mood.sad}),
      ];
      expect(CyclePredictor.detectPeriods(entries), isEmpty);
    });

    test('order of input does not matter', () {
      final entries = period(DateTime(2026, 1, 1)).reversed;
      final periods = CyclePredictor.detectPeriods(entries);
      expect(periods.single.start, DateTime(2026, 1, 1));
      expect(periods.single.end, DateTime(2026, 1, 3));
    });
  });

  group('predict', () {
    test('no data → defaults and no dates', () {
      final p = CyclePredictor.predict(entries: const [], today: DateTime(2026, 1, 10));
      expect(p.avgCycleLength, 28);
      expect(p.avgPeriodLength, 5);
      expect(p.nextPeriodStart, isNull);
      expect(p.ovulationDay, isNull);
      expect(p.daysUntilNext(DateTime(2026, 1, 10)), isNull);
    });

    test('single period uses default cycle length', () {
      final p = CyclePredictor.predict(
        entries: period(DateTime(2026, 1, 1)),
        today: DateTime(2026, 1, 10),
      );
      expect(p.avgCycleLength, 28);
      expect(p.avgPeriodLength, 3);
      expect(p.nextPeriodStart, DateTime(2026, 1, 29));
      expect(p.ovulationDay, DateTime(2026, 1, 15));
      expect(p.fertileStart, DateTime(2026, 1, 10));
      expect(p.fertileEnd, DateTime(2026, 1, 16));
    });

    test('averages observed cycle lengths', () {
      final entries = [
        ...period(DateTime(2026, 1, 1)),
        ...period(DateTime(2026, 1, 29)), // 28 hari
        ...period(DateTime(2026, 2, 28)), // 30 hari
      ];
      final p = CyclePredictor.predict(entries: entries, today: DateTime(2026, 3, 5));
      expect(p.avgCycleLength, 29);
      expect(p.nextPeriodStart, DateTime(2026, 3, 29));
    });

    test('ignores cycle lengths outside 15..60 days', () {
      final entries = [
        ...period(DateTime(2026, 1, 1)),
        ...period(DateTime(2026, 4, 1)), // 90 hari → diabaikan
        ...period(DateTime(2026, 4, 29)), // 28 hari
      ];
      final p = CyclePredictor.predict(entries: entries, today: DateTime(2026, 5, 1));
      expect(p.avgCycleLength, 28);
      expect(p.nextPeriodStart, DateTime(2026, 5, 27));
    });

    test('uses only the last 6 cycles', () {
      // 3 siklus lama @40 hari, lalu 6 siklus @28 hari.
      final starts = <DateTime>[DateTime(2025, 1, 1)];
      for (var i = 0; i < 3; i++) starts.add(addDays(starts.last, 40));
      for (var i = 0; i < 6; i++) starts.add(addDays(starts.last, 28));
      final entries = [for (final s in starts) ...period(s)];
      final p = CyclePredictor.predict(entries: entries, today: starts.last);
      expect(p.avgCycleLength, 28);
    });

    test('respects custom defaults', () {
      final p = CyclePredictor.predict(
        entries: period(DateTime(2026, 1, 1)),
        today: DateTime(2026, 1, 2),
        defaultCycleLength: 32,
      );
      expect(p.nextPeriodStart, DateTime(2026, 2, 2));
    });

    test('day predicates and lateness', () {
      final p = CyclePredictor.predict(
        entries: period(DateTime(2026, 1, 1)),
        today: DateTime(2026, 1, 10),
      );
      expect(p.isPredictedPeriod(DateTime(2026, 1, 29)), isTrue);
      expect(p.isPredictedPeriod(DateTime(2026, 1, 31)), isTrue); // avgPeriod 3
      expect(p.isPredictedPeriod(DateTime(2026, 2, 1)), isFalse);
      expect(p.isOvulation(DateTime(2026, 1, 15)), isTrue);
      expect(p.isFertile(DateTime(2026, 1, 10)), isTrue);
      expect(p.isFertile(DateTime(2026, 1, 17)), isFalse);
      expect(p.daysUntilNext(DateTime(2026, 1, 19)), 10);
      expect(p.daysUntilNext(DateTime(2026, 2, 2)), -4); // terlambat 4 hari
    });
  });
}
```

- [x] **Step 2: Run tests to verify they fail**

Run: `flutter test test/domain/cycle_predictor_test.dart`
Expected: FAIL — `cycle_predictor.dart` tidak ada.

- [x] **Step 3: Implement `lib/domain/cycle_predictor.dart`**

```dart
import 'date_key.dart';
import 'day_entry.dart';

class Period {
  const Period(this.start, this.end);
  final DateTime start;
  final DateTime end;
  int get length => daysBetween(start, end) + 1;
}

class CyclePrediction {
  const CyclePrediction({
    required this.periods,
    required this.avgCycleLength,
    required this.avgPeriodLength,
    this.nextPeriodStart,
    this.ovulationDay,
    this.fertileStart,
    this.fertileEnd,
  });

  final List<Period> periods;
  final int avgCycleLength;
  final int avgPeriodLength;
  final DateTime? nextPeriodStart;
  final DateTime? ovulationDay;
  final DateTime? fertileStart;
  final DateTime? fertileEnd;

  bool _within(DateTime d, DateTime? from, DateTime? to) {
    if (from == null || to == null) return false;
    return daysBetween(from, d) >= 0 && daysBetween(d, to) >= 0;
  }

  bool isPredictedPeriod(DateTime d) {
    final next = nextPeriodStart;
    if (next == null) return false;
    return _within(d, next, addDays(next, avgPeriodLength - 1));
  }

  bool isFertile(DateTime d) => _within(d, fertileStart, fertileEnd);

  bool isOvulation(DateTime d) => ovulationDay != null && daysBetween(ovulationDay!, d) == 0;

  /// Positif = hari menuju haid berikutnya; negatif = terlambat; null = belum ada data.
  int? daysUntilNext(DateTime today) =>
      nextPeriodStart == null ? null : daysBetween(today, nextPeriodStart!);
}

class CyclePredictor {
  static const minCycle = 15;
  static const maxCycle = 60;
  static const maxCyclesUsed = 6;
  static const lutealDays = 14;

  static List<Period> detectPeriods(Iterable<DayEntry> entries) {
    final days = entries.where((e) => e.isPeriodDay).map((e) => parseDateKey(e.date)).toList()
      ..sort();
    final periods = <Period>[];
    for (final day in days) {
      if (periods.isNotEmpty && daysBetween(periods.last.end, day) <= 2) {
        final last = periods.removeLast();
        periods.add(Period(last.start, day));
      } else {
        periods.add(Period(day, day));
      }
    }
    return periods;
  }

  static CyclePrediction predict({
    required Iterable<DayEntry> entries,
    required DateTime today,
    int defaultCycleLength = 28,
    int defaultPeriodLength = 5,
  }) {
    final periods = detectPeriods(entries);
    if (periods.isEmpty) {
      return CyclePrediction(
        periods: const [],
        avgCycleLength: defaultCycleLength,
        avgPeriodLength: defaultPeriodLength,
      );
    }

    final cycleLengths = <int>[
      for (var i = 1; i < periods.length; i++) daysBetween(periods[i - 1].start, periods[i].start),
    ].where((l) => l >= minCycle && l <= maxCycle).toList();

    final avgCycle = cycleLengths.isEmpty ? defaultCycleLength : _avgLast(cycleLengths);
    final avgPeriod = _avgLast(periods.map((p) => p.length).toList());

    final next = addDays(periods.last.start, avgCycle);
    final ovulation = addDays(next, -lutealDays);
    return CyclePrediction(
      periods: periods,
      avgCycleLength: avgCycle,
      avgPeriodLength: avgPeriod,
      nextPeriodStart: next,
      ovulationDay: ovulation,
      fertileStart: addDays(ovulation, -5),
      fertileEnd: addDays(ovulation, 1),
    );
  }

  static int _avgLast(List<int> values) {
    final recent = values.length > maxCyclesUsed ? values.sublist(values.length - maxCyclesUsed) : values;
    return (recent.reduce((a, b) => a + b) / recent.length).round();
  }
}
```

- [x] **Step 4: Implement `lib/domain/cycle_profile.dart`**

```dart
class CycleProfile {
  const CycleProfile({
    required this.id,
    required this.ownerUid,
    required this.memberUids,
    required this.name,
    this.defaultCycleLength = 28,
    this.defaultPeriodLength = 5,
  });

  final String id;
  final String ownerUid;
  final List<String> memberUids;
  final String name;
  final int defaultCycleLength;
  final int defaultPeriodLength;

  factory CycleProfile.fromMap(String id, Map<String, dynamic> map) => CycleProfile(
        id: id,
        ownerUid: map['ownerUid'] as String,
        memberUids: List<String>.from(map['memberUids'] as List? ?? const []),
        name: (map['name'] as String?) ?? '',
        defaultCycleLength: (map['defaultCycleLength'] as num?)?.toInt() ?? 28,
        defaultPeriodLength: (map['defaultPeriodLength'] as num?)?.toInt() ?? 5,
      );
}
```

- [x] **Step 5: Run tests to verify they pass**

Run: `flutter test test/domain`
Expected: PASS (semua test domain).

- [x] **Step 6: Commit**

```powershell
git add lib/domain test/domain
git commit -m "feat: add cycle prediction and profile model"
```

---

### Task 3: Generator kode undangan

**Files:**
- Create: `lib/data/invite_code.dart`
- Test: `test/data/invite_code_test.dart`

**Interfaces:**
- Consumes: —
- Produces: `const inviteAlphabet`, `String generateInviteCode({Random? random, int length = 6})`, `String normalizeInviteCode(String input)`

- [x] **Step 1: Write the failing test**

```dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/data/invite_code.dart';

void main() {
  test('generates 6 chars from the unambiguous alphabet', () {
    for (var i = 0; i < 200; i++) {
      final code = generateInviteCode();
      expect(code.length, 6);
      expect(code.split('').every(inviteAlphabet.contains), isTrue, reason: code);
    }
  });

  test('is deterministic for a seeded Random', () {
    expect(generateInviteCode(random: Random(1)), generateInviteCode(random: Random(1)));
  });

  test('normalize uppercases and strips spaces/dashes', () {
    expect(normalizeInviteCode(' ab-c 23x '), 'ABC23X');
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/invite_code_test.dart`
Expected: FAIL — file tidak ada.

- [x] **Step 3: Implement `lib/data/invite_code.dart`**

```dart
import 'dart:math';

/// Tanpa 0/O/1/I agar mudah dibacakan.
const inviteAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

String generateInviteCode({Random? random, int length = 6}) {
  final r = random ?? Random.secure();
  return List.generate(length, (_) => inviteAlphabet[r.nextInt(inviteAlphabet.length)]).join();
}

String normalizeInviteCode(String input) =>
    input.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
```

- [x] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/invite_code_test.dart`
Expected: PASS (3 tests).

- [x] **Step 5: Commit**

```powershell
git add lib/data/invite_code.dart test/data/invite_code_test.dart
git commit -m "feat: add invite code generator"
```

---

### Task 4: `AuthRepository`

**Files:**
- Create: `lib/data/auth_repository.dart`
- Test: `test/data/auth_repository_test.dart`

**Interfaces:**
- Consumes: `FirebaseAuth` (package firebase_auth)
- Produces: `class AuthRepository { AuthRepository(FirebaseAuth); Stream<User?> authStateChanges(); User? get currentUser; Future<void> signIn(String email, String password); Future<void> register(String email, String password); Future<void> sendPasswordReset(String email); Future<void> signOut(); }` dan `String authErrorMessage(Object error)`

- [x] **Step 1: Write the failing test**

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/data/auth_repository.dart';

void main() {
  test('register signs the user in and trims email', () async {
    final auth = MockFirebaseAuth();
    final repo = AuthRepository(auth);
    await repo.register('  a@b.co ', 'rahasia1');
    expect(repo.currentUser, isNotNull);
    expect(repo.currentUser!.email, 'a@b.co');
  });

  test('signOut clears the current user', () async {
    final auth = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'u1', email: 'a@b.co'));
    final repo = AuthRepository(auth);
    await repo.signOut();
    expect(repo.currentUser, isNull);
  });

  test('authErrorMessage maps common Firebase codes to Indonesian', () {
    expect(authErrorMessage(FirebaseAuthException(code: 'invalid-credential')),
        'Email atau password salah.');
    expect(authErrorMessage(FirebaseAuthException(code: 'email-already-in-use')),
        'Email sudah terdaftar. Silakan masuk.');
    expect(authErrorMessage(FirebaseAuthException(code: 'weak-password')),
        'Password minimal 6 karakter.');
    expect(authErrorMessage(FirebaseAuthException(code: 'network-request-failed')),
        'Tidak ada koneksi internet.');
    expect(authErrorMessage(Exception('x')), 'Terjadi kesalahan. Coba lagi.');
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/auth_repository_test.dart`
Expected: FAIL — file tidak ada.

- [x] **Step 3: Implement `lib/data/auth_repository.dart`**

```dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  AuthRepository(this._auth);
  final FirebaseAuth _auth;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<void> register(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);

  Future<void> sendPasswordReset(String email) => _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> signOut() => _auth.signOut();
}

String authErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Email atau password salah.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar. Silakan masuk.';
      case 'weak-password':
        return 'Password minimal 6 karakter.';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
    }
  }
  return 'Terjadi kesalahan. Coba lagi.';
}
```

- [x] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/auth_repository_test.dart`
Expected: PASS (3 tests).

- [x] **Step 5: Commit**

```powershell
git add lib/data/auth_repository.dart test/data/auth_repository_test.dart
git commit -m "feat: add auth repository with indonesian error messages"
```

---

### Task 5: `ProfileRepository` (profil, undangan, bergabung)

**Files:**
- Create: `lib/data/profile_repository.dart`
- Test: `test/data/profile_repository_test.dart`

**Interfaces:**
- Consumes: `CycleProfile` (Task 2), `generateInviteCode`, `normalizeInviteCode` (Task 3)
- Produces:
  - `class JoinException implements Exception { final String message; }`
  - `class ProfileRepository { ProfileRepository(FirebaseFirestore db, {Random? random}); Stream<String?> watchActiveProfileId(String uid); Stream<CycleProfile?> watchProfile(String profileId); Future<String> createProfile({required String uid, required String name}); Future<String> createInvite({required String uid, required String profileId, DateTime? now}); Future<void> joinWithCode({required String uid, required String rawCode, DateTime? now}); }`

- [x] **Step 1: Write the failing test**

```dart
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/data/profile_repository.dart';

void main() {
  late FakeFirebaseFirestore db;
  late ProfileRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = ProfileRepository(db, random: Random(42));
  });

  test('createProfile creates profile with owner as sole member and sets active profile', () async {
    final id = await repo.createProfile(uid: 'alice', name: '  Alice ');
    final profile = await db.collection('profiles').doc(id).get();
    expect(profile.data()!['ownerUid'], 'alice');
    expect(profile.data()!['memberUids'], ['alice']);
    expect(profile.data()!['name'], 'Alice');
    expect(profile.data()!['defaultCycleLength'], 28);
    expect(await repo.watchActiveProfileId('alice').first, id);
    final model = await repo.watchProfile(id).first;
    expect(model!.memberUids, ['alice']);
  });

  test('createInvite stores a 24h invite pointing at the profile', () async {
    final now = DateTime(2026, 10, 15, 10);
    final code = await repo.createInvite(uid: 'alice', profileId: 'p1', now: now);
    final invite = await db.collection('invites').doc(code).get();
    expect(code.length, 6);
    expect(invite.data()!['profileId'], 'p1');
    expect(invite.data()!['createdBy'], 'alice');
    expect((invite.data()!['expiresAt'] as Timestamp).toDate(), now.add(const Duration(hours: 24)));
  });

  test('joinWithCode adds the user and switches their active profile', () async {
    final id = await repo.createProfile(uid: 'alice', name: 'Alice');
    final now = DateTime(2026, 10, 15, 10);
    final code = await repo.createInvite(uid: 'alice', profileId: id, now: now);

    await repo.joinWithCode(uid: 'bob', rawCode: code.toLowerCase(), now: now);

    final profile = await db.collection('profiles').doc(id).get();
    expect(profile.data()!['memberUids'], ['alice', 'bob']);
    expect(profile.data()!['joinedWithCode'], code);
    expect(await repo.watchActiveProfileId('bob').first, id);
  });

  test('joinWithCode rejects unknown codes', () async {
    expect(
      () => repo.joinWithCode(uid: 'bob', rawCode: 'ZZZZZZ'),
      throwsA(isA<JoinException>().having((e) => e.message, 'message', 'Kode undangan tidak ditemukan.')),
    );
  });

  test('joinWithCode rejects expired codes', () async {
    final created = DateTime(2026, 10, 15, 10);
    final code = await repo.createInvite(uid: 'alice', profileId: 'p1', now: created);
    expect(
      () => repo.joinWithCode(uid: 'bob', rawCode: code, now: created.add(const Duration(hours: 25))),
      throwsA(isA<JoinException>().having((e) => e.message, 'message', 'Kode undangan sudah kedaluwarsa.')),
    );
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/profile_repository_test.dart`
Expected: FAIL — file tidak ada.

- [x] **Step 3: Implement `lib/data/profile_repository.dart`**

```dart
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/cycle_profile.dart';
import 'invite_code.dart';

class JoinException implements Exception {
  const JoinException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ProfileRepository {
  ProfileRepository(this._db, {Random? random}) : _random = random;

  final FirebaseFirestore _db;
  final Random? _random;

  static const inviteValidity = Duration(hours: 24);

  DocumentReference<Map<String, dynamic>> _user(String uid) => _db.collection('users').doc(uid);
  DocumentReference<Map<String, dynamic>> _profile(String id) => _db.collection('profiles').doc(id);

  Stream<String?> watchActiveProfileId(String uid) =>
      _user(uid).snapshots().map((s) => s.data()?['activeProfileId'] as String?);

  Stream<CycleProfile?> watchProfile(String profileId) => _profile(profileId)
      .snapshots()
      .map((s) => s.exists ? CycleProfile.fromMap(s.id, s.data()!) : null);

  Future<String> createProfile({required String uid, required String name}) async {
    final ref = _db.collection('profiles').doc();
    final batch = _db.batch()
      ..set(ref, {
        'ownerUid': uid,
        'memberUids': [uid],
        'name': name.trim(),
        'defaultCycleLength': 28,
        'defaultPeriodLength': 5,
        'createdAt': FieldValue.serverTimestamp(),
      })
      ..set(_user(uid), {'activeProfileId': ref.id}, SetOptions(merge: true));
    await batch.commit();
    return ref.id;
  }

  Future<String> createInvite({required String uid, required String profileId, DateTime? now}) async {
    final code = generateInviteCode(random: _random);
    final expiresAt = (now ?? DateTime.now()).add(inviteValidity);
    await _db.collection('invites').doc(code).set({
      'profileId': profileId,
      'createdBy': uid,
      'expiresAt': Timestamp.fromDate(expiresAt),
    });
    return code;
  }

  Future<void> joinWithCode({required String uid, required String rawCode, DateTime? now}) async {
    final code = normalizeInviteCode(rawCode);
    if (code.isEmpty) throw const JoinException('Kode undangan tidak ditemukan.');
    final invite = await _db.collection('invites').doc(code).get();
    if (!invite.exists) throw const JoinException('Kode undangan tidak ditemukan.');

    final data = invite.data()!;
    final expiresAt = (data['expiresAt'] as Timestamp).toDate();
    if ((now ?? DateTime.now()).isAfter(expiresAt)) {
      throw const JoinException('Kode undangan sudah kedaluwarsa.');
    }

    final profileId = data['profileId'] as String;
    final batch = _db.batch()
      ..update(_profile(profileId), {
        'memberUids': FieldValue.arrayUnion([uid]),
        'joinedWithCode': code, // dibaca Security Rules untuk validasi
      })
      ..set(_user(uid), {'activeProfileId': profileId}, SetOptions(merge: true));
    await batch.commit();
  }
}
```

- [x] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/profile_repository_test.dart`
Expected: PASS (5 tests).

- [x] **Step 5: Commit**

```powershell
git add lib/data/profile_repository.dart test/data/profile_repository_test.dart
git commit -m "feat: add profile repository with invite and join"
```

---

### Task 6: `DayRepository`

**Files:**
- Create: `lib/data/day_repository.dart`
- Test: `test/data/day_repository_test.dart`

**Interfaces:**
- Consumes: `DayEntry` (Task 1)
- Produces: `class DayRepository { DayRepository(FirebaseFirestore db); Stream<List<DayEntry>> watchAll(String profileId); Future<void> saveDay({required String profileId, required String uid, required DayEntry entry}); }`

- [x] **Step 1: Write the failing test**

```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/data/day_repository.dart';
import 'package:siklus/domain/day_entry.dart';

void main() {
  late FakeFirebaseFirestore db;
  late DayRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = DayRepository(db);
  });

  test('saveDay writes one document per date with updatedBy', () async {
    await repo.saveDay(
      profileId: 'p1',
      uid: 'alice',
      entry: const DayEntry(date: '2026-10-15', flow: FlowLevel.heavy, symptoms: {Symptom.cramps}),
    );
    final doc = await db.doc('profiles/p1/days/2026-10-15').get();
    expect(doc.data()!['flow'], 'heavy');
    expect(doc.data()!['symptoms'], ['cramps']);
    expect(doc.data()!['updatedBy'], 'alice');
    expect(doc.data()!.containsKey('updatedAt'), isTrue);
  });

  test('saving again overwrites the whole day (last write wins)', () async {
    await repo.saveDay(
      profileId: 'p1',
      uid: 'alice',
      entry: const DayEntry(date: '2026-10-15', flow: FlowLevel.heavy, note: 'a'),
    );
    await repo.saveDay(
      profileId: 'p1',
      uid: 'bob',
      entry: const DayEntry(date: '2026-10-15', moods: {Mood.calm}),
    );
    final data = (await db.doc('profiles/p1/days/2026-10-15').get()).data()!;
    expect(data['flow'], isNull);
    expect(data['note'], '');
    expect(data['moods'], ['calm']);
    expect(data['updatedBy'], 'bob');
  });

  test('saving an empty entry deletes the day', () async {
    await repo.saveDay(profileId: 'p1', uid: 'alice', entry: const DayEntry(date: '2026-10-15', note: 'x'));
    await repo.saveDay(profileId: 'p1', uid: 'alice', entry: const DayEntry(date: '2026-10-15'));
    expect((await db.doc('profiles/p1/days/2026-10-15').get()).exists, isFalse);
  });

  test('watchAll emits parsed entries', () async {
    await repo.saveDay(profileId: 'p1', uid: 'a', entry: const DayEntry(date: '2026-10-14', flow: FlowLevel.light));
    await repo.saveDay(profileId: 'p1', uid: 'a', entry: const DayEntry(date: '2026-10-15', flow: FlowLevel.medium));
    final entries = await repo.watchAll('p1').first;
    expect(entries.map((e) => e.date).toSet(), {'2026-10-14', '2026-10-15'});
    expect(entries.every((e) => e.updatedBy == 'a'), isTrue);
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/day_repository_test.dart`
Expected: FAIL — file tidak ada.

- [x] **Step 3: Implement `lib/data/day_repository.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/day_entry.dart';

class DayRepository {
  DayRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _days(String profileId) =>
      _db.collection('profiles').doc(profileId).collection('days');

  Stream<List<DayEntry>> watchAll(String profileId) => _days(profileId)
      .snapshots()
      .map((q) => q.docs.map((d) => DayEntry.fromMap(d.data())).toList());

  /// Satu dokumen per tanggal, ditulis utuh → last-write-wins.
  /// PENTING: saat offline Future ini baru selesai setelah tersinkron;
  /// pemanggil di UI harus memakai `unawaited(...)`.
  Future<void> saveDay({required String profileId, required String uid, required DayEntry entry}) {
    final ref = _days(profileId).doc(entry.date);
    if (entry.isEmpty) return ref.delete();
    return ref.set({
      ...entry.toMap(),
      'updatedBy': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
```

- [x] **Step 4: Run test to verify it passes**

Run: `flutter test test/data`
Expected: PASS (semua test data).

- [x] **Step 5: Commit**

```powershell
git add lib/data/day_repository.dart test/data/day_repository_test.dart
git commit -m "feat: add day repository with last-write-wins saves"
```

---

### Task 7: Firestore Security Rules + test emulator + deploy

**Files:**
- Create: `firestore.rules`, `firestore.indexes.json`
- Create/Modify: `firebase.json` (pertahankan kunci `flutter` yang dibuat flutterfire jika ada)
- Create: `firestore-tests/package.json`, `firestore-tests/rules.test.mjs`
- Modify: `.gitignore` (tambah `firestore-tests/node_modules/`)

**Interfaces:**
- Consumes: bentuk dokumen dari Task 5 & 6 (field `memberUids`, `joinedWithCode`, `days/*` keys, `invites/*`)
- Produces: rules yang ter-deploy; perintah test `firebase emulators:exec --project demo-siklus --only firestore "npm --prefix firestore-tests test"`

- [x] **Step 1: Tulis konfigurasi Firebase CLI**

`firebase.json` — jika file sudah ada dari flutterfire, tambahkan kunci `firestore` dan `emulators` tanpa menghapus kunci `flutter`:
```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "emulators": {
    "firestore": { "port": 8080 },
    "ui": { "enabled": false }
  }
}
```

`firestore.indexes.json`:
```json
{ "indexes": [], "fieldOverrides": [] }
```

- [x] **Step 2: Tulis test rules yang gagal**

`firestore-tests/package.json`:
```json
{
  "name": "siklus-firestore-tests",
  "private": true,
  "type": "module",
  "scripts": { "test": "node --test" }
}
```

Run: `npm --prefix firestore-tests install --save-dev @firebase/rules-unit-testing firebase`

`firestore-tests/rules.test.mjs`:
```js
import { after, before, beforeEach, test } from 'node:test';
import { readFileSync } from 'node:fs';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  arrayUnion,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-siklus',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
});

after(async () => env.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'profiles/p1'), {
      ownerUid: 'alice', memberUids: ['alice'], name: 'Alice',
      defaultCycleLength: 28, defaultPeriodLength: 5,
    });
    await setDoc(doc(db, 'invites/ABC234'), {
      profileId: 'p1', createdBy: 'alice', expiresAt: Timestamp.fromMillis(Date.now() + 3_600_000),
    });
    await setDoc(doc(db, 'invites/OLD234'), {
      profileId: 'p1', createdBy: 'alice', expiresAt: Timestamp.fromMillis(Date.now() - 1_000),
    });
  });
});

const as = (uid) => env.authenticatedContext(uid).firestore();
const day = (uid, extra = {}) => ({
  date: '2026-10-15', flow: 'medium', symptoms: [], moods: [], energy: null,
  note: '', updatedBy: uid, updatedAt: serverTimestamp(), ...extra,
});

test('user can only access their own user doc', async () => {
  await assertSucceeds(setDoc(doc(as('alice'), 'users/alice'), { activeProfileId: 'p1' }));
  await assertFails(getDoc(doc(as('bob'), 'users/alice')));
});

test('stranger cannot read profile or days', async () => {
  await assertFails(getDoc(doc(as('bob'), 'profiles/p1')));
  await assertFails(getDoc(doc(as('bob'), 'profiles/p1/days/2026-10-15')));
});

test('member can write a valid day', async () => {
  await assertSucceeds(setDoc(doc(as('alice'), 'profiles/p1/days/2026-10-15'), day('alice')));
});

test('day must carry the writer uid, matching date and allowed keys', async () => {
  const db = as('alice');
  await assertFails(setDoc(doc(db, 'profiles/p1/days/2026-10-15'), day('bob')));
  await assertFails(setDoc(doc(db, 'profiles/p1/days/2026-10-16'), day('alice')));
  await assertFails(setDoc(doc(db, 'profiles/p1/days/2026-10-15'), day('alice', { hacked: true })));
  await assertFails(setDoc(doc(db, 'profiles/p1/days/2026-10-15'), day('alice', { note: 'x'.repeat(2001) })));
});

test('stranger cannot write days', async () => {
  await assertFails(setDoc(doc(as('bob'), 'profiles/p1/days/2026-10-15'), day('bob')));
});

test('user can create a profile only as its sole member', async () => {
  const db = as('bob');
  await assertSucceeds(setDoc(doc(db, 'profiles/p2'), {
    ownerUid: 'bob', memberUids: ['bob'], name: 'Bob', defaultCycleLength: 28, defaultPeriodLength: 5,
  }));
  await assertFails(setDoc(doc(db, 'profiles/p3'), {
    ownerUid: 'bob', memberUids: ['bob', 'alice'], name: 'X', defaultCycleLength: 28, defaultPeriodLength: 5,
  }));
});

test('valid invite lets bob join, then bob can write days', async () => {
  const db = as('bob');
  await assertSucceeds(getDoc(doc(db, 'invites/ABC234')));
  await assertSucceeds(updateDoc(doc(db, 'profiles/p1'), {
    memberUids: arrayUnion('bob'), joinedWithCode: 'ABC234',
  }));
  await assertSucceeds(setDoc(doc(db, 'profiles/p1/days/2026-10-15'), day('bob')));
});

test('expired or missing invite cannot be used', async () => {
  const db = as('bob');
  await assertFails(updateDoc(doc(db, 'profiles/p1'), { memberUids: arrayUnion('bob'), joinedWithCode: 'OLD234' }));
  await assertFails(updateDoc(doc(db, 'profiles/p1'), { memberUids: arrayUnion('bob'), joinedWithCode: 'NOPE22' }));
  await assertFails(updateDoc(doc(db, 'profiles/p1'), { memberUids: arrayUnion('bob') }));
});

test('invite cannot be used to add someone else', async () => {
  await assertFails(updateDoc(doc(as('bob'), 'profiles/p1'), {
    memberUids: arrayUnion('charlie'), joinedWithCode: 'ABC234',
  }));
});

test('only members can create invites for a profile', async () => {
  const future = Timestamp.fromMillis(Date.now() + 3_600_000);
  await assertSucceeds(setDoc(doc(as('alice'), 'invites/NEW234'), { profileId: 'p1', createdBy: 'alice', expiresAt: future }));
  await assertFails(setDoc(doc(as('bob'), 'invites/BAD234'), { profileId: 'p1', createdBy: 'bob', expiresAt: future }));
});
```

Tambahkan `firestore.rules` sementara yang menolak semuanya agar test bisa berjalan dan gagal:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} { allow read, write: if false; }
  }
}
```

- [x] **Step 3: Run test to verify it fails**

Run: `firebase emulators:exec --project demo-siklus --only firestore "npm --prefix firestore-tests test"`
Expected: FAIL — test yang memakai `assertSucceeds` gagal (`PERMISSION_DENIED`); test `assertFails` lulus.

- [x] **Step 4: Tulis `firestore.rules` final**

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function signedIn() {
      return request.auth != null;
    }

    function isMember(profileId) {
      return signedIn()
        && request.auth.uid in get(/databases/$(database)/documents/profiles/$(profileId)).data.memberUids;
    }

    match /users/{uid} {
      allow read, write: if signedIn() && request.auth.uid == uid;
    }

    match /profiles/{profileId} {
      function isValidJoin() {
        let code = request.resource.data.joinedWithCode;
        let invite = get(/databases/$(database)/documents/invites/$(code)).data;
        return request.resource.data.diff(resource.data).affectedKeys().hasOnly(['memberUids', 'joinedWithCode'])
          && request.resource.data.memberUids.removeAll(resource.data.memberUids) == [request.auth.uid]
          && resource.data.memberUids.removeAll(request.resource.data.memberUids).size() == 0
          && request.resource.data.memberUids.size() <= 5
          && invite.profileId == profileId
          && invite.expiresAt > request.time;
      }

      allow read: if signedIn() && request.auth.uid in resource.data.memberUids;

      allow create: if signedIn()
        && request.resource.data.ownerUid == request.auth.uid
        && request.resource.data.memberUids == [request.auth.uid];

      allow update: if signedIn() && (
        (request.auth.uid in resource.data.memberUids
          && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['name', 'defaultCycleLength', 'defaultPeriodLength']))
        || isValidJoin()
      );

      match /days/{date} {
        allow read, delete: if isMember(profileId);
        allow create, update: if isMember(profileId)
          && request.resource.data.keys().hasOnly(['date', 'flow', 'symptoms', 'moods', 'energy', 'note', 'updatedBy', 'updatedAt'])
          && request.resource.data.date == date
          && request.resource.data.updatedBy == request.auth.uid
          && request.resource.data.note is string
          && request.resource.data.note.size() <= 2000
          && request.resource.data.symptoms is list
          && request.resource.data.moods is list;
      }
    }

    match /invites/{code} {
      allow get: if signedIn();
      allow create: if signedIn()
        && request.resource.data.createdBy == request.auth.uid
        && isMember(request.resource.data.profileId);
      allow delete: if signedIn() && resource.data.createdBy == request.auth.uid;
    }
  }
}
```

- [x] **Step 5: Run test to verify it passes**

Run: `firebase emulators:exec --project demo-siklus --only firestore "npm --prefix firestore-tests test"`
Expected: PASS — `# pass 10`, `# fail 0`.

- [x] **Step 6: Deploy rules ke proyek asli**

Run: `firebase deploy --only firestore:rules`
Expected: `✔  Deploy complete!`

- [x] **Step 7: Commit**

```powershell
Add-Content .gitignore "`nfirestore-tests/node_modules/"
git add firebase.json firestore.rules firestore.indexes.json firestore-tests/package.json firestore-tests/package-lock.json firestore-tests/rules.test.mjs .gitignore
git commit -m "feat: add firestore security rules with emulator tests"
```

---

### Task 8: Providers, `AuthGate`, `LoginScreen`, `SiklusApp`

**Files:**
- Create: `lib/state/providers.dart`
- Create: `lib/features/auth/auth_gate.dart`, `lib/features/auth/login_screen.dart`
- Create: `lib/features/onboarding/onboarding_screen.dart` (placeholder, diisi Task 9)
- Create: `lib/features/home/home_shell.dart` (placeholder, diisi Task 10)
- Replace: `lib/app.dart`
- Test: `test/features/auth_flow_test.dart`

**Interfaces:**
- Consumes: `AuthRepository`, `authErrorMessage` (Task 4), `ProfileRepository` (Task 5), `DayRepository` (Task 6), `CyclePredictor`, `CyclePrediction`, `CycleProfile` (Task 2), `DayEntry`, `dateOnly` (Task 1)
- Produces (di `lib/state/providers.dart`):
  - `firebaseAuthProvider: Provider<FirebaseAuth>`, `firestoreProvider: Provider<FirebaseFirestore>`, `todayProvider: Provider<DateTime>`
  - `authRepositoryProvider`, `profileRepositoryProvider`, `dayRepositoryProvider`
  - `authStateProvider: StreamProvider<User?>`, `activeProfileIdProvider: StreamProvider<String?>`, `activeProfileProvider: StreamProvider<CycleProfile?>`, `dayEntriesProvider: StreamProvider<List<DayEntry>>`, `predictionProvider: Provider<CyclePrediction>`
  - Widget: `AuthGate`, `LoginScreen`, `OnboardingScreen`, `HomeShell`, `SiklusApp`

- [x] **Step 1: Write the failing test**
- [x] **Step 2: Run test to verify it fails**
- [x] **Step 3: Implement `lib/state/providers.dart`**
- [x] **Step 4: Implement `lib/features/auth/login_screen.dart`**
- [x] **Step 5: Buat placeholder `OnboardingScreen` dan `HomeShell`**
- [x] **Step 6: Implement `lib/features/auth/auth_gate.dart`**
- [x] **Step 7: Replace `lib/app.dart`**
- [x] **Step 8: Run test to verify it passes**
- [x] **Step 9: Commit**

`test/features/auth_flow_test.dart`:
```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:siklus/features/auth/auth_gate.dart';
import 'package:siklus/features/auth/login_screen.dart';
import 'package:siklus/features/home/home_shell.dart';
import 'package:siklus/features/onboarding/onboarding_screen.dart';
import 'package:siklus/state/providers.dart';

Widget harness(MockFirebaseAuth auth, FakeFirebaseFirestore db, Widget child) => ProviderScope(
      overrides: [
        firebaseAuthProvider.overrideWithValue(auth),
        firestoreProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(DateTime(2026, 10, 15)),
      ],
      child: MaterialApp(home: child),
    );

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  testWidgets('signed out → LoginScreen', (tester) async {
    await tester.pumpWidget(harness(MockFirebaseAuth(), FakeFirebaseFirestore(), const AuthGate()));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('signed in without profile → OnboardingScreen', (tester) async {
    final auth = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'u1', email: 'a@b.co'));
    await tester.pumpWidget(harness(auth, FakeFirebaseFirestore(), const AuthGate()));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('signed in with profile → HomeShell', (tester) async {
    final auth = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'u1', email: 'a@b.co'));
    final db = FakeFirebaseFirestore();
    await db.doc('users/u1').set({'activeProfileId': 'p1'});
    await db.doc('profiles/p1').set({'ownerUid': 'u1', 'memberUids': ['u1'], 'name': 'A'});
    await tester.pumpWidget(harness(auth, db, const AuthGate()));
    await tester.pumpAndSettle();
    expect(find.byType(HomeShell), findsOneWidget);
  });

  testWidgets('login screen validates empty fields', (tester) async {
    await tester.pumpWidget(harness(MockFirebaseAuth(), FakeFirebaseFirestore(), const LoginScreen()));
    await tester.tap(find.text('Masuk'));
    await tester.pump();
    expect(find.text('Email dan password wajib diisi.'), findsOneWidget);
  });

  testWidgets('register from login screen signs the user in', (tester) async {
    final auth = MockFirebaseAuth();
    await tester.pumpWidget(harness(auth, FakeFirebaseFirestore(), const LoginScreen()));
    await tester.enterText(find.byKey(const Key('email')), 'a@b.co');
    await tester.enterText(find.byKey(const Key('password')), 'rahasia1');
    await tester.tap(find.text('Daftar akun baru'));
    await tester.pumpAndSettle();
    expect(auth.currentUser?.email, 'a@b.co');
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/auth_flow_test.dart`
Expected: FAIL — `providers.dart`, `auth_gate.dart`, dst. tidak ada.

- [x] **Step 3: Implement `lib/state/providers.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../data/day_repository.dart';
import '../data/profile_repository.dart';
import '../domain/cycle_predictor.dart';
import '../domain/cycle_profile.dart';
import '../domain/date_key.dart';
import '../domain/day_entry.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

/// Di-override di test. Catatan: tidak otomatis berganti saat lewat tengah malam (cukup untuk MVP).
final todayProvider = Provider<DateTime>((ref) => dateOnly(DateTime.now()));

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository(ref.watch(firebaseAuthProvider)));
final profileRepositoryProvider =
    Provider<ProfileRepository>((ref) => ProfileRepository(ref.watch(firestoreProvider)));
final dayRepositoryProvider =
    Provider<DayRepository>((ref) => DayRepository(ref.watch(firestoreProvider)));

final authStateProvider =
    StreamProvider<User?>((ref) => ref.watch(authRepositoryProvider).authStateChanges());

final activeProfileIdProvider = StreamProvider<String?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return ref.watch(profileRepositoryProvider).watchActiveProfileId(user.uid);
});

final activeProfileProvider = StreamProvider<CycleProfile?>((ref) {
  final id = ref.watch(activeProfileIdProvider).valueOrNull;
  if (id == null) return Stream.value(null);
  return ref.watch(profileRepositoryProvider).watchProfile(id);
});

final dayEntriesProvider = StreamProvider<List<DayEntry>>((ref) {
  final id = ref.watch(activeProfileIdProvider).valueOrNull;
  if (id == null) return Stream.value(const <DayEntry>[]);
  return ref.watch(dayRepositoryProvider).watchAll(id);
});

final predictionProvider = Provider<CyclePrediction>((ref) {
  final entries = ref.watch(dayEntriesProvider).valueOrNull ?? const <DayEntry>[];
  final profile = ref.watch(activeProfileProvider).valueOrNull;
  return CyclePredictor.predict(
    entries: entries,
    today: ref.watch(todayProvider),
    defaultCycleLength: profile?.defaultCycleLength ?? 28,
    defaultPeriodLength: profile?.defaultPeriodLength ?? 5,
  );
});
```

- [x] **Step 4: Implement `lib/features/auth/login_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository.dart';
import '../../state/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function(AuthRepository repo) action) async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Email dan password wajib diisi.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action(ref.read(authRepositoryProvider));
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_email.text.trim().isEmpty) {
      setState(() => _error = 'Isi email terlebih dahulu.');
      return;
    }
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(_email.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Email reset password sudah dikirim.')));
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 48),
            Text('Siklus', style: theme.textTheme.headlineLarge),
            const SizedBox(height: 8),
            const Text('Catat siklus bersama pasangan.'),
            const SizedBox(height: 32),
            TextField(
              key: const Key('email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('password'),
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password (min. 6 karakter)',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : () => _run((r) => r.signIn(_email.text, _password.text)),
              child: const Text('Masuk'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _busy ? null : () => _run((r) => r.register(_email.text, _password.text)),
              child: const Text('Daftar akun baru'),
            ),
            TextButton(onPressed: _busy ? null : _resetPassword, child: const Text('Lupa password?')),
          ],
        ),
      ),
    );
  }
}
```

- [x] **Step 5: Buat placeholder `OnboardingScreen` dan `HomeShell`**

`lib/features/onboarding/onboarding_screen.dart`:
```dart
import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Onboarding')));
}
```

`lib/features/home/home_shell.dart`:
```dart
import 'package:flutter/material.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Beranda')));
}
```

- [x] **Step 6: Implement `lib/features/auth/auth_gate.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../home/home_shell.dart';
import '../onboarding/onboarding_screen.dart';
import 'login_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () => const _Loading(),
      error: (e, _) => _Error('$e'),
      data: (user) {
        if (user == null) return const LoginScreen();
        final active = ref.watch(activeProfileIdProvider);
        return active.when(
          loading: () => const _Loading(),
          error: (e, _) => _Error('$e'),
          data: (id) => id == null ? const OnboardingScreen() : const HomeShell(),
        );
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _Error extends StatelessWidget {
  const _Error(this.message);
  final String message;
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('Terjadi kesalahan: $message')));
}
```

- [x] **Step 7: Replace `lib/app.dart`**

```dart
import 'package:flutter/material.dart';

import 'features/auth/auth_gate.dart';

class SiklusApp extends StatelessWidget {
  const SiklusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Siklus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFFD9475B), useMaterial3: true),
      home: const AuthGate(),
    );
  }
}
```

- [x] **Step 8: Run test to verify it passes**

Run: `flutter test test/features/auth_flow_test.dart`
Expected: PASS (5 tests).

- [x] **Step 9: Commit**

```powershell
git add lib test/features/auth_flow_test.dart
git commit -m "feat: add providers, auth gate and login screen"
```

---

### Task 9: `OnboardingScreen` (buat profil / gabung dengan kode)

**Files:**
- Replace: `lib/features/onboarding/onboarding_screen.dart`
- Test: `test/features/onboarding_screen_test.dart`

**Interfaces:**
- Consumes: `authStateProvider`, `profileRepositoryProvider` (Task 8), `JoinException` (Task 5)
- Produces: `class OnboardingScreen extends ConsumerStatefulWidget` dengan field berkunci `Key('profileName')` dan `Key('inviteCode')`, tombol `'Buat profil'` dan `'Gabung'`.

- [x] **Step 1: Write the failing test**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/features/onboarding/onboarding_screen.dart';
import 'package:siklus/state/providers.dart';

void main() {
  late MockFirebaseAuth auth;
  late FakeFirebaseFirestore db;

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        firebaseAuthProvider.overrideWithValue(auth),
        firestoreProvider.overrideWithValue(db),
      ],
      child: const MaterialApp(home: OnboardingScreen()),
    ));
    await tester.pumpAndSettle();
  }

  setUp(() {
    auth = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'u1', email: 'a@b.co'));
    db = FakeFirebaseFirestore();
  });

  testWidgets('creating a profile sets activeProfileId', (tester) async {
    await pump(tester);
    await tester.enterText(find.byKey(const Key('profileName')), 'Sari');
    await tester.tap(find.text('Buat profil'));
    await tester.pumpAndSettle();
    final user = await db.doc('users/u1').get();
    final profileId = user.data()!['activeProfileId'] as String;
    final profile = await db.doc('profiles/$profileId').get();
    expect(profile.data()!['name'], 'Sari');
  });

  testWidgets('empty name shows a message', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Buat profil'));
    await tester.pump();
    expect(find.text('Isi nama profil.'), findsOneWidget);
  });

  testWidgets('joining with a valid code adds the user', (tester) async {
    await db.doc('profiles/p1').set({'ownerUid': 'alice', 'memberUids': ['alice'], 'name': 'A'});
    await db.doc('invites/ABC234').set({
      'profileId': 'p1',
      'createdBy': 'alice',
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 1))),
    });
    await pump(tester);
    await tester.enterText(find.byKey(const Key('inviteCode')), 'abc 234');
    await tester.tap(find.text('Gabung'));
    await tester.pumpAndSettle();
    final profile = await db.doc('profiles/p1').get();
    expect(profile.data()!['memberUids'], ['alice', 'u1']);
  });

  testWidgets('unknown code shows the JoinException message', (tester) async {
    await pump(tester);
    await tester.enterText(find.byKey(const Key('inviteCode')), 'ZZZZZZ');
    await tester.tap(find.text('Gabung'));
    await tester.pumpAndSettle();
    expect(find.text('Kode undangan tidak ditemukan.'), findsOneWidget);
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/onboarding_screen_test.dart`
Expected: FAIL — `Key('profileName')` tidak ditemukan (masih placeholder).

- [x] **Step 3: Implement `lib/features/onboarding/onboarding_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/profile_repository.dart';
import '../../state/providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _name = TextEditingController();
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  void _snack(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _create() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    if (_name.text.trim().isEmpty) {
      _snack('Isi nama profil.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(profileRepositoryProvider).createProfile(uid: user.uid, name: _name.text);
    } catch (e) {
      if (mounted) _snack('Gagal membuat profil. Pastikan terhubung ke internet.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(profileRepositoryProvider).joinWithCode(uid: user.uid, rawCode: _code.text);
    } on JoinException catch (e) {
      if (mounted) _snack(e.message);
    } catch (e) {
      if (mounted) _snack('Gagal bergabung. Pastikan terhubung ke internet.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authStateProvider); // menjaga stream login tetap aktif
    final title = Theme.of(context).textTheme.titleMedium;
    return Scaffold(
      appBar: AppBar(title: const Text('Mulai')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Saya yang mencatat siklus', style: title),
          const SizedBox(height: 12),
          TextField(
            key: const Key('profileName'),
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Nama profil (mis. nama Anda)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _busy ? null : _create, child: const Text('Buat profil')),
          const Divider(height: 48),
          Text('Saya diundang pasangan', style: title),
          const SizedBox(height: 12),
          TextField(
            key: const Key('inviteCode'),
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Kode undangan', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _busy ? null : _join, child: const Text('Gabung')),
        ],
      ),
    );
  }
}
```

- [x] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/onboarding_screen_test.dart`
Expected: PASS (4 tests).

- [x] **Step 5: Commit**

```powershell
git add lib/features/onboarding test/features/onboarding_screen_test.dart
git commit -m "feat: add onboarding to create or join a profile"
```

---

### Task 10: Logika kalender + `CalendarScreen` + `HomeShell`

**Files:**
- Create: `lib/features/calendar/day_marker.dart`
- Create: `lib/features/calendar/prediction_summary.dart`
- Create: `lib/features/calendar/calendar_screen.dart`
- Create: `lib/features/log/day_log_screen.dart` (placeholder, diisi Task 11)
- Create: `lib/features/settings/settings_screen.dart` (placeholder, diisi Task 12)
- Replace: `lib/features/home/home_shell.dart`
- Test: `test/features/calendar_logic_test.dart`

**Interfaces:**
- Consumes: `CyclePrediction` (Task 2), `DayEntry`, `FlowLevel`, `dateKey` (Task 1), providers (Task 8)
- Produces:
  - `enum DayMarker { period, spotting, ovulation, predictedPeriod, fertile, logged, none }`
  - `DayMarker markerFor(DateTime day, Map<String, DayEntry> entriesByDate, CyclePrediction prediction)`
  - `class DayCell extends StatelessWidget { DayCell({required DateTime day, required DayMarker marker, bool isToday}) }`
  - `String predictionSummary(CyclePrediction prediction, DateTime today)`
  - `const cycleDisclaimer` (String)
  - `class DayLogScreen extends ConsumerStatefulWidget { const DayLogScreen({super.key, required DateTime date}) }`
  - `class SettingsScreen extends ConsumerWidget`

- [x] **Step 1: Write the failing test**

`test/features/calendar_logic_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/domain/cycle_predictor.dart';
import 'package:siklus/domain/date_key.dart';
import 'package:siklus/domain/day_entry.dart';
import 'package:siklus/features/calendar/day_marker.dart';
import 'package:siklus/features/calendar/prediction_summary.dart';

void main() {
  final entries = [
    for (var i = 0; i < 3; i++) DayEntry(date: dateKey(DateTime(2026, 1, 1 + i)), flow: FlowLevel.medium),
    const DayEntry(date: '2026-01-05', flow: FlowLevel.spotting),
    const DayEntry(date: '2026-01-07', moods: {Mood.sad}),
  ];
  final byDate = {for (final e in entries) e.date: e};
  final prediction = CyclePredictor.predict(entries: entries, today: DateTime(2026, 1, 10));

  test('markerFor follows priority', () {
    expect(markerFor(DateTime(2026, 1, 2), byDate, prediction), DayMarker.period);
    expect(markerFor(DateTime(2026, 1, 5), byDate, prediction), DayMarker.spotting);
    expect(markerFor(DateTime(2026, 1, 7), byDate, prediction), DayMarker.logged);
    expect(markerFor(DateTime(2026, 1, 15), byDate, prediction), DayMarker.ovulation);
    expect(markerFor(DateTime(2026, 1, 12), byDate, prediction), DayMarker.fertile);
    expect(markerFor(DateTime(2026, 1, 29), byDate, prediction), DayMarker.predictedPeriod);
    expect(markerFor(DateTime(2026, 1, 22), byDate, prediction), DayMarker.none);
  });

  test('predictionSummary covers all states', () {
    final empty = CyclePredictor.predict(entries: const [], today: DateTime(2026, 1, 1));
    expect(predictionSummary(empty, DateTime(2026, 1, 1)), 'Catat haid pertama untuk melihat prediksi.');
    expect(predictionSummary(prediction, DateTime(2026, 1, 19)), 'Haid berikutnya dalam 10 hari');
    expect(predictionSummary(prediction, DateTime(2026, 1, 29)), 'Haid diperkirakan mulai hari ini');
    expect(predictionSummary(prediction, DateTime(2026, 2, 2)), 'Haid terlambat 4 hari');
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/calendar_logic_test.dart`
Expected: FAIL — `day_marker.dart` tidak ada.

- [x] **Step 3: Implement `lib/features/calendar/day_marker.dart`**

```dart
import 'package:flutter/material.dart';

import '../../domain/cycle_predictor.dart';
import '../../domain/date_key.dart';
import '../../domain/day_entry.dart';

enum DayMarker { period, spotting, ovulation, predictedPeriod, fertile, logged, none }

/// Prioritas: data tercatat > prediksi.
DayMarker markerFor(DateTime day, Map<String, DayEntry> entriesByDate, CyclePrediction prediction) {
  final entry = entriesByDate[dateKey(day)];
  if (entry != null && entry.isPeriodDay) return DayMarker.period;
  if (entry?.flow == FlowLevel.spotting) return DayMarker.spotting;
  if (prediction.isOvulation(day)) return DayMarker.ovulation;
  if (prediction.isPredictedPeriod(day)) return DayMarker.predictedPeriod;
  if (prediction.isFertile(day)) return DayMarker.fertile;
  if (entry != null && !entry.isEmpty) return DayMarker.logged;
  return DayMarker.none;
}

const periodColor = Color(0xFFD9475B);
const fertileColor = Color(0xFF2A9D8F);

class DayCell extends StatelessWidget {
  const DayCell({super.key, required this.day, required this.marker, this.isToday = false});

  final DateTime day;
  final DayMarker marker;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    Color? fill;
    Color? border;
    var textColor = Theme.of(context).colorScheme.onSurface;
    switch (marker) {
      case DayMarker.period:
        fill = periodColor;
        textColor = Colors.white;
      case DayMarker.spotting:
        fill = periodColor.withValues(alpha: 0.25);
      case DayMarker.ovulation:
        fill = fertileColor;
        textColor = Colors.white;
      case DayMarker.predictedPeriod:
        border = periodColor;
      case DayMarker.fertile:
        fill = fertileColor.withValues(alpha: 0.2);
      case DayMarker.logged:
      case DayMarker.none:
        break;
    }
    return Container(
      margin: const EdgeInsets.all(4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: border != null
            ? Border.all(color: border, width: 2)
            : isToday
                ? Border.all(color: Theme.of(context).colorScheme.outline)
                : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${day.day}', style: TextStyle(color: textColor, fontWeight: isToday ? FontWeight.bold : null)),
          if (marker == DayMarker.logged)
            Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
        ],
      ),
    );
  }
}
```

- [x] **Step 4: Implement `lib/features/calendar/prediction_summary.dart`**

```dart
import '../../domain/cycle_predictor.dart';

const cycleDisclaimer =
    'Prediksi hanya perkiraan berdasarkan riwayat, bukan alat kontrasepsi atau diagnosis medis.';

String predictionSummary(CyclePrediction prediction, DateTime today) {
  final days = prediction.daysUntilNext(today);
  if (days == null) return 'Catat haid pertama untuk melihat prediksi.';
  if (days > 0) return 'Haid berikutnya dalam $days hari';
  if (days == 0) return 'Haid diperkirakan mulai hari ini';
  return 'Haid terlambat ${-days} hari';
}
```

- [x] **Step 5: Run logic test to verify it passes**

Run: `flutter test test/features/calendar_logic_test.dart`
Expected: PASS (2 tests).

- [x] **Step 6: Buat placeholder `DayLogScreen` dan `SettingsScreen`**

`lib/features/log/day_log_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DayLogScreen extends ConsumerStatefulWidget {
  const DayLogScreen({super.key, required this.date});
  final DateTime date;

  @override
  ConsumerState<DayLogScreen> createState() => _DayLogScreenState();
}

class _DayLogScreenState extends ConsumerState<DayLogScreen> {
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Catat hari')));
}
```

`lib/features/settings/settings_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const Center(child: Text('Pengaturan'));
}
```

- [x] **Step 7: Implement `lib/features/calendar/calendar_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../domain/day_entry.dart';
import '../../state/providers.dart';
import '../log/day_log_screen.dart';
import 'day_marker.dart';
import 'prediction_summary.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime? _focused;

  void _openDay(DateTime day) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DayLogScreen(date: day)));
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayProvider);
    final entries = ref.watch(dayEntriesProvider).valueOrNull ?? const <DayEntry>[];
    final byDate = {for (final e in entries) e.date: e};
    final prediction = ref.watch(predictionProvider);
    final focused = _focused ?? today;

    Widget cell(DateTime day, {bool isToday = false}) =>
        DayCell(day: day, marker: markerFor(day, byDate, prediction), isToday: isToday);

    return Scaffold(
      appBar: AppBar(title: const Text('Kalender')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(predictionSummary(prediction, today),
                style: Theme.of(context).textTheme.titleLarge),
          ),
          TableCalendar<void>(
            locale: 'id_ID',
            firstDay: DateTime(2020, 1, 1),
            lastDay: DateTime(today.year + 2, 12, 31),
            focusedDay: focused,
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableCalendarFormats: const {CalendarFormat.month: 'Bulan'},
            onPageChanged: (day) => _focused = day,
            onDaySelected: (selected, newFocused) {
              setState(() => _focused = newFocused);
              _openDay(selected);
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, _) => cell(day),
              todayBuilder: (context, day, _) => cell(day, isToday: true),
            ),
          ),
          const _Legend(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(cycleDisclaimer, style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDay(today),
        icon: const Icon(Icons.edit),
        label: const Text('Catat hari ini'),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(Widget dot, String label) =>
        Row(mainAxisSize: MainAxisSize.min, children: [dot, const SizedBox(width: 6), Text(label)]);
    Widget dot({Color? fill, Color? border}) => Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: border != null ? Border.all(color: border, width: 2) : null,
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(spacing: 16, runSpacing: 8, children: [
        item(dot(fill: periodColor), 'Haid'),
        item(dot(border: periodColor), 'Prediksi haid'),
        item(dot(fill: fertileColor.withValues(alpha: 0.2)), 'Masa subur'),
        item(dot(fill: fertileColor), 'Ovulasi'),
      ]),
    );
  }
}
```

- [x] **Step 8: Replace `lib/features/home/home_shell.dart`**

```dart
import 'package:flutter/material.dart';

import '../calendar/calendar_screen.dart';
import '../settings/settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [CalendarScreen(), SettingsScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Kalender'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Pengaturan'),
        ],
      ),
    );
  }
}
```

- [x] **Step 9: Run all tests**

Run: `flutter test`
Expected: PASS — termasuk `auth_flow_test.dart` (HomeShell sekarang merender CalendarScreen).

- [x] **Step 10: Commit**

```powershell
git add lib/features test/features/calendar_logic_test.dart
git commit -m "feat: add calendar with predictions and home navigation"
```

---

### Task 11: `DayLogScreen` (catat haid, gejala, mood, energi, catatan)

**Files:**
- Replace: `lib/features/log/day_log_screen.dart`
- Test: `test/features/day_log_screen_test.dart`

**Interfaces:**
- Consumes: `DayEntry`, enum & label (Task 1), `dateKey` (Task 1), `dayEntriesProvider`, `activeProfileIdProvider`, `authStateProvider`, `dayRepositoryProvider` (Task 8)
- Produces: `DayLogScreen(date: DateTime)` — tombol app bar `'Simpan'`, chip berlabel sesuai `labels.dart`, field `Key('note')`.

- [x] **Step 1: Write the failing test**

```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:siklus/features/log/day_log_screen.dart';
import 'package:siklus/state/providers.dart';

void main() {
  late FakeFirebaseFirestore db;
  late MockFirebaseAuth auth;

  setUpAll(() => initializeDateFormatting('id_ID'));

  setUp(() async {
    auth = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'u1', email: 'a@b.co'));
    db = FakeFirebaseFirestore();
    await db.doc('users/u1').set({'activeProfileId': 'p1'});
    await db.doc('profiles/p1').set({'ownerUid': 'u1', 'memberUids': ['u1'], 'name': 'A'});
  });

  /// Layar awal memantau dayEntriesProvider agar data sudah dimuat sebelum DayLogScreen dibuka.
  Future<void> openLog(WidgetTester tester, {required int expectedEntries}) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        firebaseAuthProvider.overrideWithValue(auth),
        firestoreProvider.overrideWithValue(db),
      ],
      child: MaterialApp(
        home: Consumer(builder: (context, ref, _) {
          final n = ref.watch(dayEntriesProvider).valueOrNull?.length;
          return Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => DayLogScreen(date: DateTime(2026, 10, 15)),
              )),
              child: Text('buka ${n ?? '-'}'),
            ),
          );
        }),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('buka $expectedEntries'));
    await tester.pumpAndSettle();
  }

  testWidgets('saves flow, symptoms, mood, energy and note', (tester) async {
    await openLog(tester, expectedEntries: 0);
    await tester.tap(find.text('Sedang'));
    await tester.tap(find.text('Kram'));
    await tester.ensureVisible(find.text('Cemas'));
    await tester.tap(find.text('Cemas'));
    await tester.ensureVisible(find.text('Lemas'));
    await tester.tap(find.text('Lemas'));
    await tester.ensureVisible(find.byKey(const Key('note')));
    await tester.enterText(find.byKey(const Key('note')), 'perut sakit');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    final data = (await db.doc('profiles/p1/days/2026-10-15').get()).data()!;
    expect(data['flow'], 'medium');
    expect(data['symptoms'], ['cramps']);
    expect(data['moods'], ['anxious']);
    expect(data['energy'], 'low');
    expect(data['note'], 'perut sakit');
    expect(data['updatedBy'], 'u1');
    expect(find.text('buka 1'), findsOneWidget); // kembali ke layar sebelumnya
  });

  testWidgets('prefills existing entry and tapping a selected chip clears it', (tester) async {
    await db.doc('profiles/p1/days/2026-10-15').set({
      'date': '2026-10-15', 'flow': 'heavy', 'symptoms': <String>[], 'moods': <String>[],
      'energy': null, 'note': '', 'updatedBy': 'u1',
    });
    await openLog(tester, expectedEntries: 1);
    final heavy = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Berat'));
    expect(heavy.selected, isTrue);

    await tester.tap(find.text('Berat')); // batalkan pilihan → entri kosong
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect((await db.doc('profiles/p1/days/2026-10-15').get()).exists, isFalse);
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/day_log_screen_test.dart`
Expected: FAIL — teks `'Sedang'` tidak ditemukan (masih placeholder).

- [x] **Step 3: Implement `lib/features/log/day_log_screen.dart`**

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/date_key.dart';
import '../../domain/day_entry.dart';
import '../../domain/labels.dart';
import '../../state/providers.dart';

class DayLogScreen extends ConsumerStatefulWidget {
  const DayLogScreen({super.key, required this.date});
  final DateTime date;

  @override
  ConsumerState<DayLogScreen> createState() => _DayLogScreenState();
}

class _DayLogScreenState extends ConsumerState<DayLogScreen> {
  FlowLevel? _flow;
  final Set<Symptom> _symptoms = {};
  final Set<Mood> _moods = {};
  Energy? _energy;
  final _note = TextEditingController();

  String get _key => dateKey(widget.date);

  @override
  void initState() {
    super.initState();
    final entries = ref.read(dayEntriesProvider).valueOrNull ?? const <DayEntry>[];
    for (final e in entries) {
      if (e.date == _key) {
        _flow = e.flow;
        _symptoms.addAll(e.symptoms);
        _moods.addAll(e.moods);
        _energy = e.energy;
        _note.text = e.note;
        break;
      }
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _save() {
    final profileId = ref.read(activeProfileIdProvider).valueOrNull;
    final user = ref.read(authStateProvider).valueOrNull;
    if (profileId == null || user == null) return;
    final entry = DayEntry(
      date: _key,
      flow: _flow,
      symptoms: {..._symptoms},
      moods: {..._moods},
      energy: _energy,
      note: _note.text.trim(),
    );
    // Tidak di-await: saat offline Future baru selesai setelah sinkron.
    unawaited(ref.read(dayRepositoryProvider).saveDay(profileId: profileId, uid: user.uid, entry: entry));
    Navigator.of(context).pop();
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('EEEE, d MMMM y', 'id_ID').format(widget.date)),
        actions: [TextButton(onPressed: _save, child: const Text('Simpan'))],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          _section('Haid'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final f in FlowLevel.values)
              ChoiceChip(
                label: Text(flowLabels[f]!),
                selected: _flow == f,
                onSelected: (s) => setState(() => _flow = s ? f : null),
              ),
          ]),
          _section('Gejala fisik'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final s in Symptom.values)
              FilterChip(
                label: Text(symptomLabels[s]!),
                selected: _symptoms.contains(s),
                onSelected: (on) => setState(() => on ? _symptoms.add(s) : _symptoms.remove(s)),
              ),
          ]),
          _section('Mood'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final m in Mood.values)
              FilterChip(
                label: Text(moodLabels[m]!),
                selected: _moods.contains(m),
                onSelected: (on) => setState(() => on ? _moods.add(m) : _moods.remove(m)),
              ),
          ]),
          _section('Energi'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final e in Energy.values)
              ChoiceChip(
                label: Text(energyLabels[e]!),
                selected: _energy == e,
                onSelected: (s) => setState(() => _energy = s ? e : null),
              ),
          ]),
          _section('Catatan'),
          TextField(
            key: const Key('note'),
            controller: _note,
            maxLines: 4,
            maxLength: 2000,
            decoration: const InputDecoration(
              hintText: 'Tulis catatan…',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [x] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/day_log_screen_test.dart`
Expected: PASS (2 tests).

- [x] **Step 5: Commit**

```powershell
git add lib/features/log test/features/day_log_screen_test.dart
git commit -m "feat: add daily log screen"
```

---

### Task 12: `SettingsScreen` (undang pasangan, info akun, keluar)

**Files:**
- Replace: `lib/features/settings/settings_screen.dart`
- Test: `test/features/settings_screen_test.dart`

**Interfaces:**
- Consumes: `activeProfileProvider`, `activeProfileIdProvider`, `authStateProvider`, `authRepositoryProvider`, `profileRepositoryProvider` (Task 8), `cycleDisclaimer` (Task 10)
- Produces: `SettingsScreen` dengan tile `'Undang pasangan'` (membuka dialog berisi kode 6 karakter, tombol `'Salin'` & `'Tutup'`) dan `'Keluar'`.

- [x] **Step 1: Write the failing test**

```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/features/settings/settings_screen.dart';
import 'package:siklus/state/providers.dart';

void main() {
  late FakeFirebaseFirestore db;
  late MockFirebaseAuth auth;

  setUp(() async {
    db = FakeFirebaseFirestore();
    auth = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'u1', email: 'a@b.co'));
    await db.doc('users/u1').set({'activeProfileId': 'p1'});
    await db.doc('profiles/p1').set({'ownerUid': 'u1', 'memberUids': ['u1', 'u2'], 'name': 'Sari'});
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        firebaseAuthProvider.overrideWithValue(auth),
        firestoreProvider.overrideWithValue(db),
      ],
      child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('shows profile name and member count', (tester) async {
    await pump(tester);
    expect(find.text('Sari'), findsOneWidget);
    expect(find.text('2 anggota'), findsOneWidget);
  });

  testWidgets('invite creates a code and shows it', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Undang pasangan'));
    await tester.pumpAndSettle();
    final invites = await db.collection('invites').get();
    expect(invites.docs.length, 1);
    final code = invites.docs.single.id;
    expect(invites.docs.single.data()['profileId'], 'p1');
    expect(find.text(code), findsOneWidget);
    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();
    expect(find.text(code), findsNothing);
  });

  testWidgets('sign out clears the user', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    expect(auth.currentUser, isNull);
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/settings_screen_test.dart`
Expected: FAIL — teks `'Sari'` tidak ditemukan.

- [x] **Step 3: Implement `lib/features/settings/settings_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../calendar/prediction_summary.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _invite(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authStateProvider).valueOrNull;
    final profileId = ref.read(activeProfileIdProvider).valueOrNull;
    if (user == null || profileId == null) return;
    try {
      final code = await ref
          .read(profileRepositoryProvider)
          .createInvite(uid: user.uid, profileId: profileId)
          .timeout(const Duration(seconds: 15));
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Kode undangan'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            SelectableText(code, style: Theme.of(dialogContext).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text('Minta pasangan memasukkan kode ini di layar "Mulai". Berlaku 24 jam.'),
          ]),
          actions: [
            TextButton(
              onPressed: () => Clipboard.setData(ClipboardData(text: code)),
              child: const Text('Salin'),
            ),
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Tutup')),
          ],
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuat undangan. Pastikan terhubung ke internet.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(activeProfileProvider).valueOrNull;
    final user = ref.watch(authStateProvider).valueOrNull;
    return SafeArea(
      child: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.favorite),
            title: Text(profile?.name ?? '-'),
            subtitle: Text('${profile?.memberUids.length ?? 0} anggota'),
          ),
          ListTile(
            leading: const Icon(Icons.group_add),
            title: const Text('Undang pasangan'),
            subtitle: const Text('Buat kode undangan (berlaku 24 jam)'),
            onTap: () => _invite(context, ref),
          ),
          const Divider(),
          ListTile(leading: const Icon(Icons.email), title: Text(user?.email ?? '')),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Keluar'),
            onTap: () => ref.read(authRepositoryProvider).signOut(),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(cycleDisclaimer, style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
```

- [x] **Step 4: Run all tests**

Run: `flutter test`
Expected: PASS — seluruh suite hijau.

- [x] **Step 5: Commit**

```powershell
git add lib/features/settings test/features/settings_screen_test.dart
git commit -m "feat: add settings with partner invite and sign out"
```

---

### Task 13: Build APK, distribusi, dan uji end-to-end di 2 HP

**Files:**
- Create: `docs/manual-test.md` (hasil uji manual)

**Interfaces:**
- Consumes: seluruh aplikasi (Task 0–12), rules ter-deploy (Task 7)
- Produces: `build/app/outputs/flutter-apk/app-release.apk`

- [x] **Step 1: Verifikasi statis**

Run: `flutter analyze; flutter test`
Expected: `No issues found!` dan semua test PASS.

- [x] **Step 2: Build APK**

Run: `flutter build apk --release`
Expected: `✓ Built build/app/outputs/flutter-apk/app-release.apk`.
Catatan: tanpa konfigurasi keystore, APK release ditandatangani debug key — cukup untuk sideload pribadi. Simpan proyek di mesin yang sama agar update berikutnya bisa dipasang di atas versi lama.

- [x] **Step 3: Pasang di HP A dan HP B**

Kirim APK (USB / Google Drive / Telegram), aktifkan *Install unknown apps* untuk aplikasi pengirim, pasang.
(Opsional, gratis: Firebase App Distribution → `firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk --app <ANDROID_APP_ID> --testers "a@x.com,b@x.com"`.)

- [x] **Step 4: Jalankan skenario uji manual dan catat di `docs/manual-test.md`**

```markdown
# Uji manual Siklus MVP — 2026-10-15

| # | Skenario | Langkah | Hasil yang diharapkan | OK? |
|---|---|---|---|---|
| 1 | Daftar & buat profil | HP A: Daftar akun → Buat profil "Sari" | Masuk ke Kalender, teks "Catat haid pertama…" | |
| 2 | Catat haid | HP A: Catat hari ini → Sedang → Simpan | Tanggal merah di kalender, ringkasan "Haid berikutnya dalam 28 hari" | |
| 3 | Undang | HP A: Pengaturan → Undang pasangan | Muncul kode 6 karakter | |
| 4 | Gabung | HP B: Daftar → masukkan kode → Gabung | HP B melihat kalender yang sama; HP A "2 anggota" | |
| 5 | Edit bersama | HP B: tambah gejala "Kram" di hari yang sama | Dalam beberapa detik HP A melihat perubahan | |
| 6 | Offline | HP A mode pesawat → catat besok "Ringan" → tutup app → online lagi | Catatan tetap ada saat offline; muncul di HP B setelah online | |
| 7 | Konflik | Kedua HP offline, edit tanggal yang sama berbeda isi → online | Kedua HP akhirnya menampilkan versi yang tersinkron terakhir | |
| 8 | Ganti device | Hapus app di HP A → pasang lagi → Masuk | Semua data kembali | |
| 9 | Kode kedaluwarsa | Pakai kode > 24 jam | Pesan "Kode undangan sudah kedaluwarsa." | |
```

- [x] **Step 5: Commit**

```powershell
git add docs/manual-test.md
git commit -m "docs: record manual end-to-end test results"
```

---

## Fase berikutnya (tidak dikerjakan di plan ini)

Google Sign-In, pengingat lokal, statistik & grafik, keluar/hapus anggota profil, edit default siklus, ekspor CSV/PDF, kunci PIN/biometrik, iOS. Masing-masing dibuat lewat spec + plan terpisah.

## Lampiran: riset opsional dengan REA

Tidak memblokir task mana pun.
- **Euki**: baca repositori sumbernya di GitHub; REA tidak diperlukan untuk kode terbuka.
- **Clue** (APK): siapkan JDK + `jadx-headless-mcp` 0.7.1, set `REA_JADX_MCP_JAR`, lalu minta agent: *"Dengan REA, telusuri taksonomi kategori gejala dan alur layar pencatatan harian di APK Clue ini; tunjukkan evidence."* Gunakan hasilnya hanya sebagai inspirasi desain (jangan menyalin kode/aset/teks).
