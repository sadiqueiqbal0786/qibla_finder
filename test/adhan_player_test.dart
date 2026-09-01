import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_finder/prayer/adhan_player.dart';
import 'package:qibla_finder/prayer/calculation_method.dart';
import 'package:qibla_finder/prayer/prayer_times.dart';

void main() {
  group('adhan feature gate', _adhanGateTests);

  group('adhan asset routing', () {
    test('Fajr uses the dawn recitation', () {
      // The dawn adhan adds "as-salatu khayrun min an-nawm"; the other four
      // do not contain it, so Fajr must not fall back to the standard file.
      expect(AdhanPlayer.assetFor(Prayer.fajr), AdhanPlayer.fajrAsset);
      expect(AdhanPlayer.assetFor(Prayer.fajr), isNot(AdhanPlayer.standardAsset));
    });

    test('the other four prayers use the standard recitation', () {
      for (final prayer in <Prayer>[
        Prayer.dhuhr,
        Prayer.asr,
        Prayer.maghrib,
        Prayer.isha,
      ]) {
        expect(AdhanPlayer.assetFor(prayer), AdhanPlayer.standardAsset,
            reason: '$prayer should use the standard adhan');
      }
    });

    test('asset paths are distinct and audioplayers-relative', () {
      expect(AdhanPlayer.standardAsset, 'audio/adhan.mp3');
      expect(AdhanPlayer.fajrAsset, 'audio/adhan_fajr.mp3');
      // AssetSource prepends "assets/", so these must not repeat it.
      expect(AdhanPlayer.standardAsset.startsWith('assets/'), isFalse);
      expect(AdhanPlayer.fajrAsset.startsWith('assets/'), isFalse);
    });
  });
}

/// Cover the feature gate, so re-enabling adhan playback later is a one-line
/// change that these tests will confirm.
void _adhanGateTests() {
  test('adhan playback is hidden while no recitation ships', () {
    expect(kAdhanPlaybackAvailable, isFalse,
        reason: 'flip this only when both audio files exist');
    expect(AdhanMode.selectable, isNot(contains(AdhanMode.adhan)));
    expect(AdhanMode.selectable,
        containsAll(<AdhanMode>[AdhanMode.silent, AdhanMode.notificationOnly]));
  });

  test('every offered mode can actually make the sound it promises', () {
    for (final mode in AdhanMode.selectable) {
      expect(mode.label, isNotEmpty);
      expect(mode.description, isNotEmpty);
    }
  });
}
