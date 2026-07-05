import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/functions/functions.dart';
import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/player/data/player_item_utils.dart';
import 'package:clashkingapp/features/player/models/player_achievement.dart';
import 'package:clashkingapp/features/player/models/player_bb_hero.dart';
import 'package:clashkingapp/features/player/models/player_bb_troop.dart';
import 'package:clashkingapp/features/player/models/player_clan.dart';
import 'package:clashkingapp/features/player/models/player_clan_games.dart';
import 'package:clashkingapp/features/player/models/player_equipment.dart';
import 'package:clashkingapp/features/player/models/player_hero.dart';
import 'package:clashkingapp/features/player/models/player_legend_ranking.dart';
import 'package:clashkingapp/features/player/models/player_legend_season.dart';
import 'package:clashkingapp/features/player/models/player_legend_stats.dart';
import 'package:clashkingapp/features/player/models/player_pet.dart';
import 'package:clashkingapp/features/player/models/player_raids.dart';
import 'package:clashkingapp/features/player/models/player_rankings.dart';
import 'package:clashkingapp/features/player/models/player_season_pass.dart';
import 'package:clashkingapp/features/player/models/player_siege_machine.dart';
import 'package:clashkingapp/features/player/models/player_spell.dart';
import 'package:clashkingapp/features/player/models/player_super_troop.dart';
import 'package:clashkingapp/features/player/models/player_troop.dart';
import 'package:clashkingapp/features/player/models/player_war_stats.dart';
import 'package:clashkingapp/features/war_cwl/models/war_info.dart';
import 'package:clashkingapp/features/war_cwl/models/war_member_presence.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';

class Player {
  String name;
  String tag;
  int townHallLevel;
  int townHallWeaponLevel;
  int expLevel;
  int trophies;
  int bestTrophies;
  int warStars;
  int attackWins;
  int defenseWins;
  int builderHallLevel;
  int builderBaseTrophies;
  int bestBuilderBaseTrophies;
  String builderBaseLeague;
  String builderBaseLeagueUrl;
  List<PlayerAchievement> achievements;
  String clanTag;
  Clan? clan;
  PlayerClanOverview clanOverview;
  String role;
  String warPreference;
  int donations;
  int donationsReceived;
  int clanCapitalContributions;
  String league;
  String townHallPic;
  String builderHallPic;
  String leagueUrl;
  List<PlayerClanGames> clanGamesPoint;
  List<PlayerSeasonPass> seasonPass;
  DateTime lastOnline;
  List<PlayerHero> heroes;
  List<PlayerBuilderBaseHero> bbHeroes;
  List<PlayerTroop> troops;
  List<PlayerSuperTroop> superTroops;
  List<PlayerBuilderBaseTroop> bbTroops;
  List<PlayerSpell> spells;
  List<PlayerEquipment> equipments;
  List<PlayerSiegeMachine> siegeMachines;
  List<PlayerPet> pets;
  PlayerLegendStats? legendsBySeason;
  List<PlayerLegendRanking> legendRanking;
  PlayerRankings? rankings;
  PlayerWarStats? warStats;
  PlayerRaids? raids;
  WarInfo? warData;

  // Per-season tracked stats from ClashKing (populated via enrichWithFullStats)
  Map<String, int> goldBySeason;
  Map<String, int> darkElixirBySeason;
  Map<String, int> activityBySeason;
  Map<String, int> attackWinsBySeason;
  Map<String, int> seasonTrophiesBySeason;
  Map<String, Map<String, int>> donationsBySeason;

