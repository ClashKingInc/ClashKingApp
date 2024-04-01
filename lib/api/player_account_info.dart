import 'dart:convert';
import 'package:clashkingapp/api/clan_info.dart';
import 'package:clashkingapp/api/current_war_info.dart';
import 'package:clashkingapp/api/discord_user_info.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:clashkingapp/api/player_accounts_list.dart';
import 'package:clashkingapp/data/troop_data.dart';

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
  final Clan clan;
  final League league;
  final List<Achievement> achievements;
  final List<Hero> heroes;
  final List<Troop> troops;
  final List<Spell> spells;
  String townHallPic = '';
  String builderHallPic = '';

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
    required this.league,
    required this.achievements,
    required this.heroes,
    required this.troops,
    required this.spells,
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
      clan: Clan.fromJson(json['clan'] ?? {}),
      league: League.fromJson(json['league'] ?? {}),
      achievements: List<Achievement>.from(
          json['achievements'].map((x) => Achievement.fromJson(x ?? {}))),
      heroes:
          List<Hero>.from(json['heroes'].map((x) => Hero.fromJson(x)) ?? []),
      troops:
          List<Troop>.from(json['troops'].map((x) => Troop.fromJson(x)) ?? []),
      spells:
          List<Spell>.from(json['spells'].map((x) => Spell.fromJson(x)) ?? []),
    );
  }
}

class Clan {
  final String tag;
  final String name;
  final int clanLevel;
  final BadgeUrls badgeUrls;

  Clan({required this.tag, required this.name, required this.clanLevel, required this.badgeUrls});

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

class League {
  final String name;
  // Include URLs for icons if needed

  League({required this.name});

  factory League.fromJson(Map<String, dynamic> json) {
    return League(
      name: json['name'] ?? 'No name',
      // Initialize URLs for icons from JSON if needed
    );
  }
}

class Achievement {
  final String name;
  final int stars;
  final int value;
  final int target;
  // Include other fields if needed

  Achievement(
      {required this.name,
      required this.stars,
      required this.value,
      required this.target});

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      name: json['name'] ?? 'No name',
      stars: json['stars'] ?? 0,
      value: json['value'] ?? 0,
      target: json['target'] ?? 0,
      // Initialize other fields from JSON if needed
    );
  }
}

class Hero {
  final String name;
  final int level;
  final int maxLevel;
  final String village;
  late String imageUrl;
  late String type;

  Hero(
      {required this.name,
      required this.level,
      required this.maxLevel,
      required this.village});

  factory Hero.fromJson(Map<String, dynamic> json) {
    return Hero(
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
  late String imageUrl;
  late String type;

  Troop(
      {required this.name,
      required this.level,
      required this.maxLevel,
      required this.village});

  factory Troop.fromJson(Map<String, dynamic> json) {
    String name = json['name'] ?? 'No name';
    print(json['name']);
    print(json['village']);
    if (name == 'Baby Dragon' && json['village'] == 'builderBase') {
      name = 'Baby Dragon 2';
    }

    return Troop(
      name: name,
      level: json['level'] ?? 0,
      maxLevel: json['maxLevel'] ?? 0,
      village: json['village'] ?? 'home',
    );
  }
}

class Spell {
  final String name;
  final int level;
  final int maxLevel;
  final String village; // "home" or "builderBase"
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
    ClanInfo clanInfo;
    CurrentWarInfo warInfo;
    List<Future> futures = [];
    final tags = user.tags;

    // Fetch all player stats, clan info and current war info for each player at the same time
    for (int i = 0; i < tags.length; i++) {
      futures.add(
        fetchPlayerStats(tags[i]).then((playerStats) async {
          user.selectedTagDetails.add({
            'tag': playerStats.tag,
            'imageUrl': playerStats.townHallPic,
            'name': playerStats.name,
            'townHallLevel': playerStats.townHallLevel,
          });
          playerAccounts.playerAccountInfo.add(playerStats);

          var results = await Future.wait<dynamic>([
            fetchClanInfo(playerStats.clan.tag),
            fetchCurrentWarInfo(playerStats.clan.tag),
          ]);
          clanInfo = results[0] as ClanInfo;
          playerAccounts.clanInfo.add(clanInfo);

          warInfo = results[1] as CurrentWarInfo;
          playerAccounts.warInfo.add(warInfo);
        }),
      );
    }

    await Future.wait(futures);
    return playerAccounts;
  }

  Future<PlayerAccountInfo> fetchPlayerStats(String tag) async {
    print('Fetching player stats');
    tag = tag.replaceAll('#', '!');

    final response = await http.get(
      Uri.parse('https://api.clashking.xyz/v1/players/$tag'),
    );

    print('Response status: ${response.statusCode}'); // Print response status
    print('Response body: ${response.body}'); // Print response body

    if (response.statusCode == 200) {
      String responseBody = utf8.decode(response.bodyBytes);
      PlayerAccountInfo playerStats =
          PlayerAccountInfo.fromJson(jsonDecode(responseBody));
      playerStats.townHallPic =
          await fetchPlayerTownHallByTownHallLevel(playerStats.townHallLevel);

      playerStats.builderHallPic = await fetchPlayerBuilderHallByTownHallLevel(
          playerStats.builderHallLevel);
      await fetchImagesAndTypes(playerStats.troops);
      await fetchImagesAndTypes(playerStats.heroes);
      await fetchImagesAndTypes(playerStats.spells);
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

  Future<ClanInfo> fetchClanInfo(String clanTag) async {
    print('Fetching clan info');
    clanTag = clanTag.replaceAll('#', '!');
    final response = await http.get(
      Uri.parse('https://api.clashking.xyz/v1/clans/$clanTag'),
    );

    print('Response status: ${response.statusCode}'); // Print response status
    print('Response body: ${response.body}'); // Print response body

    if (response.statusCode == 200) {
      String responseBody = utf8.decode(response.bodyBytes);
      ClanInfo clanInfo = ClanInfo.fromJson(jsonDecode(responseBody));
      return clanInfo;
    } else {
      throw Exception('Failed to load clan info');
    }
  }

  Future<CurrentWarInfo> fetchCurrentWarInfo(String clanTag) async {
    print('Fetching current war info');
    clanTag = clanTag.replaceAll('#', '!');
    final response = await http.get(
      Uri.parse('https://api.clashking.xyz/v1/clans/$clanTag/currentwar'),
    );

    print('Response status: ${response.statusCode}'); // Print response status
    print('Response body: ${response.body}'); // Print response body

    if (response.statusCode == 200) {
      String responseBody = utf8.decode(response.bodyBytes);
      CurrentWarInfo warInfo =
          CurrentWarInfo.fromJson(jsonDecode(responseBody));
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
