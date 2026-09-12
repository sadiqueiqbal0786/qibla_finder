import 'hijri.dart';
import 'prayer_times.dart';

/// Which end of the fast the user is waiting for.
enum FastMilestone { suhoor, iftar }

/// The Ramadan headline: one milestone, its instant, and the day number.
class RamadanStatus {
  const RamadanStatus({
    required this.milestone,
    required this.at,
    required this.wallClock,
    required this.prayer,
    required this.day,
  });

  final FastMilestone milestone;

  /// Absolute instant, so countdowns stay correct when the device clock is
  /// not in the prayer location's zone.
  final DateTime at;

  /// The same moment as [at] in the prayer location's wall clock, taken from
  /// the day that actually supplied it. Reading it off today's schedule shows
  /// today's Fajr after Maghrib has passed, which is minutes adrift.
  final DateTime? wallClock;
  final Prayer prayer;
  final int day;

  /// Works out what the user is waiting for right now.
  ///
  /// Before dawn the fast has not started, so suhoor is still ending; between
  /// Fajr and Maghrib the wait is for iftar; after Maghrib it is the next
  /// day's suhoor, which is why [tomorrow] is needed.
  static RamadanStatus? resolve({
    required DateTime now,
    required PrayerTimes today,
    PrayerTimes? tomorrow,
    required bool active,
    required HijriDate hijri,
  }) {
    if (!active) return null;
    final fajr = today[Prayer.fajr];
    final maghrib = today[Prayer.maghrib];
    if (fajr == null || maghrib == null) return null;
    final day = hijri.isRamadan ? hijri.day : 0;

    if (now.isBefore(fajr)) {
      return RamadanStatus(
        milestone: FastMilestone.suhoor,
        at: fajr,
        wallClock: today.wallClock(Prayer.fajr),
        prayer: Prayer.fajr,
        day: day,
      );
    }
    if (now.isBefore(maghrib)) {
      return RamadanStatus(
        milestone: FastMilestone.iftar,
        at: maghrib,
        wallClock: today.wallClock(Prayer.maghrib),
        prayer: Prayer.maghrib,
        day: day,
      );
    }
    final next = tomorrow?[Prayer.fajr];
    if (next == null) return null;
    return RamadanStatus(
      milestone: FastMilestone.suhoor,
      at: next,
      wallClock: tomorrow!.wallClock(Prayer.fajr),
      prayer: Prayer.fajr,
      // The fast that this suhoor opens belongs to the following day.
      day: day == 0 ? 0 : day + 1,
    );
  }
}
