import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../qibla_logic.dart';
import '../services/compass_service.dart';

/// A fully vector-drawn Qibla compass.
///
/// Design intent, in priority order:
///  1. A fixed index chevron at the top says "this is where your phone points".
///     Without it a rotating dial is ambiguous and users cannot tell which way
///     to turn.
///  2. A gold beam and Kaaba badge mark the target, so the goal is legible
///     before you read any text.
///  3. Gold target versus white dial versus green success keeps the states
///     distinguishable; the previous all-green rendering read as one blob.
class QiblaCompass extends StatelessWidget {
  const QiblaCompass({
    super.key,
    required this.compass,
    required this.qiblaBearing,
    this.size = 300,
  });

  final CompassService compass;
  final double? qiblaBearing;
  final double size;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: ValueListenableBuilder<double?>(
          // True-north heading: a Qibla bearing is measured from true north,
          // so the raw magnetic reading would be off by the declination.
          valueListenable: compass.trueHeading,
          builder: (context, heading, _) {
            final bearing = qiblaBearing;
            final delta = (heading != null && bearing != null)
                ? QiblaDirection.shortestDelta(heading, bearing)
                : null;

            return CustomPaint(
              size: Size.square(size),
              painter: _CompassPainter(
                heading: heading,
                qiblaBearing: bearing,
                delta: delta,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  _CompassPainter({
    required this.heading,
    required this.qiblaBearing,
    required this.delta,
  });

  final double? heading;
  final double? qiblaBearing;

  /// Signed shortest turn to the Qibla, or null while the compass warms up.
  final double? delta;

  bool get aligned => delta != null && delta!.abs() <= 5;
  bool get close => delta != null && delta!.abs() <= 20;

  static const Color _gold = Color(0xFFE9B44C);
  static const Color _green = Color(0xFF23C486);
  static const Color _ink = Color(0xFF07160F);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    // The index chevron lives above the dial, so inset the dial to leave room.
    final dialR = r - 16;

    _paintBackplate(canvas, center, dialR);

    canvas.save();
    canvas.translate(center.dx, center.dy);

    // Everything inside this rotation is world-referenced (north stays north).
    canvas.save();
    canvas.rotate(-_rad(heading ?? 0));
    _paintTicks(canvas, dialR);
    _paintCardinals(canvas, dialR);
    canvas.restore();

    // The target is drawn device-referenced, at (qibla - heading).
    if (qiblaBearing != null) {
      canvas.save();
      canvas.rotate(_rad(QiblaDirection.normalize(
          qiblaBearing! - (heading ?? 0))));
      _paintQiblaBeam(canvas, dialR);
      _paintKaabaBadge(canvas, dialR);
      canvas.restore();
    }

    _paintCentre(canvas, dialR);
    canvas.restore();

    _paintIndex(canvas, center, r);
  }

  // ------------------------------------------------------------- backplate

  void _paintBackplate(Canvas canvas, Offset center, double r) {
    // Depth: a soft radial wash so the face does not read as flat paper.
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.075),
            Colors.white.withValues(alpha: 0.015),
            Colors.transparent,
          ],
          stops: const [0.0, 0.72, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );

    if (aligned) {
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = _green.withValues(alpha: 0.40)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }

    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = aligned ? 2.4 : 1.4
        ..color = aligned ? _green : Colors.white.withValues(alpha: 0.22),
    );
  }

  // ------------------------------------------------------------------ dial

  void _paintTicks(Canvas canvas, double r) {
    for (var deg = 0; deg < 360; deg += 5) {
      final major = deg % 30 == 0;
      final cardinal = deg % 90 == 0;
      final outer = r - 6;
      final inner = outer - (cardinal ? 16 : (major ? 12 : 6));
      final a = _rad(deg.toDouble());

      canvas.drawLine(
        Offset(math.sin(a) * inner, -math.cos(a) * inner),
        Offset(math.sin(a) * outer, -math.cos(a) * outer),
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = cardinal ? 2.6 : (major ? 1.8 : 1.0)
          ..color = Colors.white
              .withValues(alpha: cardinal ? 0.92 : (major ? 0.55 : 0.22)),
      );
    }
  }

  void _paintCardinals(Canvas canvas, double r) {
    const labels = <int, String>{0: 'N', 90: 'E', 180: 'S', 270: 'W'};
    labels.forEach((deg, label) {
      final isNorth = deg == 0;
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            // North gets its own colour so the dial has a fixed anchor that is
            // never confused with the gold Qibla target.
            color: isNorth
                ? const Color(0xFFFF6B6B)
                : Colors.white.withValues(alpha: 0.80),
            fontSize: isNorth ? 16 : 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final radius = r - 34;
      final a = _rad(deg.toDouble());
      final at = Offset(math.sin(a) * radius, -math.cos(a) * radius);
      tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
    });
  }

  // ---------------------------------------------------------------- target

