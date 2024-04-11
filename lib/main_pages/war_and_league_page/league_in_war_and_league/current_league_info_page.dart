import 'package:flutter/material.dart';
import 'package:clashkingapp/api/current_league_info.dart';
import 'package:clashkingapp/api/clan_info.dart';
import 'dart:ui';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/api/current_war_info.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/league_in_war_and_league/component/round_clans_card.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/league_in_war_and_league/component/teams_card.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/league_in_war_and_league/league_functions.dart';

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
  late Future<Map<String, Map<String, dynamic>>> totalStarsAndPercentage;

  @override
  void initState() {
    super.initState();
    totalStarsAndPercentage =
        calculateTotalStarsAndPercentage(widget.currentLeagueInfo.rounds);
  }

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
            height: 190,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.5), BlendMode.darken),
                child: Image.network(
                  "https://clashkingfiles.b-cdn.net/landscape/cwl-landscape.png",
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned(
            top: 30,
            left: 10,
            child: IconButton(
              icon: Icon(Icons.arrow_back,
                  color: Theme.of(context).colorScheme.onPrimary, size: 32),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned.fill(
            child: FutureBuilder<Map<String, Map<String, dynamic>>>(
              future: totalStarsAndPercentage,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  // Convert the map to a list of maps for easier sorting and indexing
                  List<Map<String, dynamic>> clansList =
                      snapshot.data!.entries.map((entry) {
                    return {
                      'clanTag': entry.key,
                      'stars': entry.value['stars'],
                    };
                  }).toList();

                  // Sort the list in descending order of stars
                  clansList.sort((a, b) => b['stars'].compareTo(a['stars']));

                  // Find the index of the clan in question
                  int clanPosition = clansList
                      .indexWhere((clan) => clan['clanTag'] == widget.clanTag);

                  // Since index is 0-based, add 1 to get the position
                  clanPosition += 1;

                  int starsDifference = clansList[0]['stars'] -
                      clansList[clanPosition - 1]['stars'];

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                              height: 70,
                              child: Image.network(
                                  widget.clanInfo.badgeUrls.medium)),
                          Column(
                            children: [
                              Text(
                                widget.clanInfo.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: Colors.white),
                              ),
                              Text(
                                widget.clanInfo.tag,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(color: Colors.grey),
                              ),
                            ],
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              SizedBox(
                                  height: 30,
                                  child: Image.network(
                                      "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Podium.png")),
                              Text(
                                "$clanPosition",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              SizedBox(
                                  height: 30,
                                  child: Image.network(
                                      "https://clashkingfiles.b-cdn.net/icons/Icon_BB_Star.png")),
                              Text(
                                "${snapshot.data?[widget.clanTag]?['stars']}",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              SizedBox(
                                  height: 30,
                                  child: Image.network(
                                      "https://clashkingfiles.b-cdn.net/icons/Icon_BB_Empty_Star.png")),
                              Text(
                                "$starsDifference",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              SizedBox(
                                  height: 30,
                                  child: Image.network(
                                      "https://clashkingfiles.b-cdn.net/icons/Icon_DC_Hitrate.png")),
                              Text(
                                "${snapshot.data?[widget.clanTag]?['percentage'].toStringAsFixed(0)}",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      )
                    ],
                  );
                }
              },
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
          ],
          children: [
            ListTile(title: buildRoundsTab(context, widget.currentLeagueInfo)),
            ListTile(
                title: buildTeamsTab(context, widget.currentLeagueInfo,
                    totalStarsAndPercentage)),
          ])
    ])));
  }
}

Widget buildRoundsTab(
    BuildContext context, CurrentLeagueInfo currentLeagueInfo) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children:
        currentLeagueInfo.rounds.asMap().entries.toList().reversed.map((entry) {
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
                    return RoundClanCard(warLeagueInfo: warLeagueInfo);
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

Widget buildTeamsTab(BuildContext context, CurrentLeagueInfo currentLeagueInfo,
    Future<Map<String, Map<String, dynamic>>> totalStarsAndPercentage) {
  return FutureBuilder<Map<String, Map<String, dynamic>>>(
    future: totalStarsAndPercentage,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return CircularProgressIndicator();
      } else if (snapshot.hasError) {
        return Text('Error: ${snapshot.error}');
      } else {
        Map<String, Map<String, dynamic>> totalByClan = snapshot.data!;
        var sortedClans = currentLeagueInfo.clans.toList()
          ..sort((a, b) => (totalByClan[b.tag]?['stars'] ?? 0)
              .compareTo(totalByClan[a.tag]?['stars'] ?? 0));

        return TeamsCard(sortedClans: sortedClans, totalByClan: totalByClan);
      }
    },
  );
}
