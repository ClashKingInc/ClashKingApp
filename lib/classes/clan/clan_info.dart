import 'package:clashkingapp/classes/clan/badge_urls.dart';
import 'package:clashkingapp/classes/clan/war_league/current_war_info.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:clashkingapp/classes/data/league_data_manager.dart';
import 'package:clashkingapp/classes/clan/capital_league.dart';
import 'package:clashkingapp/classes/clan/location.dart';
import 'package:clashkingapp/classes/clan/member.dart';
import 'package:clashkingapp/classes/clan/war_league.dart';
import 'package:clashkingapp/classes/clan/war_league/current_league_info.dart';
import 'package:clashkingapp/classes/clan/war_league/war_log.dart';

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
  late CurrentLeagueInfo currentLeagueInfo;
  late CurrentWarInfo currentWarInfo;
  late String warState;
  late WarLog warLog;

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
    } catch (e) {
      throw Exception('Failed to load clan stats : $e');
    }
  }
}

// Service class to fetch clan info
class ClanService {
  Map<String, String> leagueUrls = {};

  Future<void> initEnv() async {
    await dotenv.load(fileName: ".env");
  }

  Future<Clan> fetchClanInfo(String tag) async {
    try {
      tag = tag.replaceAll('#', '!');

      final response = await http.get(
        Uri.parse('https://api.clashking.xyz/v1/clans/$tag'),
      );

      if (response.statusCode == 200) {
        String responseBody = utf8.decode(response.bodyBytes);
        Clan clanInfo = Clan.fromJson(jsonDecode(responseBody));
        if (clanInfo.warLeague != null) {
          clanInfo.warLeague!.imageUrl =
              LeagueDataManager().getLeagueUrl(clanInfo.warLeague!.name);
        }
        clanInfo.warState = await checkCurrentWar(tag, clanInfo);
        clanInfo.warLog = await WarLogService.fetchWarLogData(tag);
        return clanInfo;
      } else {
        throw Exception('Failed to load clan stats');
      }
    } catch (e) {
      throw Exception('Failed to load clan stats : $e');
    }
  }

  String fetchLeagueImageUrl(String name) {
    return leagueUrls[name] ??
        'https://clashkingfiles.b-cdn.net/clashkinglogo.png';
  }

  Future<String> checkCurrentWar(String clanTag, Clan clan) async {
    if (clanTag == "") {
      return "noClan";
    }

    final responseWar = await http.get(
      Uri.parse(
          'https://api.clashking.xyz/v1/clans/${clanTag.replaceAll('#', '%23')}/currentwar'),
    );

    final responseCwl = await http.get(
      Uri.parse(
          'https://api.clashking.xyz/v1/clans/${clanTag.replaceAll('#', '%23')}/currentwar/leaguegroup'),
    );

    if (responseWar.statusCode == 200) {
      var decodedResponse = jsonDecode(utf8.decode(responseWar.bodyBytes));
      if (decodedResponse["state"] != "notInWar" &&
          decodedResponse["reason"] != "accessDenied") {
        clan.currentWarInfo = CurrentWarInfo.fromJson(
            jsonDecode(utf8.decode(responseWar.bodyBytes)), "war", clanTag);
        return "war";
      } else if (decodedResponse["state"] == "notInWar") {
        DateTime now = DateTime.now();
        if (now.day >= 1 && now.day <= 12) {
          if (responseCwl.statusCode == 200) {
            var decodedResponseCwl =
                jsonDecode(utf8.decode(responseCwl.bodyBytes));
            if (decodedResponseCwl.containsKey("state")) {
              clan.currentLeagueInfo =
                  CurrentLeagueInfo.fromJson(decodedResponseCwl, clanTag);
              return "cwl";
            }
          }
        }
      }
    } else if (responseWar.statusCode == 403) {
      return "accessDenied";
    } else {
      throw Exception('Failed to load current war info');
    }
    return "notInWar";
  }
}
