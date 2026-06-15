import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/vehicle_catalog.dart';
import '../data/mission_generator.dart';
import '../models/achievement.dart';
import '../models/cosmetic.dart';
import '../models/mission.dart';
import '../models/vehicle.dart';

/// Central player profile + economy + persistence (cloud-save equivalent,
/// stored locally via shared_preferences, with a save version for migration).
class GameState extends ChangeNotifier {
  static const _key = 'apex_rush_save_v2';
  static const int saveVersion = 2;

  // Economy
  int cash = 2000;
  int gems = 25;

  // Garage
  String selectedVehicleId = VehicleCatalog.all.first.id;
  Set<String> ownedVehicleIds = {VehicleCatalog.all.first.id};

  // Upgrades per vehicle: vehicleId -> {UpgradeType.index: level}
  Map<String, Map<int, int>> upgrades = {};

  // Vehicle mastery XP: vehicleId -> totalXp
  Map<String, int> masteryXp = {};

  // Cosmetics: paint applied per vehicle, and owned paint ids
  Map<String, String> appliedPaint = {};
  Set<String> ownedPaints = {kDefaultPaint.id};

  // Lifetime stats
  int totalOvertakes = 0;
  int totalNearMisses = 0;
  int bestCombo = 0;
  int totalRaces = 0;
  int bestDistance = 0;
  int totalCashEarned = 0;
  int highScore = 0;

  // Achievements
  Set<String> claimedAchievements = {};
  Set<String> claimedCollectionRewards = {};

  // LiveOps
  List<Mission> missions = [];
  int _dailySeed = 0;
  int _weeklySeed = 0;

  // Leaderboards (timeframe). Each entry stores an epoch-day stamp.
  List<LeaderboardEntry> leaderboard = [];
  int ghostBestScore = 0;
  List<double> ghostBestTrack = [];

  // Accessibility (Phase L)
  bool reducedFlashing = false;
  bool colorblindMode = false;
  bool largeText = false;
  bool adFree = false; // premium package

  bool _loaded = false;
  bool get loaded => _loaded;

  // ---------- Derived getters ----------

  Vehicle get selectedVehicle => VehicleCatalog.byId(selectedVehicleId);

  Color displayColor(String vehicleId) {
    final paint = paintById(appliedPaint[vehicleId] ?? kDefaultPaint.id);
    if (paint.id == kDefaultPaint.id) return VehicleCatalog.byId(vehicleId).bodyColor;
    return paint.color;
  }

  Map<UpgradeType, int> upgradesFor(String vehicleId) {
    final raw = upgrades[vehicleId] ?? {};
    return {for (final t in UpgradeType.values) t: raw[t.index] ?? 0};
  }

  int upgradeLevel(String vehicleId, UpgradeType type) =>
      upgrades[vehicleId]?[type.index] ?? 0;

  VehicleStats statsFor(String vehicleId) =>
      VehicleStats.resolve(VehicleCatalog.byId(vehicleId), upgradesFor(vehicleId));

  int masteryLevel(String vehicleId) =>
      Mastery.resolve(masteryXp[vehicleId] ?? 0).$1;

  (int, int, int) masteryProgress(String vehicleId) =>
      Mastery.resolve(masteryXp[vehicleId] ?? 0);

  PlayerStatsView get statsView => PlayerStatsView(
        totalOvertakes: totalOvertakes,
        bestCombo: bestCombo,
        totalRaces: totalRaces,
        carsOwned: ownedVehicleIds.length,
        bestDistance: bestDistance,
        totalCashEarned: totalCashEarned,
      );

  // ---------- Garage / Shop ----------

  bool owns(String vehicleId) => ownedVehicleIds.contains(vehicleId);

  bool buyVehicle(Vehicle v) {
    if (owns(v.id) || cash < v.price) return false;
    cash -= v.price;
    ownedVehicleIds.add(v.id);
    _checkCollectionRewards();
    _save();
    notifyListeners();
    return true;
  }

  void selectVehicle(String vehicleId) {
    if (!owns(vehicleId)) return;
    selectedVehicleId = vehicleId;
    _save();
    notifyListeners();
  }

  bool upgrade(String vehicleId, UpgradeType type) {
    final level = upgradeLevel(vehicleId, type);
    if (level >= VehicleStats.maxUpgradeLevel) return false;
    final cost = upgradeCost(VehicleCatalog.byId(vehicleId).vClass, level);
    if (cash < cost) return false;
    cash -= cost;
    upgrades.putIfAbsent(vehicleId, () => {});
    upgrades[vehicleId]![type.index] = level + 1;
    _save();
    notifyListeners();
    return true;
  }

