import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/vehicle_catalog.dart';
import '../models/achievement.dart';
import '../models/vehicle.dart';

/// Central player profile + economy + persistence.
/// Acts as the "Cloud Save"/PlayerProfile equivalent from the architecture doc,
/// persisted locally via shared_preferences.
class GameState extends ChangeNotifier {
  static const _key = 'apex_rush_save_v1';

  // Economy
  int cash = 2000;
  int gems = 25;

  // Garage
  String selectedVehicleId = VehicleCatalog.all.first.id;
  Set<String> ownedVehicleIds = {VehicleCatalog.all.first.id};

  // Upgrades per vehicle: vehicleId -> {UpgradeType.index: level}
  Map<String, Map<int, int>> upgrades = {};

  // Lifetime stats
  int totalOvertakes = 0;
  int bestCombo = 0;
  int totalRaces = 0;
  int bestDistance = 0;
  int totalCashEarned = 0;
  int highScore = 0;

  // Claimed achievements
  Set<String> claimedAchievements = {};

  // Leaderboard (local simulated rivals + player runs)
  List<LeaderboardEntry> leaderboard = [];

  bool _loaded = false;
  bool get loaded => _loaded;

  Vehicle get selectedVehicle => VehicleCatalog.byId(selectedVehicleId);

  Map<UpgradeType, int> upgradesFor(String vehicleId) {
    final raw = upgrades[vehicleId] ?? {};
    return {
      for (final t in UpgradeType.values) t: raw[t.index] ?? 0,
    };
  }

  int upgradeLevel(String vehicleId, UpgradeType type) =>
      upgrades[vehicleId]?[type.index] ?? 0;

  VehicleStats statsFor(String vehicleId) =>
      VehicleStats.resolve(VehicleCatalog.byId(vehicleId), upgradesFor(vehicleId));

  PlayerStatsView get statsView => PlayerStatsView(
        totalOvertakes: totalOvertakes,
        bestCombo: bestCombo,
        totalRaces: totalRaces,
        carsOwned: ownedVehicleIds.length,
        bestDistance: bestDistance,
        totalCashEarned: totalCashEarned,
      );

  // ---------- Garage / Shop actions ----------

  bool owns(String vehicleId) => ownedVehicleIds.contains(vehicleId);

  bool buyVehicle(Vehicle v) {
    if (owns(v.id)) return false;
    if (cash < v.price) return false;
    cash -= v.price;
    ownedVehicleIds.add(v.id);
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

  // ---------- Race results ----------

  void recordRace({
    required int cashEarned,
    required int overtakes,
    required int maxCombo,
    required int distance,
    required int score,
  }) {
    cash += cashEarned;
    totalCashEarned += cashEarned;
    totalOvertakes += overtakes;
    totalRaces += 1;
    if (maxCombo > bestCombo) bestCombo = maxCombo;
    if (distance > bestDistance) bestDistance = distance;
    if (score > highScore) highScore = score;

    leaderboard.add(LeaderboardEntry(
      name: 'YOU',
      score: score,
      isPlayer: true,
    ));
    _trimLeaderboard();
    _save();
    notifyListeners();
  }

  bool canClaim(Achievement a) {
    if (claimedAchievements.contains(a.id)) return false;
    return a.progressOf(statsView) >= a.target;
  }

  bool claimAchievement(Achievement a) {
    if (!canClaim(a)) return false;
    claimedAchievements.add(a.id);
    cash += a.reward;
    totalCashEarned += a.reward;
    _save();
    notifyListeners();
    return true;
  }

  void _trimLeaderboard() {
    leaderboard.sort((a, b) => b.score.compareTo(a.score));
    if (leaderboard.length > 20) {
      leaderboard = leaderboard.sublist(0, 20);
    }
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
        bestCombo = m['bestCombo'] ?? 0;
        totalRaces = m['totalRaces'] ?? 0;
        bestDistance = m['bestDistance'] ?? 0;
        totalCashEarned = m['totalCashEarned'] ?? 0;
        highScore = m['highScore'] ?? 0;
        claimedAchievements = Set<String>.from(m['claimedAchievements'] ?? []);

        final up = m['upgrades'] as Map<String, dynamic>? ?? {};
        upgrades = up.map((k, v) => MapEntry(
              k,
              (v as Map<String, dynamic>)
                  .map((kk, vv) => MapEntry(int.parse(kk), vv as int)),
            ));

        final lb = m['leaderboard'] as List<dynamic>? ?? [];
        leaderboard = lb
            .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Load error: $e');
    }

    if (leaderboard.where((e) => !e.isPlayer).isEmpty) {
      _seedRivals();
    }
    _trimLeaderboard();
    _loaded = true;
    notifyListeners();
  }

  void _seedRivals() {
    const names = [
      'NeonGhost', 'V12_Demon', 'DriftKing', 'TurboNova', 'ApexHunter',
      'NightRider', 'BoostQueen', 'RedlineRex', 'SpeedSerpent', 'ChromeRacer',
    ];
    const scores = [
      8200, 12400, 6100, 15800, 9700, 4300, 11200, 7400, 13900, 5600,
    ];
    for (var i = 0; i < names.length; i++) {
      leaderboard.add(LeaderboardEntry(name: names[i], score: scores[i]));
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final m = {
        'cash': cash,
        'gems': gems,
        'selectedVehicleId': selectedVehicleId,
        'ownedVehicleIds': ownedVehicleIds.toList(),
        'totalOvertakes': totalOvertakes,
        'bestCombo': bestCombo,
        'totalRaces': totalRaces,
        'bestDistance': bestDistance,
        'totalCashEarned': totalCashEarned,
        'highScore': highScore,
        'claimedAchievements': claimedAchievements.toList(),
        'upgrades': upgrades.map((k, v) =>
            MapEntry(k, v.map((kk, vv) => MapEntry(kk.toString(), vv)))),
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
    totalOvertakes = 0;
    bestCombo = 0;
    totalRaces = 0;
    bestDistance = 0;
    totalCashEarned = 0;
    highScore = 0;
    claimedAchievements = {};
    leaderboard = [];
    _seedRivals();
    _trimLeaderboard();
    await _save();
    notifyListeners();
  }
}

class LeaderboardEntry {
  final String name;
  final int score;
  final bool isPlayer;
  LeaderboardEntry({required this.name, required this.score, this.isPlayer = false});

  Map<String, dynamic> toJson() => {'name': name, 'score': score, 'isPlayer': isPlayer};
  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
        name: j['name'],
        score: j['score'],
        isPlayer: j['isPlayer'] ?? false,
      );
}
