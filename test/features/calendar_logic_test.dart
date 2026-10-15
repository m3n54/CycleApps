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
