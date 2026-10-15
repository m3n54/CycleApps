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
