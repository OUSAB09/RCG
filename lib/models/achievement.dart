import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Long-term milestones from the GDD/roadmap achievements system.
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int target;
  final int reward; // cash reward

  /// Reads current progress from the player's lifetime stats.
  final int Function(PlayerStatsView stats) progressOf;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.target,
    required this.reward,
    required this.progressOf,
  });
}

/// Lightweight view of the lifetime stats needed for achievement evaluation.
class PlayerStatsView {
  final int totalOvertakes;
  final int bestCombo;
  final int totalRaces;
  final int carsOwned;
  final int bestDistance;
  final int totalCashEarned;

  const PlayerStatsView({
    required this.totalOvertakes,
    required this.bestCombo,
    required this.totalRaces,
    required this.carsOwned,
    required this.bestDistance,
    required this.totalCashEarned,
  });
}

const List<Achievement> kAchievements = [
  Achievement(
    id: 'rookie',
    title: 'Rookie Driver',
    description: 'Complete your first race',
    icon: Icons.flag_rounded,
    color: AppColors.neonGreen,
    target: 1,
    reward: 500,
    progressOf: _races,
  ),
  Achievement(
    id: 'daredevil',
    title: 'Daredevil',
    description: 'Pass 100 cars across all races',
    icon: Icons.local_fire_department_rounded,
    color: AppColors.neonOrange,
    target: 100,
    reward: 2500,
    progressOf: _overtakes,
  ),
  Achievement(
    id: 'combo_master',
    title: 'Combo Master',
    description: 'Reach a 10x combo',
    icon: Icons.bolt_rounded,
    color: AppColors.neonYellow,
    target: 10,
    reward: 5000,
    progressOf: _combo,
  ),
  Achievement(
    id: 'collector',
    title: 'Collector',
    description: 'Own 5 different vehicles',
    icon: Icons.garage_rounded,
    color: AppColors.neonCyan,
    target: 5,
    reward: 10000,
    progressOf: _cars,
  ),
  Achievement(
    id: 'long_hauler',
    title: 'Long Hauler',
    description: 'Drive 5,000m in a single race',
    icon: Icons.route_rounded,
    color: AppColors.neonMagenta,
    target: 5000,
    reward: 8000,
    progressOf: _distance,
  ),
  Achievement(
    id: 'legend',
    title: 'Legend',
    description: 'Earn 250,000 total cash',
    icon: Icons.emoji_events_rounded,
    color: AppColors.neonPurple,
    target: 250000,
    reward: 50000,
    progressOf: _cash,
  ),
];

int _races(PlayerStatsView s) => s.totalRaces;
int _overtakes(PlayerStatsView s) => s.totalOvertakes;
int _combo(PlayerStatsView s) => s.bestCombo;
int _cars(PlayerStatsView s) => s.carsOwned;
int _distance(PlayerStatsView s) => s.bestDistance;
int _cash(PlayerStatsView s) => s.totalCashEarned;
