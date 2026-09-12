import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// A titled group of related controls.
///
/// The previous settings screen was one flat column of switches, dropdowns
/// and dividers, so nothing was visibly grouped. Boxing each concern makes
/// the page scannable and gives the screen the same soft-cornered geometry as
/// the Qibla tab's glass panels.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.children,
    this.icon,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 16),
  });

  final String title;
  final IconData? icon;
  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: colors.accent),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    context.tr(title),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// A quiet label above a group of choices.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      context.tr(text),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: AppColors.of(context).muted,
      ),
    ),
  );
}

/// A wrapping row of single-choice chips.
///
/// Chips replaced dropdowns because every one of these settings has three to
/// five options: the choices are visible without a tap, and [Wrap] reflows
/// instead of overflowing when the system text size is large.
class ChoiceRow<T> extends StatelessWidget {
  const ChoiceRow({
    super.key,
    required this.value,
    required this.choices,
    required this.onChanged,
  });

  final T value;
  final Map<T, String> choices;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in choices.entries)
          ChoiceChip(
            label: Text(entry.value),
            selected: entry.key == value,
            showCheckmark: false,
            selectedColor: colors.accentWash,
            side: BorderSide(
              color: entry.key == value ? colors.accent : colors.cardBorder,
            ),
            labelStyle: TextStyle(
              fontWeight: entry.key == value ? FontWeight.w700 : null,
              color: entry.key == value ? colors.accent : null,
            ),
            onSelected: (_) => onChanged(entry.key),
          ),
      ],
    );
  }
}

/// Severity of a [NoticeRow].
enum NoticeTone { info, good, caution, bad }

/// An inline explanation or warning.
class NoticeRow extends StatelessWidget {
  const NoticeRow(this.text, {super.key, this.tone = NoticeTone.info, this.icon});

  final String text;
  final NoticeTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final (Color fill, Color ink, IconData glyph) = switch (tone) {
      NoticeTone.good => (
        colors.accentWash,
        colors.accent,
        Icons.check_circle_outline_rounded,
      ),
      NoticeTone.caution => (
        colors.cautionWash,
        colors.caution,
        Icons.warning_amber_rounded,
      ),
      NoticeTone.bad => (
        colors.dangerWash,
        colors.danger,
        Icons.error_outline_rounded,
      ),
      NoticeTone.info => (
        Theme.of(context).colorScheme.surfaceContainerHighest,
        colors.muted,
        Icons.info_outline_rounded,
      ),
    };

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? glyph, size: 18, color: ink),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: tone == NoticeTone.info
                    ? Theme.of(context).colorScheme.onSurface
                    : ink,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The signature dark panel.
///
/// Always painted in brand colours so the "next prayer" card echoes the
/// compass tab even when the app is running in the light theme.
class HeroPanel extends StatelessWidget {
  const HeroPanel({super.key, required this.child, this.padding = const EdgeInsets.all(20)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: AppBrand.heroGradient,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      boxShadow: [
        BoxShadow(
          color: AppBrand.ink.withValues(alpha: 0.28),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Padding(padding: padding, child: child),
  );
}
