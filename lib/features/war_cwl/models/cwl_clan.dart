import 'package:clashkingapp/features/clan/models/clan_badge.dart';
import 'package:clashkingapp/features/war_cwl/models/cwl_member.dart';

class CwlClan {
  final String tag;
  final String name;
  final ClanBadgeUrls badgeUrls;
  final int clanLevel;
  final int attacks;
  final int stars;
  final double destructionPercentage;
  final double destructionPercentageInflicted;
  final List<CwlMember> members;
  final int rank;
  final int warsPlayed;

  CwlClan({
    required this.tag,
    required this.name,
    required this.badgeUrls,
    required this.clanLevel,
    required this.attacks,
    required this.stars,
    required this.destructionPercentage,
    required this.destructionPercentageInflicted,
    required this.members,
    required this.rank,
    required this.warsPlayed,
  });

  factory CwlClan.fromJson(Map<String, dynamic> json) {
    try {
      return CwlClan(
        tag: json['tag'],
        name: json['name'],
        badgeUrls: ClanBadgeUrls.fromJson(json['badgeUrls']),
        clanLevel: json['clanLevel'],
        attacks: json['attack_count'] ?? 0,
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
        attacks: 0,
        stars: 0,
        destructionPercentage: 0.0,
        destructionPercentageInflicted: 0.0,
        rank: 0,
        warsPlayed: 0,
        members: [],
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'tag': tag,
      'name': name,
      'clanLevel': clanLevel,
      'attacks': attacks,
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
        attacks: 0,
        stars: 0,
        destructionPercentage: 0.0,
        destructionPercentageInflicted: 0.0,
        members: [],
        rank: 0,
        warsPlayed: 0,
      );
}
