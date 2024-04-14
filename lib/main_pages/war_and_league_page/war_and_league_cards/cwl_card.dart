import 'package:flutter/material.dart';
import 'package:clashkingapp/api/clan_info.dart';
import 'package:clashkingapp/api/current_league_info.dart';
import 'package:clashkingapp/api/current_war_info.dart';

class CwlCard extends StatefulWidget {
  final CurrentLeagueInfo currentLeagueInfo;
  final String clanTag;
  final ClanInfo clanInfo;

  CwlCard(
      {super.key,
      required this.currentLeagueInfo,
      required this.clanTag,
      required this.clanInfo});

  @override
  CwlCardState createState() => CwlCardState();
}

class CwlCardState extends State<CwlCard> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Future<CurrentWarInfo?> getActiveWar() async {
      CurrentWarInfo? inWar;
      CurrentWarInfo? inPreparation;

      for (var round in widget.currentLeagueInfo.rounds) {
        List<CurrentWarInfo> warLeagueInfos = await round.warLeagueInfos;

        for (var warInfo in warLeagueInfos) {
          if (warInfo.clan.tag == widget.clanTag ||
              warInfo.opponent.tag == widget.clanTag) {
            if (warInfo.state == 'inWar') {
              return warInfo; // Return immediately if 'inWar'
            } else if (warInfo.state == 'preparation') {
              inPreparation = warInfo; // Store 'preparation' warInfo
            }
          }
        }
      }

      // Get the last round's warLeagueInfos and return the last warInfo
      List<CurrentWarInfo> lastRoundWarInfos =
          await widget.currentLeagueInfo.rounds.last.warLeagueInfos;
      return inPreparation ?? lastRoundWarInfos.last;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Column(
                children: <Widget>[
                  SizedBox(
                    width: 70, // Maximum width
                    height: 70, // Maximum height
                    child: Center(
                      child: Image.network(widget.clanInfo.badgeUrls.large,
                          fit: BoxFit.cover),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "We are in league !",
                        textAlign: TextAlign.center,
                      ),
                      FutureBuilder<CurrentWarInfo?>(
                        future: getActiveWar(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else {
                            CurrentWarInfo? warInfo = snapshot.data;
                            return Column( children : [Text('State: ${warInfo?.state}'),
                            Text("${warInfo?.endTime}"),
                            Text("${warInfo?.attacksPerMember}")
                            ]);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
