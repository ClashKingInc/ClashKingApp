import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/game_data_service.dart';

enum PlayerBattlelogMode { ranked, farming }

enum PlayerBattlelogSource { official, history }

class PlayerBattlelogEntry {
  const PlayerBattlelogEntry({
    required this.id,
    required this.mode,
    required this.source,
    required this.attack,
    required this.opponentTag,
    required this.opponentName,
    required this.opponentTownHall,
    required this.stars,
    required this.destructionPercentage,
    required this.gold,
    required this.elixir,
    required this.darkElixir,
    required this.timestamp,
    required this.duration,
    required this.armyShareCode,
    required this.armyCounts,
  });

  final String id;
  final PlayerBattlelogMode mode;
  final PlayerBattlelogSource source;
  final bool attack;
  final String opponentTag;
  final String opponentName;
  final int opponentTownHall;
  final int stars;
  final int destructionPercentage;
  final int gold;
  final int elixir;
  final int darkElixir;
  final DateTime? timestamp;
  final int duration;
  final String armyShareCode;
  final Map<String, int> armyCounts;

  int get totalLoot => gold + elixir + darkElixir;

  factory PlayerBattlelogEntry.fromOfficial(Map<String, dynamic> json) {
    final resources = <String, int>{};
    for (final raw in _list(json['lootedResources'])) {
      final resource = _map(raw);
      final name = resource['name']?.toString().toLowerCase() ?? '';
      resources[name] = _int(resource['amount']);
    }
    final armyShareCode = json['armyShareCode']?.toString() ?? '';
    final timestamp = _parseBattleTime(json['battleTimestamp']);
    final opponentTag = json['opponentPlayerTag']?.toString() ?? '';
    return PlayerBattlelogEntry(
      id: '',
      mode: _battlelogMode(json['battleType']),
      source: PlayerBattlelogSource.official,
      attack: json['attack'] == true,
      opponentTag: opponentTag,
      opponentName: json['opponentName']?.toString() ?? '',
      opponentTownHall: _int(json['opponentTownHallLevel']),
      stars: _int(json['stars']),
      destructionPercentage: _int(json['destructionPercentage']),
      gold: resources['gold'] ?? 0,
      elixir: resources['elixir'] ?? 0,
      darkElixir: resources['darkelixir'] ?? resources['dark_elixir'] ?? 0,
      timestamp: timestamp,
      duration: _int(json['battleTime']),
      armyShareCode: armyShareCode,
      armyCounts: _parseArmyCounts(armyShareCode),
    );
  }

  factory PlayerBattlelogEntry.fromHistory(Map<String, dynamic> json) {
    final armyShareCode = json['army_share_code']?.toString() ?? '';
    final storedArmyCounts = _map(
      json['army_counts'],
    ).map((key, value) => MapEntry(key, _int(value)));
    return PlayerBattlelogEntry(
      id: json['battle_id']?.toString() ?? '',
      mode: _battlelogMode(json['battle_type']),
      source: PlayerBattlelogSource.history,
      attack: json['attack'] == true,
      opponentTag: json['opponent_tag']?.toString() ?? '',
      opponentName: json['opponent_name']?.toString() ?? '',
      opponentTownHall: _int(json['opponent_townhall']),
      stars: _int(json['stars']),
      destructionPercentage: _int(json['destruction_percentage']),
      gold: _int(json['gold']),
      elixir: _int(json['elixir']),
      darkElixir: _int(json['dark_elixir']),
      timestamp: _parseBattleTime(json['timestamp']),
      duration: _int(json['duration']),
      armyShareCode: armyShareCode,
      armyCounts: storedArmyCounts.isEmpty
          ? _parseArmyCounts(armyShareCode)
          : storedArmyCounts,
    );
  }

  String get mergeKey {
    final seconds = timestamp?.toUtc().millisecondsSinceEpoch ?? 0;
    return '${attack ? 1 : 0}|${opponentTag.toUpperCase()}|$seconds';
  }
}

class PlayerBattlelogData {
  const PlayerBattlelogData({
    required this.items,
    required this.officialAvailable,
    required this.historyAvailable,
  });

  final List<PlayerBattlelogEntry> items;
  final bool officialAvailable;
  final bool historyAvailable;

  List<PlayerBattlelogEntry> forMode(PlayerBattlelogMode mode) =>
      items.where((item) => item.mode == mode).toList(growable: false);

  static PlayerBattlelogData merge({
    required Iterable<PlayerBattlelogEntry> official,
    required Iterable<PlayerBattlelogEntry> history,
    required bool officialAvailable,
    required bool historyAvailable,
  }) {
    final merged = <String, PlayerBattlelogEntry>{};
    for (final item in official) {
      merged[item.mergeKey] = item;
    }
    // Historical rows carry parsed armies, so they intentionally win when the
    // official endpoint returns the same battle.
    for (final item in history) {
      merged[item.mergeKey] = item;
    }
    final items = merged.values.toList()
      ..sort((a, b) {
        final left = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        final right = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        return right.compareTo(left);
      });
    return PlayerBattlelogData(
      items: items,
      officialAvailable: officialAvailable,
      historyAvailable: historyAvailable,
    );
  }

