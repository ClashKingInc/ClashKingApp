import 'package:clashkingapp/api/player_account_info.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/subpages/player_dashboard/player_info_page.dart';
import 'package:clashkingapp/api/discord_user_info.dart';
import 'package:clashkingapp/components/app_bar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:clashkingapp/subpages/player_dashboard/player_legend_page.dart';

class DashboardPage extends StatelessWidget {
  final PlayerAccountInfo playerStats;
  final DiscordUser user;

  DashboardPage({required this.playerStats, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.tertiary,
      appBar: CustomAppBar(user: user),
      body: ListView(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: CreatorCodeCard(),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: PlayerStatsCard(playerStats: playerStats),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: PlayerLegendCard(playerStats: playerStats),
          ),
        ],
      ),
    );
  }
}

class CreatorCodeCard extends StatelessWidget {
  const CreatorCodeCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        // Padding right and left
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.center, // Adjust vertical alignment here
          children: <Widget>[
            Image.asset('assets/icons/Crown.png',
                width: 80, height: 80), // Specify your desired width and height
            SizedBox(width: 16), // Add space between the image and text
            Expanded(
              // Use Expanded to ensure text takes up the remaining space
              child: Text(
                AppLocalizations.of(context)?.creatorCode ??
                    'Creator Code : ClashKing',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlayerStatsCard extends StatelessWidget {
  const PlayerStatsCard({
    super.key,
    required this.playerStats,
  });

  final PlayerAccountInfo playerStats;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StatsScreen(playerStats: playerStats),
          ),
        );
      },
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.labelLarge ?? TextStyle(),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        Text(
                          playerStats.name,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        SizedBox(
                          height: 100,
                          width: 100,
                          child: Image.network(playerStats.townHallPic),
                        ),
                        Text(
                          '${playerStats.tag}',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 4.0, // gap between adjacent chips
                            runSpacing: 0.0, // gap between lines
                            children: <Widget>[
                              Chip(
                                avatar: CircleAvatar(
                                  backgroundColor: Colors
                                      .transparent, // Set to a suitable color for your design.
                                  child: Image.network(
                                      "https://clashkingfiles.b-cdn.net/icons/Clan_Badge_Border_2.png"),
                                ),
                                labelPadding:
                                    EdgeInsets.only(left: 2.0, right: 2.0),
                                label: Text(
                                  playerStats.clan.name,
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                              Chip(
                                avatar: CircleAvatar(
                                  backgroundColor: Colors
                                      .transparent, // Set to a suitable color for your design.
                                  child: playerStats.warPreference == 'in'
                                      ? Image.network(
                                          "https://clashkingfiles.b-cdn.net/icons/Icon_HV_In.png")
                                      : Image.network(
                                          'https://clashkingfiles.b-cdn.net/icons/Icon_HV_Out.png'),
                                ),
                                labelPadding:
                                    EdgeInsets.only(left: 2.0, right: 2.0),
                                label: Text(
                                  playerStats.warPreference.toString(),
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                              Chip(
                                avatar: CircleAvatar(
                                  backgroundColor: Colors
                                      .transparent, // Set to a suitable color for your design.
                                  child: Image.network(playerStats.townHallPic),
                                ),
                                label: Text('${playerStats.townHallLevel}',
                                    style:
                                        Theme.of(context).textTheme.labelLarge),
                                labelPadding: EdgeInsets.zero,
                              ),
                              Chip(
                                avatar: CircleAvatar(
                                  backgroundColor: Colors
                                      .transparent, // Set to a suitable color for your design.
                                  child: Image.network(
                                      "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Trophy.png"),
                                ),
                                label: Text('${playerStats.trophies}',
                                    style:
                                        Theme.of(context).textTheme.labelLarge),
                                labelPadding: EdgeInsets.zero,
                              ),
                              Chip(
                                avatar: Icon(LucideIcons.chevronsUpDown,
                                    color: Color.fromARGB(255, 0, 136, 255)),
                                labelPadding: EdgeInsets.zero,
                                label: Text(
                                  '${(playerStats.donations / (playerStats.donationsReceived == 0 ? 1 : playerStats.donationsReceived)).toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                              Chip(
                                avatar: CircleAvatar(
                                  backgroundColor: Colors
                                      .transparent, // Set to a suitable color for your design.
                                  child:
                                      Image.network(playerStats.builderHallPic),
                                ),
                                label: Text('${playerStats.builderHallLevel}',
                                    style:
                                        Theme.of(context).textTheme.labelLarge),
                                labelPadding: EdgeInsets.zero,
                              ),
                              Chip(
                                avatar: CircleAvatar(
                                  backgroundColor: Colors
                                      .transparent, // Set to a suitable color for your design.
                                  child: Image.network(
                                      "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Trophy.png"),
                                ),
                                label: Text(
                                    '${playerStats.builderBaseTrophies}',
                                    style:
                                        Theme.of(context).textTheme.labelLarge),
                                labelPadding: EdgeInsets.zero,
                              ),
                              Chip(
                                avatar: CircleAvatar(
                                  backgroundColor: Colors
                                      .transparent, // Set to a suitable color for your design.
                                  child: Image.network(
                                      "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Attack_Star.png"),
                                ),
                                labelPadding:
                                    EdgeInsets.only(left: 2.0, right: 2.0),
                                label: Text(
                                  '${playerStats.warStars}',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



class PlayerLegendCard extends StatelessWidget {
  const PlayerLegendCard({
    super.key,
    required this.playerStats,
  });

  final PlayerAccountInfo playerStats;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LegendScreen(playerStats: playerStats),
          ),
        );
      },
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.labelLarge ?? TextStyle(),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        Text(
                          "Legend League",
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        SizedBox(
                          height: 100,
                          width: 100,
                          child: Image.network("https://clashkingfiles.b-cdn.net/icons/Icon_HV_League_Legend_3.png"),
                        ),
                      ],
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 4.0, // gap between adjacent chips
                            runSpacing: 0.0, // gap between lines
                            children: <Widget>[
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
