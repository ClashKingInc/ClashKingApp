class PlayerCwlHistory {
  const PlayerCwlHistory({required this.items});

  final List<PlayerCwlSeason> items;

  factory PlayerCwlHistory.fromJson(Map<String, dynamic> json) {
    return PlayerCwlHistory(
      items: _maps(
        json['items'],
      ).map(PlayerCwlSeason.fromJson).toList(growable: false),
    );
  }
}

class PlayerCwlSeason {
  const PlayerCwlSeason({
    required this.season,
    required this.townHallLevel,
    required this.teamSize,
    required this.clan,
    required this.attacks,
    required this.clanPlacement,
    required this.groupPlacement,
    required this.missedAttacks,
  });

  final String season;
  final int townHallLevel;
  final int? teamSize;
  final PlayerCwlClan clan;
  final List<PlayerCwlAttack> attacks;
  final int? clanPlacement;
  final int? groupPlacement;
  final int missedAttacks;

  int get stars => attacks.fold(0, (total, attack) => total + attack.stars);

  factory PlayerCwlSeason.fromJson(Map<String, dynamic> json) {
    final placement = _map(json['placement']);
    return PlayerCwlSeason(
      season: json['season']?.toString() ?? '',
      townHallLevel: _int(json['townHallLevel']),
      teamSize: _nullableInt(json['teamSize']),
      clan: PlayerCwlClan.fromJson(_map(json['clan'])),
      attacks: _maps(
        json['attacks'],
      ).map(PlayerCwlAttack.fromJson).toList(growable: false),
      clanPlacement: _nullableInt(placement['clan']),
      groupPlacement: _nullableInt(placement['group']),
      missedAttacks: _int(json['missedAttacks']),
    );
  }
}

class PlayerCwlClan {
  const PlayerCwlClan({
    required this.tag,
    required this.name,
    required this.badgeUrl,
    required this.leagueName,
    required this.won,
    required this.lost,
    required this.tied,
    required this.totalStars,
    required this.groupPlacement,
    required this.globalPlacement,
  });

  final String tag;
  final String name;
  final String badgeUrl;
  final String leagueName;
  final int won;
  final int lost;
  final int tied;
  final int? totalStars;
  final int? groupPlacement;
  final int? globalPlacement;

  factory PlayerCwlClan.fromJson(Map<String, dynamic> json) {
    final badgeUrls = _map(json['badgeUrls']);
    final league = _map(json['warLeague']);
    final wars = _map(json['wars']);
    final placement = _map(json['placement']);
    return PlayerCwlClan(
      tag: json['tag']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      badgeUrl:
          badgeUrls['medium']?.toString() ??
          badgeUrls['large']?.toString() ??
          badgeUrls['small']?.toString() ??
          '',
      leagueName: league['name']?.toString() ?? '',
      won: _int(wars['won']),
      lost: _int(wars['lost']),
      tied: _int(wars['tied']),
      totalStars: _nullableInt(json['totalStars']),
      groupPlacement: _nullableInt(placement['group']),
      globalPlacement: _nullableInt(placement['global']),
    );
  }
}

class PlayerCwlAttack {
  const PlayerCwlAttack({
    required this.warTag,
    required this.round,
    required this.opponentName,
    required this.opponentTag,
    required this.defenderName,
    required this.defenderTag,
    required this.defenderTownHallLevel,
    required this.defenderMapPosition,
    required this.stars,
    required this.destructionPercentage,
    required this.order,
    required this.duration,
  });

  final String warTag;
  final int round;
  final String opponentName;
  final String opponentTag;
  final String defenderName;
  final String defenderTag;
  final int defenderTownHallLevel;
  final int defenderMapPosition;
  final int stars;
  final int destructionPercentage;
  final int order;
  final int duration;

  factory PlayerCwlAttack.fromJson(Map<String, dynamic> json) {
    final opponent = _map(json['opponent']);
    final defender = _map(json['defender']);
    return PlayerCwlAttack(
      warTag: json['warTag']?.toString() ?? '',
      round: _int(json['round']),
      opponentName: opponent['name']?.toString() ?? '',
      opponentTag: opponent['tag']?.toString() ?? '',
      defenderName: defender['name']?.toString() ?? '',
      defenderTag: defender['tag']?.toString() ?? '',
      defenderTownHallLevel: _int(defender['townHallLevel']),
      defenderMapPosition: _int(defender['mapPosition']),
      stars: _int(json['stars']),
      destructionPercentage: _int(json['destructionPercentage']),
      order: _int(json['order']),
      duration: _int(json['duration']),
    );
  }
}

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

Iterable<Map<String, dynamic>> _maps(Object? value) sync* {
  if (value is! List) return;
  for (final item in value) {
    if (item is Map) yield Map<String, dynamic>.from(item);
  }
}

int _int(Object? value) => _nullableInt(value) ?? 0;

int? _nullableInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');