  List<PlayerPopularArmyItem> popularTroops(
    PlayerBattlelogMode mode, {
    int limit = 3,
  }) {
    final uses = <String, int>{};
    for (final battle in items.where(
      (item) => item.mode == mode && item.attack,
    )) {
      for (final code in battle.armyCounts.keys.where(
        (code) => code.startsWith('u_') || code.startsWith('i_'),
      )) {
        uses.update(code, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    final popular =
        uses.entries
            .map(
              (entry) => PlayerPopularArmyItem(
                item: PlayerBattlelogArmyCatalog.resolve(entry.key),
                uses: entry.value,
              ),
            )
            .toList()
          ..sort((a, b) {
            final byUses = b.uses.compareTo(a.uses);
            return byUses != 0 ? byUses : a.item.name.compareTo(b.item.name);
          });
    return popular.take(limit).toList(growable: false);
  }
}

class PlayerPopularArmyItem {
  const PlayerPopularArmyItem({required this.item, required this.uses});

  final PlayerBattlelogArmyItem item;
  final int uses;
}

class PlayerBattlelogArmyItem {
  const PlayerBattlelogArmyItem({
    required this.code,
    required this.name,
    required this.imageUrl,
  });

  final String code;
  final String name;
  final String imageUrl;
}

class PlayerBattlelogArmyCatalog {
  PlayerBattlelogArmyCatalog._();

  static PlayerBattlelogArmyItem resolve(String code) {
    final split = code.split('_');
    final prefix = split.firstOrNull ?? '';
    final itemID = split.length == 2 ? int.tryParse(split[1]) : null;
    final item = itemID == null ? null : _findItem(prefix, itemID);
    final name = GameDataService.localizedNameForItem(item).trim();
    final resolvedName = name.isEmpty ? code : name;
    final imageUrl = switch (prefix) {
      's' || 'd' => ImageAssets.getSpellImage(resolvedName),
      'h' => ImageAssets.getHeroImage(resolvedName),
      'p' => ImageAssets.getPetImage(resolvedName),
      'e' => ImageAssets.getGearImage(resolvedName),
      _ => ImageAssets.getTroopImage(resolvedName),
    };
    return PlayerBattlelogArmyItem(
      code: code,
      name: resolvedName,
      imageUrl: imageUrl,
    );
  }

  static Map<String, dynamic>? _findItem(String prefix, int itemID) {
    final sectionName = switch (prefix) {
      's' || 'd' => 'spells',
      'h' => 'heroes',
      'p' => 'pets',
      'e' => 'equipment',
      _ => 'troops',
    };
    final rawSection = GameDataService.bundleData[sectionName];
    for (final item in _items(rawSection)) {
      final rawID = _int(item['_id']);
      if (rawID == itemID || rawID % 1000000 == itemID) return item;
    }

    final normalized = switch (sectionName) {
      'spells' => GameDataService.spellsData['spells'],
      'heroes' => GameDataService.heroesData['heroes'],
      'pets' => GameDataService.petsData['pets'],
      'equipment' => GameDataService.gearsData['gears'],
      _ => GameDataService.troopsData['troops'],
    };
    for (final item in _items(normalized)) {
      final rawID = _int(item['_id']);
      if (rawID == itemID || rawID % 1000000 == itemID) return item;
    }
    return null;
  }

  static Iterable<Map<String, dynamic>> _items(Object? section) sync* {
    if (section is List) {
      for (final item in section) {
        if (item is Map) yield Map<String, dynamic>.from(item);
      }
    } else if (section is Map) {
      for (final item in section.values) {
        if (item is Map) yield Map<String, dynamic>.from(item);
      }
    }
  }
}

PlayerBattlelogMode _battlelogMode(Object? value) {
  final normalized = value?.toString().trim().toLowerCase().replaceAll(
    RegExp(r'[^a-z]'),
    '',
  );
  return switch (normalized) {
    'ranked' || 'legend' => PlayerBattlelogMode.ranked,
    'homevillage' || 'farming' => PlayerBattlelogMode.farming,
    _ => PlayerBattlelogMode.farming,
  };
}

Map<String, int> _parseArmyCounts(String shareCode) {
  final payload = Uri.tryParse(shareCode)?.queryParameters['army'] ?? shareCode;
  final counts = <String, int>{};
  for (final section in RegExp(r'([hidsu])([^hidsu]*)').allMatches(payload)) {
    final prefix = section.group(1)!;
    if (prefix == 'h') continue;
    for (final rawItem in section.group(2)!.split('-')) {
      final match = RegExp(r'^(\d+)x(\d+)$').firstMatch(rawItem);
      if (match == null) continue;
      final quantity = int.tryParse(match.group(1)!);
      final itemID = int.tryParse(match.group(2)!);
      if (quantity == null || quantity <= 0 || itemID == null) continue;
      counts.update(
        '${prefix}_$itemID',
        (current) => current + quantity,
        ifAbsent: () => quantity,
      );
    }
  }
  return counts;
}

DateTime? _parseBattleTime(Object? value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) return null;
  final parsed = DateTime.tryParse(raw);
  if (parsed != null) return parsed.toUtc();
  final match = RegExp(
    r'^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})(?:\.(\d+))?Z$',
  ).firstMatch(raw);
  if (match == null) return null;
  final milliseconds = (match.group(7) ?? '').padRight(3, '0');
  return DateTime.utc(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
    int.parse(match.group(4)!),
    int.parse(match.group(5)!),
    int.parse(match.group(6)!),
    int.tryParse(milliseconds.substring(0, 3)) ?? 0,
  );
}

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const <String, dynamic>{};

List<dynamic> _list(Object? value) => value is List ? value : const [];

int _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
