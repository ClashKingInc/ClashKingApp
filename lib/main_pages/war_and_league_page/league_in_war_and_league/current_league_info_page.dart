import 'package:flutter/material.dart';
import 'package:clashkingapp/api/current_league_info.dart';
import 'package:clashkingapp/api/clan_info.dart';
import 'dart:ui';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_info_page.dart';
import 'package:clashkingapp/api/current_war_info.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_in_war_and_league/current_war_info_page.dart';

class CurrentLeagueInfoScreen extends StatefulWidget {
  final CurrentLeagueInfo currentLeagueInfo;
  final String clanTag;
  final ClanInfo clanInfo;

  CurrentLeagueInfoScreen(
      {super.key,
      required this.currentLeagueInfo,
      required this.clanTag,
      required this.clanInfo});

  @override
  CurrentLeagueInfoScreenState createState() => CurrentLeagueInfoScreenState();
}

class CurrentLeagueInfoScreenState extends State<CurrentLeagueInfoScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
            child: Column(children: [
      Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: <Widget>[
          SizedBox(
            height: 230,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.5),
                  BlendMode.darken,
                ),
                child: Image.network(
                  "https://clashkingfiles.b-cdn.net/landscape/war-landscape.jpg",
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: IconButton(
              icon: Icon(Icons.arrow_back,
                  color: Theme.of(context).colorScheme.onPrimary, size: 32),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
      ScrollableTab(
          labelColor: Theme.of(context).colorScheme.onBackground,
          tabBarDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
          ),
          unselectedLabelColor: Theme.of(context).colorScheme.onBackground,
          onTap: (value) {
            print('Tab $value selected');
          },
          tabs: [
            Tab(text: AppLocalizations.of(context)?.rounds ?? 'Rounds'),
            Tab(text: AppLocalizations.of(context)?.team ?? 'Teams'),
            Tab(text: AppLocalizations.of(context)?.wars ?? 'Wars')
          ],
          children: [
            ListTile(title: buildRoundsTab(context, widget.currentLeagueInfo)),
            ListTile(title: buildTeamsTab(context, widget.currentLeagueInfo)),
            ListTile(title: buildWarsTab(context)),
          ])
    ])));
  }
}