  Player({
    required this.name,
    required this.tag,
    required this.townHallLevel,
    required this.townHallWeaponLevel,
    required this.expLevel,
    required this.trophies,
    required this.bestTrophies,
    required this.warStars,
    required this.attackWins,
    required this.defenseWins,
    required this.builderHallLevel,
    required this.builderBaseTrophies,
    required this.bestBuilderBaseTrophies,
    required this.builderBaseLeague,
    required this.builderBaseLeagueUrl,
    required this.achievements,
    required this.clanTag,
    required this.clanOverview,
    required this.role,
    required this.warPreference,
    required this.donations,
    required this.donationsReceived,
    required this.clanCapitalContributions,
    required this.league,
    required this.townHallPic,
    required this.builderHallPic,
    required this.leagueUrl,
    required this.clanGamesPoint,
    required this.seasonPass,
    required this.lastOnline,
    required this.heroes,
    required this.bbHeroes,
    required this.troops,
    required this.superTroops,
    required this.bbTroops,
    required this.spells,
    required this.equipments,
    required this.siegeMachines,
    required this.pets,
    required this.legendsBySeason,
    required this.rankings,
    required this.legendRanking,
    this.warData,
    Map<String, int>? goldBySeason,
    Map<String, int>? darkElixirBySeason,
    Map<String, int>? activityBySeason,
    Map<String, int>? attackWinsBySeason,
    Map<String, int>? seasonTrophiesBySeason,
    Map<String, Map<String, int>>? donationsBySeason,
  }) : goldBySeason = goldBySeason ?? {},
       darkElixirBySeason = darkElixirBySeason ?? {},
       activityBySeason = activityBySeason ?? {},
       attackWinsBySeason = attackWinsBySeason ?? {},
       seasonTrophiesBySeason = seasonTrophiesBySeason ?? {},
       donationsBySeason = donationsBySeason ?? {};

  String get donationRatio => donationsReceived == 0
      ? "0.0"
      : (donations / donationsReceived).toStringAsFixed(2);

  String get warPreferenceImage => warPreference == "in"
      ? ImageAssets.warPreferenceIn
      : ImageAssets.warPreferenceOut;

  PlayerLegendSeason? get currentLegendSeason => legendsBySeason?.currentSeason;

  PlayerLegendRanking? getBestTrophiesSeason() {
    return legendRanking.reduce((a, b) => a.trophies > b.trophies ? a : b);
  }

  PlayerLegendRanking? getBestGlobalRankSeason() {
    return legendRanking.reduce((a, b) => a.rank < b.rank ? a : b);
  }

  PlayerLegendRanking? getLastSeason() {
    return legendRanking.first;
  }

  PlayerLegendRanking? getBestAttackWinsSeason() {
    return legendRanking.reduce((a, b) => a.attackWins > b.attackWins ? a : b);
  }

  String get currentSeasonKey {
    final now = DateTime.now();
    return "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}";
  }

  int get currentSeasonPoints {
    try {
      final key = currentSeasonKey;
      return seasonPass
          .firstWhere(
            (season) => season.season == key,
            orElse: () => PlayerSeasonPass(season: key, points: 0),
          )
          .points;
    } catch (e) {
      return 0;
    }
  }

  int get currentClanGamesPoints {
    try {
      final key = currentSeasonKey;
      return clanGamesPoint
          .firstWhere(
            (entry) => entry.season == key,
            orElse: () => PlayerClanGames(season: key, points: 0, clanTag: ''),
          )
          .points;
    } catch (e) {
      return 0;
    }
  }

  double get seasonPassRatio {
    try {
      final now = DateTime.now();
      int totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;
      int daysPassed = now.day;
      double seasonPassDaily = ((daysPassed * 2600) / totalDaysInMonth);
      double seasonPassRatio =
          (currentSeasonPoints.toDouble() / seasonPassDaily) > 1
          ? 1
          : (currentSeasonPoints.toDouble() / seasonPassDaily);
      return seasonPassRatio.toDouble();
    } catch (e) {
      return 0.0;
    }
  }

  int get seasonPassPointLeft {
    try {
      final now = DateTime.now();
      int totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;
      int daysPassed = now.day;
      double seasonPassDaily = ((daysPassed * 2600) / totalDaysInMonth);
      double seasonPassPointLeft =
          (seasonPassDaily - currentSeasonPoints.toDouble()).clamp(0, 2600);
      return seasonPassPointLeft.toInt();
    } catch (e) {
      return 0;
    }
  }

  double get clanGamesRatio {
    try {
      DateTime now = DateTime.now();
      DateTime clanGamesStart = DateTime(now.year, now.month, 22, 8);
      int daysPassed = now.difference(clanGamesStart).inDays + 1;
      double clanGamesDaily = (4000 / 8) * daysPassed;
      double clanGamesRatio =
          (currentClanGamesPoints.toDouble() / clanGamesDaily) > 1
          ? 1
          : (currentClanGamesPoints.toDouble() / clanGamesDaily);
      return clanGamesRatio.toDouble();
    } catch (e) {
      return 0.0;
    }
  }

