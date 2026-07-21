enum StatsSection { overview, armies, items, war, cwl, ranked }

enum StatsItemType { troop, spell, hero, pet, equipment }

class StatsDateFilter {
  const StatsDateFilter({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  int get inclusiveDays =>
      DateTime.utc(
        end.year,
        end.month,
        end.day,
      ).difference(DateTime.utc(start.year, start.month, start.day)).inDays +
      1;

  Map<String, dynamic> toJson() => {
    'start_date': formatDate(start),
    'end_date': formatDate(end),
  };

  static String formatDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

class StatsItemQuantityFilter {
  const StatsItemQuantityFilter({
    required this.item,
    this.minQuantity,
    this.maxQuantity,
  });

  final String item;
  final int? minQuantity;
  final int? maxQuantity;

  Map<String, dynamic> toJson() => {
    'item': item,
    if (minQuantity != null) 'min_quantity': minQuantity,
    if (maxQuantity != null) 'max_quantity': maxQuantity,
  };
}

class StatsBattleFilters {
  const StatsBattleFilters({
    required this.dates,
    this.townHallLevel,
    this.opponentTownHallLevel,
    this.equalTownHalls,
    this.rankedLeagueTierId,
    this.includeItems = const [],
    this.excludeItems = const [],
    this.minimumSampleSize = 100,
  });

  final StatsDateFilter dates;
  final int? townHallLevel;
  final int? opponentTownHallLevel;
  final bool? equalTownHalls;
  final int? rankedLeagueTierId;
  final List<StatsItemQuantityFilter> includeItems;
  final List<String> excludeItems;
  final int minimumSampleSize;

  Map<String, dynamic> toJson() => {
    'dates': dates.toJson(),
    if (townHallLevel != null) 'townhall_level': townHallLevel,
    if (opponentTownHallLevel != null)
      'opponent_townhall_level': opponentTownHallLevel,
    if (equalTownHalls != null) 'equal_townhalls': equalTownHalls,
    if (rankedLeagueTierId != null) 'ranked_league_tier_id': rankedLeagueTierId,
    if (includeItems.isNotEmpty)
      'include_items': includeItems.map((item) => item.toJson()).toList(),
    if (excludeItems.isNotEmpty) 'exclude_items': excludeItems,
    'minimum_sample_size': minimumSampleSize,
  };
}

class StatsArmiesQuery {
  const StatsArmiesQuery({
    required this.filters,
    this.limit = 25,
    this.sortBy = 'usage_rate',
  });

  final StatsBattleFilters filters;
  final int limit;
  final String sortBy;

  Map<String, dynamic> toJson() => {
    ...filters.toJson(),
    'limit': limit,
    'sort_by': sortBy,
  };
}

class StatsItemSelector {
  const StatsItemSelector({required this.item, required this.type, this.hero});

  final String item;
  final StatsItemType type;
  final String? hero;

  static const validEquipmentHeroes = {
    'Barbarian King',
    'Archer Queen',
    'Grand Warden',
    'Royal Champion',
    'Minion Prince',
  };

  bool get isValid =>
      item.trim().isNotEmpty &&
      (type != StatsItemType.equipment ||
          validEquipmentHeroes.contains(hero?.trim()));

  Map<String, dynamic> toJson() => {
    'item': item.trim(),
    'type': type.name,
    if (hero != null && hero!.trim().isNotEmpty) 'hero': hero!.trim(),
  };
}

class StatsItemsQuery {
  const StatsItemsQuery({required this.filters, required this.items});

  final StatsBattleFilters filters;
  final List<StatsItemSelector> items;

  Map<String, dynamic> toJson() => {
    ...filters.toJson(),
    'items': items.map((item) => item.toJson()).toList(),
  };
}

class StatsRankedQuery {
  const StatsRankedQuery({
    required this.dates,
    required this.townHallLevel,
    required this.rankedLeagueTierId,
  });

  final StatsDateFilter dates;
  final int townHallLevel;
  final int rankedLeagueTierId;

  Map<String, dynamic> toJson() => {
    'dates': dates.toJson(),
    'townhall_level': townHallLevel,
    'ranked_league_tier_id': rankedLeagueTierId,
  };
}

class StatsWarQuery {
  const StatsWarQuery({
    required this.dates,
    this.townHallLevel,
    this.opponentTownHallLevel,
    this.equalTownHalls = true,
  });

  final StatsDateFilter dates;
  final int? townHallLevel;
  final int? opponentTownHallLevel;
  final bool equalTownHalls;

  Map<String, dynamic> toJson() => {
    'dates': dates.toJson(),
    if (townHallLevel != null) 'townhall_level': townHallLevel,
    if (opponentTownHallLevel != null)
      'opponent_townhall_level': opponentTownHallLevel,
    'equal_townhalls': equalTownHalls,
  };
}

class StatsCwlQuery extends StatsWarQuery {
  const StatsCwlQuery({
    required super.dates,
    super.townHallLevel,
    super.opponentTownHallLevel,
    super.equalTownHalls,
    this.cwlLeagueId,
    this.seasons = const [],
  });

  final int? cwlLeagueId;
  final List<String> seasons;

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    if (cwlLeagueId != null) 'cwl_league_id': cwlLeagueId,
    if (seasons.isNotEmpty) 'seasons': seasons,
  };
}

class StatsDateRange {
  const StatsDateRange({required this.start, required this.end});

  final DateTime? start;
  final DateTime? end;

  factory StatsDateRange.fromJson(Object? json) {
    final map = _map(json);
    return StatsDateRange(
      start: DateTime.tryParse(map['start']?.toString() ?? ''),
      end: DateTime.tryParse(map['end']?.toString() ?? ''),
    );
  }
}

class StatsDailyPoint {
  const StatsDailyPoint({
    required this.date,
    required this.sampleSize,
    required this.averageStars,
    required this.averageDestruction,
    required this.zeroStarRate,
    required this.oneStarRate,
    required this.twoStarRate,
    required this.threeStarRate,
    this.useCount,
    this.usageRate,
  });

  final String date;
  final int sampleSize;
  final int? useCount;
  final double? usageRate;
  final double averageStars;
  final double averageDestruction;
  final double zeroStarRate;
  final double oneStarRate;
  final double twoStarRate;
  final double threeStarRate;

  factory StatsDailyPoint.fromJson(Object? json) {
    final map = _map(json);
    return StatsDailyPoint(
      date: map['date']?.toString() ?? '',
      sampleSize: _int(map['sample_size']),
      useCount: map['use_count'] == null ? null : _int(map['use_count']),
      usageRate: _nullableDouble(map['usage_rate']),
      averageStars: _double(map['average_stars']),
      averageDestruction: _double(map['average_destruction']),
      zeroStarRate: _double(map['zero_star_rate']),
      oneStarRate: _double(map['one_star_rate']),
      twoStarRate: _double(map['two_star_rate']),
      threeStarRate: _double(map['three_star_rate']),
    );
  }
}

class StatsMetrics {
  const StatsMetrics({
    required this.available,
    required this.sampleSize,
    required this.averageStars,
    required this.averageDestruction,
    required this.zeroStarRate,
    required this.oneStarRate,
    required this.twoStarRate,
    required this.threeStarRate,
    required this.daily,
    this.usageRate,
  });

  final bool available;
  final int sampleSize;
  final double? usageRate;
  final double averageStars;
  final double averageDestruction;
  final double zeroStarRate;
  final double oneStarRate;
  final double twoStarRate;
  final double threeStarRate;
  final List<StatsDailyPoint> daily;

  factory StatsMetrics.fromJson(Object? json) {
    final map = _map(json);
    return StatsMetrics(
      available: map['available'] == true,
      sampleSize: _int(map['sample_size']),
      usageRate: _nullableDouble(map['usage_rate']),
      averageStars: _double(map['average_stars']),
      averageDestruction: _double(map['average_destruction']),
      zeroStarRate: _double(map['zero_star_rate']),
      oneStarRate: _double(map['one_star_rate']),
      twoStarRate: _double(map['two_star_rate']),
      threeStarRate: _double(map['three_star_rate']),
      daily: _list(map['daily']).map(StatsDailyPoint.fromJson).toList(),
    );
  }
}

class StatsGlobalCounts {
  const StatsGlobalCounts({
    required this.playersInWar,
    required this.clansInWar,
    required this.totalJoinLeaves,
    required this.playersInLegends,
    required this.playerCount,
    required this.clanCount,
    required this.warsStored,
  });

  final int playersInWar;
  final int clansInWar;
  final int totalJoinLeaves;
  final int playersInLegends;
  final int playerCount;
  final int clanCount;
  final int warsStored;

  factory StatsGlobalCounts.fromJson(Object? json) {
    final map = _map(json);
    return StatsGlobalCounts(
      playersInWar: _int(map['players_in_war']),
      clansInWar: _int(map['clans_in_war']),
      totalJoinLeaves: _int(map['total_join_leaves']),
      playersInLegends: _int(map['players_in_legends']),
      playerCount: _int(map['player_count']),
      clanCount: _int(map['clan_count']),
      warsStored: _int(map['wars_stored']),
    );
  }
}

class StatsOverviewResponse {
  const StatsOverviewResponse({
    required this.dateRange,
    required this.counts,
    required this.ranked,
    required this.war,
    required this.cwl,
  });

  final StatsDateRange dateRange;
  final StatsGlobalCounts counts;
  final StatsMetrics ranked;
  final StatsMetrics war;
  final StatsMetrics cwl;

  factory StatsOverviewResponse.fromJson(Map<String, dynamic> json) =>
      StatsOverviewResponse(
        dateRange: StatsDateRange.fromJson(json['date_range']),
        counts: StatsGlobalCounts.fromJson(json['counts']),
        ranked: StatsMetrics.fromJson(json['ranked']),
        war: StatsMetrics.fromJson(json['war']),
        cwl: StatsMetrics.fromJson(json['cwl']),
      );
}

class StatsArmyResult {
  const StatsArmyResult({
    required this.armyShareCode,
    required this.armyItems,
    required this.armyCounts,
    required this.metrics,
  });

  final String armyShareCode;
  final List<String> armyItems;
  final Map<String, int> armyCounts;
  final StatsMetrics metrics;

  factory StatsArmyResult.fromJson(Object? json) {
    final map = _map(json);
    return StatsArmyResult(
      armyShareCode: map['army_share_code']?.toString() ?? '',
      armyItems: _list(map['army_items']).map((item) => '$item').toList(),
      armyCounts: _map(
        map['army_counts'],
      ).map((key, value) => MapEntry(key, _int(value))),
      metrics: StatsMetrics.fromJson(map),
    );
  }
}

class StatsArmiesResponse {
  const StatsArmiesResponse({
    required this.dateRange,
    required this.items,
    required this.count,
  });

  final StatsDateRange dateRange;
  final List<StatsArmyResult> items;
  final int count;

  factory StatsArmiesResponse.fromJson(Map<String, dynamic> json) =>
      StatsArmiesResponse(
        dateRange: StatsDateRange.fromJson(json['date_range']),
        items: _list(json['items']).map(StatsArmyResult.fromJson).toList(),
        count: _int(json['count']),
      );
}

class StatsItemResult {
  const StatsItemResult({
    required this.item,
    required this.type,
    required this.useCount,
    required this.metrics,
    this.hero,
    this.compositionShare,
  });

  final String item;
  final String type;
  final String? hero;
  final int useCount;
  final double? compositionShare;
  final StatsMetrics metrics;

  factory StatsItemResult.fromJson(Object? json) {
    final map = _map(json);
    return StatsItemResult(
      item: map['item']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      hero: map['hero']?.toString(),
      useCount: _int(map['use_count']),
      compositionShare: _nullableDouble(map['composition_share']),
      metrics: StatsMetrics.fromJson(map),
    );
  }
}

class StatsItemsResponse {
  const StatsItemsResponse({
    required this.dateRange,
    required this.items,
    required this.count,
  });

  final StatsDateRange dateRange;
  final List<StatsItemResult> items;
  final int count;

  factory StatsItemsResponse.fromJson(Map<String, dynamic> json) =>
      StatsItemsResponse(
        dateRange: StatsDateRange.fromJson(json['date_range']),
        items: _list(json['items']).map(StatsItemResult.fromJson).toList(),
        count: _int(json['count']),
      );
}

class StatsBreakdown {
  const StatsBreakdown({required this.key, required this.metrics});

  final String key;
  final StatsMetrics metrics;

  factory StatsBreakdown.fromJson(Object? json) {
    final map = _map(json);
    return StatsBreakdown(
      key: map['key']?.toString() ?? '',
      metrics: StatsMetrics.fromJson(map['metrics']),
    );
  }
}

class StatsPerformanceResponse {
  const StatsPerformanceResponse({
    required this.dateRange,
    required this.metrics,
    required this.breakdowns,
  });

  final StatsDateRange dateRange;
  final StatsMetrics metrics;
  final List<StatsBreakdown> breakdowns;

  factory StatsPerformanceResponse.fromJson(Map<String, dynamic> json) =>
      StatsPerformanceResponse(
        dateRange: StatsDateRange.fromJson(json['date_range']),
        metrics: StatsMetrics.fromJson(json['metrics']),
        breakdowns: _list(
          json['breakdowns'],
        ).map(StatsBreakdown.fromJson).toList(),
      );
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

List<Object?> _list(Object? value) => value is List ? value : const [];

int _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

double _double(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

double? _nullableDouble(Object? value) => value == null ? null : _double(value);
