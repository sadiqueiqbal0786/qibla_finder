/// Facts about this build, shown in Settings and used for support.
///
/// [version] is asserted against `pubspec.yaml` by `test/app_info_test.dart`,
/// so it cannot quietly go stale after a release bump.
class AppInfo {
  const AppInfo._();

  static const String name = 'Qibla Finder';
  static const String version = '2.2.0';
  static const String developer = 'Sadique Iqbal';

  /// Already published in the privacy policy, so this is not a new disclosure.
  static const String supportEmail = 'sadiqueiqbal.si@gmail.com';
}
