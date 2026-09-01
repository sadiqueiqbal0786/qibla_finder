import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_finder/data/app_database.dart';
import 'package:qibla_finder/prayer/calculation_method.dart';
import 'package:qibla_finder/prayer/prayer_settings.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('preferences', () {
    test('round-trip and overwrite', () async {
      await db.putPreference('a', '1');
      await db.putPreference('b', 'two');
      expect(await db.loadPreferences(), {'a': '1', 'b': 'two'});

      await db.putPreference('a', '9');
      expect((await db.loadPreferences())['a'], '9');
    });
  });

  group('settings persistence', () {
    test('survives a reload from the same database', () async {
      final first = await PrayerSettings.load(db);
      expect(first.autoMethod, isTrue);

      first.setMethod(CalculationMethod.karachi);
      first.setAsrMadhab(AsrMadhab.hanafi);
      first.setAdhanMode(AdhanMode.notificationOnly);
      first.setHighLatitudeRule(HighLatitudeRule.seventhOfNight);
      // Writes are fire-and-forget; let them land.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final second = await PrayerSettings.load(db);
      expect(second.method.id, 'karachi');
      expect(second.asrMadhab, AsrMadhab.hanafi);
      expect(second.adhanMode, AdhanMode.notificationOnly);
      expect(second.highLatitudeRule, HighLatitudeRule.seventhOfNight);
      // A manual choice must not be silently reverted by auto-detection.
      expect(second.autoMethod, isFalse);
      expect(second.autoAsr, isFalse);
    });

    test('a stored adhan preference falls back while it is hidden', () async {
      // Written directly, as if saved by a build where adhan was offered.
      await db.putPreference('prayer.adhan_mode', AdhanMode.adhan.name);
      final settings = await PrayerSettings.load(db);
      // Must not leave the user on a reminder that makes no sound.
      expect(settings.adhanMode, AdhanMode.notificationOnly);
    });

    test('automatic detection does not override a manual choice', () async {
      final settings = await PrayerSettings.load(db);
      settings.setMethod(CalculationMethod.egyptian);
      settings.applyRegionalDefaults('PK');
      expect(settings.method.id, 'egyptian');
    });

    test('automatic detection applies when untouched', () async {
      final settings = await PrayerSettings.load(db);
      settings.applyRegionalDefaults('PK');
      expect(settings.method.id, 'karachi');
      expect(settings.asrMadhab, AsrMadhab.hanafi);
    });
  });

  group('saved locations', () {
    test('stores and deletes pinned places', () async {
      final id = await db.saveLocation(
        label: 'Makkah',
        latitude: 21.4225,
        longitude: 39.8262,
        isoCountryCode: 'SA',
        utcOffsetHours: 3,
      );
      final all = await db.allSavedLocations();
      expect(all, hasLength(1));
      expect(all.single.label, 'Makkah');
      expect(all.single.utcOffsetHours, 3);

      await db.deleteSavedLocation(id);
      expect(await db.allSavedLocations(), isEmpty);
    });

    test('keeps exactly one current-location row', () async {
      await db.rememberCurrentLocation(
          label: 'Seattle', latitude: 47.6, longitude: -122.3);
      await db.rememberCurrentLocation(
          label: 'London', latitude: 51.5, longitude: -0.12);

      final current = await db.lastKnownLocation();
      expect(current, isNotNull);
      expect(current!.label, 'London');
      final all = await db.allSavedLocations();
      expect(all.where((l) => l.isCurrent), hasLength(1));
    });
  });

  group('prayer log', () {
    test('marking is idempotent per day and prayer', () async {
      final day = DateTime(2026, 9, 1, 13, 45);
      await db.markPrayer(day, 'fajr');
      await db.markPrayer(day, 'fajr');
      await db.markPrayer(day, 'asr');

      final marked = await db.watchMarkedFor(day).first;
      expect(marked, {'fajr', 'asr'});

      await db.unmarkPrayer(day, 'fajr');
      expect(await db.watchMarkedFor(day).first, {'asr'});
    });

    test('different days are independent', () async {
      await db.markPrayer(DateTime(2026, 9, 1), 'fajr');
      await db.markPrayer(DateTime(2026, 9, 2), 'isha');
      expect(await db.watchMarkedFor(DateTime(2026, 9, 1)).first, {'fajr'});
      expect(await db.watchMarkedFor(DateTime(2026, 9, 2)).first, {'isha'});
    });
  });
}
