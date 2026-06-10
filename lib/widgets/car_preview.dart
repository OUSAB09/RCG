import 'package:flutter/material.dart';
import '../game/components/car_painter.dart';

/// Static preview of a car using the shared CarPainter.
class CarPreview extends StatelessWidget {
  const CarPreview({super.key, required this.color, this.width = 56, this.height = 104});
  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _CarPreviewPainter(color)),
    );
  }
}

class _CarPreviewPainter extends CustomPainter {
  _CarPreviewPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    CarPainter.draw(canvas, size, color, isPlayer: true, exhaustGlow: 0.6);
  }

  @override
  bool shouldRepaint(covariant _CarPreviewPainter old) => old.color != color;
}
