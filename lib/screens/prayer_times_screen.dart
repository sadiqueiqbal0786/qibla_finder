import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_strings.dart';
import '../prayer/prayer_times.dart';
import '../prayer/ramadan.dart';
import '../qibla_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_surfaces.dart';
import '../widgets/status_view.dart';
import 'location_screen.dart';
import 'weekly_timetable_screen.dart';

/// The schedule tab.
///
/// Laid out as one focal point and a quiet list, the same way the Qibla tab
/// puts the dial first and demotes the numbers. The countdown hero is painted
/// in brand colours in both themes; everything below it follows the light or
/// dark palette.
class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key, required this.controller});
  final QiblaController controller;
  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  Timer? _ticker;
  int _dayOffset = 0;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _time(DateTime at) =>
      MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay.fromDateTime(at),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      );

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final today = controller.locationToday;
    final selected = DateTime.utc(
      today.year,
      today.month,
      today.day + _dayOffset,
    );
    final times = _dayOffset == 0
        ? controller.prayerTimes
        : controller.timesForDate(selected);

    if (times == null) return _Empty(onChoose: _location);

    var nextTimes = controller.prayerTimes!;
    var next = nextTimes.nextAfter(_now);
    if (next == null) {
      final tomorrow = controller.timesForDate(
        DateTime.utc(today.year, today.month, today.day + 1),
      );
      if (tomorrow != null) {
        nextTimes = tomorrow;
        next = tomorrow.nextAfter(_now);
      }
    }
    final current = _dayOffset == 0 ? times.currentAt(_now) : null;
    final showingToday = _dayOffset == 0;
    final ramadan = RamadanStatus.resolve(
      now: _now,
      today: controller.prayerTimes!,
      tomorrow: controller.timesForDate(
        DateTime.utc(today.year, today.month, today.day + 1),
      ),
      active: controller.ramadanActive,
      hijri: controller.hijriToday,
    );

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PlaceCard(controller: controller, onTap: _location),
                const SizedBox(height: 12),
                if (ramadan != null)
                  _RamadanHero(
                    status: ramadan,
                    now: _now,
                    format: _time,
                    wallClock: ramadan.wallClock,
                    next: next == null
                        ? null
                        : '${context.tr(nextTimes.labelFor(next.key))} '
                              '${_time(nextTimes.wallClock(next.key)!)}',
                  )
                else if (next != null)
                  _NextPrayerHero(
                    entry: next,
                    times: nextTimes,
                    now: _now,
                    previous: current?.value,
                    isTomorrow:
                        nextTimes.date.day != today.day ||
                        nextTimes.date.month != today.month,
                    format: _time,
                  ),
                const SizedBox(height: 16),
                _DayBar(
                  date: selected,
                  offset: _dayOffset,
                  onStep: (delta) => setState(() => _dayOffset += delta),
                  onToday: () => setState(() => _dayOffset = 0),
                  onWeek: _weeklyTimetable,
                ),
                const SizedBox(height: 12),
                _Schedule(
                  times: times,
                  format: _time,
                  currentPrayer: current?.key,
                  nextPrayer: showingToday && nextTimes.date == times.date
                      ? next?.key
                      : null,
                  now: _now,
                  showingToday: showingToday,
                ),
                if (times.clockDiffersFromDevice)
                  NoticeRow(
                    '${context.tr('Times follow this location’s time zone.')} '
                    '${times.zoneName?.replaceAll('_', ' ')}',
                    icon: Icons.public_rounded,
                  ),
                if (times.usedHighLatitudeRule)
                  NoticeRow(
                    context.tr(
                      'An estimate is used at this latitude. Confirm times with your mosque.',
                    ),
                    tone: NoticeTone.caution,
                  ),
                if (times.date.weekday == DateTime.friday)
                  NoticeRow(
                    context.tr(
                      'Jumma / Dhuhr marks the start of Dhuhr. Confirm Friday congregation time with your mosque.',
                    ),
                    icon: Icons.mosque_outlined,
                  ),
                const SizedBox(height: 16),
                _CalculationFooter(controller: controller, times: times),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _weeklyTimetable() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => WeeklyTimetableScreen(controller: widget.controller),
    ),
  );

  void _location() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => LocationScreen(controller: widget.controller),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onChoose});
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_searching_rounded,
            size: 44,
            color: AppColors.of(context).muted,
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('Choose a city or enable location to see prayer times.'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onChoose,
            child: Text(context.tr('Choose a city')),
          ),
        ],
      ),
    ),
  );
}

