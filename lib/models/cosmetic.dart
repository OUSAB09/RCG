import 'package:flutter/material.dart';

/// Paint / livery cosmetics (Phase I). Applied to the selected vehicle as a
/// body color override. Neon trails are represented via a glow accent color.
class PaintColor {
  final String id;
  final String name;
  final Color color;
  final int price; // cash; 0 = free/default
  final bool premium; // costs gems instead
  final bool exclusive; // earned via events, not purchasable in the shop

  const PaintColor({
    required this.id,
    required this.name,
    required this.color,
    required this.price,
    this.premium = false,
    this.exclusive = false,
  });
}

const PaintColor kDefaultPaint =
    PaintColor(id: 'default', name: 'Factory', color: Color(0x00000000), price: 0);

const List<PaintColor> kPaints = [
  kDefaultPaint,
  PaintColor(id: 'crimson', name: 'Crimson', color: Color(0xFFE63946), price: 3000),
  PaintColor(id: 'electric', name: 'Electric Blue', color: Color(0xFF2D6BFF), price: 3000),
  PaintColor(id: 'toxic', name: 'Toxic Green', color: Color(0xFF6CFF3D), price: 4500),
  PaintColor(id: 'sunset', name: 'Sunset Orange', color: Color(0xFFFF7A1A), price: 4500),
  PaintColor(id: 'violet', name: 'Violet Haze', color: Color(0xFF9B2DFF), price: 6000),
  PaintColor(id: 'gold', name: 'Champagne Gold', color: Color(0xFFFFD23D), price: 12000),
  PaintColor(id: 'chrome', name: 'Chrome Silver', color: Color(0xFFD8DCE6), price: 12000),
  PaintColor(id: 'midnight', name: 'Midnight Black', color: Color(0xFF1A1A24), price: 8000),
  PaintColor(id: 'aurora', name: 'Aurora', color: Color(0xFF22E0C0), price: 25, premium: true),
  PaintColor(id: 'inferno', name: 'Inferno', color: Color(0xFFFF2D5B), price: 25, premium: true),
  // Season-exclusive paints (earned on the seasonal event track).
  PaintColor(id: 'season_neon', name: 'Neon Pulse', color: Color(0xFFFF2DCB), price: 0, exclusive: true),
  PaintColor(id: 'season_sand', name: 'Sandstorm', color: Color(0xFFE6B347), price: 0, exclusive: true),
  PaintColor(id: 'season_aqua', name: 'Tidal', color: Color(0xFF1FE0E0), price: 0, exclusive: true),
];

PaintColor paintById(String id) =>
    kPaints.firstWhere((p) => p.id == id, orElse: () => kDefaultPaint);
