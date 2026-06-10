import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'car_painter.dart';

class PlayerCar extends PositionComponent with HasGameReference {
  PlayerCar({required this.color, required this.handling});

  final Color color;
  final double handling;
  double tilt = 0; // -1..1 steer lean
  double homeY = 0;
  bool crashed = false;
  double _t = 0;

  @override
  Future<void> onLoad() async {
    size = Vector2(46, 86);
    anchor = Anchor.center;
    homeY = game.size.y * 0.78;
    position = Vector2(game.size.x * 0.5, homeY);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    // subtle lean based on steering
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(tilt * 0.10);
    canvas.translate(-size.x / 2, -size.y / 2);

    // Exhaust glow flicker
    final glow = 0.6 + 0.4 * math.sin(_t * 18);
    CarPainter.draw(
      canvas,
      size.toSize(),
      color,
      isPlayer: true,
      exhaustGlow: crashed ? 0 : glow,
    );
    canvas.restore();
  }
}
