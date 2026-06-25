import 'package:flutter/material.dart';
import '../core/theme.dart';

/// A single reward tier on the seasonal event track (Phase H — Seasonal Events).
class SeasonTier {
  final int points; // cumulative event points required to unlock
  final int cash;
  final int gems;
  final String? paintId; // optional exclusive cosmetic unlock
  const SeasonTier({
    required this.points,
    this.cash = 0,
    this.gems = 0,
    this.paintId,
  });
}

/// A time-limited season. Event points are earned during races; players climb
/// the tier ladder to claim escalating rewards including an exclusive paint.
class Season {
  final String id;
  final String name;
  final String tagline;
  final Color color;
  final IconData icon;
  final List<SeasonTier> tiers;

  const Season({
    required this.id,
    required this.name,
    required this.tagline,
    required this.color,
    required this.icon,
    required this.tiers,
  });

  int get maxPoints => tiers.isEmpty ? 0 : tiers.last.points;
}

/// The currently-active season. Rotates by week so the event feels "live".
/// Returns a deterministic season for a given week index.
Season seasonForWeek(int week) {
  final defs = _seasonRotation;
  return defs[week % defs.length];
}

const List<SeasonTier> _standardTrack = [
  SeasonTier(points: 100, cash: 1500),
  SeasonTier(points: 250, gems: 5),
  SeasonTier(points: 450, cash: 4000),
  SeasonTier(points: 700, gems: 8),
  SeasonTier(points: 1000, cash: 8000),
  SeasonTier(points: 1400, gems: 12),
  SeasonTier(points: 1900, cash: 14000),
  SeasonTier(points: 2500, gems: 18),
];

final List<Season> _seasonRotation = [
  Season(
    id: 'neon_nights',
    name: 'Neon Nights',
    tagline: 'Light up the city skyline',
    color: AppColors.neonMagenta,
    icon: Icons.nightlife_rounded,
    tiers: [
      ..._standardTrack.sublist(0, 7),
      const SeasonTier(points: 2500, gems: 18, paintId: 'season_neon'),
    ],
  ),
  Season(
    id: 'desert_storm',
    name: 'Desert Storm',
    tagline: 'Conquer the dunes at full throttle',
    color: AppColors.neonYellow,
    icon: Icons.wb_twilight_rounded,
    tiers: [
      ..._standardTrack.sublist(0, 7),
      const SeasonTier(points: 2500, gems: 18, paintId: 'season_sand'),
    ],
  ),
  Season(
    id: 'coastal_rush',
    name: 'Coastal Rush',
    tagline: 'Chase the horizon along the coast',
    color: AppColors.neonCyan,
    icon: Icons.waves_rounded,
    tiers: [
      ..._standardTrack.sublist(0, 7),
      const SeasonTier(points: 2500, gems: 18, paintId: 'season_aqua'),
    ],
  ),
];
