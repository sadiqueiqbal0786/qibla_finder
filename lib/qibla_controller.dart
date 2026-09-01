import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'data/app_database.dart';
import 'prayer/prayer_notifications.dart';
import 'prayer/prayer_watcher.dart';
import 'prayer/prayer_settings.dart';
import 'prayer/prayer_times.dart';
import 'qibla_logic.dart';
import 'services/compass_service.dart';
import 'services/declination_service.dart';
import 'services/timezone_resolver.dart';
import 'services/location_service.dart';

/// Every state the Qibla screen can be in. The UI switches on this, so there
/// is no combination of flags that can leave the user on a dead spinner.
enum QiblaStatus {
  initializing,
  ready,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timedOut,
  failed,
}

/// Owns location, compass and the derived Qibla bearing.
///
/// The important design point: the location fix happens **once** per refresh,
/// not once per compass event. The previous implementation requested a
/// full-accuracy GPS fix inside the sensor callback, which fires tens of times
/// a second.
class QiblaController extends ChangeNotifier {
  QiblaController({
    required this.settings,
    required this.database,
    LocationService? locationService,
    CompassService? compassService,
    DeclinationService? declinationService,
    TimezoneResolver? timezoneResolver,
  })  : _location = locationService ?? LocationService(),
        compass = compassService ?? CompassService(),
        _declination = declinationService ?? DeclinationService(),
        _timezones = timezoneResolver ?? TimezoneResolver() {
    settings.addListener(_recomputePrayerTimes);
  }

  /// Fires when a prayer time arrives while the app is open.
  final PrayerWatcher _watcher = PrayerWatcher(onPrayerDue: _noopPrayerDue);

  static void _noopPrayerDue(Prayer prayer) {}

  final LocationService _location;
  final CompassService compass;
  final DeclinationService _declination;
  final TimezoneResolver _timezones;
  final PrayerSettings settings;
  final AppDatabase database;

  QiblaStatus _status = QiblaStatus.initializing;
  double? _qiblaBearing;
  double? _distanceKm;
  String? _placeName;
  String? _isoCountryCode;
  Position? _position;
  PrayerTimes? _prayerTimes;
  bool _positionIsStale = false;
  bool _refreshing = false;
  bool _disposed = false;

  QiblaStatus get status => _status;

  /// Bearing to the Kaaba in degrees from true north, or null until located.
  double? get qiblaBearing => _qiblaBearing;

  /// Great-circle distance to the Kaaba in kilometres.
  double? get distanceKm => _distanceKm;

  /// Human-readable place, or null if reverse geocoding failed or is pending.
  String? get placeName => _placeName;

  /// True when the fix came from the OS cache rather than a live reading.
  bool get positionIsStale => _positionIsStale;

  /// Detected ISO country code, used to pick a regional prayer convention.
  String? get isoCountryCode => _isoCountryCode;

  Position? get position => _position;

  /// Today's schedule for the current position, or null until located.
  PrayerTimes? get prayerTimes => _prayerTimes;

  /// True while a refresh is in flight, so the UI can show a subtle spinner
  /// without tearing down the compass.
  bool get isRefreshing => _refreshing;

  bool get hasBearing => _qiblaBearing != null;

  Future<void> initialize() async {
    compass.start();
    await refresh();
  }

