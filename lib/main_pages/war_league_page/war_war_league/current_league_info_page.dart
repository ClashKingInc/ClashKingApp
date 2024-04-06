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
              ListTile(title: buildRoundsTab(context)),
              ListTile(title: buildTeamsTab(context)),
              ListTile(title: buildWarsTab(context)),
            ])
      ])));
    }
  }

  Widget buildRoundsTab(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text('Rounds',
              style: Theme.of(context).textTheme.headline6),
        ),
      ],
    );
  }

  Widget buildTeamsTab(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text('Roster',
              style: Theme.of(context).textTheme.headline6),
        ),
      ],
    );
  }

  Widget buildWarsTab(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text('Wars',
              style: Theme.of(context).textTheme.headline6),
        ),
      ],
    );
  }