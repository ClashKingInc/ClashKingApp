import 'dart:math' as math;

import 'package:clashkingapp/features/clan/models/clan_capital_history.dart';

/// Extra client-side raid analytics ported from the ClashCliffs Discord bot
/// (MIT, codeberg.org/Kuchenmampfer/ClashCliffs) — Capital League trophy
/// prediction, projected total loot, and per-district/per-opponent
/// breakdowns — all computed from data already present in the raid payload
/// (`attackLog`/`defenseLog`), same as [RaidMedalPredictor].
class CapitalRaidAnalytics {
  CapitalRaidAnalytics._();

  static const int _capitalPeakDistrictId = 70000000;

  /// Loot the clan is on pace for if it keeps attacking at its current
  /// loot-per-attack rate for all 300 possible attacks (50 members x 6).
  /// Null once the raid has ended (nothing left to project) or before any
  /// attack has been made.
  static int? projectedTotalLoot(CapitalHistoryItem raid) {
    if (raid.state != 'ongoing' || raid.totalAttacks == 0) return null;
    return (raid.capitalTotalLoot / raid.totalAttacks * 300).round();
  }

  /// Predicted Capital League points after this raid, and the resulting
  /// change from [currentCapitalPoints] — ported from ClashCliffs'
  /// `predict_performance`, the formula that replaced its older, less
  /// accurate sqrt-based estimate (the one still used by ClashKingAPI's
  /// `predict_rewards`).
  static TrophyPrediction predictTrophyChange(
    CapitalHistoryItem raid,
    int currentCapitalPoints,
  ) {
    final performance = trophyPerformance(raid);
    final predicted = (currentCapitalPoints * 0.8 + performance * 0.2).round();
    return TrophyPrediction(
      predictedPoints: predicted,
      change: predicted - currentCapitalPoints,
    );
  }

  /// Capital League performance score for a raid week. Supercell derives the
  /// resulting trophy count from this score plus the clan's previous Capital
  /// trophies; exposing it lets the UI show an estimated trophy trend when the
  /// raid history payload does not contain official historical trophy counts.
  static double trophyPerformance(CapitalHistoryItem raid) {
    final attackCount = raid.totalAttacks;
    final avgLoot = attackCount == 0
        ? 0.0
        : raid.capitalTotalLoot / attackCount;
    final projectedOrFinalLoot = raid.state == 'ended'
        ? raid.capitalTotalLoot.toDouble()
        : avgLoot * 300;
    final avgDefLoot = _averageDefensiveLoot(raid);
    return _predictPerformance(projectedOrFinalLoot, avgLoot, avgDefLoot);
  }

