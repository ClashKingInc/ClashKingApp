import 'package:clashkingapp/components/filter_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/classes/clan/war_league/current_league_info.dart';
import 'package:clashkingapp/classes/clan/clan_info.dart';
import 'dart:ui';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/classes/clan/war_league/current_war_info.dart';
import 'package:clashkingapp/main_pages/wars_league_page/league/component/round_clans_card.dart';
import 'package:clashkingapp/main_pages/wars_league_page/league/component/teams_card.dart';
import 'package:clashkingapp/main_pages/wars_league_page/league/league_functions.dart';
import 'package:clashkingapp/main_pages/wars_league_page/league/component/members_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/main_pages/dashboard_page/player_dashboard/player_info_page.dart';
import 'package:clashkingapp/classes/profile/profile_info.dart';

class CurrentLeagueInfoScreen extends StatefulWidget {
  final CurrentLeagueInfo currentLeagueInfo;
  final String clanTag;
  final Clan clanInfo;
  final List<String> discordUser;

  CurrentLeagueInfoScreen(
      {super.key,
      required this.currentLeagueInfo,
      required this.clanTag,
      required this.clanInfo,
      required this.discordUser});

  @override
  CurrentLeagueInfoScreenState createState() => CurrentLeagueInfoScreenState();
}

class CurrentLeagueInfoScreenState extends State<CurrentLeagueInfoScreen> {
  late Future<Map<String, Map<String, dynamic>>> totalStarsAndPercentage;
  late String sortMembersBy = 'stars';
  late String sortTeamsBy = 'stars';

  @override
  void initState() {
    super.initState();
    totalStarsAndPercentage = calculateTotalStarsAndPercentage(
        widget.currentLeagueInfo.rounds, sortTeamsBy);
  }

  void updateSortMembersBy(String newValue) {
    setState(() {
      sortMembersBy = newValue;
    });
  }

  void updateSortTeamsBy(String newValue) {
    setState(() {
      sortTeamsBy = newValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: <Widget>[
                SizedBox(
                  height: 220,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.5), BlendMode.darken),
                      child: CachedNetworkImage(
                        imageUrl:
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
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 32),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Positioned(
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
                        clansList
                            .sort((a, b) => b['stars'].compareTo(a['stars']));

                        // Find the index of the clan in question
                        int clanPosition = clansList.indexWhere(
                            (clan) => clan['clanTag'] == widget.clanTag);

                        // Since index is 0-based, add 1 to get the position
                        clanPosition += 1;

                        int starsDifference = clansList[0]['stars'] -
                            clansList[clanPosition - 1]['stars'];

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            SizedBox(height: 36),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 70,
                                  child: CachedNetworkImage(
                                      imageUrl:
                                          widget.clanInfo.badgeUrls.medium),
                                ),
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
                                          ?.copyWith(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  children: [
                                    SizedBox(
                                      height: 30,
                                      child: CachedNetworkImage(
                                          imageUrl:
                                              "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Podium.png"),
                                    ),
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
                                      child: CachedNetworkImage(
                                          imageUrl:
                                              "https://clashkingfiles.b-cdn.net/icons/Icon_BB_Star.png"),
                                    ),
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
                                      child: CachedNetworkImage(
                                          imageUrl:
                                              "https://clashkingfiles.b-cdn.net/icons/Icon_BB_Empty_Star.png"),
                                    ),
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
                                      child: CachedNetworkImage(
                                          imageUrl:
                                              "https://clashkingfiles.b-cdn.net/icons/Icon_DC_Hitrate.png"),
                                    ),
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
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            ScrollableTab(
              labelColor: Theme.of(context).colorScheme.onSurface,
              labelPadding: EdgeInsets.zero,
              labelStyle: Theme.of(context).textTheme.bodyLarge,
              tabBarDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              ),
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
              onTap: (value) {},
              tabs: [
                Tab(text: AppLocalizations.of(context)?.rounds ?? 'Rounds'),
                Tab(text: AppLocalizations.of(context)?.team ?? 'Teams'),
                Tab(text: AppLocalizations.of(context)?.members ?? "Members")
              ],
              children: [
                buildRoundsTab(
                  context,
                  widget.currentLeagueInfo,
                  widget.discordUser,
                ),
                buildTeamsTab(
                  context,
                  widget.currentLeagueInfo,
                  widget.discordUser,
                  widget.clanTag,
                  totalStarsAndPercentage,
                  sortTeamsBy,
                  updateSortTeamsBy,
                ),
                buildMembersTab(
                  context,
                  widget.currentLeagueInfo,
                  widget.discordUser,
                  widget.clanTag,
                  sortMembersBy,
                  updateSortMembersBy,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget buildRoundsTab(BuildContext context, CurrentLeagueInfo currentLeagueInfo,
    List<String> discordUser) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(height: 4),
      ...currentLeagueInfo.rounds
          .asMap()
          .entries
          .toList()
          .reversed
          .map((entry) {
        int round = entry.key + 1;
        ClanLeagueRounds clanLeagueRounds = entry.value;
        return FutureBuilder<List<CurrentWarInfo>>(
          future: clanLeagueRounds.warLeagueInfos,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('Round $round',
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                  ...snapshot.data!.map((warLeagueInfo) {
                    return RoundClanCard(
                        warLeagueInfo: warLeagueInfo, discordUser: discordUser);
                  }),
                ],
              );
            } else {
              return SizedBox.shrink();
            }
          },
        );
      }),
    ],
  );
}