  int get clanGamesPointLeft {
    try {
      DateTime now = DateTime.now();
      DateTime clanGamesStart = DateTime(now.year, now.month, 22, 8);
      int daysPassed = now.difference(clanGamesStart).inDays + 1;
      double clanGamesDaily = (4000 / 8) * daysPassed;
      double clanGamesPointLeft =
          (clanGamesDaily - currentClanGamesPoints.toDouble()).clamp(0, 4000);
      return clanGamesPointLeft.toInt();
    } catch (e) {
      return 0;
    }
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    try {
      List<PlayerTroop> troops = [];
      List<PlayerSuperTroop> superTroops = [];
      List<PlayerSiegeMachine> siegeMachines = [];
      List<PlayerPet> pets = [];
      List<PlayerBuilderBaseTroop> bbTroops = [];

      if (json['troops'] is List) {
        for (var troop in json['troops']) {
          if (troop is Map<String, dynamic>) {
            String troopName = troop['name'] ?? "";
            String village = troop['village'] ?? "";

            if (village == "home") {
              if (GameDataService.isSuperTroop(troopName)) {
                superTroops.add(PlayerSuperTroop.fromJson(troop));
              } else if (GameDataService.isSiegeMachine(troopName)) {
                siegeMachines.add(PlayerSiegeMachine.fromJson(troop));
              } else if (GameDataService.isPet(troopName)) {
                pets.add(PlayerPet.fromJson(troop));
              } else {
                troops.add(PlayerTroop.fromJson(troop));
              }
            } else if (village == "builderBase") {
              bbTroops.add(PlayerBuilderBaseTroop.fromJson(troop));
            }
          }
        }
      }

      // The player league object was renamed server-side from "league" to
      // "leagueTier" — try the new key first, falling back to the old one.
      final leagueJson = json["leagueTier"] ?? json["league"];

      Player profile = Player(
        name: json["name"] ?? "Unknown",
        tag: json["tag"] ?? "Unknown",
        townHallLevel: json["townHallLevel"] ?? 0,
        townHallWeaponLevel: json["townHallWeaponLevel"] ?? 0,
        expLevel: json["expLevel"] ?? 0,
        trophies: _intFromJson(json["trophies"]),
        bestTrophies: _intFromJson(json["bestTrophies"]),
        attackWins: json["attackWins"] is int ? json["attackWins"] : 0,
        defenseWins: json["defenseWins"] is int ? json["defenseWins"] : 0,
        warStars: _intFromJson(json["warStars"]),
        builderHallLevel: json["builderHallLevel"] ?? 0,
        builderBaseTrophies: _intFromJson(json["builderBaseTrophies"]),
        bestBuilderBaseTrophies: _intFromJson(json["bestBuilderBaseTrophies"]),
        builderBaseLeague: _leagueName(json["builderBaseLeague"]),
        builderBaseLeagueUrl: ImageAssets.getBuilderBaseLeagueImage(
          json["builderBaseLeague"],
        ),
        clanTag: json["clan"]?["tag"] ?? "",
        clanOverview: json["clan"] != null
            ? PlayerClanOverview.fromJson(json["clan"])
            : PlayerClanOverview.empty(),
        role: json["role"] ?? "",
        warPreference: json["warPreference"] ?? "",
        donations: _intFromJson(json["donations"]),
        donationsReceived: _intFromJson(json["donationsReceived"]),
        clanCapitalContributions: _intFromJson(
          json["clanCapitalContributions"],
        ),
        league: leagueJson?['name'] ?? "Unranked",
        townHallPic: ImageAssets.townHall(json["townHallLevel"] ?? 0),
        builderHallPic: ImageAssets.builderHall(json["builderHallLevel"] ?? 0),
        leagueUrl: ImageAssets.getLeagueImage(
          leagueJson?['name'] ?? "Unranked",
        ),
        clanGamesPoint: [],
        seasonPass: [],
        lastOnline: DateTime.utc(1970, 1, 1),
        heroes: generateCompleteItemList<PlayerHero>(
          jsonList: (json['heroes'] as List?)
              ?.where((x) => x['village'] == 'home')
              .toList(),
          gameData: filterGameData(
            GameDataService.heroesData['heroes'],
            (k, v) => v['type'] == 'hero',
          ),
          factory: PlayerHero.fromRaw,
        ),
        bbHeroes: generateCompleteItemList<PlayerBuilderBaseHero>(
          jsonList: (json['heroes'] as List?)
              ?.where((x) => x['village'] == 'builderBase')
              .toList(),
          gameData: filterGameData(
            GameDataService.heroesData['heroes'],
            (k, v) => v['type'] == 'bb-hero',
          ),
          factory: PlayerBuilderBaseHero.fromRaw,
        ),
        troops: generateCompleteItemList<PlayerTroop>(
          jsonList: (json['troops'] as List?)
              ?.where(
                (x) =>
                    x['village'] == 'home' &&
                    !GameDataService.isSuperTroop(x['name']) &&
                    !GameDataService.isSiegeMachine(x['name']) &&
                    !GameDataService.isPet(x['name']),
              )
              .toList(),
          gameData: filterGameData(
            GameDataService.troopsData['troops'],
            (k, v) =>
                v['type'] == 'troop' &&
                !GameDataService.isSuperTroop(k) &&
                !GameDataService.isSiegeMachine(k) &&
                !GameDataService.isPet(k),
          ),
          factory: PlayerTroop.fromRaw,
        ),
        superTroops: generateCompleteItemList<PlayerSuperTroop>(
          jsonList: (json['troops'] as List?)
              ?.where(
                (x) =>
                    x['village'] == 'home' &&
                    GameDataService.isSuperTroop(x['name']),
              )
              .toList(),
          gameData: filterGameData(
            GameDataService.troopsData['troops'],
            (k, v) => v['type'] == 'troop' && GameDataService.isSuperTroop(k),
          ),
          factory: PlayerSuperTroop.fromRaw,
        ),
        siegeMachines: generateCompleteItemList<PlayerSiegeMachine>(
          jsonList: (json['troops'] as List?)
              ?.where(
                (x) =>
                    x['village'] == 'home' &&
                    GameDataService.isSiegeMachine(x['name']),
              )
              .toList(),
          gameData: filterGameData(
            GameDataService.troopsData['troops'],
            (k, v) =>
                v['type'] == 'siege-machine' &&
                GameDataService.isSiegeMachine(k),
          ),
          factory: PlayerSiegeMachine.fromRaw,
        ),
        pets: generateCompleteItemList<PlayerPet>(
          jsonList: (json['troops'] as List?)
              ?.where(
                (x) =>
                    x['village'] == 'home' && GameDataService.isPet(x['name']),
              )
              .toList(),
          gameData: GameDataService.petsData['pets'] ?? {},
          factory: PlayerPet.fromRaw,
        ),
        bbTroops: generateCompleteItemList<PlayerBuilderBaseTroop>(
          jsonList: (json['troops'] as List?)
              ?.where((x) => x['village'] == 'builderBase')
              .toList(),
          gameData: filterGameData(
            GameDataService.troopsData['troops'],
            (k, v) => v['type'] == 'bb-troop',
          ),
          factory: PlayerBuilderBaseTroop.fromRaw,
          nameMatcher: (gameDataName, jsonItem) {
            if (gameDataName == 'Baby Dragon 2' &&
                jsonItem['name'] == 'Baby Dragon') {
              return true;
            }
            return gameDataName == jsonItem['name'];
          },
        ),
        spells: generateCompleteItemList<PlayerSpell>(
          jsonList: json['spells'] as List?,
          gameData: filterSpellGameData(GameDataService.spellsData['spells']),
          factory: PlayerSpell.fromRaw,
        ),
        equipments: generateCompleteItemList<PlayerEquipment>(
          jsonList: json['heroEquipment'] as List?,
          gameData: GameDataService.gearsData['gears'] ?? {},
          factory: PlayerEquipment.fromRaw,
        ),
        achievements: json['achievements'] != null
            ? List<PlayerAchievement>.from(
                json['achievements'].map(
                  (x) => PlayerAchievement.fromJson(x ?? {}),
                ),
              )
            : <PlayerAchievement>[],
        legendsBySeason: null,
        legendRanking: [],
        rankings: null,
      );

      return profile;
    } catch (e, stacktrace) {
      DebugUtils.debugError(" Exception in Player.fromJson: $e");
      DebugUtils.debugError(stacktrace.toString());
      return Player(
        name: "Unknown",
        tag: "Unknown",
        townHallLevel: 0,
        townHallWeaponLevel: 0,
        expLevel: 0,
        trophies: 0,
        bestTrophies: 0,
        warStars: 0,
        attackWins: 0,
        defenseWins: 0,
        builderHallLevel: 0,
        builderBaseTrophies: 0,
        bestBuilderBaseTrophies: 0,
        builderBaseLeague: "Unranked",
        builderBaseLeagueUrl: ImageAssets.builderBaseStar,
        achievements: [],
        clanTag: "",
        clanOverview: PlayerClanOverview.empty(),
        role: "",
        warPreference: "",
        donations: 0,
        donationsReceived: 0,
        clanCapitalContributions: 0,
        league: "",
        townHallPic: ImageAssets.townHall(1),
        builderHallPic: ImageAssets.builderHall(1),
        leagueUrl: "",
        clanGamesPoint: [],
        seasonPass: [],
        lastOnline: DateTime.now(),
        heroes: [],
        bbHeroes: [],
        troops: [],
        superTroops: [],
        bbTroops: [],
        siegeMachines: [],
        pets: [],
        spells: [],
        equipments: [],
        legendsBySeason: null,
        legendRanking: [],
        rankings: null,
      );
    }
  }

