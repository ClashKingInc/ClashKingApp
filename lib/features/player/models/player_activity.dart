enum PlayerActivityKind {
  townHallUpgrade,
  troopUpgrade,
  heroUpgrade,
  spellUpgrade,
  equipmentUpgrade,
  superTroopBoost,
  itemUnlocked,
  nameChange,
}

enum PlayerActivityItemType { townHall, troop, hero, spell, equipment, profile }

class PlayerActivityEvent {
  const PlayerActivityEvent({
    required this.time,
    required this.kind,
    required this.itemType,
    required this.name,
    this.previousLevel,
    this.currentLevel,
    this.previousValue,
    this.currentValue,
  });

  final DateTime time;
  final PlayerActivityKind kind;
  final PlayerActivityItemType itemType;
  final String name;
  final int? previousLevel;
  final int? currentLevel;
  final String? previousValue;
  final String? currentValue;
}

class PlayerActivityFeed {
  const PlayerActivityFeed({required this.items});

  final List<PlayerActivityEvent> items;

  factory PlayerActivityFeed.fromJson(Map<String, dynamic> json) {
    final events = <PlayerActivityEvent>[];
    for (final raw in _list(json['items'])) {
      if (raw is! Map) continue;
      events.addAll(
        _expandChange(Map<String, dynamic>.from(raw)),
      );
    }
    events.sort((a, b) => b.time.compareTo(a.time));
    return PlayerActivityFeed(items: events);
  }
}

Iterable<PlayerActivityEvent> _expandChange(Map<String, dynamic> change) sync* {
  final time = DateTime.tryParse(change['time']?.toString() ?? '')?.toUtc();
  if (time == null) return;
  final type = change['type']?.toString() ?? '';
  final previous = change['previous'];
  final current = change['current'];

  switch (type) {
    case 'townHallLevel':
      final from = _int(previous);
      final to = _int(current);
      if (to > from) {
        yield PlayerActivityEvent(
          time: time,
          kind: PlayerActivityKind.townHallUpgrade,
          itemType: PlayerActivityItemType.townHall,
          name: 'Town Hall',
          previousLevel: from,
          currentLevel: to,
        );
      }
      return;
    case 'troops':
      yield* _expandItemChanges(
        time: time,
        previous: previous,
        current: current,
        itemType: PlayerActivityItemType.troop,
        upgradeKind: PlayerActivityKind.troopUpgrade,
        detectSuperTroopBoosts: true,
      );
      return;
    case 'heroes':
      yield* _expandItemChanges(
        time: time,
        previous: previous,
        current: current,
        itemType: PlayerActivityItemType.hero,
        upgradeKind: PlayerActivityKind.heroUpgrade,
      );
      return;
    case 'spells':
      yield* _expandItemChanges(
        time: time,
        previous: previous,
        current: current,
        itemType: PlayerActivityItemType.spell,
        upgradeKind: PlayerActivityKind.spellUpgrade,
      );
      return;
    case 'heroEquipment':
      yield* _expandItemChanges(
        time: time,
        previous: previous,
        current: current,
        itemType: PlayerActivityItemType.equipment,
        upgradeKind: PlayerActivityKind.equipmentUpgrade,
      );
      return;
    case 'name':
      final from = previous?.toString() ?? '';
      final to = current?.toString() ?? '';
      if (to.isNotEmpty && to != from) {
        yield PlayerActivityEvent(
          time: time,
          kind: PlayerActivityKind.nameChange,
          itemType: PlayerActivityItemType.profile,
          name: to,
          previousValue: from,
          currentValue: to,
        );
      }
      return;
  }
}

Iterable<PlayerActivityEvent> _expandItemChanges({
  required DateTime time,
  required Object? previous,
  required Object? current,
  required PlayerActivityItemType itemType,
  required PlayerActivityKind upgradeKind,
  bool detectSuperTroopBoosts = false,
}) sync* {
  final oldItems = _itemsByName(previous);
  final newItems = _itemsByName(current);
  for (final entry in newItems.entries) {
    final name = entry.key;
    final item = entry.value;
    final oldItem = oldItems[name];
    final from = _int(oldItem?['level']);
    final to = _int(item['level']);
    if (oldItem == null && to > 0) {
      yield PlayerActivityEvent(
        time: time,
        kind: PlayerActivityKind.itemUnlocked,
        itemType: itemType,
        name: name,
        currentLevel: to,
      );
    } else if (to > from) {
      yield PlayerActivityEvent(
        time: time,
        kind: upgradeKind,
        itemType: itemType,
        name: name,
        previousLevel: from,
        currentLevel: to,
      );
    }

    if (detectSuperTroopBoosts &&
        item['superTroopIsActive'] == true &&
        oldItem?['superTroopIsActive'] != true) {
      yield PlayerActivityEvent(
        time: time,
        kind: PlayerActivityKind.superTroopBoost,
        itemType: PlayerActivityItemType.troop,
        name: name,
        currentLevel: to > 0 ? to : null,
      );
    }
  }
}

Map<String, Map<String, dynamic>> _itemsByName(Object? value) {
  final result = <String, Map<String, dynamic>>{};
  for (final raw in _list(value)) {
    if (raw is! Map) continue;
    final item = Map<String, dynamic>.from(raw);
    final name = item['name']?.toString() ?? '';
    if (name.isNotEmpty) result[name] = item;
  }
  return result;
}

List<dynamic> _list(Object? value) => value is List ? value : const [];

int _int(Object? value) => value is num
    ? value.toInt()
    : int.tryParse(value?.toString() ?? '') ?? 0;
