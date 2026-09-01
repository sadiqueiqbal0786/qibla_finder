import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_finder/services/declination_service.dart';

void main() {
  final service = DeclinationService();

  double? decAt(double lat, double lon) => service.declinationFor(
        latitude: lat,
        longitude: lon,
        date: DateTime.utc(2026, 1, 1),
      );

  group('magnetic declination (WMM-2025)', () {
    // Reference declinations for epoch 2026.0. Tolerances are generous enough
    // to absorb model revisions but tight enough to catch a sign flip or a
    // degrees/radians mix-up, which are the failure modes that matter.
    // Positive is east, negative is west. The agonic (zero) line runs through
    // the middle of the USA: easterly to the west of it, westerly to the east.
    test('is strongly east in the western United States', () {
      final seattle = decAt(47.6062, -122.3321);
      expect(seattle, isNotNull);
      expect(seattle!, closeTo(15.3, 2.5));
    });

    test('is east in eastern Australia', () {
      final sydney = decAt(-33.8688, 151.2093);
      expect(sydney, isNotNull);
      expect(sydney!, closeTo(12.6, 2.5));
    });

    test('is small in western Europe', () {
      final london = decAt(51.5074, -0.1278);
      expect(london, isNotNull);
      expect(london!.abs(), lessThan(4.0));
    });

    test('is west in the eastern United States', () {
      final newYork = decAt(40.7128, -74.0060);
      expect(newYork, isNotNull);
      expect(newYork!, closeTo(-12.9, 2.5));
    });

    test('is modest near Makkah', () {
      final makkah = decAt(21.4225, 39.8262);
      expect(makkah, isNotNull);
      expect(makkah!.abs(), lessThan(8.0));
    });

    test('returns a finite value across the globe', () {
      for (var lat = -85.0; lat <= 85.0; lat += 17) {
        for (var lon = -180.0; lon <= 180.0; lon += 30) {
          final d = decAt(lat, lon);
          if (d == null) continue;
          expect(d.isFinite, isTrue, reason: 'at $lat,$lon');
          expect(d.abs(), lessThanOrEqualTo(180.0), reason: 'at $lat,$lon');
        }
      }
    });

    test('rejects impossible coordinates instead of guessing', () {
      expect(service.declinationFor(latitude: 91, longitude: 0), isNull);
      expect(service.declinationFor(latitude: 0, longitude: 181), isNull);
      expect(service.declinationFor(latitude: double.nan, longitude: 0), isNull);
    });
  });
}
