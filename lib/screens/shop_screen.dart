import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../data/vehicle_catalog.dart';
import '../state/game_state.dart';
import '../widgets/common.dart';
import '../widgets/car_preview.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final locked = VehicleCatalog.all.where((v) => !gs.owns(v.id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('CAR SHOP', style: AppTheme.display(20)),
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
          child: locked.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded, size: 64, color: AppColors.neonGreen),
                      const SizedBox(height: 12),
                      Text('GARAGE COMPLETE!',
                          style: AppTheme.display(20, color: AppColors.neonGreen)),
                      const SizedBox(height: 6),
                      Text('You own every vehicle in Apex Rush.',
                          style: AppTheme.body(14, color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: locked.length,
                  itemBuilder: (context, i) {
                    final v = locked[i];
                    final stats = gs.statsFor(v.id);
                    final canAfford = gs.cash >= v.price;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: NeonCard(
                        glow: v.vClass.color,
                        child: Row(
                          children: [
                            Container(
                              width: 70,
                              height: 90,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: RadialGradient(colors: [
                                  v.vClass.color.withValues(alpha: 0.2),
                                  AppColors.bgElevated,
                                ]),
                              ),
                              child: Center(child: CarPreview(color: v.bodyColor, width: 32, height: 60)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(v.name, style: AppTheme.display(17)),
                                  Text(v.vClass.label.toUpperCase(),
                                      style: AppTheme.body(12,
                                          color: v.vClass.color, weight: FontWeight.w700)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      _spec(Icons.speed_rounded, '${stats.topSpeed.toInt()}'),
                                      const SizedBox(width: 12),
                                      _spec(Icons.rocket_launch_rounded,
                                          '${(stats.acceleration * 100).toInt()}'),
                                      const SizedBox(width: 12),
                                      _spec(Icons.sync_alt_rounded,
                                          '${(stats.handling * 100).toInt()}'),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: NeonButton(
                                      height: 42,
                                      label: canAfford
                                          ? 'BUY  \$${fmtCash(v.price)}'
                                          : 'NEED \$${fmtCash(v.price)}',
                                      enabled: canAfford,
                                      gradient: const LinearGradient(
                                          colors: [AppColors.neonGreen, AppColors.neonCyan]),
                                      onTap: () {
                                        if (gs.buyVehicle(v)) {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                            backgroundColor: AppColors.card,
                                            content: Text('${v.name} purchased!',
                                                style: AppTheme.body(15, color: AppColors.neonGreen)),
                                          ));
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _spec(IconData icon, String v) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(v, style: AppTheme.body(13, color: AppColors.textSecondary)),
      ],
    );
  }
}
