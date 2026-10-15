import 'cycle_phase.dart';
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
      if (daysBetween(periods.last.end, today) > 0 && daysBetween(today, fertileStart!) > 0) {
        return CyclePhase.follicular;
      }
    }
    return CyclePhase.luteal;
  }
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
