import 'package:clashkingapp/features/war_cwl/models/cwl_attacks_defenses_stats.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';

class CwlMember {
  final String tag;
  final String name;
  final int townhallLevel;
  final double? avgMapPosition;
  final double? avgOpponentPosition;
  final double? avgAttackOrder;
  final double? avgTownHallLevel;
  final double? avgOpponentTownHallLevel;
  final double? avgAttackerPosition;
  final double? avgDefenseOrder;
  final double? avgAttackerTownHallLevel;
  final double? attackLowerTHLevel;
  final double? defenseLowerTHLevel;
  final double? attackUpperTHLevel;
  final double? defenseUpperTHLevel;
  final CwlAttackStats? attackStats;
  final CwlDefenseStats? defenseStats;

  CwlMember({
    required this.tag,
    required this.name,
    required this.townhallLevel,
    this.avgMapPosition,
    this.avgOpponentPosition,
    this.avgAttackOrder,
    this.avgTownHallLevel,
    this.avgOpponentTownHallLevel,
    this.avgAttackerPosition,
    this.avgDefenseOrder,
    this.avgAttackerTownHallLevel,
    this.attackLowerTHLevel,
    this.defenseLowerTHLevel,
    this.attackUpperTHLevel,
    this.defenseUpperTHLevel,
    this.attackStats,
    this.defenseStats,
  });

  int _sumStars<T>(T? stats, Map<String, int> Function(T) selector) {
    if (stats == null) return 0;
    return selector(stats).values.fold(0, (a, b) => a + b);
  }

  int get threeStars => _sumStars(attackStats, (stats) => stats.threeStars);
  int get twoStars => _sumStars(attackStats, (stats) => stats.twoStars);
  int get oneStar => _sumStars(attackStats, (stats) => stats.oneStar);
  int get zeroStar => _sumStars(attackStats, (stats) => stats.zeroStar);

  int get threeStarsDef => _sumStars(defenseStats, (stats) => stats.threeStars);
  int get twoStarsDef => _sumStars(defenseStats, (stats) => stats.twoStars);
  int get oneStarDef => _sumStars(defenseStats, (stats) => stats.oneStar);
  int get zeroStarDef => _sumStars(defenseStats, (stats) => stats.zeroStar);

  factory CwlMember.fromJson(Map<String, dynamic> json) {
    try {
      DebugUtils.debugInfo("🔍 Parsing CwlMember JSON: $json");
      DebugUtils.debugInfo("🔍 Stats structure: ${json['stats']}");
      
      return CwlMember(
          tag: json['tag'],
          name: json['name'],
          townhallLevel: json['townHallLevel'],
          avgMapPosition: json['avgMapPosition']?.toDouble(),
          avgOpponentPosition: json['avgOpponentPosition']?.toDouble(),
          avgAttackOrder: json['avgAttackOrder']?.toDouble(),
          avgTownHallLevel: json['avgTownHallLevel']?.toDouble(),
          avgOpponentTownHallLevel:
              json['avgOpponentTownHallLevel']?.toDouble(),
          avgAttackerPosition: json['avgAttackerPosition']?.toDouble(),
          avgDefenseOrder: json['avgDefenseOrder']?.toDouble(),
          avgAttackerTownHallLevel:
              json['avgAttackerTownHallLevel']?.toDouble(),
          attackLowerTHLevel: json['attackLowerTHLevel']?.toDouble(),
          defenseLowerTHLevel: json['defenseLowerTHLevel']?.toDouble(),
          attackUpperTHLevel: json['attackUpperTHLevel']?.toDouble(),
          defenseUpperTHLevel: json['defenseUpperTHLevel']?.toDouble(),
          attackStats: json['stats']?['cwl'] != null
              ? CwlAttackStats.fromJson(json['stats']['cwl'])
              : null,
          defenseStats: json['stats']?['cwl'] != null
              ? CwlDefenseStats.fromJson(json['stats']['cwl'])
              : null);
    } catch (e) {
      DebugUtils.debugError(" Error parsing CwlMember: $e");
      DebugUtils.debugError(" JSON was: $json");
      return CwlMember(
        tag: json['tag'] ?? 'No tag',
        name: json['name'] ?? 'No name',
        townhallLevel: json['townHallLevel'] ?? 0,
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
