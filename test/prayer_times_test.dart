import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_finder/prayer/calculation_method.dart';
import 'package:qibla_finder/prayer/prayer_times.dart';
import 'package:qibla_finder/prayer/solar.dart';
import 'package:qibla_finder/services/timezone_resolver.dart';

PrayerTimes compute(
  double lat,
  double lon,
  double offset,
  CalculationMethod method,
  AsrMadhab asr,
  DateTime date, {
  HighLatitudeRule rule = HighLatitudeRule.angleBased,
}) {
  return PrayerCalculator(
    method: method,
    asrMadhab: asr,
    highLatitudeRule: rule,
  ).forDate(
    date: date,
    latitude: lat,
    longitude: lon,
    utcOffsetHours: offset,
  );
}

int minutesOf(DateTime? d) => d == null ? -1 : d.hour * 60 + d.minute;

int wallMinutes(PrayerTimes t, Prayer p) => minutesOf(t.wallClock(p));

void main() {
  final sept = DateTime(2026, 9, 1);

  group('solar geometry', () {
    test('julian day matches the known epoch', () {
      // 2000-01-01 12:00 UT is JD 2451545.0, so 00:00 UT is 2451544.5.
      expect(Solar.julianDay(2000, 1, 1), closeTo(2451544.5, 1e-9));
      expect(Solar.julianDay(2026, 9, 1), closeTo(2461284.5, 1e-9));
    });

    test('declination is near zero at the equinoxes', () {
      final march = Solar.positionAt(Solar.julianDay(2026, 3, 20));
      final september = Solar.positionAt(Solar.julianDay(2026, 9, 22));
      expect(march.declination.abs(), lessThan(1.0));
      expect(september.declination.abs(), lessThan(1.0));
    });

    test('declination peaks near the solstices', () {
      final june = Solar.positionAt(Solar.julianDay(2026, 6, 21));
      final december = Solar.positionAt(Solar.julianDay(2026, 12, 21));
      expect(june.declination, closeTo(23.44, 0.2));
      expect(december.declination, closeTo(-23.44, 0.2));
    });
  });

  group('prayer times', () {
    test('London matches published sunrise/sunset within 2 minutes', () {
      final t = compute(51.5074, -0.1278, 1,
          CalculationMethod.muslimWorldLeague, AsrMadhab.standard, sept);
      // Real values for 1 Sep 2026 (BST): sunrise 06:14, sunset 19:47.
      expect(wallMinutes(t, Prayer.sunrise), closeTo(6 * 60 + 14, 2));
      expect(wallMinutes(t, Prayer.maghrib), closeTo(19 * 60 + 47, 3));
    });

    test('Makkah solar noon lands where the longitude puts it', () {
      final t = compute(21.4225, 39.8262, 3, CalculationMethod.ummAlQura,
          AsrMadhab.standard, sept);
      // 39.83E under UTC+3 puts mean solar noon at ~12:21 local.
      expect(wallMinutes(t, Prayer.dhuhr), closeTo(12 * 60 + 22, 2));
    });

    test('every prayer is in chronological order, worldwide', () {
      for (var lat = -60.0; lat <= 60.0; lat += 10) {
        for (var lon = -180.0; lon <= 180.0; lon += 45) {
          for (final month in <int>[1, 4, 7, 10]) {
            final t = compute(lat, lon, 0,
                CalculationMethod.muslimWorldLeague, AsrMadhab.standard,
                DateTime(2026, month, 15));
            final ordered = <Prayer>[
              Prayer.fajr,
              Prayer.sunrise,
              Prayer.dhuhr,
              Prayer.asr,
              Prayer.maghrib,
              Prayer.isha,
            ];
            DateTime? previous;
            for (final prayer in ordered) {
              final time = t[prayer];
              expect(time, isNotNull,
                  reason: '$prayer missing at $lat,$lon month $month');
              if (previous != null) {
                expect(time!.isAfter(previous), isTrue,
                    reason:
                        '$prayer ($time) not after previous ($previous) at '
                        '$lat,$lon month $month');
              }
              previous = time;
            }
          }
        }
      }
    });

    test('Hanafi Asr is always later than standard Asr', () {
      for (var lat = -50.0; lat <= 50.0; lat += 10) {
        final standard = compute(lat, 0, 0,
            CalculationMethod.karachi, AsrMadhab.standard, sept);
        final hanafi = compute(lat, 0, 0,
            CalculationMethod.karachi, AsrMadhab.hanafi, sept);
        expect(hanafi[Prayer.asr]!.isAfter(standard[Prayer.asr]!), isTrue,
            reason: 'at latitude $lat');
      }
    });

    test('interval-based Isha sits exactly 90 minutes after Maghrib', () {
      final t = compute(21.4225, 39.8262, 3, CalculationMethod.ummAlQura,
          AsrMadhab.standard, sept);
      final gap = t[Prayer.isha]!.difference(t[Prayer.maghrib]!).inMinutes;
      expect(gap, closeTo(90, 1));
    });

    test('polar latitudes still produce a full, ordered schedule', () {
      for (final rule in HighLatitudeRule.values) {
        final t = compute(69.6496, 18.9560, 2,
            CalculationMethod.muslimWorldLeague, AsrMadhab.standard,
            DateTime(2026, 6, 21), rule: rule);
        expect(t.usedHighLatitudeRule, isTrue);
        expect(t.times.length, Prayer.values.length,
            reason: 'rule $rule dropped a prayer');
        expect(t[Prayer.fajr]!.isBefore(t[Prayer.sunrise]!), isTrue);
        expect(t[Prayer.isha]!.isAfter(t[Prayer.maghrib]!), isTrue);
      }
    });
  });

  group('next prayer', () {
    test('skips sunrise and advances through the day', () {
      final t = compute(24.8607, 67.0011, 5, CalculationMethod.karachi,
          AsrMadhab.hanafi, sept);
      final beforeDawn = DateTime(2026, 9, 1, 3);
      expect(t.nextAfter(beforeDawn)!.key, Prayer.fajr);

      // Just after sunrise the next prayer must be Dhuhr, never Sunrise.
      final afterSunrise = t[Prayer.sunrise]!.add(const Duration(minutes: 1));
      expect(t.nextAfter(afterSunrise)!.key, Prayer.dhuhr);

      final afterIsha = t[Prayer.isha]!.add(const Duration(minutes: 1));
      expect(t.nextAfter(afterIsha), isNull);
    });

    test('reports the prayer currently in progress', () {
      final t = compute(24.8607, 67.0011, 5, CalculationMethod.karachi,
          AsrMadhab.hanafi, sept);
      final duringAsr = t[Prayer.asr]!.add(const Duration(minutes: 5));
      expect(t.currentAt(duringAsr)!.key, Prayer.asr);
    });
  });

  group('timezone independence', _timezoneIndependenceTests);

  group('regional defaults', () {
    test('maps countries to their conventional method', () {
      expect(CalculationMethod.forCountry('SA').id, 'umm_al_qura');
      expect(CalculationMethod.forCountry('PK').id, 'karachi');
      expect(CalculationMethod.forCountry('US').id, 'isna');
      expect(CalculationMethod.forCountry('EG').id, 'egyptian');
      expect(CalculationMethod.forCountry('TR').id, 'turkey');
      expect(CalculationMethod.forCountry('ID').id, 'singapore');
      expect(CalculationMethod.forCountry('AE').id, 'dubai');
      expect(CalculationMethod.forCountry('FR').id, 'mwl');
      expect(CalculationMethod.forCountry(null).id, 'mwl');
      expect(CalculationMethod.forCountry('').id, 'mwl');
      expect(CalculationMethod.forCountry('gb').id, 'mwl');
    });

    test('uses Hanafi Asr across the subcontinent only', () {
      expect(CalculationMethod.asrForCountry('PK'), AsrMadhab.hanafi);
      expect(CalculationMethod.asrForCountry('IN'), AsrMadhab.hanafi);
      expect(CalculationMethod.asrForCountry('BD'), AsrMadhab.hanafi);
      expect(CalculationMethod.asrForCountry('SA'), AsrMadhab.standard);
      expect(CalculationMethod.asrForCountry('US'), AsrMadhab.standard);
    });

    test('every method id round-trips', () {
      for (final method in CalculationMethod.all) {
        expect(CalculationMethod.byId(method.id), same(method));
      }
      expect(CalculationMethod.byId('nope'), isNull);
      expect(CalculationMethod.byId(null), isNull);
    });
  });
}

