import 'package:clashkingapp/features/war_cwl/models/cwl_attacks_defenses_stats.dart';

class CwlMember {
  final String tag;
  final String name;
  final int townhallLevel;
  final CwlAttackStats? attackStats;
  final CwlDefenseStats? defenseStats;

  CwlMember({
    required this.tag,
    required this.name,
    required this.townhallLevel,
    this.attackStats,
    this.defenseStats,
  });

  factory CwlMember.fromJson(Map<String, dynamic> json) {
    try {
      return CwlMember(
          tag: json['tag'],
          name: json['name'],
          townhallLevel: json['townHallLevel'],
          attackStats: json['attacks'] != null
              ? CwlAttackStats.fromJson(json['attacks'])
              : null,
          defenseStats: json['defense'] != null
              ? CwlDefenseStats.fromJson(json['defense'])
              : null);
    } catch (e) {
      print("❌ Error parsing CwlMember: $e");
      return CwlMember(
        tag: 'No tag',
        name: 'No name',
        townhallLevel: 0,
        attackStats: null,
        defenseStats: null,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'tag': tag,
      'name': name,
      'townHallLevel': townhallLevel,
      'attacks': attackStats?.toJson(),
      'defense': defenseStats?.toJson(),
    };
  }
}
