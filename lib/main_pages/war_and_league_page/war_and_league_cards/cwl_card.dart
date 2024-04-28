import 'package:flutter/material.dart';
import 'package:clashkingapp/api/clan_info.dart';
import 'package:clashkingapp/api/current_league_info.dart';
import 'package:clashkingapp/api/current_war_info.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_and_league_cards/current_war_info_card.dart';

class CwlCard extends StatefulWidget {
  final CurrentLeagueInfo currentLeagueInfo;
  final String clanTag;
  final ClanInfo clanInfo;

  CwlCard(
      {super.key,
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

  @override
  Widget build(BuildContext context) {
    Future<CurrentWarInfo?> getActiveWar() async {
      CurrentWarInfo? inWar;
      CurrentWarInfo? inPreparation;
      CurrentWarInfo? lastMatchedWarInfo;

      for (var round in widget.currentLeagueInfo.rounds) {
        List<CurrentWarInfo> warLeagueInfos = await round.warLeagueInfos;

        for (var warInfo in warLeagueInfos) {
          if (warInfo.clan.tag == widget.clanTag ||
              warInfo.opponent.tag == widget.clanTag) {
            lastMatchedWarInfo = warInfo; // Store the last matched warInfo

            if (warInfo.state == 'inWar') {
              return warInfo; // Return immediately if 'inWar'
            } else if (warInfo.state == 'preparation') {
              inPreparation = warInfo; // Store 'preparation' warInfo
            }
          }
        }
      }

      return inWar ?? inPreparation ?? lastMatchedWarInfo;
    }

    return FutureBuilder<CurrentWarInfo?>(
      future: getActiveWar(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
              child: SizedBox(
                  height: 100,
                  width: double.infinity,
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Loading war data..."),
                        CircularProgressIndicator()
                      ])));
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          CurrentWarInfo? warInfo = snapshot.data;
          return CurrentWarInfoCard(
              currentWarInfo: warInfo!, clanTag: widget.clanTag);
        }
      },
    );
  }
}
