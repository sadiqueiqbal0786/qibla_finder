import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone_finder/timezone_finder.dart';

/// The time zone a set of coordinates actually sits in.
@immutable
class ResolvedZone {
  const ResolvedZone({
    required this.name,
    required this.offsetHours,
  });

  /// IANA identifier, e.g. `America/Los_Angeles`.
  final String name;

  /// UTC offset in hours for the requested date, DST included.
  final double offsetHours;
}

/// Resolves coordinates to an IANA time zone, so prayer times are rendered in
/// the clock of the *place* rather than the clock of the *device*.
///
/// Those are the same thing for a phone with automatic time zone on, which is
/// why the device offset stays the fallback. They diverge for a traveller who
/// has not switched their clock, for a phone with automatic time zone off, and
/// on emulators — and in those cases the old behaviour was silently hours out.
///
/// Backed by `timezone_finder`, which tests the point against real land
/// polygons (419 zone boundaries) rather than snapping to the nearest zone
/// centroid, and by `package:timezone` for the DST rules.
class TimezoneResolver {
  TimezoneResolver();

  static bool _tzInitialised = false;

  /// Loads the IANA rule database. Safe to call repeatedly.
  ///
  /// `latest_all` rather than `latest` is required: `latest` drops the tzdb
  /// link identifiers, and 106 of the 419 boundary identifiers resolve to one.
  static void ensureInitialised() {
    if (_tzInitialised) return;
    try {
      tzdata.initializeTimeZones();
      _tzInitialised = true;
    } catch (error, stackTrace) {
      debugPrint('TimezoneResolver: tzdata init failed: $error\n$stackTrace');
    }
  }

  /// The zone containing ([latitude], [longitude]), evaluated for [date].
  ///
  /// Returns `null` when the point is not inside any boundary (mid-ocean, or a
  /// gap in the dataset) so the caller can fall back rather than show a time
  /// derived from a guess.
  ResolvedZone? resolve({
    required double latitude,
    required double longitude,
    DateTime? date,
  }) {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180) {
      return null;
    }

    ensureInitialised();
    if (!_tzInitialised) return null;

    try {
      // Note the argument order: findLocation takes (longitude, latitude).
      final location = findLocation(longitude, latitude);
      if (location == null) return null;
      final on = date ?? DateTime.now();

      // Sample at local noon. Midnight can land inside a DST transition, where
      // the offset is ambiguous or skipped entirely.
      final noon = tz.TZDateTime(location, on.year, on.month, on.day, 12);
      final offset = noon.timeZoneOffset.inMinutes / 60.0;

      return ResolvedZone(name: location.name, offsetHours: offset);
    } catch (error) {
      debugPrint('TimezoneResolver: no zone for $latitude,$longitude: $error');
      return null;
    }
  }
}
