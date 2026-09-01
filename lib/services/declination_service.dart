import 'package:flutter/foundation.dart';
import 'package:geomag/geomag.dart';

/// Magnetic declination (variation) lookup, backed by the World Magnetic
/// Model 2025 coefficients bundled by the `geomag` package.
///
/// A magnetometer reports heading relative to *magnetic* north, but a Qibla
/// bearing is a great-circle bearing from *true* north. The gap between them
/// reaches 15-20 degrees across parts of North America and Oceania, and it is
/// the usual reason people report that a Qibla app "points the wrong way".
class DeclinationService {
  DeclinationService({GeoMag? geoMag}) : _geoMag = geoMag ?? GeoMag();

  final GeoMag _geoMag;

  /// Degrees to add to a magnetic heading to obtain a true heading.
  ///
  /// Positive means magnetic north lies east of true north. Returns `null`
  /// when the model cannot be evaluated, in which case callers should fall
  /// back to the uncorrected magnetic heading rather than guessing.
  double? declinationFor({
    required double latitude,
    required double longitude,
    double altitudeMetres = 0,
    DateTime? date,
  }) {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180) {
      return null;
    }

    try {
      final result = _geoMag.calculate(
        latitude,
        longitude,
        // The model takes height in feet.
        altitudeMetres.isFinite ? altitudeMetres * 3.28084 : 0,
        date ?? DateTime.now(),
      );
      final declination = result.dec;
      if (declination.isNaN || declination.isInfinite) return null;
      // WMM declination is bounded by +/-180; anything outside means the model
      // was evaluated outside its valid range.
      if (declination.abs() > 180) return null;
      return declination;
    } catch (error, stackTrace) {
      // The model is only valid for a five-year window. Once WMM-2025 expires
      // the package throws rather than returning a wrong answer, and an
      // uncorrected compass is better than a silently wrong one.
      debugPrint('DeclinationService: WMM evaluation failed: $error\n$stackTrace');
      return null;
    }
  }
}
