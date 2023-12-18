import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

class QiblaDirection {
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled - request user to enable them
      bool enableLocationServices = await Geolocator.openLocationSettings();
      if (!enableLocationServices) {
        // Handle if user did not enable location services
        return null;
      }
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Location permission is denied - handle accordingly
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Location permissions are permanently denied - handle accordingly
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  static double getQiblaDirection(double lat, double lon) {
    double kaabaLatitude = 21.422477; // Latitude of Kaaba in Mecca
    double kaabaLongitude = 39.826202; // Longitude of Kaaba in Mecca

    double userLatRad = _degreeToRadians(lat);
    double userLonRad = _degreeToRadians(lon);
    double kaabaLatRad = _degreeToRadians(kaabaLatitude);
    double kaabaLonRad = _degreeToRadians(kaabaLongitude);

    double deltaLon = kaabaLonRad - userLonRad;

    double y = math.sin(deltaLon);
    double x = math.cos(userLatRad) * math.tan(kaabaLatRad) -
        math.sin(userLatRad) * math.cos(deltaLon);

    double qiblaAngle = math.atan2(y, x);
    qiblaAngle = _radiansToDegrees(qiblaAngle);
    qiblaAngle =
        (qiblaAngle + 360) % 360; // Normalize angle between 0 and 360 degrees

    return qiblaAngle;
  }

  static double _degreeToRadians(double degree) {
    return degree * (math.pi / 180.0);
  }

  static double _radiansToDegrees(double radians) {
    return radians * (180.0 / math.pi);
  }
}
