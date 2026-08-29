enum ClanLeaderboardType {
  homeVillage('clan_home_points'),
  builderBase('clan_builder_base_points'),
  clanCapital('clan_capital_points');

  const ClanLeaderboardType(this.apiValue);

  final String apiValue;
}

class ClanLeaderboardHistory {
  const ClanLeaderboardHistory({required this.items});

  final List<ClanLeaderboardHistoryEntry> items;

  factory ClanLeaderboardHistory.fromJson(Map<String, dynamic> json) {
    return ClanLeaderboardHistory(
      items: _maps(
        json['items'],
      ).map(ClanLeaderboardHistoryEntry.fromJson).toList(growable: false),
    );
  }
}

class ClanLeaderboardHistorySummary {
  const ClanLeaderboardHistorySummary({required this.seasons});

  final List<ClanLeaderboardSeasonSummary> seasons;

  factory ClanLeaderboardHistorySummary.fromJson(Map<String, dynamic> json) {
    return ClanLeaderboardHistorySummary(
      seasons: _maps(
        json['seasons'],
      ).map(ClanLeaderboardSeasonSummary.fromJson).toList(growable: false),
    );
  }
}

class ClanLeaderboardSeasonSummary {
  const ClanLeaderboardSeasonSummary({
    required this.season,
    required this.after,
    required this.before,
    required this.daysInTop200,
    required this.bestRank,
    required this.peakPoints,
  });

  final String season;
  final DateTime after;
  final DateTime before;
  final int daysInTop200;
  final int bestRank;
  final int peakPoints;

  factory ClanLeaderboardSeasonSummary.fromJson(Map<String, dynamic> json) {
    return ClanLeaderboardSeasonSummary(
      season: json['season']?.toString() ?? '',
      after: _date(json['after']),
      before: _date(json['before']),
      daysInTop200: _integer(json['daysInTop200']),
      bestRank: _integer(json['bestRank']),
      peakPoints: _integer(json['peakPoints']),
    );
  }
}

class ClanLeaderboardHistoryEntry {
  const ClanLeaderboardHistoryEntry({
    required this.date,
    required this.rank,
    required this.points,
    required this.members,
    this.location,
  });

  final DateTime date;
  final int rank;
  final int points;
  final int members;
  final ClanLeaderboardLocation? location;

  factory ClanLeaderboardHistoryEntry.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    return ClanLeaderboardHistoryEntry(
      date: _date(json['date']),
      rank: _integer(json['rank']),
      points: _integer(
        json['clanPoints'] ??
            json['builderBasePoints'] ??
            json['capitalPoints'],
      ),
      members: _integer(json['members']),
      location: location is Map
          ? ClanLeaderboardLocation.fromJson(
              Map<String, dynamic>.from(location),
            )
          : null,
    );
  }
}

class ClanLeaderboardLocation {
  const ClanLeaderboardLocation({
    required this.id,
    required this.name,
    required this.isCountry,
    this.countryCode,
  });

  final int id;
  final String name;
  final bool isCountry;
  final String? countryCode;

  factory ClanLeaderboardLocation.fromJson(Map<String, dynamic> json) {
    return ClanLeaderboardLocation(
      id: _integer(json['id']),
      name: json['name']?.toString() ?? '',
      isCountry: json['isCountry'] == true,
      countryCode: json['countryCode']?.toString(),
    );
  }
}

class ClanLegendHistory {
  const ClanLegendHistory({required this.items});

  final List<ClanLegendHistoryEntry> items;

  factory ClanLegendHistory.fromJson(Map<String, dynamic> json) {
    return ClanLegendHistory(
      items: _maps(
        json['items'],
      ).map(ClanLegendHistoryEntry.fromJson).toList(growable: false),
    );
  }
}

class ClanLegendHistorySummary {
  const ClanLegendHistorySummary({
    required this.seasons,
    required this.topFinishes,
  });

  final List<ClanLegendSeasonSummary> seasons;
  final List<ClanLegendHistoryEntry> topFinishes;

