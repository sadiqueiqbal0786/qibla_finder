import 'package:flutter/material.dart';
import 'l10n/app_strings.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const List<(String, String)> _sections = <(String, String)>[
    (
      'Information We Collect',
      'Qibla and prayer-time calculations run on your device. Your selected or last known location and settings are saved locally. We do not operate a server that collects your location. City search and city-name lookup use your device’s geocoding provider, which may send a search query or coordinates to its service.',
    ),
    (
      'How We Use Information',
      'This app contains no analytics or advertising trackers. Saved settings and location support offline calculations and reminder renewal. Platform services handle geocoding and app updates as described here.',
    ),
    (
      'Permissions',
      'Location permission is optional: choose a city manually or use your device’s current location. The compass uses the device magnetometer. Notification permission enables prayer reminders; precise alarm access is optional. Android renews schedules in the background using the saved location without requesting background location. Google Play handles app-update checks and downloads.',
    ),
    (
      'Contact Us',
      'If you have any questions or concerns about this privacy policy, '
          'please contact us at sadiqueiqbal.si@gmail.com.',
    ),
    (
      'Policy Changes',
      'We reserve the right to update this privacy policy at any time. Any '
          'changes will be reflected on this page.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('Privacy policy'),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          children: [
            Text(
              context.tr('Our Commitment to Your Privacy'),
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              context.tr(
                'Welcome to Qibla Finder. We are committed to protecting your privacy and ensuring a safe experience for everyone.',
              ),
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            for (final (title, body) in _sections) ...[
              const SizedBox(height: 20),
              Text(
                context.tr(title),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr(body),
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 28),
            Text(
              context.tr('Last updated: 12 September 2026'),
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
