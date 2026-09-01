import 'dart:math' as math;

/// Pure, dependency-free geodesy for the Qibla.
///
/// Everything here is a static function over plain numbers so it can be unit
/// tested without a device, a platform channel or a running Flutter binding.
class QiblaDirection {
  const QiblaDirection._();

  /// Latitude of the Kaaba, Masjid al-Haram, Mecca.
  static const double kaabaLatitude = 21.422487;

  /// Longitude of the Kaaba, Masjid al-Haram, Mecca.
  static const double kaabaLongitude = 39.826206;

  /// Mean Earth radius in kilometres (IUGG).
  static const double _earthRadiusKm = 6371.0088;

  /// Initial great-circle bearing from ([lat], [lon]) to the Kaaba, in degrees
  /// clockwise from **true** north, normalised to `[0, 360)`.
  ///
  /// Returns `null` when the coordinates are not usable (NaN, infinite or out
  /// of range), so callers never render a garbage angle.
  static double? qiblaBearing(double lat, double lon) {
    if (!_isValidLatitude(lat) || !_isValidLongitude(lon)) return null;

    final userLat = _toRadians(lat);
    final userLon = _toRadians(lon);
    final kaabaLat = _toRadians(kaabaLatitude);
    final kaabaLon = _toRadians(kaabaLongitude);

    final deltaLon = kaabaLon - userLon;

    // Standard initial-bearing formula, divided through by cos(kaabaLat):
    //   atan2(sin Δλ · cos φ₂, cos φ₁ · sin φ₂ − sin φ₁ · cos φ₂ · cos Δλ)
    final y = math.sin(deltaLon);
    final x = math.cos(userLat) * math.tan(kaabaLat) -
        math.sin(userLat) * math.cos(deltaLon);

    // At the Kaaba itself (and at the antipode) the bearing is undefined.
    if (x == 0 && y == 0) return null;

    final bearing = _toDegrees(math.atan2(y, x));
    if (bearing.isNaN || bearing.isInfinite) return null;

    return normalize(bearing);
  }

  /// Great-circle distance from ([lat], [lon]) to the Kaaba in kilometres, or
  /// `null` for unusable coordinates.
  static double? distanceToKaabaKm(double lat, double lon) {
    if (!_isValidLatitude(lat) || !_isValidLongitude(lon)) return null;

    final phi1 = _toRadians(lat);
    final phi2 = _toRadians(kaabaLatitude);
    final deltaPhi = _toRadians(kaabaLatitude - lat);
    final deltaLambda = _toRadians(kaabaLongitude - lon);

    final a = math.sin(deltaPhi / 2) * math.sin(deltaPhi / 2) +
        math.cos(phi1) *
            math.cos(phi2) *
            math.sin(deltaLambda / 2) *
            math.sin(deltaLambda / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    final distance = _earthRadiusKm * c;
    return distance.isFinite ? distance : null;
  }

  /// Folds any angle into `[0, 360)`. Safe for negative and very large inputs.
  static double normalize(double degrees) {
    if (!degrees.isFinite) return 0;
    final wrapped = degrees % 360;
    return wrapped < 0 ? wrapped + 360 : wrapped;
  }

  /// Signed shortest rotation from [from] to [to], in `(-180, 180]`.
  ///
  /// This is what keeps the needle from spinning the long way round when the
  /// heading crosses the 359° -> 0° seam.
  static double shortestDelta(double from, double to) {
    final diff = (normalize(to) - normalize(from) + 540) % 360 - 180;
    return diff;
  }

  /// Compass point label ("N", "NE", ...) for a bearing.
  static String cardinal(double degrees) {
    const points = <String>[
      'N', 'NNE', 'NE', 'ENE',
      'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW',
      'W', 'WNW', 'NW', 'NNW',
    ];
    final index = ((normalize(degrees) / 22.5) + 0.5).floor() % 16;
    return points[index];
  }

  static bool _isValidLatitude(double value) =>
      value.isFinite && value >= -90 && value <= 90;

  static bool _isValidLongitude(double value) =>
      value.isFinite && value >= -180 && value <= 180;

  static double _toRadians(double degrees) => degrees * (math.pi / 180.0);

  static double _toDegrees(double radians) => radians * (180.0 / math.pi);
}
