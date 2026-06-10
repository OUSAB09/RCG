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

/// Upgrade categories from the GDD progression system.
enum UpgradeType { engine, tires, weight, aero }

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

  const VehicleStats({
    required this.topSpeed,
    required this.acceleration,
    required this.handling,
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

    return VehicleStats(
      topSpeed: topSpeed.toDouble(),
      acceleration: acceleration.toDouble(),
      handling: handling.toDouble(),
    );
  }
}

/// Cost to upgrade a category from its current level to the next.
int upgradeCost(VehicleClass vClass, int currentLevel) {
  final classFactor = (vClass.index + 1);
  return (250 * classFactor * (currentLevel + 1) * 1.6).round();
}
