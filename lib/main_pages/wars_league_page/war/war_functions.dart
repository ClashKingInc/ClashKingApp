import 'package:clashkingapp/classes/clan/war_league/current_war_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war/current_war_info_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/classes/clan/war_league/war_log.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:clashkingapp/classes/clan/war_league/current_league_info.dart';

Map<int, int> countStars(List<WarMember> members) {
  Map<int, int> starCounts = {0: 0, 1: 0, 2: 0, 3: 0};

  for (WarMember member in members) {
    member.attacks?.forEach((attack) {
      if (attack.stars == 0) {
        starCounts[0] = starCounts[0]! + 1;
      } else if (attack.stars == 1) {
        starCounts[1] = starCounts[1]! + 1;
      } else if (attack.stars == 2) {
        starCounts[2] = starCounts[2]! + 1;
      } else if (attack.stars == 3) {
        starCounts[3] = starCounts[3]! + 1;
      }
    });
  }

  return starCounts;
}

List<Widget> generateStars(int numberOfStars, double size) {
  return List<Widget>.generate(3, (index) {
    return CachedNetworkImage(
      imageUrl: index < numberOfStars
          ? "https://clashkingfiles.b-cdn.net/icons/Icon_BB_Star.png"
          : "https://clashkingfiles.b-cdn.net/icons/Icon_BB_Empty_Star.png",
      width: size,
      height: size,
    );
  });
}

Widget timeLeft(
    CurrentWarInfo currentWarInfo, BuildContext context, TextStyle? style) {
  String hourIndicator = AppLocalizations.of(context)?.hourIndicator ?? ":";
  DateTime now = DateTime.now();
  Duration difference = Duration.zero;
  String state = '';
  String hours = '';
  String minutes = '';
  String time = '';

  if (currentWarInfo.state == 'preparation') {
    difference = currentWarInfo.startTime.difference(now);
    hours = difference.inHours.toString().padLeft(2, '0');
    minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');
    time = hours + hourIndicator + minutes;
    state = AppLocalizations.of(context)?.startsIn(time) ?? 'Starting in';
  } else if (currentWarInfo.state == 'inWar') {
    difference = currentWarInfo.endTime.difference(now);
    hours = difference.inHours.toString().padLeft(2, '0');
    minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');
    time = hours + hourIndicator + minutes;
    state = AppLocalizations.of(context)?.endsIn(time) ?? 'Ends in';
  }

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Center(
      child: Text(
        currentWarInfo.state == 'warEnded'
            ? AppLocalizations.of(context)?.warEnded ?? 'War ended'
            : state,
        style: style,
      ),
    ),
  );
}

String getPlayerNameByTag(String defenderTag, List<PlayerTab> playerTab) {
  PlayerTab? player = playerTab.firstWhere((p) => p.tag == defenderTag,
      orElse: () => PlayerTab('', 'Inconnu', 0, 0));
  return player.name;
}

String getPlayerTownhallByTag(String defenderTag, List<PlayerTab> playerTab) {
  PlayerTab? player = playerTab.firstWhere((p) => p.tag == defenderTag,
      orElse: () => PlayerTab('', 'Inconnu', 0, 0));
  return player.townhallLevel.toString();
}

String getPlayerMapPositionByTag(
    String defenderTag, List<PlayerTab> playerTab) {
  PlayerTab? player = playerTab.firstWhere((p) => p.tag == defenderTag,
      orElse: () => PlayerTab('', 'Inconnu', 0, 0));
  return player.mapPosition.toString();
}

Map<String, String> analyzeWarLogs(List<WarLogDetails> warLogs) {
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

  return {
    'totalWins': totalWins.toString(),
    'totalLosses': totalLosses.toString(),
    'totalTies': totalTies.toString(),
    'averageMembers': averageMembers.toStringAsFixed(0),
    'averageClanDestruction': averageClanDestruction.toStringAsFixed(0),
    'averageClanStarsPerMember': averageClanStarsPerMember.toStringAsFixed(1),
    'averageOpponentDestruction': averageOpponentDestruction.toStringAsFixed(0),
    'averageOpponentStarsPerMember':
        averageOpponentStarsPerMember.toStringAsFixed(1)
  };
}

Future<String> checkCurrentWar(
    String clanTag,
    LeagueInfoContainer leagueInfoContainer,
    WarInfoContainer warInfoContainer) async {
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
      warInfoContainer.currentWarInfo = CurrentWarInfo.fromJson(
          jsonDecode(utf8.decode(responseWar.bodyBytes)), "war", clanTag);
      return "war";
    } else if (decodedResponse["state"] == "notInWar") {
      DateTime now = DateTime.now();
      if (now.day >= 1 && now.day <= 12) {
        if (responseCwl.statusCode == 200) {
          var decodedResponseCwl =
              jsonDecode(utf8.decode(responseCwl.bodyBytes));
          if (decodedResponseCwl.containsKey("state")) {
            leagueInfoContainer.currentLeagueInfo =
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
