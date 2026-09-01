import 'package:flutter/foundation.dart';

/// How Isha is defined for a given convention.
enum IshaMode {
  /// Sun a fixed number of degrees below the horizon.
  angle,

  /// A fixed number of minutes after Maghrib (Umm al-Qura, Qatar).
  interval,
}

/// Shadow-length factor used for Asr.
enum AsrMadhab {
  /// Shafi'i, Maliki, Hanbali: shadow = object length.
  standard,

  /// Hanafi: shadow = twice the object length.
  hanafi;

  double get shadowFactor => this == AsrMadhab.hanafi ? 2.0 : 1.0;

  String get label => this == AsrMadhab.hanafi ? 'Hanafi' : 'Standard';
}

/// What to do at latitudes where the sun never reaches the Fajr/Isha angle.
///
/// Without one of these, northern-Europe users get blank prayer times for
/// months at a time.
enum HighLatitudeRule {
  /// Fajr/Isha sit halfway through the night.
  middleOfNight,

  /// Night is split 1/7 for Fajr and 1/7 for Isha.
  seventhOfNight,

  /// Night is split in proportion to the method's own angles.
  angleBased;

  String get label => switch (this) {
        HighLatitudeRule.middleOfNight => 'Middle of the night',
        HighLatitudeRule.seventhOfNight => 'One seventh of the night',
        HighLatitudeRule.angleBased => 'Angle based',
      };
}

/// A named prayer-time convention.
@immutable
class CalculationMethod {
  const CalculationMethod({
    required this.id,
    required this.name,
    required this.fajrAngle,
    required this.ishaMode,
    this.ishaAngle = 0,
    this.ishaInterval = 0,
    this.maghribAngle,
    this.defaultAsr = AsrMadhab.standard,
  });

  final String id;
  final String name;

  /// Degrees below the horizon for Fajr.
  final double fajrAngle;

  final IshaMode ishaMode;

  /// Degrees below the horizon for Isha, when [ishaMode] is [IshaMode.angle].
  final double ishaAngle;

  /// Minutes after Maghrib, when [ishaMode] is [IshaMode.interval].
  final int ishaInterval;

  /// Some Shia conventions define Maghrib by angle rather than sunset.
  final double? maghribAngle;

  /// Asr madhab conventionally paired with this method.
  final AsrMadhab defaultAsr;

  static const muslimWorldLeague = CalculationMethod(
    id: 'mwl',
    name: 'Muslim World League',
    fajrAngle: 18,
    ishaMode: IshaMode.angle,
    ishaAngle: 17,
  );

  static const isna = CalculationMethod(
    id: 'isna',
    name: 'Islamic Society of North America',
    fajrAngle: 15,
    ishaMode: IshaMode.angle,
    ishaAngle: 15,
  );

  static const egyptian = CalculationMethod(
    id: 'egyptian',
    name: 'Egyptian General Authority of Survey',
    fajrAngle: 19.5,
    ishaMode: IshaMode.angle,
    ishaAngle: 17.5,
  );

  static const ummAlQura = CalculationMethod(
    id: 'umm_al_qura',
    name: 'Umm al-Qura, Makkah',
    fajrAngle: 18.5,
    ishaMode: IshaMode.interval,
    ishaInterval: 90,
  );

  static const karachi = CalculationMethod(
    id: 'karachi',
    name: 'University of Islamic Sciences, Karachi',
    fajrAngle: 18,
    ishaMode: IshaMode.angle,
    ishaAngle: 18,
    defaultAsr: AsrMadhab.hanafi,
  );

  static const dubai = CalculationMethod(
    id: 'dubai',
    name: 'Dubai',
    fajrAngle: 18.2,
    ishaMode: IshaMode.angle,
    ishaAngle: 18.2,
  );

  static const qatar = CalculationMethod(
    id: 'qatar',
    name: 'Qatar',
    fajrAngle: 18,
    ishaMode: IshaMode.interval,
    ishaInterval: 90,
  );

  static const kuwait = CalculationMethod(
    id: 'kuwait',
    name: 'Kuwait',
    fajrAngle: 18,
    ishaMode: IshaMode.angle,
    ishaAngle: 17.5,
  );

  static const singapore = CalculationMethod(
    id: 'singapore',
    name: 'Singapore, Malaysia & Indonesia',
    fajrAngle: 20,
    ishaMode: IshaMode.angle,
    ishaAngle: 18,
  );

