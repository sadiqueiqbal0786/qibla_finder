import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_finder/data/app_database.dart';
import 'package:qibla_finder/prayer/calculation_method.dart';
import 'package:qibla_finder/prayer/prayer_settings.dart';
import 'package:qibla_finder/prayer/prayer_times.dart';
import 'package:qibla_finder/prayer/reminder_plan.dart';
import 'package:qibla_finder/services/alignment_tracker.dart';
import 'package:qibla_finder/qibla_controller.dart';
import 'package:qibla_finder/services/refresh_lease.dart';
import 'package:qibla_finder/services/timezone_resolver.dart';

void main() {
  test('Controller rolls Friday labels at location midnight', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final settings = await PrayerSettings.load(db);
    var now = DateTime.utc(2026, 9, 10, 18, 29);
    final controller = QiblaController(settings: settings, database: db,
      clock: () => now, syncOverride: () async {});
    await controller.selectLocation(label: 'Mumbai', latitude: 19.076,
      longitude: 72.8777, country: 'IN');
    expect(controller.prayerTimes!.date.day, 10);
    now = now.add(const Duration(minutes: 2));
    controller.refreshPrayerTimesIfStale();
    expect(controller.prayerTimes!.date.day, 11);
    expect(controller.prayerTimes!.labelFor(Prayer.dhuhr), 'Jumma / Dhuhr');
    controller.dispose(); await settings.flushed; settings.dispose(); await db.close();
  });

  test('Location date rolls into Friday independently of device date', () {
    expect(
      TimezoneResolver.calendarDay(
        DateTime.utc(2026, 9, 10, 20),
        'Asia/Kolkata',
      ),
      DateTime.utc(2026, 9, 11),
    );
    expect(
      TimezoneResolver.calendarDay(
        DateTime.utc(2026, 9, 11, 2),
        'America/New_York',
      ),
      DateTime.utc(2026, 9, 10),
    );
  });
  test(
    'Alignment needs stable accurate readings and exits on confidence loss',
    () {
      final tracker = AlignmentTracker();
      final now = DateTime.utc(2026);
      expect(tracker.update(now: now, delta: 1, reliable: false), isFalse);
      expect(tracker.update(now: now, delta: 1, reliable: true), isFalse);
      expect(
        tracker.update(
          now: now.add(const Duration(seconds: 1)),
          delta: 2,
          reliable: true,
        ),
        isTrue,
      );
      expect(
        tracker.update(
          now: now.add(const Duration(seconds: 2)),
          delta: 6,
          reliable: true,
        ),
        isTrue,
      );
      expect(
        tracker.update(
          now: now.add(const Duration(seconds: 3)),
          delta: 1,
          reliable: false,
        ),
        isFalse,
      );
    },
  );
  test(
    'Reminder renewal preserves IDs, filters muted prayers and crosses DST',
    () {
      final resolver = TimezoneResolver();
      final calculator = PrayerCalculator(
        method: CalculationMethod.isna,
        asrMadhab: AsrMadhab.standard,
      );
      PrayerTimes calculate(DateTime day) {
        final zone = resolver.resolve(
          latitude: 40.7128,
          longitude: -74.006,
          date: day,
        )!;
        return calculator.forDate(
          date: day,
          latitude: 40.7128,
          longitude: -74.006,
          utcOffsetHours: zone.offsetHours,
          zoneName: zone.name,
        );
      }

      final start = DateTime.utc(2026, 10, 30);
      List<ReminderEntry> plan(DateTime now) => buildReminderPlan(
        now: now,
        zoneName: 'America/New_York',
        calculate: calculate,
        enabled: (p) => p == Prayer.fajr,
        days: 7,
        advanceMinutes: 10,
      );
      final first = plan(start);
      final second = plan(start.add(const Duration(days: 1)));
      expect(
        first.every((e) => e.prayer == Prayer.fajr && e.at.isAfter(start)),
        isTrue,
      );
      for (final entry in first.where(
        (e) => e.at.isAfter(start.add(const Duration(days: 1))),
      )) {
        final replacement = second.singleWhere((e) => e.id == entry.id);
        expect(replacement.at, entry.at);
      }
      final dawn = first.where((e) => e.advance == 0).first;
      expect(
        first.singleWhere((e) => e.id == dawn.id + 1).at,
        dawn.at.subtract(const Duration(minutes: 10)),
      );
      expect(first.map((e) => e.id).toSet().length, first.length);
    },
  );
  test(
    'Regional reset, appearance, language and reminder choices survive reload',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final settings = await PrayerSettings.load(db);
      settings.applyRegionalDefaults('IN');
      settings.setMethod(CalculationMethod.egyptian);
      settings.setAsrMadhab(AsrMadhab.standard);
      settings.resetToAutomatic();
      expect(settings.method, CalculationMethod.karachi);
      expect(settings.asrMadhab, AsrMadhab.hanafi);
      settings.setTheme('dark');
      settings.setLanguage('ur');
      settings.setAdvanceMinutes(15);
      settings.setPrayerEnabled(Prayer.isha, false);
      await settings.flushed;
      final loaded = await PrayerSettings.load(db);
      expect(loaded.theme, 'dark');
      expect(loaded.language, 'ur');
      expect(loaded.advanceMinutes, 15);
      expect(loaded.prayerEnabled(Prayer.isha), isFalse);
      expect(loaded.prayerEnabled(Prayer.fajr), isTrue);
      settings.dispose();
      loaded.dispose();
      await db.close();
    },
  );
  test(
    'Database lease serializes refreshes and releases after failure',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final entered = Completer<void>();
      final release = Completer<void>();
      final events = <int>[];
      final first = withRefreshLease(db, () async {
        events.add(1);
        entered.complete();
        await release.future;
        events.add(2);
      });
      await entered.future;
      final second = withRefreshLease(db, () async {
        events.add(3);
      });
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(events, [1]);
      release.complete();
      await Future.wait([first, second]);
      expect(events, [1, 2, 3]);
      await expectLater(
        withRefreshLease(db, () async => throw StateError('test')),
        throwsStateError,
      );
      expect(await withRefreshLease(db, () async => 42), 42);
      await db.close();
    },
  );
}
