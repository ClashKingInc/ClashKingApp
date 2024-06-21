import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:clashkingapp/classes/clan/description/badge_urls.dart';

class WarLog {
  final List<WarLogDetails> items;
  late WarLogStats warLogStats;

  WarLog({required this.items});

  factory WarLog.fromJson(Map<String, dynamic> json) {
    var itemList = json['items'] != null
        ? (json['items'] as List)
            .map((itemJson) =>
                WarLogDetails.fromJson(itemJson as Map<String, dynamic>))
            .toList()
        : [];
    return WarLog(
        items: itemList.cast<WarLogDetails>()); // Placeholder for warLogStats
  }
}

class WarLogStats {
  final int totalWins;
  final int totalLosses;
  final int totalTies;
  final int averageMembers;
  final double averageClanDestruction;
  final double averageClanStarsPerMember;
  final double averageOpponentDestruction;
  final double averageOpponentStarsPerMember;

  WarLogStats({
    required this.totalWins,
    required this.totalLosses,
    required this.totalTies,
    required this.averageMembers,
    required this.averageClanDestruction,
    required this.averageClanStarsPerMember,
    required this.averageOpponentDestruction,
    required this.averageOpponentStarsPerMember,
  });

  factory WarLogStats.fromJson(Map<String, dynamic> json) {
    return WarLogStats(
      totalWins: int.parse(json['totalWins'] ?? '0'),
      totalLosses: int.parse(json['totalLosses'] ?? '0'),
      totalTies: int.parse(json['totalTies'] ?? '0'),
      averageMembers: int.parse(json['averageMembers'] ?? '0'),
      averageClanDestruction:
          double.parse(json['averageClanDestruction'] ?? '0'),
      averageClanStarsPerMember:
          double.parse(json['averageClanStarsPerMember'] ?? '0'),
      averageOpponentDestruction:
          double.parse(json['averageOpponentDestruction'] ?? '0'),
      averageOpponentStarsPerMember:
          double.parse(json['averageOpponentStarsPerMember'] ?? '0'),
    );
  }
}

class WarLogDetails {
  final String result;
  final DateTime endTime;
  final int teamSize;
  final int attacksPerMember;
  final ClanDetails clan;
  final ClanDetails opponent;

  WarLogDetails({
    required this.result,
    required this.endTime,
    required this.teamSize,
    required this.attacksPerMember,
    required this.clan,
    required this.opponent,
  });

  factory WarLogDetails.fromJson(Map<String, dynamic> json) {
    return WarLogDetails(
      result: json['result'] ?? '',
      endTime: DateTime.parse(json['endTime']),
      teamSize: json['teamSize'] ?? 0,
      attacksPerMember: json['attacksPerMember'] ?? 1,
      clan: ClanDetails.fromJson(json['clan']),
      opponent: ClanDetails.fromJson(json['opponent']),
    );
  }
}

class ClanDetails {
  final String tag;
  final String name;
  final BadgeUrls badgeUrls;
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
      badgeUrls: BadgeUrls.fromJson(json['badgeUrls'] ?? {}),
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
  static Future<WarLog> fetchWarLogData(String tag) async {
    final response = await http.get(Uri.parse(
        'https://api.clashking.xyz/v1/clans/${tag.replaceAll('#', '%23')}/warlog'));
    if (response.statusCode == 200) {
      String body = utf8.decode(response.bodyBytes);
      Map<String, dynamic> jsonBody = json.decode(body);
      WarLog warLog = WarLog.fromJson(jsonBody);
      warLog.warLogStats =
          await WarLogStatsService.analyzeWarLogs(warLog.items);
      return warLog;
    } else if (response.statusCode == 403) {
      return WarLog(items: []);
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
    int totalMembers = 0;
    double clanTotalDestruction = 0;
    int clanTotalStars = 0;
    double opponentTotalDestruction = 0;
    int opponentTotalStars = 0;

    for (var log in warLogs) {
      if (log.attacksPerMember == 2) {
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
        print(log.teamSize);
        totalMembers += log.teamSize;
        clanTotalDestruction += log.clan.destructionPercentage;
        clanTotalStars += log.clan.stars;
        opponentTotalDestruction += log.opponent.destructionPercentage;
        opponentTotalStars += log.opponent.stars;
      }
    }

    int logCount = warLogs.length;
    double averageMembers = logCount > 0 ? totalMembers / logCount : 0;
    double averageClanDestruction =
        logCount > 0 ? clanTotalDestruction / logCount : 0;
    double averageClanStarsPerMember =
        totalMembers > 0 ? clanTotalStars / totalMembers : 0;
    double averageOpponentDestruction =
        logCount > 0 ? opponentTotalDestruction / logCount : 0;
    double averageOpponentStarsPerMember =
        totalMembers > 0 ? opponentTotalStars / totalMembers : 0;

    return WarLogStats(
      totalWins: totalWins,
      totalLosses: totalLosses,
      totalTies: totalTies,
      averageMembers: int.parse(averageMembers.toStringAsFixed(0)),
      averageClanDestruction:
          double.parse(averageClanDestruction.toStringAsFixed(0)),
      averageClanStarsPerMember:
          double.parse(averageClanStarsPerMember.toStringAsFixed(1)),
      averageOpponentDestruction:
          double.parse(averageOpponentDestruction.toStringAsFixed(0)),
      averageOpponentStarsPerMember:
          double.parse(averageOpponentStarsPerMember.toStringAsFixed(1)),
    );
  }
}
