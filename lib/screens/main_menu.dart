import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../state/game_state.dart';
import '../widgets/common.dart';
import '../widgets/car_preview.dart';
import 'garage_screen.dart';
import 'shop_screen.dart';
import 'leaderboard_screen.dart';
import 'achievements_screen.dart';
import 'settings_screen.dart';
import 'race_setup_screen.dart';
import 'missions_screen.dart';
import 'cosmetics_screen.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final vehicle = gs.selectedVehicle;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    CurrencyChip(
                        icon: Icons.payments_rounded,
                        value: fmtCash(gs.cash),
                        color: AppColors.neonGreen),
                    const SizedBox(width: 8),
                    CurrencyChip(
                        icon: Icons.diamond_rounded,
                        value: '${gs.gems}',
                        color: AppColors.neonCyan),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _go(const SettingsScreen()),
                      icon: const Icon(Icons.settings_rounded,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              // Title
              const SizedBox(height: 8),
              ShaderMask(
                shaderCallback: (r) => AppColors.brandGradient.createShader(r),
                child: Text('APEX RUSH',
                    style: AppTheme.display(40, color: Colors.white, weight: FontWeight.w900)),
              ),
              Text('OVERTAKE • COMBO • DOMINATE',
                  style: AppTheme.body(13, color: AppColors.textSecondary, weight: FontWeight.w600)),

              // Car showroom
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _ctrl,
                    builder: (context, child) {
                      final bob = math.sin(_ctrl.value * math.pi * 2) * 8;
                      return Transform.translate(
                        offset: Offset(0, bob),
                        child: child,
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [
                              vehicle.vClass.color.withValues(alpha: 0.25),
                              Colors.transparent,
                            ]),
                          ),
                          child: Center(
                            child: CarPreview(
                                color: gs.displayColor(vehicle.id), width: 90, height: 168),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(vehicle.name,
                            style: AppTheme.display(20, color: Colors.white)),
                        Text(vehicle.vClass.label.toUpperCase(),
                            style: AppTheme.body(13, color: vehicle.vClass.color, weight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),

              // Stats summary
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _miniStat('HIGH SCORE', fmtCash(gs.highScore), AppColors.neonYellow),
                    _miniStat('BEST COMBO', '${gs.bestCombo}x', AppColors.neonMagenta),
                    _miniStat('PASSES', '${gs.totalOvertakes}', AppColors.neonCyan),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Race button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: NeonButton(
                  label: 'RACE',
                  icon: Icons.play_arrow_rounded,
                  height: 64,
                  onTap: () => _go(const RaceSetupScreen()),
                ),
              ),

              const SizedBox(height: 12),

              // Menu grid - row 1
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Row(
                  children: [
                    _menuTile(Icons.garage_rounded, 'GARAGE', AppColors.neonCyan,
                        () => _go(const GarageScreen())),
                    const SizedBox(width: 12),
                    _menuTile(Icons.storefront_rounded, 'SHOP', AppColors.neonGreen,
                        () => _go(const ShopScreen())),
                    const SizedBox(width: 12),
                    _menuTile(Icons.palette_rounded, 'PAINT', AppColors.neonOrange,
                        () => _go(const CosmeticsScreen())),
                  ],
                ),
              ),

              // Menu grid - row 2
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
                child: Row(
                  children: [
                    _menuTile(Icons.assignment_turned_in_rounded, 'MISSIONS',
                        AppColors.neonPurple, () => _go(const MissionsScreen()),
                        badge: gs.claimableMissions),
                    const SizedBox(width: 12),
                    _menuTile(Icons.leaderboard_rounded, 'RANKS', AppColors.neonYellow,
                        () => _go(const LeaderboardScreen())),
                    const SizedBox(width: 12),
                    _menuTile(Icons.emoji_events_rounded, 'GOALS', AppColors.neonMagenta,
                        () => _go(const AchievementsScreen())),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: AppTheme.display(18, color: color)),
        Text(label, style: AppTheme.body(11, color: AppColors.textDim, weight: FontWeight.w600)),
      ],
    );
  }

  Widget _menuTile(IconData icon, String label, Color color, VoidCallback onTap,
      {int badge = 0}) {
    return Expanded(
      child: NeonCard(
        glow: color,
        padding: const EdgeInsets.symmetric(vertical: 14),
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                Icon(icon, color: color, size: 26),
                const SizedBox(height: 6),
                Text(label,
                    style: AppTheme.body(11,
                        color: AppColors.textSecondary, weight: FontWeight.w700)),
              ],
            ),
            if (badge > 0)
              Positioned(
                top: -8,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: AppColors.neonGreen,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text('$badge',
                      textAlign: TextAlign.center,
                      style: AppTheme.body(10, color: Colors.black, weight: FontWeight.w900)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _go(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}
