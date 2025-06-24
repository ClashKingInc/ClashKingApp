import 'dart:convert';
import 'package:clashkingapp/features/clan/models/clan_badge.dart';
import 'package:http/http.dart' as http;

class ClanWarLog {
  final List<WarLogDetails> items;
  final String clanTag;
  late WarLogStats warLogStats;

  ClanWarLog({required this.items, required this.clanTag});

  factory ClanWarLog.fromJson(Map<String, dynamic> json, String clanTag) {
    var itemList = json['items'] != null
        ? (json['items'] as List)
            .where((itemJson) {
              // Extract the endTime and parse it to DateTime
              DateTime endTime = DateTime.parse(itemJson['endTime']);
              // Keep items where the endTime is in 2022 or later
              return endTime.year >= 2022;
            })
            .map((itemJson) =>
                WarLogDetails.fromJson(itemJson as Map<String, dynamic>, clanTag))
            .toList()
        : [];
    return ClanWarLog(items: itemList.cast<WarLogDetails>(), clanTag: clanTag);
  }
}


class WarLogStats {
  final int totalWins;
  final int totalLosses;
  final int totalTies;
  final int totalWars;
  final int averageMembers; 
  final double averageClanDestruction;
  final double averageClanStarsPerMember;
  final double averageOpponentDestruction;
  final double averageOpponentStarsPerMember;
  final double averageAttacksPerMember;
  final String winPercentage;
  final String lossPercentage;
  final String tiePercentage;
  final double averageDestructionDifference;
  final double averageClanStarsPercentage;
  final double averageOpponentStarsPercentage;

  WarLogStats({
    required this.totalWins,
    required this.totalLosses,
    required this.totalTies,
    required this.totalWars,
    required this.averageMembers,
    required this.averageClanDestruction,
    required this.averageClanStarsPerMember,
    required this.averageOpponentDestruction,
    required this.averageOpponentStarsPerMember,
    required this.averageAttacksPerMember,
    required this.winPercentage,
    required this.lossPercentage,
    required this.tiePercentage,
    required this.averageDestructionDifference,
    required this.averageClanStarsPercentage,
    required this.averageOpponentStarsPercentage,
  });

  // toString method to print the object as a string
  @override
  String toString() {
    return 'WarLogStats: {'
        'totalWins: $totalWins, '
        'totalLosses: $totalLosses, '
        'totalTies: $totalTies, '
        'totalWars: $totalWars, '
        'averageMembers: $averageMembers, '
        'averageClanDestruction: $averageClanDestruction, '
        'averageClanStarsPerMember: $averageClanStarsPerMember, '
        'averageOpponentDestruction: $averageOpponentDestruction, '
        'averageOpponentStarsPerMember: $averageOpponentStarsPerMember, '
        'averageAttacksPerMember: $averageAttacksPerMember, '
        'winPercentage: $winPercentage, '
        'lossPercentage: $lossPercentage, '
        'tiePercentage: $tiePercentage, '
        'averageDestructionDifference: $averageDestructionDifference, '
        'averageClanStarsPercentage: $averageClanStarsPercentage, '
        'averageOpponentStarsPercentage: $averageOpponentStarsPercentage'
        '}';
  }

}

class WarLogDetails {
  final String result;
  final String clanTag;
  final DateTime endTime;
  final int teamSize;
  final int attacksPerMember;
  final ClanDetails clan;
  final ClanDetails opponent;

  WarLogDetails({
    required this.result,
    required this.clanTag,
    required this.endTime,
    required this.teamSize,
    required this.attacksPerMember,
    required this.clan,
    required this.opponent,
  });

  factory WarLogDetails.fromJson(Map<String, dynamic> json, String clanTag) {
    return WarLogDetails(
      result: json['result'] ?? '',
      endTime: DateTime.parse(json['endTime']),
      teamSize: json['teamSize'] ?? 0,
      attacksPerMember: json['attacksPerMember'] ?? 1,
      clan: ClanDetails.fromJson(json['clan']),
      opponent: ClanDetails.fromJson(json['opponent']),
      clanTag: clanTag,
    );
  }
}

class ClanDetails {
  final String tag;
  final String name;
  final ClanBadgeUrls badgeUrls;
  final int clanLevel;
  final int attacks;
  final int stars;
  final double destructionPercentage;
  final int expEarned;

  ClanDetails({
    required this.tag,
    required this.name,
    required this.badgeUrls,
    required this.clanLevel,
    required this.attacks,
    required this.stars,
    required this.destructionPercentage,
    required this.expEarned,
  });

  factory ClanDetails.fromJson(Map<String, dynamic> json) {
    return ClanDetails(
      tag: json['tag'] ?? '',
      name: json['name'] ?? '',
      badgeUrls: ClanBadgeUrls.fromJson(json['badgeUrls'] ?? {}),
      clanLevel: json['clanLevel'] ?? 0,
      attacks: json['attacks'] ?? 0,
      stars: json['stars'] ?? 0,
      destructionPercentage:
          (json['destructionPercentage'] as num?)?.toDouble() ?? 0.0,
      expEarned: json['expEarned'] ?? 0,
    );
  }
}

