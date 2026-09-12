import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_finder/data/app_database.dart';
import 'package:qibla_finder/prayer/prayer_settings.dart';
import 'package:qibla_finder/qibla_controller.dart';
import 'package:qibla_finder/screens/prayer_times_screen.dart';
import 'package:qibla_finder/theme/app_theme.dart';

/// The Ramadan headline replaces the hero, so it needs the same narrow-screen
/// and large-text check the other screens get.
void main() {
  for (final language in ['en', 'hi', 'ur']) {
    testWidgets('$language Ramadan headline fits a narrow display', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = AppDatabase(NativeDatabase.memory());
      late PrayerSettings settings;
      late QiblaController controller;
      await tester.runAsync(() async {
        settings = await PrayerSettings.load(db);
        // A real Ramadan day rather than a forced flag, so this exercises the
        // path a user actually gets. 20 Feb 2026 is 3 Ramadan 1447.
        controller = QiblaController(
          settings: settings,
          database: db,
          clock: () => DateTime.utc(2026, 2, 20, 13, 0),
          syncOverride: () async {},
        );
        await controller.selectLocation(
          label: 'Mumbai',
          latitude: 19.076,
          longitude: 72.8777,
          country: 'IN',
        );
        await settings.flushed;
      });

      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(language),
          supportedLocales: const [Locale('en'), Locale('hi'), Locale('ur')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: AppTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(body: PrayerTimesScreen(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(controller.ramadanActive, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      await tester.runAsync(() async {
        await settings.flushed;
        settings.dispose();
        await db.close();
      });
    });
  }
}
