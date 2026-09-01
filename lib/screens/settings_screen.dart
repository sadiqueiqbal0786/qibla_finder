import 'package:flutter/material.dart';

import '../prayer/calculation_method.dart';
import '../prayer/prayer_notifications.dart';
import '../prayer/prayer_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.settings});

  final PrayerSettings settings;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.settings.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _onRemindersToggled(bool enabled) async {
    if (!enabled) {
      widget.settings.setRemindersEnabled(false);
      return;
    }

    final granted = await PrayerNotifications.instance.requestPermission();
    if (!mounted) return;

    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Notification permission was declined. Enable it in system '
            'settings to receive prayer reminders.',
          ),
        ),
      );
      return;
    }
    widget.settings.setRemindersEnabled(true);
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer settings',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (settings.autoMethod || settings.autoAsr)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Settings marked automatic follow the convention used where '
                'you are. Changing one switches it to manual.',
                style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.black.withValues(alpha: 0.6)),
              ),
            ),
          const _SectionHeader(title: 'Reminders'),
          SwitchListTile(
            value: settings.remindersEnabled,
            activeThumbColor: const Color(0xFF156F3F),
            onChanged: _onRemindersToggled,
            title: const Text('Prayer time reminders',
                style: TextStyle(fontSize: 15)),
            subtitle: const Text(
              'A notification at the start of each prayer, scheduled a week '
              'ahead and refreshed each time you open the app.',
              style: TextStyle(fontSize: 12),
            ),
          ),
          RadioGroup<AdhanMode>(
            groupValue: settings.adhanMode,
            onChanged: (mode) {
              if (mode != null) settings.setAdhanMode(mode);
            },
            child: Column(
              children: [
                for (final mode in AdhanMode.selectable)
                  RadioListTile<AdhanMode>(
                    value: mode,
                    activeColor: const Color(0xFF156F3F),
                    title: Text(mode.label,
                        style: const TextStyle(fontSize: 15)),
                    subtitle: Text(mode.description,
                        style: const TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
          const Divider(height: 28),
          _SectionHeader(
            title: 'Calculation method',
            trailing: settings.autoMethod ? 'Automatic' : 'Manual',
          ),
          RadioGroup<String>(
            groupValue: settings.method.id,
            onChanged: (id) {
              final method = CalculationMethod.byId(id);
              if (method != null) settings.setMethod(method);
            },
            child: Column(
              children: [
                for (final method in CalculationMethod.all)
                  RadioListTile<String>(
                    value: method.id,
                    activeColor: const Color(0xFF156F3F),
                    title:
                        Text(method.name, style: const TextStyle(fontSize: 15)),
                    subtitle: Text(
                      _describe(method),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 28),
          _SectionHeader(
            title: 'Asr calculation',
            trailing: settings.autoAsr ? 'Automatic' : 'Manual',
          ),
          RadioGroup<AsrMadhab>(
            groupValue: settings.asrMadhab,
            onChanged: (madhab) {
              if (madhab != null) settings.setAsrMadhab(madhab);
            },
            child: Column(
              children: [
                for (final madhab in AsrMadhab.values)
                  RadioListTile<AsrMadhab>(
                    value: madhab,
                    activeColor: const Color(0xFF156F3F),
                    title:
                        Text(madhab.label, style: const TextStyle(fontSize: 15)),
                    subtitle: Text(
                      madhab == AsrMadhab.hanafi
                          ? 'Shadow twice the object length'
                          : 'Shadow equal to the object length (Shafi\'i, '
                              'Maliki, Hanbali)',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 28),
          const _SectionHeader(title: 'High latitude rule'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Used only where the sun never reaches the Fajr or Isha angle.',
              style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Colors.black.withValues(alpha: 0.6)),
            ),
          ),
          RadioGroup<HighLatitudeRule>(
            groupValue: settings.highLatitudeRule,
            onChanged: (rule) {
              if (rule != null) settings.setHighLatitudeRule(rule);
            },
            child: Column(
              children: [
                for (final rule in HighLatitudeRule.values)
                  RadioListTile<HighLatitudeRule>(
                    value: rule,
                    activeColor: const Color(0xFF156F3F),
                    title:
                        Text(rule.label, style: const TextStyle(fontSize: 15)),
                  ),
              ],
            ),
          ),
          const Divider(height: 28),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: OutlinedButton.icon(
              onPressed: settings.autoMethod && settings.autoAsr
                  ? null
                  : settings.resetToAutomatic,
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: const Text('Use automatic regional defaults'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF156F3F),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _describe(CalculationMethod method) {
    final isha = method.ishaMode == IshaMode.interval
        ? '${method.ishaInterval} min after Maghrib'
        : 'Isha ${_trim(method.ishaAngle)}°';
    return 'Fajr ${_trim(method.fajrAngle)}° · $isha';
  }

  static String _trim(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : '$value';
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                letterSpacing: 0.9,
                fontWeight: FontWeight.bold,
                color: Color(0xFF156F3F),
              ),
            ),
          ),
          if (trailing != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0x14156F3F),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                trailing!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF156F3F),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
