import 'package:clashkingapp/features/player/models/player_enemy_townhall_stats.dart';
import 'package:clashkingapp/features/war_cwl/models/war_attack.dart';

class PlayerWarStats {
  final String name;
  final String tag;
  final int townhallLevel;
  final Map<String, PlayerWarTypeStats> statsByType;
  final Map<String, int> timeRange;
  List<PlayerWarStatsData>? wars;

  PlayerWarStats({
    required this.name,
    required this.tag,
    required this.townhallLevel,
    required this.timeRange,
    this.wars,
    required this.statsByType,
  });

  factory PlayerWarStats.fromJson(
      Map<String, dynamic> json, String? playerTag, List<dynamic>? wars) {
    try {
      return PlayerWarStats(
        name: json['name'] ?? '',
        tag: json['tag'] ?? '',
        townhallLevel: json['townhallLevel'] ?? 0,
        timeRange: json['timeRange'] != null
            ? Map<String, int>.from(json['timeRange'])
            : {'start': 0, 'end': 0},
        wars: wars != null
            ? wars
                .map((w) =>
                    PlayerWarStatsData.fromJson(w, playerTag ?? json['tag']))
                .toList()
            : [],
        statsByType: (json['stats'] as Map<String, dynamic>)
            .map((key, value) => MapEntry(
                  key,
                  PlayerWarTypeStats.fromJson(value),
                )),
      );
    } catch (e) {
      print('Error parsing PlayerWarStats: $e');
      return PlayerWarStats(
        name: json['name'] ?? '',
        tag: json['tag'] ?? '',
        townhallLevel: json['townhallLevel'] ?? 0,
        timeRange: {'start': 0, 'end': 0},
        wars: [],
        statsByType: {},
      );
    }
  }

  PlayerWarTypeStats getSpecificStats(String warType) {
    return statsByType[warType] ?? _emptyStats;
  }

  PlayerWarTypeStats getStatsForTypes(List<String> types) {
    if (types.isEmpty) return statsByType['all'] ?? _emptyStats;

    int totalAttacks = 0;
    int totalDefenses = 0;
    int warsCounts = 0;
    int missedAttacks = 0;
    int missedDefenses = 0;

    final starsCount = <String, int>{'0': 0, '1': 0, '2': 0, '3': 0};
    final starsCountDef = <String, int>{'0': 0, '1': 0, '2': 0, '3': 0};

    final Map<String, EnemyTownhallStats> byEnemyTownhall = {};
    final Map<String, EnemyTownhallStats> byEnemyTownhallDef = {};

    for (final type in types) {
      final s = statsByType[type];
      if (s == null) continue;

      totalAttacks += s.totalAttacks;
      totalDefenses += s.totalDefenses;
      warsCounts += s.warsCounts;
      missedAttacks += s.missedAttacks;
      missedDefenses += s.missedDefenses;

      // Stars count
      for (var k in starsCount.keys) {
        starsCount[k] = (starsCount[k] ?? 0) + (s.starsCount[k] ?? 0);
        starsCountDef[k] = (starsCountDef[k] ?? 0) + (s.starsCountDef[k] ?? 0);
      }

      // Attacks per enemy TH
      s.byEnemyTownhall.forEach((th, stats) {
        final existing = byEnemyTownhall[th];
        if (existing == null) {
          byEnemyTownhall[th] = stats.copy();
        } else {
          existing.merge(stats);
        }
      });

      // Defenses per enemy TH
      s.byEnemyTownhallDef.forEach((th, stats) {
        final existing = byEnemyTownhallDef[th];
        if (existing == null) {
          byEnemyTownhallDef[th] = stats.copy();
        } else {
          existing.merge(stats);
        }
      });
    }

    return PlayerWarTypeStats(
      warsCounts: warsCounts,
      totalAttacks: totalAttacks,
      totalDefenses: totalDefenses,
      missedAttacks: missedAttacks,
      missedDefenses: missedDefenses,
      starsCount: starsCount,
      starsCountDef: starsCountDef,
      byEnemyTownhall: byEnemyTownhall,
      byEnemyTownhallDef: byEnemyTownhallDef,
    );
  }

  static final PlayerWarTypeStats _emptyStats = PlayerWarTypeStats(
    warsCounts: 0,
    totalAttacks: 0,
    totalDefenses: 0,
    missedAttacks: 0,
    missedDefenses: 0,
    starsCount: {},
    starsCountDef: {},
    byEnemyTownhall: {},
    byEnemyTownhallDef: {},
  );
}

