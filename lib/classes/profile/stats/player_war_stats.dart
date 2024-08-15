class WarStats {
  final String playerTag;
  final String playerName;
  final int townhallLevel;
  final int mapPosition;
  final int opponentAttacks;
  final List<Attack> attacks;
  final List<Defense> defenses;
  final int timeStampsStart;
  final int timeStampsEnd;
  final int numberOfWars;
  final String warType;

  WarStats({
    required this.timeStampsStart,
    required this.timeStampsEnd,
    required this.playerTag,
    required this.playerName,
    required this.townhallLevel,
    required this.mapPosition,
    required this.opponentAttacks,
    required this.attacks,
    required this.defenses,
    required this.numberOfWars,
    required this.warType,
  });

  // Moyenne des étoiles sur toutes les attaques
  double get averageStars => attacks.isNotEmpty
      ? attacks.map((attack) => attack.stars).reduce((a, b) => a + b) /
          attacks.length
      : 0.0;

  // Moyenne du pourcentage de destruction sur toutes les attaques
  double get averageDestructionPercentage => attacks.isNotEmpty
      ? attacks
              .map((attack) => attack.destructionPercentage)
              .reduce((a, b) => a + b) /
          attacks.length
      : 0.0;

  // Moyenne des étoiles en défense
  double get averageDefenseStars => defenses.isNotEmpty
      ? defenses.map((defense) => defense.stars).reduce((a, b) => a + b) /
          defenses.length
      : 0.0;

  // Moyenne du pourcentage de destruction subi en défense
  double get averageDefenseDestructionPercentage => defenses.isNotEmpty
      ? defenses
              .map((defense) => defense.destructionPercentage)
              .reduce((a, b) => a + b) /
          defenses.length
      : 0.0;

  // Moyenne des étoiles par niveau d'hôtel de ville
  double averageStarsByTownhall(int townhallLevel) {
    final filteredAttacks = attacks
        .where((attack) => attack.defender.townhallLevel == townhallLevel)
        .toList();

    return filteredAttacks.isNotEmpty
        ? filteredAttacks
                .map((attack) => attack.stars)
                .reduce((a, b) => a + b) /
            filteredAttacks.length
        : 0.0;
  }

  int numberOfStarsAttacks(int numberOfStars) {
    return attacks.where((attack) => attack.stars == numberOfStars).length;
  }

  List<int> opponentTownhallLevels() {
    return attacks
        .map((attack) => attack.defender.townhallLevel)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
  }

  int numberOfStarsDefenses(int numberOfStars) {
    return defenses.where((defense) => defense.stars == numberOfStars).length;

  }
TownhallAttackDefenseStats getTownhallAttackDefenseStats(int townhallLevel) {
    final filteredAttacks = attacks
        .where((attack) => attack.defender.townhallLevel == townhallLevel)
        .toList();
    final filteredDefenses = defenses
        .where((defense) => defense.attacker.townhallLevel == townhallLevel)
        .toList();

    final totalAttacks = filteredAttacks.length;
    final totalDefenses = filteredDefenses.length;
    final threeStarsAttacks =
        filteredAttacks.where((attack) => attack.stars == 3).length;
    final twoStarsAttacks =
        filteredAttacks.where((attack) => attack.stars == 2).length;
    final oneStarAttacks = filteredAttacks.where((attack) => attack.stars == 1).length;
    final zeroStarsAttacks =
        filteredAttacks.where((attack) => attack.stars == 0).length;
    final threeStarsDefenses =
        filteredDefenses.where((defense) => defense.stars == 3).length;
    final twoStarsDefenses =
        filteredDefenses.where((defense) => defense.stars == 2).length;
    final oneStarDefenses = filteredDefenses.where((defense) => defense.stars == 1).length;
    final zeroStarsDefenses =
        filteredDefenses.where((defense) => defense.stars == 0).length;

    final averageAttackDestructionPercentage = filteredAttacks.isNotEmpty
        ? filteredAttacks
                .map((attack) => attack.destructionPercentage)
                .reduce((a, b) => a + b) / totalAttacks
        : 0.0;
    final averageDefenseDestructionPercentage = filteredDefenses.isNotEmpty
        ? filteredDefenses
                .map((defense) => defense.destructionPercentage)
                .reduce((a, b) => a + b) / totalDefenses
        : 0.0;

    final averageAttackStars = totalAttacks != 0
        ? filteredAttacks.map((attack) => attack.stars).reduce((a, b) => a + b) / totalAttacks
        : 0.0;
    final averageDefenseStars = totalDefenses != 0
        ? filteredDefenses.map((defense) => defense.stars).reduce((a, b) => a + b) / totalDefenses
        : 0.0;

    final townHallImageUrl = 'https://clashkingfiles.b-cdn.net/home-base/town-hall-pics/town-hall-$townhallLevel.png';

    return TownhallAttackDefenseStats(
      averageAttackStars: averageAttackStars,
      averageDefenseStars: averageDefenseStars,
      townHallImageUrl: townHallImageUrl,
      townhallLevel: townhallLevel,
      totalAttacks: totalAttacks,
      threeStarsAttacks: threeStarsAttacks,
      twoStarsAttacks: twoStarsAttacks,
      oneStarAttacks: oneStarAttacks,
      zeroStarsAttacks: zeroStarsAttacks,
      averageAttackDestructionPercentage: averageAttackDestructionPercentage,
      totalDefenses: totalDefenses,
      threeStarsDefenses: threeStarsDefenses,
      twoStarsDefenses: twoStarsDefenses,
      oneStarDefenses: oneStarDefenses,
      zeroStarsDefenses: zeroStarsDefenses,
      averageDefenseDestructionPercentage: averageDefenseDestructionPercentage
    );
}


  // Moyenne du pourcentage de destruction par niveau d'hôtel de ville
  double averageDestructionPercentageByTownhall(int townhallLevel) {
    final filteredAttacks = attacks
        .where((attack) => attack.defender.townhallLevel == townhallLevel)
        .toList();

    return filteredAttacks.isNotEmpty
        ? filteredAttacks
                .map((attack) => attack.destructionPercentage)
                .reduce((a, b) => a + b) /
            filteredAttacks.length
        : 0.0;
  }

  // Calcul de la map position moyenne
  double get averageMapPosition => mapPosition.toDouble();

  // Vérification si le joueur attaque tôt ou tard
  String getAttackTiming(int warSize) {
    if (attacks.isEmpty) return "No attacks";

    final firstAttackOrder = attacks.first.order;
    final earlyThreshold = warSize * 0.25;
    final midThreshold = warSize * 0.75;

    if (firstAttackOrder <= earlyThreshold) {
      return "Early";
    } else if (firstAttackOrder <= midThreshold) {
      return "Mid";
    } else {
      return "Late";
    }
  }
}

