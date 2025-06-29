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
      // Calculate total stars from individual star counts
      final starsCount = Map<String, int>.from(json['starsCount'] ?? {});
      final totalStars = (starsCount['3'] ?? 0) * 3 + 
                        (starsCount['2'] ?? 0) * 2 + 
                        (starsCount['1'] ?? 0) * 1;
      
      return CwlAttackStats(
        stars: totalStars,
        threeStars: {'3': starsCount['3'] ?? 0},
        twoStars: {'2': starsCount['2'] ?? 0},
        oneStar: {'1': starsCount['1'] ?? 0},
        zeroStar: {'0': starsCount['0'] ?? 0},
        totalDestruction: 0.0, // Not directly available in this format
        attackCount: json['totalAttacks'] ?? 0,
        missedAttacks: json['missedAttacks'] ?? 0,
        warsParticipated: json['warsCounts'],
        attacksPerWar: null, // Could be calculated if needed
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
      // Calculate total stars from individual star counts (defense perspective)
      final starsCountDef = Map<String, int>.from(json['starsCountDef'] ?? {});
      final totalStars = (starsCountDef['3'] ?? 0) * 3 + 
                        (starsCountDef['2'] ?? 0) * 2 + 
                        (starsCountDef['1'] ?? 0) * 1;
      
      return CwlDefenseStats(
        stars: totalStars,
        threeStars: {'3': starsCountDef['3'] ?? 0},
        twoStars: {'2': starsCountDef['2'] ?? 0},
        oneStar: {'1': starsCountDef['1'] ?? 0},
        zeroStar: {'0': starsCountDef['0'] ?? 0},
        totalDestruction: 0.0, // Not directly available in this format
        defenseCount: json['totalDefenses'] ?? 0,
        missedDefenses: json['missedDefenses'] ?? 0,
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