  static const turkey = CalculationMethod(
    id: 'turkey',
    name: 'Diyanet İşleri Başkanlığı, Türkiye',
    fajrAngle: 18,
    ishaMode: IshaMode.angle,
    ishaAngle: 17,
  );

  static const tehran = CalculationMethod(
    id: 'tehran',
    name: 'Institute of Geophysics, University of Tehran',
    fajrAngle: 17.7,
    ishaMode: IshaMode.angle,
    ishaAngle: 14,
    maghribAngle: 4.5,
  );

  static const jafari = CalculationMethod(
    id: 'jafari',
    name: 'Shia Ithna-Ashari, Leva Institute',
    fajrAngle: 16,
    ishaMode: IshaMode.angle,
    ishaAngle: 14,
    maghribAngle: 4,
  );

  static const moonsighting = CalculationMethod(
    id: 'moonsighting',
    name: 'Moonsighting Committee',
    fajrAngle: 18,
    ishaMode: IshaMode.angle,
    ishaAngle: 18,
  );

  /// Every method, in the order shown in settings.
  static const List<CalculationMethod> all = <CalculationMethod>[
    muslimWorldLeague,
    isna,
    egyptian,
    ummAlQura,
    karachi,
    dubai,
    qatar,
    kuwait,
    singapore,
    turkey,
    tehran,
    jafari,
    moonsighting,
  ];

  static CalculationMethod? byId(String? id) {
    if (id == null) return null;
    for (final method in all) {
      if (method.id == id) return method;
    }
    return null;
  }

  /// Regionally conventional method for an ISO 3166-1 alpha-2 country code.
  ///
  /// Getting this wrong produces visibly incorrect times, so the mapping
  /// follows what the local religious authority actually publishes rather than
  /// anything clever.
  static CalculationMethod forCountry(String? isoCountryCode) {
    final code = isoCountryCode?.toUpperCase();
    if (code == null || code.isEmpty) return muslimWorldLeague;

    return switch (code) {
      'SA' || 'YE' || 'OM' || 'BH' => ummAlQura,
      'AE' => dubai,
      'QA' => qatar,
      'KW' => kuwait,
      'PK' || 'IN' || 'BD' || 'AF' || 'LK' || 'NP' => karachi,
      'US' || 'CA' || 'MX' => isna,
      'EG' ||
      'SY' ||
      'IQ' ||
      'JO' ||
      'LB' ||
      'SD' ||
      'LY' ||
      'DZ' ||
      'MA' ||
      'TN' ||
      'PS' =>
        egyptian,
      'TR' => turkey,
      'IR' => tehran,
      'SG' || 'MY' || 'ID' || 'BN' => singapore,
      _ => muslimWorldLeague,
    };
  }

  /// Asr madhab conventionally followed in a country.
  static AsrMadhab asrForCountry(String? isoCountryCode) {
    final code = isoCountryCode?.toUpperCase();
    const hanafiMajority = <String>{'PK', 'IN', 'BD', 'AF', 'LK', 'NP'};
    return hanafiMajority.contains(code) ? AsrMadhab.hanafi : AsrMadhab.standard;
  }
}

/// Whether adhan playback is offered to users.
///
/// Held false while no licensed recitation ships. Everything behind it — the
/// two notification channels, [AdhanMode.adhan], the player and the watcher
/// hook — is written and tested; flipping this to true is the only change
/// needed once `adhan.mp3` and `adhan_fajr.mp3` exist in both
/// `android/app/src/main/res/raw/` and `assets/audio/`.
/// See docs/adhan-audio.md.
const bool kAdhanPlaybackAvailable = false;

/// How a prayer reminder should announce itself.
enum AdhanMode {
  /// A silent notification only.
  silent,

  /// A notification with the system default sound.
  notificationOnly,

  /// A notification plus the adhan played in full when the app is open.
  adhan;

  String get label => switch (this) {
        AdhanMode.silent => 'Silent notification',
        AdhanMode.notificationOnly => 'Notification with sound',
        AdhanMode.adhan => 'Play the adhan',
      };

  String get description => switch (this) {
        AdhanMode.silent => 'Appears in the shade without a sound.',
        AdhanMode.notificationOnly => 'Uses your default notification sound.',
        AdhanMode.adhan =>
          'Plays the full adhan when the app is open, and a notification '
              'otherwise.',
      };

  /// Modes offered in settings. Excludes adhan playback until a recitation
  /// ships, so the app never advertises a sound it cannot make.
  static List<AdhanMode> get selectable => kAdhanPlaybackAvailable
      ? values
      : const <AdhanMode>[silent, notificationOnly];
}