class PlayerWarTypeStats {
  final int warsCounts;
  final int totalAttacks;
  final int totalDefenses;
  final int missedAttacks;
  final int missedDefenses;
  final Map<String, int> starsCount;
  final Map<String, int> starsCountDef;
  final Map<String, EnemyTownhallStats> byEnemyTownhall;
  final Map<String, EnemyTownhallStats> byEnemyTownhallDef;

  PlayerWarTypeStats({
    required this.warsCounts,
    required this.totalAttacks,
    required this.totalDefenses,
    required this.missedAttacks,
    required this.missedDefenses,
    required this.starsCount,
    required this.starsCountDef,
    required this.byEnemyTownhall,
    required this.byEnemyTownhallDef,
  });

  double get averageStars {
    final totalStars = starsCount.entries.fold<int>(
      0,
      (sum, entry) => sum + int.parse(entry.key) * entry.value,
    );
    return totalAttacks > 0 ? totalStars / totalAttacks : 0.0;
  }

  double get averageStarsDef {
    final totalStarsDef = starsCountDef.entries.fold<int>(
      0,
      (sum, entry) => sum + int.parse(entry.key) * entry.value,
    );
    return totalDefenses > 0 ? totalStarsDef / totalDefenses : 0.0;
  }

  double get averageDestruction {
    final totalDestruction = byEnemyTownhall.values.fold<double>(
      0,
      (sum, e) => sum + (e.averageDestruction * e.count),
    );
    final totalHits = byEnemyTownhall.values.fold<int>(
      0,
      (sum, e) => sum + e.count,
    );
    return totalHits > 0 ? totalDestruction / totalHits : 0.0;
  }

  double get averageDestructionDef {
    final totalDestructionDef = byEnemyTownhallDef.values.fold<double>(
      0,
      (sum, e) => sum + (e.averageDestruction * e.count),
    );
    final totalHitsDef = byEnemyTownhallDef.values.fold<int>(
      0,
      (sum, e) => sum + e.count,
    );
    return totalHitsDef > 0 ? totalDestructionDef / totalHitsDef : 0.0;
  }

  Map<String, int> getFilteredStarsCountByEnemyTh({
    required List<int> selectedThLevels,
  }) {
    // Initialize result with 0 stars
    final Map<String, int> result = {
      "0": 0,
      "1": 0,
      "2": 0,
      "3": 0,
    };

    // If no filter is applied, return the default starsCount
    if (selectedThLevels.isEmpty) {
      return starsCount;
    }

    for (final th in selectedThLevels) {
      final thStats = byEnemyTownhall[th.toString()];
      if (thStats != null) {
        for (final entry in thStats.starsCount.entries) {
          result[entry.key] = result[entry.key]! + entry.value;
        }
      }
    }

    return result;
  }

  Map<String, int> getStarsCountAgainstTh(int? thLevel) {
    print("TH Level: $thLevel");
    if (thLevel == null || byEnemyTownhall.isEmpty) return starsCount;

    final stats = byEnemyTownhall["$thLevel"];
    print("Stats: $stats");
    return stats?.starsCount ?? {};
  }

  factory PlayerWarTypeStats.fromJson(Map<String, dynamic> json) {
    return PlayerWarTypeStats(
      warsCounts: json['warsCounts'] ?? 0,
      totalAttacks: json['totalAttacks'] ?? 0,
      totalDefenses: json['totalDefenses'] ?? 0,
      missedAttacks: json['missedAttacks'] ?? 0,
      missedDefenses: json['missedDefenses'] ?? 0,
      starsCount: Map<String, int>.from(json['starsCount']),
      starsCountDef: Map<String, int>.from(json['starsCountDef']),
      byEnemyTownhall: (json['byEnemyTownhall'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, EnemyTownhallStats.fromJson(value))),
      byEnemyTownhallDef: (json['byEnemyTownhallDef'] as Map<String, dynamic>)
          .map((key, value) =>
              MapEntry(key, EnemyTownhallStats.fromJson(value))),
    );
  }
}

class PlayerWarStatsData {
  final PlayerWarStatsDetails warDetails;
  final WarMemberData memberData;

  PlayerWarStatsData({
    required this.warDetails,
    required this.memberData,
  });

