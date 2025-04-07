import 'package:clashkingapp/features/clan/models/clan_badge.dart';
import 'package:clashkingapp/features/war_cwl/models/cwl_attacks_defenses_stats.dart';
import 'package:clashkingapp/features/war_cwl/models/cwl_member.dart';

class CwlClan {
  final String tag;
  final String name;
  final ClanBadgeUrls badgeUrls;
  final int clanLevel;
  final int attackCount;
  final int stars;
  final double destructionPercentage;
  final double destructionPercentageInflicted;
  final List<CwlMember> members;
  final int rank;
  final int warsPlayed;
  final Map<String, int> townHallLevels;

  int get missedAttacks {
    int totalAttacks = 0;
    for (var member in members) {
      totalAttacks += member.attackStats?.missedAttacks ?? 0;
    }
    return totalAttacks;
  }

  int _sumStars(Map<String, int> Function(CwlAttackStats) selector) {
    int total = 0;
    for (var member in members) {
      final stats = member.attackStats;
      if (stats != null) {
        final starsMap = selector(stats);
        total += starsMap.values.fold(0, (a, b) => a + b);
      }
    }
    return total;
  }

  int get threeStars => _sumStars((stats) => stats.threeStars);
  int get twoStars => _sumStars((stats) => stats.twoStars);
  int get oneStar => _sumStars((stats) => stats.oneStar);
  int get zeroStar => _sumStars((stats) => stats.zeroStar);

  int get defStars {
    int totalDefStars = 0;
    for (var member in members) {
      totalDefStars += member.defenseStats?.stars ?? 0;
    }
    return totalDefStars;
  }

  num get defDestruction {
    num totalDefStars = 0;
    for (var member in members) {
      totalDefStars += member.defenseStats?.totalDestruction ?? 0;
    }
    return totalDefStars;
  }

  num get averageStars {
    num totalAverageStars = 0;
    for (var member in members) {
      totalAverageStars += member.attackStats?.averageStars ?? 0;
    }
    return totalAverageStars;
  }

  num get averageDestruction {
    num totalAverageDestruction = 0;
    for (var member in members) {
      totalAverageDestruction += member.attackStats?.averageDestruction ?? 0;
    }
    return totalAverageDestruction;
  }

  CwlClan({
    required this.tag,
    required this.name,
    required this.badgeUrls,
    required this.clanLevel,
    required this.attackCount,
    required this.stars,
    required this.destructionPercentage,
    required this.destructionPercentageInflicted,
    required this.members,
    required this.rank,
    required this.warsPlayed,
    required this.townHallLevels,
  });

  factory CwlClan.fromJson(Map<String, dynamic> json) {
    try {
      return CwlClan(
        tag: json['tag'],
        name: json['name'],
        badgeUrls: ClanBadgeUrls.fromJson(json['badgeUrls']),
        clanLevel: json['clanLevel'],
        attackCount: json['attack_count'] ?? 0,
        stars: json['total_stars'] ?? 0,
        destructionPercentage:
            (json['total_destruction'] as num?)?.toDouble() ?? 0.0,
        destructionPercentageInflicted:
            (json['total_destruction_inflicted'] as num?)?.toDouble() ?? 0.0,
        rank: json['rank'] ?? 0,
        warsPlayed: json['wars_played'] ?? 0,
        members: (json['members'] as List<dynamic>?)
                ?.map((e) => CwlMember.fromJson(e))
                .toList() ??
            [],
        townHallLevels: Map<String, int>.from(json['town_hall_levels'] ?? {}),
      );
    } catch (e) {
      print("❌ Error parsing WarClan: $e");
      return CwlClan(
        tag: 'No tag',
        name: 'No name',
        badgeUrls: ClanBadgeUrls(
          small: 'No small',
          medium: 'No medium',
          large: 'No large',
        ),
        clanLevel: 0,
        attackCount: 0,
        stars: 0,
        destructionPercentage: 0.0,
        destructionPercentageInflicted: 0.0,
        rank: 0,
        warsPlayed: 0,
        members: [],
        townHallLevels: {},
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'tag': tag,
      'name': name,
      'clanLevel': clanLevel,
      'attacks': attackCount,
      'stars': stars,
      'destructionPercentage': destructionPercentage,
      'members': members.map((e) => e.toJson()).toList(),
    };
  }

  factory CwlClan.empty() => CwlClan(
        tag: '',
        name: '',
        badgeUrls: ClanBadgeUrls.empty(),
        clanLevel: 0,
        attackCount: 0,
        stars: 0,
        destructionPercentage: 0.0,
        destructionPercentageInflicted: 0.0,
        members: [],
        rank: 0,
        warsPlayed: 0,
        townHallLevels: {},
      );
}
