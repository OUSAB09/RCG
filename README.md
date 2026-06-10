# 🏎️ Apex Rush

A high-speed neon-arcade racing game built with **Flutter** and the **Flame** 2D game engine. Dodge traffic at extreme speeds, earn cash for close-pass overtakes, build combo multipliers, collect and upgrade cars, and climb the leaderboard.

## Gameplay Loop
**Race → Overtake → Earn Cash → Upgrade → Unlock Cars → Compete → Repeat**

## Features
- **Overtake Economy** — Near / Close / Extreme passes reward cash based on how closely you dodge
- **Combo System** — Chain passes within a tight window for up to **8× cash multiplier**
- **Physics-driven vehicles** — Top speed derived dynamically from Engine Power, Weight, Drag & Grip
- **8 Vehicle Classes** — Economy → Hatchback → Sedan → SUV → Muscle → Sports → Supercar → Hypercar
- **Upgrades** — Engine, Tires, Weight Reduction, Aerodynamics (5 levels each)
- **Traffic AI** — 4-lane traffic with varied speed profiles
- **Environments & Weather** — Neon City, Sunset Desert, Coastal Highway with Clear / Rain / Fog
- **Progression** — Cash + Gems economy with local persistence
- **Achievements & Leaderboards**

## Controls
- **Desktop:** ← → arrow keys (or A / D) to steer
- **Mobile:** Touch & drag anywhere to steer

## Tech Stack
- Flutter 3.35.4 / Dart 3.9.2
- Flame (2D game engine)
- Provider (state management)
- shared_preferences (local save)
- google_fonts

## Project Structure
```
lib/
├── core/          # Theme & visual identity
├── data/          # Vehicle catalog
├── models/        # Vehicle physics, achievements, environments
├── state/         # GameState (economy, garage, persistence)
├── game/          # Flame engine + components (road, cars, FX)
├── screens/       # Menu, garage, shop, leaderboard, achievements, game
└── widgets/       # Shared UI components
```

## Running
```bash
flutter pub get
flutter run -d chrome        # web
flutter build apk --release  # android
```
