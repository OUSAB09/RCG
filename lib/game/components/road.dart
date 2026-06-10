import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/environment.dart';

/// Scrolling road with lane markings and side scenery.
class RoadComponent extends PositionComponent with HasGameReference {
  RoadComponent({required this.env});
  final RaceEnvironment env;

  double _offset = 0;
  final List<_Scenery> _leftScenery = [];
  final List<_Scenery> _rightScenery = [];
  final math.Random _rng = math.Random();

  void scroll(double dy) {
    _offset = (_offset + dy);
    for (final s in [..._leftScenery, ..._rightScenery]) {
      s.y += dy;
    }
    _leftScenery.removeWhere((s) => s.y > game.size.y + 120);
    _rightScenery.removeWhere((s) => s.y > game.size.y + 120);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Spawn scenery occasionally
    if (_rng.nextDouble() < 0.08) {
      _leftScenery.add(_Scenery(y: -120, h: 60 + _rng.nextDouble() * 120));
    }
    if (_rng.nextDouble() < 0.08) {
      _rightScenery.add(_Scenery(y: -120, h: 60 + _rng.nextDouble() * 120));
    }
  }

  @override
  void render(Canvas canvas) {
    final sz = game.size;
    final roadLeft = sz.x * 0.10;
    final roadWidth = sz.x * 0.80;
    final roadRight = roadLeft + roadWidth;

    // Sky gradient background
    final skyPaint = Paint()
      ..shader = LinearGradient(
        colors: [env.skyTop, env.skyBottom],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, sz.x, sz.y));
    canvas.drawRect(Rect.fromLTWH(0, 0, sz.x, sz.y), skyPaint);

    // Side ground
    final groundPaint = Paint()..color = env.sceneryColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, roadLeft, sz.y), groundPaint);
    canvas.drawRect(Rect.fromLTWH(roadRight, 0, sz.x - roadRight, sz.y), groundPaint);

    // Scenery blocks (buildings / dunes / rocks)
    final sceneryPaint = Paint()..color = env.sceneryColor.withValues(alpha: 0.0);
    for (final s in _leftScenery) {
      sceneryPaint.color = Color.lerp(env.sceneryColor, Colors.black, 0.25)!;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(roadLeft * 0.15, s.y, roadLeft * 0.7, s.h),
          const Radius.circular(3),
        ),
        sceneryPaint,
      );
    }
    for (final s in _rightScenery) {
      sceneryPaint.color = Color.lerp(env.sceneryColor, Colors.black, 0.25)!;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(roadRight + roadLeft * 0.15, s.y, roadLeft * 0.7, s.h),
          const Radius.circular(3),
        ),
        sceneryPaint,
      );
    }

    // Road surface
    final roadPaint = Paint()..color = env.roadColor;
    canvas.drawRect(Rect.fromLTWH(roadLeft, 0, roadWidth, sz.y), roadPaint);

    // Road edges (glow)
    final edgePaint = Paint()
      ..color = env.laneColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawLine(Offset(roadLeft, 0), Offset(roadLeft, sz.y), edgePaint);
    canvas.drawLine(Offset(roadRight, 0), Offset(roadRight, sz.y), edgePaint);

    // Lane dashes (4 lanes -> 3 inner dividers)
    final laneWidth = roadWidth / 4;
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const dashLen = 36.0;
    const gap = 34.0;
    final period = dashLen + gap;
    final start = (_offset % period) - period;
    for (int lane = 1; lane < 4; lane++) {
      final x = roadLeft + laneWidth * lane;
      for (double y = start; y < sz.y; y += period) {
        canvas.drawLine(Offset(x, y), Offset(x, y + dashLen), dashPaint);
      }
    }
  }
}

class _Scenery {
  double y;
  final double h;
  _Scenery({required this.y, required this.h});
}