  void enrichWithFullStats(Map<String, dynamic> json) {
    clanGamesPoint =
        (json['clan_games'] as Map<String, dynamic>?)?.entries.map((entry) {
          return PlayerClanGames.fromJson(entry.key, entry.value);
        }).toList() ??
        [];

    seasonPass =
        (json['season_pass'] as Map<String, dynamic>?)?.entries.map((entry) {
          return PlayerSeasonPass(season: entry.key, points: entry.value ?? 0);
        }).toList() ??
        [];

    lastOnline = json['last_online'] != null
        ? DateTime.fromMillisecondsSinceEpoch(
            ((json['last_online'] as num) * 1000).toInt(),
            isUtc: true,
          )
        : DateTime.utc(1970, 1, 1);

    legendsBySeason = json['legends_by_season'] != null
        ? PlayerLegendStats.fromJson(json['legends_by_season'])
        : null;

    legendRanking =
        (json['legend_eos_ranking'] as List<dynamic>?)
            ?.map((x) => PlayerLegendRanking.fromJson(x))
            .toList() ??
        [];

    rankings = json['rankings'] != null
        ? PlayerRankings.fromJson(json['rankings'])
        : null;
    raids = json['raid_data'] != null && (json['raid_data'] as Map).isNotEmpty
        ? PlayerRaids.fromJson(json['raid_data'])
        : PlayerRaids.empty();

    if (json['war_data'] != null &&
        json['war_data']["currentWarInfo"] != null) {
      final originalWar = WarInfo.fromJson(json['war_data']["currentWarInfo"]);
      warData = originalWar.reorderForUser(tag);
    } else {
      warData = null;
    }

    goldBySeason = _parseSeasonIntMap(json['gold']);
    darkElixirBySeason = _parseSeasonIntMap(json['dark_elixir']);
    activityBySeason = _parseSeasonIntMap(json['activity']);
    attackWinsBySeason = _parseSeasonIntMap(json['attack_wins']);
    seasonTrophiesBySeason = _parseSeasonIntMap(json['season_trophies']);
    donationsBySeason = _parseSeasonDonationsMap(json['donations']);
  }