  // ---------- Cosmetics (Phase I) ----------

  bool ownsPaint(String paintId) => ownedPaints.contains(paintId);

  bool buyPaint(PaintColor p) {
    if (ownsPaint(p.id)) return false;
    if (p.premium) {
      if (gems < p.price) return false;
      gems -= p.price;
    } else {
      if (cash < p.price) return false;
      cash -= p.price;
    }
    ownedPaints.add(p.id);
    _save();
    notifyListeners();
    return true;
  }

  void applyPaint(String vehicleId, String paintId) {
    if (!ownsPaint(paintId)) return;
    appliedPaint[vehicleId] = paintId;
    _save();
    notifyListeners();
  }

  // ---------- Race results ----------

  void recordRace({
    required String vehicleId,
    required int cashEarned,
    required int overtakes,
    required int nearMisses,
    required int maxCombo,
    required int distance,
    required int score,
    List<double>? ghostTrack,
  }) {
    cash += cashEarned;
    totalCashEarned += cashEarned;
    totalOvertakes += overtakes;
    totalNearMisses += nearMisses;
    totalRaces += 1;
    if (maxCombo > bestCombo) bestCombo = maxCombo;
    if (distance > bestDistance) bestDistance = distance;
    if (score > highScore) highScore = score;

    // Vehicle mastery XP
    final xp = (distance ~/ 10) + overtakes * 3 + maxCombo * 5;
    masteryXp[vehicleId] = (masteryXp[vehicleId] ?? 0) + xp;

    // Ghost best
    if (score > ghostBestScore && ghostTrack != null) {
      ghostBestScore = score;
      ghostBestTrack = List<double>.from(ghostTrack);
    }

    // Leaderboard entry (timestamped)
    leaderboard.add(LeaderboardEntry(
      name: 'YOU',
      score: score,
      isPlayer: true,
      epochDay: _epochDay(),
    ));
    _trimLeaderboard();

    // Mission progress
    _advanceMissions(
        distance: distance,
        overtakes: overtakes,
        nearMisses: nearMisses,
        cash: cashEarned,
        combo: maxCombo);

    _save();
    notifyListeners();
  }

  /// Last-vehicle XP gained for the result screen.
  int lastXpGained(int distance, int overtakes, int maxCombo) =>
      (distance ~/ 10) + overtakes * 3 + maxCombo * 5;

  // ---------- Achievements & Collection ----------

  bool canClaim(Achievement a) =>
      !claimedAchievements.contains(a.id) && a.progressOf(statsView) >= a.target;

  bool claimAchievement(Achievement a) {
    if (!canClaim(a)) return false;
    claimedAchievements.add(a.id);
    cash += a.reward;
    totalCashEarned += a.reward;
    _save();
    notifyListeners();
    return true;
  }

  /// Collection rewards (Phase D): owning N cars & completing classes.
  void _checkCollectionRewards() {
    // Ownership milestones handled lazily; rewards auto-granted here.
    final owned = ownedVehicleIds.length;
    for (final m in [3, 5, 8]) {
      final id = 'own_$m';
      if (owned >= m && !claimedCollectionRewards.contains(id)) {
        claimedCollectionRewards.add(id);
        final reward = m * 3000;
        cash += reward;
        gems += m;
      }
    }
  }

  // ---------- LiveOps Missions (Phase H) ----------

  void _refreshMissionsIfNeeded() {
    final day = _epochDay();
    final week = day ~/ 7;
    bool changed = false;
    if (_dailySeed != day) {
      _dailySeed = day;
      missions.removeWhere((m) => m.period == MissionPeriod.daily);
      missions.addAll(MissionGenerator.daily(day));
      changed = true;
    }
    if (_weeklySeed != week) {
      _weeklySeed = week;
      missions.removeWhere((m) => m.period == MissionPeriod.weekly);
      missions.addAll(MissionGenerator.weekly(week));
      changed = true;
    }
    if (changed) _save();
  }

  void _advanceMissions({
    required int distance,
    required int overtakes,
    required int nearMisses,
    required int cash,
    required int combo,
  }) {
    for (final m in missions) {
      if (m.claimed) continue;
      switch (m.metric) {
        case MissionMetric.distance:
          m.progress += distance;
          break;
        case MissionMetric.overtakes:
          m.progress += overtakes;
          break;
        case MissionMetric.nearMisses:
          m.progress += nearMisses;
          break;
        case MissionMetric.cash:
          m.progress += cash;
          break;
        case MissionMetric.combo:
          if (combo > m.progress) m.progress = combo;
          break;
        case MissionMetric.races:
          m.progress += 1;
          break;
      }
    }
  }

