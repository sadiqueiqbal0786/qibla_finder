# Advance Qibla Finder

Flutter app: Qibla compass plus offline prayer times. Ships on Google Play as
`com.qibla_finder`.

## Commands

```bash
flutter analyze                        # must stay at zero issues
flutter test                           # 128 tests
flutter build appbundle --release      # -> build/app/outputs/bundle/release/
dart run build_runner build            # after touching lib/data/app_database.dart
flutter test tool/generate_icon.dart   # regenerates the launcher icon set
flutter test tool/design_preview.dart --update-goldens   # -> docs/previews/
```

## Layout

- `lib/qibla_logic.dart` — pure geodesy (bearing, distance, angle helpers)
- `lib/qibla_controller.dart` — state machine, owns location + compass + prayer times
- `lib/services/` — compass, location, declination, timezone resolution
- `lib/prayer/` — solar ephemeris, calculation methods, schedule, notifications
- `lib/widgets/qibla_compass.dart` — the dial, drawn with CustomPaint
- `lib/data/app_database.dart` — drift schema (`app_database.g.dart` is generated)
- `lib/theme/app_theme.dart` — brand constants, the `AppColors` extension, both themes
- `lib/widgets/app_surfaces.dart` — `SectionCard`, `ChoiceRow`, `NoticeRow`, `HeroPanel`

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

**Brand colour lives in `lib/theme/app_theme.dart`, nowhere else.** `AppBrand`
holds the four fixed values; everything that varies with light/dark is read
through `AppColors.of(context)`. Before this there were the same four hex
literals copied across seven files. The app bar is `AppBrand.inkSoft` in every
theme and on every tab, so moving between the compass and the schedule never
flashes a different header, and the "next prayer" hero keeps the Qibla
gradient in the light theme too — that is what ties the tabs together.

**Widget rows are sized against `OPTION_APPWIDGET_MIN_HEIGHT`**, which is the
height in the *shorter* orientation, not what you see in portrait. Measured on
a 560dpi phone, a two-row placement reports 136dp and a three-row one 210dp,
while the same two-row widget renders ~220dp tall in portrait. Sizing against
the portrait height clips the footer in landscape. The thresholds in
`PrayerWidgetProvider.applySize` are calibrated to those numbers; re-measure
before changing row heights.

**The widget is always dark**, like the compass tab and the in-app hero, whatever
the app theme is. It is the same gradient and the same mint.

**Dark surfaces must stay three distinct values** — page, card, hero. The first
cut of the dark palette put the card one step from the page and the cards
dissolved into the background. `test/theme_test.dart` pins the gap.

**The compass is vector-drawn.** Do not reintroduce PNG assets for it — 5.2 MB
of images were removed and the CustomPaint version is crisper and theme-aware.

**Adhan playback is gated off** behind `kAdhanPlaybackAvailable` in
`lib/prayer/calculation_method.dart`, because no licensed recitation ships.
Fajr needs its own file (the dawn adhan has an extra line) and its own Android
notification channel, since a channel's sound is frozen at creation. See
`docs/adhan-audio.md`. Flip the flag only once both files exist.

**Reminder delivery is verified** (Android 15 emulator, Sep 2026): with the
device on Asia/Kolkata and the location in London, alarms landed at the right
absolute instants, and a Maghrib reminder was observed firing and posting
"Maghrib time / It is time for Maghrib." Without the exact-alarm permission
Android gave the alarm a **26-minute window**, so the "Reminders may arrive
late" state is real and worth keeping honest.

**The notification icon must be a white-on-transparent silhouette**
(`@drawable/ic_notification`, generated by `tool/generate_icon.dart`). Android
discards colour and keeps only the alpha, so pointing this at the colour
launcher icon renders a featureless blob with no compass in it.

**The Hijri date is arithmetic, not sighted.** `lib/prayer/hijri.dart` is the
tabular calendar; announced Ramadan dates commonly differ by a day and differ
between countries. Never present it as a ruling.

