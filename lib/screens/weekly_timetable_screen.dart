import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_strings.dart';
import '../prayer/prayer_times.dart';
import '../qibla_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_surfaces.dart';
import '../widgets/status_view.dart';

/// Seven days at a glance.
///
/// The daily screen answers "what is next"; this one answers "when do I have
/// to be somewhere this week". Columns are the fixed [PrayerLabel.label]s
/// rather than [PrayerTimes.labelFor], so the Friday Dhuhr column keeps its
/// heading and the Jumma distinction is carried by the row marker and the
/// notice underneath.
class WeeklyTimetableScreen extends StatelessWidget {
  const WeeklyTimetableScreen({super.key, required this.controller});

  final QiblaController controller;

  static const int days = 7;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => _build(context),
  );

  // A location refresh or a settings change while this route is open must
  // reach the grid; it is pushed above the shell that normally rebuilds.
  Widget _build(BuildContext context) {
    final today = controller.locationToday;
    final schedule = <PrayerTimes>[];
    for (var i = 0; i < days; i++) {
      final times = controller.timesForDate(
        DateTime.utc(today.year, today.month, today.day + i),
      );
      if (times != null) schedule.add(times);
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Weekly timetable'))),
      body: schedule.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  context.tr(
                    'Choose a city or enable location to see prayer times.',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                ContentWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.place_rounded,
                            size: 18,
                            color: AppColors.of(context).accent,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              controller.placeName ??
                                  context.tr('Current location'),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Card(
                        clipBehavior: Clip.antiAlias,
                        // Seven prayer columns cannot fit a phone at large
                        // text sizes, so the grid scrolls sideways instead of
                        // shrinking the type or clipping a column.
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: _Grid(schedule: schedule, today: today),
                        ),
                      ),
                      if (schedule.any(
                        (day) => day.date.weekday == DateTime.friday,
                      ))
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: NoticeRow(
                            context.tr(
                              'Jumma / Dhuhr marks the start of Dhuhr. Confirm Friday congregation time with your mosque.',
                            ),
                            icon: Icons.mosque_outlined,
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

class _Grid extends StatelessWidget {
  const _Grid({required this.schedule, required this.today});

  final List<PrayerTimes> schedule;
  final DateTime today;

  String _time(BuildContext context, DateTime at) =>
      MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay.fromDateTime(at),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      );

  bool _isToday(DateTime date) =>
      date.year == today.year &&
      date.month == today.month &&
      date.day == today.day;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final labels = Theme.of(context).textTheme.labelLarge;
    final format = DateFormat.MMMEd(
      Localizations.localeOf(context).languageCode,
    );

    return Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          children: [
            _cell(context.tr('Day'), style: labels),
            for (final prayer in Prayer.values)
              _cell(context.tr(prayer.label), style: labels),
          ],
        ),
        for (final day in schedule)
          TableRow(
            decoration: BoxDecoration(
              color: _isToday(day.date)
                  ? AppColors.of(context).accent.withValues(alpha: 0.16)
                  : null,
              border: Border(
                top: BorderSide(color: AppColors.of(context).cardBorder),
              ),
            ),
            children: [
              _cell(
                format.format(day.date),
                style: labels?.copyWith(
                  fontWeight: _isToday(day.date) ? FontWeight.bold : null,
                  color: _isToday(day.date) ? colors.accent : null,
                ),
              ),
              for (final prayer in Prayer.values)
                _cell(
                  day.wallClock(prayer) == null
                      ? '—'
                      : _time(context, day.wallClock(prayer)!),
                ),
            ],
          ),
      ],
    );
  }

  Widget _cell(String text, {TextStyle? style}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Text(text, style: style, softWrap: false),
  );
}
