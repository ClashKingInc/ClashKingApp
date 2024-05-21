import 'dart:convert';
import 'package:clashkingapp/api/clan_info.dart';
import 'package:clashkingapp/api/current_war_info.dart';
import 'package:clashkingapp/api/discord_user_info.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:clashkingapp/api/player_accounts_list.dart';
import 'package:clashkingapp/data/troop_data.dart';
import 'package:clashkingapp/data/league_data.dart';

class PlayerAccountInfo {
  final String name;
  final String tag;
  final int townHallLevel;
  final int townHallWeaponLevel;
  final int expLevel;
  final int trophies;
  final int bestTrophies;
  final int warStars;
  final int attackWins;
  final int defenseWins;
  final int builderHallLevel;
  final int builderBaseTrophies;
  final int bestBuilderBaseTrophies;
  final String role;
  final String warPreference;
  final int donations;
  final int donationsReceived;
  final int clanCapitalContributions;
  final Clan? clan;
  final List<Achievement> achievements;
  final List<Hero> heroes;
  final List<Troop> troops;
  final List<Spell> spells;
  final List<Equipment> equipments;
  String league = '';
  String townHallPic = '';
  String builderHallPic = '';
  String leagueUrl = '';

  PlayerAccountInfo({
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
    required this.role,
    required this.warPreference,
    required this.donations,
    required this.donationsReceived,
    required this.clanCapitalContributions,
    required this.clan,
    required this.achievements,
    required this.heroes,
    required this.troops,
    required this.spells,
    required this.equipments,
  });

  factory PlayerAccountInfo.fromJson(Map<String, dynamic> json) {
    return PlayerAccountInfo(
      name: json['name'] ?? 'No name',
      tag: json['tag'] ?? 'No tag',
      townHallLevel: json['townHallLevel'] ?? 0,
      townHallWeaponLevel: json['townHallWeaponLevel'] ?? 0,
      expLevel: json['expLevel'] ?? 0,
      trophies: json['trophies'] ?? 0,
      bestTrophies: json['bestTrophies'] ?? 0,
      warStars: json['warStars'] ?? 0,
      attackWins: json['attackWins'] ?? 0,
      defenseWins: json['defenseWins'] ?? 0,
      builderHallLevel: json['builderHallLevel'] ?? 0,
      builderBaseTrophies: json['builderBaseTrophies'] ?? 0,
      bestBuilderBaseTrophies: json['bestBuilderBaseTrophies'] ?? 0,
      role: json['role'] ?? 'No role',
      warPreference: json['warPreference'] ?? 'No preference',
      donations: json['donations'] ?? 0,
      donationsReceived: json['donationsReceived'] ?? 0,
      clanCapitalContributions: json['clanCapitalContributions'] ?? 0,
      clan: json['clan'] != null ? Clan.fromJson(json['clan']) : null,
      achievements: List<Achievement>.from(
          json['achievements'].map((x) => Achievement.fromJson(x ?? {}))),
      heroes:
          List<Hero>.from(json['heroes'].map((x) => Hero.fromJson(x)) ?? []),
      troops:
          List<Troop>.from(json['troops'].map((x) => Troop.fromJson(x)) ?? []),
      spells:
          List<Spell>.from(json['spells'].map((x) => Spell.fromJson(x)) ?? []),
      equipments: List<Equipment>.from(
          json['heroEquipment'].map((x) => Equipment.fromJson(x)) ?? []),
    );
  }
}

class Clan {
  final String tag;
  final String name;
  final int clanLevel;
  final BadgeUrls badgeUrls;

  Clan(
      {required this.tag,
      required this.name,
      required this.clanLevel,
      required this.badgeUrls});

  factory Clan.fromJson(Map<String, dynamic> json) {
    return Clan(
      tag: json['tag'],
      name: json['name'],
      clanLevel: json['clanLevel'],
      badgeUrls: BadgeUrls.fromJson(json['badgeUrls']),
    );
  }
}

class BadgeUrls {
  final String small;
  final String large;
  final String medium;

  BadgeUrls({
    required this.small,
    required this.large,
    required this.medium,
  });

  factory BadgeUrls.fromJson(Map<String, dynamic> json) {
    return BadgeUrls(
      small: json['small'],
      large: json['large'],
      medium: json['medium'],
    );
  }
}

class Achievement {
  final String name;
  final int stars;
  final int value;
  final int target;
  final String info;
  final String completionInfo;
  final String village;

  Achievement(
      {required this.name,
      required this.stars,
      required this.value,
      required this.target,
      this.info = '',
      this.completionInfo = '',
      this.village = ''});

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      name: json['name'] ?? 'No name',
      stars: json['stars'] ?? 0,
      value: json['value'] ?? 0,
      target: json['target'] ?? 0,
      info: json['info'] ?? '',
      completionInfo: json['completionInfo'] ?? '',
      village: json['village'] ?? 'home',
    );
  }
}

class Hero {
  final String name;
  final int level;
  final int maxLevel;
  final String village;
  final List<EquipedEquipment> equipment;
  late String imageUrl;
  late String type;

