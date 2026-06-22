import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../audio/sound.dart';
import '../models/environment.dart';
import '../models/vehicle.dart';
import 'components/player_car.dart';
import 'components/road.dart';
import 'components/traffic_car.dart';
import 'components/fx.dart';

enum GamePhase { running, crashed }

/// Overtake proximity tiers (the "Overtake Economy").
class PassTier {
  final String label;
  final int baseReward;
  final Color color;
  final String symbol; // colorblind-friendly shape cue
  const PassTier(this.label, this.baseReward, this.color, this.symbol);
}

const passNear = PassTier('NEAR MISS', 50, Color(0xFF3DFF8A), '○');
const passClose = PassTier('CLOSE PASS', 120, Color(0xFFFFD23D), '◆');
const passExtreme = PassTier('EXTREME NEAR MISS!', 280, Color(0xFFFF2D9B), '★');

/// The main vertical-scrolling traffic-dodging racer built on Flame.
class RacingGame extends FlameGame with KeyboardEvents, PanDetector {
  RacingGame({
    required this.vehicle,
    required this.stats,
    required this.environment,
    required this.weather,
    required this.reducedFlashing,
    this.colorblindMode = false,
    required this.onStateChanged,
  });

  final Vehicle vehicle;
  final VehicleStats stats;
  final RaceEnvironment environment;
  final Weather weather;
  final bool reducedFlashing;
  final bool colorblindMode;

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
  int nearMisses = 0;
  int combo = 0;
  int maxCombo = 0;
  double comboTimer = 0; // seconds remaining to keep combo
  static const double comboWindow = 2.4;

  // Nitro (Phase D/I)
  double nitro = 0.4; // 0..1 charge
  bool nitroActive = false;
  static const double nitroDrain = 0.42; // per second when active
  static const double nitroGainPerPass = 0.14;

  // Slipstream (Phase A)
  bool slipstreaming = false;

  double _spawnTimer = 0;
  double _input = 0; // -1..1 steering input (keyboard)
  double? _targetX; // drag target x (touch)
  bool _nitroKey = false;
  bool started = false;

  // Ghost recording (Phase J) — record player X over time samples
  final List<double> ghostTrack = [];
  double _ghostSampleTimer = 0;
  static const double ghostSampleInterval = 0.1;

  double get effectiveMaxPx => maxSpeedPx * (nitroActive ? 1.35 : 1.0);
  double get speedKmh => (speed / maxSpeedPx) * maxSpeed;
  double maxSpeedPx = 520;

  @override
  Color backgroundColor() => environment.skyBottom;

  @override
  Future<void> onLoad() async {
    maxSpeed = stats.topSpeed;
    maxSpeedPx = 360 + stats.topSpeed * 0.9;

    road = RoadComponent(env: environment);
    add(road);

    player = PlayerCar(
      color: vehicle.bodyColor,
      handling: (stats.handling * weather.gripMul +
              stats.stability * (1 - weather.gripMul) * 0.6)
          .clamp(0.15, 1.0),
    );
    add(player);

    add(WeatherOverlay(weather: weather, env: environment));
  }

  void beginRace() => started = true;

  void activateNitro() {
    if (nitro > 0.05 && phase == GamePhase.running && !nitroActive) {
      nitroActive = true;
      Sound.nitroStart();
    }
  }