Widget buildTeamsTab(
    BuildContext context,
    CurrentLeagueInfo currentLeagueInfo,
    List<String> discordUser,
    String clanTag,
    Future<Map<String, Map<String, dynamic>>> totalStarsAndPercentage,
    String sortTeamsBy,
    Function(String) updateSortTeamsBy) {
  Map<String, String> sortByOptions = <String, String>{
    'Stars': 'stars',
    'Percentage': 'percentage',
  };

  return Column(
    children: [
      SizedBox(height: 8),
      FilterDropdown(
          sortBy: sortTeamsBy,
          updateSortBy: updateSortTeamsBy,
          sortByOptions: sortByOptions),
      SizedBox(height: 4),
      FutureBuilder<Map<String, Map<String, dynamic>>>(
        future: totalStarsAndPercentage,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            Map<String, Map<String, dynamic>> totalByClan = snapshot.data!;
            var sortedClans = currentLeagueInfo.clans.toList()
              ..sort((a, b) => (totalByClan[b.tag]?[sortTeamsBy] ?? 0)
                  .compareTo(totalByClan[a.tag]?[sortTeamsBy] ?? 0));
            return TeamsCard(
              sortedClans: sortedClans,
              totalByClan: totalByClan,
              clanTag: clanTag,
              discordUser: discordUser,
            );
          }
        },
      ),
    ],
  );
}

Widget buildMembersTab(
    BuildContext context,
    CurrentLeagueInfo currentLeagueInfo,
    List<String> discordUser,
    String clanTag,
    String sortBy,
    Function(String) updateSortBy) {
  Map<String, String> sortByOptions = <String, String>{
    'Average Stars': 'averageStars',
    'Average Percentage': 'averagePercentage',
    'Stars': 'stars',
    'Percentage': 'percentage',
  };

  return Column(
    children: [
      SizedBox(height: 8),
      FilterDropdown(
          sortBy: sortBy,
          updateSortBy: updateSortBy,
          sortByOptions: sortByOptions),
      SizedBox(height: 4),
      FutureBuilder<Map<String, dynamic>>(
        future: calculateTotalStarsAndPercentageForMember(
            currentLeagueInfo.rounds, clanTag, sortBy),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            Map<String, Map<String, dynamic>> totalStarsByMembers =
                snapshot.data!['totalByMember'];

            List<Widget> memberWidgets = totalStarsByMembers.entries
                .toList()
                .asMap()
                .entries
                .map((entry) {
              int index = entry.key;
              MapEntry<String, Map<String, dynamic>> memberEntry = entry.value;

              return GestureDetector(
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                    );
                    ProfileInfo? playerStats = await ProfileInfoService()
                        .fetchProfileInfo(memberEntry.key);
                    while (playerStats!.initialized != true) {
                      await Future.delayed(Duration(milliseconds: 100));
                    }
                    navigator.pop();
                    navigator.push(
                      MaterialPageRoute(
                        builder: (context) => StatsScreen(
                            playerStats: playerStats, discordUser: discordUser),
                      ),
                    );
                  },
                  child: MembersCard(
                    memberEntry: memberEntry,
                    index: index,
                    discordUser: discordUser,
                  ));
            }).toList();

            return Column(children: memberWidgets);
          }
        },
      ),
    ],
  );
}
