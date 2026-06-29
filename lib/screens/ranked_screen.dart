import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/rank.dart';
import '../state/game_state.dart';
import '../widgets/common.dart';

/// Ranked Events ladder (Phase J). Shows the player's current rank, division
/// progress, peak rank, and the full competitive tier ladder.
class RankedScreen extends StatelessWidget {
  const RankedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final info = gs.rank;
    final peak = gs.peakRank;

    return Scaffold(
      appBar: AppBar(
        title: Text('RANKED', style: AppTheme.display(20)),
        leading: const BackButton(color: AppColors.textPrimary),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Current rank hero card
              NeonCard(
                glow: info.tier.color,
                child: Column(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          info.tier.color.withValues(alpha: 0.45),
                          info.tier.color.withValues(alpha: 0.08),
                        ]),
                        border: Border.all(color: info.tier.color, width: 2),
                      ),
                      child: Icon(info.tier.icon, color: info.tier.color, size: 48),
                    ),
                    const SizedBox(height: 12),
                    Text(info.label,
                        style: AppTheme.display(26, color: info.tier.color)),
                    const SizedBox(height: 2),
                    Text('${gs.rankPoints} RP',
                        style: AppTheme.body(14, color: AppColors.textSecondary)),
                    const SizedBox(height: 14),
                    if (info.rpForNext > 0) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: info.tierProgress,
                          minHeight: 10,
                          backgroundColor: AppColors.bgElevated,
                          valueColor: AlwaysStoppedAnimation(info.tier.color),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                          '${info.rpForNext - info.rpIntoTier} RP to ${_nextLabel(info)}',
                          style: AppTheme.body(12, color: AppColors.textDim)),
                    ] else
                      Text('TOP TIER REACHED',
                          style: AppTheme.body(12,
                              color: info.tier.color, weight: FontWeight.w900)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _infoChip('PEAK RANK', peak.label, peak.tier.color, peak.tier.icon),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _infoChip(
                        'LAST RACE',
                        '${gs.lastRpDelta >= 0 ? '+' : ''}${gs.lastRpDelta} RP',
                        gs.lastRpDelta >= 0 ? AppColors.neonGreen : AppColors.neonMagenta,
                        gs.lastRpDelta >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('RANK LADDER',
                  style: AppTheme.display(15, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text('Win races to earn RP. Place above par to climb.',
                  style: AppTheme.body(12, color: AppColors.textDim)),
              const SizedBox(height: 12),
              for (var i = kRankTiers.length - 1; i >= 0; i--)
                _ladderRow(kRankTiers[i], i == info.tierIndex, gs.rankPoints),
            ],
          ),
        ),
      ),
    );
  }

  String _nextLabel(RankInfo info) {
    if (info.tierIndex < kRankTiers.length - 1 && info.division == 1) {
      return kRankTiers[info.tierIndex + 1].name;
    }
    if (info.division > 1) {
      final next = info.division - 1;
      return '${info.tier.name} ${next == 1 ? 'I' : 'II'}';
    }
    return 'next tier';
  }

  Widget _infoChip(String label, String value, Color color, IconData icon) {
    return NeonCard(
      glow: color,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.body(10, color: AppColors.textDim, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Row(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(value,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.display(15, color: color)),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _ladderRow(RankTier tier, bool current, int rp) {
    final reached = rp >= tier.minRp;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NeonCard(
        glow: current ? tier.color : (reached ? tier.color : AppColors.textDim),
        borderOpacity: current ? 0.85 : 0.22,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Opacity(
              opacity: reached ? 1 : 0.45,
              child: Icon(tier.icon, color: tier.color, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(tier.name,
                        style: AppTheme.display(16,
                            color: reached ? tier.color : AppColors.textDim)),
                    if (current) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: tier.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('YOU',
                            style: AppTheme.body(10, color: tier.color, weight: FontWeight.w900)),
                      ),
                    ],
                  ]),
                  Text('${tier.minRp}+ RP',
                      style: AppTheme.body(12, color: AppColors.textDim)),
                ],
              ),
            ),
            if (reached)
              const Icon(Icons.check_circle_rounded, color: AppColors.neonGreen, size: 20)
            else
              const Icon(Icons.lock_rounded, color: AppColors.textDim, size: 18),
          ],
        ),
      ),
    );
  }
}
