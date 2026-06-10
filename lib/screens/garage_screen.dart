import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../data/vehicle_catalog.dart';
import '../models/vehicle.dart';
import '../state/game_state.dart';
import '../widgets/common.dart';
import '../widgets/car_preview.dart';

class GarageScreen extends StatefulWidget {
  const GarageScreen({super.key});

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  late String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = context.read<GameState>().selectedVehicleId;
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final owned =
        VehicleCatalog.all.where((v) => gs.owns(v.id)).toList();
    final vehicle = VehicleCatalog.byId(_viewId);
    final stats = gs.statsFor(_viewId);
    final isOwned = gs.owns(_viewId);
    final isSelected = gs.selectedVehicleId == _viewId;

    return Scaffold(
      appBar: AppBar(
        title: Text('GARAGE', style: AppTheme.display(20)),
        leading: const BackButton(color: AppColors.textPrimary),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: CurrencyChip(
                  icon: Icons.payments_rounded,
                  value: fmtCash(gs.cash),
                  color: AppColors.neonGreen),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Big preview
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: RadialGradient(colors: [
                      vehicle.vClass.color.withValues(alpha: 0.2),
                      AppColors.bgElevated,
                    ]),
                    border: Border.all(color: vehicle.vClass.color.withValues(alpha: 0.4)),
                  ),
                  child: Center(child: CarPreview(color: vehicle.bodyColor, width: 80, height: 150)),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(vehicle.name, style: AppTheme.display(22)),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: vehicle.vClass.color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(vehicle.vClass.label.toUpperCase(),
                          style: AppTheme.body(12, color: vehicle.vClass.color, weight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Stats
                NeonCard(
                  glow: AppColors.neonCyan,
                  child: Column(
                    children: [
                      StatBar(
                          label: 'Top Speed',
                          value: (stats.topSpeed - 100) / 330,
                          color: AppColors.neonCyan,
                          icon: Icons.speed_rounded),
                      StatBar(
                          label: 'Acceleration',
                          value: stats.acceleration,
                          color: AppColors.neonOrange,
                          icon: Icons.rocket_launch_rounded),
                      StatBar(
                          label: 'Handling',
                          value: stats.handling,
                          color: AppColors.neonGreen,
                          icon: Icons.sync_alt_rounded),
                      const SizedBox(height: 4),
                      Text('Top speed ${stats.topSpeed.toInt()} km/h',
                          style: AppTheme.body(13, color: AppColors.textDim)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Upgrades (only for owned)
                if (isOwned) _upgradesSection(gs, vehicle),
                const SizedBox(height: 14),

                // Select button
                if (isOwned)
                  NeonButton(
                    label: isSelected ? 'SELECTED' : 'SELECT CAR',
                    icon: isSelected ? Icons.check_rounded : Icons.directions_car_rounded,
                    enabled: !isSelected,
                    gradient: isSelected
                        ? const LinearGradient(colors: [AppColors.neonGreen, AppColors.neonGreen])
                        : AppColors.brandGradient,
                    onTap: () => gs.selectVehicle(_viewId),
                  )
                else
                  NeonButton(
                    label: gs.cash >= vehicle.price
                        ? 'BUY  \$${fmtCash(vehicle.price)}'
                        : 'NEED \$${fmtCash(vehicle.price)}',
                    icon: Icons.lock_open_rounded,
                    enabled: gs.cash >= vehicle.price,
                    gradient: const LinearGradient(colors: [AppColors.neonGreen, AppColors.neonCyan]),
                    onTap: () {
                      if (gs.buyVehicle(vehicle)) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          backgroundColor: AppColors.card,
                          content: Text('${vehicle.name} added to garage!',
                              style: AppTheme.body(15, color: AppColors.neonGreen)),
                        ));
                      }
                    },
                  ),

                const SizedBox(height: 18),

                // Collection list
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('YOUR COLLECTION (${owned.length}/${VehicleCatalog.all.length})',
                      style: AppTheme.body(13, color: AppColors.textSecondary, weight: FontWeight.w700)),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: VehicleCatalog.all.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final v = VehicleCatalog.all[i];
                      final owns = gs.owns(v.id);
                      final sel = _viewId == v.id;
                      return GestureDetector(
                        onTap: () => setState(() => _viewId = v.id),
                        child: Container(
                          width: 78,
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: sel ? AppColors.neonCyan : v.vClass.color.withValues(alpha: 0.3),
                              width: sel ? 2 : 1,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Opacity(
                                opacity: owns ? 1 : 0.35,
                                child: CarPreview(color: v.bodyColor, width: 34, height: 64),
                              ),
                              if (!owns)
                                const Icon(Icons.lock_rounded, color: Colors.white70, size: 22),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _upgradesSection(GameState gs, Vehicle v) {
    return NeonCard(
      glow: AppColors.neonMagenta,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('UPGRADES', style: AppTheme.display(16, color: AppColors.neonMagenta)),
          const SizedBox(height: 8),
          _upgradeRow(gs, v, UpgradeType.engine, 'Engine', Icons.settings_rounded),
          _upgradeRow(gs, v, UpgradeType.tires, 'Tires', Icons.trip_origin_rounded),
          _upgradeRow(gs, v, UpgradeType.weight, 'Weight Reduction', Icons.fitness_center_rounded),
          _upgradeRow(gs, v, UpgradeType.aero, 'Aerodynamics', Icons.air_rounded),
        ],
      ),
    );
  }

  Widget _upgradeRow(GameState gs, Vehicle v, UpgradeType type, String label, IconData icon) {
    final level = gs.upgradeLevel(v.id, type);
    final maxed = level >= VehicleStats.maxUpgradeLevel;
    final cost = maxed ? 0 : upgradeCost(v.vClass, level);
    final canAfford = gs.cash >= cost;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTheme.body(14)),
                const SizedBox(height: 3),
                Row(
                  children: List.generate(VehicleStats.maxUpgradeLevel, (i) {
                    return Container(
                      width: 22,
                      height: 6,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: i < level ? AppColors.neonMagenta : AppColors.bgElevated,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (maxed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.neonGreen.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('MAX',
                  style: AppTheme.body(13, color: AppColors.neonGreen, weight: FontWeight.w800)),
            )
          else
            GestureDetector(
              onTap: canAfford
                  ? () {
                      gs.upgrade(v.id, type);
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: canAfford ? AppColors.neonMagenta.withValues(alpha: 0.2) : AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: canAfford ? AppColors.neonMagenta : AppColors.textDim, width: 1),
                ),
                child: Text('\$${fmtCash(cost)}',
                    style: AppTheme.body(13,
                        color: canAfford ? AppColors.neonMagenta : AppColors.textDim,
                        weight: FontWeight.w800)),
              ),
            ),
        ],
      ),
    );
  }
}
