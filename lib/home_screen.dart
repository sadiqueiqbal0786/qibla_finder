import 'package:flutter/material.dart';

import 'qibla_controller.dart';
import 'qibla_logic.dart';
import 'services/compass_service.dart';
import 'widgets/qibla_compass.dart';
import 'widgets/status_view.dart';

/// Palette shared by the Qibla surface.
class QiblaPalette {
  const QiblaPalette._();

  static const Color ink = Color(0xFF07160F);
  static const Color inkSoft = Color(0xFF0E2C1E);
  static const Color accent = Color(0xFF23C486);
  static const Color onDark = Colors.white;
  static Color onDarkMuted = Colors.white.withValues(alpha: 0.58);
}

/// The Qibla tab.
///
/// The controller is owned by the app shell, so the prayer-times tab shares a
/// single location fix instead of requesting its own.
class QiblaScreen extends StatelessWidget {
  const QiblaScreen({super.key, required this.controller});

  final QiblaController controller;

  @override
  Widget build(BuildContext context) => _buildBody();

  Widget _buildBody() {
    switch (controller.status) {
      case QiblaStatus.initializing:
        return const _LoadingView();

      case QiblaStatus.serviceDisabled:
        return StatusView(
          icon: Icons.location_off_rounded,
          title: 'Location is turned off',
          message:
              'Turn on location services so the Qibla direction can be worked '
              'out for where you are.',
          primaryLabel: 'Open location settings',
          onPrimary: controller.openLocationSettings,
          secondaryLabel: 'Try again',
          onSecondary: controller.refresh,
          busy: controller.isRefreshing,
        );

      case QiblaStatus.permissionDenied:
        return StatusView(
          icon: Icons.lock_outline_rounded,
          title: 'Location permission needed',
          message:
              'The Qibla direction depends on where you are. Your location is '
              'only used on this device and is never uploaded.',
          primaryLabel: 'Grant permission',
          onPrimary: controller.refresh,
          busy: controller.isRefreshing,
        );

      case QiblaStatus.permissionDeniedForever:
        return StatusView(
          icon: Icons.app_settings_alt_rounded,
          title: 'Permission blocked',
          message:
              'Location permission is permanently denied. Enable it under '
              'Permissions in the app settings, then come back.',
          primaryLabel: 'Open app settings',
          onPrimary: controller.openAppSettings,
          secondaryLabel: 'Try again',
          onSecondary: controller.refresh,
          busy: controller.isRefreshing,
        );

      case QiblaStatus.timedOut:
        return StatusView(
          icon: Icons.satellite_alt_rounded,
          title: 'Could not get a location fix',
          message:
              'No GPS signal reached the device. Moving near a window or going '
              'outside usually fixes this.',
          primaryLabel: 'Try again',
          onPrimary: controller.refresh,
          busy: controller.isRefreshing,
        );

      case QiblaStatus.failed:
        return StatusView(
          icon: Icons.error_outline_rounded,
          title: 'Something went wrong',
          message:
              'The Qibla direction could not be calculated. Please try again.',
          primaryLabel: 'Try again',
          onPrimary: controller.refresh,
          busy: controller.isRefreshing,
        );

      case QiblaStatus.ready:
        return _CompassView(controller: controller);
    }
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [QiblaPalette.inkSoft, QiblaPalette.ink],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: QiblaPalette.accent),
            SizedBox(height: 18),
            Text(
              'Finding your location…',
              style: TextStyle(fontSize: 15, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

/// The redesigned Qibla surface.
///
/// The previous layout stacked four solid tiles, a banner, a readout chip and
/// the dial over a full-bleed photograph, so nothing had priority and the
/// compass competed with the background. This version keeps a single focal
/// point — the dial and the turn instruction — on a calm gradient, and demotes
/// everything else to one quiet row.
class _CompassView extends StatelessWidget {
  const _CompassView({required this.controller});

  final QiblaController controller;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final compassSize = (media.size.shortestSide * 0.78).clamp(240.0, 380.0);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [QiblaPalette.inkSoft, QiblaPalette.ink],
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          color: QiblaPalette.accent,
          backgroundColor: QiblaPalette.inkSoft,
          onRefresh: controller.refresh,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  // IntrinsicHeight gives the Column a bounded height, which
                  // Spacer requires. Without it the flex children have no
                  // height to distribute inside a scroll view and the whole
                  // subtree fails to lay out.
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      child: Column(
                        children: [
                          _PlaceLine(controller: controller),
                          const SizedBox(height: 6),
                          _TrustLine(compass: controller.compass),
                          const Spacer(),
                          QiblaCompass(
                            compass: controller.compass,
                            qiblaBearing: controller.qiblaBearing,
                            size: compassSize,
                          ),
                          const SizedBox(height: 30),
                          _TurnInstruction(controller: controller),
                          const Spacer(),
                          _FactsRow(controller: controller),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Where we think the user is — quiet, single line, tappable to refresh.
class _PlaceLine extends StatelessWidget {
  const _PlaceLine({required this.controller});

  final QiblaController controller;

  @override
  Widget build(BuildContext context) {
    final place =
        controller.placeName ??
        (controller.positionIsStale ? 'Last known location' : 'Locating…');

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.place_outlined, size: 15, color: QiblaPalette.onDarkMuted),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            place,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: QiblaPalette.onDarkMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (controller.positionIsStale) ...[
          const SizedBox(width: 6),
          Icon(
            Icons.history_rounded,
            size: 14,
            color: QiblaPalette.onDarkMuted,
          ),
        ],
      ],
    );
  }
}

/// One-line compass trust state. Only speaks up when there is something worth
/// saying, so the calm state stays calm.
class _TrustLine extends StatelessWidget {
  const _TrustLine({required this.compass});

  final CompassService compass;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<CompassConfidence>(
      valueListenable: compass.confidence,
      builder: (context, confidence, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: compass.interferenceDetected,
          builder: (context, interference, _) {
            final (String text, Color color, IconData icon)? notice = switch ((
              interference,
              confidence,
            )) {
              (true, _) => (
                'Magnetic interference — move away from metal and electronics',
                const Color(0xFFFF6B6B),
                Icons.warning_amber_rounded,
              ),
              (_, CompassConfidence.unavailable) => (
                'No compass sensor — use the angle below with a separate compass',
                const Color(0xFFFF6B6B),
                Icons.explore_off_rounded,
              ),
              (_, CompassConfidence.low) => (
                'Low accuracy — wave the phone in a figure-8',
                const Color(0xFFFFC46B),
                Icons.gesture_rounded,
              ),
              (_, CompassConfidence.medium) => (
                'Fair accuracy — a figure-8 motion will sharpen it',
                const Color(0xFFFFC46B),
                Icons.gesture_rounded,
              ),
              _ => null,
            };

            if (notice == null) return const SizedBox(height: 20);

            return SizedBox(
              height: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(notice.$3, size: 14, color: notice.$2),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      notice.$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: notice.$2),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// The single most important thing on the screen.
class _TurnInstruction extends StatelessWidget {
  const _TurnInstruction({required this.controller});

  final QiblaController controller;

  @override
  Widget build(BuildContext context) {
    final bearing = controller.qiblaBearing;
    if (bearing == null) return const SizedBox(height: 78);

    return ValueListenableBuilder<double?>(
      valueListenable: controller.compass.trueHeading,
      builder: (context, heading, _) {
        if (heading == null) {
          return _Instruction(
            headline:
                '${bearing.toStringAsFixed(0)}° ${QiblaDirection.cardinal(bearing)}',
            caption: 'Waiting for the compass…',
            aligned: false,
          );
        }

        final delta = QiblaDirection.shortestDelta(heading, bearing);
        if (delta.abs() <= 5) {
          return const _Instruction(
            headline: 'Facing the Qibla',
            caption: 'You are aligned with the Kaaba',
            aligned: true,
          );
        }

        final right = delta > 0;
        return _Instruction(
          headline: 'Turn ${right ? 'right' : 'left'} ${delta.abs().round()}°',
          caption:
              'Qibla is ${bearing.toStringAsFixed(0)}° ${QiblaDirection.cardinal(bearing)}',
          aligned: false,
        );
      },
    );
  }
}

class _Instruction extends StatelessWidget {
  const _Instruction({
    required this.headline,
    required this.caption,
    required this.aligned,
  });

  final String headline;
  final String caption;
  final bool aligned;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: TextStyle(
              fontSize: aligned ? 27 : 30,
              height: 1.1,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: aligned ? QiblaPalette.accent : QiblaPalette.onDark,
            ),
            child: Text(headline, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 5),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: QiblaPalette.onDarkMuted),
          ),
        ],
      ),
    );
  }
}

/// Supporting numbers, demoted to a single quiet row along the bottom.
class _FactsRow extends StatelessWidget {
  const _FactsRow({required this.controller});

  final QiblaController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double?>(
      valueListenable: controller.compass.declination,
      builder: (context, declination, _) {
        final distance = controller.distanceKm;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              _Fact(
                label: 'Qibla',
                value: controller.qiblaBearing == null
                    ? '—'
                    : '${controller.qiblaBearing!.toStringAsFixed(1)}°',
              ),
              _FactDivider(),
              _Fact(
                label: 'To Makkah',
                value: distance == null
                    ? '—'
                    : '${_thousands(distance.round())} km',
              ),
              _FactDivider(),
              _Fact(
                label: 'Declination',
                value: declination == null
                    ? '—'
                    : '${declination.abs().toStringAsFixed(1)}°'
                          '${declination >= 0 ? 'E' : 'W'}',
                hint: declination == null ? null : 'Corrected to true north',
              ),
            ],
          ),
        );
      },
    );
  }

  static String _thousands(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return '${value < 0 ? '-' : ''}$buffer';
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value, this.hint});

  final String label;
  final String value;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: QiblaPalette.onDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 0.4,
              color: QiblaPalette.onDarkMuted,
            ),
          ),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                hint!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  color: QiblaPalette.accent.withValues(alpha: 0.85),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FactDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white.withValues(alpha: 0.09),
    );
  }
}
