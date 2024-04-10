import 'package:flutter/material.dart';
import 'package:clashkingapp/api/current_league_info.dart';
import 'package:clashkingapp/api/clan_info.dart';
import 'dart:ui';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/api/current_war_info.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/league_in_war_and_league/component/round_clans_card.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/league_in_war_and_league/component/teams_card.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/league_in_war_and_league/league_functions.dart';

class CurrentLeagueInfoScreen extends StatefulWidget {
  final CurrentLeagueInfo currentLeagueInfo;
  final String clanTag;
  final ClanInfo clanInfo;

  CurrentLeagueInfoScreen(
      {super.key,
      required this.currentLeagueInfo,
      required this.clanTag,
      required this.clanInfo});

  @override
  CurrentLeagueInfoScreenState createState() => CurrentLeagueInfoScreenState();
}

class CurrentLeagueInfoScreenState extends State<CurrentLeagueInfoScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
            child: Column(children: [
      Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: <Widget>[
          SizedBox(
            height: 230,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.5),
                  BlendMode.darken,
                ),
                child: Image.network(
                  "https://clashkingfiles.b-cdn.net/landscape/war-landscape.jpg",
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: IconButton(
              icon: Icon(Icons.arrow_back,
                  color: Theme.of(context).colorScheme.onPrimary, size: 32),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
      ScrollableTab(
          labelColor: Theme.of(context).colorScheme.onBackground,
          tabBarDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
          ),
          unselectedLabelColor: Theme.of(context).colorScheme.onBackground,
          onTap: (value) {
            print('Tab $value selected');
          },
          tabs: [
            Tab(text: AppLocalizations.of(context)?.rounds ?? 'Rounds'),
            Tab(text: AppLocalizations.of(context)?.team ?? 'Teams'),
          ],
          children: [
            ListTile(title: buildRoundsTab(context, widget.currentLeagueInfo)),
            ListTile(title: buildTeamsTab(context, widget.currentLeagueInfo)),
          ])
    ])));
  }
}

Widget buildRoundsTab(
    BuildContext context, CurrentLeagueInfo currentLeagueInfo) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children:
        currentLeagueInfo.rounds.asMap().entries.toList().reversed.map((entry) {
      int round =
          entry.key + 1; // Assuming you want round numbering to start from 1
      ClanLeagueRounds clanLeagueRounds = entry.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Round $round',
                style: Theme.of(context).textTheme.titleLarge),
          ),
          FutureBuilder<List<CurrentWarInfo>>(
            future: clanLeagueRounds.warLeagueInfos,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (snapshot.hasData) {
                return Column(
                  children: snapshot.data!.map((warLeagueInfo) {
                    return RoundClanCard(warLeagueInfo: warLeagueInfo);
                  }).toList(),
                );
              } else {
                return Text('No data available');
              }
            },
          ),
        ],
      );
    }).toList(),
  );
}

Widget buildTeamsTab(
    BuildContext context, CurrentLeagueInfo currentLeagueInfo) {
  return FutureBuilder<Map<String, Map<String, dynamic>>>(
    future: calculateTotalStarsAndPercentage(currentLeagueInfo.rounds),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return CircularProgressIndicator();
      } else if (snapshot.hasError) {
        return Text('Error: ${snapshot.error}');
      } else {
        Map<String, Map<String, dynamic>> totalByClan = snapshot.data!;
        var sortedClans = currentLeagueInfo.clans.toList()
          ..sort((a, b) => (totalByClan[b.tag]?['stars'] ?? 0)
              .compareTo(totalByClan[a.tag]?['stars'] ?? 0));

        return TeamsCard(sortedClans: sortedClans, totalByClan: totalByClan);
      }
    },
  );
}
