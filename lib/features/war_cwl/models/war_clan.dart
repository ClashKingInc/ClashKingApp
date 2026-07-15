import 'package:clashkingapp/features/clan/models/clan_badge.dart';
import 'package:clashkingapp/features/war_cwl/models/war_member.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';

class WarClan {
  static const String _noTag = 'No tag';
  static const String _noName = 'No name';

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

  factory WarClan.fromJson(Map<String, dynamic>? json) {
    try {
      final data = json ?? const <String, dynamic>{};

      return WarClan(
        tag: data['tag']?.toString() ?? _noTag,
        name: data['name']?.toString() ?? _noName,
        badgeUrls: ClanBadgeUrls.fromJson(_asMap(data['badgeUrls'])),
        clanLevel: (data['clanLevel'] as num?)?.toInt() ?? 0,
        attacks: (data['attacks'] as num?)?.toInt() ?? 0,
        stars: (data['stars'] as num?)?.toInt() ?? 0,
        destructionPercentage:
            (data['destructionPercentage'] as num?)?.toDouble() ?? 0.0,
        members:
            (data['members'] as List<dynamic>?)
                ?.whereType<Map>()
                .map((e) => WarMember.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [],
      );
    } catch (e) {
      DebugUtils.debugError(" Error parsing WarClan: $e");
      return WarClan(
        tag: _noTag,
        name: _noName,
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
      tag: _noTag,
      name: _noName,
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

  /// Calculate average attack duration in seconds for all clan attacks
  /// Returns null if no attack duration data is available
  double? getAverageAttackTime() {
    int totalDuration = 0;
    int attackCount = 0;

    for (final member in members) {
      if (member.attacks != null) {
        for (final attack in member.attacks!) {
          if (attack.duration != null) {
            totalDuration += attack.duration!;
            attackCount++;
          }
        }
      }
    }

    // Return average duration in seconds, or null if no duration data available
    return attackCount > 0 ? totalDuration / attackCount : null;
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
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}
