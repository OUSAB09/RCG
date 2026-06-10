import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/environment.dart';
import '../models/vehicle.dart';
import 'components/player_car.dart';
import 'components/road.dart';
import 'components/traffic_car.dart';
import 'components/fx.dart';

enum GamePhase { running, crashed }

/// Overtake proximity tiers (the "Overtake Economy" from the GDD).
class PassTier {
  final String label;
  final int baseReward;
  final Color color;
  const PassTier(this.label, this.baseReward, this.color);
}

const passNear = PassTier('NEAR PASS', 50, Color(0xFF3DFF8A));
const passClose = PassTier('CLOSE PASS', 120, Color(0xFFFFD23D));
const passExtreme = PassTier('EXTREME PASS!', 280, Color(0xFFFF2D9B));

/// The main vertical-scrolling traffic-dodging racer built on Flame.
class RacingGame extends FlameGame with KeyboardEvents, PanDetector {
  RacingGame({
    required this.vehicle,
    required this.stats,
    required this.environment,
    required this.weather,
    required this.onStateChanged,
  });

  final Vehicle vehicle;
  final VehicleStats stats;
  final RaceEnvironment environment;
  final Weather weather;

  /// Pushed to the Flutter HUD on every meaningful change.
  final void Function(HudState state) onStateChanged;

  late RoadComponent road;
  late PlayerCar player;
  final math.Random _rng = math.Random();

  // Lane layout — 4 lanes
  static const int laneCount = 4;
  double get roadLeft => size.x * 0.10;
  double get roadWidth => size.x * 0.80;
  double get laneWidth => roadWidth / laneCount;
  double laneCenter(int lane) => roadLeft + laneWidth * (lane + 0.5);

  // Gameplay state
  GamePhase phase = GamePhase.running;
  double speed = 0; // current world speed (px/s of scroll)
  double maxSpeed = 0; // resolved from vehicle stats
  double distance = 0; // meters
  int cash = 0;
  int overtakes = 0;
  int combo = 0;
  int maxCombo = 0;
  double comboTimer = 0; // seconds remaining to keep combo
  static const double comboWindow = 2.4;

  double _spawnTimer = 0;
  double _input = 0; // -1..1 steering input (keyboard)
  double? _targetX; // drag target x (touch)
  bool started = false;

  double get speedKmh => (speed / maxSpeedPx) * maxSpeed;
  double maxSpeedPx = 520; // top scroll speed in px/s mapped to vehicle topSpeed

  @override
  Color backgroundColor() => environment.skyBottom;

  @override
  Future<void> onLoad() async {
    // Map vehicle performance into world feel.
    maxSpeed = stats.topSpeed; // km/h display
    maxSpeedPx = 360 + stats.topSpeed * 0.9; // faster cars scroll faster

    road = RoadComponent(env: environment);
    add(road);

    player = PlayerCar(
      color: vehicle.bodyColor,
      handling: (stats.handling * weather.gripMul).clamp(0.15, 1.0),
    );
    add(player);

    add(WeatherOverlay(weather: weather, env: environment));
  }

  void beginRace() {
    started = true;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) {
      player.position = Vector2(laneCenter(1), size.y * 0.78);
      player.homeY = size.y * 0.78;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!started || phase == GamePhase.crashed) {
      super.update(0);
      return;
    }

    // --- Speed: accelerate toward max based on acceleration stat ---
    final accelRate = maxSpeedPx * (0.18 + stats.acceleration * 0.5);
    speed = math.min(maxSpeedPx, speed + accelRate * dt);

    // --- Distance (1 meter ~ 6px) ---
    distance += (speed * dt) / 6.0;

    road.scroll(speed * dt);

    // --- Steering ---
    final steerSpeed = size.x * (0.6 + player.handling * 1.4);
    if (_targetX != null) {
      // Touch drag: move toward target
      final dx = _targetX! - player.position.x;
      player.position.x += dx.clamp(-steerSpeed * dt, steerSpeed * dt);
    } else if (_input != 0) {
      player.position.x += _input * steerSpeed * dt;
    }
    final minX = roadLeft + player.size.x / 2;
    final maxX = roadLeft + roadWidth - player.size.x / 2;
    player.position.x = player.position.x.clamp(minX, maxX);
    player.tilt = _input != 0
        ? _input
        : (_targetX != null
            ? ((_targetX! - player.position.x).clamp(-30, 30) / 30)
            : 0);

    // --- Combo timer decay ---
    if (combo > 0) {
      comboTimer -= dt;
      if (comboTimer <= 0) {
        combo = 0;
      }
    }

    // --- Spawn traffic ---
    _spawnTimer -= dt;
    final spawnInterval = (0.95 - (speed / maxSpeedPx) * 0.55).clamp(0.4, 1.1);
    if (_spawnTimer <= 0) {
      _spawnTraffic();
      _spawnTimer = spawnInterval;
    }

