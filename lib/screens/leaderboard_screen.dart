import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../state/game_state.dart';
import '../widgets/common.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  LeaderboardScope _scope = LeaderboardScope.allTime;

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final entries = gs.leaderboardFor(_scope);

    return Scaffold(
      appBar: AppBar(
        title: Text('LEADERBOARD', style: AppTheme.display(20)),
        leading: const BackButton(color: AppColors.textPrimary),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Scope tabs
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _tab('DAILY', LeaderboardScope.daily),
                    const SizedBox(width: 8),
                    _tab('WEEKLY', LeaderboardScope.weekly),
                    const SizedBox(width: 8),
                    _tab('ALL-TIME', LeaderboardScope.allTime),
                  ],
                ),
              ),
              // Ghost best
              if (gs.ghostBestScore > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: NeonCard(
                    glow: AppColors.neonPurple,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(children: [
                      const Icon(Icons.directions_car_filled_rounded,
                          color: AppColors.neonPurple, size: 20),
                      const SizedBox(width: 10),
                      Text('GHOST — Personal Best',
                          style: AppTheme.body(13, color: AppColors.textSecondary)),
                      const Spacer(),
                      Text(fmtCash(gs.ghostBestScore),
                          style: AppTheme.display(15, color: AppColors.neonPurple)),
                    ]),
                  ),
                ),
              Expanded(
                child: entries.isEmpty
                    ? Center(
                        child: Text('No runs in this period yet.\nRace to climb the board!',
                            textAlign: TextAlign.center,
                            style: AppTheme.body(15, color: AppColors.textSecondary)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                                            color: e.isPlayer
                                                ? AppColors.neonCyan
                                                : AppColors.textPrimary,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(String label, LeaderboardScope scope) {
    final active = _scope == scope;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _scope = scope),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: active ? AppColors.brandGradient : null,
            color: active ? null : AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: active ? Colors.transparent : Colors.white12),
          ),
          child: Center(
            child: Text(label,
                style: AppTheme.body(13,
                    color: active ? Colors.white : AppColors.textSecondary,
                    weight: FontWeight.w800)),
          ),
        ),
      ),
    );
  }
}