  void updateFromOfficialProfile(Map<String, dynamic> json) {
    if (json.containsKey("townHallLevel")) {
      townHallLevel = _intFromJson(json["townHallLevel"]);
      townHallPic = ImageAssets.townHall(townHallLevel);
    }
    if (json.containsKey("townHallWeaponLevel")) {
      townHallWeaponLevel = _intFromJson(json["townHallWeaponLevel"]);
    }
    if (json.containsKey("builderHallLevel")) {
      builderHallLevel = _intFromJson(json["builderHallLevel"]);
      builderHallPic = ImageAssets.builderHall(builderHallLevel);
    }
    if (json.containsKey("expLevel")) {
      expLevel = _intFromJson(json["expLevel"]);
    }
    if (json.containsKey("trophies")) {
      trophies = _intFromJson(json["trophies"]);
    }
    if (json.containsKey("bestTrophies")) {
      bestTrophies = _intFromJson(json["bestTrophies"]);
    }
    if (json.containsKey("warStars")) {
      warStars = _intFromJson(json["warStars"]);
    }
    if (json.containsKey("builderBaseTrophies")) {
      builderBaseTrophies = _intFromJson(json["builderBaseTrophies"]);
    }
    if (json.containsKey("bestBuilderBaseTrophies")) {
      bestBuilderBaseTrophies = _intFromJson(json["bestBuilderBaseTrophies"]);
    }
    if (json.containsKey("donations")) {
      donations = _intFromJson(json["donations"]);
    }
    if (json.containsKey("donationsReceived")) {
      donationsReceived = _intFromJson(json["donationsReceived"]);
    }
    if (json.containsKey("clanCapitalContributions")) {
      clanCapitalContributions = _intFromJson(json["clanCapitalContributions"]);
    }
    if (json.containsKey("warPreference")) {
      warPreference = json["warPreference"]?.toString() ?? "";
    }
    if (json["builderBaseLeague"] != null) {
      builderBaseLeague = _leagueName(json["builderBaseLeague"]);
      builderBaseLeagueUrl = ImageAssets.getBuilderBaseLeagueImage(
        json["builderBaseLeague"],
      );
    }
    final leagueJson = json["leagueTier"] ?? json["league"];
    if (leagueJson != null) {
      league = _leagueName(leagueJson);
      leagueUrl = ImageAssets.getLeagueImage(league);
    }
    if (json["clan"] is Map<String, dynamic>) {
      clanOverview = PlayerClanOverview.fromJson(json["clan"]);
      clanTag = clanOverview.tag;
    }
    if (json.containsKey("role")) {
      role = json["role"]?.toString() ?? "";
    }
  }

