import 'package:clashkingapp/classes/clan/description/badge_urls.dart';
import 'package:clashkingapp/classes/clan/logs/join_leave.dart';
import 'package:clashkingapp/classes/clan/war_league/current_war_info.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:clashkingapp/classes/data/league_data_manager.dart';
import 'package:clashkingapp/classes/clan/description/capital_league.dart';
import 'package:clashkingapp/classes/clan/description/location.dart';
import 'package:clashkingapp/classes/clan/description/member.dart';
import 'package:clashkingapp/classes/clan/description/war_league.dart';
import 'package:clashkingapp/classes/clan/war_league/current_league_info.dart';
import 'package:clashkingapp/classes/clan/war_league/war_log.dart';
import 'package:clashkingapp/classes/functions.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class Clan {
  final String tag;
  final String name;
  final BadgeUrls badgeUrls;
  final int clanLevel;
  final String type;
  final String description;
  final bool isFamilyFriendly;
  final int clanPoints;
  final int clanBuilderBasePoints;
  final int clanCapitalPoints;
  final CapitalLeague? capitalLeague;
  final int requiredTrophies;
  final String warFrequency;
  final int warWinStreak;
  final int warWins;
  final int warTies;
  final int warLosses;
  final bool isWarLogPublic;
  final WarLeague? warLeague;
  final int members;
  final Location? location;
  final List<Member>? memberList;
  final List<dynamic> labels;
  final int requiredBuilderBaseTrophies;
  final int requiredTownhallLevel;
  final Map<String, dynamic> clanCapital;
  late CurrentLeagueInfo? currentLeagueInfo;
  late CurrentWarInfo? currentWarInfo;
  late String warState;
  late WarLog warLog;
  late JoinLeaveClan joinLeaveClan;

  Clan({
    required this.tag,
    required this.name,
    required this.type,
    required this.description,
    required this.isFamilyFriendly,
    required this.badgeUrls,
    required this.clanLevel,
    required this.clanPoints,
    required this.clanBuilderBasePoints,
    required this.clanCapitalPoints,
    required this.capitalLeague,
    required this.requiredTrophies,
    required this.warFrequency,
    required this.warWinStreak,
    required this.warWins,
    required this.warTies,
    required this.warLosses,
    required this.isWarLogPublic,
    required this.warLeague,
    required this.members,
    required this.location,
    required this.memberList,
    required this.labels,
    required this.requiredBuilderBaseTrophies,
    required this.requiredTownhallLevel,
    required this.clanCapital,
  });

  factory Clan.fromJson(Map<String, dynamic> json) {
    try {
      return Clan(
        tag: json['tag'] ?? 'No tag',
        name: json['name'] ?? 'No name',
        type: json['type'] ?? 'No type',
        description: json['description'] ?? 'No description',
        isFamilyFriendly: json['isFamilyFriendly'] ?? false,
        badgeUrls: BadgeUrls.fromJson(json['badgeUrls']),
        clanLevel: json['clanLevel'] ?? 0,
        clanPoints: json['clanPoints'] ?? 0,
        clanBuilderBasePoints: json['clanBuilderBasePoints'] ?? 0,
        clanCapitalPoints: json['clanCapitalPoints'] ?? 0,
        capitalLeague:
            json['capitalLeague'] != null && json['capitalLeague'].isNotEmpty
                ? CapitalLeague.fromJson(json['capitalLeague'])
                : null,
        requiredTrophies: json['requiredTrophies'] ?? 0,
        warFrequency: json['warFrequency'] ?? 'No frequency',
        warWinStreak: json['warWinStreak'] ?? 0,
        warWins: json['warWins'] ?? 0,
        warTies: json['warTies'] ?? 0,
        warLosses: json['warLosses'] ?? 0,
        isWarLogPublic: json['isWarLogPublic'] ?? false,
        warLeague: json['warLeague'] != null && json['warLeague'].isNotEmpty
            ? WarLeague.fromJson(json['warLeague'])
            : null,
        members: json['members'] ?? 0,
        location: json['location'] != null &&
                (json['location'] as Map<String, dynamic>).isNotEmpty
            ? Location.fromJson(json['location'])
            : null,
        memberList: json['memberList'] != null &&
                (json['memberList'] as List<dynamic>).isNotEmpty
            ? (json['memberList'] as List<dynamic>)
                .map((e) => Member.fromJson(e))
                .toList()
            : null,
        labels: json['labels'] ?? [],
        requiredBuilderBaseTrophies: json['requiredBuilderBaseTrophies'] ?? 0,
        requiredTownhallLevel: json['requiredTownhallLevel'] ?? 0,
        clanCapital: json['clanCapital'] ?? {},
      );
    } catch (exception, stackTrace) {
      Sentry.captureException(exception, stackTrace: stackTrace);
      throw Exception('Failed to load clan stats : $exception');
    }
  }
}

class ClanService {
  Map<String, String> leagueUrls = {};

  Future<void> initEnv() async {
    await dotenv.load(fileName: ".env");
  }