class Attack {
  final String attackerTag;
  final String defenderTag;
  final int stars;
  final double destructionPercentage;
  final int order;
  final int duration;
  final bool fresh;
  final Defender defender;
  final int attackOrder;
  final String warType;
  final int warStartTime;

  Attack({
    required this.attackerTag,
    required this.defenderTag,
    required this.stars,
    required this.destructionPercentage,
    required this.order,
    required this.duration,
    required this.fresh,
    required this.defender,
    required this.attackOrder,
    required this.warType,
    required this.warStartTime,
  });
}

class Defense {
  final String attackerTag;
  final String defenderTag;
  final int stars;
  final double destructionPercentage;
  final int order;
  final int duration;
  final bool fresh;
  final Attacker attacker;
  final int attackOrder;
  final String warType;
  final int warStartTime;

  Defense({
    required this.attackerTag,
    required this.defenderTag,
    required this.stars,
    required this.destructionPercentage,
    required this.order,
    required this.duration,
    required this.fresh,
    required this.attacker,
    required this.attackOrder,
    required this.warType,
    required this.warStartTime,
  });
}

class Defender {
  final String tag;
  final String name;
  final int townhallLevel;
  final int mapPosition;
  final int opponentAttacks;

  Defender({
    required this.tag,
    required this.name,
    required this.townhallLevel,
    required this.mapPosition,
    required this.opponentAttacks,
  });
}

class Attacker {
  final String tag;
  final String name;
  final int townhallLevel;
  final int mapPosition;
  final int opponentAttacks;

  Attacker({
    required this.tag,
    required this.name,
    required this.townhallLevel,
    required this.mapPosition,
    required this.opponentAttacks,
  });
}
class TownhallAttackDefenseStats {
  final int townhallLevel;
  final int totalAttacks;
  final int threeStarsAttacks;
  final int twoStarsAttacks;
  final int oneStarAttacks;
  final int zeroStarsAttacks;
  final double averageAttackDestructionPercentage;
  final double averageAttackStars;
  final int totalDefenses;
  final int threeStarsDefenses;
  final int twoStarsDefenses;
  final int oneStarDefenses;
  final int zeroStarsDefenses;
  final double averageDefenseDestructionPercentage;
  final double averageDefenseStars;
  final String townHallImageUrl;

  TownhallAttackDefenseStats({
    required this.averageAttackStars,
    required this.averageDefenseStars,
    required this.townHallImageUrl,
    required this.townhallLevel,
    required this.totalAttacks,
    required this.threeStarsAttacks,
    required this.twoStarsAttacks,
    required this.oneStarAttacks,
    required this.zeroStarsAttacks,
    required this.averageAttackDestructionPercentage,
    required this.totalDefenses,
    required this.threeStarsDefenses,
    required this.twoStarsDefenses,
    required this.oneStarDefenses,
    required this.zeroStarsDefenses,
    required this.averageDefenseDestructionPercentage,
  });

  @override
  String toString() {
    return 'TH$townhallLevel: $totalAttacks Attacks, $threeStarsAttacks x 3⭐, $twoStarsAttacks x 2⭐, $oneStarAttacks x 1⭐, $zeroStarsAttacks x 0⭐, Avg. Attack Destruction: ${averageAttackDestructionPercentage.toStringAsFixed(2)}%, '
           '$totalDefenses Defenses, $threeStarsDefenses x 3⭐, $twoStarsDefenses x 2⭐, $oneStarDefenses x 1⭐, $zeroStarsDefenses x 0⭐, Avg. Defense Destruction: ${averageDefenseDestructionPercentage.toStringAsFixed(2)}%';
  }
}
