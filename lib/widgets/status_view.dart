import 'package:flutter/material.dart';

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
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
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
                            : Text(primaryLabel!),
                      ),
                    ),
                  if (secondaryLabel != null) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: busy ? null : onSecondary,
                      child: Text(
                        secondaryLabel!,
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

/// Banner shown above the compass when the magnetometer cannot be trusted.
class CalibrationBanner extends StatelessWidget {
  const CalibrationBanner({
    super.key,
    required this.message,
    required this.severe,
    this.neutral = false,
  });

  final String message;
  final bool severe;

  /// Informational rather than a warning (used for the declination notice).
  final bool neutral;

  @override
  Widget build(BuildContext context) {
    final color = neutral
        ? const Color(0xFF15243A)
        : (severe ? const Color(0xFFB3261E) : const Color(0xFF8A5A00));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            neutral
                ? Icons.check_circle_outline_rounded
                : (severe
                      ? Icons.warning_amber_rounded
                      : Icons.explore_rounded),
            color: Colors.white,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.3,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
