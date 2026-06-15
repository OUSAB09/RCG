import 'dart:math' as math;
import '../models/mission.dart';

/// Generates deterministic-but-rotating sets of daily/weekly missions.
class MissionGenerator {
  static List<Mission> daily(int daySeed) {
    final rng = math.Random(daySeed);
    final pool = <Mission Function()>[
      () => Mission(
          id: 'd_dist',
          period: MissionPeriod.daily,
          metric: MissionMetric.distance,
          target: 2000 + rng.nextInt(4) * 500,
          rewardCash: 1500),
      () => Mission(
          id: 'd_over',
          period: MissionPeriod.daily,
          metric: MissionMetric.overtakes,
          target: 30 + rng.nextInt(5) * 10,
          rewardCash: 2000),
      () => Mission(
          id: 'd_near',
          period: MissionPeriod.daily,
          metric: MissionMetric.nearMisses,
          target: 15 + rng.nextInt(4) * 5,
          rewardCash: 2500),
      () => Mission(
          id: 'd_combo',
          period: MissionPeriod.daily,
          metric: MissionMetric.combo,
          target: 6 + rng.nextInt(3),
          rewardCash: 3000),
      () => Mission(
          id: 'd_cash',
          period: MissionPeriod.daily,
          metric: MissionMetric.cash,
          target: 3000 + rng.nextInt(4) * 1000,
          rewardCash: 1800),
    ];
    pool.shuffle(rng);
    return pool.take(3).map((f) => f()).toList();
  }

  static List<Mission> weekly(int weekSeed) {
    final rng = math.Random(weekSeed);
    final pool = <Mission Function()>[
      () => Mission(
          id: 'w_dist',
          period: MissionPeriod.weekly,
          metric: MissionMetric.distance,
          target: 15000 + rng.nextInt(4) * 2500,
          rewardCash: 10000,
          rewardGems: 10),
      () => Mission(
          id: 'w_over',
          period: MissionPeriod.weekly,
          metric: MissionMetric.overtakes,
          target: 200 + rng.nextInt(4) * 50,
          rewardCash: 12000,
          rewardGems: 12),
      () => Mission(
          id: 'w_races',
          period: MissionPeriod.weekly,
          metric: MissionMetric.races,
          target: 15 + rng.nextInt(3) * 5,
          rewardCash: 8000,
          rewardGems: 8),
      () => Mission(
          id: 'w_near',
          period: MissionPeriod.weekly,
          metric: MissionMetric.nearMisses,
          target: 120 + rng.nextInt(4) * 30,
          rewardCash: 14000,
          rewardGems: 15),
    ];
    pool.shuffle(rng);
    return pool.take(2).map((f) => f()).toList();
  }
}
