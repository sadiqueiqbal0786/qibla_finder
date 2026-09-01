import 'package:flutter/foundation.dart';

import '../data/app_database.dart';
import 'calculation_method.dart';

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

      settings._autoMethod = flag(_kAutoMethod, true);
      settings._autoAsr = flag(_kAutoAsr, true);
      settings._method = CalculationMethod.byId(stored[_kMethodId]) ??
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
    _db.putPreference(key, value).catchError((Object error) {
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
