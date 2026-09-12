import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_finder/app_shell.dart';
import 'package:qibla_finder/data/app_database.dart';
import 'package:qibla_finder/prayer/prayer_settings.dart';
import 'package:qibla_finder/qibla_controller.dart';
import 'package:qibla_finder/screens/welcome_screen.dart';
import 'package:qibla_finder/services/location_service.dart';
import 'package:qibla_finder/theme/app_theme.dart';

/// Counts location requests so a premature system prompt is detectable.
class _CountingLocation extends LocationService {
  int calls = 0;

  @override
  Future<LocationResult> getPosition() async {
    calls++;
    return const LocationResult.failure(LocationFailure.timeout);
  }
}

void main() {
  test('a fresh install has not been onboarded', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final settings = await PrayerSettings.load(db);
    expect(settings.onboarded, isFalse);
    settings.dispose();
    await db.close();
  });

  test('nothing asks for a location before the user has been told why',
      () async {
    // Android only offers the permission dialog once. Asking cold, before any
    // explanation, is the failure this screen exists to prevent.
    final db = AppDatabase(NativeDatabase.memory());
    final settings = await PrayerSettings.load(db);
    final location = _CountingLocation();
    final controller = QiblaController(
      settings: settings,
      database: db,
      locationService: location,
      syncOverride: () async {},
    );

    await controller.initialize();
    expect(location.calls, 0, reason: 'asked before consent');

    settings.completeOnboarding();
    await controller.refresh();
    expect(location.calls, 1);

    controller.dispose();
    await settings.flushed;
    settings.dispose();
    await db.close();
  });

  test('onboarding survives a restart', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final first = await PrayerSettings.load(db);
    first.completeOnboarding();
    await first.flushed;
    first.dispose();

    final second = await PrayerSettings.load(db);
    expect(second.onboarded, isTrue);
    second.dispose();
    await db.close();
  });

  testWidgets('the shell shows the welcome screen only on a first run', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    final settings = (await tester.runAsync(() => PrayerSettings.load(db)))!;

    Widget host() => MaterialApp(
      locale: const Locale('en'),
      supportedLocales: const [Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.light,
      home: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => AppShell(settings: settings, database: db),
      ),
    );

    await tester.pumpWidget(host());
    await tester.pump();
    expect(find.byType(WelcomeScreen), findsOneWidget);
    // Both routes are offered, and neither is styled as the lesser one.
    expect(find.text('Use my location'), findsOneWidget);
    expect(find.text('Choose a city'), findsOneWidget);

    await tester.runAsync(() async {
      settings.completeOnboarding();
      await settings.flushed;
    });
    await tester.pump();
    expect(find.byType(WelcomeScreen), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      await settings.flushed;
      settings.dispose();
      await db.close();
    });
  });

  testWidgets('both routes off the welcome screen are wired', (tester) async {
    // Driven through the screen rather than the shell: tapping the city
    // button in the shell pushes a route whose own async work never settles
    // under fake time, which hangs the pump rather than failing.
    var usedLocation = 0;
    var choseCity = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: AppTheme.light,
        home: Scaffold(
          body: WelcomeScreen(
            onUseLocation: () => usedLocation++,
            onChooseCity: () => choseCity++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Use my location'));
    await tester.pump();
    expect(usedLocation, 1);
    expect(choseCity, 0);

    await tester.tap(find.text('Choose a city'));
    await tester.pump();
    expect(choseCity, 1);
  });

  testWidgets('the welcome screen fits a narrow display at 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final language in ['en', 'hi', 'ur']) {
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
          home: Scaffold(
            body: WelcomeScreen(onUseLocation: () {}, onChooseCity: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: language);
    }
  });
}
