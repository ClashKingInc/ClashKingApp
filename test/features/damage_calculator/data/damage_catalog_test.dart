import 'package:clashkingapp/features/damage_calculator/data/damage_catalog.dart';
import 'package:clashkingapp/features/damage_calculator/domain/damage_calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses millisecond attack speed and Town Hall constraints', () {
    final catalog = DamageCatalog.fromBundle(_bundle);

    expect(catalog.maxTownHall, 12);
    expect(catalog.buildingsForTownHall(9).map((item) => item.name), [
      'Town Hall',
    ]);
    expect(catalog.buildingsForTownHall(12).map((item) => item.name), [
      'Town Hall',
      'X-Bow',
    ]);
    expect(catalog.buildings.first.levelsForTownHall(9).single.level, 9);
    expect(catalog.buildings.first.level(10)?.upgradeResource, 'Gold');
    expect(catalog.buildings.first.level(10)?.upgradeCost, 250000);
    expect(
      catalog
          .source(DamageSourceKind.lightning)!
          .levelsForTownHall(9)
          .single
          .level,
      1,
    );
    expect(
      catalog.source(DamageSourceKind.fireball)!.levels.single.damage,
      1500,
    );
    expect(
      catalog.source(DamageSourceKind.earthquake)!.levelsForTownHall(7),
      isEmpty,
    );
    expect(
      catalog
          .source(DamageSourceKind.earthquake)!
          .levelsForTownHall(8)
          .single
          .level,
      1,
    );
    expect(
      catalog.source(DamageSourceKind.flameFlinger)!.levels.single.damage,
      635,
    );
  });

  test('only exposes conditional death sources when static damage exists', () {
    final catalog = DamageCatalog.fromBundle(_bundle);

    expect(catalog.source(DamageSourceKind.balloonDeath), isNull);
    expect(catalog.source(DamageSourceKind.rocketBalloonDeath), isNull);
  });

  test('removes buildings consumed by a later Town Hall merge', () {
    const catalog = DamageCatalog(
      maxTownHall: 18,
      buildings: [
        BuildingDefinition(
          id: 'eagle',
          name: 'Eagle Artillery',
          imageName: 'Eagle Artillery',
          zapQuakeEligible: true,
          levels: [
            BuildingLevelDefinition(
              level: 7,
              hitpoints: 6200,
              requiredTownHall: 16,
            ),
          ],
        ),
        BuildingDefinition(
          id: 'x-bow',
          name: 'X-Bow',
          imageName: 'X-Bow',
          zapQuakeEligible: true,
          levels: [
            BuildingLevelDefinition(
              level: 13,
              hitpoints: 5000,
              requiredTownHall: 18,
            ),
          ],
        ),
      ],
      sources: [],
    );

    expect(catalog.buildingsForTownHall(16).map((item) => item.name), [
      'Eagle Artillery',
    ]);
    expect(catalog.buildingsForTownHall(17), isEmpty);
    expect(catalog.buildingsForTownHall(18).map((item) => item.name), [
      'X-Bow',
    ]);
  });
}

final _bundle = <String, dynamic>{
  'buildings': [
    {
      '_id': 1,
      'name': 'Town Hall',
      'village': 'home',
      'upgrade_resource': 'Gold',
      'levels': [
        {'level': 9, 'hitpoints': 4600, 'required_townhall': 9},
        {
          'level': 10,
          'hitpoints': 5500,
          'required_townhall': 10,
          'build_cost': 250000,
        },
        {'level': 12, 'hitpoints': 7000, 'required_townhall': 11},
      ],
    },
    {
      '_id': 2,
      'name': 'X-Bow',
      'village': 'home',
      'levels': [
        {'level': 5, 'hitpoints': 1500, 'required_townhall': 12},
      ],
    },
    {
      '_id': 3,
      'name': 'Dark Spell Factory',
      'village': 'home',
      'levels': [
        {'level': 2, 'required_townhall': 8},
      ],
    },
  ],
  'spells': [
    {
      'name': 'Lightning Spell',
      'housing_space': 1,
      'levels': [
        {'level': 1, 'damage': 150, 'required_townhall': 3},
        {'level': 2, 'damage': 180, 'required_townhall': 10},
      ],
    },
    {
      'name': 'Earthquake Spell',
      'housing_space': 1,
      'production_building': 'Dark Spell Factory',
      'production_building_level': 2,
      'levels': [
        {'level': 1, 'damage': 0, 'required_townhall': 8},
        {'level': 2, 'damage': 0, 'required_townhall': 10},
      ],
    },
  ],
  'equipment': [
    {
      'name': 'Fireball',
      'levels': [
        {
          'level': 1,
          'required_townhall': 8,
          'abilities': [
            {'Damage': 1500},
          ],
        },
      ],
    },
  ],
  'troops': [
    {
      'name': 'Flame Flinger',
      'attack_speed': 5000,
      'levels': [
        {'level': 1, 'dps': 127, 'required_townhall': 11},
      ],
    },
    {
      'name': 'Balloon',
      'levels': [
        {'level': 1, 'dps': 25, 'required_townhall': 3},
      ],
    },
  ],
};
