import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Procedural art generator producing deterministic, harmonious nature and travel-inspired
/// gradient palettes and topographic contour line art seeded from Nostr public keys.
class ProceduralArt {
  ProceduralArt._();

  /// Curated harmonious gradient palette pairs (Travel & Nature themed).
  static const List<List<Color>> _palettes = [
    // 0: Sage & Forest Moss
    [Color(0xFF3E634F), Color(0xFF6B947A)],
    // 1: Twilight Lavender & Mountain Heather
    [Color(0xFF5E4E8C), Color(0xFF8E7EBA)],
    // 2: Hearth Terracotta & Warm Sunset
    [Color(0xFF9E4B28), Color(0xFFCE7547)],
    // 3: Coastal Teal & Sea Mist
    [Color(0xFF2E6B68), Color(0xFF5A9E99)],
    // 4: Highland Slate & Morning Mist
    [Color(0xFF435866), Color(0xFF758D9C)],
    // 5: Warm Sandstone & Desert Ochre
    [Color(0xFF8C5C36), Color(0xFFBA8757)],
    // 6: Deep Pine & Alpine Meadow
    [Color(0xFF335848), Color(0xFF5C8B72)],
    // 7: Sunset Amber & Autumn Wood
    [Color(0xFF945A34), Color(0xFFC78553)],
    // 8: Dusk Horizon & Violet Peak
    [Color(0xFF534575), Color(0xFF8171A8)],
    // 9: River Stone & Moss Green
    [Color(0xFF455A52), Color(0xFF708B80)],
  ];

  /// Fast deterministic hash code from any seed string (e.g. pubkey hex).
  static int _hash(String seed) {
    if (seed.isEmpty) return 0;
    int h = 0x811c9dc5;
    for (int i = 0; i < seed.length; i++) {
      h ^= seed.codeUnitAt(i);
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return h.abs();
  }

  /// Returns a deterministic gradient for a given seed string (e.g. pubkey).
  static LinearGradient getGradient(
    String seed, {
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
    double opacity = 1.0,
  }) {
    final h = _hash(seed);
    final palette = _palettes[h % _palettes.length];
    final c1 = opacity < 1.0 ? palette[0].withValues(alpha: opacity) : palette[0];
    final c2 = opacity < 1.0 ? palette[1].withValues(alpha: opacity) : palette[1];

    return LinearGradient(
      begin: begin,
      end: end,
      colors: [c1, c2],
    );
  }

  /// Returns a 2-color pair for a given seed string.
  static List<Color> getColorPair(String seed) {
    final h = _hash(seed);
    return _palettes[h % _palettes.length];
  }

  /// Primary color for a given seed string.
  static Color getPrimaryColor(String seed) {
    final pair = getColorPair(seed);
    return pair[0];
  }
}

/// A lightweight, pure Flutter Canvas painter that renders subtle topographic contour lines
/// and organic landscape waves. Zero external asset dependency, instant offline rendering.
class TopographicContourPainter extends CustomPainter {
  final String seed;
  final Color strokeColor;
  final double strokeWidth;

  const TopographicContourPainter({
    required this.seed,
    this.strokeColor = Colors.white,
    this.strokeWidth = 1.2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()
      ..color = strokeColor.withValues(alpha: 0.13)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = strokeColor.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    final int hash = ProceduralArt._hash(seed);
    final random = math.Random(hash);

    // Number of contour elevation layers
    const int numCurves = 5;
    final double stepY = size.height / (numCurves + 1);

    for (int i = 1; i <= numCurves; i++) {
      final path = Path();
      final baseY = i * stepY;
      final waveOffset = (random.nextDouble() * 20) - 10;
      final freq = 0.012 + (random.nextDouble() * 0.008);
      final amp = 14.0 + (random.nextDouble() * 12.0);

      path.moveTo(0, baseY + waveOffset);

      double x = 0;
      while (x <= size.width) {
        final nextX = x + 35.0;
        final y = baseY + waveOffset + math.sin((x + hash % 100) * freq) * amp;
        final nextY = baseY + waveOffset + math.sin((nextX + hash % 100) * freq) * amp;
        final midX = (x + nextX) / 2;
        final midY = (y + nextY) / 2;

        path.quadraticBezierTo(x, y, midX, midY);
        x = nextX;
      }
      path.lineTo(size.width, baseY + waveOffset);

      canvas.drawPath(path, paint);

      // Draw subtle elevation fill under alternating contours
      if (i % 2 == 0) {
        final closedPath = Path.from(path)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
        canvas.drawPath(closedPath, fillPaint);
      }
    }

    // A subtle decorative compass / summit ring in the upper corner
    final ringPaint = Paint()
      ..color = strokeColor.withValues(alpha: 0.08)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final ringCenter = Offset(size.width * 0.82, size.height * 0.35);
    canvas.drawCircle(ringCenter, 24, ringPaint);
    canvas.drawCircle(ringCenter, 42, ringPaint);
    canvas.drawCircle(ringCenter, 60, ringPaint);
  }

  @override
  bool shouldRepaint(covariant TopographicContourPainter oldDelegate) {
    return oldDelegate.seed != seed ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
