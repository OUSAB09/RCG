import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/cosmetic.dart';
import '../models/season.dart';
import '../state/game_state.dart';
import '../widgets/common.dart';

/// Seasonal Event track (Phase H). Players earn event points from races and
/// claim escalating tier rewards, including an exclusive season paint.
class SeasonScreen extends StatelessWidget {
  const SeasonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final season = gs.currentSeason;
    final maxPoints = season.maxPoints;
    final progress = maxPoints == 0 ? 0.0 : (gs.seasonPoints / maxPoints).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: Text('SEASON EVENT', style: AppTheme.display(18)),
        leading: const BackButton(color: AppColors.textPrimary),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Row(children: [
                CurrencyChip(
                    icon: Icons.payments_rounded,
                    value: fmtCash(gs.cash),
                    color: AppColors.neonGreen),
                const SizedBox(width: 6),
                CurrencyChip(
                    icon: Icons.diamond_rounded,
                    value: '${gs.gems}',
                    color: AppColors.neonCyan),
              ]),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Event header
              NeonCard(
                glow: season.color,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(colors: [
                              season.color.withValues(alpha: 0.6),
                              season.color.withValues(alpha: 0.15),
                            ]),
                          ),
                          child: Icon(season.icon, color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(season.name, style: AppTheme.display(20, color: season.color)),
                              Text(season.tagline,
                                  style: AppTheme.body(13, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${gs.seasonPoints} / $maxPoints PTS',
                            style: AppTheme.display(14, color: AppColors.neonYellow)),
                        Row(children: [
                          const Icon(Icons.schedule_rounded,
                              size: 14, color: AppColors.textDim),
                          const SizedBox(width: 4),
                          Text('${gs.seasonDaysLeft}d left',
                              style: AppTheme.body(12, color: AppColors.textDim)),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: AppColors.bgElevated,
                        valueColor: AlwaysStoppedAnimation(season.color),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Earn event points by driving, overtaking and chaining combos.',
                        style: AppTheme.body(12, color: AppColors.textDim)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('REWARD TRACK',
                  style: AppTheme.display(15, color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              for (var i = 0; i < season.tiers.length; i++)
                _tierRow(context, gs, season, i),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tierRow(BuildContext context, GameState gs, Season season, int index) {
    final tier = season.tiers[index];
    final unlocked = gs.tierUnlocked(index);
    final claimed = gs.tierClaimed(index);
    final paint = tier.paintId != null ? paintById(tier.paintId!) : null;

    Color accent;
    if (claimed) {
      accent = AppColors.neonGreen;
    } else if (unlocked) {
      accent = season.color;
    } else {
      accent = AppColors.textDim;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NeonCard(
        glow: accent,
        borderOpacity: unlocked && !claimed ? 0.8 : 0.25,
        child: Row(
          children: [
            // Tier badge
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.18),
                border: Border.all(color: accent),
              ),
              child: Center(
                child: claimed
                    ? const Icon(Icons.check_rounded, color: AppColors.neonGreen, size: 22)
                    : Text('${index + 1}',
                        style: AppTheme.display(16, color: accent)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${tier.points} pts',
                      style: AppTheme.body(12, color: AppColors.textDim)),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (tier.cash > 0)
                        _reward(Icons.payments_rounded, '\$${fmtCash(tier.cash)}',
                            AppColors.neonGreen),
                      if (tier.gems > 0)
                        _reward(Icons.diamond_rounded, '${tier.gems}', AppColors.neonCyan),
                      if (paint != null)
                        _reward(Icons.palette_rounded, paint.name, paint.color),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _claimButton(context, gs, index, unlocked, claimed, accent),
          ],
        ),
      ),
    );
  }

  Widget _reward(IconData icon, String label, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 3),
      Text(label, style: AppTheme.body(13, color: color, weight: FontWeight.w700)),
    ]);
  }

  Widget _claimButton(BuildContext context, GameState gs, int index, bool unlocked,
      bool claimed, Color accent) {
    if (claimed) {
      return Text('CLAIMED',
          style: AppTheme.body(11, color: AppColors.neonGreen, weight: FontWeight.w800));
    }
    if (!unlocked) {
      return const Icon(Icons.lock_rounded, color: AppColors.textDim, size: 20);
    }
    return GestureDetector(
      onTap: () {
        gs.claimSeasonTier(index);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.card,
          content: Text('Tier ${index + 1} reward claimed!',
              style: AppTheme.body(15, color: AppColors.neonGreen)),
        ));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [accent, accent.withValues(alpha: 0.6)]),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('CLAIM',
            style: AppTheme.body(12, color: Colors.black, weight: FontWeight.w900)),
      ),
    );
  }
}
