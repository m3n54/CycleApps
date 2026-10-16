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

    expect(find.text('Rata-rata Durasi Haid'), findsOneWidget);
    expect(find.text('Total Siklus Tercatat'), findsOneWidget);
    expect(find.text('1 siklus'), findsOneWidget);
    expect(find.text('Kram'), findsOneWidget);
    expect(find.text('Fase Menstruasi'), findsOneWidget);
    expect(find.text('Fase Folikular'), findsOneWidget);
    expect(find.text('Fase Ovulasi'), findsOneWidget);
    expect(find.text('Fase Luteal'), findsOneWidget);
  });

  testWidgets('InsightsScreen shows empty symptom message when no symptoms logged', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayProvider.overrideWithValue(DateTime(2026, 10, 15)),
          dayEntriesProvider.overrideWith((ref) => Stream.value(const <DayEntry>[])),
        ],
        child: const MaterialApp(home: InsightsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Belum ada gejala yang tercatat'), findsOneWidget);
    expect(find.text('0 siklus'), findsOneWidget);
  });
}