  /// Number of missions that are complete but not yet claimed (for menu badge).
  int get claimableMissions =>
      missions.where((m) => m.complete && !m.claimed).length;

  bool claimMission(Mission m) {
    if (m.claimed || !m.complete) return false;
    m.claimed = true;
    cash += m.rewardCash;
    gems += m.rewardGems;
    totalCashEarned += m.rewardCash;
    _save();
    notifyListeners();
    return true;
  }

  // ---------- Settings ----------

  void setReducedFlashing(bool v) {
    reducedFlashing = v;
    _save();
    notifyListeners();
  }

  void setColorblind(bool v) {
    colorblindMode = v;
    _save();
    notifyListeners();
  }

  void setLargeText(bool v) {
    largeText = v;
    _save();
    notifyListeners();
  }

  void addGems(int n) {
    gems += n;
    _save();
    notifyListeners();
  }

  void addCash(int n) {
    cash += n;
    totalCashEarned += n;
    _save();
    notifyListeners();
  }

  void buyPremium() {
    if (gems < 100 || adFree) return;
    gems -= 100;
    adFree = true;
    _save();
    notifyListeners();
  }

  // ---------- Helpers ----------

  int _epochDay() => DateTime.now().millisecondsSinceEpoch ~/ (1000 * 60 * 60 * 24);

  void _trimLeaderboard() {
    leaderboard.sort((a, b) => b.score.compareTo(a.score));
    if (leaderboard.length > 60) leaderboard = leaderboard.sublist(0, 60);
  }

  List<LeaderboardEntry> leaderboardFor(LeaderboardScope scope) {
    final today = _epochDay();
    Iterable<LeaderboardEntry> list = leaderboard;
    switch (scope) {
      case LeaderboardScope.daily:
        list = leaderboard.where((e) => e.epochDay == today || !e.isPlayer && e.epochDay >= today - 1);
        break;
      case LeaderboardScope.weekly:
        list = leaderboard.where((e) => e.epochDay >= today - 7);
        break;
      case LeaderboardScope.allTime:
        list = leaderboard;
        break;
    }
    final out = list.toList()..sort((a, b) => b.score.compareTo(a.score));
    return out.take(20).toList();
  }

  // ---------- Persistence ----------

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        cash = m['cash'] ?? cash;
        gems = m['gems'] ?? gems;
        selectedVehicleId = m['selectedVehicleId'] ?? selectedVehicleId;
        ownedVehicleIds = Set<String>.from(m['ownedVehicleIds'] ?? ownedVehicleIds);
        totalOvertakes = m['totalOvertakes'] ?? 0;
        totalNearMisses = m['totalNearMisses'] ?? 0;
        bestCombo = m['bestCombo'] ?? 0;
        totalRaces = m['totalRaces'] ?? 0;
        bestDistance = m['bestDistance'] ?? 0;
        totalCashEarned = m['totalCashEarned'] ?? 0;
        highScore = m['highScore'] ?? 0;
        claimedAchievements = Set<String>.from(m['claimedAchievements'] ?? []);
        claimedCollectionRewards = Set<String>.from(m['claimedCollectionRewards'] ?? []);
        ownedPaints = Set<String>.from(m['ownedPaints'] ?? [kDefaultPaint.id]);
        appliedPaint = Map<String, String>.from(m['appliedPaint'] ?? {});
        masteryXp = Map<String, int>.from(m['masteryXp'] ?? {});
        ghostBestScore = m['ghostBestScore'] ?? 0;
        ghostBestTrack = (m['ghostBestTrack'] as List<dynamic>? ?? [])
            .map((e) => (e as num).toDouble())
            .toList();
        reducedFlashing = m['reducedFlashing'] ?? false;
        colorblindMode = m['colorblindMode'] ?? false;
        largeText = m['largeText'] ?? false;
        adFree = m['adFree'] ?? false;
        _dailySeed = m['dailySeed'] ?? 0;
        _weeklySeed = m['weeklySeed'] ?? 0;

        final up = m['upgrades'] as Map<String, dynamic>? ?? {};
        upgrades = up.map((k, v) => MapEntry(
            k,
            (v as Map<String, dynamic>)
                .map((kk, vv) => MapEntry(int.parse(kk), vv as int))));

