import 'package:flutter/material.dart';
import '../core/theme.dart';

enum Weather {
  clear('Clear', 1.0, 1.0, Icons.wb_sunny_rounded),
  rain('Rain', 0.78, 0.75, Icons.water_drop_rounded),
  fog('Fog', 0.92, 0.50, Icons.foggy),
  sandstorm('Sandstorm', 0.70, 0.45, Icons.tornado_rounded);

  const Weather(this.label, this.gripMul, this.visibility, this.icon);
  final String label;
  final double gripMul; // multiplies handling
  final double visibility; // 0..1, affects how far you can see (overlay)
  final IconData icon;
}

/// Track environments from the development plan (Phase B): 5 environments.
class RaceEnvironment {
  final String id;
  final String name;
  final Color skyTop;
  final Color skyBottom;
  final Color roadColor;
  final Color laneColor;
  final Color sceneryColor;
  final List<Weather> possibleWeather;
  final double cashMultiplier; // higher tiers reward more
  final int unlockDistance; // best distance needed to unlock (gameplay gate)
  final IconData icon;

  const RaceEnvironment({
    required this.id,
    required this.name,
    required this.skyTop,
    required this.skyBottom,
    required this.roadColor,
    required this.laneColor,
    required this.sceneryColor,
    required this.possibleWeather,
    required this.cashMultiplier,
    required this.unlockDistance,
    required this.icon,
  });
}

const List<RaceEnvironment> kEnvironments = [
  RaceEnvironment(
    id: 'city',
    name: 'City Night',
    skyTop: Color(0xFF1A0E33),
    skyBottom: Color(0xFF3A1B5E),
    roadColor: Color(0xFF20203A),
    laneColor: AppColors.neonCyan,
    sceneryColor: Color(0xFF2B1B47),
    possibleWeather: [Weather.clear, Weather.rain, Weather.fog],
    cashMultiplier: 1.0,
    unlockDistance: 0,
    icon: Icons.location_city_rounded,
  ),
  RaceEnvironment(
    id: 'desert',
    name: 'Desert Highway',
    skyTop: Color(0xFF3A1E12),
    skyBottom: Color(0xFFB5532A),
    roadColor: Color(0xFF332016),
    laneColor: AppColors.neonYellow,
    sceneryColor: Color(0xFF5E331C),
    possibleWeather: [Weather.clear, Weather.fog, Weather.sandstorm],
    cashMultiplier: 1.4,
    unlockDistance: 3000,
    icon: Icons.wb_twilight_rounded,
  ),
  RaceEnvironment(
    id: 'coast',
    name: 'Coastal Route',
    skyTop: Color(0xFF06283D),
    skyBottom: Color(0xFF1B6E8C),
    roadColor: Color(0xFF16252E),
    laneColor: AppColors.neonGreen,
    sceneryColor: Color(0xFF0E3A4A),
    possibleWeather: [Weather.clear, Weather.rain],
    cashMultiplier: 1.8,
    unlockDistance: 6500,
    icon: Icons.beach_access_rounded,
  ),
  RaceEnvironment(
    id: 'mountain',
    name: 'Mountain Pass',
    skyTop: Color(0xFF0E1A2B),
    skyBottom: Color(0xFF3D5A6E),
    roadColor: Color(0xFF1B2630),
    laneColor: AppColors.neonPurple,
    sceneryColor: Color(0xFF223040),
    possibleWeather: [Weather.clear, Weather.fog, Weather.rain],
    cashMultiplier: 2.2,
    unlockDistance: 11000,
    icon: Icons.terrain_rounded,
  ),
  RaceEnvironment(
    id: 'expressway',
    name: 'Rainy Expressway',
    skyTop: Color(0xFF101422),
    skyBottom: Color(0xFF2A3346),
    roadColor: Color(0xFF161A26),
    laneColor: AppColors.neonMagenta,
    sceneryColor: Color(0xFF1E2331),
    possibleWeather: [Weather.rain, Weather.fog],
    cashMultiplier: 2.6,
    unlockDistance: 17000,
    icon: Icons.thunderstorm_rounded,
  ),
];
