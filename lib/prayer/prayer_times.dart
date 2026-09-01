import 'package:flutter/foundation.dart';

import 'calculation_method.dart';
import 'solar.dart';

enum Prayer { fajr, sunrise, dhuhr, asr, maghrib, isha }

extension PrayerLabel on Prayer {
  String get label => switch (this) {
        Prayer.fajr => 'Fajr',
        Prayer.sunrise => 'Sunrise',
        Prayer.dhuhr => 'Dhuhr',
        Prayer.asr => 'Asr',
        Prayer.maghrib => 'Maghrib',
        Prayer.isha => 'Isha',
      };

  /// Sunrise is a boundary, not a prayer — it gets no reminder and is styled
  /// differently in the schedule.
  bool get isPrayer => this != Prayer.sunrise;
}

/// One day's times, in the device's local timezone.
@immutable
class PrayerTimes {
  const PrayerTimes({
    required this.date,
    required this.times,
    required this.method,
    required this.asrMadhab,
    required this.usedHighLatitudeRule,
    required this.timezoneOffsetHours,
    required this.deviceOffsetHours,
    this.zoneName,
  });

  final DateTime date;

  /// Absolute instants, stored in UTC.
  ///
  /// Storing wall-clock `DateTime`s would silently re-interpret them in the
  /// device's zone: correct on a phone whose clock matches where it is, but
  /// giving nonsense countdowns and misfiring alarms for a traveller who has
  /// not switched over. Instants compare and schedule correctly everywhere;
  /// [wallClock] converts one back for display.
  final Map<Prayer, DateTime> times;
  final CalculationMethod method;
  final AsrMadhab asrMadhab;

  /// True when a polar-latitude fallback was applied, so the UI can say so
  /// rather than presenting an estimate as gospel.
  final bool usedHighLatitudeRule;

  /// UTC offset these times are expressed in.
  final double timezoneOffsetHours;

  /// UTC offset the device clock was on when this was computed.
  final double deviceOffsetHours;

  /// IANA zone the coordinates resolved to, e.g. `America/Los_Angeles`.
  ///
  /// Null when the point sits outside every boundary, in which case the
  /// device clock was used instead.
  final String? zoneName;

  /// True when these times are shown in the location's clock rather than the
  /// device's, because the two disagree.
  ///
  /// The usual cause is a traveller who has not switched their phone over, or
  /// automatic time zone being off. The times are correct for where the user
  /// is standing; the note exists so the numbers are not confusing next to a
  /// status-bar clock that says something else.
  bool get clockDiffersFromDevice =>
      zoneName != null &&
      (timezoneOffsetHours - deviceOffsetHours).abs() > 0.01;

  /// The absolute instant of [prayer].
  DateTime? operator [](Prayer prayer) => times[prayer];

  /// [prayer] rendered in the clock of the location.
  ///
  /// The returned value carries the location's wall-clock fields, so
  /// formatting it prints what a clock on that wall would read.
  DateTime? wallClock(Prayer prayer) {
    final instant = times[prayer];
    if (instant == null) return null;
    return instant
        .toUtc()
        .add(Duration(minutes: (timezoneOffsetHours * 60).round()));
  }

  /// The next prayer strictly after [from], or null if today is exhausted.
  MapEntry<Prayer, DateTime>? nextAfter(DateTime from) {
    for (final prayer in Prayer.values) {
      if (!prayer.isPrayer) continue;
      final time = times[prayer];
      if (time != null && time.isAfter(from)) {
        return MapEntry(prayer, time);
      }
    }
    return null;
  }

  /// The prayer currently in progress at [at].
  MapEntry<Prayer, DateTime>? currentAt(DateTime at) {
    MapEntry<Prayer, DateTime>? current;
    for (final prayer in Prayer.values) {
      if (!prayer.isPrayer) continue;
      final time = times[prayer];
      if (time != null && !time.isAfter(at)) {
        current = MapEntry(prayer, time);
      }
    }
    return current;
  }
}

/// Offline prayer-time calculator.
class PrayerCalculator {
  const PrayerCalculator({
    required this.method,
    required this.asrMadhab,
    this.highLatitudeRule = HighLatitudeRule.angleBased,
  });

  final CalculationMethod method;
  final AsrMadhab asrMadhab;
  final HighLatitudeRule highLatitudeRule;

  /// Standard atmospheric refraction plus solar semi-diameter.
  static const double _riseSetAngle = 0.833;

