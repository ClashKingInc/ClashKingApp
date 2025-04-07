import 'package:clashkingapp/features/war_cwl/models/cwl_league.dart';
import 'package:clashkingapp/features/war_cwl/models/cwl_league_round.dart';
import 'package:clashkingapp/features/war_cwl/models/war_info.dart';

class WarCwl {
  final String tag;
  final bool isInWar;
  final bool isInCwl;
  final WarInfo warInfo;
  final CwlLeague? leagueInfo;
  final List<WarInfo> warLeagueInfos;

  WarCwl({
    required this.tag,
    required this.isInWar,
    required this.isInCwl,
    required this.warInfo,
    this.leagueInfo,
    required this.warLeagueInfos,
  });

  get teamSize => warLeagueInfos[0].teamSize;

  factory WarCwl.fromJson(Map<String, dynamic> json) {
    return WarCwl(
      tag: json['clan_tag'],
      isInWar: json['isInWar'],
      isInCwl: json['isInCwl'],
      warInfo: WarInfo.fromJson(json['war_info']),
      leagueInfo: json['league_info'] != null
          ? CwlLeague.fromJson(json['league_info'])
          : null,
      warLeagueInfos: (json['war_league_infos'] as List)
          .map((e) => WarInfo.fromJson(e))
          .toList(),
    );
  }

  WarInfo? getActiveWarByTag(String tag) {
    try {
      return warLeagueInfos.firstWhere(
        (warInfo) =>
            warInfo.state == 'inWar' &&
            (warInfo.clan!.tag == tag || warInfo.opponent!.tag == tag),
      );
    } catch (e) {
      return null;
    }
  }

  CwlLeagueRound? getRoundForWarTag(String? warTag) {
    return leagueInfo!.rounds.firstWhere(
      (round) => round.containsWar(warTag),
      orElse: () => CwlLeagueRound(roundNumber: -1, warTags: []),
    );
  }

  WarInfo? getWarInfoFromTag(String tag) {
    try {
      return warLeagueInfos.firstWhere((warInfo) => warInfo.tag == tag);
    } catch (e) {
      print("❌ Error getting war info from tag: $e");
      return null;
    }
  }

  
}
