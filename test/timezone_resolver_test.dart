import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_finder/services/timezone_resolver.dart';

void main() {
  final resolver = TimezoneResolver();

  ResolvedZone? at(double lat, double lon, DateTime on) =>
      resolver.resolve(latitude: lat, longitude: lon, date: on);

  final september = DateTime(2026, 9, 1);
  final january = DateTime(2026, 1, 15);

  group('zone identification', () {
    test('resolves major cities to the right IANA zone', () {
      expect(at(47.6062, -122.3321, september)?.name, 'America/Los_Angeles');
      expect(at(40.7128, -74.0060, september)?.name, 'America/New_York');
      expect(at(51.5074, -0.1278, september)?.name, 'Europe/London');
      expect(at(24.8607, 67.0011, september)?.name, 'Asia/Karachi');
      expect(at(28.6139, 77.2090, september)?.name, 'Asia/Kolkata');
      expect(at(-33.8688, 151.2093, september)?.name, 'Australia/Sydney');
    });

    test('argument order is (latitude, longitude), not swapped', () {
      // Paris is 48.86N 2.35E. Swapping the arguments lands in the Indian
      // Ocean off Somalia, so this catches a lat/lon transposition.
      expect(at(48.8566, 2.3522, september)?.name, 'Europe/Paris');
    });

    test('returns null mid-ocean rather than guessing', () {
      expect(at(0, -140, september), isNull);
    });

    test('rejects impossible coordinates', () {
      expect(resolver.resolve(latitude: 91, longitude: 0), isNull);
      expect(resolver.resolve(latitude: 0, longitude: 181), isNull);
      expect(resolver.resolve(latitude: double.nan, longitude: 0), isNull);
    });
  });

  group('offsets include daylight saving', () {
    test('Seattle is -7 in September and -8 in January', () {
      expect(at(47.6062, -122.3321, september)?.offsetHours, -7.0);
      expect(at(47.6062, -122.3321, january)?.offsetHours, -8.0);
    });

    test('London is +1 in September and 0 in January', () {
      expect(at(51.5074, -0.1278, september)?.offsetHours, 1.0);
      expect(at(51.5074, -0.1278, january)?.offsetHours, 0.0);
    });

    test('handles half-hour zones', () {
      expect(at(28.6139, 77.2090, september)?.offsetHours, 5.5);
    });

    test('zones without DST do not shift', () {
      expect(at(24.8607, 67.0011, september)?.offsetHours, 5.0);
      expect(at(24.8607, 67.0011, january)?.offsetHours, 5.0);
      expect(at(21.4225, 39.8262, september)?.offsetHours, 3.0);
    });
  });
}
