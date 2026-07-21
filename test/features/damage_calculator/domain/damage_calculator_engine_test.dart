import 'package:clashkingapp/features/damage_calculator/domain/damage_calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = DamageCalculatorEngine();
  const lightning = DamageSourceDefinition(
    kind: DamageSourceKind.lightning,
    name: 'Lightning Spell',
    imageUrl: '',
    housingSpace: 1,
    levels: [DamageLevel(level: 7, requiredTownHall: 10, damage: 400)],
  );
  group('source damage', () {
    test('adds fixed source counts', () {
      final result = engine.evaluate(_target(hitpoints: 2000), const [
        DamageStackEntry(source: lightning, level: lightningLevel, count: 3),
      ]);

      expect(result.totalDamage, 1200);
      expect(result.remainingHitpoints, 800);
      expect(result.destroyed, isFalse);
    });

    test('ignores zero and negative counts', () {
      final target = _target(hitpoints: 1000);
      for (final count in [0, -1]) {
        final result = engine.evaluate(target, [
          DamageStackEntry(
            source: lightning,
            level: lightningLevel,
            count: count,
          ),
        ]);
        expect(result.totalDamage, 0);
        expect(result.remainingHitpoints, 1000);
      }
    });
  });

  group('earthquake stacking', () {
    test('uses the odd-denominator diminishing sequence', () {
      final damage = engine.earthquakeDamage(
        hitpoints: 1000,
        basePercent: 29,
        count: 4,
      );

      expect(damage, closeTo(486.095, 0.001));
    });

    test('caps damage at target HP and handles boundaries', () {
      expect(
        engine.earthquakeDamage(hitpoints: 1000, basePercent: 0, count: 4),
        0,
      );
      expect(
        engine.earthquakeDamage(hitpoints: 0, basePercent: 29, count: 4),
        0,
      );
      expect(
        engine.earthquakeDamage(hitpoints: 100, basePercent: 100, count: 2),
        100,
      );
    });
  });

  group('Zap Quake optimizer', () {
    test('returns only destructive combinations within capacity', () {
      final combinations = engine.validZapQuakeCombinations(
        target: _target(hitpoints: 1000),
        lightning: lightningLevel,
        earthquake: earthquakeLevel,
        capacity: 3,
      );

      expect(combinations, hasLength(2));
      expect(
        combinations.map(
          (combo) =>
              (combo.lightningCount, combo.earthquakeCount, combo.capacityUsed),
        ),
        [(3, 0, 3), (2, 1, 3)],
      );
      expect(
        combinations.every(
          (combo) => combo.capacityUsed <= 3 && combo.damage >= 1000,
        ),
        isTrue,
      );
    });

    test('rejects ineligible storage targets', () {
      final combinations = engine.validZapQuakeCombinations(
        target: _target(hitpoints: 1000, eligible: false),
        lightning: lightningLevel,
        earthquake: earthquakeLevel,
        capacity: 20,
      );

      expect(combinations, isEmpty);
    });
  });

  test('evaluates multiple buildings independently', () {
    final results = engine.evaluateAll(
      [_target(hitpoints: 1000), _target(hitpoints: 2000)],
      const [
        DamageStackEntry(source: lightning, level: lightningLevel, count: 3),
      ],
    );

    expect(results[0].destroyed, isTrue);
    expect(results[0].remainingHitpoints, 0);
    expect(results[1].destroyed, isFalse);
    expect(results[1].remainingHitpoints, 800);
  });

  test('spells do not damage ineligible storage targets', () {
    final result = engine.evaluate(
      _target(hitpoints: 1000, eligible: false),
      const [
        DamageStackEntry(source: lightning, level: lightningLevel, count: 3),
      ],
    );

    expect(result.totalDamage, 0);
    expect(result.remainingHitpoints, 1000);
  });
}

const lightningLevel = DamageLevel(level: 7, requiredTownHall: 10, damage: 400);
const earthquakeLevel = DamageLevel(
  level: 5,
  requiredTownHall: 11,
  earthquakePercent: 29,
);

DamageTarget _target({required int hitpoints, bool eligible = true}) {
  final level = BuildingLevelDefinition(
    level: 1,
    hitpoints: hitpoints,
    requiredTownHall: 1,
  );
  return DamageTarget(
    building: BuildingDefinition(
      id: 'building-$hitpoints-$eligible',
      name: 'Building',
      imageName: 'Building',
      levels: [level],
      zapQuakeEligible: eligible,
    ),
    level: level,
  );
}
