import 'package:flutter/material.dart';
import 'package:clashkingapp/api/clan_info.dart';
import 'package:clashkingapp/api/current_league_info.dart';
import 'package:clashkingapp/api/current_war_info.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war_league_cards/war_card.dart';

class CwlCard extends StatefulWidget {
  final CurrentLeagueInfo currentLeagueInfo;
  final String clanTag;
  final ClanInfo clanInfo;

  CwlCard({
    super.key,
    required this.currentLeagueInfo,
    required this.clanTag,
    required this.clanInfo,
  });

  @override
  CwlCardState createState() => CwlCardState();
}

class CwlCardState extends State<CwlCard> {
  @override
  void initState() {
    super.initState();
  }

  Future<CurrentWarInfo?> getActiveWar() async {
    CurrentWarInfo? inWar;
    CurrentWarInfo? inPreparation;
    CurrentWarInfo? lastMatchedWarInfo;

    for (var round in widget.currentLeagueInfo.rounds) {
      List<CurrentWarInfo> warLeagueInfos = await round.warLeagueInfos;

      for (var warInfo in warLeagueInfos) {
        if (warInfo.clan.tag == widget.clanTag || warInfo.opponent.tag == widget.clanTag) {
          lastMatchedWarInfo = warInfo;

          if (warInfo.state == 'inWar') {
            return warInfo;
          } else if (warInfo.state == 'preparation') {
            inPreparation = warInfo;
          }
        }
      }
    }

    return inWar ?? inPreparation ?? lastMatchedWarInfo;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CurrentWarInfo?>(
      future: getActiveWar(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            margin: EdgeInsets.only(top: 8, left: 12, right: 12, bottom: 8),
            child: SizedBox(
              height: 100,
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Loading war data..."),
                  SizedBox(height: 10),
                  CircularProgressIndicator()
                ],
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          CurrentWarInfo? warInfo = snapshot.data;
          return CurrentWarInfoCard(currentWarInfo: warInfo!, clanTag: widget.clanTag);
        }
      },
    );
  }
}