  Future<Clan> fetchClanInfo(String clanTag) async {
    try {
      String tag = clanTag.replaceAll('#', '!');
      print('Fetching clan info for $tag');

      final clanInfoFuture = http.get(
        Uri.parse('https://api.clashking.xyz/v1/clans/$tag'),
      );

      final now = DateTime.now();
      DateTime lastMonday = findLastMondayOfMonth(now.year, now.month - 1);
      int timestampLastMonday = lastMonday.millisecondsSinceEpoch ~/ 1000;

      // Start fetching warState, warLog, and joinLeaveLog in parallel
      final warStateFuture = fetchWarStateInfo(clanTag);
      final warLogFuture = WarLogService.fetchWarLogData(tag);
      final joinLeaveLogFuture = JoinLeaveClanService.fetchJoinLeaveData(
          tag, timestampLastMonday.toString());

      // Wait for all futures to complete
      final responses = await Future.wait([
        clanInfoFuture,
        warStateFuture,
        warLogFuture,
        joinLeaveLogFuture,
      ]);

      // Extract responses
      final clanInfoResponse = responses[0] as http.Response;
      final warStateInfo = responses[1] as WarStateInfo;
      final warLog = responses[2] as WarLog;
      final joinLeaveLog = responses[3] as JoinLeaveClan;

      if (clanInfoResponse.statusCode == 200) {
        String responseBody = utf8.decode(clanInfoResponse.bodyBytes);
        Clan clanInfo = Clan.fromJson(jsonDecode(responseBody));

        if (clanInfo.warLeague != null) {
          clanInfo.warLeague!.imageUrl =
              LeagueDataManager().getLeagueUrl(clanInfo.warLeague!.name);
        }

        // Assign the results to clanInfo
        if (warStateInfo.currentLeagueInfo != null) {
          clanInfo.warState = "cwl";
        } else {
          clanInfo.warState = warStateInfo.state;
        }
        clanInfo.currentWarInfo = warStateInfo.currentWarInfo;
        clanInfo.currentLeagueInfo = warStateInfo.currentLeagueInfo;
        clanInfo.warLog = warLog;
        clanInfo.joinLeaveClan = joinLeaveLog;
        print("Clan info fetched: ${clanInfo.name}");
        return clanInfo;
      } else {
        throw Exception('Failed to load clan stats');
      }
    } catch (exception, stackTrace) {
      Sentry.captureException(exception, stackTrace: stackTrace);
      throw Exception('Failed to load clan stats: $exception');
    }
  }

  String fetchLeagueImageUrl(String name) {
    return leagueUrls[name] ??
        'https://clashkingfiles.b-cdn.net/clashkinglogo.png';
  }

  Future<WarStateInfo> fetchWarStateInfo(String clanTag) async {
    final now = DateTime.now();
    final warInfoFuture = fetchCurrentWarInfo(clanTag);
    final leagueInfoFuture = (now.day > 1 && now.day < 12)
        ? fetchCurrentLeagueInfo(clanTag)
        : Future.value(null);

    final responses = await Future.wait([warInfoFuture, leagueInfoFuture]);

    final warStateInfo = responses[0] as WarStateInfo;
    final leagueInfo = responses[1] as CurrentLeagueInfo?;

    if (warStateInfo.state == "notInWar" && leagueInfo != null) {
      return WarStateInfo(state: "cwl", currentLeagueInfo: leagueInfo);
    }

    return warStateInfo;
  }

  Future<WarStateInfo> fetchCurrentWarInfo(String clanTag) async {
    String tag = clanTag.replaceAll('#', '!');

    final responseWar = await http.get(
      Uri.parse(
          'https://api.clashking.xyz/v1/clans/${tag.replaceAll('#', '%23')}/currentwar'),
    );

    if (responseWar.statusCode == 200) {
      var decodedResponse = jsonDecode(utf8.decode(responseWar.bodyBytes));
      if (decodedResponse["state"] != "notInWar" &&
          decodedResponse["reason"] != "accessDenied") {
        final currentWarInfo =
            CurrentWarInfo.fromJson(decodedResponse, "war", clanTag);
        return WarStateInfo(state: "war", currentWarInfo: currentWarInfo);
      } else if (decodedResponse["state"] == "notInWar") {
        return WarStateInfo(state: "notInWar");
      }
    } else if (responseWar.statusCode == 403) {
      return WarStateInfo(state: "accessDenied");
    } else {
      throw Exception('Failed to load current war info');
    }
    return WarStateInfo(state: "notInWar");
  }

  Future<CurrentLeagueInfo?> fetchCurrentLeagueInfo(String clanTag) async {
    final responseCwl = await http.get(
      Uri.parse(
          'https://api.clashking.xyz/v1/clans/${clanTag.replaceAll('#', '%23')}/currentwar/leaguegroup'),
    );

    if (responseCwl.statusCode == 200) {
      var decodedResponseCwl = jsonDecode(utf8.decode(responseCwl.bodyBytes));
      if (decodedResponseCwl.containsKey("state")) {
        return CurrentLeagueInfo.fromJson(decodedResponseCwl, clanTag);
      }
    } else if (responseCwl.statusCode == 403) {
      return null;
    } else {
      throw Exception('Failed to load current league info');
    }
    return null;
  }
}

class WarStateInfo {
  final String state;
  final CurrentWarInfo? currentWarInfo;
  final CurrentLeagueInfo? currentLeagueInfo;

  WarStateInfo({
    required this.state,
    this.currentWarInfo,
    this.currentLeagueInfo,
  });
}
