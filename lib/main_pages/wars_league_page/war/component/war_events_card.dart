import 'package:flutter/material.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war/war_functions.dart';
import 'package:clashkingapp/classes/clan/war_league/current_war_info.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war/current_war_info_page.dart';
import 'package:clashkingapp/common/right_pointing_triangle.dart';
import 'package:clashkingapp/common/left_pointing_triangle.dart';
import 'package:clashkingapp/common/filter_dropdown.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WarEventsCard extends StatefulWidget {
  final CurrentWarInfo currentWarInfo;
  final List<PlayerTab> playerTab;
  final List<String> discordUser;

  const WarEventsCard({
    super.key,
    required this.currentWarInfo,
    required this.playerTab,
    required this.discordUser,
  });

  @override
  WarEventsCardState createState() => WarEventsCardState();
}

class WarEventsCardState extends State<WarEventsCard> {
  String filterOption = 'All';
  bool filterActiveUsers = false;

  void updateFilterOption(String newOption) {
    setState(() {
      filterOption = newOption;
    });
  }

  void toggleFilterActiveUsers() {
    setState(() {
      filterActiveUsers = !filterActiveUsers;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> allAttacks = [];

    if (filterOption != "4") {
      for (var member in widget.currentWarInfo.clan.members) {
        member.attacks?.forEach((attack) {
          bool shouldAdd = filterOption == "All" || filterOption == "5" || attack.stars.toString() == filterOption;
          if (filterActiveUsers) {
            shouldAdd &= (widget.discordUser.contains(member.tag) || widget.discordUser.contains(attack.defenderTag));
          }
          if (shouldAdd) {
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
          bool shouldAdd = filterOption == "All" || filterOption == "4" || attack.stars.toString() == filterOption;
          if (filterActiveUsers) {
            shouldAdd &= (widget.discordUser.contains(member.tag) || widget.discordUser.contains(attack.defenderTag));
          }
          if (shouldAdd) {
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
      return Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              children: [
                FilterDropdown(
                  sortBy: filterOption,
                  updateSortBy: updateFilterOption,
                  sortByOptions: {
                    AppLocalizations.of(context)?.all ?? "All": 'All',
                    widget.currentWarInfo.clan.name: '5',
                    widget.currentWarInfo.opponent.name: '4',
                    generateStars(3, 20): '3',
                    generateStars(2, 20): '2',
                    generateStars(1, 20): '1',
                    generateStars(0, 20): '0',
                  },
                ),
                SizedBox(height: 4),
                Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Column(
                      children: List<Widget>.generate(
                        allAttacks.length,
                        (index) {
                          var attack = allAttacks[index];
                          if (attack["clan"] == 0) {
                            Color backgroundColor = widget.discordUser.contains(attack["attackerTag"])
                              ? Colors.green
                              : Theme.of(context).scaffoldBackgroundColor;
                            bool hasBorderAttack = widget.discordUser.contains(attack["attackerTag"]);
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
                                          color: Theme.of(context).scaffoldBackgroundColor,
                                          border: hasBorderAttack
                                            ? Border(
                                              top: BorderSide(color: Colors.green, width: 2),
                                              left: BorderSide(color: Colors.green, width: 2),
                                              bottom: BorderSide(color: Colors.green, width: 2),
                                            )
                                            : null,
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            SizedBox(width: 4),
                                            SizedBox(
                                              height: 40,
                                              width: 40,
                                              child: CachedNetworkImage(imageUrl: 
                                                'https://assets.clashk.ing/home-base/town-hall-pics/town-hall-${getPlayerTownhallByTag(attack["attackerTag"], widget.playerTab)}.png'),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    "N°${getPlayerMapPositionByTag(attack["attackerTag"], widget.playerTab)}",
                                                    style: Theme.of(context).textTheme.bodySmall
                                                      ?.copyWith(color: Theme.of(context).colorScheme.tertiary),
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
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).scaffoldBackgroundColor,
                                          border: hasBorderAttack
                                            ? Border(
                                                top: BorderSide(color: Colors.green, width: 2),
                                                bottom: BorderSide(color: Colors.green, width: 2),
                                              )
                                            : null,
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '${attack["destructionPercentage"]}%',
                                              style: Theme.of(context).textTheme.labelLarge
                                                ?.copyWith(color: Theme.of(context).colorScheme.tertiary)),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                ...generateStars(attack["stars"], 13),
                                              ]
                                            ),
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
                                            color: backgroundColor,
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      "N°${getPlayerMapPositionByTag(attack["defenderTag"], widget.playerTab)}",
                                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.tertiary),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  getPlayerNameByTag(attack["defenderTag"], widget.playerTab),
                                                  style: Theme.of(context).textTheme.bodySmall,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            height: 40,
                                            width: 40,
                                            child: CachedNetworkImage(imageUrl: 
                                              'https://assets.clashk.ing/home-base/town-hall-pics/town-hall-${getPlayerTownhallByTag(attack["defenderTag"], widget.playerTab)}.png')),
                                          SizedBox(width: 4),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            );
                          } else {
                            Color backgroundColor = widget.discordUser.contains(attack["defenderTag"])
                              ? Colors.red
                              : Theme.of(context).scaffoldBackgroundColor;
                            bool hasBorderDefense = widget.discordUser.contains(attack["defenderTag"]);
                            return Padding(
                              padding: EdgeInsets.only(top: 4, bottom: 4),
                              child: IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          SizedBox(width: 4),
                                          SizedBox(
                                            height: 40,
                                            width: 40,
                                            child: CachedNetworkImage(imageUrl: 
                                              'https://assets.clashk.ing/home-base/town-hall-pics/town-hall-${getPlayerTownhallByTag(attack["defenderTag"], widget.playerTab)}.png',
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  "N°${getPlayerMapPositionByTag(attack["defenderTag"], widget.playerTab)}",
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.tertiary),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  getPlayerNameByTag(attack["defenderTag"], widget.playerTab),
                                                  style: Theme.of(context).textTheme.bodySmall,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          LeftPointingTriangle(
                                            width: 10,
                                            color: backgroundColor,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).scaffoldBackgroundColor,
                                          border: hasBorderDefense
                                            ? Border(
                                              top: BorderSide(color: Colors.red, width: 2),
                                              bottom: BorderSide(color: Colors.red, width: 2),
                                            )
                                            : null,
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '${attack["destructionPercentage"]}%',
                                              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.tertiary),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                ...generateStars(attack["stars"], 13),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).scaffoldBackgroundColor,
                                          border: hasBorderDefense
                                            ? Border(
                                              top: BorderSide(color: Colors.red, width: 2),
                                              right: BorderSide(color: Colors.red, width: 2),
                                              bottom: BorderSide(color: Colors.red, width: 2),
                                            )
                                            : null,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                        "N°${getPlayerMapPositionByTag(attack["attackerTag"], widget.playerTab)}",
                                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.tertiary),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis),
                                                    ]
                                                  ),
                                                  Text(
                                                    "${attack["attackerName"]}",
                                                    style: Theme.of(context).textTheme.bodySmall,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis),
                                                ]
                                              ),
                                            ),
                                            SizedBox(
                                              height: 40,
                                              width: 40,
                                              child: CachedNetworkImage(imageUrl: 
                                                'https://assets.clashk.ing/home-base/town-hall-pics/town-hall-${getPlayerTownhallByTag(attack["attackerTag"], widget.playerTab)}.png'),
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
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 20,
            child: IconButton(
              icon: Icon(Icons.link, color: filterActiveUsers ? Colors.green : null),
              onPressed: toggleFilterActiveUsers,
              color: filterActiveUsers ? Colors.green : Colors.grey,
              tooltip: 'Filter Active Users',
            ),
          ),
        ],
      );
    } else {
      return Stack(
        children: [
          Center(
            child: Column(
              children: [
                SizedBox(height: 8),
                FilterDropdown(
                  sortBy: filterOption,
                  updateSortBy: updateFilterOption,
                  sortByOptions: {
                    AppLocalizations.of(context)?.all ?? "All": 'All',
                    widget.currentWarInfo.clan.name: '5',
                    widget.currentWarInfo.opponent.name: '4',
                    generateStars(3, 20): '3',
                    generateStars(2, 20): '2',
                    generateStars(1, 20): '1',
                    generateStars(0, 20): '0',
                  },
                ),
                SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(AppLocalizations.of(context)?.noDataAvailable ?? 'No data available'))),
                SizedBox(height: 32),
                CachedNetworkImage(imageUrl: 
                  'https://assets.clashk.ing/stickers/Villager_HV_Villager_7.png',
                  height: 250,
                  width: 200,
                ),
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 20,
            child: IconButton(
              icon: Icon(Icons.link, color: filterActiveUsers ? Colors.green : null),
              onPressed: toggleFilterActiveUsers,
              color: filterActiveUsers ? Colors.green : Colors.grey,
              tooltip: 'Filter Active Users',
            ),
          ),
        ],
      );
    }
  }
}
