import 'package:clashkingapp/features/war_cwl/models/cwl_league.dart';
import 'package:clashkingapp/features/war_cwl/models/cwl_league_round.dart';
import 'package:clashkingapp/features/war_cwl/models/war_info.dart';
import 'package:clashkingapp/features/war_cwl/models/war_member_presence.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';

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

  int get teamSize => warLeagueInfos.isNotEmpty
      ? warLeagueInfos[0].teamSize ?? 0
      : warInfo.teamSize ?? 0;

  factory WarCwl.fromJson(Map<String, dynamic> json, String? tag) {
    try {
      final warInfoData = _asMap(json['war_info']);
      final warState = warInfoData?['state']?.toString() ?? 'notInWar';
      final leagueInfoData = _asMap(json['league_info']);
      final warLeagueInfosData =
          (json['war_league_infos'] as List<dynamic>? ?? [])
              .map(_asMap)
              .whereType<Map<String, dynamic>>()
              .map(WarInfo.fromJson)
              .where((warInfo) =>
                  warInfo.state != 'unknown' ||
                  warInfo.clan != null ||
                  warInfo.opponent != null)
              .toList();

      return WarCwl(
        tag: json['clan_tag']?.toString() ?? tag ?? '',
        isInWar: json['isInWar'] == true,
        isInCwl: json['isInCwl'] == true,
        warInfo: warState != 'notInWar'
            ? WarInfo.fromJson(_asMap(warInfoData?['currentWarInfo']))
            : WarInfo(state: 'notInWar'),
        leagueInfo:
            leagueInfoData != null ? CwlLeague.fromJson(leagueInfoData) : null,
        warLeagueInfos: warLeagueInfosData,
      );
    } catch (e) {
      DebugUtils.debugError(" Error parsing WarCwl: $e");
      return WarCwl(
        tag: json['clan_tag']?.toString() ?? tag ?? '',
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
      DebugUtils.debugInfo("🔍 Looking for CWL war for clan: $normalizedTag");

      bool matchesTag(WarInfo warInfo, String tag) =>
          (warInfo.clan != null &&
              normalizeClanTag(warInfo.clan!.tag) == tag) ||
          (warInfo.opponent != null &&
              normalizeClanTag(warInfo.opponent!.tag) == tag);

      // First try to find active war (inWar)
      final activeWar = warLeagueInfos.firstWhere(
        (warInfo) =>
            warInfo.state == 'inWar' && matchesTag(warInfo, normalizedTag),
        orElse: () => WarInfo(state: 'notFound'),
      );

      if (activeWar.state != 'notFound') {
        DebugUtils.debugSuccess("Found active CWL war for clan $tag");
        return activeWar.reorderForClan(normalizedTag);
      }

      // If no active war, try preparation war
      final prepWar = warLeagueInfos.firstWhere(
        (warInfo) =>
            warInfo.state == 'preparation' &&
            matchesTag(warInfo, normalizedTag),
        orElse: () => WarInfo(state: 'notFound'),
      );

      if (prepWar.state != 'notFound') {
        DebugUtils.debugSuccess(
            "Found preparation CWL war for clan $normalizedTag");
        return prepWar.reorderForClan(normalizedTag);
      }

      // If no active or prep war, try most recent ended war
      final endedWars = warLeagueInfos
          .where(
            (warInfo) =>
                warInfo.state == 'warEnded' &&
                matchesTag(warInfo, normalizedTag),
          )
          .toList();

      if (endedWars.isNotEmpty) {
        // Sort by end time to get most recent
        endedWars.sort((a, b) => (b.endTime ?? '')
            .toString()
            .compareTo((a.endTime ?? '').toString()));
        DebugUtils.debugSuccess(
            "Found recent ended CWL war for clan $normalizedTag");
        return endedWars.first.reorderForClan(normalizedTag);
      }

      DebugUtils.debugError("No CWL wars found for clan $normalizedTag");
      DebugUtils.debugInfo("🔍 Available wars in warLeagueInfos:");
      for (final war in warLeagueInfos) {
        DebugUtils.debugInfo(
            "   War: ${war.state}, Clan: ${war.clan?.tag}, Opponent: ${war.opponent?.tag}");
      }
      return null;
    } catch (e) {
      DebugUtils.debugError("Error finding CWL war for clan $tag: $e");
      return null;
    }
  }

  CwlLeagueRound? getRoundForWarTag(String? warTag) {
    final league = leagueInfo;
    if (league == null) {
      return CwlLeagueRound(roundNumber: -1, warTags: []);
    }

    return league.rounds.firstWhere(
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
      DebugUtils.debugError("Error getting member presence: $e");
    }
    return WarMemberPresence(isInWar: false);
  }

  /// Get active war by player tag and automatically reorder so user's clan is always 'clan'
  /// This is a convenience method that combines finding the war and reordering for the user
  WarInfo? getActiveWarByPlayerTag(String playerTag) {
    try {
      // First find any war containing this player
      for (final warInfo in warLeagueInfos) {
        final playerInClan =
            warInfo.clan?.members.any((member) => member.tag == playerTag) ??
                false;
        final playerInOpponent = warInfo.opponent?.members
                .any((member) => member.tag == playerTag) ??
            false;

        if (playerInClan || playerInOpponent) {
          // Found a war with this player, prioritize by state
          if (warInfo.state == 'inWar') {
            DebugUtils.debugSuccess(
                "Found active CWL war for player $playerTag");
            return warInfo.reorderForUser(playerTag);
          }
        }
      }

      // If no active war, try preparation
      for (final warInfo in warLeagueInfos) {
        final playerInClan =
            warInfo.clan?.members.any((member) => member.tag == playerTag) ??
                false;
        final playerInOpponent = warInfo.opponent?.members
                .any((member) => member.tag == playerTag) ??
            false;

        if (playerInClan || playerInOpponent) {
          if (warInfo.state == 'preparation') {
            DebugUtils.debugSuccess(
                "Found preparation CWL war for player $playerTag");
            return warInfo.reorderForUser(playerTag);
          }
        }
      }

      // If no active or prep war, try most recent ended war
      final playerWars = warLeagueInfos.where((warInfo) {
        final playerInClan =
            warInfo.clan?.members.any((member) => member.tag == playerTag) ??
                false;
        final playerInOpponent = warInfo.opponent?.members
                .any((member) => member.tag == playerTag) ??
            false;
        return (playerInClan || playerInOpponent) &&
            warInfo.state == 'warEnded';
      }).toList();

      if (playerWars.isNotEmpty) {
        // Sort by end time to get most recent
        playerWars.sort((a, b) => (b.endTime ?? '')
            .toString()
            .compareTo((a.endTime ?? '').toString()));
        DebugUtils.debugSuccess(
            "Found recent ended CWL war for player $playerTag");
        return playerWars.first.reorderForUser(playerTag);
      }

      DebugUtils.debugWarning("No CWL wars found for player $playerTag");
      return null;
    } catch (e) {
      DebugUtils.debugError("Error finding CWL war for player $playerTag: $e");
      return null;
    }
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
