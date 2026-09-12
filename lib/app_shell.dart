import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'l10n/app_strings.dart';
import 'screens/location_screen.dart';

import 'data/app_database.dart';
import 'home_screen.dart';
import 'prayer/prayer_settings.dart';
import 'privacy_policy.dart';
import 'qibla_controller.dart';
import 'screens/prayer_times_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/welcome_screen.dart';
import 'theme/app_theme.dart';

/// Owns the single [QiblaController] and switches between the Qibla compass
/// and the prayer schedule.
///
/// Both tabs read one location fix and one compass subscription; nothing is
/// duplicated per tab.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.settings, required this.database});

  final PrayerSettings settings;
  final AppDatabase database;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  late final QiblaController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = QiblaController(
      settings: widget.settings,
      database: widget.database,
    )..addListener(_onChanged);
    _controller.compass.aligned.addListener(_onAligned);
    _controller.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onChanged);
    _controller.compass.aligned.removeListener(_onAligned);
    _controller.dispose();
    super.dispose();
  }

  void _onAligned() {
    if (_index == 0 &&
        _controller.compass.aligned.value &&
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      HapticFeedback.lightImpact();
    }
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _controller.compass.stop();
      return;
    }
    if (_index == 0) _controller.compass.start();
    // Coming back from system settings should just work, without the user
    // hunting for a retry button.
    if (_controller.status != QiblaStatus.ready) {
      _controller.refresh();
    }
    // And if the app sat in the background past midnight, roll the schedule.
    _controller.refreshPrayerTimesIfStale();
    _controller.renewReminders();
  }

  /// Consent first, then the fix. Both routes end the first run, so the
  /// screen never reappears.
  void _acceptLocation() {
    widget.settings.completeOnboarding();
    _controller.refresh();
  }

  void _chooseCity() {
    widget.settings.completeOnboarding();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LocationScreen(controller: _controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.settings.onboarded) {
      return Scaffold(
        body: WelcomeScreen(
          onUseLocation: _acceptLocation,
          onChooseCity: _chooseCity,
        ),
      );
    }
    final onQibla = _index == 0;

    return Scaffold(
      backgroundColor: onQibla
          ? AppBrand.inkSoft
          : Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            Image.asset(
              'assets/icon/icon_monochrome.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.explore, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.tr(onQibla ? 'Qibla Compass' : 'Prayer Times'),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: context.tr('Refresh location'),
            onPressed: _controller.isRefreshing ? null : _controller.refresh,
            icon: _controller.isRefreshing
                ? Semantics(
                    label: context.tr('Finding your location…'),
                    child: const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Icon(
                    Icons.my_location_rounded,
                    semanticLabel: context.tr('Refresh location'),
                  ),
          ),
          PopupMenuButton<String>(
            tooltip: context.tr('More'),
            icon: Icon(
              Icons.more_vert_rounded,
              semanticLabel: context.tr('More'),
            ),
            onSelected: (value) {
              switch (value) {
                case 'location':
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => LocationScreen(controller: _controller),
                    ),
                  );
                case 'settings':
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SettingsScreen(
                        settings: widget.settings,
                        controller: _controller,
                      ),
                    ),
                  );
                case 'privacy':
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PrivacyPolicyScreen(),
                    ),
                  );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'location',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.place_outlined),
                  title: Text(context.tr('Choose a city')),
                ),
              ),
              PopupMenuItem<String>(
                value: 'settings',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.tune_rounded),
                  title: Text(context.tr('Settings')),
                ),
              ),
              PopupMenuItem<String>(
                value: 'privacy',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.privacy_tip_outlined),
                  title: Text(context.tr('Privacy policy')),
                ),
              ),
            ],
          ),
        ],
      ),
      // IndexedStack keeps both tabs alive, so switching back to the compass
      // does not restart the sensor or re-request a location fix.
      body: IndexedStack(
        index: _index,
        children: [
          QiblaScreen(controller: _controller),
          PrayerTimesScreen(controller: _controller),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() => _index = value);
          if (value == 0) {
            _controller.compass.start();
          } else {
            _controller.compass.stop();
          }
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: context.tr('Qibla'),
          ),
          NavigationDestination(
            icon: Icon(Icons.access_time_outlined),
            selectedIcon: Icon(Icons.access_time_filled),
            label: context.tr('Prayer Times'),
          ),
        ],
      ),
    );
  }
}
