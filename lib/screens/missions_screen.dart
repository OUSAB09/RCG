import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/mission.dart';
import '../state/game_state.dart';
import '../widgets/common.dart';

class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final daily = gs.missions.where((m) => m.period == MissionPeriod.daily).toList();
    final weekly = gs.missions.where((m) => m.period == MissionPeriod.weekly).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('MISSIONS', style: AppTheme.display(20)),
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
              _sectionHeader('DAILY MISSIONS', 'Resets every 24h', AppColors.neonCyan),
              ...daily.map((m) => _missionTile(context, gs, m)),
              const SizedBox(height: 20),
              _sectionHeader('WEEKLY CHALLENGES', 'Bigger rewards', AppColors.neonMagenta),
              ...weekly.map((m) => _missionTile(context, gs, m)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(title, style: AppTheme.display(16, color: color)),
          const SizedBox(width: 8),
          Text(subtitle, style: AppTheme.body(12, color: AppColors.textDim)),
        ],
      ),
    );
  }

  Widget _missionTile(BuildContext context, GameState gs, Mission m) {
    final frac = (m.progress / m.target).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NeonCard(
        glow: m.color,
        borderOpacity: m.complete && !m.claimed ? 0.7 : 0.25,
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: m.color.withValues(alpha: 0.15),
                border: Border.all(color: m.color.withValues(alpha: 0.5)),
              ),
              child: Icon(m.icon, color: m.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.title, style: AppTheme.display(14)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Stack(children: [
                      Container(height: 8, color: AppColors.bgElevated),
                      FractionallySizedBox(
                        widthFactor: frac,
                        child: Container(height: 8, color: m.color),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text('${m.progress.clamp(0, m.target)} / ${m.target}',
                        style: AppTheme.body(11, color: AppColors.textDim)),
                    const Spacer(),
                    Text('+\$${fmtCash(m.rewardCash)}',
                        style: AppTheme.body(11, color: AppColors.neonGreen, weight: FontWeight.w700)),
                    if (m.rewardGems > 0) ...[
                      const SizedBox(width: 6),
                      Text('+${m.rewardGems}💎',
                          style: AppTheme.body(11, color: AppColors.neonCyan, weight: FontWeight.w700)),
                    ],
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _claimButton(context, gs, m),
          ],
        ),
      ),
    );
  }

  Widget _claimButton(BuildContext context, GameState gs, Mission m) {
    if (m.claimed) {
      return const Icon(Icons.check_circle_rounded, color: AppColors.neonGreen, size: 26);
    }
    if (m.complete) {
      return GestureDetector(
        onTap: () {
          if (gs.claimMission(m)) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: AppColors.card,
              content: Text('Reward claimed!',
                  style: AppTheme.body(15, color: AppColors.neonGreen)),
            ));
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.neonGreen, AppColors.neonCyan]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('CLAIM', style: AppTheme.body(12, color: Colors.white, weight: FontWeight.w800)),
        ),
      );
    }
    return const Icon(Icons.lock_clock_rounded, color: AppColors.textDim, size: 22);
  }
}
