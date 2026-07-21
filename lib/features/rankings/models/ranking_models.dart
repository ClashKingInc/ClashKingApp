import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/config/api_config.dart';

enum RankingAudience { players, clans }

enum RankingPeriod { current, history }

enum RankingSource { official, clashKing }

enum RankingBoard {
  playerHome(
    audience: RankingAudience.players,
    source: RankingSource.official,
    supportsLocation: true,
    supportsHistory: true,
    iconUrl: ImageAssets.trophies,
  ),
  playerBuilder(
    audience: RankingAudience.players,
    source: RankingSource.official,
    supportsLocation: true,
    supportsHistory: true,
    iconUrl: ImageAssets.builderBaseTrophy,
  ),
  playerTownHall(
    audience: RankingAudience.players,
    source: RankingSource.clashKing,
    supportsLocation: false,
    supportsHistory: true,
    iconUrl: ImageAssets.trophies,
  ),
  playerRanked(
    audience: RankingAudience.players,
    source: RankingSource.clashKing,
    supportsLocation: false,
    supportsHistory: true,
    iconUrl: ImageAssets.legendLeagueOne,
  ),
  clanHome(
    audience: RankingAudience.clans,
    source: RankingSource.official,
    supportsLocation: true,
    supportsHistory: true,
    iconUrl: ImageAssets.trophies,
  ),
  clanBuilder(
    audience: RankingAudience.clans,
    source: RankingSource.official,
    supportsLocation: true,
    supportsHistory: true,
    iconUrl: ImageAssets.builderBaseTrophy,
  ),
  clanCapital(
    audience: RankingAudience.clans,
    source: RankingSource.official,
    supportsLocation: true,
    supportsHistory: true,
    iconUrl: ImageAssets.capitalTrophy,
  ),
  clanDonations(
    audience: RankingAudience.clans,
    source: RankingSource.clashKing,
    supportsLocation: true,
    supportsHistory: false,
    supportsWorldwide: false,
    iconUrl: ImageAssets.clanGamesMedals,
  ),
  clanWarWins(
    audience: RankingAudience.clans,
    source: RankingSource.clashKing,
    supportsLocation: true,
    supportsHistory: false,
    supportsWorldwide: false,
    iconUrl: ImageAssets.war,
  ),
  clanWinStreak(
    audience: RankingAudience.clans,
    source: RankingSource.clashKing,
    supportsLocation: false,
    supportsHistory: false,
    iconUrl: ImageAssets.war,
  );

  const RankingBoard({
    required this.audience,
    required this.source,
    required this.supportsLocation,
    required this.supportsHistory,
    required this.iconUrl,
    this.supportsWorldwide = true,
  });

  final RankingAudience audience;
  final RankingSource source;
  final bool supportsLocation;
  final bool supportsHistory;
  final bool supportsWorldwide;
  final String iconUrl;

  bool get isClan => audience == RankingAudience.clans;
}

class RankingLocation {
  const RankingLocation({
    required this.id,
    required this.name,
    required this.isCountry,
    this.countryCode,
    this.isWorldwide = false,
  });

  const RankingLocation.worldwide()
    : id = null,
      name = 'Worldwide',
      isCountry = false,
      countryCode = null,
      isWorldwide = true;

  final int? id;
  final String name;
  final bool isCountry;
  final String? countryCode;
  final bool isWorldwide;

  String get apiPath => isWorldwide ? 'global' : id.toString();

  bool get hasValidCountryCode =>
      isCountry && RegExp(r'^[A-Za-z]{2}$').hasMatch(countryCode ?? '');

