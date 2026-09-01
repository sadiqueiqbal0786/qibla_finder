import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Typed key/value store for user preferences.
///
/// A table rather than a map file, so preferences live in the same transaction
/// boundary and migration story as everything else.
class Preferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// Places the user has pinned, and the current auto-detected one.
///
/// This is the storage travel mode needs: a Qibla and a prayer schedule for a
/// city you are not standing in requires that city's own coordinates and UTC
/// offset, not the phone's.
class SavedLocations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get label => text().withLength(min: 1, max: 120)();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get isoCountryCode => text().nullable()();

  /// UTC offset in hours for this place, so prayer times can be rendered in
  /// local-to-the-place time rather than device time.
  RealColumn get utcOffsetHours => real().nullable()();

  /// True for the row tracking the device's current position.
  BoolColumn get isCurrent => boolean().withDefault(const Constant(false))();

  DateTimeColumn get savedAt =>
      dateTime().withDefault(currentDateAndTime)();
}

/// A record of prayers the user marked as performed.
///
/// Kept as one row per prayer per day so streaks and history can be derived
/// later without a schema change.
class PrayerRecords extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Midnight of the day the prayer belongs to.
  DateTimeColumn get day => dateTime()();

  /// [Prayer] enum name, stored as text so reordering the enum is harmless.
  TextColumn get prayer => text().withLength(min: 1, max: 20)();

  DateTimeColumn get markedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {day, prayer},
      ];
}

@DriftDatabase(tables: [Preferences, SavedLocations, PrayerRecords])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'qibla_finder'));

  @override
  int get schemaVersion => 1;

  // ---------------------------------------------------------------- prefs

  Future<Map<String, String>> loadPreferences() async {
    final rows = await select(preferences).get();
    return {for (final row in rows) row.key: row.value};
  }

  Future<void> putPreference(String key, String value) {
    return into(preferences).insertOnConflictUpdate(
      PreferencesCompanion.insert(key: key, value: value),
    );
  }

  // ------------------------------------------------------------- locations

  Future<List<SavedLocation>> allSavedLocations() {
    return (select(savedLocations)
          ..orderBy([(t) => OrderingTerm.desc(t.savedAt)]))
        .get();
  }

  Future<int> saveLocation({
    required String label,
    required double latitude,
    required double longitude,
    String? isoCountryCode,
    double? utcOffsetHours,
  }) {
    return into(savedLocations).insert(
      SavedLocationsCompanion.insert(
        label: label,
        latitude: latitude,
        longitude: longitude,
        isoCountryCode: Value(isoCountryCode),
        utcOffsetHours: Value(utcOffsetHours),
      ),
    );
  }

  Future<int> deleteSavedLocation(int id) {
    return (delete(savedLocations)..where((t) => t.id.equals(id))).go();
  }

  /// Remembers the last known position so a cold start can show a Qibla
  /// immediately instead of an empty screen while GPS warms up.
  Future<void> rememberCurrentLocation({
    required String label,
    required double latitude,
    required double longitude,
    String? isoCountryCode,
  }) async {
    await transaction(() async {
      await (delete(savedLocations)..where((t) => t.isCurrent.equals(true)))
          .go();
      await into(savedLocations).insert(
        SavedLocationsCompanion.insert(
          label: label,
          latitude: latitude,
          longitude: longitude,
          isoCountryCode: Value(isoCountryCode),
          isCurrent: const Value(true),
        ),
      );
    });
  }

  Future<SavedLocation?> lastKnownLocation() {
    return (select(savedLocations)..where((t) => t.isCurrent.equals(true)))
        .getSingleOrNull();
  }

  // ---------------------------------------------------------------- record

  Future<void> markPrayer(DateTime day, String prayer) async {
    final midnight = DateTime(day.year, day.month, day.day);
    // insertOnConflictUpdate targets the primary key (id), not the
    // (day, prayer) unique key, so re-marking would raise a constraint
    // failure. Marking carries no extra data, so ignoring a duplicate is both
    // correct and keeps the original markedAt timestamp.
    await into(prayerRecords).insert(
      PrayerRecordsCompanion.insert(day: midnight, prayer: prayer),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<void> unmarkPrayer(DateTime day, String prayer) {
    final midnight = DateTime(day.year, day.month, day.day);
    return (delete(prayerRecords)
          ..where((t) => t.day.equals(midnight) & t.prayer.equals(prayer)))
        .go();
  }

  /// Prayer names marked for [day]. Watched so the schedule updates itself.
  Stream<Set<String>> watchMarkedFor(DateTime day) {
    final midnight = DateTime(day.year, day.month, day.day);
    return (select(prayerRecords)..where((t) => t.day.equals(midnight)))
        .watch()
        .map((rows) => rows.map((r) => r.prayer).toSet());
  }
}
