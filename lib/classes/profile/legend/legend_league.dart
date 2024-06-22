import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class PlayerLegendData {
  final Map<String, LegendDay> legendData;
  final Map<String, dynamic> legendRanking;
  final String name;
  final String tag;
  final int townHallLevel;
  final Map<String, dynamic> rankings;
  final int streak;
  List<dynamic> seasonsData = [];
  String firstTrophies = '0';
  String currentTrophies = "0";
  int diffTrophies = 0;
  List<dynamic> attacksList = [];
  List<dynamic> defensesList = [];

  PlayerLegendData({
    required this.legendData,
    required this.legendRanking,
    required this.name,
    required this.tag,
    required this.townHallLevel,
    required this.rankings,
    required this.streak,
  });

  factory PlayerLegendData.fromJson(Map<String, dynamic> json) {
    var legendDataJson = json['legends'] as Map<String, dynamic>? ?? {};
    Map<String, LegendDay> legendDataMap = legendDataJson.map((key, value) => MapEntry(key, LegendDay.fromJson(value)));

    return PlayerLegendData(
      legendData: legendDataMap,
      legendRanking: json['rankings'] ?? {},
      name: json['name'] ?? '',
      tag: json['tag'] ?? '',
      townHallLevel: json['townhall'] ?? 0,
      rankings: json['rankings'] ?? {},
      streak: json['streak'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'legends': legendData.map((key, value) => MapEntry(key, value.toJson())),
      'legendRanking': legendRanking,
      'name': name,
      'tag': tag,
      'townHallLevel': townHallLevel,
      'rankings': rankings,
      'streak': streak,
    };
  }

  bool get isEmpty => legendData.isEmpty;
  bool get isNotEmpty => legendData.isNotEmpty;
}

class PlayerLegendService {
  Future<PlayerLegendData?> fetchLegendData(String tag) async {
    final response = await http.get(Uri.parse(
        'https://api.clashking.xyz/player/${tag.substring(1)}/legends'));
    if (response.statusCode == 200) {
      String responseBody = utf8.decode(response.bodyBytes);
      PlayerLegendData playerLegendData =
          PlayerLegendData.fromJson(jsonDecode(responseBody));
      await calculateLegendData(playerLegendData);
      return playerLegendData;
    } else {
      return null;
    }
  }

  Future<void> calculateLegendData(PlayerLegendData playerLegendData) async {
    DateTime selectedDate = DateTime.now().toUtc().subtract(Duration(hours: 5));
    String date = DateFormat('yyyy-MM-dd').format(selectedDate);
    if (playerLegendData.legendData.isEmpty ||
        !playerLegendData.legendData.containsKey(date)) {
      playerLegendData.firstTrophies = "0";
      playerLegendData.currentTrophies = "0";
      playerLegendData.diffTrophies = 0;
      playerLegendData.attacksList = [];
      playerLegendData.defensesList = [];
    } else {
      LegendDay details = playerLegendData.legendData[date]!;
      String firstTrophies = '0';
      String currentTrophies = "0";
      int diffTrophies = 0;
      List<dynamic> attacksList =
          details.newAttacks.isNotEmpty ? details.newAttacks : details.attacks;
      List<dynamic> defensesList = details.newDefenses.isNotEmpty
          ? details.newDefenses
          : details.defenses;

      if (attacksList.isNotEmpty && defensesList.isNotEmpty) {
        var lastAttack = attacksList.last as Attack;
        var lastDefense = defensesList.last as Defense;
        currentTrophies = (lastAttack.time > lastDefense.time
            ? lastAttack.trophies.toString()
            : lastDefense.trophies.toString());

        var firstAttack = attacksList.first as Attack;
        var firstDefense = defensesList.first as Defense;
        firstTrophies = (firstAttack.time < firstDefense.time
                ? (firstAttack.trophies - firstAttack.change)
                : (firstDefense.trophies + firstDefense.change))
            .toString();
        diffTrophies = int.parse(currentTrophies) - int.parse(firstTrophies);
      } else if (attacksList.isNotEmpty) {
        var lastAttack = attacksList.last as Attack;
        currentTrophies = lastAttack.trophies.toString();
        var firstAttack = attacksList.first as Attack;
        firstTrophies = (firstAttack.trophies - firstAttack.change).toString();
        diffTrophies = int.parse(currentTrophies) - int.parse(firstTrophies);
      } else if (defensesList.isNotEmpty) {
        var lastDefense = defensesList.last as Defense;
        currentTrophies = lastDefense.trophies.toString();
        var firstDefense = defensesList.first as Defense;
        firstTrophies =
            (firstDefense.trophies + firstDefense.change).toString();
        diffTrophies = int.parse(currentTrophies) - int.parse(firstTrophies);
      } else {
        currentTrophies = details.defenses.isNotEmpty
            ? details.defenses.last.toString()
            : '0';
        firstTrophies = details.defenses.isNotEmpty
            ? details.defenses.first.toString()
            : '0';
      }

      playerLegendData.firstTrophies = firstTrophies;
      playerLegendData.currentTrophies = currentTrophies;
      playerLegendData.diffTrophies = diffTrophies;
      playerLegendData.attacksList = attacksList;
      playerLegendData.defensesList = defensesList;
    }
  }
}

class PlayerLegendSeasonsService {
  static Future<List<dynamic>> fetchSeasonsData(String tag) async {
    final response = await http.get(Uri.parse(
        'https://api.clashking.xyz/player/${tag.substring(1)}/legend_rankings'));

    if (response.statusCode == 200) {
      String body = utf8.decode(response.bodyBytes);
      return json.decode(body);
    } else {
      throw Exception('Failed to load seasons data');
    }
  }
}
class HeroGear {
  final String name;
  final int level;

  HeroGear({required this.name, required this.level});

  factory HeroGear.fromJson(Map<String, dynamic> json) {
    return HeroGear(
      name: json['name'],
      level: json['level'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'level': level,
    };
  }
}

class Attack {
  final int change;
  final int time;
  final int trophies;
  final List<HeroGear> heroGear;

  Attack({
    required this.change,
    required this.time,
    required this.trophies,
    required this.heroGear,
  });

  factory Attack.fromJson(Map<String, dynamic> json) {
    var heroGearJson = json['hero_gear'] as List<dynamic>? ?? [];
    List<HeroGear> heroGearList =
        heroGearJson.map((i) => HeroGear.fromJson(i)).toList();

    return Attack(
      change: json['change'],
      time: json['time'],
      trophies: json['trophies'],
      heroGear: heroGearList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'change': change,
      'time': time,
      'trophies': trophies,
      'hero_gear': heroGear.map((v) => v.toJson()).toList(),
    };
  }
}


class Defense {
  final int change;
  final int time;
  final int trophies;

  Defense({
    required this.change,
    required this.time,
    required this.trophies,
  });

  factory Defense.fromJson(Map<String, dynamic> json) {
    return Defense(
      change: json['change'],
      time: json['time'],
      trophies: json['trophies'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'change': change,
      'time': time,
      'trophies': trophies,
    };
  }
}

class LegendDay {
  final List<int> defenses;
  final List<Defense> newDefenses;
  final int numAttacks;
  final List<int> attacks;
  final List<Attack> newAttacks;

  LegendDay({
    required this.defenses,
    required this.newDefenses,
    required this.numAttacks,
    required this.attacks,
    required this.newAttacks,
  });

  factory LegendDay.fromJson(Map<String, dynamic> json) {
    var defensesJson = json['defenses'] as List<dynamic>? ?? [];
    var newDefensesJson = json['new_defenses'] as List<dynamic>? ?? [];
    var attacksJson = json['attacks'] as List<dynamic>? ?? [];
    var newAttacksJson = json['new_attacks'] as List<dynamic>? ?? [];

    List<Defense> newDefensesList = newDefensesJson.map((i) => Defense.fromJson(i)).toList();
    List<Attack> newAttacksList = newAttacksJson.map((i) => Attack.fromJson(i)).toList();

    return LegendDay(
      defenses: defensesJson.cast<int>(),
      newDefenses: newDefensesList,
      numAttacks: json['num_attacks'] ?? 0,
      attacks: attacksJson.cast<int>(),
      newAttacks: newAttacksList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'defenses': defenses,
      'new_defenses': newDefenses.map((v) => v.toJson()).toList(),
      'num_attacks': numAttacks,
      'attacks': attacks,
      'new_attacks': newAttacks.map((v) => v.toJson()).toList(),
    };
  }
}

