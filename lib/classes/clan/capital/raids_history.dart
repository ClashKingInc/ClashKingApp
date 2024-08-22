import 'dart:convert';
import 'package:http/http.dart' as http;

class CapitalHistoryItems {
  final List<CapitalHistoryItem> items;

  CapitalHistoryItems({required this.items});

  factory CapitalHistoryItems.fromJson(Map<String, dynamic> json) {
    return CapitalHistoryItems(
      items: List<CapitalHistoryItem>.from(json['items'].map((x) => CapitalHistoryItem.fromJson(x))),
    );
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
    print(json);
    print(json['members']);
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
        ? List<RaidMember>.from(json['members'].map((x) => RaidMember.fromJson(x))) 
        : [],
      attackLog: json['attackLog'] != null 
        ? List<RaidAttackLog>.from(json['attackLog'].map((x) => RaidAttackLog.fromJson(x))) 
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
      districts: List<District>.from(json['districts'].map((x) => District.fromJson(x))),
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

class CapitalHistoryService {
  static Future<CapitalHistoryItems> fetchCapitalData(String tag, int limit) async {
    final response = await http.get(
      Uri.parse('https://api.clashking.xyz/v1/clans/${tag.replaceAll('#', '%23')}/capitalraidseasons?limit=$limit'),
    );

    print(response.statusCode);

    if (response.statusCode == 200) {
      String body = utf8.decode(response.bodyBytes);
      return CapitalHistoryItems.fromJson(jsonDecode(body));
    } else {
      throw Exception('Failed to load capital history');
    }
  }
}

