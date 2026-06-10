import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/environment.dart';
import '../state/game_state.dart';
import '../widgets/common.dart';
import '../widgets/car_preview.dart';
import 'game_screen.dart';

class RaceSetupScreen extends StatefulWidget {
  const RaceSetupScreen({super.key});

  @override
  State<RaceSetupScreen> createState() => _RaceSetupScreenState();
}

class _RaceSetupScreenState extends State<RaceSetupScreen> {
  int _envIndex = 0;

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final vehicle = gs.selectedVehicle;

    return Scaffold(
      appBar: AppBar(
        title: Text('SELECT ROUTE', style: AppTheme.display(18)),
        leading: const BackButton(color: AppColors.textPrimary),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: kEnvironments.length,
                  itemBuilder: (context, i) {
                    final env = kEnvironments[i];
                    final unlocked = gs.bestDistance >= env.unlockDistance;
                    final selected = _envIndex == i;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: NeonCard(
                        glow: selected ? AppColors.neonCyan : env.laneColor,
                        borderOpacity: selected ? 0.8 : 0.3,
                        onTap: unlocked ? () => setState(() => _envIndex = i) : null,
                        child: Opacity(
                          opacity: unlocked ? 1 : 0.5,
                          child: Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: LinearGradient(
                                    colors: [env.skyTop, env.skyBottom],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                                child: Icon(
                                    unlocked ? Icons.terrain_rounded : Icons.lock_rounded,
                                    color: Colors.white70),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(env.name, style: AppTheme.display(16)),
                                    Text(
                                        unlocked
                                            ? 'Cash x${env.cashMultiplier}'
                                            : 'Unlock: drive ${env.unlockDistance}m',
                                        style: AppTheme.body(13,
                                            color: unlocked ? AppColors.neonGreen : AppColors.textDim)),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 6,
                                      children: env.possibleWeather
                                          .map((w) => Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.bgElevated,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(w.label,
                                                    style: AppTheme.body(11,
                                                        color: AppColors.textSecondary)),
                                              ))
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),
                              if (selected)
                                const Icon(Icons.check_circle_rounded,
                                    color: AppColors.neonCyan),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CarPreview(color: vehicle.bodyColor, width: 36, height: 66),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(vehicle.name, style: AppTheme.display(16)),
                          Text('Top ${gs.statsFor(vehicle.id).topSpeed.toInt()} km/h',
                              style: AppTheme.body(13, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: NeonButton(
                        label: 'START',
                        icon: Icons.flag_rounded,
                        onTap: () {
                          final env = kEnvironments[_envIndex];
                          final weather = env.possibleWeather[
                              math.Random().nextInt(env.possibleWeather.length)];
                          Navigator.of(context).pushReplacement(MaterialPageRoute(
                            builder: (_) => GameScreen(environment: env, weather: weather),
                          ));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
