import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/functions/functions.dart';
import 'package:clashkingapp/core/services/api_service.dart';
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
  });

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

      Player profile = Player(
        name: json["name"] ?? "Unknown",
        tag: json["tag"] ?? "Unknown",
        townHallLevel: json["townHallLevel"] ?? 0,
        townHallWeaponLevel: json["townHallWeaponLevel"] ?? 0,
        expLevel: json["expLevel"] ?? 0,
        trophies: json["trophies"] ?? 0,
        bestTrophies: json["bestTrophies"] ?? 0,
        attackWins: json["attackWins"] is int ? json["attackWins"] : 0,
        defenseWins: json["defenseWins"] is int ? json["defenseWins"] : 0,
        warStars: json["warStars"] is int ? json["warStars"] : 0,
        builderHallLevel: json["builderHallLevel"] ?? 0,
        builderBaseTrophies: json["builderBaseTrophies"] ?? 0,
        bestBuilderBaseTrophies: json["bestBuilderBaseTrophies"] ?? 0,
        clanTag: json["clan"]["tag"] ?? "",
        clanOverview: json["clan"] != null
            ? PlayerClanOverview.fromJson(json["clan"])
            : PlayerClanOverview.empty(),
        role: json["role"] ?? "",
        warPreference: json["warPreference"] ?? "",
        donations: json["donations"] is int ? json["donations"] : 0,
        donationsReceived:
            json["donationsReceived"] is int ? json["donationsReceived"] : 0,
        clanCapitalContributions: json["clanCapitalContributions"] is int
            ? json["clanCapitalContributions"]
            : 0,
        league: json["league"]?['name'] ?? "",
        townHallPic: ImageAssets.townHall(json["townHallLevel"] ?? 0),
        builderHallPic: ImageAssets.builderHall(json["builderHallLevel"] ?? 0),
        leagueUrl: ApiService.cocAssetsProxyUrl(
            json['league']?['iconUrls']?['medium'] ?? ""),
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
              ?.where((x) =>
                  x['village'] == 'home' &&
                  !GameDataService.isSuperTroop(x['name']) &&
                  !GameDataService.isSiegeMachine(x['name']) &&
                  !GameDataService.isPet(x['name']))
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
              ?.where((x) =>
                  x['village'] == 'home' &&
                  GameDataService.isSuperTroop(x['name']))
              .toList(),
          gameData: filterGameData(
            GameDataService.troopsData['troops'],
            (k, v) => v['type'] == 'troop' && GameDataService.isSuperTroop(k),
          ),
          factory: PlayerSuperTroop.fromRaw,
        ),
        siegeMachines: generateCompleteItemList<PlayerSiegeMachine>(
          jsonList: (json['troops'] as List?)
              ?.where((x) =>
                  x['village'] == 'home' &&
                  GameDataService.isSiegeMachine(x['name']))
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
              ?.where((x) =>
                  x['village'] == 'home' && GameDataService.isPet(x['name']))
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
          gameData: GameDataService.spellsData['spells'] ?? {},
          factory: PlayerSpell.fromRaw,
        ),
        equipments: generateCompleteItemList<PlayerEquipment>(
          jsonList: json['heroEquipment'] as List?,
          gameData: GameDataService.gearsData['gears'] ?? {},
          factory: PlayerEquipment.fromRaw,
        ),
        achievements: List<PlayerAchievement>.from(json['achievements']
            .map((x) => PlayerAchievement.fromJson(x ?? {}))),
        legendsBySeason: null,
        legendRanking: [],
        rankings: null,
        warData: json['war_data'] != null &&
                json['war_data']["currentWarInfo"] != null
            ? WarInfo.fromJson(json['war_data']["currentWarInfo"])
            : null,
      );

      return profile;
    } catch (e, stacktrace) {
      print("❌ Exception in Player.fromJson: $e");
      print(stacktrace);
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
          achievements: [],
          clanTag: "",
          clanOverview: PlayerClanOverview.empty(),
          role: "",
          warPreference: "",
          donations: 0,
          donationsReceived: 0,
          clanCapitalContributions: 0,
          league: "",
          townHallPic: "",
          builderHallPic: "",
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
          rankings: null);
    }
  }

  void enrichWithFullStats(Map<String, dynamic> json) {
    print(json['raid_data']);
    clanGamesPoint =
        (json['clan_games'] as Map<String, dynamic>?)?.entries.map((entry) {
              return PlayerClanGames.fromJson(entry.key, entry.value);
            }).toList() ??
            [];

    seasonPass =
        (json['season_pass'] as Map<String, dynamic>?)?.entries.map((entry) {
              return PlayerSeasonPass(
                season: entry.key,
                points: entry.value ?? 0,
              );
            }).toList() ??
            [];

    lastOnline = json['last_online'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['last_online'] * 1000,
            isUtc: true)
        : DateTime.utc(1970, 1, 1);

    legendsBySeason = json['legends_by_season'] != null
        ? PlayerLegendStats.fromJson(json['legends_by_season'])
        : null;

    legendRanking = (json['legend_eos_ranking'] as List<dynamic>?)
            ?.map((x) => PlayerLegendRanking.fromJson(x))
            .toList() ??
        [];

    rankings = json['rankings'] != null
        ? PlayerRankings.fromJson(json['rankings'])
        : null;
    raids = json['raid_data'] != null && (json['raid_data'] as Map).isNotEmpty
        ? PlayerRaids.fromJson(json['raid_data'])
        : PlayerRaids.empty();
  }

  String getLastOnlineText(BuildContext context) {
    final now = DateTime.now().toUtc();
    final diff = now.difference(lastOnline);

    final loc = AppLocalizations.of(context)!;

    if (diff.inSeconds < 60) {
      return loc.justNow;
    } else if (diff.inMinutes < 60) {
      final minutes = diff.inMinutes;
      return minutes == 1 ? loc.minuteAgo(minutes) : loc.minutesAgo(minutes);
    } else if (diff.inHours < 24) {
      final hours = diff.inHours;
      return hours == 1 ? loc.hourAgo(hours) : loc.hoursAgo(hours, hours);
    } else {
      final days = diff.inDays;
      return days == 1 ? loc.dayAgo(days) : loc.daysAgo(days);
    }
  }

  /// Returns a progress ratio between 0.0 and 1.0 based on player's to-do completion
  double getTodoProgressRatio({required WarMemberPresence memberCwl}) {
    double totalDone = 0;
    double totalEvent = 0;

    // Legend League
    if (league == 'Legend League') {
      totalEvent += 8;
      totalDone +=
          currentLegendSeason!.currentDay?.totalAttacks.toDouble() ?? 0.0;
    }

    // CWL (guerres de ligue)
    if (memberCwl.attacksAvailable != 0) {
      totalEvent += memberCwl.attacksAvailable.toDouble();
      totalDone += memberCwl.attacksDone.toDouble();
    }

    // Clan Games
    if (isInTimeFrameForClanGames()) {
      DateTime now = DateTime.now();
      DateTime clanGamesStart = DateTime(now.year, now.month, 22, 8);
      int daysPassed = now.difference(clanGamesStart).inDays + 1;
      double clanGamesDaily = (4000 / 8) * daysPassed;
      double clanGamesRatio =
          (currentClanGamesPoints / clanGamesDaily).clamp(0, 1);
      totalEvent += 2;
      totalDone += clanGamesRatio * 2;
    }

    // Season Pass
    DateTime now = DateTime.now();
    int totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;
    int daysPassed = now.day;
    double seasonPassDaily = ((daysPassed * 2600) / totalDaysInMonth);
    double seasonPassRatio =
        (currentSeasonPoints / seasonPassDaily).clamp(0, 1);
    totalEvent += 2;
    totalDone += seasonPassRatio * 2;

    // Raids
    if (isInTimeFrameForRaid()) {
      totalEvent += raids?.attackLimit ?? 0.0;
      totalDone += raids?.attackDone ?? 0.0;
    }

    if (totalEvent == 0) return 0.0;
    return (totalDone / totalEvent).clamp(0.0, 1.0);
  }
}