  /// Per-district-type totals (Capital Peak + the 5 regular districts),
  /// aggregated across every opponent in [log] — how many were fully
  /// destroyed, how many attacks it took, how much was looted, and a
  /// hit-rate histogram (attacks needed -> how many districts took that
  /// many).
  static List<DistrictStat> districtStats(List<RaidAttackLog> log) {
    final byId = <int, _DistrictAccumulator>{};
    for (final opponent in log) {
      for (final district in opponent.districts) {
        if (district.destructionPercent != 100) continue;
        final acc = byId.putIfAbsent(
          district.id,
          () => _DistrictAccumulator(district.name),
        );
        acc.count += 1;
        acc.attacks += district.attackCount;
        acc.loot += district.totalLooted;
        acc.hitRates.update(
          district.attackCount,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
    }
    final stats = byId.entries
        .map(
          (entry) => DistrictStat(
            id: entry.key,
            name: entry.value.name,
            destroyedCount: entry.value.count,
            attacks: entry.value.attacks,
            loot: entry.value.loot,
            hitRates: Map.unmodifiable(entry.value.hitRates),
          ),
        )
        .toList();
    stats.sort((a, b) => a.id.compareTo(b.id));
    return stats;
  }

  /// One entry per opponent clan faced in [log] (attacked, if offense; or
  /// who attacked us, if defense), sorted by loot descending. Keeps the
  /// raw per-district attack list so the UI can drill into who attacked
  /// what on tap.
  static List<OpponentStat> opponentStats(List<RaidAttackLog> log) {
    final stats = log
        .map(
          (opponent) => OpponentStat(
            clan: opponent.defender,
            attacks: opponent.attackCount,
            districtsDestroyed: opponent.districtsDestroyed,
            districtCount: opponent.districtCount,
            loot: opponent.districts.fold<int>(
              0,
              (sum, district) => sum + district.totalLooted,
            ),
            districts: opponent.districts,
          ),
        )
        .toList();
    stats.sort((a, b) => b.loot.compareTo(a.loot));
    return stats;
  }

  /// Aggregates totals, weekly averages, and the best/worst raid across
  /// every *ended* raid in [raids] — the ongoing week (if any) is excluded
  /// since its numbers are still incomplete. Works entirely from the raid
  /// weeks already loaded for the page, no extra request needed.
  static RaidHistorySummary summarizeHistory(List<CapitalHistoryItem> raids) {
    final ended = raids.where((raid) => raid.state == 'ended').toList();
    if (ended.isEmpty) return const RaidHistorySummary.empty();

    var totalLoot = 0;
    var totalAttacks = 0;
    var totalRaidsCompleted = 0;
    var totalDistrictsDestroyed = 0;
    CapitalHistoryItem? best;
    CapitalHistoryItem? worst;

    int rewardOf(CapitalHistoryItem raid) =>
        6 * raid.offensiveReward + raid.defensiveReward;

    for (final raid in ended) {
      totalLoot += raid.capitalTotalLoot;
      totalAttacks += raid.totalAttacks;
      totalRaidsCompleted += raid.raidsCompleted;
      totalDistrictsDestroyed += raid.enemyDistrictsDestroyed;
      if (best == null || rewardOf(raid) > rewardOf(best)) best = raid;
      if (worst == null || rewardOf(raid) < rewardOf(worst)) worst = raid;
    }

    return RaidHistorySummary(
      weeksCounted: ended.length,
      totalLoot: totalLoot,
      totalAttacks: totalAttacks,
      totalRaidsCompleted: totalRaidsCompleted,
      totalDistrictsDestroyed: totalDistrictsDestroyed,
      avgLootPerWeek: totalLoot / ended.length,
      avgAttacksPerWeek: totalAttacks / ended.length,
      bestRaid: best,
      worstRaid: worst,
    );
  }

  /// Count of districts one-shot (destroyed in a single attack) versus
  /// "failed" (Capital Peak taking more than 3 attacks, or a regular
  /// district taking more than 2) — a rough offense/defense efficiency
  /// signal.
  static AttackEfficiency attackEfficiency(List<RaidAttackLog> log) {
    var oneshots = 0;
    var fails = 0;
    for (final opponent in log) {
      for (final district in opponent.districts) {
        if (district.destructionPercent != 100) continue;
        if (district.attackCount == 1) {
          oneshots += 1;
        } else if (district.id == _capitalPeakDistrictId) {
          if (district.attackCount > 3) fails += 1;
        } else if (district.attackCount > 2) {
          fails += 1;
        }
      }
    }
    return AttackEfficiency(oneshots: oneshots, fails: fails);
  }

  /// Aggregates every individual attack in the offensive log by attacker.
  ///
  /// The API does not expose loot per individual hit, only at district level,
  /// so these stats intentionally focus on hit count, stars and destruction.
  static List<PlayerAttackStat> playerAttackStats(List<RaidAttackLog> log) {
    final byTag = <String, _PlayerAttackAccumulator>{};
    for (final opponent in log) {
      for (final district in opponent.districts) {
        for (final attack in district.attacks ?? const <Attack>[]) {
          final key = attack.tag.isEmpty ? attack.name : attack.tag;
          final acc = byTag.putIfAbsent(
            key,
            () => _PlayerAttackAccumulator(attack.name, attack.tag),
          );
          acc.attacks += 1;
          acc.stars += attack.stars;
          acc.destruction += attack.destructionPercent;
          if (attack.stars >= 3 || attack.destructionPercent >= 100) {
            acc.perfectHits += 1;
          }
        }
      }
    }

    final stats = byTag.values
        .map(
          (acc) => PlayerAttackStat(
            name: acc.name,
            tag: acc.tag,
            attacks: acc.attacks,
            stars: acc.stars,
            destruction: acc.destruction,
            perfectHits: acc.perfectHits,
          ),
        )
        .toList();
    stats.sort((a, b) {
      final attackCompare = b.attacks.compareTo(a.attacks);
      if (attackCompare != 0) return attackCompare;
      final starCompare = b.stars.compareTo(a.stars);
      if (starCompare != 0) return starCompare;
      return b.avgDestruction.compareTo(a.avgDestruction);
    });
    return stats;
  }

  /// Defense-focused view of our own districts from defenseLog: how often
  /// each district was hit, destroyed, held, and how much loot it gave up.
  static List<DistrictDefenseStat> districtDefenseStats(
    List<RaidAttackLog> log,
  ) {
    final byId = <int, _DistrictDefenseAccumulator>{};
    for (final opponent in log) {
      for (final district in opponent.districts) {
        final acc = byId.putIfAbsent(
          district.id,
          () => _DistrictDefenseAccumulator(district.name),
        );
        acc.defenses += 1;
        acc.attacksTaken += district.attackCount;
        acc.destruction += district.destructionPercent;
        acc.lootLost += district.totalLooted;
        if (district.destructionPercent >= 100) {
          acc.destroyed += 1;
        } else {
          acc.held += 1;
        }
      }
    }

    final stats = byId.entries
        .map(
          (entry) => DistrictDefenseStat(
            id: entry.key,
            name: entry.value.name,
            defenses: entry.value.defenses,
            destroyed: entry.value.destroyed,
            held: entry.value.held,
            attacksTaken: entry.value.attacksTaken,
            destruction: entry.value.destruction,
            lootLost: entry.value.lootLost,
          ),
        )
        .toList();
    stats.sort((a, b) {
      final heldCompare = b.held.compareTo(a.held);
      if (heldCompare != 0) return heldCompare;
      return a.avgDestruction.compareTo(b.avgDestruction);
    });
    return stats;
  }

  static double _predictPerformance(
    double loot,
    double avgLoot,
    double avgDefLoot,
  ) {
    const threshold = 664;
    final center = math.pow(loot < 0 ? 0 : loot, 0.6).toDouble();
    final skill = avgLoot - avgDefLoot;
    final double perf;
    if (skill > threshold) {
      perf = center + 50 * math.log(skill) + 360;
    } else if (skill < -threshold) {
      perf = center - 50 * math.log(-skill) - 360;
    } else {
      perf = center + skill + 34;
    }
    return perf < 0 ? 0 : perf;
  }

  /// Average defensive loot per attack, padded with a "dummy" baseline
  /// (3.5 attacks per district) so a handful of early defenses don't skew
  /// the average — same padding ClashCliffs uses.
  static double _averageDefensiveLoot(CapitalHistoryItem raid) {
    final defenseLog = raid.defenseLog ?? const [];
    if (defenseLog.isEmpty) return 0;

    final districtCount = defenseLog.first.districtCount;
    final dummyAttackCount = 3.5 * districtCount;

    final fullyDestroyedOpponents = defenseLog
        .where(
          (opponent) => opponent.districtsDestroyed == opponent.districtCount,
        )
        .toList();
    final lootPerDefense = fullyDestroyedOpponents.isEmpty
        ? 0.0
        : fullyDestroyedOpponents
                  .map(
                    (opponent) => opponent.districts.fold<int>(
                      0,
                      (sum, district) => sum + district.totalLooted,
                    ),
                  )
                  .reduce((a, b) => a + b) /
              fullyDestroyedOpponents.length;

    var totalDefensiveLoot = 0;
    var defenseAttackCount = 0;
    for (final opponent in defenseLog) {
      for (final district in opponent.districts) {
        if (district.destructionPercent != 100) continue;
        totalDefensiveLoot += district.totalLooted;
        defenseAttackCount += district.attackCount;
      }
    }

    final denominator = defenseAttackCount + dummyAttackCount;
    return denominator == 0
        ? 0.0
        : (totalDefensiveLoot + lootPerDefense) / denominator;
  }
}

class TrophyPrediction {
  final int predictedPoints;
  final int change;

  const TrophyPrediction({required this.predictedPoints, required this.change});
}

class DistrictStat {
  final int id;
  final String name;
  final int destroyedCount;
  final int attacks;
  final int loot;
  final Map<int, int> hitRates;

  const DistrictStat({
    required this.id,
    required this.name,
    required this.destroyedCount,
    required this.attacks,
    required this.loot,
    required this.hitRates,
  });

  double get avgAttacksPerDestroy =>
      destroyedCount == 0 ? 0 : attacks / destroyedCount;

  double get avgLootPerAttack => attacks == 0 ? 0 : loot / attacks;
}

class OpponentStat {
  final RaidDefender clan;
  final int attacks;
  final int districtsDestroyed;
  final int districtCount;
  final int loot;
  final List<District> districts;

  const OpponentStat({
    required this.clan,
    required this.attacks,
    required this.districtsDestroyed,
    required this.districtCount,
    required this.loot,
    required this.districts,
  });
}

class AttackEfficiency {
  final int oneshots;
  final int fails;

  const AttackEfficiency({required this.oneshots, required this.fails});
}

class PlayerAttackStat {
  final String name;
  final String tag;
  final int attacks;
  final int stars;
  final int destruction;
  final int perfectHits;

  const PlayerAttackStat({
    required this.name,
    required this.tag,
    required this.attacks,
    required this.stars,
    required this.destruction,
    required this.perfectHits,
  });

  double get avgStars => attacks == 0 ? 0 : stars / attacks;

  double get avgDestruction => attacks == 0 ? 0 : destruction / attacks;
}

class DistrictDefenseStat {
  final int id;
  final String name;
  final int defenses;
  final int destroyed;
  final int held;
  final int attacksTaken;
  final int destruction;
  final int lootLost;

  const DistrictDefenseStat({
    required this.id,
    required this.name,
    required this.defenses,
    required this.destroyed,
    required this.held,
    required this.attacksTaken,
    required this.destruction,
    required this.lootLost,
  });

  double get avgAttacksTaken => defenses == 0 ? 0 : attacksTaken / defenses;

  double get avgDestruction => defenses == 0 ? 0 : destruction / defenses;
}

class RaidHistorySummary {
  final int weeksCounted;
  final int totalLoot;
  final int totalAttacks;
  final int totalRaidsCompleted;
  final int totalDistrictsDestroyed;
  final double avgLootPerWeek;
  final double avgAttacksPerWeek;
  final CapitalHistoryItem? bestRaid;
  final CapitalHistoryItem? worstRaid;

  const RaidHistorySummary({
    required this.weeksCounted,
    required this.totalLoot,
    required this.totalAttacks,
    required this.totalRaidsCompleted,
    required this.totalDistrictsDestroyed,
    required this.avgLootPerWeek,
    required this.avgAttacksPerWeek,
    required this.bestRaid,
    required this.worstRaid,
  });

  const RaidHistorySummary.empty()
    : weeksCounted = 0,
      totalLoot = 0,
      totalAttacks = 0,
      totalRaidsCompleted = 0,
      totalDistrictsDestroyed = 0,
      avgLootPerWeek = 0,
      avgAttacksPerWeek = 0,
      bestRaid = null,
      worstRaid = null;

  int rewardOf(CapitalHistoryItem raid) =>
      6 * raid.offensiveReward + raid.defensiveReward;
}

class _DistrictAccumulator {
  _DistrictAccumulator(this.name);

  final String name;
  int count = 0;
  int attacks = 0;
  int loot = 0;
  final Map<int, int> hitRates = {};
}

class _PlayerAttackAccumulator {
  _PlayerAttackAccumulator(this.name, this.tag);

  final String name;
  final String tag;
  int attacks = 0;
  int stars = 0;
  int destruction = 0;
  int perfectHits = 0;
}

class _DistrictDefenseAccumulator {
  _DistrictDefenseAccumulator(this.name);

  final String name;
  int defenses = 0;
  int destroyed = 0;
  int held = 0;
  int attacksTaken = 0;
  int destruction = 0;
  int lootLost = 0;
}
