import 'package:clashkingapp/api/current_league_info.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war_league_cards/access_denied_card.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/api/current_war_info.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war/current_war_info_page.dart';
import 'package:clashkingapp/main_pages/wars_league_page/league/current_league_info_page.dart';
import 'package:clashkingapp/api/user_info.dart';
import 'package:clashkingapp/api/player_account_info.dart';
import 'package:clashkingapp/api/clan_info.dart';
import 'package:clashkingapp/api/war_log.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war_league_cards/not_in_war_card.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war_league_cards/cwl_card.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war_league_cards/war_card.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war_league_cards/war_history_card.dart';
import 'package:clashkingapp/api/wars_league_info.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_cards/no_clan_card.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war/war_functions.dart';

class CurrentWarInfoPage extends StatefulWidget {
  final ClanInfo? clanInfo;
  final PlayerAccountInfo playerStats;
  final User discordUser;
  @override
  final Key key;

  CurrentWarInfoPage(
      {required this.key,
      required this.discordUser,
      required this.playerStats,
      required this.clanInfo});

  @override
  State<CurrentWarInfoPage> createState() => CurrentWarInfoPageState();
}

class CurrentWarInfoPageState extends State<CurrentWarInfoPage> {
  LeagueInfoContainer leagueInfoContainer = LeagueInfoContainer();
  WarInfoContainer warInfoContainer = WarInfoContainer();

  List<Map<int, List<WarLeagueInfo>>> warLeagueInfoByRound = [];
  late Future<WarLog> warLogData = Future.value(WarLog(items: []));
  late Map<String, String> warLogStats = {};
  late Future<String> currentWarFuture;

  @override
  void initState() {
    super.initState();
    setupData();
  }

  void setupData() {
    if (widget.clanInfo != null) {
      currentWarFuture = checkCurrentWar(
          widget.clanInfo!.tag, leagueInfoContainer, warInfoContainer);
      warLogData = WarLogService.fetchWarLogData(widget.clanInfo!.tag);
      warLogData.then((data) {
        if (data.items.isNotEmpty) {
          setState(() {
            warLogStats = analyzeWarLogs(data.items);
          });
        }
      });
    }
    else {
      currentWarFuture = Future.value("noClan");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: RefreshIndicator(
      backgroundColor: Theme.of(context).colorScheme.surface,
      onRefresh: () async {
        setState(() {
          setupData();
        });
      },
      child: FutureBuilder<String>(
        future: currentWarFuture,
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            final warState = snapshot.data ?? false;
            return ListView(
              children: <Widget>[
                if (warState == "war")
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CurrentWarInfoScreen(
                            currentWarInfo: warInfoContainer.currentWarInfo!,
                            discordUser: widget.discordUser.tags,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.only(left: 4.0, right: 4.0),
                      child: CurrentWarInfoCard(
                          currentWarInfo: warInfoContainer.currentWarInfo!,
                          clanTag: widget.clanInfo!.tag),
                    ),
                  )
                else if (warState == "accessDenied")
                  Padding(
                    padding: EdgeInsets.only(left: 4.0, right: 4.0),
                    child: AccessDeniedCard(
                        clanName: widget.playerStats.clan!.name,
                        clanBadgeUrl: widget.playerStats.clan!.badgeUrls.large),
                  )
                else if (warState == "cwl")
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CurrentLeagueInfoScreen(
                            currentLeagueInfo:
                                leagueInfoContainer.currentLeagueInfo!,
                            clanTag: widget.playerStats.clan!.tag,
                            clanInfo: widget.clanInfo!,
                            discordUser: widget.discordUser.tags,
                          ),
                        ),
                      );
                    },
                    child: CwlCard(
                      currentLeagueInfo: leagueInfoContainer.currentLeagueInfo!,
                      clanTag: widget.playerStats.clan!.tag,
                      clanInfo: widget.clanInfo!,
                    ),
                  )
                else if (warState == "noClan")
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Card(
                      child: NoClanCard(),
                    ),
                  )
                else
                  Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    child: NotInWarCard(
                        clanName: widget.playerStats.clan!.name,
                        clanBadgeUrl: widget.playerStats.clan!.badgeUrls.large),
                  ),
                if (warState != "noClan" && warState != "accessDenied")
                  buildWarHistorySection()
              ],
            );
          }
        },
      ),
    ));
  }

  Widget buildWarHistorySection() {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([warLogData.then((value) => value.items)]),
      builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          List<WarLogDetails> warLogDetails =
              snapshot.data![0] as List<WarLogDetails>;

          return WarHistoryCard(
            warLogData: warLogDetails,
            playerStats: widget.playerStats,
            discordUser: widget.discordUser.tags,
            warLogStats: warLogStats,
          );
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }
}