  PrayerTimes forDate({
    required DateTime date,
    required double latitude,
    required double longitude,
    double? utcOffsetHours,
    String? zoneName,
  }) {
    final local = DateTime(date.year, date.month, date.day);

    // Defaults to the offset the device is actually in, so DST is handled by
    // the platform rather than by us guessing. Injectable so the engine can be
    // tested against other cities, and so travel mode can pass the offset of a
    // saved location rather than the phone's current one.
    final offsetHours =
        utcOffsetHours ?? local.timeZoneOffset.inMinutes / 60.0;

    final jd = Solar.julianDay(local.year, local.month, local.day) -
        longitude / 360.0;

    double? angleTime(double angle, {required bool beforeNoon}) =>
        Solar.hourAngleTime(
          julianDate: jd,
          latitude: latitude,
          angle: angle,
          beforeNoon: beforeNoon,
        );

    final noon = Solar.middayHours(jd);
    var sunrise = angleTime(_riseSetAngle, beforeNoon: true);
    var sunset = angleTime(_riseSetAngle, beforeNoon: false);
    var fajr = angleTime(method.fajrAngle, beforeNoon: true);
    final asr = Solar.asrTime(
      julianDate: jd,
      latitude: latitude,
      factor: asrMadhab.shadowFactor,
    );

    final maghribAngle = method.maghribAngle;
    var maghrib = maghribAngle == null
        ? sunset
        : angleTime(maghribAngle, beforeNoon: false);

    double? isha;
    if (method.ishaMode == IshaMode.interval) {
      isha = maghrib == null
          ? null
          : maghrib + method.ishaInterval / 60.0;
    } else {
      isha = angleTime(method.ishaAngle, beforeNoon: false);
    }

    // Polar fallbacks. Sunrise/sunset failing means true midnight sun or polar
    // night; we still need a night span to divide, so fall back to the
    // civil-twilight boundary before giving up.
    var usedHighLatitude = false;
    if (sunrise == null || sunset == null) {
      usedHighLatitude = true;
      sunrise ??= angleTime(6, beforeNoon: true) ?? noon - 6;
      sunset ??= angleTime(6, beforeNoon: false) ?? noon + 6;
    }

    final nightLength = (sunrise + 24.0) - sunset;

    if (fajr == null) {
      usedHighLatitude = true;
      fajr = sunrise -
          _nightPortion(nightLength, method.fajrAngle);
    }
    if (isha == null) {
      usedHighLatitude = true;
      isha = sunset +
          _nightPortion(
              nightLength,
              method.ishaMode == IshaMode.angle
                  ? method.ishaAngle
                  : method.fajrAngle);
    }
    maghrib ??= sunset;

    // Even when an angle resolves, it can land absurdly far from sunrise at
    // high latitude. Clamp to the rule's portion so Fajr never precedes the
    // middle of the night.
    final fajrLimit = sunrise - _nightPortion(nightLength, method.fajrAngle);
    if (fajr < fajrLimit) {
      usedHighLatitude = true;
      fajr = fajrLimit;
    }
    final ishaLimit = sunset +
        _nightPortion(
            nightLength,
            method.ishaMode == IshaMode.angle
                ? method.ishaAngle
                : method.fajrAngle);
    if (isha > ishaLimit) {
      usedHighLatitude = true;
      isha = ishaLimit;
    }

    final raw = <Prayer, double?>{
      Prayer.fajr: fajr,
      Prayer.sunrise: sunrise,
      Prayer.dhuhr: noon + 1.0 / 60.0,
      Prayer.asr: asr,
      Prayer.maghrib: maghrib,
      Prayer.isha: isha,
    };

    final times = <Prayer, DateTime>{};
    raw.forEach((prayer, hours) {
      if (hours == null || !hours.isFinite) return;
      // Convert from mean solar time at this longitude to the location's
      // clock, then to an absolute instant.
      final localHours = hours + offsetHours - longitude / 15.0;
      times[prayer] = _toInstant(local, localHours, offsetHours);
    });

    return PrayerTimes(
      date: local,
      times: times,
      method: method,
      asrMadhab: asrMadhab,
      usedHighLatitudeRule: usedHighLatitude,
      timezoneOffsetHours: offsetHours,
      deviceOffsetHours: local.timeZoneOffset.inMinutes / 60.0,
      zoneName: zoneName,
    );
  }

  /// Portion of the night allotted to Fajr/Isha under the active rule.
  double _nightPortion(double nightLength, double angle) {
    return switch (highLatitudeRule) {
      HighLatitudeRule.middleOfNight => nightLength / 2.0,
      HighLatitudeRule.seventhOfNight => nightLength / 7.0,
      HighLatitudeRule.angleBased => nightLength * angle / 60.0,
    };
  }

  /// Converts a wall-clock hour in the location's zone into an absolute UTC
  /// instant.
  static DateTime _toInstant(
    DateTime day,
    double localHours,
    double offsetHours,
  ) {
    final utcMidnight = DateTime.utc(day.year, day.month, day.day);
    final minutes = ((localHours - offsetHours) * 60).round();
    return utcMidnight.add(Duration(minutes: minutes));
  }
}
