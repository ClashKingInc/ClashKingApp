import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/features/clan/models/clan_war_log.dart';
import 'package:clashkingapp/features/war_cwl/models/war_clan.dart';
import 'package:clashkingapp/features/war_cwl/models/war_info.dart';
import 'package:clashkingapp/features/war_cwl/models/war_member.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war/war.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sentry_flutter/sentry_flutter.dart';

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
      errorWidget: (context, url, error) => Icon(Icons.error),
      imageUrl: index < numberOfStars
          ? "https://assets.clashk.ing/icons/Icon_BB_Star.png"
          : "https://assets.clashk.ing/icons/Icon_BB_Empty_Star.png",
      width: size,
      height: size,
    );
  });
}

List<Widget> generateStarsWithIconBefore(
    int numberOfStars, double size, String iconUrl) {
  return [
    CachedNetworkImage(
      imageUrl: iconUrl,
      width: size,
      height: size,
      errorWidget: (context, url, error) => const Icon(Icons.error),
    ),
    const SizedBox(width: 4),
    ...List.generate(
        3,
        (index) => CachedNetworkImage(
              imageUrl: index < numberOfStars
                  ? "https://assets.clashk.ing/icons/Icon_BB_Star.png"
                  : "https://assets.clashk.ing/icons/Icon_BB_Empty_Star.png",
              width: size,
              height: size,
              errorWidget: (context, url, error) => const Icon(Icons.error),
            )),
  ];
}

List<Widget> generateDoubleIcons(
    double size, String iconUrl1, String iconUrl2) {
  return [
    MobileWebImage(
      imageUrl: iconUrl1,
      width: size,
      height: size,
    ),
    const SizedBox(width: 4),
    MobileWebImage(
      imageUrl: iconUrl2,
      width: size,
      height: size,
    ),
  ];
}

List<Widget> generateDoubleImageIconsWithText(
    double size, String iconUrl1, String iconUrl2, String text) {
  return [
    MobileWebImage(
      imageUrl: iconUrl1,
      width: size,
      height: size,
    ),
    const SizedBox(width: 4),
    MobileWebImage(
      imageUrl: iconUrl2,
      width: size,
      height: size,
    ),
    const SizedBox(width: 4),
    Text(text),
  ];
}

List<Widget> generateImageIconWithText(
    double size, String iconUrl, String text) {
  return [
    MobileWebImage(
      imageUrl: iconUrl,
      width: size,
      height: size,
    ),
    const SizedBox(width: 4),
    Text(text),
  ];
}

List<Widget> generateDoubleIconsWithText(
    double size, String iconUrl, IconData icon2, String text) {
  return [
    MobileWebImage(
      imageUrl: iconUrl,
      width: size,
      height: size,
    ),
    const SizedBox(width: 4),
    Icon(icon2),
    const SizedBox(width: 4),
    Text(text),
  ];
}

List<Widget> generateIconWithText(double size, IconData icon, String text) {
  return [
    Icon(icon),
    const SizedBox(width: 4),
    Text(text),
  ];
}

Widget timeLeft(
    WarInfo currentWarInfo, BuildContext context, TextStyle? style) {
  String hourIndicator = AppLocalizations.of(context)?.timeHourIndicator ?? ":";
  DateTime now = DateTime.now();
  Duration difference = Duration.zero;
  String state = '';
  String hours = '';
  String minutes = '';
  String time = '';

  if (currentWarInfo.state == 'preparation') {
    difference = currentWarInfo.startTime?.difference(now) ?? Duration.zero;
    hours = difference.inHours.toString().padLeft(2, '0');
    minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');
    time = hours + hourIndicator + minutes;
    state = AppLocalizations.of(context)?.timeStartsIn(time) ?? 'Starting in';
  } else if (currentWarInfo.state == 'inWar') {
    difference = currentWarInfo.endTime?.difference(now) ?? Duration.zero;
    hours = difference.inHours.toString().padLeft(2, '0');
    minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');
    time = hours + hourIndicator + minutes;
    state = AppLocalizations.of(context)?.timeEndsIn(time) ?? 'Ends in';
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

Future<String?> fetchWarOpponentTag(String clanTag) async {
  final response = await http.get(
      Uri.parse('https://api.clashking.xyz/war/${clanTag.substring(1)}/basic'));

  if (response.statusCode == 200) {
    String body = utf8.decode(response.bodyBytes);
    var data = json.decode(body);

    // Check if 'clans' exists and is a list
    if (data != null && data.containsKey('clans') && data['clans'] is List) {
      List<dynamic> clans = data['clans'];

      // Find the opponent's clan tag
      for (String tag in clans) {
        if (tag != clanTag) {
          return tag; // Return the opponent's clan tag
        }
      }
    }

    // Return null if 'clans' does not exist or no opponent's clan tag found
    return null;
  } else {
    Sentry.captureMessage(
        'Failed to load $clanTag war opponent tag with status code: ${response.statusCode}');
    return null;
  }
}

WarMember? getMemberByTag(String tag, WarClan clan) {
  try {
    return clan.members.firstWhere((m) => m.tag == tag);
  } catch (e) {
    return null;
  }
}