  /// Re-runs the whole location flow. Safe to call from a button, from app
  /// resume, or twice at once.
  Future<void> refresh() async {
    if (_disposed || _refreshing) return;

    _refreshing = true;
    // Keep the previous bearing on screen while refreshing so the needle does
    // not blink away on every retry.
    if (!hasBearing) _status = QiblaStatus.initializing;
    _safeNotify();

    final result = await _location.getPosition();
    if (_disposed) return;

    if (!result.isSuccess) {
      _status = switch (result.failure) {
        LocationFailure.serviceDisabled => QiblaStatus.serviceDisabled,
        LocationFailure.permissionDenied => QiblaStatus.permissionDenied,
        LocationFailure.permissionDeniedForever =>
          QiblaStatus.permissionDeniedForever,
        LocationFailure.timeout => QiblaStatus.timedOut,
        _ => QiblaStatus.failed,
      };
      _refreshing = false;
      _safeNotify();
      return;
    }

    final position = result.position!;
    final bearing =
        QiblaDirection.qiblaBearing(position.latitude, position.longitude);

    if (bearing == null) {
      _status = QiblaStatus.failed;
      _refreshing = false;
      _safeNotify();
      return;
    }

    _qiblaBearing = bearing;
    _distanceKm =
        QiblaDirection.distanceToKaabaKm(position.latitude, position.longitude);
    _position = position;
    _positionIsStale = result.isStale;

    // Correct the magnetometer for local magnetic variation. Without this the
    // needle is off by the declination, which exceeds 15 degrees in parts of
    // North America and Oceania.
    compass.setDeclination(_declination.declinationFor(
      latitude: position.latitude,
      longitude: position.longitude,
      altitudeMetres: position.altitude,
    ));
    _status = QiblaStatus.ready;
    _refreshing = false;
    _recomputePrayerTimes(notify: false);
    _safeNotify();

    // Reverse geocoding is cosmetic, so it runs after the Qibla is already on
    // screen and its failure is not allowed to change the status. It also
    // supplies the country code that picks the regional prayer convention.
    final place =
        await _location.describe(position.latitude, position.longitude);
    if (_disposed || place == null) return;
    _placeName = place.label ?? _placeName;
    _isoCountryCode = place.isoCountryCode;
    // Cache it so a cold start can show a Qibla immediately instead of an
    // empty screen while GPS warms up.
    unawaited(database
        .rememberCurrentLocation(
          label: place.label ?? 'Current location',
          latitude: position.latitude,
          longitude: position.longitude,
          isoCountryCode: place.isoCountryCode,
        )
        .catchError((Object e) => debugPrint('cache location failed: $e')));
    // Applying regional defaults notifies settings listeners, which triggers
    // _recomputePrayerTimes via the listener registered in the constructor.
    settings.applyRegionalDefaults(place.isoCountryCode);
    _recomputePrayerTimes(notify: false);
    _safeNotify();
  }

  void _recomputePrayerTimes({bool notify = true}) {
    if (_disposed) return;
    final position = _position;
    if (position == null) return;

    try {
      final today = DateTime.now();
      // Render in the clock of the place, not the clock of the phone. These
      // agree for a phone with automatic time zone on, and diverge exactly
      // where the old behaviour was silently hours wrong.
      final zone = _timezones.resolve(
        latitude: position.latitude,
        longitude: position.longitude,
        date: today,
      );

      _prayerTimes = PrayerCalculator(
        method: settings.method,
        asrMadhab: settings.asrMadhab,
        highLatitudeRule: settings.highLatitudeRule,
      ).forDate(
        date: today,
        latitude: position.latitude,
        longitude: position.longitude,
        utcOffsetHours: zone?.offsetHours,
        zoneName: zone?.name,
      );
    } catch (error, stackTrace) {
      // A prayer-time failure must never take the Qibla compass down with it.
      debugPrint('QiblaController: prayer times failed: $error\n$stackTrace');
      _prayerTimes = null;
    }
    _watcher.update(times: _prayerTimes, mode: settings.adhanMode);
    if (notify) _safeNotify();
    unawaited(_syncReminders());
  }

  /// Keeps scheduled reminders in step with the current position and settings.
  Future<void> _syncReminders() async {
    final position = _position;
    if (position == null) return;

    if (!settings.remindersEnabled) {
      await PrayerNotifications.instance.cancelAll();
      return;
    }

    await PrayerNotifications.instance.reschedule(
      latitude: position.latitude,
      longitude: position.longitude,
      method: settings.method,
      asrMadhab: settings.asrMadhab,
      highLatitudeRule: settings.highLatitudeRule,
      adhanMode: settings.adhanMode,
    );
  }

  /// Recomputes for a new calendar day. Called when the app resumes.
  void refreshPrayerTimesIfStale() {
    final current = _prayerTimes;
    if (current == null) return;
    final today = DateTime.now();
    if (current.date.year == today.year &&
        current.date.month == today.month &&
        current.date.day == today.day) {
      return;
    }
    _recomputePrayerTimes();
  }

  Future<void> openLocationSettings() => _location.openLocationSettings();

  Future<void> openAppSettings() => _location.openAppSettings();

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _watcher.dispose();
    settings.removeListener(_recomputePrayerTimes);
    compass.dispose();
    super.dispose();
  }
}
