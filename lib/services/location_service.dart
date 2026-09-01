import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Why a location request could not be satisfied.
enum LocationFailure {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unknown,
}

/// The outcome of a location request: either a [position], or a [failure].
///
/// Modelling this explicitly means the UI can render a specific, actionable
/// screen for each case instead of a spinner that never resolves.
@immutable
class LocationResult {
  const LocationResult.success(this.position, {this.isStale = false})
      : failure = null;

  const LocationResult.failure(this.failure)
      : position = null,
        isStale = false;

  final Position? position;
  final LocationFailure? failure;

  /// True when this came from the OS cache rather than a fresh fix.
  final bool isStale;

  bool get isSuccess => position != null;
}

/// A resolved place: what to show the user, and the country code used to pick
/// a regionally conventional prayer-time convention.
@immutable
class PlaceInfo {
  const PlaceInfo({this.label, this.isoCountryCode});

  final String? label;
  final String? isoCountryCode;
}

/// Location and reverse-geocoding, with every platform failure mapped to a
/// value instead of an exception escaping into the widget tree.
class LocationService {
  LocationService({
    this.fixTimeout = const Duration(seconds: 20),
    this.geocodeTimeout = const Duration(seconds: 10),
  });

  final Duration fixTimeout;
  final Duration geocodeTimeout;

  /// Guards against overlapping requests. The Android geolocator throws if a
  /// second request starts while one is in flight, which is exactly what the
  /// previous per-sensor-event code was doing thousands of times a minute.
  Future<LocationResult>? _inFlight;

  Future<LocationResult> getPosition() {
    return _inFlight ??= _getPosition().whenComplete(() => _inFlight = null);
  }

  Future<LocationResult> _getPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult.failure(LocationFailure.serviceDisabled);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const LocationResult.failure(LocationFailure.permissionDenied);
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult.failure(
            LocationFailure.permissionDeniedForever);
      }

      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: fixTimeout,
          ),
        ).timeout(fixTimeout);
        return LocationResult.success(position);
      } on TimeoutException {
        // Indoors a fresh fix can simply never arrive. A cached one still
        // yields a Qibla accurate to a fraction of a degree.
        final cached = await _lastKnown();
        if (cached != null) {
          return LocationResult.success(cached, isStale: true);
        }
        return const LocationResult.failure(LocationFailure.timeout);
      }
    } on LocationServiceDisabledException {
      return const LocationResult.failure(LocationFailure.serviceDisabled);
    } on PermissionDeniedException {
      return const LocationResult.failure(LocationFailure.permissionDenied);
    } catch (error, stackTrace) {
      debugPrint('LocationService: $error\n$stackTrace');
      final cached = await _lastKnown();
      if (cached != null) {
        return LocationResult.success(cached, isStale: true);
      }
      return const LocationResult.failure(LocationFailure.unknown);
    }
  }

  Future<Position?> _lastKnown() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (error) {
      debugPrint('LocationService: no cached position: $error');
      return null;
    }
  }

  /// Best-effort place description. Never throws and never blocks the Qibla:
  /// a failed lookup just means the location chip stays empty and the prayer
  /// method falls back to Muslim World League.
  Future<PlaceInfo?> describe(double latitude, double longitude) async {
    try {
      final placemarks = await Geocoding()
          .placemarkFromCoordinates(latitude, longitude)
          .timeout(geocodeTimeout);
      if (placemarks.isEmpty) return null;

      final place = placemarks.first;
      final parts = <String>[
        for (final candidate in <String?>[
          place.locality,
          place.subAdministrativeArea,
          place.administrativeArea,
          place.country,
        ])
          if (candidate != null && candidate.trim().isNotEmpty) candidate.trim(),
      ];
      return PlaceInfo(
        label: parts.isEmpty ? null : parts.take(2).join(', '),
        isoCountryCode: place.isoCountryCode,
      );
    } catch (error) {
      debugPrint('LocationService: reverse geocode failed: $error');
      return null;
    }
  }

  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (error) {
      debugPrint('LocationService: openLocationSettings failed: $error');
      return false;
    }
  }

  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (error) {
      debugPrint('LocationService: openAppSettings failed: $error');
      return false;
    }
  }
}
