enum PlayerHistoryType {
  troopLevel('troop_level'),
  superTroopBoost('super_troop_boost'),
  heroLevel('hero_level'),
  spellLevel('spell_level'),
  petLevel('pet_level'),
  equipmentLevel('equipment_level'),
  townHallLevel('townhall_level'),
  experienceLevel('exp_level'),
  bestTrophies('best_trophies'),
  bestBuilderBaseTrophies('best_builder_base_trophies'),
  warPreference('war_preference');

  const PlayerHistoryType(this.apiValue);

  final String apiValue;
}

enum PlayerActivityKind {
  townHallUpgrade,
  troopUpgrade,
  heroUpgrade,
  spellUpgrade,
  petUpgrade,
  equipmentUpgrade,
  superTroopBoost,
  itemUnlocked,
  experienceLevelChange,
  trophyRecord,
  builderTrophyRecord,
  warPreferenceChange,
}

enum PlayerActivityItemType {
  townHall,
  troop,
  hero,
  spell,
  pet,
  equipment,
  trophy,
  profile,
}

class PlayerActivityEvent {
  const PlayerActivityEvent({
    required this.time,
    required this.kind,
    required this.itemType,
    required this.name,
    this.itemId,
    this.townHallLevel,
    this.previousLevel,
    this.currentLevel,
    this.previousValue,
    this.currentValue,
  });

  final DateTime time;
  final PlayerActivityKind kind;
  final PlayerActivityItemType itemType;
  final String name;
  final int? itemId;
  final int? townHallLevel;
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
    for (final raw in _maps(json['items'])) {
      final event = _eventFromChange(raw);
      if (event != null) events.add(event);
    }
    events.sort((a, b) => b.time.compareTo(a.time));
    return PlayerActivityFeed(items: events);
  }
}

PlayerActivityEvent? _eventFromChange(Map<String, dynamic> change) {
  final time = DateTime.tryParse(change['time']?.toString() ?? '')?.toUtc();
  if (time == null) return null;
  final type = change['type']?.toString() ?? '';
  if (type == 'name') return null;
  final item = change['item'] is Map
      ? Map<String, dynamic>.from(change['item'] as Map)
      : const <String, dynamic>{};
  final previous = change['previous'];
  final current = change['current'];
  final previousLevel = _nullableInt(previous);
  final currentLevel = _nullableInt(current);
  final itemName = item['name']?.toString() ?? '';
  final itemId = _nullableInt(item['id']);
  final townHallLevel = _nullableInt(change['townhall_level']);

  final kind = switch (type) {
    'troop_level' =>
      previousLevel == 0
          ? PlayerActivityKind.itemUnlocked
          : PlayerActivityKind.troopUpgrade,
    'super_troop_boost' => PlayerActivityKind.superTroopBoost,
    'hero_level' =>
      previousLevel == 0
          ? PlayerActivityKind.itemUnlocked
          : PlayerActivityKind.heroUpgrade,
    'spell_level' =>
      previousLevel == 0
          ? PlayerActivityKind.itemUnlocked
          : PlayerActivityKind.spellUpgrade,
    'pet_level' =>
      previousLevel == 0
          ? PlayerActivityKind.itemUnlocked
          : PlayerActivityKind.petUpgrade,
    'equipment_level' =>
      previousLevel == 0
          ? PlayerActivityKind.itemUnlocked
          : PlayerActivityKind.equipmentUpgrade,
    'townhall_level' => PlayerActivityKind.townHallUpgrade,
    'exp_level' => PlayerActivityKind.experienceLevelChange,
    'best_trophies' => PlayerActivityKind.trophyRecord,
    'best_builder_base_trophies' => PlayerActivityKind.builderTrophyRecord,
    'war_preference' => PlayerActivityKind.warPreferenceChange,
    _ => null,
  };
  if (kind == null) return null;

  final itemType = switch (type) {
    'troop_level' || 'super_troop_boost' => PlayerActivityItemType.troop,
    'hero_level' => PlayerActivityItemType.hero,
    'spell_level' => PlayerActivityItemType.spell,
    'pet_level' => PlayerActivityItemType.pet,
    'equipment_level' => PlayerActivityItemType.equipment,
    'townhall_level' => PlayerActivityItemType.townHall,
    'best_trophies' ||
    'best_builder_base_trophies' => PlayerActivityItemType.trophy,
    _ => PlayerActivityItemType.profile,
  };

  return PlayerActivityEvent(
    time: time,
    kind: kind,
    itemType: itemType,
    name: itemName,
    itemId: itemId,
    townHallLevel: townHallLevel,
    previousLevel: previousLevel,
    currentLevel: currentLevel,
    previousValue: previous?.toString(),
    currentValue: current?.toString(),
  );
}

Iterable<Map<String, dynamic>> _maps(Object? value) sync* {
  if (value is! List) return;
  for (final item in value) {
    if (item is Map) yield Map<String, dynamic>.from(item);
  }
}

int? _nullableInt(Object? value) {
  if (value == null) return null;
  return value is num ? value.toInt() : int.tryParse(value.toString());
}
