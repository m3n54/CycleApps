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
      for (var i = 0; i < 3; i++) {
        starts.add(addDays(starts.last, 40));
      }
      for (var i = 0; i < 6; i++) {
        starts.add(addDays(starts.last, 28));
      }
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