  Hero(
      {required this.name,
      required this.level,
      required this.maxLevel,
      required this.village,
      required this.equipment});

  factory Hero.fromJson(Map<String, dynamic> json) {
    return Hero(
      name: json['name'] ?? 'No name',
      level: json['level'] ?? 0,
      maxLevel: json['maxLevel'] ?? 0,
      village: json['village'] ?? 'home',
      equipment: json['equipment'] != null
          ? List<EquipedEquipment>.from(
              json['equipment'].map((x) => EquipedEquipment.fromJson(x)))
          : [],
    );
  }
}

class EquipedEquipment {
  final String name;
  final int level;
  final int maxLevel;
  final String village;
  String imageUrl;
  late String type;

  EquipedEquipment(
      {required this.name,
      required this.level,
      required this.maxLevel,
      required this.village,
      this.imageUrl = 'https://clashkingfiles.b-cdn.net/clashkinglogo.png'});

  factory EquipedEquipment.fromJson(Map<String, dynamic> json) {
    return EquipedEquipment(
      name: json['name'] ?? 'No name',
      level: json['level'] ?? 0,
      maxLevel: json['maxLevel'] ?? 0,
      village: json['village'] ?? 'home',
      imageUrl: json['imageUrl'] ??
          'https://clashkingfiles.b-cdn.net/clashkinglogo.png',
    );
  }
}

class Equipment {
  final String name;
  final int level;
  final int maxLevel;
  final String village;
  late String imageUrl;
  late String type;

  Equipment(
      {required this.name,
      required this.level,
      required this.maxLevel,
      required this.village});

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      name: json['name'] ?? 'No name',
      level: json['level'] ?? 0,
      maxLevel: json['maxLevel'] ?? 0,
      village: json['village'] ?? 'home',
    );
  }
}

class Troop {
  final String name;
  final int level;
  final int maxLevel;
  final String village;
  final bool superTroopIsActive;
  late String imageUrl;
  late String type;

  Troop(
      {required this.name,
      required this.level,
      required this.maxLevel,
      required this.superTroopIsActive,
      required this.village});

  factory Troop.fromJson(Map<String, dynamic> json) {
    String name = json['name'] ?? 'No name';
    if (name == 'Baby Dragon' && json['village'] == 'builderBase') {
      name = 'Baby Dragon 2';
    }

    return Troop(
      name: name,
      level: json['level'] ?? 0,
      maxLevel: json['maxLevel'] ?? 0,
      superTroopIsActive: json['superTroopIsActive'] ?? false,
      village: json['village'] ?? 'home',
    );
  }
}

class Spell {
  final String name;
  final int level;
  final int maxLevel;
  final String village;
  late String imageUrl;
  late String type;

  Spell(
      {required this.name,
      required this.level,
      required this.maxLevel,
      required this.village});

  factory Spell.fromJson(Map<String, dynamic> json) {
    return Spell(
      name: json['name'] ?? 'No name',
      level: json['level'] ?? 0,
      maxLevel: json['maxLevel'] ?? 0,
      village: json['village'] ?? 'home',
    );
  }
}

// Service

class PlayerService {
  Future<void> initEnv() async {
    await dotenv.load(fileName: ".env");
  }

  Future<PlayerAccounts> fetchPlayerAccounts(DiscordUser user) async {
    PlayerAccounts playerAccounts =
        PlayerAccounts(playerAccountInfo: [], clanInfo: [], warInfo: []);
    ClanInfo? clanInfo;
    List<Future> futures = [];
    final tags = user.tags;

    // Fetch all player stats, clan info and current war info for each player at the same time
    for (int i = 0; i < tags.length; i++) {
      futures.add(
        fetchPlayerStats(tags[i]).then((playerStats) async {
          if (!user.selectedTagDetails
              .any((details) => details['tag'] == playerStats.tag)) {
            user.selectedTagDetails.add({
              'tag': playerStats.tag,
              'imageUrl': playerStats.townHallPic,
              'name': playerStats.name,
              'townHallLevel': playerStats.townHallLevel,
            });
          }
          playerAccounts.playerAccountInfo.add(playerStats);

          if (playerStats.clan != null && playerStats.clan!.tag.isNotEmpty) {
            var results = await Future.wait<dynamic>([
              fetchClanInfo(playerStats.clan!.tag),
              //fetchCurrentWarInfo(playerStats.clan.tag),
            ]);
            clanInfo = results[0] as ClanInfo;
            playerAccounts.clanInfo!.add(clanInfo!);
          } 

          /*warInfo = results[1] as CurrentWarInfo;
          playerAccounts.warInfo.add(warInfo);*/
        }),
      );
    }

    await Future.wait(futures);

    // Remove any selected tag details that are not in the player accounts list anymore
    user.selectedTagDetails.removeWhere((details) {
      return !playerAccounts.playerAccountInfo
          .any((playerStats) => playerStats.tag == details['tag']);
    });

    return playerAccounts;
  }

