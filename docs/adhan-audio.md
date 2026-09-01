# Adhan audio

> This file lives in `docs/` on purpose. Android resource filenames must be
> lowercase `a-z0-9_`, so a `README.md` inside `res/raw/` fails the build.

## Two recitations are needed

The dawn adhan contains an extra line the other four do not:
*aṣ-ṣalātu khayrun min an-nawm* — "prayer is better than sleep" — recited twice
after *ḥayya ʿalā al-falāḥ*. So Fajr needs its own file.

| Prayer                      | File          |
| --------------------------- | ------------- |
| Fajr                        | `adhan_fajr`  |
| Dhuhr, Asr, Maghrib, Isha   | `adhan`       |

## Where the files go

**Android — plays with the app closed, at full length:**

```
android/app/src/main/res/raw/adhan.mp3
android/app/src/main/res/raw/adhan_fajr.mp3
```

Filenames must be lowercase `a-z0-9_` with no spaces, or the build fails.

**Flutter — in-app playback while the app is open:**

```
assets/audio/adhan.mp3
assets/audio/adhan_fajr.mp3
```

and declare the folder in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/icon/
    - assets/audio/
```

**iOS — add both to the Runner bundle in Xcode:**

```
adhan.aiff
adhan_fajr.aiff
```

## Three things to know

* **Channels cache their sound.** Android freezes a notification channel's
  sound when the channel is first created and ignores later changes. If you add
  or swap a file after the app has already run, bump the channel id
  (`_channelAdhan` / `_channelAdhanFajr` in
  `lib/prayer/prayer_notifications.dart`) or clear the app's data — otherwise
  the old sound sticks. This is also why Fajr has its own channel rather than
  sharing one and swapping the sound.

* **iOS caps custom notification sounds at 30 seconds.** A full adhan cannot
  play from a closed iOS app; that is an Apple restriction, not a bug here. Use
  a short call for the `.aiff` files. Full playback on iOS happens only while
  the app is open, through `AdhanPlayer`.

* **Missing files degrade to silence, per file.** `AdhanPlayer` tracks each
  asset separately, so a missing Fajr recitation does not silence Dhuhr. On
  Android a missing raw resource means the notification arrives without sound.

No recitation ships with this repo: which recording to distribute is a
licensing decision for the app owner.
