import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_finder/prayer/hijri.dart';

void main() {
  test('matches the tabular calendar at known dates', () {
    // Ramadan starts, checked against the arithmetic calendar. Announced
    // starts track these within a day; that is why the mode is overridable.
    expect(HijriDate.fromCivil(DateTime.utc(2024, 3, 11)), const HijriDate(1445, 9, 1));
    expect(HijriDate.fromCivil(DateTime.utc(2025, 3, 1)), const HijriDate(1446, 9, 1));
    expect(HijriDate.fromCivil(DateTime.utc(2026, 2, 18)), const HijriDate(1447, 9, 1));
    // A reference value away from Ramadan.
    expect(HijriDate.fromCivil(DateTime.utc(2000, 1, 1)), const HijriDate(1420, 9, 24));
  });

  test('flags Ramadan only inside the ninth month', () {
    expect(HijriDate.fromCivil(DateTime.utc(2026, 2, 17)).isRamadan, isFalse);
    expect(HijriDate.fromCivil(DateTime.utc(2026, 2, 18)).isRamadan, isTrue);
    expect(HijriDate.fromCivil(DateTime.utc(2026, 3, 19)).isRamadan, isTrue);
    expect(HijriDate.fromCivil(DateTime.utc(2026, 3, 20)).isRamadan, isFalse);
  });

  test('advances one Hijri day per civil day across a month boundary', () {
    var previous = HijriDate.fromCivil(DateTime.utc(2026, 2, 10));
    for (var i = 1; i <= 60; i++) {
      final current = HijriDate.fromCivil(DateTime.utc(2026, 2, 10 + i));
      final rolled = current.day == 1 && previous.day >= 29;
      expect(
        rolled || current.day == previous.day + 1,
        isTrue,
        reason: 'went from $previous to $current',
      );
      previous = current;
    }
  });

  test('every day of a Ramadan is numbered 1 to 29 or 30', () {
    final days = <int>[];
    for (var i = 0; i < 40; i++) {
      final date = HijriDate.fromCivil(DateTime.utc(2026, 2, 18 + i));
      if (date.isRamadan) days.add(date.day);
    }
    expect(days.first, 1);
    expect(days.length, anyOf(29, 30));
    expect(days, List<int>.generate(days.length, (i) => i + 1));
  });
}
