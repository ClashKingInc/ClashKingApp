import 'package:clashkingapp/features/player/models/player_war_stats.dart';

class ClanWarStats {
  final List<PlayerWarStats> players;
  final String clanTag;
  final List<ClanWarStatsData> wars;

  ClanWarStats(
      {required this.players, required this.clanTag, required this.wars});

  factory ClanWarStats.fromJson(Map<String, dynamic> item) {
    try {
      return ClanWarStats(
        players: (item['players'] as List<dynamic>? ?? [])
            .map((m) => PlayerWarStats.fromJson(m, null, null))
            .toList(),
        clanTag: item["clan_tag"],
        wars: item['wars'] != null
            ? (item['wars'] as List<dynamic>? ?? [])
                .map((m) => ClanWarStatsData.fromJson(m))
                .toList()
            : [],
      );
    } catch (e) {
      print('❌ Error parsing ClanWarStats: $e');
      return ClanWarStats(
        players: [],
        clanTag: "",
        wars: [],
      );
    }
  }
}

class ClanWarStatsData {
  final PlayerWarStatsDetails warDetails;
  final List<WarMemberData> membersData;

  ClanWarStatsData({
    required this.warDetails,
    required this.membersData,
  });

  factory ClanWarStatsData.fromJson(
      Map<String, dynamic> json) {
    try {
      final warDetails = PlayerWarStatsDetails.fromJson(json['war_data']);
      final members = json['members'] as List<dynamic>? ?? [];

      return ClanWarStatsData(
        warDetails: warDetails,
        membersData: members.map((m) => WarMemberData.fromJson(m)).toList(),
      );
    } catch (e) {
      print('Error parsing ClanWarStatsData: $e');
      return ClanWarStatsData(
        warDetails: PlayerWarStatsDetails.fromJson(json['war_data']),
        membersData: [],
      );
    }
  }
}