  factory PlayerWarStatsData.fromJson(
      Map<String, dynamic> json, String playerTag) {
    try {
      final warDetails = PlayerWarStatsDetails.fromJson(json['war_data']);
      final members = json['members'] as List<dynamic>? ?? [];

      // On ne peut parser qu'un seul membre ici, donc on choisit le premier si présent
      if (members.isEmpty) throw Exception("No members in war json");

      final member =
          members.firstWhere((m) => m['tag'] == playerTag, orElse: () => null);

      if (member == null) {
        throw Exception("Member with tag $playerTag not found in war.");
      }

      return PlayerWarStatsData(
        warDetails: warDetails,
        memberData: WarMemberData.fromJson(member),
      );
    } catch (e) {
      print('Error parsing PlayerWarStatsData: $e');
      return PlayerWarStatsData(
        warDetails: PlayerWarStatsDetails(
          state: 'unknown',
          teamSize: 0,
          attacksPerMember: 0,
          battleModifier: '',
          preparationStartTime: '',
          startTime: '',
          endTime: '',
          clan: ClanInfo(
            tag: '',
            name: '',
            badgeUrls: {},
            clanLevel: 0,
            attacks: 0,
            stars: 0,
            destructionPercentage: 0.0,
          ),
          opponent: ClanInfo(
            tag: '',
            name: '',
            badgeUrls: {},
            clanLevel: 0,
            attacks: 0,
            stars: 0,
            destructionPercentage: 0.0,
          ),
          type: '',
        ),
        memberData: WarMemberData(
          tag: '',
          name: '',
          townhallLevel: 0,
          mapPosition: 0,
          opponentAttacks: 0,
          attacks: [],
          defenses: [],
        ),
      );
    }
  }
}

// Represents the war information from "war_data"
class PlayerWarStatsDetails {
  final String state;
  final int teamSize;
  final int attacksPerMember;
  final String battleModifier;
  final String preparationStartTime;
  final String startTime;
  final String endTime;
  final ClanInfo clan;
  final ClanInfo opponent;
  final String type;

  PlayerWarStatsDetails({
    required this.state,
    required this.teamSize,
    required this.attacksPerMember,
    required this.battleModifier,
    required this.preparationStartTime,
    required this.startTime,
    required this.endTime,
    required this.clan,
    required this.opponent,
    required this.type,
  });

  factory PlayerWarStatsDetails.fromJson(Map<String, dynamic> json) {
    return PlayerWarStatsDetails(
      state: json['state'] ?? '',
      teamSize: (json['teamSize'] ?? 0) as int,
      attacksPerMember: (json['attacksPerMember'] ?? 0) as int,
      battleModifier: json['battleModifier'] ?? '',
      preparationStartTime: json['preparationStartTime'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      clan: ClanInfo.fromJson(json['clan'] ?? {}),
      opponent: ClanInfo.fromJson(json['opponent'] ?? {}),
      type: json['type'] ?? '',
    );
  }
}

// Represents the clan or opponent info
class ClanInfo {
  final String tag;
  final String name;
  final Map<String, dynamic> badgeUrls;
  final int clanLevel;
  final int attacks;
  final int stars;
  final double destructionPercentage;

  ClanInfo({
    required this.tag,
    required this.name,
    required this.badgeUrls,
    required this.clanLevel,
    required this.attacks,
    required this.stars,
    required this.destructionPercentage,
  });

  factory ClanInfo.fromJson(Map<String, dynamic> json) {
    return ClanInfo(
      tag: json['tag'] ?? '',
      name: json['name'] ?? '',
      badgeUrls: Map<String, dynamic>.from(json['badgeUrls'] ?? {}),
      clanLevel: (json['clanLevel'] ?? 0) as int,
      attacks: (json['attacks'] ?? 0) as int,
      stars: (json['stars'] ?? 0) as int,
      destructionPercentage: (json['destructionPercentage'] ?? 0).toDouble(),
    );
  }
}

// Represents the member data from "member_data"
class WarMemberData {
  final String tag;
  final String name;
  final int townhallLevel;
  final int mapPosition;
  final int opponentAttacks;
  final List<WarAttack> attacks;
  final List<WarAttack> defenses;

  WarMemberData({
    required this.tag,
    required this.name,
    required this.townhallLevel,
    required this.mapPosition,
    required this.opponentAttacks,
    required this.attacks,
    required this.defenses,
  });

  factory WarMemberData.fromJson(Map<String, dynamic> json) {
    return WarMemberData(
      tag: json['tag'] ?? '',
      name: json['name'] ?? '',
      townhallLevel: (json['townhallLevel'] ?? 0) as int,
      mapPosition: (json['mapPosition'] ?? 0) as int,
      opponentAttacks: (json['opponentAttacks'] ?? 0) as int,
      attacks: (json['attacks'] as List<dynamic>? ?? [])
          .map((a) => WarAttack.fromJson(a))
          .toList(),
      defenses: (json['defenses'] as List<dynamic>? ?? [])
          .map((d) => WarAttack.fromJson(d))
          .toList(),
    );
  }
}
