import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_finder/data/app_database.dart';
import 'package:qibla_finder/prayer/calculation_method.dart';
import 'package:qibla_finder/prayer/prayer_settings.dart';
import 'package:qibla_finder/prayer/prayer_times.dart';
import 'package:qibla_finder/prayer/reminder_plan.dart';
import 'package:qibla_finder/qibla_controller.dart';

PrayerTimes _day(DateTime date, Map<Prayer, int> offsets) => PrayerCalculator(
  method: CalculationMethod.karachi,
  asrMadhab: AsrMadhab.hanafi,
  highLatitudeRule: HighLatitudeRule.middleOfNight,
  offsets: offsets,
).forDate(
  date: date,
  latitude: 25.5941,
  longitude: 85.1376,
  utcOffsetHours: 5.5,
  zoneName: 'Asia/Kolkata',
);

void main() {
  final date = DateTime.utc(2026, 9, 13);
  final plain = _day(date, const {});

  test('a correction moves only the prayer it names', () {
    final shifted = _day(date, const {Prayer.asr: 3});
    expect(
      shifted[Prayer.asr]!.difference(plain[Prayer.asr]!),
      const Duration(minutes: 3),
    );
    for (final other in Prayer.values.where((p) => p != Prayer.asr)) {
      expect(shifted[other], plain[other], reason: '$other moved');
    }
  });

  test('corrections work in both directions', () {
    final shifted = _day(date, const {Prayer.fajr: -4, Prayer.isha: 6});
    expect(
      plain[Prayer.fajr]!.difference(shifted[Prayer.fajr]!),
      const Duration(minutes: 4),
    );
    expect(
      shifted[Prayer.isha]!.difference(plain[Prayer.isha]!),
      const Duration(minutes: 6),
    );
  });

  test('the wall clock reflects the correction', () {
    final shifted = _day(date, const {Prayer.maghrib: 5});
    expect(
      shifted.wallClock(Prayer.maghrib)!.difference(
        plain.wallClock(Prayer.maghrib)!,
      ),
      const Duration(minutes: 5),
    );
  });

  test('reminders fire at the adjusted time, not the calculated one', () {
    // A correction the alarms ignored would be worse than no correction.
    final now = DateTime.utc(2026, 9, 12, 20, 0);
    List<ReminderEntry> plan(Map<Prayer, int> offsets) => buildReminderPlan(
      now: now,
      zoneName: 'Asia/Kolkata',
      calculate: (d) => _day(d, offsets),
      enabled: (p) => p.isPrayer,
      days: 1,
    );
    final before = plan(const {}).firstWhere((e) => e.prayer == Prayer.dhuhr);
    final after = plan(
      const {Prayer.dhuhr: 7},
    ).firstWhere((e) => e.prayer == Prayer.dhuhr);
    expect(after.at.difference(before.at), const Duration(minutes: 7));
  });

  test('settings clamp a correction to the offered range', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final settings = await PrayerSettings.load(db);
    settings.setOffset(Prayer.fajr, 999);
    expect(settings.offsetFor(Prayer.fajr), PrayerSettings.maxOffset);
    settings.setOffset(Prayer.fajr, -999);
    expect(settings.offsetFor(Prayer.fajr), -PrayerSettings.maxOffset);
    expect(settings.hasOffsets, isTrue);
    settings.clearOffsets();
    expect(settings.hasOffsets, isFalse);
    expect(settings.offsetFor(Prayer.fajr), 0);
    await settings.flushed;
    settings.dispose();
    await db.close();
  });

  test('a correction survives a restart and reaches the schedule', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final first = await PrayerSettings.load(db);
    first.setOffset(Prayer.asr, -2);
    await first.flushed;
    first.dispose();

    final second = await PrayerSettings.load(db);
    expect(second.offsetFor(Prayer.asr), -2);

    final controller = QiblaController(
      settings: second,
      database: db,
      clock: () => DateTime.utc(2026, 9, 13, 6, 0),
      syncOverride: () async {},
    );
    await controller.selectLocation(
      label: 'Patna',
      latitude: 25.5941,
      longitude: 85.1376,
      country: 'IN',
    );
    final shown = controller.prayerTimes![Prayer.asr]!;
    final unshifted = _day(
      controller.prayerTimes!.date,
      const {},
    )[Prayer.asr]!;
    expect(unshifted.difference(shown), const Duration(minutes: 2));

    controller.dispose();
    await second.flushed;
    second.dispose();
    await db.close();
  });
}
