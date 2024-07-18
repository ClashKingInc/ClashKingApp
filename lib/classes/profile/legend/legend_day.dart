import 'package:clashkingapp/classes/profile/legend/legend_hero_gear.dart';
import 'package:clashkingapp/classes/profile/legend/legend_attack.dart';
import 'package:clashkingapp/classes/profile/legend/legend_defense.dart';

class LegendDay {
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


  LegendDay({
    required this.defenses,
    required this.newDefenses,
    required this.numAttacks,
    required this.attacks,
    required this.newAttacks,
  }) : gearCount = _calculateGearCount(newAttacks);

  factory LegendDay.fromJson(Map<String, dynamic> json) {
    // Handle older format with simple integer lists
    List<int> defenses =
        (json['defenses'] as List<dynamic>?)?.map((e) => e as int).toList() ??
            [];
    List<int> attacks =
        (json['attacks'] as List<dynamic>?)?.map((e) => e as int).toList() ??
            [];

    // Handle newer format with more detailed objects
    List<Defense> newDefenses = (json['new_defenses'] as List<dynamic>?)
            ?.map((e) => Defense.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    List<Attack> newAttacks = (json['new_attacks'] as List<dynamic>?)
            ?.map((e) => Attack.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return LegendDay(
      defenses: defenses,
      newDefenses: newDefenses,
      numAttacks: json['num_attacks'] as int? ?? 0,
      attacks: attacks,
      newAttacks: newAttacks,
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
}