  factory ClanLegendHistorySummary.fromJson(Map<String, dynamic> json) {
    return ClanLegendHistorySummary(
      seasons: _maps(
        json['seasons'],
      ).map(ClanLegendSeasonSummary.fromJson).toList(growable: false),
      topFinishes: _maps(
        json['topFinishes'],
      ).map(ClanLegendHistoryEntry.fromJson).toList(growable: false),
    );
  }
}

class ClanLegendSeasonSummary {
  const ClanLegendSeasonSummary({
    required this.season,
    required this.after,
    required this.before,
    required this.playerCount,
  });

  final String season;
  final DateTime after;
  final DateTime before;
  final int playerCount;

  factory ClanLegendSeasonSummary.fromJson(Map<String, dynamic> json) {
    return ClanLegendSeasonSummary(
      season: json['season']?.toString() ?? '',
      after: _date(json['after']),
      before: _date(json['before']),
      playerCount: _integer(json['playerCount']),
    );
  }
}

class ClanLegendHistoryEntry {
  const ClanLegendHistoryEntry({
    required this.season,
    required this.tag,
    required this.name,
    required this.expLevel,
    required this.trophies,
    required this.attackWins,
    required this.defenseWins,
    required this.rank,
  });

  final String season;
  final String tag;
  final String name;
  final int expLevel;
  final int trophies;
  final int attackWins;
  final int defenseWins;
  final int rank;

  factory ClanLegendHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ClanLegendHistoryEntry(
      season: json['season']?.toString() ?? '',
      tag: json['tag']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      expLevel: _integer(json['expLevel']),
      trophies: _integer(json['trophies']),
      attackWins: _integer(json['attackWins']),
      defenseWins: _integer(json['defenseWins']),
      rank: _integer(json['rank']),
    );
  }
}

class ClanRecords {
  const ClanRecords({this.clanPoints, this.warWinStreak});

  final ClanRecord? clanPoints;
  final ClanRecord? warWinStreak;

  bool get isEmpty => clanPoints == null && warWinStreak == null;

  factory ClanRecords.fromJson(Map<String, dynamic> json) {
    return ClanRecords(
      clanPoints: _record(json['clanPoints']),
      warWinStreak: _record(json['warWinStreak']),
    );
  }
}

class ClanRecord {
  const ClanRecord({required this.value, required this.time});

  final int value;
  final DateTime time;

  factory ClanRecord.fromJson(Map<String, dynamic> json) {
    return ClanRecord(
      value: _integer(json['value']),
      time: _date(json['time']),
    );
  }
}

class ClanProfileHistory {
  const ClanProfileHistory({required this.items});

  final List<ClanProfileChange> items;

  factory ClanProfileHistory.fromJson(Map<String, dynamic> json) {
    return ClanProfileHistory(
      items: _maps(
        json['items'],
      ).map(ClanProfileChange.fromJson).toList(growable: false),
    );
  }
}

enum ClanProfileChangeType { clanLevel, description, unknown }

class ClanProfileChange {
  const ClanProfileChange({
    required this.time,
    required this.type,
    required this.previous,
    required this.current,
  });

  final DateTime time;
  final ClanProfileChangeType type;
  final Object? previous;
  final Object? current;

  factory ClanProfileChange.fromJson(Map<String, dynamic> json) {
    return ClanProfileChange(
      time: _date(json['time']),
      type: switch (json['type']?.toString()) {
        'clanLevel' => ClanProfileChangeType.clanLevel,
        'description' => ClanProfileChangeType.description,
        _ => ClanProfileChangeType.unknown,
      },
      previous: json['previous'],
      current: json['current'],
    );
  }
}

ClanRecord? _record(Object? value) {
  if (value is! Map) return null;
  return ClanRecord.fromJson(Map<String, dynamic>.from(value));
}

Iterable<Map<String, dynamic>> _maps(Object? value) sync* {
  if (value is! List) return;
  for (final item in value) {
    if (item is Map) yield Map<String, dynamic>.from(item);
  }
}

int _integer(Object? value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;

DateTime _date(Object? value) =>
    DateTime.tryParse(value?.toString() ?? '')?.toUtc() ??
    DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