  static Map<String, int> _parseSeasonIntMap(dynamic raw) {
    if (raw is! Map) return {};
    return {
      for (final e in raw.entries)
        if (e.value is num) e.key.toString(): (e.value as num).toInt(),
    };
  }

  static int _intFromJson(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.replaceAll(',', '')) ?? 0;
    return 0;
  }

  static String _leagueName(dynamic value) {
    if (value is Map && value['name'] is String) {
      return value['name'] as String;
    }
    return 'Unranked';
  }

  static Map<String, Map<String, int>> _parseSeasonDonationsMap(dynamic raw) {
    if (raw is! Map) return {};
    final result = <String, Map<String, int>>{};
    for (final e in raw.entries) {
      if (e.value is Map) {
        final inner = e.value as Map;
        result[e.key.toString()] = {
          for (final ie in inner.entries)
            if (ie.value is num) ie.key.toString(): (ie.value as num).toInt(),
        };
      }
    }
    return result;
  }

  String getLastOnlineText(BuildContext context) {
    final now = DateTime.now().toUtc();
    final diff = now.difference(lastOnline);

    final loc = AppLocalizations.of(context)!;

    if (diff.inSeconds < 60) {
      return loc.timeJustNow;
    } else if (diff.inMinutes < 60) {
      final minutes = diff.inMinutes;
      return minutes == 1
          ? loc.timeMinuteAgo(minutes)
          : loc.timeMinutesAgo(minutes);
    } else if (diff.inHours < 24) {
      final hours = diff.inHours;
      return hours == 1 ? loc.timeHourAgo(hours) : loc.timeHoursAgo(hours);
    } else {
      final days = diff.inDays;
      return days == 1 ? loc.timeDayAgo(days) : loc.timeDaysAgo(days);
    }
  }

  /// Returns a progress ratio between 0.0 and 1.0 based on player's to-do completion
  double getTodoProgressRatio({required WarMemberPresence memberCwl}) {
    final metrics = getTodoProgressMetrics(memberCwl: memberCwl);
    if (metrics.isEmpty) return 1.0;

    final done = metrics.fold<double>(
      0,
      (sum, metric) => sum + metric.progressDone.clamp(0, metric.progressTotal),
    );
    final total = metrics.fold<double>(
      0,
      (sum, metric) => sum + metric.progressTotal,
    );
    if (total == 0) return 1.0;
    return (done / total).clamp(0.0, 1.0);
  }

  List<TodoProgressMetric> getTodoProgressMetrics({
    required WarMemberPresence memberCwl,
  }) {
    final metrics = <TodoProgressMetric>[];

    if (league == 'Legend League' && currentLegendSeason?.currentDay != null) {
      metrics.add(
        TodoProgressMetric(
          label: 'Legend attacks',
          done: currentLegendSeason?.currentDay?.totalAttacks ?? 0,
          total: 8,
        ),
      );
    }

    final regularWar = warData;
    final cwlWar = clan?.warCwl?.warInfo;
    final sameWarAsCwl =
        regularWar != null &&
        cwlWar != null &&
        ((regularWar.clan?.tag == cwlWar.clan?.tag &&
                regularWar.opponent?.tag == cwlWar.opponent?.tag) ||
            (regularWar.clan?.tag == cwlWar.opponent?.tag &&
                regularWar.opponent?.tag == cwlWar.clan?.tag));

    if (regularWar != null && regularWar.state == 'inWar' && !sameWarAsCwl) {
      metrics.add(
        TodoProgressMetric(
          label: 'War attacks',
          done: regularWar.getAttacksDoneByPlayer(tag, clanTag),
          total: regularWar.attacksPerMember ?? 2,
        ),
      );
    }

    if (cwlWar != null &&
        cwlWar.state == 'inWar' &&
        cwlWar.isPlayerInWar(tag, clanTag)) {
      metrics.add(
        TodoProgressMetric(
          label: 'CWL attacks',
          done: cwlWar.getAttacksDoneByPlayer(tag, clanTag),
          total: cwlWar.attacksPerMember ?? 1,
        ),
      );
    } else if (isInTimeFrameForCwl() && memberCwl.attacksAvailable > 0) {
      metrics.add(
        TodoProgressMetric(
          label: 'CWL attacks',
          done: memberCwl.attacksDone,
          total: memberCwl.attacksAvailable,
        ),
      );
    }

    if (isInTimeFrameForClanGames()) {
      final required = requiredClanGamesPoints;
      final ratio = required <= 0
          ? 1.0
          : (currentClanGamesPoints / required).clamp(0.0, 1.0);
      metrics.add(
        TodoProgressMetric(
          label: 'Clan Games',
          done: currentClanGamesPoints,
          total: required,
          progressDone: ratio * 2,
          progressTotal: 2,
        ),
      );
    }

    if (isInTimeFrameForRaid()) {
      metrics.add(
        TodoProgressMetric(
          label: 'Raid attacks',
          done: raids?.attackDone ?? 0,
          total: raids?.attackLimit ?? 5,
        ),
      );
    }

    final requiredSeasonPoints = requiredSeasonPassPoints;
    final seasonRatio = requiredSeasonPoints <= 0
        ? 1.0
        : (currentSeasonPoints / requiredSeasonPoints).clamp(0.0, 1.0);
    metrics.add(
      TodoProgressMetric(
        label: 'Season Pass',
        done: currentSeasonPoints,
        total: requiredSeasonPoints,
        progressDone: seasonRatio * 2,
        progressTotal: 2,
      ),
    );

    return metrics;
  }
}

class TodoProgressMetric {
  final String label;
  final int done;
  final int total;
  final num progressDone;
  final num progressTotal;

  const TodoProgressMetric({
    required this.label,
    required this.done,
    required this.total,
    num? progressDone,
    num? progressTotal,
  }) : progressDone = progressDone ?? done,
       progressTotal = progressTotal ?? total;

  double get progressRatio {
    if (progressTotal == 0) return 1.0;
    return (progressDone / progressTotal).clamp(0.0, 1.0);
  }
}
