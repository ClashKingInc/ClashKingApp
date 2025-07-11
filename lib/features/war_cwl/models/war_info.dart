import 'package:clashkingapp/features/war_cwl/models/war_clan.dart';
import 'package:clashkingapp/features/war_cwl/models/war_member.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';

class WarInfo {
  final String? tag;
  final String state;
  final int? teamSize;
  final int? attacksPerMember;
  final WarClan? clan;
  final WarClan? opponent;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime? preparationStartTime;
  final String? warType;

  WarInfo({
    this.tag,
    required this.state,
    this.teamSize,
    this.attacksPerMember,
    this.clan,
    this.opponent,
    this.startTime,
    this.endTime,
    this.preparationStartTime,
    this.warType,
  });

  factory WarInfo.fromJson(Map<String, dynamic> json) {
    try {
      return WarInfo(
        tag: json['war_tag'],
        state: json['state'] ?? 'unknown',
        teamSize: json['teamSize'],
        attacksPerMember: json['attacksPerMember'],
        startTime: json['startTime'] != null
            ? DateTime.parse(json['startTime'])
            : null,
        endTime:
            json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
        preparationStartTime: json['preparationStartTime'] != null
            ? DateTime.parse(json['preparationStartTime'])
            : null,
        warType: json['warType'] ?? json['type'] ?? 'unknown',
        clan: json['clan'] != null ? WarClan.fromJson(json['clan']) : null,
        opponent: json['opponent'] != null
            ? WarClan.fromJson(json['opponent'])
            : null,
      );
    } catch (e) {
      DebugUtils.debugError("Error parsing WarInfo: $e");
      return WarInfo(
        state: 'unknown',
        clan: null,
        opponent: null,
      );
    }
  }

  factory WarInfo.empty() {
    return WarInfo(
      state: 'unknown',
      clan: WarClan.empty(),
      opponent: WarClan.empty(),
    );
  }

  /// Return a WarMember from either clan or opponent by tag
  WarMember? getMemberByTag(String tag) {
    // First check clan members
    final clanMembers = clan?.members ?? [];
    for (final member in clanMembers) {
      if (member.tag == tag) {
        return member;
      }
    }
    
    // Then check opponent members
    final opponentMembers = opponent?.members ?? [];
    for (final member in opponentMembers) {
      if (member.tag == tag) {
        return member;
      }
    }
    
    // Member not found in either clan
    return null;
  }

  /// Get the TH level from a tag
  int? getTownhallLevelByTag(String tag) {
    return getMemberByTag(tag)?.townhallLevel;
  }

  /// Get the map position from a tag
  int? getMapPositionByTag(String tag) {
    return getMemberByTag(tag)?.mapPosition;
  }

  /// Get the name from a tag
  String? getNameByTag(String tag) {
    return getMemberByTag(tag)?.name;
  }

  int getAttacksDoneByPlayer(String playerTag, String clanTag) {
    if (clan?.tag == clanTag) {
      return clan?.members
              .firstWhere((member) => member.tag == playerTag,
                  orElse: () => WarMember.empty())
              .attacks
              ?.length ??
          0;
    } else if (opponent?.tag == clanTag) {
      return opponent?.members
              .firstWhere((member) => member.tag == playerTag,
                  orElse: () => WarMember.empty())
              .attacks
              ?.length ??
          0;
    }
    return 0;
  }

  bool isPlayerInWar(String playerTag, String clanTag) {
    if (clan?.tag == clanTag) {
      return clan?.members.any((member) => member.tag == playerTag) ?? false;
    } else if (opponent?.tag == clanTag) {
      return opponent?.members.any((member) => member.tag == playerTag) ??
          false;
    }
    return false;
  }

  String getWarResult(String clanTag) {
    if (clan?.tag != clanTag && opponent?.tag != clanTag) {
      return 'unknown';
    }
    bool isPerfectWar() {
      return (clan?.destructionPercentage == 100.0 &&
              opponent?.destructionPercentage == 100.0);
    }

    if (clan?.tag == clanTag) {
      if (state == 'warEnded') {
        if (isPerfectWar()) {
          return 'perfectWar';
        }
        if (clan!.stars > opponent!.stars) {
          return 'won';
        } else if (clan!.stars < opponent!.stars) {
          return 'lost';
        } else {
          // Tie on stars, check destructionPercentage
          if ((clan!.destructionPercentage) > (opponent!.destructionPercentage)) {
            return 'won';
          } else if ((clan!.destructionPercentage) < (opponent!.destructionPercentage)) {
            return 'lost';
          } else {
            return 'tie';
          }
        }
      } else {
        return 'inWar';
      }
    } else if (opponent?.tag == clanTag) {
      if (state == 'warEnded') {
        if (isPerfectWar()) {
          return 'perfectWar';
        }
        if (opponent!.stars > clan!.stars) {
          return 'won';
        } else if (opponent!.stars < clan!.stars) {
          return 'lost';
        } else {
          // Tie on stars, check destructionPercentage
          if ((opponent!.destructionPercentage) > (clan!.destructionPercentage)) {
            return 'won';
          } else if ((opponent!.destructionPercentage) < (clan!.destructionPercentage)) {
            return 'lost';
          } else {
            return 'tie';
          }
        }
      } else {
        return 'inWar';
      }
    }
    return 'unknown';
  }

