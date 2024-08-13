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
  final String season;

  WarStats({
    required this.season,
    required this.timeStampsStart,
    required this.timeStampsEnd,
    required this.playerTag,
    required this.playerName,
    required this.townhallLevel,
    required this.mapPosition,
    required this.opponentAttacks,
    required this.attacks,
    required this.defenses,
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

  double percentageOfStarsAttacks(int numberOfStars) {
    final filteredAttacks =
        attacks.where((attack) => attack.stars == numberOfStars).toList();

    return filteredAttacks.isNotEmpty
        ? filteredAttacks.length / attacks.length * 100
        : 0.0;
  }

  List<int> opponentTownhallLevels() {
    return attacks
        .map((attack) => attack.defender.townhallLevel)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
  }

  double percentageOfStarsDefenses(int numberOfStars) {
    final filteredDefenses =
        defenses.where((defense) => defense.stars == numberOfStars).toList();

    return filteredDefenses.isNotEmpty
        ? filteredDefenses.length / defenses.length * 100
        : 0.0;
  }

  TownhallAttackStats getTownhallAttackStats(int townhallLevel) {
    final filteredAttacks = attacks
        .where((attack) => attack.defender.townhallLevel == townhallLevel)
        .toList();

    final totalAttacks = filteredAttacks.length;
    final threeStars =
        filteredAttacks.where((attack) => attack.stars == 3).length;
    final twoStars =
        filteredAttacks.where((attack) => attack.stars == 2).length;
    final oneStar = filteredAttacks.where((attack) => attack.stars == 1).length;
    final zeroStars =
        filteredAttacks.where((attack) => attack.stars == 0).length;
    final averageDestructionPercentage = filteredAttacks.isNotEmpty
        ? filteredAttacks
                .map((attack) => attack.destructionPercentage)
                .reduce((a, b) => a + b) /
            totalAttacks
        : 0.0;
    
    final averageStars = totalAttacks != 0 ? filteredAttacks.map((attack) => attack.stars).reduce((a, b) => a + b) / totalAttacks : 0.0;

    final townHallpic = 'https://clashkingfiles.b-cdn.net/home-base/town-hall-pics/town-hall-$townhallLevel.png';

    return TownhallAttackStats(
      averageStars: averageStars,
      townHallImageUrl : townHallpic,
      townhallLevel: townhallLevel,
      totalAttacks: totalAttacks,
      threeStars: threeStars,
      twoStars: twoStars,
      oneStar: oneStar,
      zeroStars: zeroStars,
      averageDestructionPercentage: averageDestructionPercentage,
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

class TownhallAttackStats {
  final int townhallLevel;
  final int totalAttacks;
  final int threeStars;
  final int twoStars;
  final int oneStar;
  final int zeroStars;
  final double averageDestructionPercentage;
  final double averageStars;
  final String townHallImageUrl;

  TownhallAttackStats({
    required this.averageStars,
    required this.townHallImageUrl,
    required this.townhallLevel,
    required this.totalAttacks,
    required this.threeStars,
    required this.twoStars,
    required this.oneStar,
    required this.zeroStars,
    required this.averageDestructionPercentage,
  });

  @override
  String toString() {
    return 'TH$townhallLevel: $totalAttacks Attacks, $threeStars x 3⭐, $twoStars x 2⭐, $oneStar x 1⭐, $zeroStars x 0⭐, Avg. Destruction: ${averageDestructionPercentage.toStringAsFixed(2)}%';
  }
}