/// Where these times are for — the first thing to check when a time looks off.
class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.controller, required this.onTap});

  final QiblaController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.place_rounded, color: colors.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.placeName ?? context.tr('Current location'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      context.tr(
                        controller.manualLocation
                            ? 'Selected city'
                            : controller.positionIsStale
                            ? 'Saved location'
                            : 'Current location',
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.edit_location_alt_outlined, color: colors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// The countdown. One focal point, brand-coloured in every theme.
class _NextPrayerHero extends StatelessWidget {
  const _NextPrayerHero({
    required this.entry,
    required this.times,
    required this.now,
    required this.previous,
    required this.isTomorrow,
    required this.format,
  });

  final MapEntry<Prayer, DateTime> entry;
  final PrayerTimes times;
  final DateTime now;
  final DateTime? previous;
  final bool isTomorrow;
  final String Function(DateTime) format;

  @override
  Widget build(BuildContext context) {
    final remaining = entry.value.difference(now);
    // The bar fills across the window between the prayer that has started and
    // the one coming, so a glance says "nearly there" without reading digits.
    final total = previous == null
        ? null
        : entry.value.difference(previous!).inSeconds;
    final progress = total == null || total <= 0
        ? null
        : (1 - remaining.inSeconds / total).clamp(0.0, 1.0);

    return HeroPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_active_rounded,
                size: 15,
                color: AppBrand.mint,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  context.tr('Next prayer'),
                  style: const TextStyle(
                    color: AppBrand.mint,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              if (isTomorrow) ...[
                const SizedBox(width: 8),
                _Tag(context.tr('Tomorrow')),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Text(
                context.tr(times.labelFor(entry.key)),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                format(times.wallClock(entry.key)!),
                style: TextStyle(
                  color: QiblaPalette.onDarkMuted,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (progress != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                valueColor: const AlwaysStoppedAnimation(AppBrand.mint),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Icon(
                Icons.hourglass_bottom_rounded,
                size: 16,
                color: QiblaPalette.onDarkMuted,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${context.tr('Time remaining')}: ${_remaining(remaining)}',
                  style: TextStyle(
                    color: QiblaPalette.onDarkMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  textDirection: Directionality.of(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Shared with the Ramadan hero.
  static String _remaining(Duration duration) {
    final seconds = duration.inSeconds.clamp(0, 9999999);
    return '${(seconds ~/ 3600).toString().padLeft(2, '0')}:'
        '${(seconds ~/ 60 % 60).toString().padLeft(2, '0')}:'
        '${(seconds % 60).toString().padLeft(2, '0')}';
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: AppBrand.mint.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: AppBrand.mint,
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

/// Date stepper plus the way into the week view.
class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.date,
    required this.offset,
    required this.onStep,
    required this.onToday,
    required this.onWeek,
  });

  final DateTime date;
  final int offset;
  final ValueChanged<int> onStep;
  final VoidCallback onToday;
  final VoidCallback onWeek;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final label = DateFormat.yMMMEd(
      Localizations.localeOf(context).languageCode,
    ).format(date);

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                IconButton(
                  tooltip: context.tr('Previous day'),
                  onPressed: offset <= -30 ? null : () => onStep(-1),
                  icon: Icon(
                    Icons.chevron_left_rounded,
                    semanticLabel: context.tr('Previous day'),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (offset == 0)
                        Text(
                          context.tr('Today'),
                          style: TextStyle(fontSize: 11.5, color: colors.accent),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: context.tr('Next day'),
                  onPressed: offset >= 30 ? null : () => onStep(1),
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    semanticLabel: context.tr('Next day'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            if (offset != 0)
              TextButton.icon(
                onPressed: onToday,
                icon: const Icon(Icons.today_rounded, size: 18),
                label: Text(context.tr('Today')),
              ),
            TextButton.icon(
              onPressed: onWeek,
              icon: const Icon(Icons.calendar_view_week_outlined, size: 18),
              label: Text(context.tr('Weekly timetable')),
            ),
          ],
        ),
      ],
    );
  }
}

/// The day's times as one grouped list rather than six floating cards.
class _Schedule extends StatelessWidget {
  const _Schedule({
    required this.times,
    required this.format,
    required this.currentPrayer,
    required this.nextPrayer,
    required this.now,
    required this.showingToday,
  });

  final PrayerTimes times;
  final String Function(DateTime) format;
  final Prayer? currentPrayer;
  final Prayer? nextPrayer;
  final DateTime now;
  final bool showingToday;

  static IconData _glyph(Prayer prayer) => switch (prayer) {
    Prayer.fajr => Icons.nightlight_round,
    Prayer.sunrise => Icons.wb_twilight_rounded,
    Prayer.dhuhr => Icons.light_mode_rounded,
    Prayer.asr => Icons.wb_sunny_outlined,
    Prayer.maghrib => Icons.wb_twilight_rounded,
    Prayer.isha => Icons.dark_mode_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final visible = Prayer.values
        .where((prayer) => times[prayer] != null)
        .toList();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0) Divider(height: 1, color: colors.cardBorder),
            _Row(
              prayer: visible[i],
              times: times,
              format: format,
              isCurrent: visible[i] == currentPrayer,
              isNext: visible[i] == nextPrayer,
              // A past prayer is dimmed so the eye lands on what is live.
              isPast: showingToday && times[visible[i]]!.isBefore(now),
              glyph: _glyph(visible[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.prayer,
    required this.times,
    required this.format,
    required this.isCurrent,
    required this.isNext,
    required this.isPast,
    required this.glyph,
  });

  final Prayer prayer;
  final PrayerTimes times;
  final String Function(DateTime) format;
  final bool isCurrent;
  final bool isNext;
  final bool isPast;
  final IconData glyph;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final highlight = isCurrent || isNext;
    final faded = isPast && !isCurrent;
    final tint = isCurrent
        ? colors.accentWash
        : isNext
        ? colors.accentWash.withValues(alpha: 0.5)
        : null;

    return Container(
      color: tint,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            glyph,
            size: 19,
            color: highlight
                ? colors.accent
                : (faded ? colors.muted.withValues(alpha: 0.6) : colors.muted),
          ),
          const SizedBox(width: 14),
          // The name and the time sit at opposite ends until the text size
          // makes that impossible, at which point the time drops to its own
          // line rather than overflowing.
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 4,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      context.tr(times.labelFor(prayer)),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: highlight
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: faded
                            ? colors.muted
                            : (isCurrent ? colors.accent : null),
                      ),
                    ),
                    if (isCurrent) _Pill(context.tr('Now'), colors.accent),
                    if (isNext && !isCurrent)
                      _Pill(context.tr('Next'), colors.accent),
                    if (!prayer.isPrayer)
                      Text(
                        context.tr('Not a prayer'),
                        style: TextStyle(fontSize: 11.5, color: colors.muted),
                      ),
                  ],
                ),
                Text(
                  format(times.wallClock(prayer)!),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
                    color: faded
                        ? colors.muted
                        : (isCurrent ? colors.accent : null),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _CalculationFooter extends StatelessWidget {
  const _CalculationFooter({required this.controller, required this.times});

  final QiblaController controller;
  final PrayerTimes times;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('Calculation'),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: colors.muted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${times.method.name} · '
          '${context.tr('{madhab} Asr').replaceAll('{madhab}', context.tr(controller.settings.asrMadhab.label))} · '
          '${context.tr(controller.settings.autoMethod ? 'Automatic' : 'Manual')}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.muted,
          ),
        ),
      ],
    );
  }
}

/// The Ramadan headline.
///
/// During the month the question is never "what is the next prayer" but "when
/// do I eat", so suhoor and iftar take the focal point and the next prayer
/// drops to one quiet line.
class _RamadanHero extends StatelessWidget {
  const _RamadanHero({
    required this.status,
    required this.now,
    required this.format,
    required this.wallClock,
    required this.next,
  });

  final RamadanStatus status;
  final DateTime now;
  final String Function(DateTime) format;
  final DateTime? wallClock;
  final String? next;

  @override
  Widget build(BuildContext context) {
    final isIftar = status.milestone == FastMilestone.iftar;
    final remaining = status.at.difference(now);

    return HeroPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isIftar
                    ? Icons.dinner_dining_rounded
                    : Icons.bedtime_outlined,
                size: 15,
                color: AppBrand.mint,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  status.day == 0
                      ? context.tr('Ramadan')
                      : context
                            .tr('Ramadan {day}')
                            .replaceAll('{day}', '${status.day}'),
                  style: const TextStyle(
                    color: AppBrand.mint,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Text(
                context.tr(isIftar ? 'Iftar' : 'Suhoor ends'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              if (wallClock != null)
                Text(
                  format(wallClock!),
                  style: TextStyle(
                    color: QiblaPalette.onDarkMuted,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.hourglass_bottom_rounded,
                size: 16,
                color: QiblaPalette.onDarkMuted,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${context.tr('Time remaining')}: ${_NextPrayerHero._remaining(remaining)}',
                  style: TextStyle(
                    color: QiblaPalette.onDarkMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  textDirection: Directionality.of(context),
                ),
              ),
            ],
          ),
          if (next != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  size: 14,
                  color: QiblaPalette.onDarkMuted,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${context.tr('Next prayer')}: $next',
                    style: TextStyle(
                      color: QiblaPalette.onDarkMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
