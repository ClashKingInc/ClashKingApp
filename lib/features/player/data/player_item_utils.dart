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
  return Map.fromEntries(
    data.entries.where((e) => predicate(e.key, e.value)),
  );
}
