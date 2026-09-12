import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_finder/theme/app_theme.dart';

void main() {
  test('both themes carry the semantic colours screens read', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      expect(theme.extension<AppColors>(), isNotNull);
    }
  });

  test('the app bar is the brand ink in every theme', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      expect(theme.appBarTheme.backgroundColor, AppBrand.inkSoft);
      expect(theme.appBarTheme.foregroundColor, Colors.white);
    }
  });

  testWidgets('a screen built under a bare theme still resolves colours', (
    tester,
  ) async {
    // AppColors.of must degrade rather than throw, so a widget shown outside
    // the app's own MaterialApp cannot crash on a missing extension.
    late AppColors resolved;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Builder(
          builder: (context) {
            resolved = AppColors.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(resolved.accent, AppColors.dark.accent);
  });

  test('page, card and hero are three distinct values in dark', () {
    // The first cut had the card within one step of the page and the cards
    // dissolved into the background.
    final scheme = AppTheme.dark.colorScheme;
    final card = AppTheme.dark.cardTheme.color!;
    expect(scheme.surface, isNot(card));
    expect(_luminanceGap(scheme.surface, card), greaterThan(0.004));
    expect(_luminanceGap(scheme.surface, AppBrand.inkSoft), greaterThan(0.004));
  });
}

double _luminanceGap(Color a, Color b) =>
    (a.computeLuminance() - b.computeLuminance()).abs();
