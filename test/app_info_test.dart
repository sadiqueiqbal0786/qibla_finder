import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_finder/app_info.dart';

void main() {
  test('the version shown in About matches pubspec', () {
    // Otherwise a release bump leaves About reporting the previous build, and
    // a support mail names the wrong version.
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final declared = RegExp(
      r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)',
      multiLine: true,
    ).firstMatch(pubspec);
    expect(declared, isNotNull, reason: 'no version in pubspec.yaml');
    expect(AppInfo.version, declared!.group(1));
  });

  test('the support address matches the one in the privacy policy', () {
    final policy = File('lib/privacy_policy.dart').readAsStringSync();
    expect(policy, contains(AppInfo.supportEmail));
  });
}
