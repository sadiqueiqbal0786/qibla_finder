import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../services/timezone_resolver.dart';
import 'calculation_method.dart';
import 'prayer_times.dart';

/// Schedules a local reminder at each prayer time.
///
/// Everything here is best-effort: a device that refuses notification
/// permission, blocks exact alarms, or has no timezone database still runs the
/// rest of the app normally.
class PrayerNotifications {
  PrayerNotifications._();

  static final PrayerNotifications instance = PrayerNotifications._();

  /// One channel per sound. Android freezes a channel's sound at creation
  /// time and ignores later changes, so switching the adhan setting has to
  /// switch channel rather than mutate one.
  static const String _channelSilent = 'prayer_silent_v1';
  static const String _channelDefault = 'prayer_default_v1';
  static const String _channelAdhan = 'prayer_adhan_v1';
  static const String _channelAdhanFajr = 'prayer_adhan_fajr_v1';

  /// Android plays these from `android/app/src/main/res/raw/` while the app is
  /// closed. Values are resource names, without extension.
  ///
  /// Fajr has its own recitation: the dawn adhan adds
  /// *aṣ-ṣalātu khayrun min an-nawm* ("prayer is better than sleep"), which the
  /// other four do not contain. A channel's sound is fixed when the channel is
  /// created, so the two cannot share one channel.
  static const String _adhanResource = 'adhan';
  static const String _adhanFajrResource = 'adhan_fajr';

  /// Reminders are scheduled this many days ahead and topped up on each app
  /// launch. iOS caps pending notifications at 64, so a week of five prayers
  /// (35) leaves comfortable headroom.
  static const int _daysAhead = 7;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final TimezoneResolver _timezones = TimezoneResolver();

  bool _initialized = false;
  bool _timezoneReady = false;

  Future<bool> initialize() async {
    if (_initialized) return true;
    try {
      await _prepareTimezone();

      const android = AndroidInitializationSettings('@mipmap/launcher_icon');
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      await _plugin.initialize(
        settings: const InitializationSettings(android: android, iOS: darwin),
      );
      _initialized = true;
      return true;
    } catch (error, stackTrace) {
      debugPrint('PrayerNotifications: init failed: $error\n$stackTrace');
      return false;
    }
  }

