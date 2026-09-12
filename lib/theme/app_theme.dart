import 'package:flutter/material.dart';

/// Fixed brand constants.
///
/// These never vary with the light/dark setting. The Qibla dial, the app bar
/// and the "next prayer" hero are painted from them in every theme, which is
/// what makes the three tabs read as one app rather than a compass bolted to
/// a stock Material settings page.
class AppBrand {
  const AppBrand._();

  /// Deepest ground, the bottom of every hero gradient.
  static const Color ink = Color(0xFF07160F);

  /// Top of every hero gradient, and the app bar in every theme.
  static const Color inkSoft = Color(0xFF0E2C1E);

  /// The signature mint. Legible only on [ink]/[inkSoft], never on a light
  /// surface — use [AppColors.accent] for anything sitting on the page.
  static const Color mint = Color(0xFF23C486);

  /// The deep green that carries the accent role on light surfaces.
  static const Color forest = Color(0xFF156F3F);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [inkSoft, ink],
  );
}

/// Kept for the Qibla tab, which is dark in every theme.
class QiblaPalette {
  const QiblaPalette._();

  static const Color ink = AppBrand.ink;
  static const Color inkSoft = AppBrand.inkSoft;
  static const Color accent = AppBrand.mint;
  static const Color onDark = Colors.white;
  static Color onDarkMuted = Colors.white.withValues(alpha: 0.58);
}

/// Semantic colours that do vary with the theme.
///
/// Read them with `AppColors.of(context)` rather than reaching for a raw hex,
/// so a palette change lands everywhere at once.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.accent,
    required this.accentWash,
    required this.cardBorder,
    required this.muted,
    required this.caution,
    required this.cautionWash,
    required this.danger,
    required this.dangerWash,
  });

  /// Interactive green for text and icons sitting on the page surface.
  final Color accent;

  /// A faint tint of [accent] for selected rows and success notices.
  final Color accentWash;
  final Color cardBorder;

  /// Secondary text.
  final Color muted;
  final Color caution;
  final Color cautionWash;
  final Color danger;
  final Color dangerWash;

  static AppColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppColors>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  static const AppColors light = AppColors(
    accent: Color(0xFF0B6B3F),
    accentWash: Color(0xFFE3F3EA),
    cardBorder: Color(0xFFDCE7E0),
    muted: Color(0xFF5A6B62),
    caution: Color(0xFF8A5A00),
    cautionWash: Color(0xFFFBF0DC),
    danger: Color(0xFFB3261E),
    dangerWash: Color(0xFFFAE4E2),
  );

  static const AppColors dark = AppColors(
    accent: AppBrand.mint,
    accentWash: Color(0xFF16382A),
    cardBorder: Color(0xFF24422F),
    muted: Color(0xFF9BB0A4),
    caution: Color(0xFFFFC46B),
    cautionWash: Color(0xFF33280F),
    danger: Color(0xFFFF6B6B),
    dangerWash: Color(0xFF3A1B1B),
  );

  @override
  AppColors copyWith({
    Color? accent,
    Color? accentWash,
    Color? cardBorder,
    Color? muted,
    Color? caution,
    Color? cautionWash,
    Color? danger,
    Color? dangerWash,
  }) => AppColors(
    accent: accent ?? this.accent,
    accentWash: accentWash ?? this.accentWash,
    cardBorder: cardBorder ?? this.cardBorder,
    muted: muted ?? this.muted,
    caution: caution ?? this.caution,
    cautionWash: cautionWash ?? this.cautionWash,
    danger: danger ?? this.danger,
    dangerWash: dangerWash ?? this.dangerWash,
  );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      accent: Color.lerp(accent, other.accent, t)!,
      accentWash: Color.lerp(accentWash, other.accentWash, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      caution: Color.lerp(caution, other.caution, t)!,
      cautionWash: Color.lerp(cautionWash, other.cautionWash, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerWash: Color.lerp(dangerWash, other.dangerWash, t)!,
    );
  }
}

class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(
    ColorScheme.fromSeed(
      seedColor: AppBrand.forest,
      surface: const Color(0xFFF4F8F5),
      surfaceContainerHighest: const Color(0xFFE7EFE9),
      primary: AppBrand.forest,
      secondaryContainer: const Color(0xFFD9EEE2),
      onSecondaryContainer: const Color(0xFF0B2418),
    ),
    AppColors.light,
    const Color(0xFFFFFFFF),
  );

  static ThemeData get dark => _build(
    ColorScheme.fromSeed(
      seedColor: AppBrand.mint,
      brightness: Brightness.dark,
      surface: const Color(0xFF06140E),
      surfaceContainerHighest: const Color(0xFF19382A),
      primary: AppBrand.mint,
      onPrimary: AppBrand.ink,
      secondaryContainer: const Color(0xFF16382A),
      onSecondaryContainer: Colors.white,
    ),
    AppColors.dark,
    const Color(0xFF122C1F),
  );

  static ThemeData _build(
    ColorScheme scheme,
    AppColors colors,
    Color cardColor,
  ) {
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      extensions: [colors],
      // One dark bar in every theme and on every tab, so moving between the
      // compass and the schedule never flashes a different header.
      appBarTheme: const AppBarTheme(
        backgroundColor: AppBrand.inkSoft,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.cardBorder),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardColor,
        indicatorColor: colors.accentWash,
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.muted),
        ),
      ),
      dividerTheme: DividerThemeData(color: colors.cardBorder, space: 1),
      chipTheme: ChipThemeData(
        side: BorderSide(color: colors.cardBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      listTileTheme: ListTileThemeData(iconColor: colors.accent),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: colors.accent),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.accent,
          side: BorderSide(color: colors.cardBorder),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
