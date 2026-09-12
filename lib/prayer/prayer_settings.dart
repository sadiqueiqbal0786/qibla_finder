import 'package:flutter/foundation.dart';

import '../data/app_database.dart';
import 'calculation_method.dart';
import 'prayer_times.dart';

/// User preferences for prayer-time calculation, persisted in the SQLite
/// database so they survive app close, reinstall-preserving backups, and share
/// a transaction boundary with saved locations and the prayer log.
///
/// Every load and save is failure-tolerant: if storage is unavailable the app
/// keeps running on in-memory defaults rather than refusing to start.
class PrayerSettings extends ChangeNotifier {
  PrayerSettings._(this._db);

  final AppDatabase _db;

  static const _kMethodId = 'prayer.method_id';
  static const _kAutoMethod = 'prayer.auto_method';
  static const _kAsrMadhab = 'prayer.asr_madhab';
  static const _kAutoAsr = 'prayer.auto_asr';
  static const _kHighLatRule = 'prayer.high_lat_rule';
  static const _kRemindersEnabled = 'prayer.reminders_enabled';
  static const _kAdhanMode = 'prayer.adhan_mode';

  String? _country;
  String _theme = 'system';
  String _ramadanMode = 'auto';
  bool _onboarded = false;
  bool _ramadanReminders = true;
  int _suhoorAdvance = 30;
  String _language = 'en';
  int _advanceMinutes = 0;
  final Set<String> _mutedPrayers = {};
  final Map<Prayer, int> _offsets = {};
  Future<void> _writes = Future<void>.value();
  Future<void> get flushed => _writes;
  String get theme => _theme;

  /// How to place Ramadan against the arithmetic Hijri calendar.
  ///
  /// 'auto' trusts the calculation. 'earlier' and 'later' shift it by one day
  /// for a local sighting that does not match, which is the only way the
  /// announced date ever differs. 'off' hides the headline entirely. There is
  /// deliberately no "always on": that would show the fasting headline in
  /// every month of the year.
  String get ramadanMode => _ramadanMode;

  /// Whether the user has been told why the app wants a location.
  ///
  /// Nothing may ask for the permission until this is true. A cold system
  /// prompt on first launch is the one moment where a refusal is hardest to
  /// recover from, and the app is far worse without either a fix or a city.
  bool get onboarded => _onboarded;

  void completeOnboarding() {
    if (_onboarded) return;
    _onboarded = true;
    _write('app.onboarded', 'true');
    notifyListeners();
  }

  /// Largest correction offered either way, in minutes.
  static const int maxOffset = 30;

  /// Per-prayer correction, for matching a mosque's printed timetable.
  Map<Prayer, int> get offsets => Map.unmodifiable(_offsets);

  int offsetFor(Prayer prayer) => _offsets[prayer] ?? 0;

  bool get hasOffsets => _offsets.values.any((m) => m != 0);

  void setOffset(Prayer prayer, int minutes) {
    final clamped = minutes.clamp(-maxOffset, maxOffset);
    if (offsetFor(prayer) == clamped) return;
    if (clamped == 0) {
      _offsets.remove(prayer);
    } else {
      _offsets[prayer] = clamped;
    }
    _write('prayer.offset.${prayer.name}', '$clamped');
    notifyListeners();
  }

  void clearOffsets() {
    if (_offsets.isEmpty) return;
    for (final prayer in Prayer.values) {
      _write('prayer.offset.${prayer.name}', '0');
    }
    _offsets.clear();
    notifyListeners();
  }

  /// Whether the two fasting reminders are scheduled during Ramadan.
  bool get ramadanReminders => _ramadanReminders;

  /// Warning before Fajr for suhoor. The ordinary advance setting cannot do
  /// this job: it applies to all five prayers at once, so asking for warning
  /// before suhoor would also fire early alerts for Dhuhr through Isha.
  int get suhoorAdvanceMinutes => _suhoorAdvance;

  /// Civil days to add before converting to the Hijri date.
  int get ramadanDayShift => switch (_ramadanMode) {
    'earlier' => 1,
    'later' => -1,
    _ => 0,
  };
  String get language => _language;
  int get advanceMinutes => _advanceMinutes;
  bool prayerEnabled(Prayer prayer) =>
      prayer.isPrayer && !_mutedPrayers.contains(prayer.name);
  void setTheme(String value) {
    if (!['system', 'light', 'dark'].contains(value)) return;
    _theme = value;
    _write('app.theme', value);
    notifyListeners();
  }