  void deactivateNitro() {
    if (nitroActive) {
      nitroActive = false;
      Sound.nitroEnd();
    }
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

    // --- Nitro management ---
    if (_nitroKey) activateNitro();
    if (nitroActive) {
      nitro -= nitroDrain * dt;
      if (nitro <= 0) {
        nitro = 0;
        nitroActive = false;
      }
      if (!reducedFlashing && _rng.nextDouble() < 0.4) {
        add(NitroTrail(position: player.position.clone()));
      }
    }

    // --- Speed: accelerate toward (boosted) max ---
    final target = effectiveMaxPx;
    final accelRate = maxSpeedPx *
        (0.18 + stats.acceleration * 0.5) *
        (nitroActive ? 2.2 : 1.0);
    if (speed < target) {
      speed = math.min(target, speed + accelRate * dt);
    } else {
      speed = math.max(target, speed - maxSpeedPx * 0.6 * dt);
    }

    // --- Distance (1 meter ~ 6px) ---
    distance += (speed * dt) / 6.0;

    road.scroll(speed * dt);

    // --- Steering ---
    final steerSpeed = size.x * (0.6 + player.handling * 1.4);
    if (_targetX != null) {
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
    player.boosting = nitroActive;

    // --- Ghost recording ---
    _ghostSampleTimer += dt;
    if (_ghostSampleTimer >= ghostSampleInterval) {
      _ghostSampleTimer = 0;
      ghostTrack.add(player.position.x / size.x); // normalized
    }

    // --- Combo timer decay ---
    if (combo > 0) {
      comboTimer -= dt;
      if (comboTimer <= 0) combo = 0;
    }

    // --- Spawn traffic ---
    _spawnTimer -= dt;
    final spawnInterval = (0.95 - (speed / maxSpeedPx) * 0.55).clamp(0.38, 1.1);
    if (_spawnTimer <= 0) {
      _spawnTraffic();
      _spawnTimer = spawnInterval;
    }

    // --- High-speed bonus: continuous cash while near top speed ---
    final speedFrac = speed / maxSpeedPx;

    // --- Engine drone (procedural audio) ---
    if (phase == GamePhase.running) {
      Sound.engine(speedFrac.clamp(0.0, 1.0), nitroActive);
    }

    if (speedFrac > 0.85) {
      _highSpeedAccum += dt;
      if (_highSpeedAccum >= 1.0) {
        _highSpeedAccum = 0;
        final bonus = (15 * environment.cashMultiplier).round();
        cash += bonus;
        if (!reducedFlashing) {
          add(FloatingText(
            text: 'HIGH SPEED +\$$bonus',
            color: const Color(0xFF22E0FF),
            position: Vector2(player.position.x + 50, player.position.y - 10),
          ));
        }
      }
    } else {
      _highSpeedAccum = 0;
    }

    // --- Traffic update, near-miss, slipstream, overtakes & collisions ---
    slipstreaming = false;
    final toRemove = <TrafficCar>[];
    for (final t in children.whereType<TrafficCar>()) {
      // Lane-drift AI for aggressive/distracted
      if (t.driftVel != 0) {
        t.position.x += t.driftVel * dt;
        if (t.position.x < t.minX || t.position.x > t.maxX) {
          t.driftVel = -t.driftVel;
          t.position.x = t.position.x.clamp(t.minX, t.maxX);
        }
      }

      final relative = speed - t.ownSpeedPx;
      t.position.y += relative * dt;

      // Slipstream: directly behind a car & close → small speed/nitro gain
      final dx = (t.position.x - player.position.x).abs();
      final dy = player.position.y - t.position.y;
      if (dy > 0 && dy < 120 && dx < t.size.x * 0.7 && !t.passed) {
        slipstreaming = true;
        nitro = (nitro + 0.05 * dt).clamp(0.0, 1.0);
      }

      if (!t.passed && _collides(player, t)) {
        _crash();
        return;
      }

      // Near miss (close horizontal gap while overlapping vertically)
      if (!t.nearMissCounted &&
          !t.passed &&
          dx < t.size.x * 0.95 &&
          dy.abs() < t.size.y * 0.6) {
        t.nearMissCounted = true;
      }

      if (!t.passed && t.position.y > player.position.y + player.size.y * 0.5) {
        t.passed = true;
        _registerOvertake(t);
      }

      if (t.position.y > size.y + 100) toRemove.add(t);
    }
    for (final t in toRemove) {
      t.removeFromParent();
    }

    _emitHud();
  }

  double _highSpeedAccum = 0;

  void _spawnTraffic() {
    final lanesToFill = _rng.nextInt(2) + 1;
    final lanes = List.generate(laneCount, (i) => i)..shuffle(_rng);
    final chosen = lanes.take(lanesToFill).toList();

    for (final lane in chosen) {
      final type = _pickTrafficType();
      final ownSpeed =
          maxSpeedPx * (type.baseSpeedFrac + _rng.nextDouble() * 0.06);
      final colors = _trafficColors;
      final car = TrafficCar(
        color: type == TrafficType.truck
            ? _truckColors[_rng.nextInt(_truckColors.length)]
            : colors[_rng.nextInt(colors.length)],
        ownSpeedPx: ownSpeed,
        type: type,
      );
      car.position = Vector2(laneCenter(lane), -90 - _rng.nextDouble() * 70);

      // Lane-change behavior for aggressive/distracted
      if (type == TrafficType.aggressive || type == TrafficType.distracted) {
        final range = laneWidth * 0.6;
        car.minX = (laneCenter(lane) - range).clamp(roadLeft + car.size.x / 2,
            roadLeft + roadWidth - car.size.x / 2);
        car.maxX = (laneCenter(lane) + range).clamp(roadLeft + car.size.x / 2,
            roadLeft + roadWidth - car.size.x / 2);
        car.driftVel = (_rng.nextBool() ? 1 : -1) *
            laneWidth *
            (type == TrafficType.aggressive ? 0.9 : 0.5);
      }
      add(car);
    }
  }

  TrafficType _pickTrafficType() {
    final r = _rng.nextDouble();
    if (r < 0.45) return TrafficType.civilian;
    if (r < 0.62) return TrafficType.distracted;
    if (r < 0.78) return TrafficType.sports;
    if (r < 0.90) return TrafficType.aggressive;
    return TrafficType.truck;
  }

  static const List<Color> _trafficColors = [
    Color(0xFFE0E0E8),
    Color(0xFF5B6CFF),
    Color(0xFFFF5B6C),
    Color(0xFFFFC04D),
    Color(0xFF4DD0FF),
    Color(0xFF8C8CA8),
  ];
  static const List<Color> _truckColors = [
    Color(0xFF8A8A9E),
    Color(0xFF6E5B43),
    Color(0xFF4A5A6E),
  ];

  bool _collides(PositionComponent a, PositionComponent b) {
    final ar = a.toRect().deflate(7);
    final br = b.toRect().deflate(7);
    return ar.overlaps(br);
  }

  void _registerOvertake(TrafficCar t) {
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
    if (tier != passNear || gap < laneHalf * 1.3) nearMisses++;

    // Nitro charge from skilled passes
    nitro = (nitro +
            nitroGainPerPass * (tier == passExtreme ? 1.6 : 1.0))
        .clamp(0.0, 1.0);

    final mult = math.min(8.0, 1.0 + (combo - 1) * 0.5);
    // Trucks are worth more (bigger risk)
    final typeBonus = t.type == TrafficType.truck ? 1.5 : 1.0;
    final reward =
        (tier.baseReward * mult * environment.cashMultiplier * typeBonus)
            .round();
    cash += reward;

    final label = colorblindMode ? '${tier.symbol} ${tier.label}' : tier.label;
    Sound.pass(tier == passExtreme ? 2 : (tier == passClose ? 1 : 0));
    add(FloatingText(
      text: '+\$$reward  $label',
      color: tier.color,
      position: Vector2(t.position.x, player.position.y - 30),
    ));

    if (tier == passExtreme && !reducedFlashing) {
      add(SpeedBurst(position: player.position.clone()));
    }
  }

  void _crash() {
    phase = GamePhase.crashed;
    Sound.stopEngine();
    Sound.crash();
    add(CrashFx(position: player.position.clone(), reduced: reducedFlashing));
    player.crashed = true;
    nitroActive = false;
    HapticFeedback.heavyImpact();
    _emitHud();
  }

  @override
  void onRemove() {
    Sound.stopEngine();
    super.onRemove();
  }

  /// Phase I — "Continue Run" after a crash (rewarded-ad simulation).
  void continueRun() {
    phase = GamePhase.running;
    player.crashed = false;
    combo = 0;
    speed = maxSpeedPx * 0.4;
    nitro = 0.5;
    // Clear nearby traffic for a fair restart
    for (final t in children.whereType<TrafficCar>().toList()) {
      if (t.position.y > -50) t.removeFromParent();
    }
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
      nearMisses: nearMisses,
      nitro: nitro,
      nitroActive: nitroActive,
      slipstreaming: slipstreaming,
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
    _nitroKey = keysPressed.contains(LogicalKeyboardKey.space) ||
        keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
        keysPressed.contains(LogicalKeyboardKey.keyW);
    if (!_nitroKey) nitroActive = false;
    _targetX = null;
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
  void onPanEnd(DragEndInfo info) => _targetX = null;
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
  final int nearMisses;
  final double nitro;
  final bool nitroActive;
  final bool slipstreaming;
  final GamePhase phase;

  const HudState({
    required this.speedKmh,
    required this.maxKmh,
    required this.distance,
    required this.cash,
    required this.combo,
    required this.comboFrac,
    required this.overtakes,
    required this.nearMisses,
    required this.nitro,
    required this.nitroActive,
    required this.slipstreaming,
    required this.phase,
  });
}
