import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../state/game_state.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    return Scaffold(
      appBar: AppBar(
        title: Text('SETTINGS', style: AppTheme.display(20)),
        leading: const BackButton(color: AppColors.textPrimary),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              NeonCard(
                glow: AppColors.neonCyan,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('HOW TO PLAY', style: AppTheme.display(16, color: AppColors.neonCyan)),
                    const SizedBox(height: 10),
                    _tip(Icons.keyboard_rounded, 'Desktop', 'Use ← → arrow keys (or A / D) to steer'),
                    _tip(Icons.touch_app_rounded, 'Mobile', 'Touch & drag anywhere to steer your car'),
                    _tip(Icons.local_fire_department_rounded, 'Overtakes',
                        'Pass cars closely to earn more cash — Near, Close, Extreme'),
                    _tip(Icons.bolt_rounded, 'Combos',
                        'Chain quick passes to multiply rewards up to 8x'),
                    _tip(Icons.local_fire_department_rounded, 'Nitro',
                        'Hold SPACE / W (or the Nitro button) to boost'),
                    _tip(Icons.warning_amber_rounded, 'Crash', 'Hitting traffic ends the run'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              NeonCard(
                glow: AppColors.neonPurple,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ACCESSIBILITY', style: AppTheme.display(16, color: AppColors.neonPurple)),
                    const SizedBox(height: 4),
                    _toggle(
                      'Reduced Flashing',
                      'Fewer particle & burst effects',
                      Icons.flash_off_rounded,
                      gs.reducedFlashing,
                      gs.setReducedFlashing,
                    ),
                    _toggle(
                      'Colorblind Mode',
                      'High-contrast pass labels & icons',
                      Icons.visibility_rounded,
                      gs.colorblindMode,
                      gs.setColorblind,
                    ),
                    _toggle(
                      'Large Text',
                      'Increase in-app text size',
                      Icons.text_fields_rounded,
                      gs.largeText,
                      gs.setLargeText,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              NeonCard(
                glow: AppColors.neonCyan,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AUDIO', style: AppTheme.display(16, color: AppColors.neonCyan)),
                    const SizedBox(height: 4),
                    _toggle(
                      'Sound Effects',
                      'Engine, nitro, passes & crashes',
                      Icons.graphic_eq_rounded,
                      gs.soundOn,
                      gs.setSound,
                      color: AppColors.neonCyan,
                    ),
                    _toggle(
                      'Music',
                      'Synthwave menu soundtrack',
                      Icons.music_note_rounded,
                      gs.musicOn,
                      gs.setMusic,
                      color: AppColors.neonCyan,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              NeonCard(
                glow: AppColors.neonGreen,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PROFILE', style: AppTheme.display(16, color: AppColors.neonGreen)),
                    const SizedBox(height: 10),
                    _stat('Total Races', '${gs.totalRaces}'),
                    _stat('Total Overtakes', '${gs.totalOvertakes}'),
                    _stat('Best Combo', '${gs.bestCombo}x'),
                    _stat('Best Distance', '${gs.bestDistance} m'),
                    _stat('High Score', fmtCash(gs.highScore)),
                    _stat('Lifetime Cash', '\$${fmtCash(gs.totalCashEarned)}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              NeonButton(
                label: 'RESET PROGRESS',
                icon: Icons.restart_alt_rounded,
                gradient: const LinearGradient(colors: [AppColors.neonOrange, AppColors.neonMagenta]),
                onTap: () => _confirmReset(context, gs),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text('Apex Rush  •  v2.0',
                    style: AppTheme.body(12, color: AppColors.textDim)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tip(IconData icon, String title, String body) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.neonCyan, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.body(14, weight: FontWeight.w700)),
                Text(body, style: AppTheme.body(13, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggle(String title, String subtitle, IconData icon, bool value,
      void Function(bool) onChanged,
      {Color color = AppColors.neonPurple}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.body(14, weight: FontWeight.w700)),
                Text(subtitle, style: AppTheme.body(12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: color,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.body(14, color: AppColors.textSecondary)),
          Text(value, style: AppTheme.display(14)),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, GameState gs) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Reset Progress?', style: AppTheme.display(18)),
        content: Text('This erases all cash, cars, upgrades and records.',
            style: AppTheme.body(14, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL', style: AppTheme.body(14, color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              gs.resetProgress();
              Navigator.pop(ctx);
            },
            child: Text('RESET', style: AppTheme.body(14, color: AppColors.neonMagenta)),
          ),
        ],
      ),
    );
  }
}