  Future<PlayerAccountInfo> fetchPlayerStats(String tag) async {
    tag = tag.replaceAll('#', '!');

    final response = await http.get(
      Uri.parse('https://api.clashking.xyz/v1/players/$tag'),
    );

    if (response.statusCode == 200) {
      String responseBody = utf8.decode(response.bodyBytes);
      PlayerAccountInfo playerStats =
          PlayerAccountInfo.fromJson(jsonDecode(responseBody));
      playerStats.townHallPic =
          await fetchPlayerTownHallByTownHallLevel(playerStats.townHallLevel);

      playerStats.leagueUrl = await fetchLeagueImageUrl(playerStats.league);

      playerStats.builderHallPic = await fetchPlayerBuilderHallByTownHallLevel(
          playerStats.builderHallLevel);
      await fetchImagesAndTypes(playerStats.troops);
      await fetchImagesAndTypes(playerStats.heroes);
      await fetchImagesAndTypes(playerStats.spells);
      await fetchImagesAndTypes(playerStats.equipments);
      print(playerStats.tag);
      playerStats.league = await fetchLeagueName(playerStats.tag);
      playerStats.leagueUrl = await fetchLeagueImageUrl(playerStats.league);
      return playerStats;
    } else {
      throw Exception('Failed to load player stats');
    }
  }

  Future<String> fetchPlayerTownHallByTownHallLevel(int townHallLevel) async {
    String townHallPic;
    if (townHallLevel >= 1 && townHallLevel <= 16) {
      townHallPic =
          'https://clashkingfiles.b-cdn.net/home-base/town-hall-pics/town-hall-$townHallLevel.png';
    } else {
      townHallPic =
          'https://clashkingfiles.b-cdn.net/home-base/town-hall-pics/town-hall-16.png';
    }
    return townHallPic;
  }

  Future<String> fetchPlayerBuilderHallByTownHallLevel(
      int builderHallLevel) async {
    String builderHallPic;
    if (builderHallLevel >= 1 && builderHallLevel <= 10) {
      builderHallPic =
          'https://clashkingfiles.b-cdn.net/builder-base/builder-hall-pics/Building_BB_Builder_Hall_level_$builderHallLevel.png';
    } else {
      builderHallPic =
          'https://clashkingfiles.b-cdn.net/builder-base/builder-hall-pics/Building_BB_Builder_Hall_level_8.png';
    }

    return builderHallPic;
  }

  Future<ClanInfo> fetchClanInfo(String tag) async {
    tag = tag.replaceAll('#', '!');

    final response = await http.get(
      Uri.parse('https://api.clashking.xyz/v1/clans/$tag'),
    );

    if (response.statusCode == 200) {
      String responseBody = utf8.decode(response.bodyBytes);
      ClanInfo clanInfo = ClanInfo.fromJson(jsonDecode(responseBody));
      clanInfo.warLeague.imageUrl =
          await fetchLeagueImageUrl(clanInfo.warLeague.name);

      return clanInfo;
    } else {
      throw Exception('Failed to load clan stats');
    }
  }

  Future<String> fetchLeagueImageUrl(String name) async {
    if (leaguesUrls.containsKey(name)) {
      // If the league name is in the map, return the corresponding URL and type
      return leaguesUrls[name]!['url']!;
    } else {
      // If the league name is not in the map, return default image URL and type
      return 'https://clashkingfiles.b-cdn.net/clashkinglogo.png';
    }
  }

  Future<String> fetchLeagueName(String tag) async {
    tag = tag.replaceAll('#', '!');

    final response = await http.get(
      Uri.parse('https://api.clashking.xyz/player/$tag/stats'),
    );

    if (response.statusCode == 200) {
      String responseBody = utf8.decode(response.bodyBytes);
      return jsonDecode(responseBody)['league'] ?? "Unranked";
    } else {
      return "Unranked";
    }
  }

  Future<CurrentWarInfo> fetchCurrentWarInfo(String clanTag) async {
    clanTag = clanTag.replaceAll('#', '!');
    final response = await http.get(
      Uri.parse('https://api.clashking.xyz/v1/clans/$clanTag/currentwar'),
    );

    if (response.statusCode == 200) {
      String responseBody = utf8.decode(response.bodyBytes);
      CurrentWarInfo warInfo =
          CurrentWarInfo.fromJson(jsonDecode(responseBody), "war");
      return warInfo;
    } else {
      throw Exception('Failed to load current war info');
    }
  }

  Future<void> fetchImagesAndTypes(List<dynamic> items) async {
    for (var item in items) {
      Map<String, String> urlAndType = await fetchTroopImageUrl(item.name);
      item.imageUrl = urlAndType['url'] ??
          'https://clashkingfiles.b-cdn.net/clashkinglogo.png';
      item.type = urlAndType['type'] ?? 'unknown';
    }
  }

  Future<Map<String, String>> fetchTroopImageUrl(String name) async {
    if (troopUrlsAndTypes.containsKey(name)) {
      // If the troop name is in the map, return the corresponding URL and type
      return troopUrlsAndTypes[name]!;
    } else {
      // If the troop name is not in the map, return default image URL and type
      return {
        'url': 'https://clashkingfiles.b-cdn.net/clashkinglogo.png',
        'type': 'unknown',
      };
    }
  }
}