Widget buildRoundsTab(
    BuildContext context, CurrentLeagueInfo currentLeagueInfo) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: currentLeagueInfo.rounds.asMap().entries.map((entry) {
      int round =
          entry.key + 1; // Assuming you want round numbering to start from 1
      ClanLeagueRounds clanLeagueRounds = entry.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Round $round',
                style: Theme.of(context).textTheme.titleLarge),
          ),
          FutureBuilder<List<CurrentWarInfo>>(
            future: clanLeagueRounds.warLeagueInfos,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (snapshot.hasData) {
                return Column(
                  children: snapshot.data!.map((warLeagueInfo) {
                    return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CurrentWarInfoScreen(
                                  currentWarInfo: warLeagueInfo),
                            ),
                          );
                        },
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start, // Add this line
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        height: 40,
                                        width: 40,
                                        child: Image.network(
                                            warLeagueInfo.clan.badgeUrls.small),
                                      ),
                                      Text(
                                        warLeagueInfo.clan.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                      Text(
                                        "${warLeagueInfo.clan.attacks}/${warLeagueInfo.teamSize.toString()}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                              color:
                                                  warLeagueInfo.clan.attacks ==
                                                          warLeagueInfo.teamSize
                                                      ? Colors.purple
                                                      : null,
                                            ),
                                      ),
                                      Text(
                                        "${warLeagueInfo.clan.destructionPercentage.toStringAsFixed(2)}%",
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color: warLeagueInfo.clan
                                                          .destructionPercentage >
                                                      warLeagueInfo.opponent
                                                          .destructionPercentage
                                                  ? Colors.blue
                                                  : null,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(
                                          "${warLeagueInfo.clan.stars}",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                color: warLeagueInfo
                                                                .clan.stars >
                                                            warLeagueInfo
                                                                .opponent
                                                                .stars ||
                                                        (warLeagueInfo.clan
                                                                    .stars ==
                                                                warLeagueInfo
                                                                    .opponent
                                                                    .stars &&
                                                            warLeagueInfo.clan
                                                                    .destructionPercentage >
                                                                warLeagueInfo
                                                                    .opponent
                                                                    .destructionPercentage)
                                                    ? Colors.green
                                                    : null,
                                              ),
                                        ),
                                        Text(" - "),
                                        Text(
                                          "${warLeagueInfo.opponent.stars}",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                color: warLeagueInfo.opponent
                                                                .stars >
                                                            warLeagueInfo
                                                                .clan.stars ||
                                                        (warLeagueInfo.opponent
                                                                    .stars ==
                                                                warLeagueInfo
                                                                    .clan
                                                                    .stars &&
                                                            warLeagueInfo
                                                                    .opponent
                                                                    .destructionPercentage >
                                                                warLeagueInfo
                                                                    .clan
                                                                    .destructionPercentage)
                                                    ? Colors.green
                                                    : null,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        height: 40,
                                        width: 40,
                                        child: Image.network(warLeagueInfo
                                            .opponent.badgeUrls.small),
                                      ),
                                      Text(
                                        warLeagueInfo.opponent.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                      Text(
                                        "${warLeagueInfo.opponent.attacks}/${warLeagueInfo.teamSize.toString()}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                              color: warLeagueInfo
                                                          .opponent.attacks ==
                                                      warLeagueInfo.teamSize
                                                  ? Colors.purple
                                                  : null,
                                            ),
                                      ),
                                      Text(
                                        "${warLeagueInfo.opponent.destructionPercentage.toStringAsFixed(2)}%",
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color: warLeagueInfo.opponent
                                                          .destructionPercentage >
                                                      warLeagueInfo.clan
                                                          .destructionPercentage
                                                  ? Colors.blue
                                                  : null,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ));
                  }).toList(),
                );
              } else {
                return Text('No data available');
              }
            },
          ),
        ],
      );
    }).toList(),
  );
}

Widget buildTeamsTab(
    BuildContext context, CurrentLeagueInfo currentLeagueInfo) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Column(
      children: currentLeagueInfo.clans.map((clan) {
        var townHallLevelCounts = <int, int>{};

        for (var member in clan.members) {
          final townHallLevel = member.townHallLevel;
          townHallLevelCounts[townHallLevel] =
              (townHallLevelCounts[townHallLevel] ?? 0) + 1;
        }

        var sortedEntries = townHallLevelCounts.entries.toList()
          ..sort((a, b) => b.key.compareTo(a.key));

        townHallLevelCounts = Map.fromEntries(sortedEntries);

        return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    backgroundColor: Theme.of(context).colorScheme.background,
                    body: FutureBuilder<ClanInfo>(
                      future: ClanService().fetchClanInfo(clan.tag),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else {
                          return ClanInfoScreen(clanInfo: snapshot.data!);
                        }
                      },
                    ),
                  ),
                ),
              );
            },
            child: Card(
                child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                      child: Column(children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(clan.badgeUrls.small,
                            width: 35, height: 35),
                        SizedBox(width: 10),
                        Column(children: [
                          Text(clan.name,
                              style: Theme.of(context).textTheme.bodyMedium),
                          Text(clan.tag,
                              style: Theme.of(context).textTheme.labelMedium),
                        ])
                      ],
                    ),
                    SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: townHallLevelCounts.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Wrap(
                            children: [
                              Image.network(
                                'https://clashkingfiles.b-cdn.net/home-base/town-hall-pics/town-hall-${entry.key}.png',
                                width: 20,
                              ),
                              SizedBox(width: 5),
                              Text('x${entry.value}'),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ])),
                ],
              ),
            )));
      }).toList(),
    ),
  ]);
}

Widget buildWarsTab(BuildContext context) {
  return Column(
    children: [
      ListTile(
        title: Text('Wars', style: Theme.of(context).textTheme.titleLarge),
      ),
    ],
  );
}
