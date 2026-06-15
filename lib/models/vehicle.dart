import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Vehicle classes from the GDD (Economy -> Hypercar).
enum VehicleClass {
  economy('Economy', AppColors.textSecondary),
  hatchback('Hatchback', AppColors.neonGreen),
  sedan('Sedan', AppColors.neonCyan),
  suv('SUV', AppColors.neonYellow),
  muscle('Muscle', AppColors.neonOrange),
  sports('Sports', AppColors.neonMagenta),
  supercar('Supercar', AppColors.neonPurple),
  hypercar('Hypercar', Color(0xFFFFFFFF));

  const VehicleClass(this.label, this.color);
  final String label;
  final Color color;
}

/// Upgrade categories from the development plan (Phase D).
enum UpgradeType {
  engine('Engine', Icons.settings_rounded),
  tires('Tires', Icons.trip_origin_rounded),
  weight('Weight', Icons.fitness_center_rounded),
  aero('Aero', Icons.air_rounded),
  nitro('Nitro', Icons.local_fire_department_rounded),
  electronics('Electronics', Icons.memory_rounded);

  const UpgradeType(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Static vehicle definition. The actual performance is derived from a
/// physics simulation of Engine Power, Weight, Drag and Grip — exactly as the
/// roadmap dictates (top speed is a dynamic combination of physical limits).
class Vehicle {
  final String id;
  final String name;
  final VehicleClass vClass;
  final int price; // cash to unlock; 0 = starter
  final Color bodyColor;

  // Base physical attributes (before upgrades)
  final double enginePower; // horsepower-equivalent (raw acceleration & top speed)
  final double weight; // kg (handling, braking, momentum)
  final double drag; // aerodynamic drag coefficient (lower = faster top speed)
  final double grip; // tire grip 0..1 (steering responsiveness)

  const Vehicle({
    required this.id,
    required this.name,
    required this.vClass,
    required this.price,
    required this.bodyColor,
    required this.enginePower,
    required this.weight,
    required this.drag,
    required this.grip,
  });
}

/// Resolves the live performance of a vehicle given the player's upgrades.
/// Upgrade levels range 0..[maxUpgradeLevel].
class VehicleStats {
  static const int maxUpgradeLevel = 5;

  final double topSpeed; // km/h (display) -> internal world units handled in game
  final double acceleration; // 0..1 normalized
  final double handling; // 0..1 normalized
  final double nitroPower; // 0..1 boost strength
  final double stability; // 0..1 electronics: traction/abs/weather resistance

  const VehicleStats({
    required this.topSpeed,
    required this.acceleration,
    required this.handling,
    required this.nitroPower,
    required this.stability,
  });

  /// Physics-driven resolution.
  /// Top speed ∝ enginePower / (weight * drag)  (the "three physical limits")
  /// Acceleration ∝ enginePower / weight
  /// Handling ∝ grip * (1 / weight factor)
  factory VehicleStats.resolve(Vehicle v, Map<UpgradeType, int> upgrades) {
    final eng = upgrades[UpgradeType.engine] ?? 0;
    final tire = upgrades[UpgradeType.tires] ?? 0;
    final wgt = upgrades[UpgradeType.weight] ?? 0;
    final aero = upgrades[UpgradeType.aero] ?? 0;
    final nitro = upgrades[UpgradeType.nitro] ?? 0;
    final elec = upgrades[UpgradeType.electronics] ?? 0;

    // Apply upgrade scaling
    final power = v.enginePower * (1 + eng * 0.10); // +10% per level
    final mass = v.weight * (1 - wgt * 0.06); // -6% per level
    final dragC = v.drag * (1 - aero * 0.08); // -8% per level
    final grip = (v.grip + tire * 0.04).clamp(0.0, 1.0); // +0.04 per level

    final rawTop = power / (mass * dragC);
    // Normalize to a believable km/h range (110 .. 430)
    final topSpeed = (110 + rawTop * 4200).clamp(110.0, 430.0);

    final rawAccel = power / mass;
    final acceleration = (rawAccel * 1.6).clamp(0.0, 1.0);

    final handling = (grip * (1100 / mass)).clamp(0.0, 1.0);
    final nitroPower = (0.35 + nitro * 0.13).clamp(0.0, 1.0);
    final stability = (0.25 + elec * 0.15).clamp(0.0, 1.0);

    return VehicleStats(
      topSpeed: topSpeed.toDouble(),
      acceleration: acceleration.toDouble(),
      handling: handling.toDouble(),
      nitroPower: nitroPower.toDouble(),
      stability: stability.toDouble(),
    );
  }
}

/// Cost to upgrade a category from its current level to the next.
int upgradeCost(VehicleClass vClass, int currentLevel) {
  final classFactor = (vClass.index + 1);
  return (250 * classFactor * (currentLevel + 1) * 1.6).round();
}

/// Vehicle Mastery (Phase D) — levels 1..50 earned by racing each car.
class Mastery {
  static const int maxLevel = 50;

  /// XP needed to advance from [level] to level+1 (rising curve).
  static int xpForLevel(int level) => 100 + level * 60;

  /// Returns (level, xpIntoLevel, xpForNext) for a given total XP.
  static (int, int, int) resolve(int totalXp) {
    int level = 1;
    int remaining = totalXp;
    while (level < maxLevel) {
      final need = xpForLevel(level);
      if (remaining < need) break;
      remaining -= need;
      level++;
    }
    final next = level >= maxLevel ? 0 : xpForLevel(level);
    return (level, remaining, next);
  }

  /// Cash bonus multiplier from mastery level (up to +25% at L50).
  static double cashBonus(int level) => 1.0 + (level - 1) / (maxLevel - 1) * 0.25;
}
