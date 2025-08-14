import 'package:clashkingapp/core/utils/debug_utils.dart';

class CwlAttackStats {
  final int stars;
  final Map<String, int> threeStars;
  final Map<String, int> twoStars;
  final Map<String, int> oneStar;
  final Map<String, int> zeroStar;
  final double totalDestruction;
  final int attackCount;
  final int missedAttacks;
  final int? warsParticipated;
  final int? attacksPerWar;

  CwlAttackStats({
    required this.stars,
    required this.threeStars,
    required this.twoStars,
    required this.oneStar,
    required this.zeroStar,
    required this.totalDestruction,
    required this.attackCount,
    required this.missedAttacks,
    this.warsParticipated,
    this.attacksPerWar,
  });

  double get averageStars {
    if (attackCount == 0) return 0.0;
    return stars / attackCount;
  }

  double get averageDestruction {
    if (attackCount == 0) return 0.0;
    return totalDestruction / attackCount;
  }

  /// Calculate missed attacks based on wars participated and expected attacks
  int get calculatedMissedAttacks {
    if (warsParticipated == null || attacksPerWar == null) {
      return missedAttacks; // Fallback to API value
    }
    final expectedAttacks = (warsParticipated! * attacksPerWar!);
    final missed = expectedAttacks - attackCount;
    return missed > 0 ? missed : 0;
  }

  factory CwlAttackStats.fromJson(Map<String, dynamic> json) {
    try {
      DebugUtils.debugInfo("🔍 Parsing CwlAttackStats JSON: $json");
      
      // API returns: {"stars": 6, "3_stars": {"13": 1, "14": 1}, "2_stars": {"15": 1}, ...}
      final threeStarsMap = Map<String, int>.from(json['3_stars'] ?? {});
      final twoStarsMap = Map<String, int>.from(json['2_stars'] ?? {});
      final oneStarMap = Map<String, int>.from(json['1_star'] ?? {});
      final zeroStarMap = Map<String, int>.from(json['0_star'] ?? {});
      
      DebugUtils.debugInfo("🔍 Attack Stats - 3★: $threeStarsMap, 2★: $twoStarsMap, 1★: $oneStarMap, 0★: $zeroStarMap");
      
      return CwlAttackStats(
        stars: json['stars'] ?? 0,
        threeStars: threeStarsMap,
        twoStars: twoStarsMap,
        oneStar: oneStarMap,
        zeroStar: zeroStarMap,
        totalDestruction: (json['total_destruction'] ?? 0.0).toDouble(),
        attackCount: json['attack_count'] ?? 0,
        missedAttacks: json['missed_attacks'] ?? 0,
        warsParticipated: null, // Not provided in this format
        attacksPerWar: null, // Not provided in this format
      );
    } catch (e) {
      DebugUtils.debugError(" Error parsing CwlAttackStats: $e");
      DebugUtils.debugError(" JSON was: $json");
      return CwlAttackStats(
        stars: 0,
        threeStars: {},
        twoStars: {},
        oneStar: {},
        zeroStar: {},
        totalDestruction: 0.0,
        attackCount: 0,
        missedAttacks: 0,
        warsParticipated: null,
        attacksPerWar: null,
      );
    }
  }

  Map<String, dynamic> toJson() => {
        'stars': stars,
        '3_stars': threeStars,
        '2_stars': twoStars,
        '1_star': oneStar,
        '0_star': zeroStar,
        'total_destruction': totalDestruction,
        'attack_count': attackCount,
        'missed_attacks': missedAttacks,
      };
}

class CwlDefenseStats {
  final int stars;
  final Map<String, int> threeStars;
  final Map<String, int> twoStars;
  final Map<String, int> oneStar;
  final Map<String, int> zeroStar;
  final double totalDestruction;
  final int defenseCount;
  final int missedDefenses;

  CwlDefenseStats({
    required this.stars,
    required this.threeStars,
    required this.twoStars,
    required this.oneStar,
    required this.zeroStar,
    required this.totalDestruction,
    required this.defenseCount,
    required this.missedDefenses,
  });

  double get averageStars {
    if (defenseCount == 0) return 0.0;
    return stars / defenseCount;
  }

  double get averageDestruction {
    if (defenseCount == 0) return 0.0;
    return totalDestruction / defenseCount;
  }

  factory CwlDefenseStats.fromJson(Map<String, dynamic> json) {
    try {
      DebugUtils.debugInfo("🔍 Parsing CwlDefenseStats JSON: $json");
      
      // API returns: {"stars": 4, "3_stars": {"14": 1}, "2_stars": {}, "1_star": {"15": 1}, ...}
      final threeStarsMap = Map<String, int>.from(json['3_stars'] ?? {});
      final twoStarsMap = Map<String, int>.from(json['2_stars'] ?? {});
      final oneStarMap = Map<String, int>.from(json['1_star'] ?? {});
      final zeroStarMap = Map<String, int>.from(json['0_star'] ?? {});
      
      DebugUtils.debugInfo("🔍 Defense Stats - 3★: $threeStarsMap, 2★: $twoStarsMap, 1★: $oneStarMap, 0★: $zeroStarMap");
      
      return CwlDefenseStats(
        stars: json['stars'] ?? 0,
        threeStars: threeStarsMap,
        twoStars: twoStarsMap,
        oneStar: oneStarMap,
        zeroStar: zeroStarMap,
        totalDestruction: (json['total_destruction'] ?? 0.0).toDouble(),
        defenseCount: json['defense_count'] ?? 0,
        missedDefenses: json['missed_defenses'] ?? 0,
      );
    } catch (e) {
      DebugUtils.debugError(" Error parsing CwlDefenseStats: $e");
      DebugUtils.debugError(" JSON was: $json");
      return CwlDefenseStats(
        stars: 0,
        threeStars: {},
        twoStars: {},
        oneStar: {},
        zeroStar: {},
        totalDestruction: 0.0,
        defenseCount: 0,
        missedDefenses: 0,
      );
    }
  }

  Map<String, dynamic> toJson() => {
        'stars': stars,
        '3_stars': threeStars,
        '2_stars': twoStars,
        '1_star': oneStar,
        '0_star': zeroStar,
        'total_destruction': totalDestruction,
        'defense_count': defenseCount,
      };
}
