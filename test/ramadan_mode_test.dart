import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_finder/data/app_database.dart';
import 'package:qibla_finder/prayer/prayer_settings.dart';
import 'package:qibla_finder/qibla_controller.dart';

/// The headline must be confined to Ramadan in every mode.
///
/// An earlier cut offered "always on", which left the fasting headline up in
/// every other month of the year.
void main() {
  Future<({QiblaController controller, PrayerSettings settings, AppDatabase db})>
  open(DateTime now) async {
    final db = AppDatabase(NativeDatabase.memory());
    final settings = await PrayerSettings.load(db);
    final controller = QiblaController(
      settings: settings,
      database: db,
      clock: () => now,
      syncOverride: () async {},
    );
    await controller.selectLocation(
      label: 'Mumbai',
      latitude: 19.076,
      longitude: 72.8777,
      country: 'IN',
    );
    return (controller: controller, settings: settings, db: db);
  }

  Future<void> close(
    ({QiblaController controller, PrayerSettings settings, AppDatabase db}) it,
  ) async {
    it.controller.dispose();
    await it.settings.flushed;
    it.settings.dispose();
    await it.db.close();
  }

  test('is off outside Ramadan in every mode', () async {
    // 12 Sep 2026 is in Rabi al-Awwal, half a year from Ramadan.
    final it = await open(DateTime.utc(2026, 9, 12, 13, 0));
    for (final mode in ['auto', 'earlier', 'later', 'off']) {
      it.settings.setRamadanMode(mode);
      expect(it.controller.ramadanActive, isFalse, reason: 'mode $mode');
    }
    await close(it);
  });

  test('is on inside Ramadan unless switched off', () async {
    final it = await open(DateTime.utc(2026, 2, 20, 13, 0));
    for (final mode in ['auto', 'earlier', 'later']) {
      it.settings.setRamadanMode(mode);
      expect(it.controller.ramadanActive, isTrue, reason: 'mode $mode');
    }
    it.settings.setRamadanMode('off');
    expect(it.controller.ramadanActive, isFalse);
    await close(it);
  });

  test('the shift moves the first and last day by one', () async {
    // 1 Ramadan 1447 is calculated as 18 Feb 2026, so the day before is
    // Ramadan only for someone whose mosque started early.
    final eve = await open(DateTime.utc(2026, 2, 17, 13, 0));
    eve.settings.setRamadanMode('auto');
    expect(eve.controller.ramadanActive, isFalse);
    eve.settings.setRamadanMode('earlier');
    expect(eve.controller.ramadanActive, isTrue);
    expect(eve.controller.hijriToday.day, 1);
    await close(eve);

    // And the calculated first day is not yet Ramadan for someone late.
    final first = await open(DateTime.utc(2026, 2, 18, 13, 0));
    first.settings.setRamadanMode('later');
    expect(first.controller.ramadanActive, isFalse);
    await close(first);
  });

  test('an unknown stored mode falls back to automatic', () async {
    final it = await open(DateTime.utc(2026, 2, 20, 13, 0));
    it.settings.setRamadanMode('always');
    expect(it.settings.ramadanMode, 'auto');
    expect(it.controller.ramadanActive, isTrue);
    await close(it);
  });
}
