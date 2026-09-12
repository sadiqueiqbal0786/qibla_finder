import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_info.dart';
import '../l10n/app_strings.dart';
import '../prayer/calculation_method.dart';
import '../prayer/prayer_notifications.dart';
import '../prayer/prayer_settings.dart';
import '../prayer/prayer_times.dart';
import '../privacy_policy.dart';
import '../qibla_controller.dart';
import '../services/background_refresh.dart';
import '../theme/app_theme.dart';
import '../widgets/app_surfaces.dart';
import '../widgets/status_view.dart';

/// Settings, grouped.
///
/// Everything the user changes often sits at the top in its own card; the
/// angle and high-latitude machinery stays folded away under Advanced.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
    required this.controller,
  });
  final PrayerSettings settings;
  final QiblaController controller;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  bool _busy = false;
  ({bool allowed, bool exact, int pending})? _status;

  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_changed);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    widget.settings.removeListener(_changed);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _status != null) _check();
  }

  void _changed() {
    if (mounted) setState(() => _status = null);
  }

  Future<void> _action(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                'Could not complete this action. Check permissions and try again.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _check() => _action(() async {
    await widget.settings.flushed;
    await BackgroundRefresh.refresh(
      widget.controller.database,
      propagateErrors: true,
      force: true,
    );
    final value = await PrayerNotifications.instance.status();
    if (mounted) setState(() => _status = value);
  });

  Future<void> _toggle(bool enabled) => _action(() async {
    if (enabled && !await PrayerNotifications.instance.requestPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Notifications are blocked'))),
        );
      }
      return;
    }
    widget.settings.setRemindersEnabled(enabled);
  });

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Settings'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _reminders(settings, android),
                const SizedBox(height: 14),
                _status_(android),
                const SizedBox(height: 14),
                _ramadan(settings),
                const SizedBox(height: 14),
                _appearance(settings),
                const SizedBox(height: 14),
                _calculation(settings),
                const SizedBox(height: 14),
                _adjust(settings),
                if (android) ...[const SizedBox(height: 14), _widget()],
                const SizedBox(height: 14),
                _about(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reminders(PrayerSettings settings, bool android) => SectionCard(
    title: 'Reminders',
    icon: Icons.notifications_active_outlined,
    children: [
      _Toggle(
        label: context.tr('Prayer reminders'),
        value: settings.remindersEnabled,
        onChanged: _busy ? null : _toggle,
      ),
      if (settings.remindersEnabled) ...[
        const SizedBox(height: 14),
        const FieldLabel('Which prayers'),
        // Five toggles became five chips: the whole choice is one line of
        // reading instead of a screen of switch rows.
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final prayer in Prayer.values.where((p) => p.isPrayer))
              _PrayerChip(
                label: context.tr(prayer.label),
                selected: settings.prayerEnabled(prayer),
                onChanged: (value) => settings.setPrayerEnabled(prayer, value),
              ),
          ],
        ),
        const SizedBox(height: 18),
        const FieldLabel('Remind me before prayer'),
        ChoiceRow<int>(
          value: settings.advanceMinutes,
          choices: {
            for (final value in [0, 5, 10, 15, 30])
              value: context.tr(
                value == 0 ? 'At prayer time only' : '$value minutes before',
              ),
          },
          onChanged: settings.setAdvanceMinutes,
        ),
        const SizedBox(height: 18),
        const FieldLabel('Sound'),
        ChoiceRow<AdhanMode>(
          value: settings.adhanMode,
          choices: {
            for (final mode in AdhanMode.selectable)
              mode: context.tr(
                mode == AdhanMode.silent
                    ? 'Silent'
                    : mode == AdhanMode.notificationOnly
                    ? 'Notification sound'
                    : 'Play the adhan',
              ),
          },
          onChanged: settings.setAdhanMode,
        ),
        const SizedBox(height: 8),
        NoticeRow(
          context.tr(
            android
                ? 'Reminders renew automatically using your saved location. Open the app after travelling or force-stopping it.'
                : 'Open the app every few days to renew reminders. Background renewal is available on Android.',
          ),
        ),
      ],
    ],
  );

  Widget _status_(bool android) {
    final status = _status;
    final colors = AppColors.of(context);
    return SectionCard(
      title: 'Reminder status',
      icon: Icons.verified_outlined,
      children: [
        if (status == null)
          Text(
            context.tr(
              'Check that reminders are permitted and scheduled on this device.',
            ),
            style: TextStyle(color: colors.muted),
          )
        else ...[
          NoticeRow(
            context.tr(
              !status.allowed
                  ? 'Notifications are blocked'
                  : status.pending == 0
                  ? 'No reminders scheduled'
                  : status.exact
                  ? 'Reminders are ready'
                  : 'Reminders may arrive late',
            ),
            tone: !status.allowed
                ? NoticeTone.bad
                : status.pending == 0
                ? NoticeTone.caution
                : status.exact
                ? NoticeTone.good
                : NoticeTone.caution,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '${context.tr('Scheduled notifications')}: ${status.pending}',
              style: TextStyle(color: colors.muted),
            ),
          ),
        ],
        const SizedBox(height: 10),
        if (_busy)
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: LinearProgressIndicator(),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _busy ? null : _check,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(context.tr('Check reminders')),
            ),
            if (status != null) ...[
              if (!status.allowed)
                TextButton(
                  onPressed: () => _toggle(true),
                  child: Text(context.tr('Enable notifications')),
                ),
              if (android && !status.exact)
                TextButton(
                  onPressed: () => _action(
                    () => PrayerNotifications.instance.requestExactPermission(),
                  ),
                  child: Text(context.tr('Allow precise reminders')),
                ),
              TextButton(
                onPressed: widget.controller.openAppSettings,
                child: Text(context.tr('Open app settings')),
              ),
              TextButton(
                onPressed: () => _action(
                  () => PrayerNotifications.instance.testNotification(
                    language: widget.settings.language,
                  ),
                ),
                child: Text(context.tr('Send test notification')),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _ramadan(PrayerSettings settings) => SectionCard(
    title: 'Ramadan',
    icon: Icons.nightlight_round,
    children: [
      const FieldLabel('Show suhoor and iftar'),
      ChoiceRow<String>(
        value: settings.ramadanMode,
        choices: {
          'auto': context.tr('Automatic'),
          'earlier': context.tr('A day earlier'),
          'later': context.tr('A day later'),
          'off': context.tr('Off'),
        },
        onChanged: settings.setRamadanMode,
      ),
      const SizedBox(height: 8),
      NoticeRow(
        context.tr(
          'Suhoor and iftar appear during Ramadan only. The Hijri date is calculated, so if your mosque started a day earlier or later, shift it to match.',
        ),
      ),
      if (widget.controller.ramadanActive)
        NoticeRow(
          context
              .tr('Showing Ramadan {day}')
              .replaceAll('{day}', '${widget.controller.hijriToday.day}'),
          tone: NoticeTone.good,
        ),
      if (settings.ramadanMode != 'off') ...[
        const Divider(height: 28),
        _Toggle(
          label: context.tr('Suhoor and iftar reminders'),
          value: settings.ramadanReminders,
          onChanged: settings.setRamadanReminders,
        ),
        if (settings.ramadanReminders) ...[
          const SizedBox(height: 14),
          const FieldLabel('Warn me before suhoor ends'),
          ChoiceRow<int>(
            value: settings.suhoorAdvanceMinutes,
            choices: {
              for (final value in [0, 15, 30, 45, 60])
                value: value == 0
                    ? context.tr('At Fajr only')
                    : context.tr('$value minutes before'),
            },
            onChanged: settings.setSuhoorAdvance,
          ),
          const SizedBox(height: 8),
          NoticeRow(
            context.tr(
              'These are scheduled during Ramadan only, on top of your prayer reminders.',
            ),
          ),
        ],
      ],
    ],
  );

  Widget _appearance(PrayerSettings settings) => SectionCard(
    title: 'Appearance',
    icon: Icons.palette_outlined,
    children: [
      const FieldLabel('Theme'),
      ChoiceRow<String>(
        value: settings.theme,
        choices: {
          for (final item in ['system', 'light', 'dark'])
            item: context.tr('${item[0].toUpperCase()}${item.substring(1)}'),
        },
        onChanged: settings.setTheme,
      ),
      const SizedBox(height: 18),
      const FieldLabel('Language'),
      ChoiceRow<String>(
        value: settings.language,
        choices: const {'en': 'English', 'hi': 'हिन्दी', 'ur': 'اردو'},
        onChanged: settings.setLanguage,
      ),
    ],
  );

  Widget _calculation(PrayerSettings settings) {
    final colors = AppColors.of(context);
    return SectionCard(
      title: 'Calculation',
      icon: Icons.calculate_outlined,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      children: [
        Text(
          settings.method.name,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(
          context.tr('{madhab} Asr').replaceAll(
            '{madhab}',
            context.tr(settings.asrMadhab.label),
          ),
          style: TextStyle(color: colors.muted),
        ),
        const SizedBox(height: 8),
        NoticeRow(
          context.tr(
            'Regional defaults are selected automatically. Change advanced settings only if needed.',
          ),
          icon: settings.autoMethod && settings.autoAsr
              ? Icons.check_circle_outline_rounded
              : Icons.tune_rounded,
        ),
        if (!settings.autoMethod || !settings.autoAsr)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: settings.resetToAutomatic,
              icon: const Icon(Icons.auto_mode_rounded, size: 18),
              label: Text(context.tr('Use automatic regional defaults')),
            ),
          ),
        Theme(
          // The expansion tile draws its own divider lines, which fight the
          // card border.
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 8),
            title: Text(
              context.tr('Advanced calculation settings'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            iconColor: colors.accent,
            collapsedIconColor: colors.accent,
            children: [
              const FieldLabel('Calculation method'),
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
                        contentPadding: EdgeInsets.zero,
                        title: Text(method.name),
                        subtitle: Text(
                          'Fajr ${method.fajrAngle}° · Isha '
                          '${method.ishaMode == IshaMode.interval ? '${method.ishaInterval} min' : '${method.ishaAngle}°'}',
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const FieldLabel('Asr calculation'),
              RadioGroup<AsrMadhab>(
                groupValue: settings.asrMadhab,
                onChanged: (value) {
                  if (value != null) settings.setAsrMadhab(value);
                },
                child: Column(
                  children: [
                    for (final value in AsrMadhab.values)
                      RadioListTile<AsrMadhab>(
                        value: value,
                        contentPadding: EdgeInsets.zero,
                        title: Text(context.tr(value.label)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const FieldLabel('High latitude rule'),
              RadioGroup<HighLatitudeRule>(
                groupValue: settings.highLatitudeRule,
                onChanged: (value) {
                  if (value != null) settings.setHighLatitudeRule(value);
                },
                child: Column(
                  children: [
                    for (final value in HighLatitudeRule.values)
                      RadioListTile<HighLatitudeRule>(
                        value: value,
                        contentPadding: EdgeInsets.zero,
                        title: Text(context.tr(value.label)),
                      ),
                  ],
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: settings.resetToAutomatic,
                  icon: const Icon(Icons.auto_mode_rounded, size: 18),
                  label: Text(context.tr('Use automatic regional defaults')),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Correction for a mosque's printed timetable.
  Widget _adjust(PrayerSettings settings) => SectionCard(
    title: 'Adjust times',
    icon: Icons.more_time_rounded,
    children: [
      NoticeRow(
        context.tr(
          'If your mosque publishes times a few minutes apart from these, shift each prayer to match. Reminders follow the adjusted time.',
        ),
      ),
      const SizedBox(height: 6),
      for (final prayer in Prayer.values)
        _OffsetRow(
          label: context.tr(prayer.label),
          minutes: settings.offsetFor(prayer),
          onChanged: (value) => settings.setOffset(prayer, value),
        ),
      if (settings.hasOffsets)
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: settings.clearOffsets,
            icon: const Icon(Icons.restart_alt_rounded, size: 18),
            label: Text(context.tr('Reset adjustments')),
          ),
        ),
    ],
  );

  Widget _widget() => SectionCard(
    title: 'Home-screen widget',
    icon: Icons.widgets_outlined,
    children: [
      Text(
        context.tr('Next prayer on your home screen'),
        style: TextStyle(color: AppColors.of(context).muted),
      ),
      const SizedBox(height: 12),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: OutlinedButton.icon(
          onPressed: _busy ? null : _addWidget,
          icon: const Icon(Icons.add_to_home_screen_rounded, size: 18),
          label: Text(context.tr('Add widget')),
        ),
      ),
    ],
  );

  Widget _about() {
    final colors = AppColors.of(context);
    return SectionCard(
      title: 'About',
      icon: Icons.info_outline_rounded,
      children: [
        Text(
          '${AppInfo.name} ${AppInfo.version}',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          context
              .tr('Built by {developer}')
              .replaceAll('{developer}', AppInfo.developer),
          style: TextStyle(color: colors.muted),
        ),
        const SizedBox(height: 12),
        Text(
          context.tr(
            'Prayer times and the Qibla are calculated, not fetched. If a time '
            'does not match your mosque, adjust it above and tell me what you '
            'expected.',
          ),
          style: TextStyle(color: colors.muted),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _emailDeveloper,
              icon: const Icon(Icons.mail_outline_rounded, size: 18),
              label: Text(context.tr('Contact the developer')),
            ),
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PrivacyPolicyScreen(),
                ),
              ),
              icon: const Icon(Icons.privacy_tip_outlined, size: 18),
              label: Text(context.tr('Privacy policy')),
            ),
          ],
        ),
      ],
    );
  }

  /// Pre-fills the version so a report says which build it came from.
  Future<void> _emailDeveloper() => _action(() async {
    final uri = Uri(
      scheme: 'mailto',
      path: AppInfo.supportEmail,
      queryParameters: {
        'subject': '${AppInfo.name} ${AppInfo.version}',
      },
    );
    if (!await launchUrl(uri)) {
      throw StateError('No mail app');
    }
  });

  void _addWidget() => _action(() async {
    await widget.settings.flushed;
    await BackgroundRefresh.refresh(
      widget.controller.database,
      propagateErrors: true,
    );
    if (await HomeWidget.isRequestPinWidgetSupported() == true) {
      await HomeWidget.requestPinWidget(
        qualifiedAndroidName: 'com.example.qibla_finder.PrayerWidgetProvider',
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Long-press your home screen, choose Widgets, then Qibla Finder.',
            ),
          ),
        ),
      );
    }
  });
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      const SizedBox(width: 12),
      Switch(value: value, onChanged: onChanged),
    ],
  );
}

/// A per-prayer opt-in.
class _PrayerChip extends StatelessWidget {
  const _PrayerChip({
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      avatar: Icon(
        selected ? Icons.check_circle_rounded : Icons.circle_outlined,
        size: 17,
        color: selected ? colors.accent : colors.muted,
      ),
      selectedColor: colors.accentWash,
      side: BorderSide(color: selected ? colors.accent : colors.cardBorder),
      labelStyle: TextStyle(
        fontWeight: selected ? FontWeight.w700 : null,
        color: selected ? colors.accent : null,
      ),
      onSelected: onChanged,
    );
  }
}

/// One prayer's correction, as a stepper.
///
/// A chip row cannot carry sixty-one values, and a free text field invites
/// nonsense; stepping by a minute is how people actually reconcile a printed
/// timetable.
class _OffsetRow extends StatelessWidget {
  const _OffsetRow({
    required this.label,
    required this.minutes,
    required this.onChanged,
  });

  final String label;
  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final text = minutes == 0
        ? context.tr('On time')
        : '${minutes > 0 ? '+' : ''}$minutes';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
          IconButton(
            onPressed: minutes <= -PrayerSettings.maxOffset
                ? null
                : () => onChanged(minutes - 1),
            icon: Icon(
              Icons.remove_circle_outline_rounded,
              semanticLabel: context
                  .tr('{prayer} one minute earlier')
                  .replaceAll('{prayer}', label),
            ),
          ),
          SizedBox(
            width: 64,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: minutes == 0 ? FontWeight.w500 : FontWeight.w700,
                color: minutes == 0 ? colors.muted : colors.accent,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          IconButton(
            onPressed: minutes >= PrayerSettings.maxOffset
                ? null
                : () => onChanged(minutes + 1),
            icon: Icon(
              Icons.add_circle_outline_rounded,
              semanticLabel: context
                  .tr('{prayer} one minute later')
                  .replaceAll('{prayer}', label),
            ),
          ),
        ],
      ),
    );
  }
}
