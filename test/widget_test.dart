import 'package:flutter_test/flutter_test.dart';

import 'package:apex_rush/state/game_state.dart';
import 'package:apex_rush/data/vehicle_catalog.dart';
import 'package:apex_rush/models/vehicle.dart';
import 'package:apex_rush/models/season.dart';

void main() {
  test('Starter vehicle is owned and physics resolves sane stats', () {
    final gs = GameState();
    expect(gs.owns(VehicleCatalog.all.first.id), isTrue);

    final stats = gs.statsFor(gs.selectedVehicleId);
    expect(stats.topSpeed, greaterThan(100));
    expect(stats.topSpeed, lessThanOrEqualTo(430));
    expect(stats.acceleration, inInclusiveRange(0, 1));
    expect(stats.handling, inInclusiveRange(0, 1));
  });

  test('Hypercar is faster than economy car', () {
    final gs = GameState();
    final eco = gs.statsFor('eco_pebble');
    final hyper = VehicleStats.resolve(
      VehicleCatalog.byId('hyper_apex'),
      {for (final t in UpgradeType.values) t: 0},
    );
    expect(hyper.topSpeed, greaterThan(eco.topSpeed));
  });

  test('Season rotation is deterministic and has an ascending reward track', () {
    final a = seasonForWeek(0);
    final b = seasonForWeek(0);
    expect(a.id, b.id); // deterministic for a given week

    // Tier point requirements must strictly increase.
    for (var i = 1; i < a.tiers.length; i++) {
      expect(a.tiers[i].points, greaterThan(a.tiers[i - 1].points));
    }
    // Final tier should grant an exclusive paint.
    expect(a.tiers.last.paintId, isNotNull);
  });
}
