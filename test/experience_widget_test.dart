import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_finder/data/app_database.dart';
import 'package:qibla_finder/home_screen.dart';
import 'package:qibla_finder/prayer/prayer_settings.dart';
import 'package:qibla_finder/prayer/prayer_times.dart';
import 'package:qibla_finder/qibla_controller.dart';
import 'package:qibla_finder/screens/prayer_times_screen.dart';
import 'package:qibla_finder/screens/settings_screen.dart';
import 'package:qibla_finder/screens/weekly_timetable_screen.dart';
import 'package:qibla_finder/theme/app_theme.dart';

void main() {
  for (final language in ['en', 'hi', 'ur']) {
    testWidgets('$language screens fit narrow display at 200 percent text', (
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
        controller = QiblaController(
          settings: settings,
          database: db,
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
      Widget host(Widget child) => MaterialApp(
        locale: Locale(language),
        supportedLocales: const [Locale('en'), Locale('hi'), Locale('ur')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: child,
      );
      await tester.pumpWidget(
        host(Scaffold(body: QiblaScreen(controller: controller))),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        host(Scaffold(body: PrayerTimesScreen(controller: controller))),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (language == 'ur') {
        expect(
          Directionality.of(tester.element(find.byType(PrayerTimesScreen))),
          TextDirection.rtl,
        );
      }
      await tester.pumpWidget(
        host(WeeklyTimetableScreen(controller: controller)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final table = tester.widget<Table>(find.byType(Table));
      // A header row plus one row per day, each with a label and six times.
      expect(table.children, hasLength(WeeklyTimetableScreen.days + 1));
      for (final row in table.children) {
        expect(row.children, hasLength(Prayer.values.length + 1));
      }
      // Mumbai resolves every prayer, so no cell falls back to a dash.
      expect(find.text('\u2014'), findsNothing);
      await tester.pumpWidget(
        host(SettingsScreen(settings: settings, controller: controller)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
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
