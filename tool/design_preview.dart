// Dev tool, not a test of behaviour. Renders the themed screens to PNGs so a
// design change can be looked at rather than guessed at:
//
//   flutter test tool/design_preview.dart --update-goldens
//
// Output lands in docs/previews/. Text renders as blocks because the test
// environment ships no font; the point is layout, colour and spacing.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_finder/data/app_database.dart';
import 'package:qibla_finder/prayer/prayer_settings.dart';
import 'package:qibla_finder/qibla_controller.dart';
import 'package:qibla_finder/screens/prayer_times_screen.dart';
import 'package:qibla_finder/screens/settings_screen.dart';
import 'package:qibla_finder/screens/weekly_timetable_screen.dart';
import 'package:qibla_finder/theme/app_theme.dart';

void main() {
  for (final (name, theme) in [('light', AppTheme.light), ('dark', AppTheme.dark)]) {
    testWidgets('render $name', (tester) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = AppDatabase(NativeDatabase.memory());
      late PrayerSettings settings;
      late QiblaController controller;
      await tester.runAsync(() async {
        settings = await PrayerSettings.load(db);
        controller = QiblaController(
          settings: settings, database: db, syncOverride: () async {});
        await controller.selectLocation(
          label: 'Mumbai', latitude: 19.076, longitude: 72.8777, country: 'IN');
        await settings.flushed;
      });
      Widget host(Widget child) => MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: theme,
        home: child,
      );
      await tester.pumpWidget(host(Scaffold(
        appBar: AppBar(title: const Text('Prayer Times')),
        body: PrayerTimesScreen(controller: controller))));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('../docs/previews/prayer_$name.png'));

      await tester.pumpWidget(
          host(SettingsScreen(settings: settings, controller: controller)));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('../docs/previews/settings_$name.png'));

      await tester.pumpWidget(host(WeeklyTimetableScreen(controller: controller)));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('../docs/previews/weekly_$name.png'));

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
