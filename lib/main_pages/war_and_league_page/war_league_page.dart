import 'package:clashkingapp/api/current_league_info.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_and_league_cards/access_denied_card.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/api/current_war_info.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_in_war_and_league/current_war_info_page.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/league_in_war_and_league/current_league_info_page.dart';
import 'package:clashkingapp/api/discord_user_info.dart';
import 'package:clashkingapp/api/player_account_info.dart';
import 'package:clashkingapp/api/clan_info.dart';
import 'package:clashkingapp/api/war_history.dart';
import 'package:clashkingapp/api/war_log.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:clashkingapp/main_pages/war_and_league_page/war_and_league_cards/not_in_war_card.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_and_league_cards/cwl_card.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_and_league_cards/current_war_info_card.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_and_league_cards/war_history_card.dart';
import 'package:clashkingapp/api/wars_league_info.dart';

class CurrentWarInfoPage extends StatefulWidget {
  final ClanInfo clanInfo;
  final PlayerAccountInfo playerStats;
  final DiscordUser discordUser;

  CurrentWarInfoPage(
      {required this.discordUser, required this.playerStats, required this.clanInfo});

  @override
  State<CurrentWarInfoPage> createState() => CurrentWarInfoPageState();
}

class CurrentWarInfoPageState extends State<CurrentWarInfoPage> {
  CurrentWarInfo? currentWarInfo;
  CurrentLeagueInfo? currentLeagueInfo;
  List<Map<int, List<WarLeagueInfo>>> warLeagueInfoByRound = [];
  late Future<List<dynamic>> warHistoryData;
  late Future<WarLog> warLogData;

  @override
  void initState() {
    super.initState();
    warHistoryData = WarHistoryService.fetchWarHistoryData(widget.clanInfo.tag);
    warLogData = WarLogService.fetchWarLogData(widget.clanInfo.tag);
      // Après avoir chargé warLogData
  warLogData.then((data) {
    print("War Log Data Loaded: ${data.items.length} items");
    if (data.items.isNotEmpty) {
      print("First item of War Log: ${data.items.first}");
    }
  });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            warHistoryData = WarHistoryService.fetchWarHistoryData(widget.clanInfo.tag);
            warLogData = WarLogService.fetchWarLogData(widget.clanInfo.tag);
          });
        },
        child: FutureBuilder<String>(
          future: checkCurrentWar(widget.playerStats),
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              final warState = snapshot.data ?? false;
              return ListView(
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      if (warState == "war")
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CurrentWarInfoScreen(
                                  currentWarInfo: currentWarInfo!,
                                  discordUser: widget.discordUser.tags,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 8.0),
                            child: CurrentWarInfoCard(
                              currentWarInfo: currentWarInfo!, 
                              clanTag : widget.clanInfo.tag),
                          ),
                        )
                      else if (warState == "accessDenied")
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: AccessDeniedCard(
                            clanName: widget.playerStats.clan.name, 
                            clanBadgeUrl: widget.playerStats.clan.badgeUrls.large
                          ),
                        )
                      else if (warState == "cwl")
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CurrentLeagueInfoScreen(
                                  currentLeagueInfo: currentLeagueInfo!,
                                  clanTag: widget.playerStats.clan.tag,
                                  clanInfo: widget.clanInfo,
                                  discordUser: widget.discordUser.tags,
                                ),
                              ),
                            );
                          },
                          child: CwlCard(
                            currentLeagueInfo: currentLeagueInfo!,
                            clanTag: widget.playerStats.clan.tag,
                            clanInfo: widget.clanInfo,
                          ),
                        )
                      else
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 8.0),
                          child: NotInWarCard(
                            clanName: widget.playerStats.clan.name, 
                            clanBadgeUrl: widget.playerStats.clan.badgeUrls.large),
                        ),
                      buildWarHistorySection()
                    ],
                  ),
                ],
              );
            }
          },
        ),
      )
    );
  }

  Widget buildWarHistorySection() {
  return FutureBuilder<List<dynamic>>(
    future: Future.wait([warHistoryData, warLogData.then((value) => value.items)]),
    builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      } else if (snapshot.hasError) {
        return Text('Error: ${snapshot.error}');
      } else if (snapshot.hasData) {
        List<dynamic> warHistory = snapshot.data![0];
        List<WarLogDetails> warLogDetails = snapshot.data![1] as List<WarLogDetails>;

        return WarHistoryCard(
          warHistoryData: warHistory,
          warLogData: warLogDetails,
          playerStats: widget.playerStats,
          discordUser: widget.discordUser.tags,
        );
      } else {
        return SizedBox.shrink();
      }
    },
  );
}


  Future<String> checkCurrentWar(PlayerAccountInfo playerStats) async {
    final responseWar = await http.get(
      Uri.parse(
          'https://api.clashking.xyz/v1/clans/${playerStats.clan.tag.replaceAll('#', '%23')}/currentwar'),
    );

    final responseCwl = await http.get(
      Uri.parse(
          'https://api.clashking.xyz/v1/clans/${playerStats.clan.tag.replaceAll('#', '%23')}/currentwar/leaguegroup'),
    );

    if (responseWar.statusCode == 200) {
      var decodedResponse = jsonDecode(utf8.decode(responseWar.bodyBytes));
      if (decodedResponse["state"] != "notInWar" &&
          decodedResponse["reason"] != "accessDenied") {
        currentWarInfo = CurrentWarInfo.fromJson(
            jsonDecode(utf8.decode(responseWar.bodyBytes)), "war");
        return "war";
      } else if (decodedResponse["reason"] == "accessDenied") {
        return "accessDenied";
      } else if (decodedResponse["state"] == "notInWar") {
        return "notInWar";
      } else {
        DateTime now = DateTime.now();
        if (now.day >= 1 && now.day <= 14) {
          if (responseCwl.statusCode == 200) {
            var decodedResponseCwl =
                jsonDecode(utf8.decode(responseCwl.bodyBytes));
            if (decodedResponseCwl.containsKey("state")) {
              currentLeagueInfo =
                  CurrentLeagueInfo.fromJson(decodedResponseCwl);
              return "cwl";
            } else {
              return "notInLeague";
            }
          } else {
            return "notInWar";
          }
        } else {
          throw Exception('Failed to load current war info');
        }
      }
    } else {
      throw Exception('Failed to load current war info');
    }
  }
}
