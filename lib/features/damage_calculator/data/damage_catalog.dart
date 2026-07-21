import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/damage_calculator/domain/damage_calculator_engine.dart';

class DamageCatalog {
  const DamageCatalog({
    required this.maxTownHall,
    required this.buildings,
    required this.sources,
  });

  final int maxTownHall;
  final List<BuildingDefinition> buildings;
  final List<DamageSourceDefinition> sources;

  factory DamageCatalog.fromBundle(Map<String, dynamic> bundle) {
    final buildings = _parseBuildings(bundle['buildings']);
    final sources = <DamageSourceDefinition>[
      ...?_spellSource(
        bundle['spells'],
        rawBuildings: bundle['buildings'],
        name: 'Lightning Spell',
        kind: DamageSourceKind.lightning,
      ),
      ...?_earthquakeSource(
        bundle['spells'],
        rawBuildings: bundle['buildings'],
      ),
      ...?_equipmentSource(
        bundle['equipment'],
        name: 'Giant Arrow',
        kind: DamageSourceKind.giantArrow,
      ),
      ...?_equipmentSource(
        bundle['equipment'],
        name: 'Fireball',
        kind: DamageSourceKind.fireball,
      ),
      ...?_flameFlingerSource(bundle['troops']),
      ...?_troopDeathSource(
        bundle['troops'],
        name: 'Balloon',
        kind: DamageSourceKind.balloonDeath,
      ),
      ...?_troopDeathSource(
        bundle['troops'],
        name: 'Rocket Balloon',
        kind: DamageSourceKind.rocketBalloonDeath,
      ),
    ];
    final maxTownHall = buildings
        .expand((building) => building.levels)
        .fold(
          1,
          (max, level) =>
              level.requiredTownHall > max ? level.requiredTownHall : max,
        );
    return DamageCatalog(
      maxTownHall: maxTownHall,
      buildings: buildings,
      sources: sources,
    );
  }

  DamageSourceDefinition? source(DamageSourceKind kind) {
    for (final source in sources) {
      if (source.kind == kind) return source;
    }
    return null;
  }

  List<BuildingDefinition> buildingsForTownHall(int townHall) => buildings
      .where((building) => building.levelsForTownHall(townHall).isNotEmpty)
      .toList(growable: false);
}

List<BuildingDefinition> _parseBuildings(dynamic rawBuildings) {
  if (rawBuildings is! List) return const [];
  final buildings = <BuildingDefinition>[];
  for (final raw in rawBuildings) {
    if (raw is! Map || raw['village'] != 'home') continue;
    final name = raw['name']?.toString().trim() ?? '';
    if (name.isEmpty) continue;
    final levels = _levels(raw['levels'], (level) {
      final levelNumber = _int(level['level']);
      final hitpoints = _int(level['hitpoints']);
      if (hitpoints <= 0) return null;
      return BuildingLevelDefinition(
        level: levelNumber,
        hitpoints: hitpoints,
        requiredTownHall: name == 'Town Hall'
            ? levelNumber
            : _int(level['required_townhall'], fallback: 1),
      );
    });
    if (levels.isEmpty) continue;
    final id = raw['_id']?.toString() ?? name;
    final lowerName = name.toLowerCase();
    buildings.add(
      BuildingDefinition(
        id: id,
        name: name,
        imageName: name,
        levels: levels,
        zapQuakeEligible: !lowerName.contains('storage'),
      ),
    );
  }
  buildings.sort((a, b) {
    if (a.name == 'Town Hall') return -1;
    if (b.name == 'Town Hall') return 1;
    return a.name.compareTo(b.name);
  });
  return buildings;
}

List<DamageSourceDefinition>? _spellSource(
  dynamic rawSources, {
  required dynamic rawBuildings,
  required String name,
  required DamageSourceKind kind,
}) {
  final source = _findNamed(rawSources, name);
  if (source == null) return null;
  final levels = _levels(source['levels'], (raw) {
    final damage = _double(raw['damage']);
    if (damage <= 0) return null;
    return DamageLevel(
      level: _int(raw['level']),
      requiredTownHall: _sourceRequiredTownHall(raw, source, rawBuildings),
      damage: damage,
    );
  });
  if (levels.isEmpty) return null;
  return [
    DamageSourceDefinition(
      kind: kind,
      name: name,
      imageUrl: ImageAssets.getSpellImage(name),
      levels: levels,
      housingSpace: _int(source['housing_space'], fallback: 1),
    ),
  ];
}

