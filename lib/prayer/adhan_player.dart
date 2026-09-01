import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'prayer_times.dart';

/// Plays the adhan when a prayer time arrives and the app is in the
/// foreground.
///
/// Two recitations are used. The dawn adhan adds
/// *aṣ-ṣalātu khayrun min an-nawm* ("prayer is better than sleep"), which the
/// other four prayers do not contain, so Fajr gets its own file.
///
/// Neither is bundled: shipping a recording means shipping someone's
/// recitation, which is a licensing decision for the app owner rather than
/// something to guess at. Drop files at the paths below and declare them in
/// `pubspec.yaml`; until then every call is a no-op and the reminder falls
/// back to the notification sound.
class AdhanPlayer {
  AdhanPlayer._();

  static final AdhanPlayer instance = AdhanPlayer._();

  /// Standard adhan, for Dhuhr, Asr, Maghrib and Isha.
  ///
  /// Relative to the asset root, because audioplayers' AssetSource prepends
  /// `assets/`.
  static const String standardAsset = 'audio/adhan.mp3';

  /// Dawn adhan, for Fajr only.
  static const String fajrAsset = 'audio/adhan_fajr.mp3';

  static String assetFor(Prayer prayer) =>
      prayer == Prayer.fajr ? fajrAsset : standardAsset;

  final AudioPlayer _player = AudioPlayer();

  /// Tracked per file: one recitation may be present while the other is not,
  /// and a missing Fajr file must not silence Dhuhr.
  final Set<String> _missingAssets = <String>{};

  bool _playing = false;

  bool get isPlaying => _playing;

  /// Notifies listeners when playback starts or stops, so a banner can be
  /// shown and dismissed.
  final ValueNotifier<bool> playing = ValueNotifier<bool>(false);

  Future<void> play(Prayer prayer) async {
    final asset = assetFor(prayer);
    if (_missingAssets.contains(asset) || _playing) return;

    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.play(AssetSource(asset));
      _setPlaying(true);

      _player.onPlayerComplete.listen((_) => _setPlaying(false));
    } catch (error) {
      // A missing or unreadable asset must degrade to silence, never to a
      // crash at prayer time. Remember it so we stop retrying every prayer.
      debugPrint('AdhanPlayer: cannot play $asset: $error');
      _missingAssets.add(asset);
      _setPlaying(false);
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (error) {
      debugPrint('AdhanPlayer: stop failed: $error');
    }
    _setPlaying(false);
  }

  void _setPlaying(bool value) {
    _playing = value;
    playing.value = value;
  }

  Future<void> dispose() async {
    await _player.dispose();
    playing.dispose();
  }
}
