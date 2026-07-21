import 'package:clashkingapp/features/damage_calculator/data/damage_catalog.dart';
import 'package:clashkingapp/features/damage_calculator/domain/damage_calculator_engine.dart';

class DamageAccountPreset {
  const DamageAccountPreset({
    required this.tag,
    required this.name,
    required this.townHall,
    this.ownedLevels = const {},
  });

  final String tag;
  final String name;
  final int townHall;
  final Map<DamageSourceKind, int> ownedLevels;
}

class SelectedBuilding {
  const SelectedBuilding({required this.buildingId, required this.level});

  final String buildingId;
  final int level;

  SelectedBuilding copyWith({int? level}) =>
      SelectedBuilding(buildingId: buildingId, level: level ?? this.level);
}

class SelectedDamageSource {
  const SelectedDamageSource({
    required this.kind,
    required this.level,
    required this.count,
  });

  final DamageSourceKind kind;
  final int level;
  final int count;

  SelectedDamageSource copyWith({int? level, int? count}) =>
      SelectedDamageSource(
        kind: kind,
        level: level ?? this.level,
        count: count ?? this.count,
      );
}

class DamageCalculatorSession {
  DamageCalculatorSession(this.catalog, {int? townHall})
    : townHall = (townHall ?? catalog.maxTownHall).clamp(
        1,
        catalog.maxTownHall,
      ) {
    _seedDefaults();
  }

  final DamageCatalog catalog;
  int townHall;
  int spellCapacity = 11;
  String? selectedAccountTag;
  final List<SelectedBuilding> targets = [];
  final Map<DamageSourceKind, SelectedDamageSource> sources = {};

  List<BuildingDefinition> get availableBuildings =>
      catalog.buildingsForTownHall(townHall);

  List<DamageSourceDefinition> get availableSources => catalog.sources
      .where((source) => source.levelsForTownHall(townHall).isNotEmpty)
      .toList(growable: false);

  void setTownHall(int value) {
    townHall = value.clamp(1, catalog.maxTownHall);
    _repairTargets();
    _repairSources();
  }

  bool addTarget(String buildingId) {
    if (targets.any((target) => target.buildingId == buildingId)) return false;
    final building = _building(buildingId);
    if (building == null) return false;
    final levels = building.levelsForTownHall(townHall);
    if (levels.isEmpty) return false;
    targets.add(
      SelectedBuilding(buildingId: buildingId, level: levels.last.level),
    );
    return true;
  }

  void removeTarget(String buildingId) {
    targets.removeWhere((target) => target.buildingId == buildingId);
  }

  void setTargetLevel(String buildingId, int level) {
    final building = _building(buildingId);
    if (building == null) return;
    final valid = building.levelsForTownHall(townHall);
    if (!valid.any((candidate) => candidate.level == level)) return;
    final index = targets.indexWhere(
      (target) => target.buildingId == buildingId,
    );
    if (index >= 0) targets[index] = targets[index].copyWith(level: level);
  }

  void setSourceLevel(DamageSourceKind kind, int level) {
    final definition = catalog.source(kind);
    if (definition == null) return;
    final valid = definition.levelsForTownHall(townHall);
    if (!valid.any((candidate) => candidate.level == level)) return;
    final current = sources[kind];
    sources[kind] = SelectedDamageSource(
      kind: kind,
      level: level,
      count: current?.count ?? 0,
    );
  }

  void setSourceCount(DamageSourceKind kind, int count) {
    final current = sources[kind];
    if (current == null) return;
    sources[kind] = current.copyWith(count: count.clamp(0, 99));
  }

  void setSpellCapacity(int value) {
    spellCapacity = value.clamp(1, 20);
  }

  void applyPreset(DamageAccountPreset preset) {
    selectedAccountTag = preset.tag;
    setTownHall(preset.townHall);
    for (final entry in preset.ownedLevels.entries) {
      final definition = catalog.source(entry.key);
      if (definition == null) continue;
      final valid = definition.levelsForTownHall(townHall);
      if (valid.isEmpty) continue;
      final chosen = valid.lastWhere(
        (level) => level.level <= entry.value,
        orElse: () => valid.first,
      );
      setSourceLevel(entry.key, chosen.level);
    }
  }

  List<DamageTarget> resolvedTargets() {
    final resolved = <DamageTarget>[];
    for (final selected in targets) {
      final building = _building(selected.buildingId);
      final level = building?.level(selected.level);
      if (building != null && level != null) {
        resolved.add(DamageTarget(building: building, level: level));
      }
    }
    return resolved;
  }

  List<DamageStackEntry> resolvedStack() {
    final resolved = <DamageStackEntry>[];
    for (final selected in sources.values) {
      final source = catalog.source(selected.kind);
      final level = source?.level(selected.level);
      if (source != null && level != null && selected.count > 0) {
        resolved.add(
          DamageStackEntry(source: source, level: level, count: selected.count),
        );
      }
    }
    return resolved;
  }

  void _seedDefaults() {
    _repairSources();
    final townHallBuilding = catalog.buildings
        .where((building) => building.name == 'Town Hall')
        .firstOrNull;
    if (townHallBuilding != null) addTarget(townHallBuilding.id);
  }

  void _repairTargets() {
    for (var index = targets.length - 1; index >= 0; index--) {
      final selected = targets[index];
      final building = _building(selected.buildingId);
      final valid = building?.levelsForTownHall(townHall) ?? const [];
      if (valid.isEmpty) {
        targets.removeAt(index);
        continue;
      }
      if (!valid.any((level) => level.level == selected.level)) {
        targets[index] = selected.copyWith(level: valid.last.level);
      }
    }
  }

  void _repairSources() {
    final validKinds = <DamageSourceKind>{};
    for (final source in catalog.sources) {
      final valid = source.levelsForTownHall(townHall);
      if (valid.isEmpty) continue;
      validKinds.add(source.kind);
      final current = sources[source.kind];
      final currentValid =
          current != null && valid.any((level) => level.level == current.level);
      sources[source.kind] = SelectedDamageSource(
        kind: source.kind,
        level: currentValid ? current.level : valid.last.level,
        count: current?.count ?? 0,
      );
    }
    sources.removeWhere((kind, _) => !validKinds.contains(kind));
  }

  BuildingDefinition? _building(String id) {
    for (final building in catalog.buildings) {
      if (building.id == id) return building;
    }
    return null;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
