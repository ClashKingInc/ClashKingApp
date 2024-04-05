import 'package:flutter/material.dart';
import 'package:clashkingapp/api/current_war_info.dart';
import 'package:clashkingapp/main_pages/war_league_page/war_war_league/current_war_info_page.dart';
import 'package:clashkingapp/components/app_bar.dart';
import 'package:clashkingapp/api/discord_user_info.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/api/player_account_info.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:clashkingapp/main_pages/war_league_page/components/not_in_war_card.dart';
import 'package:clashkingapp/main_pages/war_league_page/components/cwl_card.dart';

class CurrentWarInfoPage extends StatelessWidget {
  final DiscordUser user;
  final PlayerAccountInfo playerStats;
  CurrentWarInfo? currentWarInfo;

  CurrentWarInfoPage(
      {required this.user, required this.playerStats, this.currentWarInfo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.tertiary,
      appBar: CustomAppBar(user: user),
      body: FutureBuilder<String>(
        future: checkCurrentWar(playerStats),
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
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                        child: CwlCard(playerStats: playerStats),
                      )
                    else
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                        child: NotInWarCard(playerStats: playerStats),
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
    final response_war = await http.get(
      Uri.parse(
          'https://api.clashking.xyz/v1/clans/${playerStats.clan.tag.replaceAll('#', '%23')}/currentwar'),
      headers: {'Authorization': 'Bearer ${dotenv.env['API_KEY']}'},
    );
  
    final response_cwl = await http.get(
      Uri.parse(
          'https://api.clashking.xyz/v1/clans/${playerStats.clan.tag.replaceAll('#', '%23')}/currentwar/leaguegroup'),
      headers: {'Authorization': 'Bearer ${dotenv.env['API_KEY']}'},
    );
  
    if (response_war.statusCode == 200) {
      var decodedResponse = jsonDecode(response_war.body);
      if (decodedResponse["state"] != "notInWar") {
        currentWarInfo = CurrentWarInfo.fromJson(jsonDecode(response_war.body));
        return "war";
      } else {
        DateTime now = DateTime.now();
        if (now.day >= 1 && now.day <= 10) {
          if (response_cwl.statusCode == 200) {
            var decodedResponseCwl = jsonDecode(response_cwl.body);
            if (decodedResponseCwl.containsKey("state")) {
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


class CurrentWarInfoCard extends StatelessWidget {
  const CurrentWarInfoCard({
    super.key,
    required this.currentWarInfo,
  });

  final CurrentWarInfo currentWarInfo;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: () {
                switch (currentWarInfo.state) {
                  case 'accessDenied':
                    return _privateWarLog(context); //Pas sur que ca catch bien
                  case 'preparation':
                    return _preparationState(context);
                  case 'inWar':
                    return _inWarState(context);
                  case 'warEnded':
                    return _warEnded(context);
                  default:
                    return Text('Clan state unknown');
                }
              }(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _privateWarLog(BuildContext context) {
    return Center(
        child: Text(
            AppLocalizations.of(context)?.warLogClosed ?? 'War log closed'));
  }

  Widget _warEnded(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Column(
          children: <Widget>[
            SizedBox(
              width: 90,
              height: 90,
              child: Image.network(currentWarInfo.clan.badgeUrls.large,
                  fit: BoxFit.cover),
            ),
            Center(child: Text(currentWarInfo.clan.name)),
          ],
        ),
        Column(
          children: <Widget>[
            Center(
                child: Text(AppLocalizations.of(context)?.warEnded ?? 'War',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
            Center(
              child: currentWarInfo.clan.stars > currentWarInfo.opponent.stars
                  ? Text(AppLocalizations.of(context)?.victory ?? 'Victory',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.green))
                  : currentWarInfo.clan.stars < currentWarInfo.opponent.stars
                      ? Text(AppLocalizations.of(context)?.defeat ?? 'Defeat',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.red))
                      : currentWarInfo.clan.destructionPercentage >
                              currentWarInfo.opponent.destructionPercentage
                          ? Text(
                              AppLocalizations.of(context)?.victory ??
                                  'Victory',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.green))
                          : currentWarInfo.clan.destructionPercentage <
                                  currentWarInfo.opponent.destructionPercentage
                              ? Text(
                                  AppLocalizations.of(context)?.defeat ??
                                      'Defeat',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.red))
                              : Text(
                                  AppLocalizations.of(context)?.draw ?? 'Tie',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)),
            ),
            Center(
                child: Text(
                    '${currentWarInfo.clan.stars.toString().padRight(2, ' ')} - ${currentWarInfo.opponent.stars.toString().padRight(2, ' ')} ',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 20))),
            Center(
                child: Text(
                    '${currentWarInfo.clan.destructionPercentage.toStringAsFixed(2).padLeft(5, '0')}%    ${currentWarInfo.opponent.destructionPercentage.toStringAsFixed(2).padLeft(5, ' ')}%')),
            Center(child: Text(' ')),
          ],
        ),
        Column(
          children: <Widget>[
            SizedBox(),
            SizedBox(
              width: 90,
              height: 90,
              child: Image.network(currentWarInfo.opponent.badgeUrls.large,
                  fit: BoxFit.cover),
            ),
            Center(child: Text(currentWarInfo.opponent.name)),
          ],
        ),
      ],
    );
  }

  Widget _preparationState(BuildContext context) {
    DateTime now = DateTime.now();
    Duration difference = currentWarInfo.startTime.difference(now);

    String hours = difference.inHours.toString().padLeft(2, '0');
    String minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Column(
          children: <Widget>[
            SizedBox(
              width: 90,
              height: 90,
              child: Image.network(currentWarInfo.clan.badgeUrls.large,
                  fit: BoxFit.cover),
            ),
            Center(child: Text(currentWarInfo.clan.name)),
          ],
        ),
        Column(
          children: <Widget>[
            Center(
                child: Text(AppLocalizations.of(context)?.preparation ??
                    'Preparation')),
            Center(
                child: Text(
                    '${AppLocalizations.of(context)?.startsIn} $hours:$minutes')),
          ],
        ),
        Column(
          children: <Widget>[
            SizedBox(
              width: 90,
              height: 90,
              child: Image.network(currentWarInfo.opponent.badgeUrls.large,
                  fit: BoxFit.cover),
            ),
            Center(child: Text(currentWarInfo.opponent.name)),
          ],
        ),
      ],
    );
  }

  Widget _inWarState(BuildContext context) {
    DateTime now = DateTime.now();
    Duration difference = currentWarInfo.endTime.difference(now);

    String hours = difference.inHours.toString().padLeft(2, '0');
    String minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Column(
          children: <Widget>[
            SizedBox(
              width: 85,
              height: 85,
              child: Image.network(currentWarInfo.clan.badgeUrls.large,
                  fit: BoxFit.cover),
            ),
            Center(child: Text(currentWarInfo.clan.name)),
          ],
        ),
        Column(
          children: <Widget>[
            Center(
                child: Text('$hours:$minutes',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            Center(
                child: Text(
                    '${currentWarInfo.clan.stars.toString().padRight(2, ' ')} - ${currentWarInfo.opponent.stars.toString().padRight(2, ' ')} ',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 20))),
            Center(
                child: Text(
                    '${currentWarInfo.clan.destructionPercentage.toStringAsFixed(2).padLeft(5, '0')}%    ${currentWarInfo.opponent.destructionPercentage.toStringAsFixed(2).padLeft(5, ' ')}%')),
            Center(child: Text(' ')),
          ],
        ),
        Column(
          children: <Widget>[
            SizedBox(
              width: 85,
              height: 85,
              child: Image.network(currentWarInfo.opponent.badgeUrls.large,
                  fit: BoxFit.cover),
            ),
            Center(child: Text(currentWarInfo.opponent.name)),
          ],
        ),
      ],
    );
  }
}
