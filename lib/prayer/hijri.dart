

/// A Hijri date from the tabular Islamic calendar.
///
/// The tabular calendar is arithmetic, so it is deterministic and needs no
/// network. It is *not* authoritative: the start of a Hijri month depends on
/// a local moon sighting, and announced dates commonly differ from the
/// arithmetic date by a day either way, and differ between countries on the
/// same day. Everything built on this must stay correctable by the user and
/// must never be presented as a ruling.
class HijriDate {
  const HijriDate(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;

  static const int ramadan = 9;
  static const int shawwal = 10;

  bool get isRamadan => month == ramadan;

  /// Converts a civil date, which must already be the calendar day in the
  /// prayer location's zone rather than the device's.
  factory HijriDate.fromCivil(DateTime date) =>
      _fromJulianDay(_julianDay(date.year, date.month, date.day));

  /// Gregorian calendar date to Julian Day Number.
  static int _julianDay(int year, int month, int day) {
    final a = (14 - month) ~/ 12;
    final y = year + 4800 - a;
    final m = month + 12 * a - 3;
    return day +
        (153 * m + 2) ~/ 5 +
        365 * y +
        y ~/ 4 -
        y ~/ 100 +
        y ~/ 400 -
        32045;
  }

  /// Julian Day Number to the tabular Islamic calendar, civil epoch.
  static HijriDate _fromJulianDay(int jdn) {
    var l = jdn - 1948440 + 10632;
    final n = (l - 1) ~/ 10631;
    l = l - 10631 * n + 354;
    final j = ((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719) +
        (l ~/ 5670) * ((43 * l) ~/ 15238);
    l = l -
        ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
        (j ~/ 16) * ((15238 * j) ~/ 43) +
        29;
    final month = (24 * l) ~/ 709;
    final day = l - (709 * month) ~/ 24;
    return HijriDate(30 * n + j - 30, month, day);
  }

  @override
  String toString() => '$day/$month/$year';

  @override
  bool operator ==(Object other) =>
      other is HijriDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);
}
