# Advance Qibla Finder

Flutter app: Qibla compass plus offline prayer times. Ships on Google Play as
`com.qibla_finder`.

## Commands

```bash
flutter analyze                        # must stay at zero issues
flutter test                           # 60 tests
flutter build appbundle --release      # -> build/app/outputs/bundle/release/
dart run build_runner build            # after touching lib/data/app_database.dart
flutter test tool/generate_icon.dart   # regenerates the launcher icon set
```

## Layout

- `lib/qibla_logic.dart` — pure geodesy (bearing, distance, angle helpers)
- `lib/qibla_controller.dart` — state machine, owns location + compass + prayer times
- `lib/services/` — compass, location, declination, timezone resolution
- `lib/prayer/` — solar ephemeris, calculation methods, schedule, notifications
- `lib/widgets/qibla_compass.dart` — the dial, drawn with CustomPaint
- `lib/data/app_database.dart` — drift schema (`app_database.g.dart` is generated)

## Decisions that must not be casually reverted

**Never request a location fix inside the compass callback.** The original code
called `getCurrentPosition` on every sensor event (10–50/sec). That was the main
cause of crashes, ANRs and battery drain. Location is fetched once per refresh,
behind an in-flight latch in `LocationService`.

**Needle angle is `qibla - heading`.** The original composed to
`-(heading + qibla)` and only pointed correctly when facing due north.

**Headings are corrected to true north** using WMM-2025 via the `geomag`
package. A magnetometer reports magnetic north; a Qibla bearing is measured
from true north. The gap reaches 15–20° in parts of North America and Oceania.
`CompassService.trueHeading` is what the UI consumes, not `heading`.

**Prayer times are stored as absolute UTC instants**, not wall-clock
`DateTime`s. Wall-clock values get silently reinterpreted in the device zone,
which gives nonsense countdowns and misfiring alarms for anyone whose phone
clock does not match where they are. Use `PrayerTimes.wallClock(prayer)` for
display and the raw instant for ordering, countdowns and scheduling.

**Prayer times use the location's time zone**, resolved from land polygons via
`timezone_finder`, not the device's. `TimezoneResolver` falls back to the device
offset when a point resolves to no zone.

**The compass is vector-drawn.** Do not reintroduce PNG assets for it — 5.2 MB
of images were removed and the CustomPaint version is crisper and theme-aware.

**Adhan playback is gated off** behind `kAdhanPlaybackAvailable` in
`lib/prayer/calculation_method.dart`, because no licensed recitation ships.
Fajr needs its own file (the dawn adhan has an extra line) and its own Android
notification channel, since a channel's sound is frozen at creation. See
`docs/adhan-audio.md`. Flip the flag only once both files exist.

**No `USE_EXACT_ALARM`.** It is a Play-restricted permission. Reminders check
`canScheduleExactNotifications()` once and fall back to inexact scheduling.

## Gotchas

- `flutter_compass` reports magnetic north; null heading means the sensor is
  settling — hold the last value rather than snapping to north.
- Android resource filenames must be lowercase `a-z0-9_`. A `README.md` inside
  `res/raw/` fails the build.
- Flutter uses Android Studio's bundled JDK (25), not `/usr/bin/java` (17).

## Release

Signing reads `android/key.properties` (gitignored) and falls back to the debug
key when absent. The original upload keystore was lost; a new one was generated
and registered with Play via upload-key reset. **Back up
`android/app/upload-keystore.jks` and `android/key.properties` — they exist in
one place only.**

## Known gaps

- Compass rotation, smoothing and interference detection are **unverified on
  real hardware** — emulators have no magnetometer.
- Prayer reminder notifications have never been observed actually firing.
- AAB is ~77 MB, mostly the timezone boundary polygons. Play splits per ABI.
- Android namespace is still `com.example.qibla_finder` (applicationId is
  correct). Harmless; renaming risks breaking pinned launcher shortcuts.