    // --- Traffic update, overtakes & collisions ---
    final toRemove = <TrafficCar>[];
    for (final t in children.whereType<TrafficCar>()) {
      // Traffic also moves; relative speed = our speed - their speed
      final relative = speed - t.ownSpeedPx;
      t.position.y += relative * dt;

      // Collision check (AABB with small forgiveness)
      if (!t.passed && _collides(player, t)) {
        _crash();
        return;
      }

      // Overtake detection — traffic passed below the player
      if (!t.passed && t.position.y > player.position.y + player.size.y * 0.5) {
        t.passed = true;
        _registerOvertake(t);
      }

      if (t.position.y > size.y + 80) toRemove.add(t);
    }
    for (final t in toRemove) {
      t.removeFromParent();
    }

    _emitHud();
  }

  void _spawnTraffic() {
    // Choose 1-2 lanes, never block all lanes
    final lanesToFill = _rng.nextInt(2) + 1;
    final lanes = List.generate(laneCount, (i) => i)..shuffle(_rng);
    final chosen = lanes.take(lanesToFill).toList();

    for (final lane in chosen) {
      // Traffic AI profile -> own speed (slower than player's top)
      final profile = _rng.nextInt(4); // careful, average, aggressive, distracted
      final baseFrac = [0.30, 0.42, 0.55, 0.36][profile];
      final ownSpeed = maxSpeedPx * (baseFrac + _rng.nextDouble() * 0.08);
      final colors = _trafficColors;
      final car = TrafficCar(
        color: colors[_rng.nextInt(colors.length)],
        ownSpeedPx: ownSpeed,
      );
      car.position = Vector2(laneCenter(lane), -80 - _rng.nextDouble() * 60);
      add(car);
    }
  }

  static const List<Color> _trafficColors = [
    Color(0xFFE0E0E8),
    Color(0xFF5B6CFF),
    Color(0xFFFF5B6C),
    Color(0xFFFFC04D),
    Color(0xFF4DD0FF),
    Color(0xFF8C8CA8),
  ];

  bool _collides(PositionComponent a, PositionComponent b) {
    final ar = a.toRect().deflate(6);
    final br = b.toRect().deflate(6);
    return ar.overlaps(br);
  }

  void _registerOvertake(TrafficCar t) {
    // Proximity = horizontal gap at pass moment
    final gap = (t.position.x - player.position.x).abs();
    final laneHalf = laneWidth / 2;
    PassTier tier;
    if (gap < laneHalf * 0.55) {
      tier = passExtreme;
    } else if (gap < laneHalf * 1.1) {
      tier = passClose;
    } else {
      tier = passNear;
    }

    combo += 1;
    if (combo > maxCombo) maxCombo = combo;
    comboTimer = comboWindow;
    overtakes += 1;

    // Combo multiplier grows with chain length (exponential-ish, capped)
    final mult = math.min(8.0, 1.0 + (combo - 1) * 0.5);
    final reward =
        (tier.baseReward * mult * environment.cashMultiplier).round();
    cash += reward;

    // Floating reward text
    add(FloatingText(
      text: '+\$$reward  ${tier.label}',
      color: tier.color,
      position: Vector2(t.position.x, player.position.y - 30),
    ));

    if (tier == passExtreme) {
      add(SpeedBurst(position: player.position.clone()));
    }
  }

  void _crash() {
    phase = GamePhase.crashed;
    add(CrashFx(position: player.position.clone()));
    player.crashed = true;
    HapticFeedback.heavyImpact();
    _emitHud();
  }

  void _emitHud() {
    onStateChanged(HudState(
      speedKmh: speedKmh,
      maxKmh: maxSpeed,
      distance: distance.toInt(),
      cash: cash,
      combo: combo,
      comboFrac: combo > 0 ? (comboTimer / comboWindow).clamp(0.0, 1.0) : 0.0,
      overtakes: overtakes,
      phase: phase,
    ));
  }

  // ---------- Input ----------

  @override
  KeyEventResult onKeyEvent(
      KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final left = keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
        keysPressed.contains(LogicalKeyboardKey.keyA);
    final right = keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
        keysPressed.contains(LogicalKeyboardKey.keyD);
    _targetX = null; // keyboard overrides touch
    _input = (right ? 1 : 0) + (left ? -1 : 0).toDouble();
    return KeyEventResult.handled;
  }

  @override
  void onPanStart(DragStartInfo info) {
    if (phase == GamePhase.crashed) return;
    _input = 0;
    _targetX = info.eventPosition.global.x;
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (phase == GamePhase.crashed) return;
    _input = 0;
    _targetX = info.eventPosition.global.x;
  }

  @override
  void onPanEnd(DragEndInfo info) {
    _targetX = null;
  }
}

/// Snapshot of game state pushed to the Flutter HUD overlay.
class HudState {
  final double speedKmh;
  final double maxKmh;
  final int distance;
  final int cash;
  final int combo;
  final double comboFrac;
  final int overtakes;
  final GamePhase phase;

  const HudState({
    required this.speedKmh,
    required this.maxKmh,
    required this.distance,
    required this.cash,
    required this.combo,
    required this.comboFrac,
    required this.overtakes,
    required this.phase,
  });
}