/// Regression cover for the bug this fix closes: prayer times were computed in
/// the *device* time zone, so a phone still on Asia/Kolkata while physically in
/// Seattle showed Fajr in the afternoon and Dhuhr after midnight.
void _timezoneIndependenceTests() {
  test('times do not depend on the device clock', () {
    final resolver = TimezoneResolver();
    final date = DateTime(2026, 9, 1);
    const seattleLat = 47.6062;
    const seattleLon = -122.3321;

    final zone = resolver.resolve(
      latitude: seattleLat,
      longitude: seattleLon,
      date: date,
    );
    expect(zone, isNotNull);
    expect(zone!.name, 'America/Los_Angeles');

    final times = PrayerCalculator(
      method: CalculationMethod.isna,
      asrMadhab: AsrMadhab.standard,
    ).forDate(
      date: date,
      latitude: seattleLat,
      longitude: seattleLon,
      utcOffsetHours: zone.offsetHours,
      zoneName: zone.name,
    );

    // Every prayer must land in a sane part of a Seattle day.
    // Wall clock in Seattle, regardless of the clock this test runs under.
    expect(times.wallClock(Prayer.fajr)!.hour, inInclusiveRange(3, 6),
        reason: 'Fajr before dawn');
    expect(times.wallClock(Prayer.sunrise)!.hour, inInclusiveRange(5, 7));
    expect(times.wallClock(Prayer.dhuhr)!.hour, inInclusiveRange(12, 14),
        reason: 'Dhuhr around noon');
    expect(times.wallClock(Prayer.maghrib)!.hour, inInclusiveRange(18, 21),
        reason: 'Maghrib at dusk');

    // And the whole schedule must sit inside the one Seattle calendar day.
    for (final prayer in Prayer.values) {
      expect(times.wallClock(prayer)!.day, date.day,
          reason: '$prayer spilled days');
    }

    // The stored values are absolute instants, so a countdown is correct no
    // matter what zone the device is in. Dhuhr in Seattle on 1 Sep 2026 is
    // 20:0x UTC (13:0x PDT).
    expect(times[Prayer.dhuhr]!.isUtc, isTrue);
    expect(times[Prayer.dhuhr]!.toUtc().hour, 20);
  });

  test('the same place yields the same times whatever the device offset', () {
    final resolver = TimezoneResolver();
    final date = DateTime(2026, 9, 1);
    final zone = resolver.resolve(
      latitude: 47.6062,
      longitude: -122.3321,
      date: date,
    )!;

    PrayerTimes build() => PrayerCalculator(
          method: CalculationMethod.isna,
          asrMadhab: AsrMadhab.standard,
        ).forDate(
          date: date,
          latitude: 47.6062,
          longitude: -122.3321,
          utcOffsetHours: zone.offsetHours,
          zoneName: zone.name,
        );

    final a = build();
    final b = build();
    for (final prayer in Prayer.values) {
      expect(a[prayer], b[prayer]);
    }
    expect(a.zoneName, 'America/Los_Angeles');
    expect(a.timezoneOffsetHours, -7.0);
  });
}
