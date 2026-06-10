import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/vehicle.dart';

/// The full roster of unlockable vehicles, one (or more) per class.
/// Stats tuned so each higher tier feels distinctly faster.
class VehicleCatalog {
  static const List<Vehicle> all = [
    // --- Economy (starter) ---
    Vehicle(
      id: 'eco_pebble',
      name: 'Pebble 1.0',
      vClass: VehicleClass.economy,
      price: 0,
      bodyColor: AppColors.textSecondary,
      enginePower: 0.090,
      weight: 1050,
      drag: 0.34,
      grip: 0.55,
    ),
    // --- Hatchback ---
    Vehicle(
      id: 'hatch_spark',
      name: 'Spark GT',
      vClass: VehicleClass.hatchback,
      price: 4500,
      bodyColor: AppColors.neonGreen,
      enginePower: 0.130,
      weight: 1100,
      drag: 0.32,
      grip: 0.60,
    ),
    // --- Sedan ---
    Vehicle(
      id: 'sedan_aero',
      name: 'Aero Lux',
      vClass: VehicleClass.sedan,
      price: 12000,
      bodyColor: AppColors.neonCyan,
      enginePower: 0.180,
      weight: 1350,
      drag: 0.30,
      grip: 0.63,
    ),
    // --- SUV ---
    Vehicle(
      id: 'suv_titan',
      name: 'Titan X',
      vClass: VehicleClass.suv,
      price: 24000,
      bodyColor: AppColors.neonYellow,
      enginePower: 0.230,
      weight: 1850,
      drag: 0.40,
      grip: 0.66,
    ),
    // --- Muscle ---
    Vehicle(
      id: 'muscle_stallion',
      name: 'Stallion 440',
      vClass: VehicleClass.muscle,
      price: 48000,
      bodyColor: AppColors.neonOrange,
      enginePower: 0.330,
      weight: 1600,
      drag: 0.31,
      grip: 0.64,
    ),
    // --- Sports ---
    Vehicle(
      id: 'sports_viper',
      name: 'Viper RS',
      vClass: VehicleClass.sports,
      price: 92000,
      bodyColor: AppColors.neonMagenta,
      enginePower: 0.420,
      weight: 1300,
      drag: 0.27,
      grip: 0.74,
    ),
    // --- Supercar ---
    Vehicle(
      id: 'super_phantom',
      name: 'Phantom V12',
      vClass: VehicleClass.supercar,
      price: 185000,
      bodyColor: AppColors.neonPurple,
      enginePower: 0.560,
      weight: 1250,
      drag: 0.24,
      grip: 0.82,
    ),
    // --- Hypercar ---
    Vehicle(
      id: 'hyper_apex',
      name: 'Apex One',
      vClass: VehicleClass.hypercar,
      price: 420000,
      bodyColor: Color(0xFFFFFFFF),
      enginePower: 0.720,
      weight: 1150,
      drag: 0.20,
      grip: 0.90,
    ),
  ];

  static Vehicle byId(String id) =>
      all.firstWhere((v) => v.id == id, orElse: () => all.first);
}
