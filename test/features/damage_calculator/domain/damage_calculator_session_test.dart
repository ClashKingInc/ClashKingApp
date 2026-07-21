import 'package:clashkingapp/features/damage_calculator/data/damage_catalog.dart';
import 'package:clashkingapp/features/damage_calculator/domain/damage_calculator_engine.dart';
import 'package:clashkingapp/features/damage_calculator/domain/damage_calculator_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses max valid levels and repairs invalid state after a TH change', () {
    final session = DamageCalculatorSession(_catalog, townHall: 12);

    expect(session.targets.single.level, 2);
    expect(session.sources[DamageSourceKind.lightning]!.level, 3);

    session.setTownHall(9);

    expect(session.targets.single.level, 1);
    expect(session.sources[DamageSourceKind.lightning]!.level, 1);
  });

  test('account presets apply locally and clamp unsupported owned levels', () {
    final session = DamageCalculatorSession(_catalog, townHall: 12);
    const preset = DamageAccountPreset(
      tag: '#ABC',
      name: 'Chief',
      townHall: 9,
      ownedLevels: {DamageSourceKind.lightning: 99},
    );

    session.applyPreset(preset);

    expect(session.selectedAccountTag, '#ABC');
    expect(session.townHall, 9);
    expect(session.sources[DamageSourceKind.lightning]!.level, 1);
  });

  test('rejects duplicate and invalid building selections', () {
    final session = DamageCalculatorSession(_catalog, townHall: 9);

    expect(session.addTarget('town-hall'), isFalse);
    expect(session.addTarget('locked'), isFalse);
    expect(session.targets, hasLength(1));
  });
}

const _catalog = DamageCatalog(
  maxTownHall: 12,
  buildings: [
    BuildingDefinition(
      id: 'town-hall',
      name: 'Town Hall',
      imageName: 'Town Hall',
      zapQuakeEligible: true,
      levels: [
        BuildingLevelDefinition(level: 1, hitpoints: 1000, requiredTownHall: 9),
        BuildingLevelDefinition(
          level: 2,
          hitpoints: 2000,
          requiredTownHall: 12,
        ),
      ],
    ),
    BuildingDefinition(
      id: 'locked',
      name: 'Locked',
      imageName: 'Locked',
      zapQuakeEligible: true,
      levels: [
        BuildingLevelDefinition(
          level: 1,
          hitpoints: 2000,
          requiredTownHall: 12,
        ),
      ],
    ),
  ],
  sources: [
    DamageSourceDefinition(
      kind: DamageSourceKind.lightning,
      name: 'Lightning Spell',
      imageUrl: '',
      levels: [
        DamageLevel(level: 1, requiredTownHall: 3, damage: 150),
        DamageLevel(level: 2, requiredTownHall: 10, damage: 180),
        DamageLevel(level: 3, requiredTownHall: 12, damage: 210),
      ],
    ),
  ],
);