**A `tooltip:` on an icon button does not reach the semantics tree.** Three
controls were tappable but announced nothing. Put the name on the icon
(`Icon(..., semanticLabel: ...)`), which merges onto the button's own node; a
wrapping `Semantics` makes a second node instead and is worse.
`test/accessibility_test.dart` walks the tree on every screen and fails on any
tappable node with an empty label. Note that a `uiautomator` dump is *not* a
valid check: it does not expose a text field's hint, so it reports correctly
labelled fields as bare edit boxes.

**Nothing may request location before `settings.onboarded`.** Android offers
the permission dialog once; a cold prompt on first launch is the one refusal
that is hard to recover from. `QiblaController.initialize` is gated on it and
`test/onboarding_test.dart` counts calls into a fake `LocationService` to prove
it. On the welcome screen "Choose a city" is deliberately the same size and
weight as "Use my location" — it is a peer route, not a consolation prize.

**`AppInfo.version` is asserted against `pubspec.yaml`** by a test, so bumping
the release without updating it fails rather than leaving About reporting the
previous build in support mail.

**Per-prayer corrections are applied inside `PrayerCalculator.forDate`**, not
at the display layer, so the schedule, countdowns, reminders and widget all
move together. A correction the alarms ignored would be worse than none. Every
`PrayerCalculator` construction must pass `settings.offsets`, and the offsets
belong in the `BackgroundRefresh` signature or a changed correction will not
rebuild the alarms. Range is ±30 minutes; no calculation reproduces a given
mosque's printed timetable, which is what this is for.

**Suhoor needs its own reminder.** `settings.advanceMinutes` applies to all
five prayers at once, so it cannot give warning before Fajr without firing
early alerts for Dhuhr through Isha. `suhoorAdvanceMinutes` is separate and
Ramadan-only. A fasting reminder that lands on the same instant as a prayer
reminder **replaces** it — otherwise Maghrib and iftar both fire at sunset.
Verified firing on the emulator at Ramadan 3/4 1447.

**Reminder ids are 20 slots per day**: two per prayer (`index * 2`, plus one
for the advance warning), then 12 and 13 for suhoor and iftar. Keep new
reminder kinds inside that block or renewal will start cancelling live alarms.

**The Ramadan headline is confined to the ninth Hijri month.** The override is
a one-day shift (`earlier`/`later`), not an on switch, because the only way a
local announcement ever differs is by a day. An earlier cut offered "always
on" and left the fasting headline up in September. `test/ramadan_mode_test.dart`
asserts every mode is inactive outside Ramadan.

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

## Before upgrading Flutter

`flutter_timezone`, `home_widget` and `workmanager_android` still apply the
Kotlin Gradle Plugin. Gradle warns that a future Flutter will refuse to build
an app whose plugins do this. **There is nothing to fix in this repo**: as of
Sep 2026 all three are already at their latest published versions (5.1.0,
0.9.4, 0.10.9) and the migration to Built-in Kotlin has to come from the plugin
authors. Check `flutter pub outdated` for those three before bumping Flutter,
and hold the upgrade until they ship it. Replacing them instead would mean
rewriting the widget bridge, the background renewal and the timezone lookup,
which is a lot of risk for no user-visible gain.

## Known gaps

- Compass rotation, smoothing and interference detection are **unverified on
  real hardware** — emulators have no magnetometer.
- The AAB is ~86 MB but that is the *upload*: ~107 MB of it is debug symbols
  and the Proguard map, which no user downloads. A device fetches one ABI,
  about 25 MB. If you want to trim, the target is `libapp.so` at ~13 MB per
  ABI, roughly double a plain Flutter app, most likely the compiled timezone
  boundary tables.
- Android namespace is still `com.example.qibla_finder` (applicationId is
  correct). Harmless; renaming risks breaking pinned launcher shortcuts.
