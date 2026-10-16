import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/domain/cycle_profile.dart';
import 'package:siklus/domain/day_entry.dart';
import 'package:siklus/features/home/home_screen.dart';
import 'package:siklus/features/insights/insights_screen.dart';
import 'package:siklus/features/settings/settings_screen.dart';
import 'package:siklus/state/providers.dart';
import 'package:siklus/theme/cycle_theme.dart';

void main() {
  Widget wrapWithNarrowViewport(Widget child, {double width = 100}) {
    return ProviderScope(
      overrides: [
        todayProvider.overrideWithValue(DateTime(2026, 10, 16)),
        activeProfileProvider.overrideWith(
          (_) => Stream.value(
            const CycleProfile(
              id: 'p1',
              ownerUid: 'u1',
              memberUids: ['u1'],
              name: 'Nata',
              defaultCycleLength: 28,
              defaultPeriodLength: 5,
            ),
          ),
        ),
        dayEntriesProvider.overrideWith(
          (_) => Stream.value([
            const DayEntry(
              date: '2026-10-16',
              flow: FlowLevel.medium,
              symptoms: {Symptom.cramps, Symptom.headache},
              moods: {Mood.happy, Mood.calm},
              energy: Energy.medium,
              cervicalMucus: CervicalMucus.creamy,
              sexualActivity: SexualActivity.protected,
              note: 'Catatan hari ini',
            ),
          ]),
        ),
      ],
      child: MaterialApp(
        theme: CycleTheme.lightTheme,
        home: Center(
          child: SizedBox(
            width: width,
            height: 600,
            child: child,
          ),
        ),
      ),
    );
  }

  testWidgets('SettingsScreen does not throw ListTile width or overflow error on narrow viewport',
      (tester) async {
    await tester.pumpWidget(wrapWithNarrowViewport(const SettingsScreen(), width: 90));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('HomeScreen does not overflow on narrow viewport', (tester) async {
    await tester.pumpWidget(wrapWithNarrowViewport(const HomeScreen(), width: 100));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('InsightsScreen does not overflow on narrow viewport', (tester) async {
    await tester.pumpWidget(wrapWithNarrowViewport(const InsightsScreen(), width: 120));
    await tester.pumpAndSettle();
    expect(find.byType(InsightsScreen), findsOneWidget);
  });
}
