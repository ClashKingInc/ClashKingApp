import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:clashkingapp/features/player/models/player_item.dart';

typedef PlayerItemFactory<T extends PlayerItem> =
    T Function({
      required String name,
      required int level,
      required int maxLevel,
      required bool isUnlocked,
      Map<String, dynamic>? meta,
      Map<String, dynamic>? rawJson,
    });

List<T> generateCompleteItemList<T extends PlayerItem>({
  required List<dynamic>? jsonList,
  required Map<String, dynamic> gameData,
  required PlayerItemFactory<T> factory,
  bool Function(String itemName, dynamic jsonItem)? nameMatcher,
}) {
  final Map<String, Map<String, dynamic>> allItems = Map.fromEntries(
    gameData.entries.map(
      (e) => MapEntry(e.key, e.value as Map<String, dynamic>),
    ),
  );

  return allItems.entries.map((entry) {
    final key = entry.key;
    final meta = entry.value;
    final name = meta['name']?.toString() ?? key;
    final owned = jsonList?.firstWhere(
      (x) =>
          nameMatcher?.call(key, x) ??
          nameMatcher?.call(name, x) ??
          x['name'] == name,
      orElse: () => null,
    );

    return factory(
      name: name,
      level: owned?['level'] ?? 0,
      maxLevel: owned?['maxLevel'] ?? meta['maxLevel'] ?? 0,
      isUnlocked: owned != null,
      meta: meta,
      rawJson: owned,
    );
  }).toList();
}

Map<String, dynamic> filterGameData(
  Map<String, dynamic>? data,
  bool Function(String key, Map<String, dynamic> value) predicate,
) {
  if (data == null) return {};

  final filteredEntries = <MapEntry<String, dynamic>>[];
  for (final entry in data.entries) {
    final value = entry.value;
    if (value is! Map) {
      continue;
    }

    final typedValue = Map<String, dynamic>.from(value);
    if (typedValue['is_seasonal'] == true) {
      continue;
    }

    if (predicate(entry.key, typedValue)) {
      filteredEntries.add(MapEntry(entry.key, typedValue));
    }
  }

  return Map.fromEntries(filteredEntries);
}

Map<String, dynamic> filterSpellGameData(Map<String, dynamic>? data) {
  return filterGameData(data, (_, _) => true);
}

/// Returns the highest item level unlockable at [thLevel] based on bundle metadata.
/// Returns 0 if the item has no levels or is not available at that TH level.
int maxLevelForTH(
  Map<String, dynamic>? meta,
  int thLevel, {
  int? maxTownHallLevel,
  int? itemMaxLevel,
}) {
  if (meta == null || thLevel <= 0) return 0;
  final levels = meta['levels'];
  if (levels is! List || levels.isEmpty) return 0;
  int maxLevel = 0;
  for (final entry in levels) {
    if (entry is Map) {
      final requiredTH = entry['required_townhall'];
      final level = entry['level'];
      if (requiredTH is num && level is num && requiredTH <= thLevel) {
        if (level > maxLevel) maxLevel = level.toInt();
      }
    }
  }

  final declaredMaxLevel =
      itemMaxLevel ?? (meta['maxLevel'] as num?)?.toInt() ?? 0;
  final effectiveMaxTownHallLevel =
      maxTownHallLevel ?? GameDataService.getMaxTownHallLevel();
  if (effectiveMaxTownHallLevel > 0 &&
      thLevel >= effectiveMaxTownHallLevel &&
      declaredMaxLevel > maxLevel) {
    return declaredMaxLevel;
  }

  return maxLevel;
}

int maxLevelForItemAtTH(PlayerItem item, int thLevel, {int? maxTownHallLevel}) {
  final thMax = maxLevelForTH(
    item.meta,
    thLevel,
    maxTownHallLevel: maxTownHallLevel,
    itemMaxLevel: item.maxLevel,
  );

  if (thMax > 0) return thMax;
  return item.maxLevel;
}

class UpgradeResourceAmount {
  final String key;
  final num amount;

  const UpgradeResourceAmount(this.key, this.amount);
}

class UpgradeRemainingSummary {
  final int targetLevel;
  final int levelsRemaining;
  final int seconds;
  final List<UpgradeResourceAmount> resources;

  const UpgradeRemainingSummary({
    required this.targetLevel,
    required this.levelsRemaining,
    required this.seconds,
    required this.resources,
  });

  bool get isComplete => levelsRemaining <= 0;
}

UpgradeRemainingSummary calculateRemainingUpgradeSummary(
  PlayerItem item, {
  required int targetLevel,
}) {
  final meta = item.meta;
  if (meta == null || targetLevel <= 0 || item.level >= targetLevel) {
    return UpgradeRemainingSummary(
      targetLevel: targetLevel,
      levelsRemaining: 0,
      seconds: 0,
      resources: const [],
    );
  }

  final costs = <String, num>{};
  var totalSeconds = 0;
  final firstUpgradeLevel = item.level <= 0 ? 1 : item.level;
  final levels = meta['levels'];
  final levelStats = <int, Map<String, dynamic>>{
    if (levels is List)
      for (final entry in levels.whereType<Map>())
        if (entry['level'] is num)
          (entry['level'] as num).toInt(): Map<String, dynamic>.from(entry),
  };

  for (var level = firstUpgradeLevel; level < targetLevel; level++) {
    final stats = levelStats[level];
    if (stats == null) continue;

    totalSeconds += (stats['upgrade_time'] as num?)?.toInt() ?? 0;
    final upgradeCost = stats['upgrade_cost'];

    if (upgradeCost is Map) {
      for (final entry in upgradeCost.entries) {
        final amount = entry.value is num ? entry.value as num : 0;
        if (amount <= 0) continue;
        final key = normalizeResource(entry.key.toString());
        costs[key] = (costs[key] ?? 0) + amount;
      }
    } else {
      final amount = upgradeCost is num ? upgradeCost : 0;
      if (amount <= 0) continue;
      final key = normalizeResource(
        meta['upgrade_resource']?.toString() ?? 'resource',
      );
      costs[key] = (costs[key] ?? 0) + amount;
    }
  }

  final resources =
      costs.entries
          .map((entry) => UpgradeResourceAmount(entry.key, entry.value))
          .where((resource) => resource.amount > 0)
          .toList()
        ..sort(
          (a, b) =>
              resourceSortWeight(a.key).compareTo(resourceSortWeight(b.key)),
        );

  return UpgradeRemainingSummary(
    targetLevel: targetLevel,
    levelsRemaining: (targetLevel - item.level).clamp(0, targetLevel),
    seconds: totalSeconds,
    resources: resources,
  );
}

Map<String, dynamic>? findLevelStats(Map<String, dynamic>? meta, int level) {
  if (meta == null) return null;
  final levels = meta['levels'];
  if (levels is! List) return null;
  for (final entry in levels) {
    if (entry is Map && entry['level'] == level) {
      return Map<String, dynamic>.from(entry);
    }
  }
  return null;
}

String normalizeResource(String value) {
  return value.trim().toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
}

int resourceSortWeight(String key) {
  if (key.contains('gold') && !key.contains('builder')) return 0;
  if (key.contains('elixir') && !key.contains('dark')) return 1;
  if (key.contains('dark')) return 2;
  if (key.contains('builder') && key.contains('gold')) return 3;
  if (key.contains('builder') && key.contains('elixir')) return 4;
  if (key.contains('shiny')) return 5;
  if (key.contains('glowy')) return 6;
  if (key.contains('starry')) return 7;
  return 99;
}
