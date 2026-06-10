import 'package:flutter/material.dart';
import '../core/theme.dart';

enum Weather {
  clear('Clear', 1.0, 1.0),
  rain('Rain', 0.78, 0.75),
  fog('Fog', 0.92, 0.55);

  const Weather(this.label, this.gripMul, this.visibility);
  final String label;
  final double gripMul; // multiplies handling
  final double visibility; // 0..1, affects how far you can see (fog overlay)
}

/// Track environments from the GDD.
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
  });
}

const List<RaceEnvironment> kEnvironments = [
  RaceEnvironment(
    id: 'city',
    name: 'Neon City',
    skyTop: Color(0xFF1A0E33),
    skyBottom: Color(0xFF3A1B5E),
    roadColor: Color(0xFF20203A),
    laneColor: AppColors.neonCyan,
    sceneryColor: Color(0xFF2B1B47),
    possibleWeather: [Weather.clear, Weather.rain, Weather.fog],
    cashMultiplier: 1.0,
    unlockDistance: 0,
  ),
  RaceEnvironment(
    id: 'desert',
    name: 'Sunset Desert',
    skyTop: Color(0xFF3A1E12),
    skyBottom: Color(0xFFB5532A),
    roadColor: Color(0xFF332016),
    laneColor: AppColors.neonYellow,
    sceneryColor: Color(0xFF5E331C),
    possibleWeather: [Weather.clear, Weather.fog],
    cashMultiplier: 1.4,
    unlockDistance: 4000,
  ),
  RaceEnvironment(
    id: 'coast',
    name: 'Coastal Highway',
    skyTop: Color(0xFF06283D),
    skyBottom: Color(0xFF1B6E8C),
    roadColor: Color(0xFF16252E),
    laneColor: AppColors.neonGreen,
    sceneryColor: Color(0xFF0E3A4A),
    possibleWeather: [Weather.clear, Weather.rain],
    cashMultiplier: 1.8,
    unlockDistance: 9000,
  ),
];
