import 'dart:async';

import 'adhan_player.dart';
import 'calculation_method.dart';
import 'prayer_times.dart';

/// Fires when a prayer time is reached while the app is open.
///
/// Scheduled notifications cover the app being closed; this covers the case
/// where the user is looking at the screen when the time arrives, which is
/// when playing the adhan is actually appropriate.
class PrayerWatcher {
  PrayerWatcher({required this.onPrayerDue});

  final void Function(Prayer prayer) onPrayerDue;

  Timer? _timer;
  PrayerTimes? _times;
  AdhanMode _mode = AdhanMode.notificationOnly;
  final Set<String> _fired = <String>{};
  bool _disposed = false;

  void update({required PrayerTimes? times, required AdhanMode mode}) {
    _mode = mode;

    // A new day's schedule means the "already fired" set is stale.
    if (_times?.date != times?.date) _fired.clear();
    _times = times;

    _timer?.cancel();
    if (times == null || _disposed) return;

    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _check());
    _check();
  }

  void _check() {
    if (_disposed) return;
    final times = _times;
    if (times == null) return;

    final now = DateTime.now();
    for (final prayer in Prayer.values) {
      if (!prayer.isPrayer) continue;
      final at = times[prayer];
      if (at == null) continue;

      final key = '${times.date.toIso8601String()}#${prayer.name}';
      if (_fired.contains(key)) continue;

      final since = now.difference(at);
      // Fire once, inside a two-minute window after the time passes, so a
      // late resume does not replay this morning's Fajr.
      if (since.isNegative || since > const Duration(minutes: 2)) continue;

      _fired.add(key);
      onPrayerDue(prayer);
      if (_mode == AdhanMode.adhan) {
        unawaited(AdhanPlayer.instance.play(prayer));
      }
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
  }
}
