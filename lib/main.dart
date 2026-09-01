import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'splash_screen.dart';

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

class QiblaApp extends StatelessWidget {
  const QiblaApp({super.key});

  static const Color seed = Color(0xFF156F3F);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qibla Compass',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: seed,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      // Keep the compass legible regardless of the system font-scale setting.
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.3,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashScreen(),
    );
  }
}
