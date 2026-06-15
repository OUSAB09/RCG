import 'package:flutter/material.dart';
import '../core/theme.dart';

enum MissionMetric { distance, overtakes, nearMisses, cash, combo, races }

enum MissionPeriod { daily, weekly }

/// A LiveOps mission/challenge (Phase H).
class Mission {
  final String id;
  final MissionPeriod period;
  final MissionMetric metric;
  final int target;
  final int rewardCash;
  final int rewardGems;

  int progress; // accumulated within the period
  bool claimed;

  Mission({
    required this.id,
    required this.period,
    required this.metric,
    required this.target,
    required this.rewardCash,
    this.rewardGems = 0,
    this.progress = 0,
    this.claimed = false,
  });

  bool get complete => progress >= target;

  String get title {
    switch (metric) {
      case MissionMetric.distance:
        return 'Drive ${target}m';
      case MissionMetric.overtakes:
        return 'Overtake $target cars';
      case MissionMetric.nearMisses:
        return 'Get $target near misses';
      case MissionMetric.cash:
        return 'Earn \$$target in races';
      case MissionMetric.combo:
        return 'Reach a ${target}x combo';
      case MissionMetric.races:
        return 'Complete $target races';
    }
  }

  IconData get icon {
    switch (metric) {
      case MissionMetric.distance:
        return Icons.route_rounded;
      case MissionMetric.overtakes:
        return Icons.swap_horiz_rounded;
      case MissionMetric.nearMisses:
        return Icons.warning_amber_rounded;
      case MissionMetric.cash:
        return Icons.payments_rounded;
      case MissionMetric.combo:
        return Icons.bolt_rounded;
      case MissionMetric.races:
        return Icons.flag_rounded;
    }
  }

  Color get color {
    switch (period) {
      case MissionPeriod.daily:
        return AppColors.neonCyan;
      case MissionPeriod.weekly:
        return AppColors.neonMagenta;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'period': period.index,
        'metric': metric.index,
        'target': target,
        'rewardCash': rewardCash,
        'rewardGems': rewardGems,
        'progress': progress,
        'claimed': claimed,
      };

  factory Mission.fromJson(Map<String, dynamic> j) => Mission(
        id: j['id'],
        period: MissionPeriod.values[j['period']],
        metric: MissionMetric.values[j['metric']],
        target: j['target'],
        rewardCash: j['rewardCash'],
        rewardGems: j['rewardGems'] ?? 0,
        progress: j['progress'] ?? 0,
        claimed: j['claimed'] ?? false,
      );
}
