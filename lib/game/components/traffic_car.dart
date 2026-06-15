import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'car_painter.dart';

/// Traffic AI profiles from the development plan (Phase A).
enum TrafficType {
  civilian('Civilian', 46, 84, 0.34),
  distracted('Distracted', 46, 84, 0.30),
  sports('Sports Car', 44, 80, 0.52),
  aggressive('Aggressive', 46, 86, 0.48),
  truck('Truck', 58, 130, 0.26);

  const TrafficType(this.label, this.w, this.h, this.baseSpeedFrac);
  final String label;
  final double w;
  final double h;
  final double baseSpeedFrac; // fraction of player max speed
}

class TrafficCar extends PositionComponent with HasGameReference {
  TrafficCar({
    required this.color,
    required this.ownSpeedPx,
    required this.type,
  });

  final Color color;
  final double ownSpeedPx; // forward speed (same direction as player)
  final TrafficType type;
  bool passed = false;
  bool nearMissCounted = false;

  // Lane-change behavior (aggressive/distracted drift)
  double driftVel = 0;
  double minX = 0;
  double maxX = 0;

  @override
  Future<void> onLoad() async {
    size = Vector2(type.w, type.h);
    anchor = Anchor.center;
  }

  @override
  void render(Canvas canvas) {
    if (type == TrafficType.truck) {
      _drawTruck(canvas);
    } else {
      CarPainter.draw(canvas, size.toSize(), color, isPlayer: false);
    }
  }

  void _drawTruck(Canvas canvas) {
    final w = size.x, h = size.y;
    // shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(3, 5, w, h), const Radius.circular(6)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // cab
    final cab = Paint()..color = Color.lerp(color, Colors.white, 0.15)!;
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h * 0.24), const Radius.circular(6)), cab);
    // trailer
    final trailer = Paint()
      ..shader = LinearGradient(colors: [
        Color.lerp(color, Colors.white, 0.1)!,
        Color.lerp(color, Colors.black, 0.3)!,
      ]).createShader(Rect.fromLTWH(0, h * 0.26, w, h * 0.74));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, h * 0.26, w, h * 0.74), const Radius.circular(4)),
        trailer);
    // container lines
    final line = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..strokeWidth = 2;
    for (double y = h * 0.4; y < h * 0.95; y += h * 0.18) {
      canvas.drawLine(Offset(4, y), Offset(w - 4, y), line);
    }
    // tail lights
    final tail = Paint()..color = AppColors.neonOrange;
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(6, h - 6, w * 0.2, 4), const Radius.circular(2)),
        tail);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.74, h - 6, w * 0.2, 4), const Radius.circular(2)),
        tail);
  }
}
