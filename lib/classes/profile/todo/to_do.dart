import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:clashkingapp/classes/profile/todo/cwl_data.dart';
import 'package:clashkingapp/classes/profile/todo/legends_data.dart';
import 'package:clashkingapp/classes/profile/todo/raids_data.dart';
import 'package:clashkingapp/classes/profile/todo/clan_games_data.dart';
import 'package:clashkingapp/classes/profile/todo/to_do_list.dart';
import 'package:clashkingapp/classes/account/accounts.dart';
import 'package:clashkingapp/classes/profile/profile_info.dart';

class ToDo {
  final String playerTag;
  final String currentClan;
  final LegendData? legends;
  final int seasonPass;
  final int lastActive;
  final RaidData raids;
  final CwlData cwl;
  final ClanGames clanGames;
  late final int percentageDone;
  late int totalDone;
  late int totalEvent;
  late final bool isInTimeFrameForRaid;
  late final bool isInTimeFrameForClanGames;
  late final double seasonPassRatio;
  late final bool isLegend;

  ToDo({
    required this.playerTag,
    required this.currentClan,
    this.legends,
    required this.seasonPass,
    required this.lastActive,
    required this.raids,
    required this.cwl,
    required this.clanGames,
  }) {
    final nowUtc = DateTime.now().toUtc();
    isInTimeFrameForRaid =
        (nowUtc.weekday == DateTime.friday && nowUtc.hour >= 6) ||
            (nowUtc.weekday == DateTime.saturday ||
                nowUtc.weekday == DateTime.sunday) ||
            (nowUtc.weekday == DateTime.monday && nowUtc.hour < 6);
    isInTimeFrameForClanGames = (nowUtc.day >= 22 && nowUtc.hour >= 8) &&
        (nowUtc.day <= 28 && nowUtc.hour <= 8);
  }

  factory ToDo.fromJson(Map<String, dynamic> json) {
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
    );
  }

  void calculateTotals(ProfileInfo profileInfo) {
    totalDone = 0;
    totalEvent = 0;

    // Legend completed
    if (profileInfo.playerLegendData != null &&
        profileInfo.playerLegendData!.isInLegend == true) {
      totalEvent += 100;
      isLegend = true;
      double legendRatio = legends!.numAttacks / 8;
      totalDone += (legendRatio * 100).toInt();
    } else {
      isLegend = false;
    }

    // CWL attacks completed
    if (cwl.attackLimit != 0) {
      totalEvent += 100;
      double cwlRatio = cwl.attacksDone.toDouble() / cwl.attackLimit.toDouble();
      totalDone += (cwlRatio * 100).toInt();
    }

    // Clan games completed
    if (isInTimeFrameForClanGames) {
      totalEvent += 100;
      double clanGamesRatio = clanGames.points / 4000;
      totalDone += (clanGamesRatio * 100).toInt();
    }

    // Raids completed
    if (isInTimeFrameForRaid) {
      totalEvent += 100;
      if (raids.attackLimit == 0) {
        raids.attackLimit = 5;
      }
      double raidRatio =
          raids.attacksDone.toDouble() / raids.attackLimit.toDouble();
      totalDone += (raidRatio * 100).toInt();
    }

    // Season pass completed
    DateTime now = DateTime.now();
    // Get the total number of days in the current month
    int totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;
    // Get the number of days that have passed in the current month
    int daysPassed = now.day;
    double seasonPassDaily = ((daysPassed * 2600) / totalDaysInMonth);
    totalEvent += 100;
    seasonPassRatio = (seasonPass.toDouble() / seasonPassDaily) > 1
        ? 1
        : (seasonPass.toDouble() / seasonPassDaily);
    totalDone += (seasonPassRatio * 100).toInt();

    // Calculate overall percentage done
    if (totalEvent > 0) {
      percentageDone = (totalDone / totalEvent * 100).toInt();
    } else {
      percentageDone = 0; // No events, so 0% done
    }
  }
}

class PlayerDataService {
  static void fetchPlayerToDoData(List<String> tags, Accounts accounts) async {
    final tagsParameter = tags.asMap().entries.map((entry) {
      String encodedTag = entry.value.replaceAll('#', '%23');
      return '${entry.key == 0 ? '' : '&'}player_tags=$encodedTag';
    }).join('');
    final response = await http.get(
        Uri.parse('https://api.clashking.xyz/player/to-do?$tagsParameter'));

    if (response.statusCode == 200) {
      String body = utf8.decode(response.bodyBytes);
      Map<String, dynamic> jsonBody = json.decode(body);
      accounts.toDoList = ToDoList.fromJson(jsonBody);
      accounts.isTodoInitialized = true;
    } else {
      throw Exception('Failed to load player data');
    }
  }
}
