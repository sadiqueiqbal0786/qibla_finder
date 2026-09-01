import 'dart:math' as math;

/// Apparent position of the sun for a given instant.
class SolarPosition {
  const SolarPosition({
    required this.declination,
    required this.equationOfTime,
  });

  /// Solar declination in degrees.
  final double declination;

  /// Equation of time in hours.
  final double equationOfTime;
}

/// Low-precision solar ephemeris (US Naval Observatory / Meeus).
///
/// Accurate to well under a minute for prayer-time purposes, and entirely
/// offline — no API, no key, no network.
class Solar {
  const Solar._();

  /// Julian Day for a civil calendar date at 00:00 UT.
  static double julianDay(int year, int month, int day) {
    var y = year;
    var m = month;
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();

    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        day +
        b -
        1524.5;
  }

  static SolarPosition positionAt(double julianDate) {
    final d = julianDate - 2451545.0;

    // Mean anomaly, mean longitude, apparent longitude.
    final g = _fixAngle(357.529 + 0.98560028 * d);
    final q = _fixAngle(280.459 + 0.98564736 * d);
    final l = _fixAngle(
        q + 1.915 * _sinDeg(g) + 0.020 * _sinDeg(2 * g));

    // Obliquity of the ecliptic.
    final e = 23.439 - 0.00000036 * d;

    final declination = _asinDeg(_sinDeg(e) * _sinDeg(l));

    var rightAscension =
        _atan2Deg(_cosDeg(e) * _sinDeg(l), _cosDeg(l)) / 15.0;
    rightAscension = _fixHour(rightAscension);

    final equationOfTime = q / 15.0 - rightAscension;

    return SolarPosition(
      declination: declination,
      equationOfTime: equationOfTime,
    );
  }

  /// Local solar noon, in hours, for [julianDate].
  static double middayHours(double julianDate) {
    final eqt = positionAt(julianDate).equationOfTime;
    return _fixHour(12.0 - eqt);
  }

  /// Hours from midnight at which the sun sits [angle] degrees below the
  /// horizon, on the given side of noon.
  ///
  /// Returns `null` in the polar case where the sun never reaches that angle —
  /// the caller then applies a high-latitude rule rather than rendering a
  /// nonsense time.
  static double? hourAngleTime({
    required double julianDate,
    required double latitude,
    required double angle,
    required bool beforeNoon,
  }) {
    final declination = positionAt(julianDate).declination;
    final noon = middayHours(julianDate);

    final numerator = -_sinDeg(angle) - _sinDeg(declination) * _sinDeg(latitude);
    final denominator = _cosDeg(declination) * _cosDeg(latitude);
    if (denominator == 0) return null;

    final ratio = numerator / denominator;
    if (ratio.isNaN || ratio.abs() > 1.0) return null;

    final offset = _acosDeg(ratio) / 15.0;
    return beforeNoon ? noon - offset : noon + offset;
  }

  /// Time at which an object's shadow reaches [factor] times its own length
  /// plus its noon shadow — the definition of Asr.
  static double? asrTime({
    required double julianDate,
    required double latitude,
    required double factor,
  }) {
    final declination = positionAt(julianDate).declination;
    final angle = -_acotDeg(factor + _tanDeg((latitude - declination).abs()));
    return hourAngleTime(
      julianDate: julianDate,
      latitude: latitude,
      angle: angle,
      beforeNoon: false,
    );
  }

  static double _fixAngle(double angle) {
    final wrapped = angle % 360.0;
    return wrapped < 0 ? wrapped + 360.0 : wrapped;
  }

  static double _fixHour(double hour) {
    final wrapped = hour % 24.0;
    return wrapped < 0 ? wrapped + 24.0 : wrapped;
  }

  static const double _deg = math.pi / 180.0;

  static double _sinDeg(double d) => math.sin(d * _deg);
  static double _cosDeg(double d) => math.cos(d * _deg);
  static double _tanDeg(double d) => math.tan(d * _deg);
  static double _asinDeg(double x) => math.asin(x) / _deg;
  static double _acosDeg(double x) => math.acos(x) / _deg;
  static double _atan2Deg(double y, double x) => math.atan2(y, x) / _deg;
  static double _acotDeg(double x) => math.atan2(1.0, x) / _deg;
}
