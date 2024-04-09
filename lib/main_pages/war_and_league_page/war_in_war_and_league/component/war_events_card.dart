import 'package:flutter/material.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_in_war_and_league/war_functions.dart';
import 'package:clashkingapp/api/current_war_info.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_in_war_and_league/current_war_info_page.dart';

class WarEventsCard extends StatelessWidget {
  const WarEventsCard({
    super.key,
    required this.currentWarInfo,
    required this.playerTab
  });

  final CurrentWarInfo currentWarInfo;
  final List<PlayerTab> playerTab;

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> allAttacks = [];
    for (var member in currentWarInfo.clan.members) {
      member.attacks?.forEach((attack) {
        allAttacks.add({
          "attackerName": member.name,
          "attackerTag": member.tag,
          "defenderTag": attack.defenderTag,
          "stars": attack.stars,
          "destructionPercentage": attack.destructionPercentage,
          "order": attack.order,
          "clan": 0
        });
      });
    }
    for (var member in currentWarInfo.opponent.members) {
      member.attacks?.forEach((attack) {
        allAttacks.add({
          "attackerName": member.name,
          "attackerTag": member.tag,
          "defenderTag": attack.defenderTag,
          "stars": attack.stars,
          "destructionPercentage": attack.destructionPercentage,
          "order": attack.order,
          "clan": 1
        });
      });
    }

    allAttacks.sort((a, b) => b["order"].compareTo(a["order"]));

    return Card(
        child: ListView.builder(
      shrinkWrap: true,
      physics: ClampingScrollPhysics(),
      itemCount: allAttacks.length,
      itemBuilder: (context, index) {
        var attack = allAttacks[index];
        return Padding(
            padding: EdgeInsets.only(bottom: 16, right: 8, left: 8),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 4,
                    child: Row(
                      children: [
                        SizedBox(
                          height: 40,
                          width: 40,
                          child: Image.network(
                            'https://clashkingfiles.b-cdn.net/home-base/town-hall-pics/town-hall-${getPlayerTownhallByTag(attack["attackerTag"], playerTab)}.png',
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "N°${getPlayerMapPositionByTag(attack["attackerTag"], playerTab)}",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .tertiary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                "${attack["attackerName"]}",
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('${attack["destructionPercentage"]}%',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .tertiary)),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          ...generateStars(attack["stars"]),
                        ]),
                        Icon(attack["clan"] == 1
                            ? LucideIcons.arrowRight
                            : LucideIcons.arrowLeft),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                          "N°${getPlayerMapPositionByTag(attack["defenderTag"], playerTab)}",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .tertiary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ]),
                                Text(
                                    getPlayerNameByTag(attack["defenderTag"], playerTab),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ]),
                        ),
                        SizedBox(
                          height: 40,
                          width: 40,
                          child: Image.network(
                              'https://clashkingfiles.b-cdn.net/home-base/town-hall-pics/town-hall-${getPlayerTownhallByTag(attack["attackerTag"], playerTab)}.png'),
                        ),
                      ],
                    ),
                  )
                ]));
      },
    ));
  }
}