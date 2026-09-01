import 'dart:async';

import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'data/app_database.dart';
import 'prayer/prayer_settings.dart';

/// A branded intro that also loads persisted settings off the main path.
///
/// It deliberately does **no** permission work. The previous version polled
/// `Geolocator.requestPermission()` on a 1-second repeating timer, which
/// stacked duplicate permission requests and duplicate dialogs, and hung
/// forever on a spinner whenever permission was permanently denied. All of
/// that now lives in [HomeScreen]'s state machine, which always has a way out.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _minimumDisplay = Duration(milliseconds: 1400);

  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..forward();

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    // Load settings and hold the splash for a minimum beat concurrently, so a
    // fast device still gets a stable intro and a slow one never blocks.
    final database = AppDatabase();
    final results = await Future.wait<Object?>(<Future<Object?>>[
      PrayerSettings.load(database),
      Future<Object?>.delayed(_minimumDisplay),
    ]);
    if (!mounted) return;

    final settings = results.first as PrayerSettings;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, _, _) =>
            AppShell(settings: settings, database: database),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E4C2C),
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/icon/logos__white.png',
                width: 128,
                height: 128,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.explore,
                  size: 108,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Qibla Compass',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 30),
              const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