List<DamageSourceDefinition>? _earthquakeSource(
  dynamic rawSources, {
  required dynamic rawBuildings,
}) {
  final source = _findNamed(rawSources, 'Earthquake Spell');
  if (source == null) return null;
  const buildingPercent = <int, double>{
    1: 14.5,
    2: 17,
    3: 21,
    4: 25,
    5: 29,
    6: 29,
    7: 29,
    8: 29,
  };
  final levels = _levels(source['levels'], (raw) {
    final level = _int(raw['level']);
    final percent = buildingPercent[level];
    if (percent == null) return null;
    return DamageLevel(
      level: level,
      requiredTownHall: _sourceRequiredTownHall(raw, source, rawBuildings),
      earthquakePercent: percent,
    );
  });
  if (levels.isEmpty) return null;
  return [
    DamageSourceDefinition(
      kind: DamageSourceKind.earthquake,
      name: 'Earthquake Spell',
      imageUrl: ImageAssets.getSpellImage('Earthquake Spell'),
      levels: levels,
      housingSpace: _int(source['housing_space'], fallback: 1),
    ),
  ];
}

List<DamageSourceDefinition>? _equipmentSource(
  dynamic rawSources, {
  required String name,
  required DamageSourceKind kind,
}) {
  final source = _findNamed(rawSources, name);
  if (source == null) return null;
  final levels = _levels(source['levels'], (raw) {
    final abilities = raw['abilities'];
    if (abilities is! List || abilities.isEmpty || abilities.first is! Map) {
      return null;
    }
    final ability = abilities.first as Map;
    final damage = _double(ability['Damage'] ?? ability['damage']);
    if (damage <= 0) return null;
    return DamageLevel(
      level: _int(raw['level']),
      requiredTownHall: _int(raw['required_townhall'], fallback: 1),
      damage: damage,
    );
  });
  if (levels.isEmpty) return null;
  return [
    DamageSourceDefinition(
      kind: kind,
      name: name,
      imageUrl: ImageAssets.getGearImage(name),
      levels: levels,
    ),
  ];
}

List<DamageSourceDefinition>? _flameFlingerSource(dynamic rawSources) {
  final source = _findNamed(rawSources, 'Flame Flinger');
  if (source == null) return null;
  final attackSpeed = _double(source['attack_speed']);
  if (attackSpeed <= 0) return null;
  final levels = _levels(source['levels'], (raw) {
    final dps = _double(raw['dps']);
    if (dps <= 0) return null;
    return DamageLevel(
      level: _int(raw['level']),
      requiredTownHall: _int(raw['required_townhall'], fallback: 1),
      damage: dps * attackSpeed,
    );
  });
  if (levels.isEmpty) return null;
  return [
    DamageSourceDefinition(
      kind: DamageSourceKind.flameFlinger,
      name: 'Flame Flinger hit',
      imageUrl: ImageAssets.getSiegeMachineImage('Flame Flinger'),
      levels: levels,
    ),
  ];
}

List<DamageSourceDefinition>? _troopDeathSource(
  dynamic rawSources, {
  required String name,
  required DamageSourceKind kind,
}) {
  final source = _findNamed(rawSources, name);
  if (source == null) return null;
  final levels = _levels(source['levels'], (raw) {
    final damage = _double(
      raw['death_damage'] ?? raw['deathDamage'] ?? raw['death_damage_on_death'],
    );
    if (damage <= 0) return null;
    return DamageLevel(
      level: _int(raw['level']),
      requiredTownHall: _int(raw['required_townhall'], fallback: 1),
      damage: damage,
    );
  });
  if (levels.isEmpty) return null;
  return [
    DamageSourceDefinition(
      kind: kind,
      name: '$name death damage',
      imageUrl: ImageAssets.getTroopImage(name),
      levels: levels,
    ),
  ];
}

Map<dynamic, dynamic>? _findNamed(dynamic rawSources, String name) {
  if (rawSources is! List) return null;
  for (final raw in rawSources) {
    if (raw is Map && raw['name'] == name) return raw;
  }
  return null;
}

int _sourceRequiredTownHall(Map rawLevel, Map source, dynamic rawBuildings) {
  final levelRequirement = _int(rawLevel['required_townhall'], fallback: 1);
  final productionBuilding = source['production_building']?.toString();
  final productionLevel = _int(source['production_building_level']);
  if (rawBuildings is! List ||
      productionBuilding == null ||
      productionLevel <= 0) {
    return levelRequirement;
  }
  final building = _findNamed(rawBuildings, productionBuilding);
  final rawLevels = building?['levels'];
  if (rawLevels is! List) return levelRequirement;
  for (final raw in rawLevels) {
    if (raw is Map && _int(raw['level']) == productionLevel) {
      final unlock = _int(raw['required_townhall'], fallback: 1);
      return unlock > levelRequirement ? unlock : levelRequirement;
    }
  }
  return levelRequirement;
}

List<T> _levels<T>(dynamic rawLevels, T? Function(Map raw) parse) {
  if (rawLevels is! List) return const [];
  final levels = <T>[];
  for (final raw in rawLevels) {
    if (raw is! Map) continue;
    final value = parse(raw);
    if (value != null) levels.add(value);
  }
  return levels;
}

int _int(Object? value, {int fallback = 0}) => switch (value) {
  final num number => number.round(),
  final String text => int.tryParse(text) ?? fallback,
  _ => fallback,
};

double _double(Object? value) => switch (value) {
  final num number => number.toDouble(),
  final String text => double.tryParse(text) ?? 0,
  _ => 0,
};
