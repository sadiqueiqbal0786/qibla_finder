import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_finder/app_shell.dart';
import 'package:qibla_finder/data/app_database.dart';
import 'package:qibla_finder/home_screen.dart';
import 'package:qibla_finder/prayer/prayer_settings.dart';
import 'package:qibla_finder/qibla_controller.dart';
import 'package:qibla_finder/screens/location_screen.dart';
import 'package:qibla_finder/screens/prayer_times_screen.dart';
import 'package:qibla_finder/screens/settings_screen.dart';
import 'package:qibla_finder/screens/weekly_timetable_screen.dart';
import 'package:qibla_finder/screens/welcome_screen.dart';
import 'package:qibla_finder/theme/app_theme.dart';

/// Nothing a screen reader can tap may be silent.
///
/// The semantics tree is the authority. An `uiautomator` dump does not expose
/// a Flutter text field's hint, so it reports labelled fields as bare edit
/// boxes; and a tooltip on an `InputDecoration` suffix never reaches the tree
/// at all, which is how the city search button ended up tappable but unnamed.
void main() {
  /// Every node carrying a tap action, with the label a reader would speak.
  List<String> tappableLabels(WidgetTester tester) {
    final labels = <String>[];
    void walk(SemanticsNode node) {
      if (node.getSemanticsData().hasAction(SemanticsAction.tap)) {
        labels.add(node.label);
      }
      node.visitChildren((child) {
        walk(child);
        return true;
      });
    }

    // rootPipelineOwner carries no semanticsOwner in a widget test; the
    // tree hangs off the binding's own pipeline owner.
    // ignore: deprecated_member_use
    walk(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
    return labels;
  }

  Future<void> audit(
    WidgetTester tester,
    String name,
    Widget Function(QiblaController, PrayerSettings) build,
  ) async {
    final handle = tester.ensureSemantics();
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

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: AppTheme.light,
        home: build(controller, settings),
      ),
    );
    await tester.pumpAndSettle();

    final silent = tappableLabels(tester).where((l) => l.trim().isEmpty);
    expect(silent, isEmpty, reason: '$name has an unlabelled control');

    handle.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    await tester.runAsync(() async {
      await settings.flushed;
      settings.dispose();
      await db.close();
    });
  }

  testWidgets('Qibla tab names every control', (tester) async {
    await audit(
      tester,
      'Qibla',
      (c, s) => Scaffold(body: QiblaScreen(controller: c)),
    );
  });

  testWidgets('prayer times names every control', (tester) async {
    await audit(
      tester,
      'Prayer times',
      (c, s) => Scaffold(body: PrayerTimesScreen(controller: c)),
    );
  });

  testWidgets('settings names every control', (tester) async {
    await audit(
      tester,
      'Settings',
      (c, s) => SettingsScreen(settings: s, controller: c),
    );
  });

  testWidgets('city search names every control', (tester) async {
    await audit(tester, 'Location', (c, s) => LocationScreen(controller: c));
  });

  testWidgets('weekly timetable names every control', (tester) async {
    await audit(
      tester,
      'Weekly',
      (c, s) => WeeklyTimetableScreen(controller: c),
    );
  });

  testWidgets('the app bar names its icon buttons', (tester) async {
    final handle = tester.ensureSemantics();
    final db = AppDatabase(NativeDatabase.memory());
    final settings = (await tester.runAsync(() => PrayerSettings.load(db)))!;
    // Past the first run, or the shell shows the welcome screen instead.
    await tester.runAsync(() async {
      settings.completeOnboarding();
      await settings.flushed;
    });
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: AppTheme.light,
        home: AppShell(settings: settings, database: db),
      ),
    );
    await tester.pump();
    // The refresh button shows a spinner while the first fix is in flight,
    // so only the overflow is guaranteed present at this moment.
    final labels = tappableLabels(tester);
    expect(labels, contains('More'));
    expect(labels.where((l) => l.trim().isEmpty), isEmpty);

    handle.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      await settings.flushed;
      settings.dispose();
      await db.close();
    });
  });

  testWidgets('the welcome screen names every control', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: AppTheme.light,
        home: Scaffold(
          body: WelcomeScreen(onUseLocation: () {}, onChooseCity: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final labels = tappableLabels(tester);
    expect(labels, contains('Use my location'));
    expect(labels, contains('Choose a city'));
    expect(labels.where((l) => l.trim().isEmpty), isEmpty);
    handle.dispose();
  });

  testWidgets('the search field says what it is', (tester) async {
    final handle = tester.ensureSemantics();
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
    });
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: AppTheme.light,
        home: LocationScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    final field = tester.getSemantics(find.byType(TextField));
    expect(field.label, contains('Search city'));

    handle.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    await tester.runAsync(() async {
      await settings.flushed;
      settings.dispose();
      await db.close();
    });
  });
}
