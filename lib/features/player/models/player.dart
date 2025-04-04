import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/player/models/player_bb_hero.dart';
import 'package:clashkingapp/features/player/models/player_bb_troop.dart';
import 'package:clashkingapp/features/player/models/player_equipment.dart';
import 'package:clashkingapp/features/player/models/player_hero.dart';
import 'package:clashkingapp/features/player/models/player_legend_ranking.dart';
import 'package:clashkingapp/features/player/models/player_legend_season.dart';
import 'package:clashkingapp/features/player/models/player_legend_stats.dart';
import 'package:clashkingapp/features/player/models/player_pet.dart';
import 'package:clashkingapp/features/player/models/player_rankings.dart';
import 'package:clashkingapp/features/player/models/player_siege_machine.dart';
import 'package:clashkingapp/features/player/models/player_spell.dart';
import 'package:clashkingapp/features/player/models/player_super_troop.dart';
import 'package:clashkingapp/features/player/models/player_troop.dart';

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
  String clanTag;
  Clan? clan;
  String role;
  String warPreference;
  int donations;
  int donationsReceived;
  int clanCapitalContributions;
  String league;
  String townHallPic;
  String builderHallPic;
  String leagueUrl;
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
  final List<PlayerLegendRanking> legendRanking;
  final PlayerRankings? rankings;

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
    required this.clanTag,
    required this.role,
    required this.warPreference,
    required this.donations,
    required this.donationsReceived,
    required this.clanCapitalContributions,
    required this.league,
    required this.townHallPic,
    required this.builderHallPic,
    required this.leagueUrl,
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
  });

  String get donationRatio => donationsReceived == 0
      ? "0.0"
      : (donations / donationsReceived).toStringAsFixed(2);

  String get warPreferenceImage => warPreference == "in"
      ? ImageAssets.warPreferenceIn
      : ImageAssets.warPreferenceOut;

  PlayerLegendSeason? get currentLegendSeason => legendsBySeason?.currentSeason;

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
        warStars: json["warStars"] ?? 0,
        attackWins: json["attackWins"] ?? 0,
        defenseWins: json["defenseWins"] ?? 0,
        builderHallLevel: json["builderHallLevel"] ?? 0,
        builderBaseTrophies: json["builderBaseTrophies"] ?? 0,
        bestBuilderBaseTrophies: json["bestBuilderBaseTrophies"] ?? 0,
        clanTag: json["clan"]?["tag"] ?? "",
        role: json["role"] ?? "",
        warPreference: json["warPreference"] ?? "",
        donations: json["donations"] ?? 0,
        donationsReceived: json["donationsReceived"] ?? 0,
        clanCapitalContributions: json["clanCapitalContributions"] ?? 0,
        league: json["league"]?["name"] ?? "",
        townHallPic: ImageAssets.townHall(json["townHallLevel"] ?? 0),
        builderHallPic: ImageAssets.builderHall(json["builderHallLevel"] ?? 0),
        leagueUrl: ApiService.cocAssetsProxyUrl(json["league"]?["iconUrls"]?["medium"] ?? ""),
        heroes: (json['heroes'] as List)
            .where((x) => x['village'] == 'home')
            .map((x) => PlayerHero.fromJson(x))
            .toList(),
        bbHeroes: (json['heroes'] as List)
            .where((x) => x['village'] == 'builderBase')
            .map((x) => PlayerBuilderBaseHero.fromJson(x))
            .toList(),
        troops: troops,
        superTroops: superTroops,
        siegeMachines: siegeMachines,
        pets: pets,
        bbTroops: bbTroops,
        spells: (json['spells'] as List<dynamic>?)
                ?.map((x) => PlayerSpell.fromJson(x ?? {}))
                .toList() ??
            [],
        equipments: (json['heroEquipment'] as List<dynamic>?)
                ?.map((x) => PlayerEquipment.fromJson(x ?? {}))
                .toList() ??
            [],
        legendsBySeason: json['legends_by_season'] != null
            ? PlayerLegendStats.fromJson(json['legends_by_season'])
            : null,
        legendRanking: (json['legend_eos_ranking'] as List<dynamic>?)
                ?.map((x) => PlayerLegendRanking.fromJson(x ?? {}))
                .toList() ??
            [],
        rankings: json['rankings'] != null
            ? PlayerRankings.fromJson(json['rankings'])
            : null,
      );

      return profile;
    } catch (e, stacktrace) {
      print("❌ Exception in ProfileInfo.fromJson: $e");
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
        clanTag: "",
        role: "",
        warPreference: "",
        donations: 0,
        donationsReceived: 0,
        clanCapitalContributions: 0,
        league: "",
        townHallPic: "",
        builderHallPic: "",
        leagueUrl: "",
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
        rankings: null
      );
    }
  }
}
