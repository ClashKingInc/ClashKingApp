import 'package:clashkingapp/api/current_war_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_in_war_and_league/current_war_info_page.dart';


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
      return Image.network(
        index < numberOfStars
            ? "https://clashkingfiles.b-cdn.net/icons/Icon_BB_Star.png"
            : "https://clashkingfiles.b-cdn.net/icons/Icon_BB_Empty_Star.png",
        width: size,
        height: size,
      );
    });
  }

  
  Widget timeLeft(currentWarInfo, context) {
    DateTime now = DateTime.now();
    Duration difference = Duration.zero;
    String state = '';

    if (currentWarInfo.state == 'preparation') {
      difference = currentWarInfo.startTime.difference(now);
      state = AppLocalizations.of(context)?.startsIn ?? 'Starting in';
    } else if (currentWarInfo.state == 'inWar') {
      difference = currentWarInfo.endTime.difference(now);
      state = AppLocalizations.of(context)?.endsIn ?? 'Ends in';
    }

    String hours = difference.inHours.toString().padLeft(2, '0');
    String minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: Text(
          currentWarInfo.state == 'warEnded'
              ? AppLocalizations.of(context)?.warEnded ?? 'War ended'
              : '$state $hours:$minutes',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
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

  String getPlayerMapPositionByTag(String defenderTag, List<PlayerTab> playerTab) {
    PlayerTab? player = playerTab.firstWhere((p) => p.tag == defenderTag,
        orElse: () => PlayerTab('', 'Inconnu', 0, 0));
    return player.mapPosition.toString();
  }