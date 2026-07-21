import 'dart:math' as math;

enum DamageSourceKind {
  lightning,
  earthquake,
  giantArrow,
  fireball,
  flameFlinger,
  balloonDeath,
  rocketBalloonDeath,
}

class DamageLevel {
  const DamageLevel({
    required this.level,
    required this.requiredTownHall,
    this.damage,
    this.earthquakePercent,
  });

  final int level;
  final int requiredTownHall;
  final double? damage;
  final double? earthquakePercent;
}

class DamageSourceDefinition {
  const DamageSourceDefinition({
    required this.kind,
    required this.name,
    required this.imageUrl,
    required this.levels,
    this.housingSpace = 0,
  });

  final DamageSourceKind kind;
  final String name;
  final String imageUrl;
  final List<DamageLevel> levels;
  final int housingSpace;

  List<DamageLevel> levelsForTownHall(int townHall) => levels
      .where((level) => level.requiredTownHall <= townHall)
      .toList(growable: false);

  DamageLevel? level(int value) {
    for (final candidate in levels) {
      if (candidate.level == value) return candidate;
    }
    return null;
  }
}

class BuildingLevelDefinition {
  const BuildingLevelDefinition({
    required this.level,
    required this.hitpoints,
    required this.requiredTownHall,
  });

  final int level;
  final int hitpoints;
  final int requiredTownHall;
}

class BuildingDefinition {
  const BuildingDefinition({
    required this.id,
    required this.name,
    required this.imageName,
    required this.levels,
    required this.zapQuakeEligible,
  });

  final String id;
  final String name;
  final String imageName;
  final List<BuildingLevelDefinition> levels;
  final bool zapQuakeEligible;

  List<BuildingLevelDefinition> levelsForTownHall(int townHall) => levels
      .where((level) => level.requiredTownHall <= townHall)
      .toList(growable: false);

  BuildingLevelDefinition? level(int value) {
    for (final candidate in levels) {
      if (candidate.level == value) return candidate;
    }
    return null;
  }
}

class DamageTarget {
  const DamageTarget({required this.building, required this.level});

  final BuildingDefinition building;
  final BuildingLevelDefinition level;

  String get id => building.id;
  int get hitpoints => level.hitpoints;
}

class DamageStackEntry {
  const DamageStackEntry({
    required this.source,
    required this.level,
    required this.count,
  });

  final DamageSourceDefinition source;
  final DamageLevel level;
  final int count;
}

class DamageResult {
  const DamageResult({
    required this.target,
    required this.totalDamage,
    required this.remainingHitpoints,
  });

  final DamageTarget target;
  final double totalDamage;
  final double remainingHitpoints;

  bool get destroyed => remainingHitpoints <= 0;
  double get percentDestroyed => target.hitpoints <= 0
      ? 0
      : math.min(100, totalDamage / target.hitpoints * 100);
}

class ZapQuakeCombination {
  const ZapQuakeCombination({
    required this.lightningCount,
    required this.earthquakeCount,
    required this.capacityUsed,
    required this.damage,
  });

  final int lightningCount;
  final int earthquakeCount;
  final int capacityUsed;
  final double damage;
}

class DamageCalculatorEngine {
  const DamageCalculatorEngine();

  /// Buildings take the full first Earthquake percentage. Each later spell
  /// deals 1/3, 1/5, 1/7, ... of that base percentage.
  double earthquakeDamage({
    required int hitpoints,
    required double basePercent,
    required int count,
  }) {
    if (hitpoints <= 0 || basePercent <= 0 || count <= 0) return 0;
    var total = 0.0;
    for (var index = 0; index < count; index++) {
      total += hitpoints * (basePercent / 100) / (index * 2 + 1);
    }
    return math.min(hitpoints.toDouble(), total);
  }

  DamageResult evaluate(DamageTarget target, Iterable<DamageStackEntry> stack) {
    var total = 0.0;
    for (final entry in stack) {
      if (entry.count <= 0) continue;
      if (!target.building.zapQuakeEligible &&
          (entry.source.kind == DamageSourceKind.lightning ||
              entry.source.kind == DamageSourceKind.earthquake)) {
        continue;
      }
      if (entry.source.kind == DamageSourceKind.earthquake) {
        total += earthquakeDamage(
          hitpoints: target.hitpoints,
          basePercent: entry.level.earthquakePercent ?? 0,
          count: entry.count,
        );
      } else {
        total += (entry.level.damage ?? 0) * entry.count;
      }
    }
    final applied = math.min(target.hitpoints.toDouble(), total);
    return DamageResult(
      target: target,
      totalDamage: applied,
      remainingHitpoints: math.max(0, target.hitpoints - total),
    );
  }

  List<DamageResult> evaluateAll(
    Iterable<DamageTarget> targets,
    Iterable<DamageStackEntry> stack,
  ) => targets.map((target) => evaluate(target, stack)).toList(growable: false);

  List<ZapQuakeCombination> validZapQuakeCombinations({
    required DamageTarget target,
    required DamageLevel lightning,
    required DamageLevel earthquake,
    required int capacity,
  }) {
    if (!target.building.zapQuakeEligible ||
        capacity <= 0 ||
        (lightning.damage ?? 0) <= 0 ||
        (earthquake.earthquakePercent ?? 0) <= 0) {
      return const [];
    }

    final combinations = <ZapQuakeCombination>[];
    for (var earthquakes = 0; earthquakes < capacity; earthquakes++) {
      for (
        var lightningCount = 1;
        lightningCount + earthquakes <= capacity;
        lightningCount++
      ) {
        final quakeDamage = earthquakeDamage(
          hitpoints: target.hitpoints,
          basePercent: earthquake.earthquakePercent!,
          count: earthquakes,
        );
        final damage = quakeDamage + lightning.damage! * lightningCount;
        if (damage + 0.000001 < target.hitpoints) continue;
        combinations.add(
          ZapQuakeCombination(
            lightningCount: lightningCount,
            earthquakeCount: earthquakes,
            capacityUsed: lightningCount + earthquakes,
            damage: damage,
          ),
        );
        // More lightning with the same Earthquake count is always dominated.
        break;
      }
    }

    combinations.sort((a, b) {
      final capacityOrder = a.capacityUsed.compareTo(b.capacityUsed);
      if (capacityOrder != 0) return capacityOrder;
      return a.earthquakeCount.compareTo(b.earthquakeCount);
    });
    return combinations;
  }
}
