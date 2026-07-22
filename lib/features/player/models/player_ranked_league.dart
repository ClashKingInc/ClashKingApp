class RankedLeagueData {
  const RankedLeagueData({
    required this.playerTag,
    required this.playerName,
    required this.townHallLevel,
    required this.trophies,
    required this.bestTrophies,
    required this.currentTier,
    required this.tiers,
    required this.history,
    this.currentGroup,
    this.previousGroup,
  });

  final String playerTag;
  final String playerName;
  final int townHallLevel;
  final int trophies;
  final int bestTrophies;
  final RankedLeagueTier? currentTier;
  final Map<int, RankedLeagueTier> tiers;
  final List<RankedLeagueHistoryEntry> history;
  final RankedLeagueGroup? currentGroup;
  final RankedLeagueGroup? previousGroup;

  RankedLeagueGroup? groupForSeason(int seasonId) {
    if (currentGroup?.seasonId == seasonId) return currentGroup;
    if (previousGroup?.seasonId == seasonId) return previousGroup;
    return null;
  }

  RankedLeagueMember? get currentMember => currentGroup?.members
      .where((member) => member.playerTag == playerTag)
      .firstOrNull;

  int? get currentRank {
    final member = currentMember;
    if (member == null || currentGroup == null) return null;
    return currentGroup!.members.indexOf(member) + 1;
  }

  int? get currentMaxBattles {
    final tierId = currentTier?.id;
    if (tierId == null) return null;
    for (final entry in history) {
      if (entry.leagueTierId == tierId && entry.maxBattles > 0) {
        return entry.maxBattles;
      }
    }
    return null;
  }
}

class RankedLeagueTier {
  const RankedLeagueTier({
    required this.id,
    required this.name,
    required this.smallIconUrl,
    required this.largeIconUrl,
  });

  final int id;
  final String name;
  final String smallIconUrl;
  final String largeIconUrl;

  factory RankedLeagueTier.fromJson(Map<String, dynamic> json) {
    final icons = json['iconUrls'] as Map<String, dynamic>? ?? const {};
    return RankedLeagueTier(
      id: _asInt(json['id']),
      name: json['name'] as String? ?? 'Unranked',
      smallIconUrl: icons['small'] as String? ?? '',
      largeIconUrl: icons['large'] as String? ?? '',
    );
  }
}

class RankedLeagueGroup {
  RankedLeagueGroup({
    required this.tag,
    required this.seasonId,
    required List<RankedLeagueMember> members,
    required this.attackLogs,
    required this.defenseLogs,
  }) : members = [...members]
         ..sort((a, b) => b.leagueTrophies.compareTo(a.leagueTrophies));

  final String tag;
  final int seasonId;
  final List<RankedLeagueMember> members;
  final List<RankedLeagueBattle> attackLogs;
  final List<RankedLeagueBattle> defenseLogs;

  factory RankedLeagueGroup.fromJson(
    Map<String, dynamic> json, {
    required String tag,
    required int seasonId,
  }) {
    return RankedLeagueGroup(
      tag: tag,
      seasonId: seasonId,
      members: _mapList(json['members'], RankedLeagueMember.fromJson),
      attackLogs: _mapList(json['attackLogs'], RankedLeagueBattle.fromJson),
      defenseLogs: _mapList(json['defenseLogs'], RankedLeagueBattle.fromJson),
    );
  }
}

class RankedLeagueMember {
  const RankedLeagueMember({
    required this.playerTag,
    required this.playerName,
    required this.clanTag,
    required this.clanName,
    required this.leagueTrophies,
    required this.attackWinCount,
    required this.attackLoseCount,
    required this.defenseWinCount,
    required this.defenseLoseCount,
  });

  final String playerTag;
  final String playerName;
  final String clanTag;
  final String clanName;
  final int leagueTrophies;
  final int attackWinCount;
  final int attackLoseCount;
  final int defenseWinCount;
  final int defenseLoseCount;

  factory RankedLeagueMember.fromJson(Map<String, dynamic> json) {
    return RankedLeagueMember(
      playerTag: json['playerTag'] as String? ?? '',
      playerName: json['playerName'] as String? ?? '',
      clanTag: json['clanTag'] as String? ?? '',
      clanName: json['clanName'] as String? ?? '',
      leagueTrophies: _asInt(json['leagueTrophies']),
      attackWinCount: _asInt(json['attackWinCount']),
      attackLoseCount: _asInt(json['attackLoseCount']),
      defenseWinCount: _asInt(json['defenseWinCount']),
      defenseLoseCount: _asInt(json['defenseLoseCount']),
    );
  }
}

class RankedLeagueBattle {
  const RankedLeagueBattle({
    required this.opponentPlayerTag,
    required this.opponentName,
    required this.stars,
    required this.destructionPercentage,
    required this.trophies,
    required this.creationTime,
  });

  final String opponentPlayerTag;
  final String opponentName;
  final int stars;
  final double destructionPercentage;
  final int trophies;
  final DateTime? creationTime;

  factory RankedLeagueBattle.fromJson(Map<String, dynamic> json) {
    return RankedLeagueBattle(
      opponentPlayerTag: json['opponentPlayerTag'] as String? ?? '',
      opponentName: json['opponentName'] as String? ?? '',
      stars: _asInt(json['stars']),
      destructionPercentage: _asDouble(json['destructionPercentage']),
      trophies: _asInt(json['trophies']),
      creationTime: _parseApiTime(json['creationTime'] as String?),
    );
  }
}

class RankedLeagueHistoryEntry {
  const RankedLeagueHistoryEntry({
    required this.leagueSeasonId,
    required this.leagueTrophies,
    required this.leagueTierId,
    required this.placement,
    required this.attackWins,
    required this.attackLosses,
    required this.attackStars,
    required this.defenseWins,
    required this.defenseLosses,
    required this.defenseStars,
    required this.maxBattles,
  });

  final int leagueSeasonId;
  final int leagueTrophies;
  final int leagueTierId;
  final int placement;
  final int attackWins;
  final int attackLosses;
  final int attackStars;
  final int defenseWins;
  final int defenseLosses;
  final int defenseStars;
  final int maxBattles;

  DateTime get startsAt =>
      DateTime.fromMillisecondsSinceEpoch(leagueSeasonId * 1000, isUtc: true);

  factory RankedLeagueHistoryEntry.fromJson(Map<String, dynamic> json) {
    return RankedLeagueHistoryEntry(
      leagueSeasonId: _asInt(json['leagueSeasonId']),
      leagueTrophies: _asInt(json['leagueTrophies']),
      leagueTierId: _asInt(json['leagueTierId']),
      placement: _asInt(json['placement']),
      attackWins: _asInt(json['attackWins']),
      attackLosses: _asInt(json['attackLosses']),
      attackStars: _asInt(json['attackStars']),
      defenseWins: _asInt(json['defenseWins']),
      defenseLosses: _asInt(json['defenseLosses']),
      defenseStars: _asInt(json['defenseStars']),
      maxBattles: _asInt(json['maxBattles']),
    );
  }
}

List<T> _mapList<T>(Object? value, T Function(Map<String, dynamic>) parse) {
  return (value as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map(parse)
      .toList();
}

int _asInt(Object? value) => value is num ? value.toInt() : 0;

double _asDouble(Object? value) => value is num ? value.toDouble() : 0;

DateTime? _parseApiTime(String? value) {
  if (value == null || value.isEmpty) return null;
  final normalized = value.replaceFirst(
    RegExp(r'^(\d{8}T\d{6})\.000Z$'),
    r'$1Z',
  );
  return DateTime.tryParse(normalized);
}
