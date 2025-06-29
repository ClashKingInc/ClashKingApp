class CapitalHistoryItems {
  final List<CapitalHistoryItem> items;
  final String? clanTag;
  final CapitalStats? stats;

  CapitalHistoryItems({required this.items, required this.clanTag, this.stats});

  factory CapitalHistoryItems.fromJson(
      Map<String, dynamic> json, String clanTag, {Map<String, dynamic>? statsData}) {
    try {
      return CapitalHistoryItems(
        items: json['history'] != null 
            ? List<CapitalHistoryItem>.from(
                json['history'].map((x) => CapitalHistoryItem.fromJson(x)))
            : [],
        clanTag: clanTag,
        stats: statsData != null ? CapitalStats.fromJson(statsData) : null,
      );
    } catch (e) {
      print("Error parsing CapitalHistoryItems: $e");
      return CapitalHistoryItems.empty();
    }
  }

  factory CapitalHistoryItems.empty() {
    return CapitalHistoryItems(items: [], clanTag: "");
  }
}

class CapitalHistoryItem {
  String state;
  DateTime startTime;
  DateTime endTime;
  int capitalTotalLoot;
  int raidsCompleted;
  int totalAttacks;
  int enemyDistrictsDestroyed;
  int offensiveReward;
  int defensiveReward;
  List<RaidMember>? members;
  List<RaidAttackLog>? attackLog;

  CapitalHistoryItem({
    required this.state,
    required this.startTime,
    required this.endTime,
    required this.capitalTotalLoot,
    required this.raidsCompleted,
    required this.totalAttacks,
    required this.enemyDistrictsDestroyed,
    required this.offensiveReward,
    required this.defensiveReward,
    required this.members,
    required this.attackLog,
  });

  factory CapitalHistoryItem.fromJson(Map<String, dynamic> json) {
    return CapitalHistoryItem(
      state: json['state'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      capitalTotalLoot: json['capitalTotalLoot'],
      raidsCompleted: json['raidsCompleted'],
      totalAttacks: json['totalAttacks'],
      enemyDistrictsDestroyed: json['enemyDistrictsDestroyed'],
      offensiveReward: json['offensiveReward'],
      defensiveReward: json['defensiveReward'],
      members: json['members'] != null
          ? List<RaidMember>.from(
              json['members'].map((x) => RaidMember.fromJson(x)))
          : [],
      attackLog: json['attackLog'] != null
          ? List<RaidAttackLog>.from(
              json['attackLog'].map((x) => RaidAttackLog.fromJson(x)))
          : [],
    );
  }
}

class RaidMember {
  String tag;
  String name;
  int attacks;
  int attackLimit;
  int bonusAttackLimit;
  int capitalResourcesLooted;

  RaidMember({
    required this.tag,
    required this.name,
    required this.attacks,
    required this.attackLimit,
    required this.bonusAttackLimit,
    required this.capitalResourcesLooted,
  });

  factory RaidMember.fromJson(Map<String, dynamic> json) {
    return RaidMember(
      tag: json['tag'],
      name: json['name'],
      attacks: json['attacks'],
      attackLimit: json['attackLimit'],
      bonusAttackLimit: json['bonusAttackLimit'],
      capitalResourcesLooted: json['capitalResourcesLooted'],
    );
  }
}

class RaidAttackLog {
  RaidDefender defender;
  int attackCount;
  int districtCount;
  int districtsDestroyed;
  List<District> districts;

  RaidAttackLog({
    required this.defender,
    required this.attackCount,
    required this.districtCount,
    required this.districtsDestroyed,
    required this.districts,
  });

  factory RaidAttackLog.fromJson(Map<String, dynamic> json) {
    return RaidAttackLog(
      defender: RaidDefender.fromJson(json['defender']),
      attackCount: json['attackCount'],
      districtCount: json['districtCount'],
      districtsDestroyed: json['districtsDestroyed'],
      districts: List<District>.from(
          json['districts'].map((x) => District.fromJson(x))),
    );
  }
}

class RaidDefender {
  String tag;
  String name;
  int level;
  Map<String, String> badgeUrls;

  RaidDefender({
    required this.tag,
    required this.name,
    required this.level,
    required this.badgeUrls,
  });

  factory RaidDefender.fromJson(Map<String, dynamic> json) {
    return RaidDefender(
      tag: json['tag'],
      name: json['name'],
      level: json['level'],
      badgeUrls: Map<String, String>.from(json['badgeUrls']),
    );
  }
}

class District {
  int id;
  String name;
  int districtHallLevel;
  int destructionPercent;
  int stars;
  int attackCount;
  int totalLooted;
  List<Attack>? attacks;

  District({
    required this.id,
    required this.name,
    required this.districtHallLevel,
    required this.destructionPercent,
    required this.stars,
    required this.attackCount,
    required this.totalLooted,
    required this.attacks,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['id'],
      name: json['name'],
      districtHallLevel: json['districtHallLevel'],
      destructionPercent: json['destructionPercent'],
      stars: json['stars'],
      attackCount: json['attackCount'],
      totalLooted: json['totalLooted'],
      attacks: json['attacks'] != null
          ? List<Attack>.from(json['attacks'].map((x) => Attack.fromJson(x)))
          : [],
    );
  }
}

class Attack {
  String tag;
  String name;
  int destructionPercent;
  int stars;

