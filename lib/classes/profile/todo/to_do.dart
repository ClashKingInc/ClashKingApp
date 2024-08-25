import 'package:clashkingapp/classes/profile/todo/cwl_data.dart';
import 'package:clashkingapp/classes/profile/todo/legends_data.dart';
import 'package:clashkingapp/classes/profile/todo/raids_data.dart';
import 'package:clashkingapp/classes/profile/todo/clan_games_data.dart';
import 'package:clashkingapp/classes/profile/todo/war_data.dart';
import 'package:clashkingapp/classes/profile/profile_info.dart';

class ToDo {
  final String playerTag;
  final String currentClan;
  final LegendData? legends;
  final int seasonPass;
  final int lastActive;
  final RaidData raids;
  final CwlData cwl;
  WarData? war;
  final ClanGames clanGames;
  late int percentageDone;
  late double totalDone;
  late double totalEvent;
  late final bool isInTimeFrameForRaid;
  late final bool isInTimeFrameForClanGames;
  late final double seasonPassRatio;
  late final bool isLegend;
  late bool isInitialized = false;

  ToDo(
      {required this.playerTag,
      required this.currentClan,
      required this.legends,
      required this.seasonPass,
      required this.lastActive,
      required this.raids,
      required this.cwl,
      required this.clanGames,
      required this.war}) {
    final nowUtc = DateTime.now().toUtc();
    DateTime start = DateTime(nowUtc.year, nowUtc.month, 22, 8, 0, 0).toUtc();
    DateTime end = DateTime(nowUtc.year, nowUtc.month, 28, 8, 0, 0).toUtc();

    isInTimeFrameForRaid =
        (nowUtc.weekday == DateTime.friday && nowUtc.hour >= 6) ||
            (nowUtc.weekday == DateTime.saturday ||
                nowUtc.weekday == DateTime.sunday) ||
            (nowUtc.weekday == DateTime.monday && nowUtc.hour < 6);
    isInTimeFrameForClanGames = nowUtc.isAfter(start) && nowUtc.isBefore(end);
  }

  factory ToDo.fromJson(Map<String, dynamic> json, WarData? warData) {
    return ToDo(
      playerTag: json['player_tag'] ?? '',
      currentClan: json['current_clan'] ?? 'No clan',
      legends: json['legends'] != null && json['legends'].isNotEmpty
          ? LegendData.fromJson(json['legends'])
          : null,
      seasonPass: json['season_pass'] is int ? json['season_pass'] : 0,
      lastActive: json['last_active'] ?? 0,
      raids: json['raids'] != null && json['raids'].isNotEmpty
          ? RaidData.fromJson(json['raids'])
          : RaidData(attacksDone: 0, attackLimit: 0),
      cwl: json['cwl'] != null && json['cwl'].isNotEmpty
          ? CwlData.fromJson(json['cwl'])
          : CwlData(attacksDone: 0, attackLimit: 0),
      clanGames: json['clan_games'] != null && json['clan_games'].isNotEmpty
          ? ClanGames.fromJson(json['clan_games'])
          : ClanGames(clanTag: "#VY2J0LL", points: 0),
      war: warData,
    );
  }

  static Future<ToDo> createToDoFromJson(Map<String, dynamic> json) async {
    WarData? warData;

    if (json['war'] != null && json['war'].isNotEmpty) {
      DateTime warTime = DateTime.parse(json['war']['time']);
      DateTime now = DateTime.now().toUtc();
      Duration difference = warTime.difference(now);
      if (difference.inMinutes < (24 * 60)) {
        warData = await WarData.fetchWarData(json);
      }
    }
    ToDo toDo = ToDo.fromJson(json, warData);
    return toDo;
  }

  void calculateTotals(ProfileInfo profileInfo) {
    totalDone = 0;
    totalEvent = 0;

    // Legend completed
    if (profileInfo.playerLegendData != null &&
        profileInfo.playerLegendData!.isInLegend == true && profileInfo.league == "Legend League") {
      totalEvent += 8;
      isLegend = true;
      totalDone += legends != null ? legends!.numAttacks : 0;
    } else {
      isLegend = false;
    }

    // War attacks completed
    if (war != null && war!.attackLimit != 0) {
      totalEvent += war!.attackLimit;
      totalDone += war!.attacksDone.toInt();
    }

    // CWL attacks completed
    if (cwl.attackLimit != 0) {
      totalEvent += cwl.attackLimit;
      totalDone += cwl.attacksDone.toInt();
    }

    // Clan games completed
    if (isInTimeFrameForClanGames) {
      DateTime now = DateTime.now();
      DateTime clanGamesStart =
          DateTime(now.year, now.month, 22, 8); // Start of Clan Games
      int daysPassed = now.difference(clanGamesStart).inDays + 1;
      double clanGamesDaily = (4000 / 8) * daysPassed;
      double clanGamesRatio = (clanGames.points.toDouble() / clanGamesDaily) > 1
          ? 1
          : clanGames.points.toDouble() / clanGamesDaily;
      totalEvent += 2;
      totalDone += clanGamesRatio * 2;
    }

    // Raids completed
    if (isInTimeFrameForRaid) {
      totalEvent += raids.attackLimit != 0 ? raids.attackLimit : 5;
      if (raids.attackLimit == 0) {
        raids.attackLimit = 5;
      }
      totalDone += raids.attacksDone.toInt();
    }

    // Season pass completed
    DateTime now = DateTime.now();
    // Get the total number of days in the current month
    int totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;
    // Get the number of days that have passed in the current month
    int daysPassed = now.day;
    double seasonPassDaily = ((daysPassed * 2600) / totalDaysInMonth);
    totalEvent += 2;
    seasonPassRatio = (seasonPass.toDouble() / seasonPassDaily) > 1
        ? 1
        : (seasonPass.toDouble() / seasonPassDaily);
    totalDone += seasonPassRatio * 2;

    // Calculate overall percentage done
    if (totalEvent > 0) {
      percentageDone = (totalDone / totalEvent * 100).toInt();
    } else {
      percentageDone = 0; // No events, so 0% done
    }
    isInitialized = true;
  }
}
