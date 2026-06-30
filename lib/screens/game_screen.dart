import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../audio/sound.dart';
import '../core/theme.dart';
import '../game/racing_game.dart';
import '../models/environment.dart';
import '../models/vehicle.dart';
import '../state/game_state.dart';
import '../widgets/common.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.environment, required this.weather});
  final RaceEnvironment environment;
  final Weather weather;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late RacingGame _game;
  late String _vehicleId;
  HudState _hud = const HudState(
    speedKmh: 0,
    maxKmh: 0,
    distance: 0,
    cash: 0,
    combo: 0,
    comboFrac: 0,
    overtakes: 0,
    nearMisses: 0,
    nitro: 0.4,
    nitroActive: false,
    slipstreaming: false,
    phase: GamePhase.running,
  );

  int _countdown = 3;
  bool _started = false;
  bool _resultRecorded = false;
  bool _usedContinue = false;
  bool _musicOn = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final gs = context.read<GameState>();
    _vehicleId = gs.selectedVehicleId;
    _musicOn = gs.musicOn;
    _game = RacingGame(
      vehicle: gs.selectedVehicle,
      stats: gs.statsFor(_vehicleId),
      environment: widget.environment,
      weather: widget.weather,
      reducedFlashing: gs.reducedFlashing,
      colorblindMode: gs.colorblindMode,
      bodyColor: gs.displayColor(_vehicleId),
      onStateChanged: _onHud,
    );
    // Pause menu music during the race; the engine drone takes over.
    Sound.stopMusic();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(milliseconds: 800), (t) {
      if (_countdown <= 1) {
        t.cancel();
        setState(() => _started = true);
        _game.beginRace();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  void _onHud(HudState s) {
    if (!mounted) return;
    setState(() => _hud = s);
    if (s.phase == GamePhase.crashed && !_resultRecorded) {
      _resultRecorded = true;
      _recordResult();
    }
  }

  void _recordResult() {
    final gs = context.read<GameState>();
    final masteryLvl = gs.masteryLevel(_vehicleId);
    final boosted = (_hud.cash * Mastery.cashBonus(masteryLvl)).round();
    final score = _hud.distance + boosted + _hud.overtakes * 25;
    gs.recordRace(
      vehicleId: _vehicleId,
      cashEarned: boosted,
      overtakes: _hud.overtakes,
      nearMisses: _hud.nearMisses,
      maxCombo: _game.maxCombo,
      distance: _hud.distance,
      score: score,
      ghostTrack: _game.ghostTrack,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    Sound.stopEngine();
    // Resume menu music if it was on.
    if (_musicOn) Sound.startMusic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final crashed = _hud.phase == GamePhase.crashed;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: GameWidget(game: _game)),

          // Top HUD
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _hudPill(Icons.payments_rounded, '\$${_hud.cash}', AppColors.neonGreen),
                  const SizedBox(width: 8),
                  _hudPill(Icons.route_rounded, '${_hud.distance}m', AppColors.neonCyan),
                  const Spacer(),
                  if (_hud.slipstreaming && !crashed)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.neonCyan.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text('SLIPSTREAM',
                          style: AppTheme.body(12, color: AppColors.neonCyan, weight: FontWeight.w800)),
                    ),
                  IconButton(
                    onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),

          if (_hud.combo > 1 && !crashed)
            Positioned(
              top: MediaQuery.of(context).padding.top + 44,
              left: 0,
              right: 0,
              child: Center(child: _comboWidget()),
            ),

          if (!crashed)
            Positioned(left: 16, bottom: 24, child: _speedometer()),

          // Nitro control (bottom-right) — tap & hold to boost
          if (!crashed && _started)
            Positioned(right: 16, bottom: 24, child: _nitroButton()),

          if (!_started && !crashed)
            Container(
              color: Colors.black.withValues(alpha: 0.4),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_countdown > 0 ? '$_countdown' : 'GO!',
                        style: AppTheme.display(90, color: Colors.white, weight: FontWeight.w900)),
                    Text('Hold NITRO • Steer to dodge',
                        style: AppTheme.body(14, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),

          if (crashed) _gameOverPanel(),
        ],
      ),
    );
  }

  Widget _hudPill(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(text, style: AppTheme.display(15, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _comboWidget() {
    final mult = (1.0 + (_hud.combo - 1) * 0.5).clamp(1.0, 8.0);
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            colors: [AppColors.neonYellow, AppColors.neonMagenta],
          ).createShader(r),
          child: Text('${_hud.combo}x COMBO',
              style: AppTheme.display(28, color: Colors.white, weight: FontWeight.w900)),
        ),
        Text('${mult.toStringAsFixed(1)}x CASH',
            style: AppTheme.body(13, color: AppColors.neonYellow, weight: FontWeight.w700)),
        const SizedBox(height: 4),
        SizedBox(
          width: 140,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _hud.comboFrac,
              minHeight: 5,
              backgroundColor: Colors.black54,
              valueColor: const AlwaysStoppedAnimation(AppColors.neonMagenta),
            ),
          ),
        ),
      ],
    );
  }

  Widget _nitroButton() {
    final hasNitro = _hud.nitro > 0.05;
    return GestureDetector(
      onTapDown: (_) => _game.activateNitro(),
      onTapUp: (_) => _game.deactivateNitro(),
      onTapCancel: () => _game.deactivateNitro(),
      child: Container(
        width: 82,
        height: 82,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _hud.nitroActive
              ? AppColors.neonOrange.withValues(alpha: 0.4)
              : Colors.black.withValues(alpha: 0.5),
          border: Border.all(
              color: hasNitro ? AppColors.neonOrange : AppColors.textDim, width: 3),
          boxShadow: _hud.nitroActive
              ? [BoxShadow(color: AppColors.neonOrange.withValues(alpha: 0.6), blurRadius: 18)]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 70,
              height: 70,
              child: CircularProgressIndicator(
                value: _hud.nitro,
                strokeWidth: 5,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation(
                    hasNitro ? AppColors.neonOrange : AppColors.textDim),
              ),
            ),
            const Icon(Icons.local_fire_department_rounded,
                color: Colors.white, size: 30),
          ],
        ),
      ),
    );
  }

  Widget _speedometer() {
    final frac = _hud.maxKmh > 0 ? (_hud.speedKmh / _hud.maxKmh).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.6), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${_hud.speedKmh.toInt()}',
              style: AppTheme.display(28, color: Colors.white, weight: FontWeight.w900)),
          Text('KM/H', style: AppTheme.body(10, color: AppColors.neonCyan)),
          const SizedBox(height: 4),
          SizedBox(
            width: 56,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: frac,
                minHeight: 4,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation(
                    Color.lerp(AppColors.neonGreen, AppColors.neonMagenta, frac)!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gameOverPanel() {
    final gs = context.read<GameState>();
    final masteryLvl = gs.masteryLevel(_vehicleId);
    final boosted = (_hud.cash * Mastery.cashBonus(masteryLvl)).round();
    final score = _hud.distance + boosted + _hud.overtakes * 25;
    final isHighScore = score >= gs.highScore && score > 0;

    return Container(
      color: Colors.black.withValues(alpha: 0.78),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: NeonCard(
              glow: AppColors.neonMagenta,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('CRASHED', style: AppTheme.display(30, color: AppColors.neonMagenta)),
                  if (isHighScore) ...[
                    const SizedBox(height: 4),
                    Text('NEW HIGH SCORE!',
                        style: AppTheme.body(14, color: AppColors.neonYellow, weight: FontWeight.w700)),
                  ],
                  const SizedBox(height: 18),
                  _resultRow('Score', fmtCash(score), AppColors.neonYellow),
                  _resultRow('Distance', '${_hud.distance} m', AppColors.neonCyan),
                  _resultRow('Overtakes', '${_hud.overtakes}', AppColors.neonGreen),
                  _resultRow('Near Misses', '${_hud.nearMisses}', AppColors.neonOrange),
                  _resultRow('Best Combo', '${_game.maxCombo}x', AppColors.neonMagenta),
                  const Divider(color: Colors.white24, height: 28),
                  _resultRow('Cash Earned', '+\$$boosted', AppColors.neonGreen, big: true),
                  if (Mastery.cashBonus(masteryLvl) > 1.0)
                    Text('includes +${(Mastery.cashBonus(masteryLvl) * 100 - 100).toInt()}% mastery bonus',
                        style: AppTheme.body(11, color: AppColors.textDim)),
                  const SizedBox(height: 6),
                  _resultRow(
                    '${gs.rank.label}  (RP)',
                    '${gs.lastRpDelta >= 0 ? '+' : ''}${gs.lastRpDelta}',
                    gs.lastRpDelta >= 0 ? AppColors.neonCyan : AppColors.neonMagenta,
                  ),
                  const SizedBox(height: 22),

                  // Continue run (rewarded-ad style) — once per race
                  if (!_usedContinue)
                    NeonButton(
                      label: 'WATCH AD • CONTINUE',
                      icon: Icons.ondemand_video_rounded,
                      height: 52,
                      gradient: const LinearGradient(
                          colors: [AppColors.neonCyan, AppColors.neonGreen]),
                      onTap: _continueRun,
                    ),
                  if (!_usedContinue) const SizedBox(height: 10),

                  NeonButton(
                    label: 'RACE AGAIN',
                    icon: Icons.replay_rounded,
                    onTap: () {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (_) => GameScreen(
                            environment: widget.environment, weather: widget.weather),
                      ));
                    },
                  ),
                  const SizedBox(height: 10),
                  NeonButton(
                    label: 'MAIN MENU',
                    icon: Icons.home_rounded,
                    height: 50,
                    gradient: const LinearGradient(
                        colors: [AppColors.cardHi, AppColors.bgElevated]),
                    onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _continueRun() {
    setState(() {
      _usedContinue = true;
      _resultRecorded = false; // allow recording again after the new run ends
    });
    _game.continueRun();
  }

  Widget _resultRow(String label, String value, Color color, {bool big = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.body(big ? 16 : 15, color: AppColors.textSecondary)),
          Text(value, style: AppTheme.display(big ? 22 : 16, color: color)),
        ],
      ),
    );
  }
}