        missions = (m['missions'] as List<dynamic>? ?? [])
            .map((e) => Mission.fromJson(e as Map<String, dynamic>))
            .toList();

        leaderboard = (m['leaderboard'] as List<dynamic>? ?? [])
            .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Load error: $e');
    }

    if (leaderboard.where((e) => !e.isPlayer).isEmpty) _seedRivals();
    _trimLeaderboard();
    _refreshMissionsIfNeeded();
    _loaded = true;
    notifyListeners();
  }

  void _seedRivals() {
    const names = [
      'NeonGhost', 'V12_Demon', 'DriftKing', 'TurboNova', 'ApexHunter',
      'NightRider', 'BoostQueen', 'RedlineRex', 'SpeedSerpent', 'ChromeRacer',
      'PhantomZ', 'NitroFox', 'BlazeMaru', 'VoltRunner', 'IronPiston',
    ];
    const scores = [
      8200, 12400, 6100, 15800, 9700, 4300, 11200, 7400, 13900, 5600,
      18200, 16400, 7900, 10500, 6800,
    ];
    final today = _epochDay();
    for (var i = 0; i < names.length; i++) {
      leaderboard.add(LeaderboardEntry(
        name: names[i],
        score: scores[i],
        epochDay: today - (i % 5),
      ));
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final m = {
        'version': saveVersion,
        'cash': cash,
        'gems': gems,
        'selectedVehicleId': selectedVehicleId,
        'ownedVehicleIds': ownedVehicleIds.toList(),
        'totalOvertakes': totalOvertakes,
        'totalNearMisses': totalNearMisses,
        'bestCombo': bestCombo,
        'totalRaces': totalRaces,
        'bestDistance': bestDistance,
        'totalCashEarned': totalCashEarned,
        'highScore': highScore,
        'claimedAchievements': claimedAchievements.toList(),
        'claimedCollectionRewards': claimedCollectionRewards.toList(),
        'ownedPaints': ownedPaints.toList(),
        'appliedPaint': appliedPaint,
        'masteryXp': masteryXp,
        'ghostBestScore': ghostBestScore,
        'ghostBestTrack': ghostBestTrack,
        'reducedFlashing': reducedFlashing,
        'colorblindMode': colorblindMode,
        'largeText': largeText,
        'adFree': adFree,
        'dailySeed': _dailySeed,
        'weeklySeed': _weeklySeed,
        'upgrades': upgrades.map((k, v) =>
            MapEntry(k, v.map((kk, vv) => MapEntry(kk.toString(), vv)))),
        'missions': missions.map((e) => e.toJson()).toList(),
        'leaderboard': leaderboard.map((e) => e.toJson()).toList(),
      };
      await prefs.setString(_key, jsonEncode(m));
    } catch (e) {
      if (kDebugMode) debugPrint('Save error: $e');
    }
  }

  Future<void> resetProgress() async {
    cash = 2000;
    gems = 25;
    selectedVehicleId = VehicleCatalog.all.first.id;
    ownedVehicleIds = {VehicleCatalog.all.first.id};
    upgrades = {};
    masteryXp = {};
    appliedPaint = {};
    ownedPaints = {kDefaultPaint.id};
    totalOvertakes = 0;
    totalNearMisses = 0;
    bestCombo = 0;
    totalRaces = 0;
    bestDistance = 0;
    totalCashEarned = 0;
    highScore = 0;
    claimedAchievements = {};
    claimedCollectionRewards = {};
    missions = [];
    leaderboard = [];
    ghostBestScore = 0;
    ghostBestTrack = [];
    _dailySeed = 0;
    _weeklySeed = 0;
    _seedRivals();
    _trimLeaderboard();
    _refreshMissionsIfNeeded();
    await _save();
    notifyListeners();
  }
}

enum LeaderboardScope { daily, weekly, allTime }

class LeaderboardEntry {
  final String name;
  final int score;
  final bool isPlayer;
  final int epochDay;
  LeaderboardEntry({
    required this.name,
    required this.score,
    this.isPlayer = false,
    this.epochDay = 0,
  });

  Map<String, dynamic> toJson() =>
      {'name': name, 'score': score, 'isPlayer': isPlayer, 'epochDay': epochDay};
  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
        name: j['name'],
        score: j['score'],
        isPlayer: j['isPlayer'] ?? false,
        epochDay: j['epochDay'] ?? 0,
      );
}
