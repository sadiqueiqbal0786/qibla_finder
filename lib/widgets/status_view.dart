import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';

/// A full-screen, always-actionable state.
///
/// Every non-ready status routes here, so there is no path through the app
/// that leaves the user staring at a spinner with nothing to tap. The previous
/// build deadlocked exactly this way when location permission was permanently
/// denied.
class StatusView extends StatelessWidget {
  const StatusView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.busy = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E2C1E), Color(0xFF07160F)],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 46, color: const Color(0xFF23C486)),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    context.tr(title),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    context.tr(message),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: Colors.white.withValues(alpha: 0.66),
                    ),
                  ),
                  const SizedBox(height: 26),
                  if (primaryLabel != null)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: busy ? null : onPrimary,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF23C486),
                          foregroundColor: const Color(0xFF07160F),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(context.tr(primaryLabel!)),
                      ),
                    ),
                  if (secondaryLabel != null) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: busy ? null : onSecondary,
                      child: Text(
                        context.tr(secondaryLabel!),
                        style: const TextStyle(color: Color(0xFF23C486)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Caps content width and centres it.
///
/// Phone layouts stretched edge to edge on a tablet, giving line lengths past
/// comfortable reading. Constraining the column keeps one design working on
/// both rather than needing a separate tablet layout.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = 620});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