  void setRamadanMode(String value) {
    if (!['auto', 'earlier', 'later', 'off'].contains(value)) return;
    _ramadanMode = value;
    _write('app.ramadan_mode', value);
    notifyListeners();
  }

  void setRamadanReminders(bool value) {
    if (_ramadanReminders == value) return;
    _ramadanReminders = value;
    _write('prayer.ramadan_reminders', '$value');
    notifyListeners();
  }

  void setSuhoorAdvance(int minutes) {
    if (![0, 15, 30, 45, 60].contains(minutes)) return;
    _suhoorAdvance = minutes;
    _write('prayer.suhoor_advance', '$minutes');
    notifyListeners();
  }

  void setLanguage(String value) {
    if (!['en', 'hi', 'ur'].contains(value)) return;
    _language = value;
    _write('app.language', value);
    notifyListeners();
  }

  void setAdvanceMinutes(int value) {
    if (![0, 5, 10, 15, 30].contains(value)) return;
    _advanceMinutes = value;
    _write('prayer.advance', '$value');
    notifyListeners();
  }

  void setPrayerEnabled(Prayer prayer, bool enabled) {
    if (!prayer.isPrayer) return;
    if (enabled) {
      _mutedPrayers.remove(prayer.name);
    } else {
      _mutedPrayers.add(prayer.name);
    }
    _write('prayer.muted', _mutedPrayers.join(','));
    notifyListeners();
  }

  bool _autoMethod = true;
  bool _autoAsr = true;
  CalculationMethod _method = CalculationMethod.muslimWorldLeague;
  AsrMadhab _asrMadhab = AsrMadhab.standard;
  HighLatitudeRule _highLatitudeRule = HighLatitudeRule.angleBased;
  bool _remindersEnabled = false;
  AdhanMode _adhanMode = AdhanMode.notificationOnly;

  /// True while the method follows the detected country.
  bool get autoMethod => _autoMethod;
  bool get autoAsr => _autoAsr;
  CalculationMethod get method => _method;
  AsrMadhab get asrMadhab => _asrMadhab;
  HighLatitudeRule get highLatitudeRule => _highLatitudeRule;
  bool get remindersEnabled => _remindersEnabled;

  /// How loudly a prayer reminder should announce itself.
  AdhanMode get adhanMode => _adhanMode;

  static Future<PrayerSettings> load(AppDatabase db) async {
    final settings = PrayerSettings._(db);
    try {
      final stored = await db.loadPreferences();
      bool flag(String key, bool fallback) =>
          stored.containsKey(key) ? stored[key] == 'true' : fallback;

      settings._country = stored['prayer.country'];
      settings._theme =
          ['system', 'light', 'dark'].contains(stored['app.theme'])
          ? stored['app.theme']!
          : 'system';
      settings._ramadanMode =
          ['auto', 'earlier', 'later', 'off'].contains(
            stored['app.ramadan_mode'],
          )
          ? stored['app.ramadan_mode']!
          : 'auto';
      for (final prayer in Prayer.values) {
        final stored0 = int.tryParse(stored['prayer.offset.${prayer.name}'] ?? '');
        if (stored0 != null && stored0 != 0) {
          settings._offsets[prayer] = stored0.clamp(-maxOffset, maxOffset);
        }
      }
      settings._onboarded = flag('app.onboarded', false);
      settings._ramadanReminders = flag('prayer.ramadan_reminders', true);
      final suhoor = int.tryParse(stored['prayer.suhoor_advance'] ?? '');
      settings._suhoorAdvance = [0, 15, 30, 45, 60].contains(suhoor)
          ? suhoor!
          : 30;
      settings._language = ['en', 'hi', 'ur'].contains(stored['app.language'])
          ? stored['app.language']!
          : 'en';
      final advance = int.tryParse(stored['prayer.advance'] ?? '') ?? 0;
      settings._advanceMinutes = [0, 5, 10, 15, 30].contains(advance)
          ? advance
          : 0;
      settings._mutedPrayers.addAll((stored['prayer.muted'] ?? '').split(','));
      settings._autoMethod = flag(_kAutoMethod, true);
      settings._autoAsr = flag(_kAutoAsr, true);
      settings._method =
          CalculationMethod.byId(stored[_kMethodId]) ??
          CalculationMethod.muslimWorldLeague;
      settings._asrMadhab = _asrFromName(stored[_kAsrMadhab]);
      settings._highLatitudeRule = _ruleFromName(stored[_kHighLatRule]);
      settings._remindersEnabled = flag(_kRemindersEnabled, false);
      settings._adhanMode = _adhanFromName(stored[_kAdhanMode]);
    } catch (error) {
      debugPrint('PrayerSettings: falling back to defaults: $error');
    }
    return settings;
  }