  Future<void> _prepareTimezone() async {
    if (_timezoneReady) return;
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name.identifier));
    } catch (error) {
      // Falling back to UTC would shift every reminder, so prefer a fixed
      // offset location derived from the device instead.
      debugPrint('PrayerNotifications: timezone lookup failed: $error');
    }
    _timezoneReady = true;
  }

  /// Asks for notification permission. Returns false if the user declines or
  /// the platform refuses.
  Future<bool> requestPermission() async {
    if (!await initialize()) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        return granted ?? false;
      }

      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        final granted = await ios.requestPermissions(alert: true, sound: true);
        return granted ?? false;
      }
      return false;
    } catch (error) {
      debugPrint('PrayerNotifications: permission request failed: $error');
      return false;
    }
  }

  /// Clears and re-schedules reminders for the next [_daysAhead] days.
  Future<void> reschedule({
    required double latitude,
    required double longitude,
    required CalculationMethod method,
    required AsrMadhab asrMadhab,
    required HighLatitudeRule highLatitudeRule,
    AdhanMode adhanMode = AdhanMode.notificationOnly,
  }) async {
    if (!await initialize()) return;

    await cancelAll();

    // Android 14 denies exact alarms by default to apps that are not clock or
    // calendar apps, and this app deliberately does not request the
    // Play-restricted USE_EXACT_ALARM. Ask once rather than letting 35
    // schedule calls each throw and fall back.
    final exact = await _canScheduleExact();

    final calculator = PrayerCalculator(
      method: method,
      asrMadhab: asrMadhab,
      highLatitudeRule: highLatitudeRule,
    );
    final now = DateTime.now();

    var id = 0;
    for (var dayOffset = 0; dayOffset < _daysAhead; dayOffset++) {
      final day = DateTime(now.year, now.month, now.day)
          .add(Duration(days: dayOffset));

      late final PrayerTimes times;
      try {
        // Resolved per day, not once: a DST transition can fall inside the
        // seven-day window, and an hour-late Fajr reminder is a real failure.
        final zone = _timezones.resolve(
          latitude: latitude,
          longitude: longitude,
          date: day,
        );
        times = calculator.forDate(
          date: day,
          latitude: latitude,
          longitude: longitude,
          utcOffsetHours: zone?.offsetHours,
          zoneName: zone?.name,
        );
      } catch (error) {
        debugPrint('PrayerNotifications: skipping $day: $error');
        continue;
      }

      for (final prayer in Prayer.values) {
        if (!prayer.isPrayer) continue;
        final time = times[prayer];
        if (time == null || !time.isAfter(now)) continue;

        await _scheduleOne(
          id: id++,
          prayer: prayer,
          at: time,
          adhanMode: adhanMode,
          exact: exact,
        );
      }
    }
  }

  /// Builds the platform payload for the selected sound.
  ///
  /// The adhan plays from the notification itself, which is what lets it sound
  /// with the app closed. On Android the full recitation plays. On iOS a
  /// custom notification sound is capped at 30 seconds by the OS, so the
  /// bundled clip should be a short call rather than the full adhan.
  NotificationDetails _detailsFor(AdhanMode mode, Prayer prayer) {
    final isFajr = prayer == Prayer.fajr;

    final android = switch (mode) {
      AdhanMode.silent => const AndroidNotificationDetails(
          _channelSilent,
          'Prayer reminders (silent)',
          channelDescription: 'Prayer time reminders without a sound.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: false,
          category: AndroidNotificationCategory.reminder,
        ),
      AdhanMode.notificationOnly => const AndroidNotificationDetails(
          _channelDefault,
          'Prayer reminders',
          channelDescription: 'Prayer time reminders with the default sound.',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
        ),
      AdhanMode.adhan => AndroidNotificationDetails(
          isFajr ? _channelAdhanFajr : _channelAdhan,
          isFajr
              ? 'Fajr reminder (adhan)'
              : 'Prayer reminders (adhan)',
          channelDescription: isFajr
              ? 'Plays the Fajr adhan at dawn.'
              : 'Plays the adhan when Dhuhr, Asr, Maghrib or Isha begins.',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          sound: RawResourceAndroidNotificationSound(
            isFajr ? _adhanFajrResource : _adhanResource,
          ),
        ),
    };

    final darwin = switch (mode) {
      AdhanMode.silent => const DarwinNotificationDetails(presentSound: false),
      AdhanMode.notificationOnly => const DarwinNotificationDetails(),
      // iOS caps custom notification sounds at 30 seconds.
      AdhanMode.adhan => DarwinNotificationDetails(
          sound: isFajr ? 'adhan_fajr.aiff' : 'adhan.aiff',
        ),
    };

    return NotificationDetails(android: android, iOS: darwin);
  }

  /// Whether the OS will honour exact alarms right now.
  Future<bool> _canScheduleExact() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return true; // iOS schedules exactly.
      return await android.canScheduleExactNotifications() ?? false;
    } catch (error) {
      debugPrint('PrayerNotifications: exact-alarm check failed: $error');
      return false;
    }
  }

  Future<void> _scheduleOne({
    required int id,
    required Prayer prayer,
    required DateTime at,
    required AdhanMode adhanMode,
    required bool exact,
  }) async {
    final details = _detailsFor(adhanMode, prayer);

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: '${prayer.label} time',
        body: 'It is time for ${prayer.label}.',
        scheduledDate: tz.TZDateTime.from(at, tz.local),
        notificationDetails: details,
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } on Exception catch (error) {
      // Safety net: the permission can be revoked between the check above and
      // this call. Losing the reminder entirely would be worse than a late one.
      debugPrint('PrayerNotifications: exact alarm refused: $error');
      try {
        await _plugin.zonedSchedule(
          id: id,
          title: '${prayer.label} time',
          body: 'It is time for ${prayer.label}.',
          scheduledDate: tz.TZDateTime.from(at, tz.local),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (fallbackError) {
        debugPrint('PrayerNotifications: schedule failed: $fallbackError');
      }
    }
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (error) {
      debugPrint('PrayerNotifications: cancelAll failed: $error');
    }
  }
}
