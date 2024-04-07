import 'package:clashkingapp/api/current_league_info.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/api/current_war_info.dart';
import 'package:clashkingapp/main_pages/war_league_page/war_war_league/current_war_info_page.dart';
import 'package:clashkingapp/main_pages/war_league_page/war_war_league/current_league_info_page.dart';
import 'package:clashkingapp/components/app_bar.dart';
import 'package:clashkingapp/api/discord_user_info.dart';
import 'package:clashkingapp/api/player_account_info.dart';
import 'package:clashkingapp/api/clan_info.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:clashkingapp/main_pages/war_league_page/components/not_in_war_card.dart';
import 'package:clashkingapp/main_pages/war_league_page/components/cwl_card.dart';
import 'package:clashkingapp/main_pages/war_league_page/components/current_war_info_card.dart';

class CurrentWarInfoPage extends StatefulWidget {
  final DiscordUser user;
  final PlayerAccountInfo playerStats;
  final ClanInfo clanInfo;

  CurrentWarInfoPage({required this.user, required this.playerStats, required this.clanInfo});

  @override
  State<CurrentWarInfoPage> createState() => _CurrentWarInfoPageState();
}

class _CurrentWarInfoPageState extends State<CurrentWarInfoPage> {
  CurrentWarInfo? currentWarInfo;
  CurrentLeagueInfo? currentLeagueInfo;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.tertiary,
      appBar: CustomAppBar(user: widget.user),
      body: FutureBuilder<String>(
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
                              ),
                            ),
                          );
                        },
                        child: CurrentWarInfoCard(currentWarInfo: currentWarInfo!),
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
                              ),
                            ),
                          );
                        },
                        child: CwlCard(playerStats: widget.playerStats),
                      )
                    else
                      Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 8.0),
                        child: NotInWarCard(playerStats: widget.playerStats),
                      ),
                  ],
                ),
              ],
            );
          }
        },
      ),
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
      if (decodedResponse["state"] != "notInWar") {
        currentWarInfo = CurrentWarInfo.fromJson(jsonDecode(utf8.decode(responseWar.bodyBytes)));
        return "war";
      } else {
        DateTime now = DateTime.now();
        if (now.day >= 1 && now.day <= 10) {
          if (responseCwl.statusCode == 200) {
            var decodedResponseCwl = jsonDecode(utf8.decode(responseCwl.bodyBytes));
            if (decodedResponseCwl.containsKey("state")) {
              currentLeagueInfo = CurrentLeagueInfo.fromJson(jsonDecode(utf8.decode(responseCwl.bodyBytes)));
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
