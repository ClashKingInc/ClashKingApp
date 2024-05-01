import 'package:clashkingapp/api/current_league_info.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_and_league_cards/access_denied_card.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/api/current_war_info.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_in_war_and_league/current_war_info_page.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/league_in_war_and_league/current_league_info_page.dart';
import 'package:clashkingapp/api/discord_user_info.dart';
import 'package:clashkingapp/api/player_account_info.dart';
import 'package:clashkingapp/api/clan_info.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:clashkingapp/main_pages/war_and_league_page/war_and_league_cards/not_in_war_card.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_and_league_cards/cwl_card.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_and_league_cards/current_war_info_card.dart';
import 'package:clashkingapp/api/wars_league_info.dart';

class CurrentWarInfoPage extends StatefulWidget {
  final DiscordUser user;
  final PlayerAccountInfo playerStats;
  final ClanInfo clanInfo;

  CurrentWarInfoPage(
      {required this.user, required this.playerStats, required this.clanInfo});

  @override
  State<CurrentWarInfoPage> createState() => _CurrentWarInfoPageState();
}

class _CurrentWarInfoPageState extends State<CurrentWarInfoPage> {
  CurrentWarInfo? currentWarInfo;
  CurrentLeagueInfo? currentLeagueInfo;
  List<Map<int, List<WarLeagueInfo>>> warLeagueInfoByRound = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: RefreshIndicator(
      onRefresh: () async {
        setState(() {});
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
                                discordUser: widget.user.tags,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 8.0),
                          child: CurrentWarInfoCard(
                              currentWarInfo: currentWarInfo!,
                              clanTag: widget.clanInfo.tag),
                        ),
                      )
                    else if (warState == "accessDenied")
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: AccessDeniedCard(
                            clanName: widget.playerStats.clan.name,
                            clanBadgeUrl:
                                widget.playerStats.clan.badgeUrls.large),
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
                                discordUser: widget.user.tags,
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
                            clanBadgeUrl:
                                widget.playerStats.clan.badgeUrls.large),
                      ),
                  ],
                ),
              ],
            );
          }
        },
      ),
    ));
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
