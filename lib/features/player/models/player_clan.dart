import 'package:clashkingapp/features/clan/models/clan_badge.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';

class PlayerClanOverview {
  final String tag;
  final String name;
  final int clanLevel;
  final ClanBadgeUrls badgeUrls;

  PlayerClanOverview({
    required this.tag,
    required this.name,
    required this.clanLevel,
    required this.badgeUrls,
  });

  factory PlayerClanOverview.fromJson(Map<String, dynamic> json) {
    try {
      return PlayerClanOverview(
        tag: json['tag']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        clanLevel: (json['clanLevel'] as num?)?.toInt() ?? 0,
        badgeUrls: ClanBadgeUrls.fromJson(
          (json['badgeUrls'] as Map<String, dynamic>?) ?? {},
        ),
      );
    } catch (e) {
      DebugUtils.debugError(" Error parsing PlayerClanOverview: $e");
      return PlayerClanOverview.empty();
    }
  }

  PlayerClanOverview.empty()
    : tag = "",
      name = "",
      clanLevel = 0,
      badgeUrls = ClanBadgeUrls(small: "", large: "", medium: "");
}
