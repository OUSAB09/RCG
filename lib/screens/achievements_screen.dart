import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/achievement.dart';
import '../state/game_state.dart';
import '../widgets/common.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final stats = gs.statsView;

    return Scaffold(
      appBar: AppBar(
        title: Text('ACHIEVEMENTS', style: AppTheme.display(18)),
        leading: const BackButton(color: AppColors.textPrimary),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: CurrencyChip(
                  icon: Icons.payments_rounded,
                  value: fmtCash(gs.cash),
                  color: AppColors.neonGreen),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          top: false,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: kAchievements.length,
            itemBuilder: (context, i) {
              final a = kAchievements[i];
              final progress = a.progressOf(stats);
              final done = progress >= a.target;
              final claimed = gs.claimedAchievements.contains(a.id);
              final frac = (progress / a.target).clamp(0.0, 1.0);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: NeonCard(
                  glow: a.color,
                  borderOpacity: done ? 0.6 : 0.25,
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: a.color.withValues(alpha: done ? 0.25 : 0.1),
                          border: Border.all(color: a.color.withValues(alpha: 0.5)),
                        ),
                        child: Icon(a.icon, color: a.color, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.title, style: AppTheme.display(15)),
                            Text(a.description,
                                style: AppTheme.body(12, color: AppColors.textSecondary)),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: Stack(
                                children: [
                                  Container(height: 8, color: AppColors.bgElevated),
                                  FractionallySizedBox(
                                    widthFactor: frac,
                                    child: Container(height: 8, color: a.color),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('${_clamp(progress, a.target)} / ${a.target}',
                                style: AppTheme.body(11, color: AppColors.textDim)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      _rewardWidget(context, gs, a, done, claimed),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _rewardWidget(
      BuildContext context, GameState gs, Achievement a, bool done, bool claimed) {
    if (claimed) {
      return Column(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.neonGreen, size: 26),
          Text('CLAIMED', style: AppTheme.body(10, color: AppColors.neonGreen)),
        ],
      );
    }
    if (done) {
      return GestureDetector(
        onTap: () {
          if (gs.claimAchievement(a)) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: AppColors.card,
              content: Text('Claimed \$${fmtCash(a.reward)}!',
                  style: AppTheme.body(15, color: AppColors.neonGreen)),
            ));
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.neonGreen, AppColors.neonCyan]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('+\$${fmtCash(a.reward)}',
              style: AppTheme.body(13, color: Colors.white, weight: FontWeight.w800)),
        ),
      );
    }
    return Column(
      children: [
        const Icon(Icons.lock_rounded, color: AppColors.textDim, size: 20),
        Text('\$${fmtCash(a.reward)}', style: AppTheme.body(11, color: AppColors.textDim)),
      ],
    );
  }

  int _clamp(int p, int t) => p > t ? t : p;
}
