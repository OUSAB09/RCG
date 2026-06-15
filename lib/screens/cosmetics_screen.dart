import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/cosmetic.dart';
import '../state/game_state.dart';
import '../widgets/common.dart';
import '../widgets/car_preview.dart';

class CosmeticsScreen extends StatefulWidget {
  const CosmeticsScreen({super.key});

  @override
  State<CosmeticsScreen> createState() => _CosmeticsScreenState();
}

class _CosmeticsScreenState extends State<CosmeticsScreen> {
  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final vehicleId = gs.selectedVehicleId;
    final vehicle = gs.selectedVehicle;
    final appliedId = gs.appliedPaint[vehicleId] ?? kDefaultPaint.id;
    final previewColor = gs.displayColor(vehicleId);

    return Scaffold(
      appBar: AppBar(
        title: Text('PAINT SHOP', style: AppTheme.display(18)),
        leading: const BackButton(color: AppColors.textPrimary),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Row(children: [
                CurrencyChip(
                    icon: Icons.payments_rounded,
                    value: fmtCash(gs.cash),
                    color: AppColors.neonGreen),
                const SizedBox(width: 6),
                CurrencyChip(
                    icon: Icons.diamond_rounded,
                    value: '${gs.gems}',
                    color: AppColors.neonCyan),
              ]),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Preview
              Container(
                height: 180,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: RadialGradient(colors: [
                    previewColor.withValues(alpha: 0.25),
                    AppColors.bgElevated,
                  ]),
                  border: Border.all(color: previewColor.withValues(alpha: 0.4)),
                ),
                child: Center(child: CarPreview(color: previewColor, width: 72, height: 134)),
              ),
              Text('${vehicle.name}  •  Customizing',
                  style: AppTheme.body(14, color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: kPaints.length,
                  itemBuilder: (context, i) {
                    final p = kPaints[i];
                    final owned = gs.ownsPaint(p.id);
                    final applied = appliedId == p.id;
                    final swatch = p.id == kDefaultPaint.id ? vehicle.bodyColor : p.color;
                    return GestureDetector(
                      onTap: () => _onTap(gs, p, owned, vehicleId),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: applied ? AppColors.neonCyan : Colors.white12,
                            width: applied ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: swatch,
                                border: Border.all(color: Colors.white24),
                                boxShadow: [
                                  BoxShadow(color: swatch.withValues(alpha: 0.5), blurRadius: 10),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(p.name,
                                textAlign: TextAlign.center,
                                style: AppTheme.body(11, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            _tag(gs, p, owned, applied),
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
    );
  }

  Widget _tag(GameState gs, PaintColor p, bool owned, bool applied) {
    if (applied) {
      return Text('APPLIED',
          style: AppTheme.body(10, color: AppColors.neonCyan, weight: FontWeight.w800));
    }
    if (owned) {
      return Text('TAP TO APPLY',
          style: AppTheme.body(10, color: AppColors.neonGreen, weight: FontWeight.w700));
    }
    if (p.premium) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.diamond_rounded, size: 11, color: AppColors.neonCyan),
        const SizedBox(width: 2),
        Text('${p.price}', style: AppTheme.body(11, color: AppColors.neonCyan, weight: FontWeight.w800)),
      ]);
    }
    return Text('\$${fmtCash(p.price)}',
        style: AppTheme.body(11, color: AppColors.neonYellow, weight: FontWeight.w800));
  }

  void _onTap(GameState gs, PaintColor p, bool owned, String vehicleId) {
    if (owned) {
      gs.applyPaint(vehicleId, p.id);
      return;
    }
    final ok = gs.buyPaint(p);
    if (ok) {
      gs.applyPaint(vehicleId, p.id);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.card,
        content: Text('${p.name} unlocked & applied!',
            style: AppTheme.body(15, color: AppColors.neonGreen)),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.card,
        content: Text(p.premium ? 'Not enough gems' : 'Not enough cash',
            style: AppTheme.body(15, color: AppColors.neonMagenta)),
      ));
    }
  }
}
