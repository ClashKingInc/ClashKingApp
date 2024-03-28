import 'dart:convert';

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
      name: json['name'],
      tag: json['tag'],
      townHallLevel: json['townHallLevel'],
      townHallWeaponLevel: json['townHallWeaponLevel'],
      expLevel: json['expLevel'],
      trophies: json['trophies'],
      bestTrophies: json['bestTrophies'],
      warStars: json['warStars'],
      attackWins: json['attackWins'],
      defenseWins: json['defenseWins'],
      builderHallLevel: json['builderHallLevel'],
      builderBaseTrophies: json['builderBaseTrophies'],
      bestBuilderBaseTrophies: json['bestBuilderBaseTrophies'],
      role: json['role'],
      warPreference: json['warPreference'],
      donations: json['donations'],
      donationsReceived: json['donationsReceived'],
      clanCapitalContributions: json['clanCapitalContributions'],
      clan: Clan.fromJson(json['clan']),
      league: League.fromJson(json['league']),
      achievements: List<Achievement>.from(json['achievements'].map((x) => Achievement.fromJson(x))),
      heroes: List<Hero>.from(json['heroes'].map((x) => Hero.fromJson(x))),
      troops: List<Troop>.from(json['troops'].map((x) => Troop.fromJson(x))),
      spells: List<Spell>.from(json['spells'].map((x) => Spell.fromJson(x))),
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
      name: json['name'],
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
      name: json['name'],
      stars: json['stars'],
      value: json['value'],
      target: json['target'],
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
      name: json['name'],
      level: json['level'],
      maxLevel: json['maxLevel'],
      village: json['village'],
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
      name: json['name'],
      level: json['level'],
      maxLevel: json['maxLevel'],
      village: json['village'],
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
      name: json['name'],
      level: json['level'],
      maxLevel: json['maxLevel'],
      village: json['village'],
    );
  }
}