  /// Applies the regional convention for [isoCountryCode], but only for the
  /// axes the user has not overridden by hand.
  void applyRegionalDefaults(String? isoCountryCode) {
    if (isoCountryCode == null || isoCountryCode.isEmpty) return;

    _country = isoCountryCode;
    _write('prayer.country', isoCountryCode);
    var changed = false;
    if (_autoMethod) {
      final detected = CalculationMethod.forCountry(isoCountryCode);
      if (detected.id != _method.id) {
        _method = detected;
        _write(_kMethodId, detected.id);
        changed = true;
      }
    }
    if (_autoAsr) {
      final detected = CalculationMethod.asrForCountry(isoCountryCode);
      if (detected != _asrMadhab) {
        _asrMadhab = detected;
        _write(_kAsrMadhab, detected.name);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void setMethod(CalculationMethod method) {
    if (_method.id == method.id && !_autoMethod) return;
    _method = method;
    _autoMethod = false;
    _write(_kMethodId, method.id);
    _write(_kAutoMethod, 'false');
    notifyListeners();
  }

  void setAsrMadhab(AsrMadhab madhab) {
    if (_asrMadhab == madhab && !_autoAsr) return;
    _asrMadhab = madhab;
    _autoAsr = false;
    _write(_kAsrMadhab, madhab.name);
    _write(_kAutoAsr, 'false');
    notifyListeners();
  }

  void setHighLatitudeRule(HighLatitudeRule rule) {
    if (_highLatitudeRule == rule) return;
    _highLatitudeRule = rule;
    _write(_kHighLatRule, rule.name);
    notifyListeners();
  }

  void setRemindersEnabled(bool enabled) {
    if (_remindersEnabled == enabled) return;
    _remindersEnabled = enabled;
    _write(_kRemindersEnabled, '$enabled');
    notifyListeners();
  }

  /// Hands both axes back to automatic regional detection.
  void resetToAutomatic() {
    _autoMethod = true;
    _autoAsr = true;
    _write(_kAutoMethod, 'true');
    _write(_kAutoAsr, 'true');
    applyRegionalDefaults(_country);
    notifyListeners();
  }

  void setAdhanMode(AdhanMode mode) {
    if (_adhanMode == mode) return;
    _adhanMode = mode;
    _write(_kAdhanMode, mode.name);
    notifyListeners();
  }

  /// Fire-and-forget write. A failed write must not take the UI down; the
  /// value still applies for this session.
  void _write(String key, String value) {
    _writes = _writes.then((_) => _db.putPreference(key, value)).catchError((
      Object error,
    ) {
      debugPrint('PrayerSettings: could not persist $key: $error');
    });
  }

  static AsrMadhab _asrFromName(String? name) {
    for (final value in AsrMadhab.values) {
      if (value.name == name) return value;
    }
    return AsrMadhab.standard;
  }

  static AdhanMode _adhanFromName(String? name) {
    for (final value in AdhanMode.values) {
      if (value.name == name) {
        // A stored preference for a mode that is no longer offered would
        // otherwise leave the user on a reminder that makes no sound.
        if (!AdhanMode.selectable.contains(value)) {
          return AdhanMode.notificationOnly;
        }
        return value;
      }
    }
    return AdhanMode.notificationOnly;
  }

  static HighLatitudeRule _ruleFromName(String? name) {
    for (final value in HighLatitudeRule.values) {
      if (value.name == name) return value;
    }
    return HighLatitudeRule.angleBased;
  }
}
