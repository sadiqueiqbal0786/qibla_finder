import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../prayer/adhan_player.dart';
import '../prayer/prayer_times.dart';
import '../qibla_controller.dart';

/// Today's schedule with a live countdown to the next prayer.
class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key, required this.controller});

  final QiblaController controller;

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  static final DateFormat _time = DateFormat.jm();

  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    // One second is enough for a mm:ss countdown, and this rebuilds only the
    // schedule subtree, not the compass.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ticker = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final times = widget.controller.prayerTimes;

    if (times == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Prayer times will appear once your location is available.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.black54),
          ),
        ),
      );
    }

    final next = times.nextAfter(_now);
    final current = times.currentAt(_now);

    return RefreshIndicator(
      color: const Color(0xFF156F3F),
      onRefresh: widget.controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: AdhanPlayer.instance.playing,
            builder: (context, playing, _) {
              if (!playing) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Material(
                  color: const Color(0xFF156F3F),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: AdhanPlayer.instance.stop,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Icon(Icons.volume_up_rounded, color: Colors.white),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Adhan playing',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text('STOP',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.8)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          _NextPrayerCard(next: next, now: _now, times: times),
          const SizedBox(height: 18),
          if (times.clockDiffersFromDevice) ...[
            _Notice(
              icon: Icons.public_rounded,
              text: 'Shown in ${times.zoneName!.replaceAll('_', ' ')} '
                  '(${_offsetLabel(times.timezoneOffsetHours)}), the time zone '
                  'for this location. Your device clock is set to '
                  '${_offsetLabel(times.deviceOffsetHours)}.',
            ),
            const SizedBox(height: 14),
          ],
          if (times.usedHighLatitudeRule) ...[
            _Notice(
              icon: Icons.info_outline_rounded,
              text: 'At this latitude the sun does not reach the Fajr or Isha '
                  'angle, so the "${times.method.name}" angles were replaced by '
                  'the ${widget.controller.settings.highLatitudeRule.label} '
                  'rule. Check with your local mosque.',
            ),
            const SizedBox(height: 14),
          ],
          for (final prayer in Prayer.values)
            if (times[prayer] != null)
              _PrayerRow(
                prayer: prayer,
                time: times[prayer]!,
                isNext: next?.key == prayer,
                isCurrent: current?.key == prayer && next?.key != prayer,
                label: _time.format(times.wallClock(prayer)!),
              ),
          const SizedBox(height: 20),
          _MethodFooter(controller: widget.controller),
        ],
      ),
    );
  }
}

String _offsetLabel(double hours) {
  final sign = hours < 0 ? '-' : '+';
  final total = (hours.abs() * 60).round();
  final h = (total ~/ 60).toString().padLeft(2, '0');
  final m = (total % 60).toString().padLeft(2, '0');
  return 'UTC$sign$h:$m';
}

class _NextPrayerCard extends StatelessWidget {
  const _NextPrayerCard({
    required this.next,
    required this.now,
    required this.times,
  });

  final MapEntry<Prayer, DateTime>? next;
  final DateTime now;
  final PrayerTimes times;

  @override
  Widget build(BuildContext context) {
    final entry = next;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B8A5A), Color(0xFF0E4C2C)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry == null ? 'ALL PRAYERS COMPLETE' : 'NEXT PRAYER',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (entry == null)
            const Text(
              'Fajr tomorrow',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  entry.key.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat.jm().format(times.wallClock(entry.key)!),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'in ${_formatRemaining(entry.value.difference(now))}',
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatRemaining(Duration d) {
    if (d.isNegative) return 'now';
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }
}

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.prayer,
    required this.time,
    required this.isNext,
    required this.isCurrent,
    required this.label,
  });

  final Prayer prayer;
  final DateTime time;
  final bool isNext;
  final bool isCurrent;
  final String label;

  @override
  Widget build(BuildContext context) {
    final highlighted = isNext || isCurrent;
    final muted = !prayer.isPrayer;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0x141B8A5A) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlighted ? const Color(0xFF1B8A5A) : Colors.black12,
          width: highlighted ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _iconFor(prayer),
            size: 20,
            color: muted
                ? Colors.black38
                : (highlighted ? const Color(0xFF156F3F) : Colors.black54),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              prayer.label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: highlighted ? FontWeight.bold : FontWeight.w500,
                color: muted ? Colors.black45 : Colors.black87,
              ),
            ),
          ),
          if (isNext)
            Container(
              margin: const EdgeInsets.only(right: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF1B8A5A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'NEXT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: highlighted ? FontWeight.bold : FontWeight.w500,
              color: muted ? Colors.black45 : Colors.black87,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(Prayer prayer) => switch (prayer) {
        Prayer.fajr => Icons.nightlight_round,
        Prayer.sunrise => Icons.wb_twilight_rounded,
        Prayer.dhuhr => Icons.wb_sunny_rounded,
        Prayer.asr => Icons.wb_cloudy_rounded,
        Prayer.maghrib => Icons.wb_twilight_rounded,
        Prayer.isha => Icons.dark_mode_rounded,
      };
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    const tint = Color(0xFF156F3F);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: tint),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 13, height: 1.4, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodFooter extends StatelessWidget {
  const _MethodFooter({required this.controller});

  final QiblaController controller;

  @override
  Widget build(BuildContext context) {
    final settings = controller.settings;
    final auto = settings.autoMethod;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Calculation',
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600,
            color: Colors.black.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${settings.method.name} · ${settings.asrMadhab.label} Asr'
          '${auto ? ' · auto-selected' : ''}',
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: Colors.black.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
