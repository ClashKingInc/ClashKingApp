import 'package:flutter/material.dart';
import 'package:clashkingapp/api/current_league_info.dart';
import 'dart:ui';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CurrentLeagueInfoScreen extends StatefulWidget {
  final CurrentLeagueInfo currentLeagueInfo;

  CurrentLeagueInfoScreen({super.key, required this.currentLeagueInfo});

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
          unselectedLabelColor: Theme.of(context).colorScheme.onBackground,
          onTap: (value) {
            print('Tab $value selected');
          },
          tabs: [
            Tab(text: AppLocalizations.of(context)?.rounds ?? 'Rounds'),
            Tab(text: AppLocalizations.of(context)?.team ?? 'Teams'),
            Tab(text: AppLocalizations.of(context)?.wars ?? 'Wars')
          ],
          children: [
            ListTile(title: buildRoundsTab(context, widget.currentLeagueInfo)),
            ListTile(title: buildTeamsTab(context, widget.currentLeagueInfo)),
            ListTile(title: buildWarsTab(context)),
          ])
    ])));
  }
}

Widget buildRoundsTab(
    BuildContext context, CurrentLeagueInfo currentLeagueInfo) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Rounds', style: Theme.of(context).textTheme.headline6),
    Text('Current round: ${currentLeagueInfo.state}'),
    Text('Current war: ${currentLeagueInfo.season}'),
    Column(
      children: currentLeagueInfo.clans.map((clan) {
        return Column(
          children: <Widget>[
            Text('Tag: ${clan.tag}'),
            Text('Name: ${clan.name}'),
            Image.network(clan.badgeUrls.small),
            Text('Clan Level: ${clan.clanLevel}'),
            Column(
              children: clan.members.map((member) {
                return Column(children: [
                  Text('Member: ${member.name}'),
                  Text('Tag: ${member.tag}'),
                  Text('TownHall Level: ${member.townHallLevel}')
                ]);
              }).toList(),
            ),
          ],
        );
      }).toList(),
    ),
    Column(
      children: currentLeagueInfo.rounds.map((round) {
        return Text('Round: $round');
      }).toList(),
    )
  ]);
}

Widget buildTeamsTab(
    BuildContext context, CurrentLeagueInfo currentLeagueInfo) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Column(
      children: currentLeagueInfo.clans.map((clan) {
        final townHallLevelCounts = <int, int>{};

        for (var member in clan.members) {
          final townHallLevel = member.townHallLevel;
          townHallLevelCounts[townHallLevel] =
              (townHallLevelCounts[townHallLevel] ?? 0) + 1;
        }

        return Card(
            child: Column(
          children: <Widget>[
            Row(
              children: [
                Column(
                  children: [
                    Text('${clan.name}',
                        style: Theme.of(context).textTheme.bodyMedium),
                    Text('${clan.tag}',
                        style: Theme.of(context).textTheme.labelMedium),
                    Image.network(clan.badgeUrls.small, width: 50, height: 50),
                    Text('Lvl. ${clan.clanLevel}'),
                  ],
                ),
                Wrap(
                  children: townHallLevelCounts.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Wrap(
                        children: [
                          Image.network(
                            'https://clashkingfiles.b-cdn.net/home-base/town-hall-pics/town-hall-${entry.key}.png',
                            width: 20,
                          ),
                          SizedBox(width: 5),
                          Text('x${entry.value}'),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            )
          ],
        ));
      }).toList(),
    ),
    Column(
      children: currentLeagueInfo.rounds.map((round) {
        return Text('Round: $round');
      }).toList(),
    )
  ]);
}

Widget buildWarsTab(BuildContext context) {
  return Column(
    children: [
      ListTile(
        title: Text('Wars', style: Theme.of(context).textTheme.headline6),
      ),
    ],
  );
}
