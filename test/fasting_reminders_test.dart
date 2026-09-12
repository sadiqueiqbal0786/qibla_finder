import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_finder/prayer/calculation_method.dart';
import 'package:qibla_finder/prayer/prayer_times.dart';
import 'package:qibla_finder/prayer/reminder_plan.dart';

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
  List<ReminderEntry> plan({
    required DateTime now,
    bool fasting = true,
    int suhoor = 30,
    int shift = 0,
    int days = 3,
    int advance = 0,
  }) => buildReminderPlan(
    now: now,
    zoneName: 'Asia/Kolkata',
    calculate: _day,
    enabled: (p) => p.isPrayer,
    days: days,
    advanceMinutes: advance,
    fastingReminders: fasting,
    suhoorAdvanceMinutes: suhoor,
    hijriDayShift: shift,
  );

  // 20 Feb 2026 is inside Ramadan 1447; 12 Sep 2026 is not.
  final inRamadan = DateTime.utc(2026, 2, 19, 20, 0);
  final outside = DateTime.utc(2026, 9, 12, 20, 0);

  test('adds a suhoor and an iftar reminder on each Ramadan day', () {
    final entries = plan(now: inRamadan, days: 1);
    expect(
      entries.where((e) => e.kind == ReminderKind.suhoor),
      hasLength(1),
    );
    expect(entries.where((e) => e.kind == ReminderKind.iftar), hasLength(1));
  });

  test('schedules none outside Ramadan', () {
    final entries = plan(now: outside);
    expect(entries.any((e) => e.kind != ReminderKind.prayer), isFalse);
    // The ordinary prayer reminders are untouched.
    expect(entries.where((e) => e.kind == ReminderKind.prayer), isNotEmpty);
  });

  test('schedules none when the user turns them off', () {
    final entries = plan(now: inRamadan, fasting: false);
    expect(entries.any((e) => e.kind != ReminderKind.prayer), isFalse);
  });

  test('suhoor lands the chosen number of minutes before Fajr', () {
    final entries = plan(now: inRamadan, suhoor: 45, days: 1);
    final suhoor = entries.firstWhere((e) => e.kind == ReminderKind.suhoor);
    final fajr = entries.firstWhere(
      (e) => e.kind == ReminderKind.prayer && e.prayer == Prayer.fajr,
    );
    expect(fajr.at.difference(suhoor.at), const Duration(minutes: 45));
    expect(suhoor.advance, 45);
  });

  test('iftar replaces the Maghrib reminder rather than doubling it', () {
    final entries = plan(now: inRamadan, days: 1);
    final iftar = entries.firstWhere((e) => e.kind == ReminderKind.iftar);
    expect(iftar.advance, 0);
    // Nothing else fires at sunset, so the user gets one notification.
    expect(entries.where((e) => e.at == iftar.at), hasLength(1));
  });

  test('a suhoor warning at Fajr replaces the Fajr reminder', () {
    final entries = plan(now: inRamadan, suhoor: 0, days: 1);
    final suhoor = entries.firstWhere((e) => e.kind == ReminderKind.suhoor);
    expect(entries.where((e) => e.at == suhoor.at), hasLength(1));
  });

  test('a suhoor warning before Fajr leaves the Fajr reminder alone', () {
    final entries = plan(now: inRamadan, suhoor: 30, days: 1);
    expect(
      entries.any(
        (e) => e.kind == ReminderKind.prayer && e.prayer == Prayer.fajr,
      ),
      isTrue,
    );
  });

  test('outside Ramadan every prayer reminder survives', () {
    final entries = plan(now: outside, days: 1);
    expect(
      entries.where((e) => e.prayer == Prayer.maghrib),
      hasLength(1),
    );
  });

  test('ids never collide, including with the advance warnings', () {
    final entries = plan(now: inRamadan, advance: 10, days: 3);
    final ids = entries.map((e) => e.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('the day shift moves which days get fasting reminders', () {
    // 17 Feb 2026 is the eve of the calculated Ramadan, so it only counts for
    // someone whose mosque started a day early. Stand before that morning's
    // Fajr, or the suhoor warning is legitimately in the past.
    final eve = DateTime.utc(2026, 2, 16, 20, 0);
    expect(
      plan(now: eve, days: 1).any((e) => e.kind != ReminderKind.prayer),
      isFalse,
    );
    expect(
      plan(now: eve, days: 1, shift: 1).any((e) => e.kind == ReminderKind.suhoor),
      isTrue,
    );
  });

  test('a suhoor time already past is not scheduled', () {
    final times = _day(DateTime.utc(2026, 2, 20));
    final afterFajr = times[Prayer.fajr]!.add(const Duration(minutes: 1));
    final entries = plan(now: afterFajr, days: 1);
    expect(
      entries.any(
        (e) => e.kind == ReminderKind.suhoor && e.at.isBefore(afterFajr),
      ),
      isFalse,
    );
  });
}
