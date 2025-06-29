import 'package:clashkingapp/features/war_cwl/models/cwl_league.dart';
import 'package:clashkingapp/features/war_cwl/models/cwl_league_round.dart';
import 'package:clashkingapp/features/war_cwl/models/war_info.dart';
import 'package:clashkingapp/features/war_cwl/models/war_member_presence.dart';

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

  int get teamSize => warLeagueInfos[0].teamSize ?? 0;

  factory WarCwl.fromJson(Map<String, dynamic> json, String? tag) {
    try {
      return WarCwl(
        tag: json['clan_tag'] ?? tag,
        isInWar: json['isInWar'],
        isInCwl: json['isInCwl'],
        warInfo: json['war_info']['state'] != "notInWar"
            ? WarInfo.fromJson(json['war_info']["currentWarInfo"])
            : WarInfo(state: 'notInWar'),
        leagueInfo: json['league_info'] != null
            ? CwlLeague.fromJson(json['league_info'])
            : null,
        warLeagueInfos: (json['war_league_infos'] as List)
            .map((e) => WarInfo.fromJson(e))
            .toList(),
      );
    } catch (e) {
      print("❌ Error parsing WarCwl: $e");
      return WarCwl(
        tag: json['clan_tag'],
        isInWar: false,
        isInCwl: false,
        warInfo: WarInfo(state: 'unknown'),
        leagueInfo: null,
        warLeagueInfos: [],
      );
    }
  }

  WarInfo? getActiveWarByTag(String tag) {
    return warLeagueInfos.firstWhere(
      (warInfo) =>
          warInfo.state == 'inWar' &&
          (warInfo.clan!.tag == tag || warInfo.opponent!.tag == tag),
      orElse: () => warLeagueInfos.isNotEmpty ? warLeagueInfos.last : WarInfo(state: 'unknown'),
    );
  }

  CwlLeagueRound? getRoundForWarTag(String? warTag) {
    return leagueInfo!.rounds.firstWhere(
      (round) => round.containsWar(warTag),
      orElse: () => CwlLeagueRound(roundNumber: -1, warTags: []),
    );
  }

  WarInfo? getWarInfoFromTag(String tag) {
    return warLeagueInfos.firstWhere(
      (warInfo) => warInfo.tag == tag,
      orElse: () => WarInfo(state: 'unknown'),
    );
  }

  WarInfo getActiveWarForClan(String clanTag) {
    return warLeagueInfos.firstWhere(
      (warInfo) =>
          warInfo.state == 'inWar' &&
          (warInfo.clan!.tag == clanTag || warInfo.opponent!.tag == clanTag),
      orElse: () => WarInfo(state: 'unknown'),
    );
  }

  WarMemberPresence getMemberPresence(String memberTag, String clanTag) {
    try {
      final warInfo = getActiveWarForClan(clanTag);
      final member = warInfo.getMemberByTag(memberTag);

      if (member != null) {
        int attacksDone = member.attacks?.length ?? 0;
        return WarMemberPresence(
          isInWar: true,
          attacksDone: attacksDone,
          attacksAvailable: warInfo.attacksPerMember ?? 1,
        );
      }
    } catch (e) {
      print("❌ Error getting member presence: $e");
    }
    return WarMemberPresence(isInWar: false);
  }
}
