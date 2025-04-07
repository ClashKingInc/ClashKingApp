import 'package:clashkingapp/features/clan/models/clan_badge.dart';

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
        tag: json['tag'] as String,
        name: json['name'] as String,
        clanLevel: json['clanLevel'] as int,
        badgeUrls: ClanBadgeUrls.fromJson(json['badgeUrls']),
      );
    } catch (e) {
      print("❌ Error parsing PlayerClanOverview: $e");
      return PlayerClanOverview.empty();
    }
  }

  PlayerClanOverview.empty()
      : tag = "",
        name = "",
        clanLevel = 0,
        badgeUrls = ClanBadgeUrls(
          small: "",
          large: "",
          medium: "",
        );
}
