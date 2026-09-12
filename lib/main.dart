import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'app_shell.dart';
import 'data/app_database.dart';
import 'prayer/prayer_settings.dart';
import 'services/background_refresh.dart';
import 'theme/app_theme.dart';

void main() {
  // runZonedGuarded plus the two framework hooks below mean an unexpected
  // error anywhere — widget build, platform channel, or a stray async gap —
  // is logged rather than tearing the app down.
  runZonedGuarded<void>(
    () {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint('Uncaught framework error: ${details.exception}');
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        debugPrint('Uncaught platform error: $error\n$stack');
        return true;
      };

      runApp(const QiblaApp());
    },
    (Object error, StackTrace stack) {
      debugPrint('Uncaught zone error: $error\n$stack');
    },
  );
}

class QiblaApp extends StatefulWidget {
  const QiblaApp({super.key});
  @override
  State<QiblaApp> createState() => _QiblaAppState();
}

class _QiblaAppState extends State<QiblaApp> {
  final _database = AppDatabase();
  late final Future<PrayerSettings> _settings = PrayerSettings.load(_database);
  PrayerSettings? _loaded;
  @override
  void initState() {
    super.initState();
    unawaited(BackgroundRefresh.initialize());
  }

  @override
  void dispose() {
    _loaded?.dispose();
    unawaited(
      (_loaded?.flushed ?? Future<void>.value()).then((_) => _database.close()),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<PrayerSettings>(
    future: _settings,
    builder: (context, snapshot) {
      final settings = snapshot.data;
      if (settings == null) {
        return const MaterialApp(
          home: Scaffold(body: Center(child: CircularProgressIndicator())),
        );
      }
      _loaded = settings;
      return ListenableBuilder(
        listenable: settings,
        builder: (context, _) => MaterialApp(
          title: 'Qibla Finder',
          debugShowCheckedModeBanner: false,
          locale: Locale(settings.language),
          supportedLocales: const [Locale('en'), Locale('hi'), Locale('ur')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          themeMode: switch (settings.theme) {
            'dark' => ThemeMode.dark,
            'light' => ThemeMode.light,
            _ => ThemeMode.system,
          },
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: AppShell(settings: settings, database: _database),
        ),
      );
    },
  );
}
