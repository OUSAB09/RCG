import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../state/game_state.dart';
import '../widgets/common.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final entries = [...gs.leaderboard]..sort((a, b) => b.score.compareTo(a.score));

    return Scaffold(
      appBar: AppBar(
        title: Text('LEADERBOARD', style: AppTheme.display(20)),
        leading: const BackButton(color: AppColors.textPrimary),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          top: false,
          child: entries.isEmpty
              ? Center(
                  child: Text('Race to set a score!',
                      style: AppTheme.body(16, color: AppColors.textSecondary)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  itemBuilder: (context, i) {
                    final e = entries[i];
                    final rank = i + 1;
                    final medalColor = rank == 1
                        ? AppColors.neonYellow
                        : rank == 2
                            ? const Color(0xFFC0C0D0)
                            : rank == 3
                                ? AppColors.neonOrange
                                : AppColors.textDim;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: NeonCard(
                        glow: e.isPlayer ? AppColors.neonCyan : medalColor,
                        borderOpacity: e.isPlayer ? 0.7 : 0.25,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 34,
                              child: rank <= 3
                                  ? Icon(Icons.emoji_events_rounded, color: medalColor, size: 24)
                                  : Text('$rank',
                                      style: AppTheme.display(16, color: AppColors.textDim)),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(e.name,
                                  style: AppTheme.body(16,
                                      color: e.isPlayer ? AppColors.neonCyan : AppColors.textPrimary,
                                      weight: e.isPlayer ? FontWeight.w800 : FontWeight.w600)),
                            ),
                            Text(fmtCash(e.score),
                                style: AppTheme.display(16, color: AppColors.neonYellow)),
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
}
