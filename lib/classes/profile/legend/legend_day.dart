import 'package:clashkingapp/classes/profile/legend/legend_hero_gear.dart';
import 'package:clashkingapp/classes/profile/legend/legend_attack.dart';
import 'package:clashkingapp/classes/profile/legend/legend_defense.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class LegendDay {
  final DateTime date;
  final int numDefenses;
  final List<int> defenses;
  final List<Defense> newDefenses;
  final int numAttacks;
  final List<int> attacks;
  final List<Attack> newAttacks;
  final Map<String, Map<String, GearDetails>> gearCount;
  late int startTrophies;
  late int endTrophies;
  late String currentTrophies;
  late int diffTrophies;
  late List<dynamic> attacksList;
  late List<dynamic> defensesList;
  late LegendDayStats attacksStats;
  late LegendDayStats defensesStats;

  LegendDay({
    required this.date,
    required this.numDefenses,
    required this.defenses,
    required this.newDefenses,
    required this.numAttacks,
    required this.attacks,
    required this.newAttacks,
  })  : gearCount = _calculateGearCount(newAttacks),
        attacksList = newAttacks.isNotEmpty ? newAttacks : attacks,
        defensesList = newDefenses.isNotEmpty ? newDefenses : defenses {
    calculateTrophies();
  }

  factory LegendDay.fromJson(String key, Map<String, dynamic> json) {
    DateTime date = DateTime.parse(key);
    // Handle older format with simple integer lists
    List<int> defenses =
        (json['defenses'] as List<dynamic>?)?.map((e) => e as int).toList() ??
            [];
    List<int> attacks =
        (json['attacks'] as List<dynamic>?)?.map((e) => e as int).toList() ??
            [];

    // Handle newer format avec des objets plus détaillés
    List<Defense> newDefenses = (json['new_defenses'] as List<dynamic>?)
            ?.map((e) => Defense.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    List<Attack> newAttacks = (json['new_attacks'] as List<dynamic>?)
            ?.map((e) => Attack.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    var legendDay = LegendDay(
      date: date,
      numDefenses: countAttacksDefenses(defenses),
      defenses: defenses,
      newDefenses: newDefenses,
      numAttacks: countAttacksDefenses(attacks),
      attacks: attacks,
      newAttacks: newAttacks,
    );

    legendDay.calculateTrophies();

    return legendDay;
  }

  static int countAttacksDefenses(List<int> list) {
    int count = 0;
    for (int value in list) {
      switch (value) {
        case 320:
          count += 8;
          break;
        case (> 280 && < 320):
          count += 7;
          break;
        case (> 240 && < 280):
          count += 6;
          break;
        case (> 160 && < 200):
          count += 5;
          break;
        case (> 120 && < 160):
          count += 4;
          break;
        case (> 80 && < 120):
          count += 3;
          break;
        case (> 40 && < 80):
          count += 2;
          break;
        default:
          count += 1;
          break;
      }
    }
    return count;
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

  static Map<String, Map<String, GearDetails>> _calculateGearCount(
      List<Attack> attacks) {
    Map<String, Map<String, GearDetails>> heroGearCount = {};

    void countGearInList(List<HeroGear> gearList) {
      for (var gear in gearList) {
        if (!heroGearCount.containsKey(gear.hero)) {
          heroGearCount[gear.hero] = {};
        }
        var gearMap = heroGearCount[gear.hero]!;

        if (gearMap.containsKey(gear.name)) {
          gearMap[gear.name]!.count += 1;
        } else {
          gearMap[gear.name] = GearDetails(1, gear.url, gear.hero, gear.name);
        }
      }
    }

    for (var attack in attacks) {
      countGearInList(attack.heroGear);
    }

    return heroGearCount;
  }

  void calculateTrophies() {
    try {
      startTrophies = 0;
      currentTrophies = "0";

      if (attacksList.isNotEmpty && defensesList.isNotEmpty) {
        var lastAttack = attacksList.last is Attack
            ? attacksList.last as Attack
            : Attack(
                change: attacksList.last, time: 0, trophies: 0, heroGear: []);
        var lastDefense = defensesList.last is Defense
            ? defensesList.last as Defense
            : Defense(change: defensesList.last, time: 0, trophies: 0);

        currentTrophies = (lastAttack.time > lastDefense.time
            ? lastAttack.trophies.toString()
            : lastDefense.trophies.toString());

        var firstAttack = attacksList.first is Attack
            ? attacksList.first as Attack
            : Attack(
                change: attacksList.first, time: 0, trophies: 0, heroGear: []);
        var firstDefense = defensesList.first is Defense
            ? defensesList.first as Defense
            : Defense(change: defensesList.first, time: 0, trophies: 0);

        startTrophies = (firstAttack.time < firstDefense.time
            ? (firstAttack.trophies - firstAttack.change)
            : (firstDefense.trophies + firstDefense.change));
      } else if (attacksList.isNotEmpty) {
        var lastAttack = attacksList.last is Attack
            ? attacksList.last as Attack
            : Attack(
                change: attacksList.last, time: 0, trophies: 0, heroGear: []);
        currentTrophies = lastAttack.trophies.toString();
        var firstAttack = attacksList.first is Attack
            ? attacksList.first as Attack
            : Attack(
                change: attacksList.first, time: 0, trophies: 0, heroGear: []);
        startTrophies = (firstAttack.trophies - firstAttack.change);
      } else if (defensesList.isNotEmpty) {
        var lastDefense = defensesList.last is Defense
            ? defensesList.last as Defense
            : Defense(change: defensesList.last, time: 0, trophies: 0);
        currentTrophies = lastDefense.trophies.toString();
        var firstDefense = defensesList.first is Defense
            ? defensesList.first as Defense
            : Defense(change: defensesList.first, time: 0, trophies: 0);
        startTrophies = (firstDefense.trophies + firstDefense.change);
      }

      endTrophies = int.parse(currentTrophies);
      diffTrophies = endTrophies - startTrophies;
      currentTrophies = currentTrophies;
      attacksStats = calculateStats(attacksList);
      defensesStats = calculateStats(defensesList);
    } catch (exception, stackTrace) {
      final hint = Hint.withMap({
        'custom_message': 'Error while calculating legends trophies',
        'attacksList': attacksList,
        'defensesList': defensesList,
        'startTrophies': startTrophies,
        'endTrophies': endTrophies,
        'currentTrophies': currentTrophies,
        'diffTrophies': diffTrophies,
        'attacksStats': attacksStats,
        'defensesStats': defensesStats,
      });
      Sentry.captureException(exception, stackTrace: stackTrace, hint: hint);
    }
  }
}

class LegendDayStats {
  final int sum;
  final int count;
  final double average;
  final int remaining;
  final int bestPossibleTrophies;

  LegendDayStats({
    required this.sum,
    required this.count,
    required this.average,
    required this.remaining,
    required this.bestPossibleTrophies,
  });

  @override
  String toString() {
    return 'LegendDayStats(sum: $sum, count: $count, average: $average, remaining: $remaining, bestPossibleTrophies: $bestPossibleTrophies)';
  }
}

LegendDayStats calculateStats(List<dynamic> list) {
  int sum = 0;
  int count = 0;
  double average = 0;
  int remaining = 320;
  int bestPossibleTrophies = 0;

  if (list.isNotEmpty) {
    var filteredList =
        list.where((item) => item is Attack || item is Defense).toList();
    if (filteredList.isNotEmpty) {
      sum = filteredList
          .map((item) =>
              (item is Attack ? item.change : (item as Defense).change))
          .reduce((value, element) => value + element);
      count = filteredList.length +
          filteredList
              .where((item) =>
                  (item is Attack ? item.change : (item as Defense).change) >
                  40)
              .length;
      average = sum / count;
      remaining = 320 - count * 40;
      bestPossibleTrophies = remaining + sum;
    }
  }

  return LegendDayStats(
    sum: sum,
    count: count,
    average: average,
    remaining: remaining,
    bestPossibleTrophies: bestPossibleTrophies,
  );
}
