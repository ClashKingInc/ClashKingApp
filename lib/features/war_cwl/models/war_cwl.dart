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
    try {
      // Normalize clan tag for comparison (ensure # prefix)
      String normalizeClanTag(String clanTag) {
        if (!clanTag.startsWith('#')) return '#$clanTag';
        return clanTag;
      }
      
      final normalizedTag = normalizeClanTag(tag);
      print("🔍 Looking for CWL war for clan: $normalizedTag");
      
      // First try to find active war (inWar)
      final activeWar = warLeagueInfos.firstWhere(
        (warInfo) =>
            warInfo.state == 'inWar' &&
            (normalizeClanTag(warInfo.clan!.tag) == normalizedTag || 
             normalizeClanTag(warInfo.opponent!.tag) == normalizedTag),
        orElse: () => WarInfo(state: 'notFound'),
      );
      
      if (activeWar.state != 'notFound') {
        print("✅ Found active CWL war for clan $tag");
        return activeWar;
      }
      
      // If no active war, try preparation war
      final prepWar = warLeagueInfos.firstWhere(
        (warInfo) =>
            warInfo.state == 'preparation' &&
            (normalizeClanTag(warInfo.clan!.tag) == normalizedTag || 
             normalizeClanTag(warInfo.opponent!.tag) == normalizedTag),
        orElse: () => WarInfo(state: 'notFound'),
      );
      
      if (prepWar.state != 'notFound') {
        print("✅ Found preparation CWL war for clan $normalizedTag");
        return prepWar;
      }
      
      // If no active or prep war, try most recent ended war
      final endedWars = warLeagueInfos.where(
        (warInfo) =>
            warInfo.state == 'warEnded' &&
            (normalizeClanTag(warInfo.clan!.tag) == normalizedTag || 
             normalizeClanTag(warInfo.opponent!.tag) == normalizedTag),
      ).toList();
      
      if (endedWars.isNotEmpty) {
        // Sort by end time to get most recent
        endedWars.sort((a, b) => (b.endTime ?? '').toString().compareTo((a.endTime ?? '').toString()));
        print("✅ Found recent ended CWL war for clan $normalizedTag");
        return endedWars.first;
      }
      
      print("❌ No CWL wars found for clan $normalizedTag");
      print("🔍 Available wars in warLeagueInfos:");
      for (final war in warLeagueInfos) {
        print("   War: ${war.state}, Clan: ${war.clan?.tag}, Opponent: ${war.opponent?.tag}");
      }
      return null;
      
    } catch (e) {
      print("❌ Error finding CWL war for clan $tag: $e");
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
    return warLeagueInfos.firstWhere(
      (warInfo) => warInfo.tag == tag,
      orElse: () => WarInfo(state: 'unknown'),
    );
  }

  WarInfo getActiveWarForClan(String clanTag) {
    // Use the improved logic from getActiveWarByTag
    final war = getActiveWarByTag(clanTag);
    return war ?? WarInfo(state: 'notInCwl');
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
