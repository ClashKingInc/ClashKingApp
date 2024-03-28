import 'dart:convert';
import 'package:clashkingapp/api/clan_info.dart';
import 'package:clashkingapp/api/current_war_info.dart';


class PlayerAccounts {
  final List<PlayerStats> items;
  final List<ClanInfo> clanInfo;
  final List<CurrentWarInfo> warInfo;

  PlayerAccounts({required this.items, required this.clanInfo, required this.warInfo});

  factory PlayerAccounts.fromJson(List<dynamic> json) {
    List<PlayerStats> playerAccounts = [];
    List<ClanInfo> clanInfo = [];
    List<CurrentWarInfo> warInfo = [];
    PlayerStats playerInfo;

    for (var item in json) {
      playerAccounts.add(PlayerStats.fromJson(item));
      ClanInfo clan = ClanInfo.fromJson(item['clan']);
      clanInfo.add(clan);
      CurrentWarInfo war = CurrentWarInfo.fromJson(item['clan']['currentWar']);
      warInfo.add(war);

      print('Player name: ${item['name']}');
    }

    return PlayerAccounts(items: playerAccounts, clanInfo: clanInfo, warInfo: warInfo);
  }
}

class PlayerStats {
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


  PlayerStats({
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

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
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
      achievements: List<Achievement>.from(json['achievements'].map((x) => Achievement.fromJson(x ?? {}))),
      heroes: List<Hero>.from(json['heroes'].map((x) => Hero.fromJson(x)) ?? []),
      troops: List<Troop>.from(json['troops'].map((x) => Troop.fromJson(x)) ?? []),
      spells: List<Spell>.from(json['spells'].map((x) => Spell.fromJson(x)) ?? []),     
    );
  }
}

class Clan {
  final String tag;
  final String name;
  final int clanLevel;
  // Include URLs for badges if needed

  Clan({required this.tag, required this.name, required this.clanLevel});

  factory Clan.fromJson(Map<String, dynamic> json) {
    return Clan(
      tag: json['tag'],
      name: json['name'],
      clanLevel: json['clanLevel'],
      // Initialize URLs for badges from JSON if needed
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

  Achievement({required this.name, required this.stars, required this.value, required this.target});

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
  // You can add more attributes like equipment here

  Hero({required this.name, required this.level, required this.maxLevel, required this.village});

  factory Hero.fromJson(Map<String, dynamic> json) {
    return Hero(
      name: json['name'] ?? 'No name',
      level: json['level'] ?? 0,
      maxLevel: json['maxLevel'] ?? 0,
      village: json['village'] ?? 'home',
      // Initialize other attributes from JSON if needed
    );
  }
}


class Troop {
  final String name;
  final int level;
  final int maxLevel;
  final String village; // "home" or "builderBase"

  Troop({required this.name, required this.level, required this.maxLevel, required this.village});

  factory Troop.fromJson(Map<String, dynamic> json) {
    return Troop(
      name: json['name'] ?? 'No name',
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

  Spell({required this.name, required this.level, required this.maxLevel, required this.village});

  factory Spell.fromJson(Map<String, dynamic> json) {
    return Spell(
      name: json['name'] ?? 'No name',
      level: json['level'] ?? 0,
      maxLevel: json['maxLevel'] ?? 0,
      village: json['village']  ?? 'home',
    );
  }
}
