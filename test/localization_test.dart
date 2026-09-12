import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_finder/l10n/app_strings.dart';

/// Every user-facing literal routed through `tr` must resolve in Hindi and
/// Urdu. A missing entry falls back to English silently, which shows up as a
/// half-translated screen rather than a crash, so only a test catches it.
void main() {
  final definitions = File('lib/l10n/app_strings.dart').readAsStringSync();
  final defined = RegExp(
    '^\\s*(?:\'((?:[^\'\\\\]|\\\\.)*)\'|"((?:[^"\\\\]|\\\\.)*)"):\\s*\\[',
    multiLine: true,
  ).allMatches(definitions).map((m) => m.group(1) ?? m.group(2)!).toSet();

  test('every translated key has a Hindi and an Urdu value', () {
    for (final key in defined) {
      for (final language in ['hi', 'ur']) {
        final value = AppStrings.translate(key, language);
        expect(value, isNotEmpty, reason: '$key has no $language value');
        expect(
          value,
          isNot(key),
          reason: '$key is untranslated in $language',
        );
      }
    }
  });

  test('placeholders survive translation', () {
    final placeholder = RegExp(r'\{\w+\}');
    for (final key in defined.where((k) => placeholder.hasMatch(k))) {
      final wanted = placeholder.allMatches(key).map((m) => m[0]).toSet();
      for (final language in ['hi', 'ur']) {
        final got = placeholder
            .allMatches(AppStrings.translate(key, language))
            .map((m) => m[0])
            .toSet();
        expect(got, wanted, reason: '$key drops a placeholder in $language');
      }
    }
  });

  test('every minute option both pickers offer is translated', () {
    // These keys are assembled at runtime, so the source scan below cannot
    // see them.
    for (final minutes in [5, 10, 15, 30, 45, 60]) {
      final key = '$minutes minutes before';
      expect(defined, contains(key), reason: '$key is missing');
    }
  });

  test('literals passed to tr are all translated', () {
    final call = RegExp(
      'tr\\(\\s*(?:\'((?:[^\'\\\\\\n]|\\\\.)*)\'|"((?:[^"\\\\\\n]|\\\\.)*)")\\s*[,)]',
      multiLine: true,
    );
    final missing = <String, String>{};
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.contains('l10n')) continue;
      final source = entity.readAsStringSync();
      for (final match in call.allMatches(source)) {
        final key = (match.group(1) ?? match.group(2)!).replaceAll(r'\$', r'$');
        if (key.contains(r'$')) continue; // built at runtime
        if (!defined.contains(key)) missing[key] = entity.path;
      }
    }
    expect(missing, isEmpty, reason: 'untranslated literals: $missing');
  });
}
