import 'package:flutter/material.dart';

/// Competitive rank tiers (Phase J — Ranked Events). Players earn Rank Points
/// (RP) from race performance and climb a ladder of tiers, each with three
/// divisions (III → II → I).
class RankTier {
  final String name;
  final int minRp; // RP required to enter this tier
  final Color color;
  final IconData icon;
  const RankTier(this.name, this.minRp, this.color, this.icon);
}

const List<RankTier> kRankTiers = [
  RankTier('Bronze', 0, Color(0xFFB87333), Icons.shield_outlined),
  RankTier('Silver', 600, Color(0xFFC0C0D0), Icons.shield_rounded),
  RankTier('Gold', 1500, Color(0xFFFFD23D), Icons.military_tech_outlined),
  RankTier('Platinum', 3000, Color(0xFF3DFFE0), Icons.workspace_premium_outlined),
  RankTier('Diamond', 5200, Color(0xFF22E0FF), Icons.diamond_outlined),
  RankTier('Apex', 8000, Color(0xFFFF2D9B), Icons.local_fire_department_rounded),
];

/// Resolved rank info for a given RP value.
class RankInfo {
  final RankTier tier;
  final int tierIndex;
  final int division; // 3, 2, 1 (1 is highest within a tier); 0 for top tier
  final int rpIntoTier; // RP earned beyond the tier floor
  final int rpForNext; // RP span to the next tier (0 if at max)
  final String label; // e.g. "Gold II", or "Apex" for the top tier

  const RankInfo({
    required this.tier,
    required this.tierIndex,
    required this.division,
    required this.rpIntoTier,
    required this.rpForNext,
    required this.label,
  });

  double get tierProgress => rpForNext == 0 ? 1.0 : (rpIntoTier / rpForNext).clamp(0.0, 1.0);

  static RankInfo resolve(int rp) {
    var index = 0;
    for (var i = kRankTiers.length - 1; i >= 0; i--) {
      if (rp >= kRankTiers[i].minRp) {
        index = i;
        break;
      }
    }
    final tier = kRankTiers[index];
    final isTop = index == kRankTiers.length - 1;
    final nextFloor = isTop ? tier.minRp : kRankTiers[index + 1].minRp;
    final span = isTop ? 0 : nextFloor - tier.minRp;
    final into = rp - tier.minRp;

    // Three divisions split the span; top tier has no divisions.
    String label;
    int division;
    if (isTop) {
      division = 0;
      label = tier.name;
    } else {
      final third = span / 3;
      // division 3 (lowest) → 1 (highest)
      division = 3 - (into / third).floor().clamp(0, 2);
      label = '${tier.name} ${_roman(division)}';
    }

    return RankInfo(
      tier: tier,
      tierIndex: index,
      division: division,
      rpIntoTier: into,
      rpForNext: span,
      label: label,
    );
  }

  static String _roman(int n) => switch (n) { 1 => 'I', 2 => 'II', _ => 'III' };
}