  Attack({
    required this.tag,
    required this.name,
    required this.destructionPercent,
    required this.stars,
  });

  factory Attack.fromJson(Map<String, dynamic> json) {
    return Attack(
      tag: json['attacker']['tag'],
      name: json['attacker']['name'],
      destructionPercent: json['destructionPercent'],
      stars: json['stars'],
    );
  }
}

class CapitalStats {
  final int totalLoot;
  final int totalAttacks;
  final int numberOfWeeks;
  final int totalRaids;
  final int totalDistrictsDestroyed;
  final int totalOffensiveRewards;
  final int totalDefensiveRewards;
  final double avgLootPerAttack;
  final double avgLootPerWeek;
  final double avgAttacksPerWeek;
  final double avgAttacksPerRaid;
  final double avgAttacksPerDistrict;
  final double avgOffensiveRewards;
  final double avgDefensiveRewards;
  final CapitalRaidSummary? bestRaid;
  final CapitalRaidSummary? worstRaid;

  CapitalStats({
    required this.totalLoot,
    required this.totalAttacks,
    required this.numberOfWeeks,
    required this.totalRaids,
    required this.totalDistrictsDestroyed,
    required this.totalOffensiveRewards,
    required this.totalDefensiveRewards,
    required this.avgLootPerAttack,
    required this.avgLootPerWeek,
    required this.avgAttacksPerWeek,
    required this.avgAttacksPerRaid,
    required this.avgAttacksPerDistrict,
    required this.avgOffensiveRewards,
    required this.avgDefensiveRewards,
    this.bestRaid,
    this.worstRaid,
  });

  factory CapitalStats.fromJson(Map<String, dynamic> json) {
    return CapitalStats(
      totalLoot: json['totalLoot'] ?? 0,
      totalAttacks: json['totalAttacks'] ?? 0,
      numberOfWeeks: json['numberOfWeeks'] ?? 0,
      totalRaids: json['totalRaids'] ?? 0,
      totalDistrictsDestroyed: json['totalDistrictsDestroyed'] ?? 0,
      totalOffensiveRewards: json['totalOffensiveRewards'] ?? 0,
      totalDefensiveRewards: json['totalDefensiveRewards'] ?? 0,
      avgLootPerAttack: (json['avgLootPerAttack'] as num?)?.toDouble() ?? 0.0,
      avgLootPerWeek: (json['avgLootPerWeek'] as num?)?.toDouble() ?? 0.0,
      avgAttacksPerWeek: (json['avgAttacksPerWeek'] as num?)?.toDouble() ?? 0.0,
      avgAttacksPerRaid: (json['avgAttacksPerRaid'] as num?)?.toDouble() ?? 0.0,
      avgAttacksPerDistrict: (json['avgAttacksPerDistrict'] as num?)?.toDouble() ?? 0.0,
      avgOffensiveRewards: (json['avgOffensiveRewards'] as num?)?.toDouble() ?? 0.0,
      avgDefensiveRewards: (json['avgDefensiveRewards'] as num?)?.toDouble() ?? 0.0,
      bestRaid: json['bestRaid'] != null ? CapitalRaidSummary.fromJson(json['bestRaid']) : null,
      worstRaid: json['worstRaid'] != null ? CapitalRaidSummary.fromJson(json['worstRaid']) : null,
    );
  }
}

class CapitalRaidSummary {
  final String startTime;
  final int capitalTotalLoot;
  final int totalRewards;
  final int raidsCompleted;
  final int totalAttacks;
  final int enemyDistrictsDestroyed;
  final double avgAttacksPerRaid;
  final double avgAttacksPerDistrict;

  CapitalRaidSummary({
    required this.startTime,
    required this.capitalTotalLoot,
    required this.totalRewards,
    required this.raidsCompleted,
    required this.totalAttacks,
    required this.enemyDistrictsDestroyed,
    required this.avgAttacksPerRaid,
    required this.avgAttacksPerDistrict,
  });

  factory CapitalRaidSummary.fromJson(Map<String, dynamic> json) {
    return CapitalRaidSummary(
      startTime: json['startTime'] ?? '',
      capitalTotalLoot: json['capitalTotalLoot'] ?? 0,
      totalRewards: json['totalRewards'] ?? 0,
      raidsCompleted: json['raidsCompleted'] ?? 0,
      totalAttacks: json['totalAttacks'] ?? 0,
      enemyDistrictsDestroyed: json['enemyDistrictsDestroyed'] ?? 0,
      avgAttacksPerRaid: (json['avgAttacksPerRaid'] as num?)?.toDouble() ?? 0.0,
      avgAttacksPerDistrict: (json['avgAttacksPerDistrict'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
