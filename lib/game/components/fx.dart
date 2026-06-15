import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/environment.dart';

/// Floating reward text that rises and fades.
class FloatingText extends PositionComponent with HasGameReference {
  FloatingText({required this.text, required this.color, required Vector2 position}) {
    this.position = position;
  }
  final String text;
  final Color color;
  double _life = 0;
  static const double _maxLife = 1.1;

  @override
  void update(double dt) {
    super.update(dt);
    _life += dt;
    position.y -= 46 * dt;
    if (_life >= _maxLife) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final opacity = (1 - _life / _maxLife).clamp(0.0, 1.0);
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withValues(alpha: opacity),
          fontSize: 16,
          fontWeight: FontWeight.w800,
          shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, 0));
  }
}

/// Quick neon ring burst on extreme passes.
class SpeedBurst extends PositionComponent {
  SpeedBurst({required Vector2 position}) {
    this.position = position;
  }
  double _life = 0;
  static const double _maxLife = 0.5;

  @override
  void update(double dt) {
    super.update(dt);
    _life += dt;
    if (_life >= _maxLife) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = _life / _maxLife;
    final paint = Paint()
      ..color = const Color(0xFFFF2D9B).withValues(alpha: (1 - t) * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(Offset.zero, 20 + t * 60, paint);
  }
}

/// Speed/nitro trail streak behind the player.
class NitroTrail extends PositionComponent {
  NitroTrail({required Vector2 position}) {
    this.position = position;
  }
  double _life = 0;
  static const double _maxLife = 0.4;

  @override
  void update(double dt) {
    super.update(dt);
    _life += dt;
    position.y += 220 * dt;
    if (_life >= _maxLife) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = _life / _maxLife;
    final paint = Paint()
      ..color = Color.lerp(const Color(0xFFFFD23D), const Color(0xFFFF2D9B), t)!
          .withValues(alpha: (1 - t) * 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset.zero, 5 * (1 - t) + 2, paint);
  }
}

/// Crash explosion particles.
class CrashFx extends PositionComponent {
  CrashFx({required Vector2 position, this.reduced = false}) {
    this.position = position;
  }
  final bool reduced;
  final math.Random _rng = math.Random();
  final List<_P> _parts = [];
  double _life = 0;

  @override
  Future<void> onLoad() async {
    final count = reduced ? 8 : 22;
    for (int i = 0; i < count; i++) {
      final a = _rng.nextDouble() * math.pi * 2;
      final sp = 60 + _rng.nextDouble() * 220;
      _parts.add(_P(
        vx: math.cos(a) * sp,
        vy: math.sin(a) * sp,
        color: [
          const Color(0xFFFFD23D),
          const Color(0xFFFF7A3D),
          const Color(0xFFFF2D9B),
        ][_rng.nextInt(3)],
        r: 2 + _rng.nextDouble() * 4,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _life += dt;
    for (final p in _parts) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += 200 * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    final opacity = (1 - _life / 1.0).clamp(0.0, 1.0);
    for (final p in _parts) {
      canvas.drawCircle(
        Offset(p.x, p.y),
        p.r,
        Paint()..color = p.color.withValues(alpha: opacity),
      );
    }
  }
}

class _P {
  double x = 0, y = 0;
  double vx, vy, r;
  Color color;
  _P({required this.vx, required this.vy, required this.color, required this.r});
}

/// Weather visual overlay — rain streaks or fog veil.
class WeatherOverlay extends PositionComponent with HasGameReference {
  WeatherOverlay({required this.weather, required this.env});
  final Weather weather;
  final RaceEnvironment env;

  final math.Random _rng = math.Random();
  final List<_Drop> _drops = [];

  @override
  void update(double dt) {
    super.update(dt);
    if (weather == Weather.rain) {
      while (_drops.length < 90) {
        _drops.add(_Drop(
          x: _rng.nextDouble() * game.size.x,
          y: _rng.nextDouble() * game.size.y,
          speed: 700 + _rng.nextDouble() * 500,
          len: 12 + _rng.nextDouble() * 14,
        ));
      }
      for (final d in _drops) {
        d.y += d.speed * dt;
        if (d.y > game.size.y) {
          d.y = -20;
          d.x = _rng.nextDouble() * game.size.x;
        }
      }
    } else if (weather == Weather.sandstorm) {
      while (_drops.length < 70) {
        _drops.add(_Drop(
          x: _rng.nextDouble() * game.size.x,
          y: _rng.nextDouble() * game.size.y,
          speed: 500 + _rng.nextDouble() * 400,
          len: 8 + _rng.nextDouble() * 10,
        ));
      }
      for (final d in _drops) {
        d.y += d.speed * dt;
        d.x += 220 * dt; // wind to the right
        if (d.y > game.size.y || d.x > game.size.x) {
          d.y = -20;
          d.x = _rng.nextDouble() * game.size.x - 60;
        }
      }
    }
  }

  @override
  int get priority => 100;

  @override
  void render(Canvas canvas) {
    final sz = game.size;
    if (weather == Weather.fog) {
      final fog = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.32),
          ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ).createShader(Rect.fromLTWH(0, 0, sz.x, sz.y));
      canvas.drawRect(Rect.fromLTWH(0, 0, sz.x, sz.y), fog);
    } else if (weather == Weather.rain) {
      final rainPaint = Paint()
        ..color = const Color(0xFFAEE3FF).withValues(alpha: 0.45)
        ..strokeWidth = 1.5;
      for (final d in _drops) {
        canvas.drawLine(Offset(d.x, d.y), Offset(d.x - 3, d.y + d.len), rainPaint);
      }
      // slight darken
      canvas.drawRect(Rect.fromLTWH(0, 0, sz.x, sz.y),
          Paint()..color = Colors.black.withValues(alpha: 0.12));
    } else if (weather == Weather.sandstorm) {
      // sandy haze veil
      final haze = Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFFD9A05B).withValues(alpha: 0.18),
            const Color(0xFFC2762E).withValues(alpha: 0.42),
          ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ).createShader(Rect.fromLTWH(0, 0, sz.x, sz.y));
      canvas.drawRect(Rect.fromLTWH(0, 0, sz.x, sz.y), haze);
      final grain = Paint()..color = const Color(0xFFE8C089).withValues(alpha: 0.5);
      for (final d in _drops) {
        canvas.drawLine(Offset(d.x, d.y), Offset(d.x - 6, d.y + d.len), grain..strokeWidth = 2);
      }
    }
  }
}

class _Drop {
  double x, y, speed, len;
  _Drop({required this.x, required this.y, required this.speed, required this.len});
}
