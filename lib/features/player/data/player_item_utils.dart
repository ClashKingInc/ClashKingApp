import 'package:clashkingapp/features/player/models/player_item.dart';

typedef PlayerItemFactory<T extends PlayerItem> = T Function({
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
    gameData.entries
        .map((e) => MapEntry(e.key, e.value as Map<String, dynamic>)),
  );

  return allItems.entries.map((entry) {
    final name = entry.key;
    final meta = entry.value;
    final owned = jsonList?.firstWhere(
      (x) => nameMatcher?.call(name, x) ?? x['name'] == name,
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
  return filterGameData(data, (_, __) => true);
}

/// Returns the highest item level unlockable at [thLevel] based on bundle metadata.
/// Returns 0 if the item has no levels or is not available at that TH level.
int maxLevelForTH(Map<String, dynamic>? meta, int thLevel) {
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
  return maxLevel;
}
