import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/status_view.dart';

/// The first launch, before anything asks for a permission.
///
/// The app used to open straight onto the system location dialog with no
/// explanation. That is the one prompt a user cannot easily undo: a refusal
/// leaves the compass and the schedule with nothing to work from, and Android
/// will not ask twice. So the reason comes first, and picking a city is
/// offered as a peer of using the device location rather than as the fallback
/// you reach for after saying no.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.onUseLocation,
    required this.onChooseCity,
  });

  final VoidCallback onUseLocation;
  final VoidCallback onChooseCity;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppBrand.heroGradient),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: ContentWidth(
              maxWidth: 460,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/icon/icon_monochrome.png',
                      width: 76,
                      height: 76,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.explore_rounded,
                        size: 68,
                        color: AppBrand.mint,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    context.tr('Qibla Finder'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    context.tr(
                      'The Qibla direction and your prayer times both depend on where you are.',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: QiblaPalette.onDarkMuted,
                    ),
                  ),
                  const SizedBox(height: 26),
                  const _Point(
                    icon: Icons.offline_bolt_outlined,
                    text: 'Everything is calculated on your device and works '
                        'offline.',
                  ),
                  const _Point(
                    icon: Icons.location_city_rounded,
                    text: 'No location? Pick your city instead. Nothing is '
                        'lost either way.',
                  ),
                  const _Point(
                    icon: Icons.lock_outline_rounded,
                    text: 'We do not run a server that collects where you are.',
                  ),
                  const SizedBox(height: 30),
                  FilledButton(
                    onPressed: onUseLocation,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppBrand.mint,
                      foregroundColor: AppBrand.ink,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      context.tr('Use my location'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Same size and weight as the button above: this is a
                  // choice between two routes, not a way out of a refusal.
                  OutlinedButton(
                    onPressed: onChooseCity,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppBrand.mint,
                      side: BorderSide(
                        color: AppBrand.mint.withValues(alpha: 0.55),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      context.tr('Choose a city'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: AppBrand.mint),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            context.tr(text),
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );
}
