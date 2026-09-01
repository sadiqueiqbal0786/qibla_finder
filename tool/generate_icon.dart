// Renders the launcher icon set with Flutter's own canvas and writes PNGs.
//
// Run with:  flutter test tool/generate_icon.dart
//
// Kept as source rather than a binary asset so the mark can be adjusted and
// regenerated instead of redrawn in an image editor.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// The app palette, from lib/home_screen.dart.
const Color ink = Color(0xFF07160F);
const Color inkSoft = Color(0xFF0E2C1E);
const Color accent = Color(0xFF23C486);
const Color gold = Color(0xFFE9B44C);

/// The mark: a compass dial with the gold Qibla needle.
///
/// Mirrors the in-app compass — dial in white, target in gold, alignment in
/// green — so the icon and the screen it opens read as the same object. Tick
/// marks are kept few and heavy; fine detail turns to mush at launcher size.
void paintGlyph(Canvas canvas, double size, {double scale = 1.0}) {
  final centre = Offset(size / 2, size / 2);
  final radius = size * 0.30 * scale;

  // Dial ring.
  canvas.drawCircle(
    centre,
    radius,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.034 * scale
      ..color = Colors.white.withValues(alpha: 0.92),
  );

  // Four cardinal ticks only.
  for (var i = 0; i < 4; i++) {
    final angle = i * math.pi / 2;
    final outer = radius - size * 0.052 * scale;
    final inner = outer - size * 0.045 * scale;
    canvas.drawLine(
      centre + Offset(math.sin(angle) * inner, -math.cos(angle) * inner),
      centre + Offset(math.sin(angle) * outer, -math.cos(angle) * outer),
      Paint()
        ..strokeWidth = size * 0.022 * scale
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  // The Qibla needle, angled so the icon reads as "pointing" rather than
  // as a plain compass rose.
  canvas.save();
  canvas.translate(centre.dx, centre.dy);
  canvas.rotate(38 * math.pi / 180);

  final length = radius * 0.86;
  final head = Path()
    ..moveTo(0, -length)
    ..lineTo(-size * 0.055 * scale, -length * 0.28)
    ..lineTo(0, -length * 0.12)
    ..lineTo(size * 0.055 * scale, -length * 0.28)
    ..close();
  canvas.drawPath(head, Paint()..color = gold);

  final tail = Path()
    ..moveTo(0, length * 0.52)
    ..lineTo(-size * 0.034 * scale, length * 0.12)
    ..lineTo(0, 0)
    ..lineTo(size * 0.034 * scale, length * 0.12)
    ..close();
  canvas.drawPath(tail, Paint()..color = Colors.white.withValues(alpha: 0.45));
  canvas.restore();

  // Hub.
  canvas.drawCircle(centre, size * 0.032 * scale, Paint()..color = accent);
}

void paintBackground(Canvas canvas, double size, {bool rounded = false}) {
  final rect = Rect.fromLTWH(0, 0, size, size);
  final paint = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [inkSoft, ink],
    ).createShader(rect);

  if (rounded) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(size * 0.225)),
      paint,
    );
  } else {
    canvas.drawRect(rect, paint);
  }
}

Future<void> write(
    String path, int size, void Function(Canvas, double) draw) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  draw(canvas, size.toDouble());
  final image = await recorder.endRecording().toImage(size, size);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(Uint8List.sublistView(data!));
  // ignore: avoid_print
  print('wrote $path (${size}x$size)');
}

void main() {
  test('generate launcher icons', () async {
    const dir = 'assets/icon';

    await write('$dir/icon.png', 1024, (canvas, size) {
      paintBackground(canvas, size);
      paintGlyph(canvas, size);
    });

    await write('$dir/icon_rounded.png', 1024, (canvas, size) {
      paintBackground(canvas, size, rounded: true);
      paintGlyph(canvas, size);
    });

    // Android masks the outer ~28%, so the glyph shrinks into the safe zone.
    await write('$dir/icon_foreground.png', 1024,
        (canvas, size) => paintGlyph(canvas, size, scale: 0.72));

    await write('$dir/icon_background.png', 1024,
        (canvas, size) => paintBackground(canvas, size));

    // Android 13+ themed icons: single colour, no background.
    await write('$dir/icon_monochrome.png', 1024, (canvas, size) {
      final centre = Offset(size / 2, size / 2);
      const scale = 0.72;
      final radius = size * 0.30 * scale;
      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = size * 0.034 * scale
          ..color = Colors.white,
      );
      canvas.save();
      canvas.translate(centre.dx, centre.dy);
      canvas.rotate(38 * math.pi / 180);
      final length = radius * 0.86;
      canvas.drawPath(
        Path()
          ..moveTo(0, -length)
          ..lineTo(-size * 0.055 * scale, -length * 0.28)
          ..lineTo(0, -length * 0.12)
          ..lineTo(size * 0.055 * scale, -length * 0.28)
          ..close(),
        Paint()..color = Colors.white,
      );
      canvas.restore();
      canvas.drawCircle(centre, size * 0.032 * scale, Paint()..color = Colors.white);
    });

    expect(File('$dir/icon.png').existsSync(), isTrue);
  });
}
