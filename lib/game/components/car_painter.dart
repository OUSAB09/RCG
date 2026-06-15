import 'package:flutter/material.dart';

/// Shared vector car renderer — a clean top-down car shape.
class CarPainter {
  static void draw(
    Canvas canvas,
    Size size,
    Color color, {
    required bool isPlayer,
    double exhaustGlow = 0,
    bool boosting = false,
  }) {
    final w = size.width;
    final h = size.height;

    // Shadow
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(3, 5, w, h),
        const Radius.circular(12),
      ),
      shadow,
    );

    // Body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      const Radius.circular(12),
    );
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Color.lerp(color, Colors.white, 0.25)!,
          color,
          Color.lerp(color, Colors.black, 0.35)!,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRRect(bodyRect, bodyPaint);

    // Outline glow for player
    if (isPlayer) {
      final outline = Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRRect(bodyRect, outline);
    }

    // Windshield (front = top)
    final glassPaint = Paint()..color = const Color(0xFF0C1428).withValues(alpha: 0.85);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.18, h * 0.14, w * 0.64, h * 0.20),
        const Radius.circular(5),
      ),
      glassPaint,
    );
    // Rear window
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.20, h * 0.64, w * 0.60, h * 0.16),
        const Radius.circular(5),
      ),
      glassPaint,
    );

    // Roof highlight strip
    final roof = Paint()..color = Color.lerp(color, Colors.white, 0.12)!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.24, h * 0.36, w * 0.52, h * 0.26),
        const Radius.circular(4),
      ),
      roof,
    );

    // Headlights (front/top)
    final light = Paint()..color = const Color(0xFFFFF6CC);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.10, 2, w * 0.16, 5),
          const Radius.circular(2)),
      light,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.74, 2, w * 0.16, 5),
          const Radius.circular(2)),
      light,
    );

    // Tail lights (rear/bottom)
    final tail = Paint()..color = const Color(0xFFFF3B3B);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.10, h - 7, w * 0.16, 5),
          const Radius.circular(2)),
      tail,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.74, h - 7, w * 0.16, 5),
          const Radius.circular(2)),
      tail,
    );

    // Exhaust glow for player
    if (isPlayer && exhaustGlow > 0) {
      final glowColor = boosting ? const Color(0xFFFF7A3D) : const Color(0xFF22E0FF);
      final ex = Paint()
        ..color = glowColor.withValues(alpha: (0.5 * exhaustGlow).clamp(0.0, 0.9))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, boosting ? 12 : 8);
      final r = (boosting ? 9 : 6) * exhaustGlow.clamp(0.0, 1.6);
      canvas.drawCircle(Offset(w * 0.3, h + 6), r, ex);
      canvas.drawCircle(Offset(w * 0.7, h + 6), r, ex);
    }
  }
}
