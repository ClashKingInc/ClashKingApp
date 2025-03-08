import 'package:clashkingapp/common/widgets/inputs/filter_dropdown.dart';
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
import 'package:clashkingapp/common/widgets/buttons/chip.dart';

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
  late String sortMembersBy = 'stars';
  late String sortTeamsBy = 'stars';
  ClanLeagueDetails? clan;

  @override
  void initState() {
    super.initState();
    clan = widget.currentLeagueInfo.getClanDetails(widget.clanTag);
  }

  void updateSortMembersBy(String newValue) {
    setState(() {
      sortMembersBy = newValue;
      widget.currentLeagueInfo
          .sortClans(widget.currentLeagueInfo.clans, sortMembersBy);
    });
  }

  void updateSortTeamsBy(String newValue) {
    setState(() {
      sortTeamsBy = newValue;
      widget.currentLeagueInfo
          .sortClans(widget.currentLeagueInfo.clans, sortTeamsBy);
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
                            "https://assets.clashk.ing/landscape/cwl-landscape.png",
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 10,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 32),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Positioned(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(height: 36),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 70,
                            child: CachedNetworkImage(
                                imageUrl: widget.clanInfo.badgeUrls.medium),
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
                      Wrap(
                        alignment: WrapAlignment.start,
                        spacing: 7.0,
                        runSpacing: -7.0,
                        children: <Widget>[
                          ImageChip(
                            textColor: Colors.white,
                            imageUrl:
                                "https://assets.clashk.ing/icons/Icon_HV_Podium.png",
                            labelPadding: 2,
                            label: widget.currentLeagueInfo
                                .getClanDetails(widget.clanTag)!
                                .rank
                                .toString(),
                            description: AppLocalizations.of(context)!
                                .cwlRank(clan!.rank),
                          ),
                          ImageChip(
                            textColor: Colors.white,
                            imageUrl:
                                "https://assets.clashk.ing/icons/Icon_BB_Star.png",
                            labelPadding: 2,
                            label: clan!.stars.toString(),
                            description: AppLocalizations.of(context)!
                                .cwlStars(clan!.stars),
                          ),
                          IconChip(
                            textColor: Colors.white,
                            icon: Icons.keyboard_double_arrow_up,
                            color: Colors.blue,
                            size: 16,
                            labelPadding: 2,
                            label: clan!.starsDifferenceWithFirst.toString(),
                            description: AppLocalizations.of(context)!
                                .cwlMissingStarsFromFirst(
                                    clan!.starsDifferenceWithFirst),
                          ),
                          IconChip(
                            textColor: Colors.white,
                            icon: Icons.arrow_upward,
                            color: Colors.blue,
                            size: 16,
                            labelPadding: 2,
                            label: clan!.starsDifferenceWithNext.toString(),
                            description: AppLocalizations.of(context)!
                                .cwlMissingStarsFromNext(
                                    clan!.starsDifferenceWithNext),
                          ),
                          ImageChip(
                            textColor: Colors.white,
                            imageUrl:
                                "https://assets.clashk.ing/icons/Icon_DC_Hitrate.png",
                            labelPadding: 2,
                            label:
                                clan!.destructionPercentage.toInt().toString(),
                            description: AppLocalizations.of(context)!
                                .cwlDestructionPercentage(clan!
                                    .destructionPercentage
                                    .toStringAsFixed(0)),
                          ),
                        ],
                      ),
                    ],
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

Widget buildTeamsTab(
    BuildContext context,
    CurrentLeagueInfo currentLeagueInfo,
    List<String> discordUser,
    String clanTag,
    String sortTeamsBy,
    Function(String) updateSortTeamsBy) {
  Map<String, String> sortByOptions = <String, String>{
    'Stars': 'stars',
    'Percentage': 'percentage',
  };

  // Sort clans based on the selected sortBy value
  currentLeagueInfo.sortClans(currentLeagueInfo.clans, sortTeamsBy);

  return Column(
    children: [
      SizedBox(height: 8),
      FilterDropdown(
        sortBy: sortTeamsBy,
        updateSortBy: updateSortTeamsBy,
        sortByOptions: sortByOptions,
      ),
      SizedBox(height: 4),
      TeamsCard(
        currentLeagueInfo: currentLeagueInfo,
        clanTag: clanTag,
        sortBy: sortTeamsBy,
        discordUser: discordUser,
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
        sortByOptions: sortByOptions,
      ),
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
                      .fetchCompleteProfileInfo(memberEntry.key);
                  navigator.pop();
                  navigator.push(
                    MaterialPageRoute(
                      builder: (context) => StatsScreen(
                          playerStats: playerStats!, discordUser: discordUser),
                    ),
                  );
                },
                child: MembersCard(
                  memberEntry: memberEntry,
                  index: index,
                  discordUser: discordUser,
                ),
              );
            }).toList();

            return Column(children: memberWidgets);
          }
        },
      ),
    ],
  );
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
