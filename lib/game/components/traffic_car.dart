import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'car_painter.dart';

class TrafficCar extends PositionComponent with HasGameReference {
  TrafficCar({required this.color, required this.ownSpeedPx});

  final Color color;
  final double ownSpeedPx; // forward speed (same direction as player)
  bool passed = false;

  @override
  Future<void> onLoad() async {
    size = Vector2(46, 84);
    anchor = Anchor.center;
  }

  @override
  void render(Canvas canvas) {
    CarPainter.draw(canvas, size.toSize(), color, isPlayer: false);
  }
}
