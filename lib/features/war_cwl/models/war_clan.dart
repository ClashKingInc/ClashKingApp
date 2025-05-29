import 'package:clashkingapp/features/clan/models/clan_badge.dart';
import 'package:clashkingapp/features/war_cwl/models/war_member.dart';

class WarClan {
  final String tag;
  final String name;
  final ClanBadgeUrls badgeUrls;
  final int clanLevel;
  final int attacks;
  final int stars;
  final double destructionPercentage;
  final List<WarMember> members;

  WarClan({
    required this.tag,
    required this.name,
    required this.badgeUrls,
    required this.clanLevel,
    required this.attacks,
    required this.stars,
    required this.destructionPercentage,
    required this.members,
  });

  factory WarClan.fromJson(Map<String, dynamic> json) {
    try {
      return WarClan(
        tag: json['tag'],
        name: json['name'],
        badgeUrls: ClanBadgeUrls.fromJson(json['badgeUrls']),
        clanLevel: json['clanLevel'],
        attacks: json['attacks'] ?? 0,
        stars: json['stars'] ?? 0,
        destructionPercentage:
            (json['destructionPercentage'] as num?)?.toDouble() ?? 0.0,
        members: (json['members'] as List<dynamic>?)
                ?.map((e) => WarMember.fromJson(e))
                .toList() ??
            [],
      );
    } catch (e) {
      print("❌ Error parsing WarClan: $e");
      return WarClan(
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
        members: [],
      );
    }
  }

  factory WarClan.empty() {
    return WarClan(
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
      members: [],
    );
  }

  get expEarned => null;

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
}
