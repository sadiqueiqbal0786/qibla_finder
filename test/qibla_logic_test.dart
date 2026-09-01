import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_finder/qibla_logic.dart';

void main() {
  group('qiblaBearing', () {
    // Reference bearings cross-checked against standard great-circle
    // calculators. A degree of tolerance covers Kaaba-coordinate variation.
    const cases = <String, (double, double, double)>{
      'London': (51.5074, -0.1278, 118.99),
      'New York': (40.7128, -74.0060, 58.48),
      'Jakarta': (-6.2088, 106.8456, 295.15),
      'Delhi': (28.6139, 77.2090, 266.51),
      'Cape Town': (-33.9249, 18.4241, 22.63),
      'Sydney': (-33.8688, 151.2093, 277.50),
    };

    cases.forEach((city, data) {
      test('is correct for $city', () {
        final bearing = QiblaDirection.qiblaBearing(data.$1, data.$2);
        expect(bearing, isNotNull);
        expect(bearing!, closeTo(data.$3, 1.0));
      });
    });

    test('rejects out-of-range and non-finite coordinates', () {
      expect(QiblaDirection.qiblaBearing(91, 0), isNull);
      expect(QiblaDirection.qiblaBearing(0, 181), isNull);
      expect(QiblaDirection.qiblaBearing(double.nan, 0), isNull);
      expect(QiblaDirection.qiblaBearing(0, double.infinity), isNull);
    });

    test('always returns a normalised angle', () {
      for (var lat = -80.0; lat <= 80.0; lat += 7) {
        for (var lon = -175.0; lon <= 175.0; lon += 11) {
          final bearing = QiblaDirection.qiblaBearing(lat, lon);
          if (bearing == null) continue;
          expect(bearing, greaterThanOrEqualTo(0));
          expect(bearing, lessThan(360));
        }
      }
    });
  });

  group('distanceToKaabaKm', () {
    test('is ~0 at the Kaaba itself', () {
      final d = QiblaDirection.distanceToKaabaKm(
          QiblaDirection.kaabaLatitude, QiblaDirection.kaabaLongitude);
      expect(d, isNotNull);
      expect(d!, closeTo(0, 0.5));
    });

    test('matches known distances', () {
      expect(QiblaDirection.distanceToKaabaKm(51.5074, -0.1278)!,
          closeTo(4772, 40));
      expect(QiblaDirection.distanceToKaabaKm(28.6139, 77.2090)!,
          closeTo(3859, 40));
    });
  });

  group('normalize', () {
    test('folds any input into [0, 360)', () {
      expect(QiblaDirection.normalize(0), 0);
      expect(QiblaDirection.normalize(360), 0);
      expect(QiblaDirection.normalize(-1), 359);
      expect(QiblaDirection.normalize(-721), closeTo(359, 1e-9));
      expect(QiblaDirection.normalize(1080.5), closeTo(0.5, 1e-9));
    });

    test('is safe for non-finite input', () {
      expect(QiblaDirection.normalize(double.nan), 0);
      expect(QiblaDirection.normalize(double.infinity), 0);
    });
  });

  group('shortestDelta', () {
    test('takes the short way round the 0/360 seam', () {
      expect(QiblaDirection.shortestDelta(359, 1), closeTo(2, 1e-9));
      expect(QiblaDirection.shortestDelta(1, 359), closeTo(-2, 1e-9));
      expect(QiblaDirection.shortestDelta(10, 20), closeTo(10, 1e-9));
      expect(QiblaDirection.shortestDelta(20, 10), closeTo(-10, 1e-9));
    });

    test('never exceeds a half turn', () {
      for (var from = 0.0; from < 360; from += 13) {
        for (var to = 0.0; to < 360; to += 17) {
          final delta = QiblaDirection.shortestDelta(from, to);
          expect(delta, greaterThan(-180.0001));
          expect(delta, lessThanOrEqualTo(180.0001));
        }
      }
    });
  });

  group('cardinal', () {
    test('maps bearings to compass points', () {
      expect(QiblaDirection.cardinal(0), 'N');
      expect(QiblaDirection.cardinal(90), 'E');
      expect(QiblaDirection.cardinal(180), 'S');
      expect(QiblaDirection.cardinal(270), 'W');
      expect(QiblaDirection.cardinal(45), 'NE');
      expect(QiblaDirection.cardinal(359), 'N');
    });
  });
}
