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
