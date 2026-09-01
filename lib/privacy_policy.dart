import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const List<(String, String)> _sections = <(String, String)>[
    (
      'Information We Collect',
      'We do not collect any personal information or store any user data on '
          'our servers. Your location is read on your device only, purely to '
          'calculate the Qibla direction, and it never leaves the device.',
    ),
    (
      'How We Use Information',
      'Since we do not collect any personal information, we do not use or '
          'share any data. This app contains no analytics and no tracking.',
    ),
    (
      'Permissions',
      'Location permission is required to compute the direction of the Kaaba '
          'from where you are. The compass reading comes from your device '
          'magnetometer. Neither is transmitted anywhere.',
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
        backgroundColor: const Color(0xFF156F3F),
        foregroundColor: Colors.white,
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          children: [
            const Text(
              'Our Commitment to Your Privacy',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Welcome to Advance Qibla Finder. We are committed to protecting '
              'your privacy and ensuring a safe experience for everyone.',
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.black.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 8),
            for (final (title, body) in _sections) ...[
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.black.withValues(alpha: 0.72),
                ),
              ),
            ],
            const SizedBox(height: 28),
            Text(
              'Last updated: 1 September 2026',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