  /// Create a new WarInfo with clan and opponent reordered so the user's clan is always 'clan'
  /// Returns a new WarInfo where:
  /// - If the user is in 'clan', returns the same WarInfo
  /// - If the user is in 'opponent', swaps clan and opponent
  /// - If the user is not found in either, returns the original WarInfo
  WarInfo reorderForUser(String userPlayerTag) {
    // Check if user is in the clan side
    final isUserInClan = clan?.members.any((member) => member.tag == userPlayerTag) ?? false;
    
    // Check if user is in the opponent side  
    final isUserInOpponent = opponent?.members.any((member) => member.tag == userPlayerTag) ?? false;
    
    DebugUtils.debugInfo("Reordering war for user $userPlayerTag: inClan=$isUserInClan, inOpponent=$isUserInOpponent");
    
    // If user is in clan position, no reordering needed
    if (isUserInClan && !isUserInOpponent) {
      DebugUtils.debugInfo("User is in clan position, no reordering needed");
      return this;
    }
    
    // If user is in opponent position, swap clan and opponent
    if (isUserInOpponent && !isUserInClan) {
      DebugUtils.debugInfo("User is in opponent position, swapping clan and opponent");
      return WarInfo(
        tag: tag,
        state: state,
        teamSize: teamSize,
        attacksPerMember: attacksPerMember,
        clan: opponent, // User's clan becomes 'clan'
        opponent: clan, // Original clan becomes 'opponent'
        startTime: startTime,
        endTime: endTime,
        preparationStartTime: preparationStartTime,
        warType: warType,
      );
    }
    
    // If user is not found in either side, or found in both (shouldn't happen), return original
    if (!isUserInClan && !isUserInOpponent) {
      DebugUtils.debugWarning("User $userPlayerTag not found in either clan or opponent");
    } else if (isUserInClan && isUserInOpponent) {
      DebugUtils.debugWarning("User $userPlayerTag found in both clan and opponent (unexpected)");
    }
    
    return this;
  }

  /// Create a new WarInfo with clan and opponent reordered so the specified clan tag is always 'clan'
  /// This is useful when you know which clan should be considered "yours" based on clan tag rather than player tag
  WarInfo reorderForClan(String clanTag) {
    // Normalize clan tags for comparison
    String normalizeClanTag(String tag) {
      if (!tag.startsWith('#')) return '#$tag';
      return tag;
    }
    
    final normalizedTargetTag = normalizeClanTag(clanTag);
    final normalizedClanTag = clan?.tag != null ? normalizeClanTag(clan!.tag) : null;
    final normalizedOpponentTag = opponent?.tag != null ? normalizeClanTag(opponent!.tag) : null;
    
    DebugUtils.debugInfo("Reordering war for clan $normalizedTargetTag: clanTag=$normalizedClanTag, opponentTag=$normalizedOpponentTag");
    
    // If target clan is already in clan position, no reordering needed
    if (normalizedClanTag == normalizedTargetTag) {
      DebugUtils.debugInfo("Target clan is already in clan position, no reordering needed");
      return this;
    }
    
    // If target clan is in opponent position, swap clan and opponent
    if (normalizedOpponentTag == normalizedTargetTag) {
      DebugUtils.debugInfo("Target clan is in opponent position, swapping clan and opponent");
      return WarInfo(
        tag: tag,
        state: state,
        teamSize: teamSize,
        attacksPerMember: attacksPerMember,
        clan: opponent, // Target clan becomes 'clan'
        opponent: clan, // Original clan becomes 'opponent'
        startTime: startTime,
        endTime: endTime,
        preparationStartTime: preparationStartTime,
        warType: warType,
      );
    }
    
    // If target clan is not found in either side, return original
    DebugUtils.debugWarning("Target clan $normalizedTargetTag not found in either clan or opponent position");
    return this;
  }
}
