import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:workmanager/workmanager.dart';
import '../data/app_database.dart';
import '../l10n/app_strings.dart';
import '../prayer/prayer_notifications.dart';
import '../prayer/prayer_settings.dart';
import '../prayer/prayer_times.dart';
import '../qibla_logic.dart';
import 'timezone_resolver.dart';
import 'refresh_lease.dart';

@pragma('vm:entry-point')
void prayerBackgroundDispatcher() {
  Workmanager().executeTask((task, input) async {
    WidgetsFlutterBinding.ensureInitialized();
    final db = AppDatabase();
    try {
      await BackgroundRefresh.refresh(db, propagateErrors: true);
      return true;
    } catch (error) {
      debugPrint('Background prayer renewal: $error');
      return false;
    } finally {
      await db.close();
    }
  });
}

class BackgroundRefresh {
  static Future<void> _queue = Future<void>.value();
  static Future<void> initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await Workmanager().initialize(prayerBackgroundDispatcher);
      await Workmanager().registerPeriodicTask(
        'prayer-renewal',
        'prayer-renewal',
        frequency: const Duration(hours: 12),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
    } catch (error) {
      debugPrint('Could not register prayer renewal: $error');
    }
  }

  static Future<void> refresh(
    AppDatabase db, {
    bool propagateErrors = false,
    bool force = false,
  }) {
    final operation = _queue.then(
      (_) => withRefreshLease(db, () => _refresh(db, force)),
    );
    _queue = operation.catchError((Object error) {
      debugPrint('Prayer refresh: $error');
    });
    return propagateErrors ? operation : _queue;
  }

  static Future<void> _refresh(AppDatabase db, bool force) async {
    final settings = await PrayerSettings.load(db);
    try {
      final place = await db.lastKnownLocation();
      await PrayerNotifications.instance.initialize();
      if (!settings.remindersEnabled) {
        await PrayerNotifications.instance.cancelAll();
      }
      if (place == null) return;
      final stored = await db.loadPreferences();
      final notificationStatus = await PrayerNotifications.instance.status();
      final signature = jsonEncode([
        notificationStatus.allowed,
        notificationStatus.exact,
        place.latitude,
        place.longitude,
        place.label,
        settings.method.id,
        settings.asrMadhab.name,
        settings.highLatitudeRule.name,
        settings.remindersEnabled,
        settings.advanceMinutes,
        settings.adhanMode.name,
        settings.language,
        Prayer.values.map(settings.prayerEnabled).toList(),
        Prayer.values.map(settings.offsetFor).toList(),
        settings.ramadanReminders,
        settings.suhoorAdvanceMinutes,
        settings.ramadanMode,
      ]);
      final refreshed = DateTime.tryParse(stored['schedule.refreshed'] ?? '');
      if (!force &&
          stored['schedule.signature'] == signature &&
          refreshed != null &&
          DateTime.now().difference(refreshed).inHours >= 0 &&
          DateTime.now().difference(refreshed).inHours < 6) {
        return;
      }
      if (settings.remindersEnabled) {
        await PrayerNotifications.instance.reschedule(
          latitude: place.latitude,
          longitude: place.longitude,
          settings: settings,
        );
        await db.putPreference(
          'reminders.renewed_at',
          DateTime.now().toUtc().toIso8601String(),
        );
      }
      if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
        await _recordRefresh(db, signature);
        return;
      }
      final resolver = TimezoneResolver();
      final zone = resolver.resolve(
        latitude: place.latitude,
        longitude: place.longitude,
      );
      final today = TimezoneResolver.calendarDay(DateTime.now(), zone?.name);
      final calculator = PrayerCalculator(
        method: settings.method,
        asrMadhab: settings.asrMadhab,
        highLatitudeRule: settings.highLatitudeRule,
        offsets: settings.offsets,
      );
      final entries = <Map<String, Object>>[];
      for (var i = 0; i < 30; i++) {
        final day = DateTime.utc(today.year, today.month, today.day + i);
        final on = resolver.resolve(
          latitude: place.latitude,
          longitude: place.longitude,
          date: day,
        );
        final times = calculator.forDate(
          date: day,
          latitude: place.latitude,
          longitude: place.longitude,
          utcOffsetHours: on?.offsetHours,
          zoneName: on?.name,
        );
        for (final prayer in Prayer.values.where((p) => p.isPrayer)) {
          final at = times[prayer];
          if (at != null) {
            entries.add({
              'name': AppStrings.translate(
                times.labelFor(prayer),
                settings.language,
              ),
              'at': at.millisecondsSinceEpoch,
            });
          }
        }
      }
      await HomeWidget.saveWidgetData<String>(
        'widget_title',
        AppStrings.translate('Next prayer', settings.language),
      );
      await HomeWidget.saveWidgetData<String>(
        'widget_empty',
        AppStrings.translate(
          'Choose a city or enable location to see prayer times.',
          settings.language,
        ),
      );
      await HomeWidget.saveWidgetData<String>(
        'prayer_entries',
        jsonEncode(entries),
      );
      await HomeWidget.saveWidgetData<String>('prayer_place', place.label);
      // The widget represents both halves of the app, so it carries the Qibla
      // bearing alongside the schedule.
      final bearing = QiblaDirection.qiblaBearing(
        place.latitude,
        place.longitude,
      );
      await HomeWidget.saveWidgetData<String>(
        'qibla_bearing',
        bearing == null ? '' : bearing.toStringAsFixed(0),
      );
      await HomeWidget.saveWidgetData<String>(
        'widget_qibla_label',
        AppStrings.translate('Qibla', settings.language),
      );
      await HomeWidget.saveWidgetData<String>(
        'widget_now_label',
        AppStrings.translate('Now', settings.language),
      );
      await HomeWidget.saveWidgetData<String>(
        'widget_refresh_label',
        AppStrings.translate('Refresh', settings.language),
      );
      await HomeWidget.saveWidgetData<String>('prayer_zone', zone?.name ?? '');
      await HomeWidget.saveWidgetData<String>(
        'widget_language',
        settings.language,
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: 'com.example.qibla_finder.PrayerWidgetProvider',
      );
      await _recordRefresh(db, signature);
    } finally {
      settings.dispose();
    }
  }

  static Future<void> _recordRefresh(AppDatabase db, String signature) async {
    await db.putPreference('schedule.signature', signature);
    await db.putPreference(
      'schedule.refreshed',
      DateTime.now().toUtc().toIso8601String(),
    );
  }
}
