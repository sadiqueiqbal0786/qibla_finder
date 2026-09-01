import 'package:flutter/material.dart';

import 'data/app_database.dart';
import 'home_screen.dart';
import 'prayer/prayer_settings.dart';
import 'privacy_policy.dart';
import 'qibla_controller.dart';
import 'screens/prayer_times_screen.dart';
import 'screens/settings_screen.dart';

/// Owns the single [QiblaController] and switches between the Qibla compass
/// and the prayer schedule.
///
/// Both tabs read one location fix and one compass subscription; nothing is
/// duplicated per tab.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.settings,
    required this.database,
  });

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
    )
      ..addListener(_onChanged);
    _controller.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Coming back from system settings should just work, without the user
    // hunting for a retry button.
    if (_controller.status != QiblaStatus.ready) {
      _controller.refresh();
    }
    // And if the app sat in the background past midnight, roll the schedule.
    _controller.refreshPrayerTimesIfStale();
  }

  @override
  Widget build(BuildContext context) {
    final onQibla = _index == 0;

    return Scaffold(
      backgroundColor: onQibla ? const Color(0xFF0E2C1E) : Colors.white,
      appBar: AppBar(
        backgroundColor:
            onQibla ? const Color(0xFF0E2C1E) : const Color(0xFF156F3F),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
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
                onQibla ? 'Qibla Compass' : 'Prayer Times',
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
            tooltip: 'Refresh location',
            onPressed: _controller.isRefreshing ? null : _controller.refresh,
            icon: _controller.isRefreshing
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.2, color: Colors.white),
                  )
                : const Icon(Icons.my_location_rounded),
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          SettingsScreen(settings: widget.settings),
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
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'settings',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.tune_rounded),
                  title: Text('Prayer settings'),
                ),
              ),
              PopupMenuItem<String>(
                value: 'privacy',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.privacy_tip_outlined),
                  title: Text('Privacy policy'),
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
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Qibla',
          ),
          NavigationDestination(
            icon: Icon(Icons.access_time_outlined),
            selectedIcon: Icon(Icons.access_time_filled),
            label: 'Prayer Times',
          ),
        ],
      ),
    );
  }
}
