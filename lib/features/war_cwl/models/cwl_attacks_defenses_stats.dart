class CwlAttackStats {
  final int stars;
  final int threeStars;
  final int twoStars;
  final int oneStar;
  final int zeroStar;
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

  factory CwlAttackStats.fromJson(Map<String, dynamic> json) {
    try {
      return CwlAttackStats(
        stars: json['stars'] ?? 0,
        threeStars: json['3_stars'] ?? 0,
        twoStars: json['2_stars'] ?? 0,
        oneStar: json['1_star'] ?? 0,
        zeroStar: json['0_star'] ?? 0,
        totalDestruction:
            (json['total_destruction'] as num?)?.toDouble() ?? 0.0,
        attackCount: json['attack_count'] ?? 0,
        missedAttacks: json['missed_attacks'] ?? 0,
      );
    } catch (e) {
      print("❌ Error parsing CwlAttackStats: $e");
      return CwlAttackStats(
        stars: 0,
        threeStars: 0,
        twoStars: 0,
        oneStar: 0,
        zeroStar: 0,
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
  final int threeStars;
  final int twoStars;
  final int oneStar;
  final int zeroStar;
  final double totalDestruction;
  final int defenseCount;

  CwlDefenseStats({
    required this.stars,
    required this.threeStars,
    required this.twoStars,
    required this.oneStar,
    required this.zeroStar,
    required this.totalDestruction,
    required this.defenseCount,
  });

  factory CwlDefenseStats.fromJson(Map<String, dynamic> json) {
    try {
      return CwlDefenseStats(
        stars: json['stars'] ?? 0,
        threeStars: json['3_stars'] ?? 0,
        twoStars: json['2_stars'] ?? 0,
        oneStar: json['1_star'] ?? 0,
        zeroStar: json['0_star'] ?? 0,
        totalDestruction:
            (json['total_destruction'] as num?)?.toDouble() ?? 0.0,
        defenseCount: json['defense_count'] ?? 0,
      );
    } catch (e) {
      print("❌ Error parsing CwlDefenseStats: $e");
      return CwlDefenseStats(
        stars: 0,
        threeStars: 0,
        twoStars: 0,
        oneStar: 0,
        zeroStar: 0,
        totalDestruction: 0.0,
        defenseCount: 0,
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
