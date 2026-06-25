import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../audio/sound.dart';
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
import 'season_screen.dart';

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
                    if (gs.dailyRewardAvailable)
                      IconButton(
                        onPressed: () => _openDailyReward(gs),
                        icon: const Icon(Icons.card_giftcard_rounded,
                            color: AppColors.neonYellow),
                        tooltip: 'Daily reward',
                      ),
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

              const SizedBox(height: 14),

              // Seasonal event banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _seasonBanner(gs),
              ),

              const SizedBox(height: 12),

              // Race button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: NeonButton(
                  label: 'RACE',
                  icon: Icons.play_arrow_rounded,
                  height: 64,
                  onTap: () {
                    _unlockAudio();
                    Sound.uiTap();
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const RaceSetupScreen()));
                  },
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

  Widget _seasonBanner(GameState gs) {
    final season = gs.currentSeason;
    final maxPoints = season.maxPoints;
    final progress =
        maxPoints == 0 ? 0.0 : (gs.seasonPoints / maxPoints).clamp(0.0, 1.0);
    final claimable = gs.claimableSeasonTiers;
    return NeonCard(
      glow: season.color,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => _go(const SeasonScreen()),
      child: Row(
        children: [
          Icon(season.icon, color: season.color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(season.name,
                        style: AppTheme.body(14, color: Colors.white, weight: FontWeight.w800)),
                    const SizedBox(width: 6),
                    Text('SEASON',
                        style: AppTheme.body(9, color: season.color, weight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: AppColors.bgElevated,
                    valueColor: AlwaysStoppedAnimation(season.color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (claimable > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                  color: AppColors.neonGreen, shape: BoxShape.circle),
              child: Text('$claimable',
                  style: AppTheme.body(11, color: Colors.black, weight: FontWeight.w900)),
            )
          else
            Icon(Icons.chevron_right_rounded, color: season.color),
        ],
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
    _unlockAudio();
    Sound.uiTap();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _unlockAudio() {
    final gs = context.read<GameState>();
    Sound.unlock();
    Sound.configure(sfx: gs.soundOn, music: gs.musicOn);
    if (gs.musicOn) Sound.startMusic();
  }

  void _openDailyReward(GameState gs) {
    _unlockAudio();
    final reward = gs.claimDailyReward();
    if (reward == null) return;
    final (cash, gems) = reward;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Row(children: [
          const Icon(Icons.card_giftcard_rounded, color: AppColors.neonYellow),
          const SizedBox(width: 8),
          Text('Daily Reward!', style: AppTheme.display(18)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Welcome back, racer. Here\'s your daily bonus:',
                style: AppTheme.body(14, color: AppColors.textSecondary)),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CurrencyChip(
                    icon: Icons.payments_rounded,
                    value: '+${fmtCash(cash)}',
                    color: AppColors.neonGreen),
                const SizedBox(width: 10),
                CurrencyChip(
                    icon: Icons.diamond_rounded,
                    value: '+$gems',
                    color: AppColors.neonCyan),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('AWESOME',
                style: AppTheme.body(14, color: AppColors.neonGreen, weight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
