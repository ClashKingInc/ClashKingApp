import 'package:flutter/material.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_in_war_and_league/war_functions.dart';
import 'package:clashkingapp/api/current_war_info.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_in_war_and_league/current_war_info_page.dart';
import 'package:clashkingapp/components/right_pointing_triangle.dart';
import 'package:clashkingapp/components/left_pointing_triangle.dart';
import 'package:clashkingapp/components/filter_dropdown.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WarEventsCard extends StatefulWidget {
  final CurrentWarInfo currentWarInfo;
  final List<PlayerTab> playerTab;

  const WarEventsCard({
    super.key,
    required this.currentWarInfo,
    required this.playerTab,
  });

  @override
  WarEventsCardState createState() => WarEventsCardState();
}

class WarEventsCardState extends State<WarEventsCard> {
  String filterOption = 'All';

  void updateFilterOption(String newOption) {
    setState(() {
      filterOption = newOption;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> allAttacks = [];

    if (filterOption != "4") {
      for (var member in widget.currentWarInfo.clan.members) {
        member.attacks?.forEach((attack) {
          if (filterOption == "All" || filterOption == "5" || attack.stars.toString() == filterOption) {
            allAttacks.add({
              "attackerName": member.name,
              "attackerTag": member.tag,
              "defenderTag": attack.defenderTag,
              "stars": attack.stars,
              "destructionPercentage": attack.destructionPercentage,
              "order": attack.order,
              "clan": 0
            });
          }
        });
      }
    }
    if (filterOption != "5") {
      for (var member in widget.currentWarInfo.opponent.members) {
        member.attacks?.forEach((attack) {
          if (filterOption == "All" || filterOption == "4" || attack.stars.toString() == filterOption) {
            allAttacks.add({
              "attackerName": member.name,
              "attackerTag": member.tag,
              "defenderTag": attack.defenderTag,
              "stars": attack.stars,
              "destructionPercentage": attack.destructionPercentage,
              "order": attack.order,
              "clan": 1
            });
          }
        });
      }
    }

    allAttacks.sort((a, b) => b["order"].compareTo(a["order"]));

    if (allAttacks.isNotEmpty) {
      return Padding(
          padding: EdgeInsets.all(8),
          child: Column(children: [
            FilterDropdown(
              sortBy: filterOption,
              updateSortBy: updateFilterOption,
              sortByOptions: {
                AppLocalizations.of(context)?.all ?? "All" : 'All',
                widget.currentWarInfo.clan.name: '5',
                widget.currentWarInfo.opponent.name: '4',
                '3 ${AppLocalizations.of(context)?.starsSmall ?? "stars"}': '3',
                '2 ${AppLocalizations.of(context)?.starsSmall ?? "stars"}': '2',
                '1 ${AppLocalizations.of(context)?.starSmall ?? "star"}': '1',
                '0 ${AppLocalizations.of(context)?.starSmall ?? "star"}': '0',
              },
            ),
            Card(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Column(
                  children: List<Widget>.generate(
                    allAttacks.length,
                    (index) {
                      var attack = allAttacks[index];
                      if (attack["clan"] == 0) {
                        return Padding(
                          padding: EdgeInsets.only(top: 4, bottom: 4),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .background,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        SizedBox(width: 4),
                                        SizedBox(
                                          height: 40,
                                          width: 40,
                                          child: Image.network(
                                              'https://clashkingfiles.b-cdn.net/home-base/town-hall-pics/town-hall-${getPlayerTownhallByTag(attack["attackerTag"], widget.playerTab)}.png'),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                "N°${getPlayerMapPositionByTag(attack["attackerTag"], widget.playerTab)}",
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
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .background,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                            '${attack["destructionPercentage"]}%',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge
                                                ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .tertiary)),
                                        Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ...generateStars(
                                                  attack["stars"], 13),
                                            ]),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      RightPointingTriangle(
                                        width: 10,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .background,
                                      ),
                                      Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                        "N°${getPlayerMapPositionByTag(attack["defenderTag"], widget.playerTab)}",
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .tertiary),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis),
                                                  ]),
                                              Text(
                                                  getPlayerNameByTag(
                                                      attack["defenderTag"],
                                                      widget.playerTab),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                            ]),
                                      ),
                                      SizedBox(
                                          height: 40,
                                          width: 40,
                                          child: Image.network(
                                              'https://clashkingfiles.b-cdn.net/home-base/town-hall-pics/town-hall-${getPlayerTownhallByTag(attack["defenderTag"], widget.playerTab)}.png')),
                                      SizedBox(width: 4),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      } else {
                        return Padding(
                          padding: EdgeInsets.only(top: 4, bottom: 4),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(width: 4),
                                      SizedBox(
                                        height: 40,
                                        width: 40,
                                        child: Image.network(
                                          'https://clashkingfiles.b-cdn.net/home-base/town-hall-pics/town-hall-${getPlayerTownhallByTag(attack["defenderTag"], widget.playerTab)}.png',
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "N°${getPlayerMapPositionByTag(attack["defenderTag"], widget.playerTab)}",
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
                                              getPlayerNameByTag(
                                                  attack["defenderTag"],
                                                  widget.playerTab),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      LeftPointingTriangle(
                                        width: 10,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .background,
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .background,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                            '${attack["destructionPercentage"]}%',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge
                                                ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .tertiary),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ...generateStars(
                                                attack["stars"], 13),
                                          ],
                                        ),
                                      ]
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .background,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                          "N°${getPlayerMapPositionByTag(attack["attackerTag"], widget.playerTab)}",
                                                          style: Theme.of(
                                                                  context)
                                                              .textTheme
                                                              .bodySmall
                                                              ?.copyWith(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .tertiary),
                                                          maxLines: 1,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis),
                                                    ]),
                                                Text(
                                                    "${attack["attackerName"]}",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall,
                                                    maxLines: 1,
                                                    overflow: TextOverflow
                                                        .ellipsis),
                                              ]),
                                        ),
                                        SizedBox(
                                          height: 40,
                                          width: 40,
                                          child: Image.network(
                                              'https://clashkingfiles.b-cdn.net/home-base/town-hall-pics/town-hall-${getPlayerTownhallByTag(attack["attackerTag"], widget.playerTab)}.png'),
                                        ),
                                        SizedBox(width: 4),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
          ]));
    } else {
      return Column(children: [
        SizedBox(height: 16),
        Card(
            child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(AppLocalizations.of(context)?.noDataAvailable ?? 'No data available'))),
        SizedBox(height: 32),
        Image.network(
          'https://clashkingfiles.b-cdn.net/stickers/Villager_HV_Villager_7.png',
          height: 250,
          width: 200,
        )
      ]);
    }
  }
}