  /// A soft wedge from the hub out to the Kaaba badge. This is the single
  /// clearest "go this way" cue on the screen.
  void _paintQiblaBeam(Canvas canvas, double r) {
    final colour = aligned ? _green : _gold;
    const halfWidth = 7.0; // degrees

    // Annulus wedge, not a pie slice: the inner cut keeps the beam clear of
    // the centre readout no matter which way the Qibla lies.
    final inner = r * 0.44;
    // Stop short of the badge so the arrowhead does not run under it.
    final outer = r - 34;
    final outerRect = Rect.fromCircle(center: Offset.zero, radius: outer);
    final innerRect = Rect.fromCircle(center: Offset.zero, radius: inner);

    final path = Path()
      ..arcTo(innerRect, _rad(-90 - halfWidth), _rad(halfWidth * 2), true)
      ..arcTo(outerRect, _rad(-90 + halfWidth), _rad(-halfWidth * 2), false)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          colors: [
            colour.withValues(alpha: 0.10),
            colour.withValues(alpha: 0.34),
          ],
        ).createShader(outerRect),
    );

    // A crisp spine down the middle of the wedge.
    canvas.drawLine(
      Offset(0, -inner),
      Offset(0, -(outer - 4)),
      Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3
        ..color = colour.withValues(alpha: 0.95),
    );

    // Arrowhead just inside the badge.
    final head = Path()
      ..moveTo(0, -(outer + 8))
      ..lineTo(-8, -(outer - 5))
      ..lineTo(8, -(outer - 5))
      ..close();
    canvas.drawPath(head, Paint()..color = colour);
  }

  /// The Kaaba itself, riding the rim at the Qibla bearing.
  void _paintKaabaBadge(Canvas canvas, double r) {
    canvas.save();
    // Sit just inside the rim. Placing it outside the dial radius pushed the
    // badge past the widget bounds and clipped it.
    canvas.translate(0, -(r - 13));

    final colour = aligned ? _green : _gold;

    canvas.drawCircle(Offset.zero, 12, Paint()..color = colour);
    canvas.drawCircle(
      Offset.zero,
      12,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _ink.withValues(alpha: 0.55),
    );

    // Kaaba glyph: dark cube with a gold band.
    final cube = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-6.5, -6, 13, 12),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(cube, Paint()..color = _ink);
    canvas.drawRect(
      const Rect.fromLTWH(-6.5, -1.6, 13, 2.6),
      Paint()..color = colour,
    );
    canvas.restore();
  }

  // ---------------------------------------------------------------- centre

  void _paintCentre(Canvas canvas, double r) {
    final discR = r * 0.40;

    // An opaque disc so the readout never has to compete with the beam or the
    // dial behind it.
    canvas.drawCircle(
      Offset.zero,
      discR,
      Paint()..color = const Color(0xFF0B2016),
    );
    canvas.drawCircle(
      Offset.zero,
      discR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.10),
    );

    if (heading == null) {
      final waiting = TextPainter(
        text: TextSpan(
          text: '—',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      waiting.paint(canvas, Offset(-waiting.width / 2, -waiting.height / 2));
      return;
    }

    final caption = TextPainter(
      text: TextSpan(
        text: 'FACING',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.40),
          fontSize: 9.5,
          letterSpacing: 1.8,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final value = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '${heading!.round().toString().padLeft(3, '0')}°',
            style: TextStyle(
              color: aligned ? _green : Colors.white,
              fontSize: discR * 0.46,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
              height: 1.0,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final cardinal = TextPainter(
      text: TextSpan(
        text: QiblaDirection.cardinal(heading!),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 12,
          letterSpacing: 1.0,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Stack the three pieces around the centre so nothing overlaps.
    final blockHeight = caption.height + 3 + value.height + 2 + cardinal.height;
    var y = -blockHeight / 2;
    caption.paint(canvas, Offset(-caption.width / 2, y));
    y += caption.height + 3;
    value.paint(canvas, Offset(-value.width / 2, y));
    y += value.height + 2;
    cardinal.paint(canvas, Offset(-cardinal.width / 2, y));
  }

  // ----------------------------------------------------------------- index

  /// Fixed chevron at 12 o'clock. It never rotates, because it represents the
  /// phone, not the world — this is what makes the dial readable.
  void _paintIndex(Canvas canvas, Offset center, double r) {
    final colour = aligned ? _green : Colors.white.withValues(alpha: 0.85);
    final top = center.dy - r + 1;

    final path = Path()
      ..moveTo(center.dx, top + 13)
      ..lineTo(center.dx - 8, top)
      ..lineTo(center.dx + 8, top)
      ..close();

    canvas.drawPath(path, Paint()..color = colour);
  }

  static double _rad(double degrees) => degrees * math.pi / 180.0;

  @override
  bool shouldRepaint(covariant _CompassPainter old) =>
      old.heading != heading ||
      old.qiblaBearing != qiblaBearing ||
      old.delta != delta;
}
