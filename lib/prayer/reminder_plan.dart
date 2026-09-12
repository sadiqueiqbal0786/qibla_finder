import '../services/timezone_resolver.dart';
import 'hijri.dart';
import 'prayer_times.dart';

/// What a scheduled reminder is for, which decides its wording.
enum ReminderKind { prayer, suhoor, iftar }

class ReminderEntry {
  const ReminderEntry(
    this.id,
    this.prayer,
    this.label,
    this.at,
    this.advance, {
    this.kind = ReminderKind.prayer,
  });

  final int id;
  final Prayer prayer;
  final String label;
  final DateTime at;
  final int advance;
  final ReminderKind kind;
}

/// Stable IDs let renewal replace matching alarms without cancelling the
/// entire schedule first. Dates use the location's calendar, including DST.
///
/// Each day owns 20 id slots: two per prayer for the reminder and its advance
/// warning, then two more at the top for the fasting pair.
List<ReminderEntry> buildReminderPlan({
  required DateTime now,
  required String? zoneName,
  required PrayerTimes Function(DateTime) calculate,
  required bool Function(Prayer) enabled,
  required int days,
  int advanceMinutes = 0,
  bool fastingReminders = false,
  int suhoorAdvanceMinutes = 30,
  int hijriDayShift = 0,
}) {
  final today = TimezoneResolver.calendarDay(now, zoneName);
  final result = <ReminderEntry>[];
  final fasting = <ReminderEntry>[];
  for (var i = 0; i < days; i++) {
    final day = DateTime.utc(today.year, today.month, today.day + i);
    final times = calculate(day);
    final dayId = day.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    for (final prayer in Prayer.values.where(enabled)) {
      final instant = times[prayer];
      if (instant == null) continue;
      final id = dayId * 20 + prayer.index * 2;
      if (instant.isAfter(now)) {
        result.add(
          ReminderEntry(id, prayer, times.labelFor(prayer), instant, 0),
        );
      }
      final early = instant.subtract(Duration(minutes: advanceMinutes));
      if (advanceMinutes > 0 && early.isAfter(now)) {
        result.add(
          ReminderEntry(
            id + 1,
            prayer,
            times.labelFor(prayer),
            early,
            advanceMinutes,
          ),
        );
      }
    }

    if (!fastingReminders) continue;
    // The fast belongs to the Hijri day the *dawn* falls in, shifted by the
    // user's sighting correction.
    if (!HijriDate.fromCivil(
      day.add(Duration(days: hijriDayShift)),
    ).isRamadan) {
      continue;
    }
    final fajr = times[Prayer.fajr];
    final maghrib = times[Prayer.maghrib];
    if (fajr != null) {
      final at = fajr.subtract(Duration(minutes: suhoorAdvanceMinutes));
      if (at.isAfter(now)) {
        fasting.add(
          ReminderEntry(
            dayId * 20 + 12,
            Prayer.fajr,
            'Fajr',
            at,
            suhoorAdvanceMinutes,
            kind: ReminderKind.suhoor,
          ),
        );
      }
    }
    if (maghrib != null && maghrib.isAfter(now)) {
      fasting.add(
        ReminderEntry(
          dayId * 20 + 13,
          Prayer.maghrib,
          'Maghrib',
          maghrib,
          0,
          kind: ReminderKind.iftar,
        ),
      );
    }
  }
  // A fasting reminder landing on the same instant as a prayer reminder
  // replaces it. Otherwise Maghrib and iftar both fire at sunset, and a
  // suhoor warning set to "at Fajr only" doubles up with Fajr.
  final taken = fasting.map((e) => e.at).toSet();
  result.removeWhere(
    (e) => e.kind == ReminderKind.prayer && e.advance == 0 && taken.contains(e.at),
  );
  return result..addAll(fasting);
}