class WarLogService {
  static Future<ClanWarLog> fetchWarLogData(String tag) async {
    final response = await http.get(Uri.parse(
        'https://proxy.clashk.ing/v1/clans/${tag.replaceAll('#', '%23')}/warlog'));

    if (response.statusCode == 200) {
      String body = utf8.decode(response.bodyBytes);
      Map<String, dynamic> jsonBody = json.decode(body);
      ClanWarLog warLog = ClanWarLog.fromJson(jsonBody, tag);
      warLog.warLogStats =
          await WarLogStatsService.analyzeWarLogs(warLog.items);
      return warLog;
    } else if (response.statusCode == 403) {
      return ClanWarLog(items: [], clanTag: tag);
    } else {
      throw Exception('Failed to load war history data');
    }
  }
}

class WarLogStatsService {
  static Future<WarLogStats> analyzeWarLogs(List<WarLogDetails> warLogs) async {
    int totalWins = 0;
    int totalLosses = 0;
    int totalTies = 0;
    int totalWars = 0;
    int totalMembers = 0;
    int totalAttacks = 0;
    double clanTotalDestruction = 0;
    int clanTotalStars = 0;
    double opponentTotalDestruction = 0;
    int opponentTotalStars = 0;
    int maxPossibleStars = 0;

    for (var log in warLogs) {
      if (log.attacksPerMember == 2) {
        totalWars++;
        switch (log.result) {
          case 'win':
            totalWins++;
            break;
          case 'lose':
            totalLosses++;
            break;
          case 'tie':
            totalTies++;
            break;
        }
        int possibleStarsForThisWar = log.teamSize * 3;
        maxPossibleStars += possibleStarsForThisWar;
        totalMembers += log.teamSize;
        totalAttacks += log.clan.attacks;
        clanTotalDestruction += log.clan.destructionPercentage;
        clanTotalStars += log.clan.stars;
        opponentTotalDestruction += log.opponent.destructionPercentage;
        opponentTotalStars += log.opponent.stars;
      }
    }

    double averageMembers = totalWars > 0 ? totalMembers / totalWars : 0;
    double averageClanDestruction =
        totalWars > 0 ? clanTotalDestruction / totalWars : 0;
    double averageClanStarsPerMember =
        totalMembers > 0 ? clanTotalStars / totalMembers : 0;
    double averageOpponentDestruction =
        totalWars > 0 ? opponentTotalDestruction / totalWars : 0;
    double averageOpponentStarsPerMember =
        totalMembers > 0 ? opponentTotalStars / totalMembers : 0;
    double averageClanStarsPercentage =
        maxPossibleStars > 0 ? (clanTotalStars / maxPossibleStars) * 100 : 0;
    double averageOpponentStarsPercentage =
        maxPossibleStars > 0 ? (opponentTotalStars / maxPossibleStars) * 100 : 0;
    double averageAttacksPerMember =
        totalMembers > 0 ? totalAttacks / totalMembers : 0;
    double winPercentage = totalWars > 0 ? (totalWins / totalWars) * 100 : 0;
    double lossPercentage = totalWars > 0 ? (totalLosses / totalWars) * 100 : 0;
    double tiePercentage = totalWars > 0 ? (totalTies / totalWars) * 100 : 0;
    double averageDestructionDifference =
        averageClanDestruction - averageOpponentDestruction;

    return WarLogStats(
      totalWins: totalWins,
      totalLosses: totalLosses,
      totalTies: totalTies,
      totalWars: totalWars,
      averageMembers: int.parse(averageMembers.toStringAsFixed(0)),
      averageClanDestruction:
          double.parse(averageClanDestruction.toStringAsFixed(0)),
      averageClanStarsPerMember:
          double.parse(averageClanStarsPerMember.toStringAsFixed(1)),
      averageOpponentDestruction:
          double.parse(averageOpponentDestruction.toStringAsFixed(0)),
      averageOpponentStarsPerMember:
          double.parse(averageOpponentStarsPerMember.toStringAsFixed(1)),
      averageClanStarsPercentage:
          double.parse(averageClanStarsPercentage.toStringAsFixed(1)),
      averageOpponentStarsPercentage:
          double.parse(averageOpponentStarsPercentage.toStringAsFixed(1)),
      averageAttacksPerMember:
          double.parse(averageAttacksPerMember.toStringAsFixed(1)),
      winPercentage: winPercentage.toStringAsFixed(0),
      lossPercentage: lossPercentage.toStringAsFixed(0),
      tiePercentage: tiePercentage.toStringAsFixed(0),
      averageDestructionDifference:
          double.parse(averageDestructionDifference.toStringAsFixed(1)),
    );
  }
}
