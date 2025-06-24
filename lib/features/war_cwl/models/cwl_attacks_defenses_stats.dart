class CwlAttackStats {
  final int stars;
  final Map<String, int> threeStars;
  final Map<String, int> twoStars;
  final Map<String, int> oneStar;
  final Map<String, int> zeroStar;
  final double totalDestruction;
  final int attackCount;
  final int missedAttacks;

  CwlAttackStats({
    required this.stars,
    required this.threeStars,
    required this.twoStars,
    required this.oneStar,
    required this.zeroStar,
    required this.totalDestruction,
    required this.attackCount,
    required this.missedAttacks,
  });

  get averageStars {
    if (attackCount == 0) return 0.0;
    return stars / attackCount;
  }

  get averageDestruction {
    if (attackCount == 0) return 0.0;
    return totalDestruction / attackCount;
  }

  factory CwlAttackStats.fromJson(Map<String, dynamic> json) {
    try {
      return CwlAttackStats(
        stars: json['stars'] ?? 0,
        threeStars: Map<String, int>.from(json['3_stars'] ?? {}),
        twoStars: Map<String, int>.from(json['2_stars'] ?? {}),
        oneStar: Map<String, int>.from(json['1_star'] ?? {}),
        zeroStar: Map<String, int>.from(json['0_star'] ?? {}),
        totalDestruction:
            (json['total_destruction'] as num?)?.toDouble() ?? 0.0,
        attackCount: json['attack_count'] ?? 0,
        missedAttacks: json['missed_attacks'] ?? 0,
      );
    } catch (e) {
      print("❌ Error parsing CwlAttackStats: $e");
      return CwlAttackStats(
        stars: 0,
        threeStars: {},
        twoStars: {},
        oneStar: {},
        zeroStar: {},
        totalDestruction: 0.0,
        attackCount: 0,
        missedAttacks: 0,
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

  get averageStars {
    if (defenseCount == 0) return 0.0;
    return stars / defenseCount;
  }

  get averageDestruction {
    if (defenseCount == 0) return 0.0;
    return totalDestruction / defenseCount;
  }

  factory CwlDefenseStats.fromJson(Map<String, dynamic> json) {
    try {
      return CwlDefenseStats(
        stars: json['stars'] ?? 0,
        threeStars: Map<String, int>.from(json['3_stars'] ?? {}),
        twoStars: Map<String, int>.from(json['2_stars'] ?? {}),
        oneStar: Map<String, int>.from(json['1_star'] ?? {}),
        zeroStar: Map<String, int>.from(json['0_star'] ?? {}),
        totalDestruction:
            (json['total_destruction'] as num?)?.toDouble() ?? 0.0,
        defenseCount: json['defense_count'] ?? 0,
        missedDefenses: json['missed_defenses'] ?? 0,
      );
    } catch (e) {
      print("❌ Error parsing CwlDefenseStats: $e");
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
