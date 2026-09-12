import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_finder/prayer/calculation_method.dart';
import 'package:qibla_finder/prayer/hijri.dart';
import 'package:qibla_finder/prayer/prayer_times.dart';
import 'package:qibla_finder/prayer/ramadan.dart';

PrayerTimes _day(DateTime date) => PrayerCalculator(
  method: CalculationMethod.muslimWorldLeague,
  asrMadhab: AsrMadhab.standard,
  highLatitudeRule: HighLatitudeRule.middleOfNight,
).forDate(
  date: date,
  latitude: 19.076,
  longitude: 72.8777,
  utcOffsetHours: 5.5,
  zoneName: 'Asia/Kolkata',
);

void main() {
  final date = DateTime.utc(2026, 2, 20);
  final today = _day(date);
  final tomorrow = _day(DateTime.utc(2026, 2, 21));
  final hijri = HijriDate.fromCivil(date);
  final fajr = today[Prayer.fajr]!;
  final maghrib = today[Prayer.maghrib]!;

  RamadanStatus? at(DateTime now, {bool active = true}) => RamadanStatus.resolve(
    now: now,
    today: today,
    tomorrow: tomorrow,
    active: active,
    hijri: hijri,
  );

  test('before dawn the wait is for suhoor to end at Fajr', () {
    final status = at(fajr.subtract(const Duration(minutes: 30)))!;
    expect(status.milestone, FastMilestone.suhoor);
    expect(status.at, fajr);
    expect(status.prayer, Prayer.fajr);
  });

  test('during the fast the wait is for iftar at Maghrib', () {
    final status = at(fajr.add(const Duration(hours: 1)))!;
    expect(status.milestone, FastMilestone.iftar);
    expect(status.at, maghrib);
    expect(status.prayer, Prayer.maghrib);
  });

  test('after iftar it rolls to the next day\'s suhoor', () {
    final status = at(maghrib.add(const Duration(minutes: 1)))!;
    expect(status.milestone, FastMilestone.suhoor);
    expect(status.at, tomorrow[Prayer.fajr]);
    // The fast this suhoor opens is the following day of the month.
    expect(status.day, hijri.day + 1);
  });

  test('the shown time is the day the countdown actually targets', () {
    // Reading the wall clock off today's schedule after Maghrib shows today's
    // Fajr while counting down to tomorrow's, which is minutes adrift.
    final status = at(maghrib.add(const Duration(minutes: 1)))!;
    expect(status.wallClock, tomorrow.wallClock(Prayer.fajr));
    expect(status.wallClock, isNot(today.wallClock(Prayer.fajr)));

    final beforeDawn = at(fajr.subtract(const Duration(minutes: 30)))!;
    expect(beforeDawn.wallClock, today.wallClock(Prayer.fajr));
    expect(
      at(fajr.add(const Duration(hours: 1)))!.wallClock,
      today.wallClock(Prayer.maghrib),
    );
  });

  test('the milestone flips exactly at Fajr and at Maghrib', () {
    expect(at(fajr)!.milestone, FastMilestone.iftar);
    expect(at(maghrib)!.milestone, FastMilestone.suhoor);
  });

  test('nothing is shown when the mode is off', () {
    expect(at(fajr.add(const Duration(hours: 1)), active: false), isNull);
  });

  test('the day number tracks the Hijri day through Ramadan', () {
    expect(hijri.isRamadan, isTrue);
    expect(at(fajr.add(const Duration(hours: 1)))!.day, hijri.day);
  });
}