  factory RankingLocation.fromJson(Map<String, dynamic> json) {
    return RankingLocation(
      id: _asIntOrNull(json['id']),
      name: json['name']?.toString().trim() ?? '',
      isCountry: json['isCountry'] == true,
      countryCode: json['countryCode']?.toString().trim().toUpperCase(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RankingLocation &&
      other.id == id &&
      other.isWorldwide == isWorldwide;

  @override
  int get hashCode => Object.hash(id, isWorldwide);
}

class RankingLeagueOption {
  const RankingLeagueOption({
    required this.id,
    required this.name,
    required this.iconUrl,
  });

  static const legendOne = RankingLeagueOption(
    id: 105000036,
    name: 'Legend I',
    iconUrl: ImageAssets.legendLeagueOne,
  );

  final int id;
  final String name;
  final String iconUrl;
}

class RankingQuery {
  const RankingQuery({
    required this.board,
    required this.location,
    required this.period,
    required this.historyDate,
    required this.townHallLevel,
    required this.leagueTier,
  });

  final RankingBoard board;
  final RankingLocation location;
  final RankingPeriod period;
  final DateTime historyDate;
  final int townHallLevel;
  final RankingLeagueOption leagueTier;
}

class RankingResult {
  const RankingResult({
    required this.entries,
    required this.source,
    required this.limit,
  });

  final List<RankingEntry> entries;
  final RankingSource source;
  final int limit;
}

class RankingEntry {
  const RankingEntry({
    required this.audience,
    required this.rank,
    required this.previousRank,
    required this.tag,
    required this.name,
    required this.subtitle,
    required this.score,
    required this.imageUrl,
    required this.metricImageUrl,
    required this.townHallLevel,
    this.clanBadgeUrl = '',
  });

  final RankingAudience audience;
  final int rank;
  final int previousRank;
  final String tag;
  final String name;
  final String subtitle;
  final int score;
  final String imageUrl;
  final String metricImageUrl;
  final int townHallLevel;
  final String clanBadgeUrl;

  String get movement {
    if (previousRank <= 0 || rank <= 0) return '=';
    final delta = previousRank - rank;
    if (delta == 0) return '=';
    return delta > 0 ? '+$delta' : '$delta';
  }

  factory RankingEntry.fromJson(
    Map<String, dynamic> json,
    RankingBoard board, {
    String? rankedLeagueIconUrl,
  }) {
    final tag = _firstString(json, const ['tag', 'player_tag', 'clan_tag']);
    final townHall = _firstInt(json, const [
      'townHallLevel',
      'townhall_level',
      'townhallLevel',
    ]);
    final clanName =
        _nestedString(json['clan'], 'name') ??
        _firstString(json, const ['clan_name', 'clanName']);
    final clanTag =
        _nestedString(json['clan'], 'tag') ??
        _firstString(json, const ['clan_tag', 'clanTag']);
    final subtitleParts = <String>[
      if (clanName.isNotEmpty) clanName,
      if (clanTag.isNotEmpty && clanTag != tag) clanTag,
      if (board.isClan && clanName.isEmpty && clanTag.isEmpty && tag.isNotEmpty)
        tag,
    ];
    final includedClanBadge =
        _nestedString(json['clan'], 'badge') ??
        _nestedString(json['clan'], 'badgeUrls.medium') ??
        _nestedString(json['clan'], 'badge_urls.medium') ??
        _firstString(json, const ['clan_badge', 'clanBadge']);
    final clanBadgeUrl = board.isClan || clanTag.isEmpty
        ? ''
        : board.source == RankingSource.official
        ? '${ApiConfig.apiUrlV2}/clan/${Uri.encodeComponent(clanTag)}/badge'
        : includedClanBadge;

    final leagueIcon =
        _nestedString(json['leagueTier'], 'iconUrls.medium') ??
        _nestedString(json['leagueTier'], 'iconUrls.large') ??
        _nestedString(json['leagueTier'], 'iconUrls.small') ??
        _nestedString(json['leagueTier'], 'badge') ??
        _nestedString(json['league'], 'iconUrls.medium') ??
        _nestedString(json['league'], 'iconUrls.large') ??
        _nestedString(json['league'], 'iconUrls.small') ??
        _nestedString(json['league'], 'badge');
    final badgeUrl =
        _nestedString(json['badgeUrls'], 'medium') ??
        _nestedString(json['badge_urls'], 'medium') ??
        _firstString(json, const ['badge_url']);
    final selectedRankedLeagueIcon = board == RankingBoard.playerRanked
        ? (rankedLeagueIconUrl ?? board.iconUrl)
        : null;
    final playerImageUrl = townHall > 0
        ? ImageAssets.townHall(townHall)
        : (selectedRankedLeagueIcon ?? leagueIcon ?? board.iconUrl);
    final imageUrl = board.isClan
        ? (badgeUrl.isEmpty ? ImageAssets.clanCastle : badgeUrl)
        : playerImageUrl;
    final metricImageUrl = board.isClan
        ? board.iconUrl
        : (selectedRankedLeagueIcon ?? leagueIcon ?? board.iconUrl);

    return RankingEntry(
      audience: board.audience,
      rank: _firstInt(json, const ['rank', 'placement']),
      previousRank: _firstInt(json, const ['previousRank', 'previous_rank']),
      tag: tag,
      name: _firstString(json, const ['name', 'player_name', 'clan_name'], tag),
      subtitle: subtitleParts.join(' · '),
      score: _scoreFor(json, board),
      imageUrl: imageUrl,
      metricImageUrl: metricImageUrl,
      townHallLevel: townHall,
      clanBadgeUrl: clanBadgeUrl,
    );
  }
}

int _scoreFor(Map<String, dynamic> json, RankingBoard board) {
  final keys = switch (board) {
    RankingBoard.playerBuilder => const [
      'builderBaseTrophies',
      'builder_base_trophies',
      'versusTrophies',
      'trophies',
    ],
    RankingBoard.playerRanked => const [
      'league_trophies',
      'leagueTrophies',
      'trophies',
    ],
    RankingBoard.clanHome => const ['clanPoints', 'clan_points'],
    RankingBoard.clanBuilder => const [
      'clanBuilderBasePoints',
      'clanVersusPoints',
      'clan_builder_base_points',
    ],
    RankingBoard.clanCapital => const [
      'clanCapitalPoints',
      'capitalPoints',
      'clan_capital_points',
    ],
    RankingBoard.clanDonations => const ['donations', 'troops_donated'],
    RankingBoard.clanWarWins => const ['war_wins', 'warWins'],
    RankingBoard.clanWinStreak => const ['war_win_streak', 'warWinStreak'],
    _ => const ['trophies'],
  };
  return _firstInt(json, keys);
}

int _firstInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _asIntOrNull(json[key]);
    if (value != null) return value;
  }
  return 0;
}

int? _asIntOrNull(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

String _firstString(
  Map<String, dynamic> json,
  List<String> keys, [
  String fallback = '',
]) {
  for (final key in keys) {
    final value = json[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return fallback;
}

String? _nestedString(Object? raw, String path) {
  Object? current = raw;
  for (final segment in path.split('.')) {
    if (current is! Map) return null;
    current = current[segment];
  }
  final value = current?.toString().trim() ?? '';
  return value.isEmpty ? null : value;
}
