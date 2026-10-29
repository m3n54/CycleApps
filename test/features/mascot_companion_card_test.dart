import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/domain/cycle_mascot.dart';
import 'package:siklus/domain/cycle_phase.dart';
import 'package:siklus/domain/day_entry.dart';
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

  testWidgets('MascotCompanionCard renders in dark theme and supports partner mode with different characters', (tester) async {
    MascotCharacter? selected;

    await tester.pumpWidget(
      MaterialApp(
        theme: CycleTheme.darkTheme,
        home: Scaffold(
          body: MascotCompanionCard(
            character: MascotCharacter.babyDino,
            phase: CyclePhase.luteal,
            todayEntry: const DayEntry(
              date: '2026-10-29',
              moods: {Mood.sensitive},
            ),
            isPartner: true,
            partnerName: 'Siti',
            onSelectMascot: (next) => selected = next,
          ),
        ),
      ),
    );

    expect(find.textContaining('Baby Dino'), findsOneWidget);
    expect(find.textContaining('Mode Manja'), findsOneWidget);

    final quotes = CycleMascotAdvisor.bubbleMessages(
      character: MascotCharacter.babyDino,
      state: MascotMoodState.cravingPouty,
      isPartner: true,
      partnerName: 'Siti',
    );
    expect(find.text(quotes[0]), findsOneWidget);

    // Open mascot picker and select Chibi Girl
    await tester.tap(find.byKey(const Key('changeMascotButton')));
    await tester.pumpAndSettle();

    expect(find.text('Chibi Girl'), findsOneWidget);
    await tester.tap(find.text('Chibi Girl'));
    await tester.pumpAndSettle();

    expect(selected, MascotCharacter.chibiGirl);
  });

  testWidgets('MascotCompanionCard renders without overflow on 320px mobile viewport', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        theme: CycleTheme.lightTheme,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: MascotCompanionCard(
              character: MascotCharacter.mochiKitten,
              phase: CyclePhase.menstrual,
              todayEntry: null,
              isPartner: false,
              partnerName: 'Nata',
              onSelectMascot: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(MascotCompanionCard), findsOneWidget);
  });
}
