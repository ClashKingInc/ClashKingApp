import 'package:clashkingapp/api/player_account_info.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/subpages/player_dashboard/player_info_page.dart';
import 'package:clashkingapp/api/discord_user_info.dart';
import 'package:clashkingapp/components/app_bar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';

class DashboardPage extends StatelessWidget {
  final PlayerAccountInfo playerStats;
  final DiscordUser user;

  DashboardPage({required this.playerStats, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8E1),
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
        style: Theme.of(context).textTheme.labelSmall ?? TextStyle(),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(child: Text(playerStats.name)),
                Center(child: Text(playerStats.tag)),
                Row(
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        SizedBox(
                          height: 100,
                          width: 100,
                          child: Image.network(playerStats.townHallPic),
                        ),
                      ],
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Wrap(
                            spacing: 4.0, // gap between adjacent chips
                            runSpacing: 0.0, // gap between lines
                            children: <Widget>[
                              Chip(
                                avatar: Icon(LucideIcons.home, size: 16),
                                label: Text('${playerStats.townHallLevel}',
                                    style:
                                        Theme.of(context).textTheme.labelSmall),
                                labelPadding:
                                    EdgeInsets.only(left: 2.0, right: 2.0),
                              ),
                              Chip(
                                avatar: Icon(LucideIcons.hammer),
                                label: Text('${playerStats.builderHallLevel}',
                                    style:
                                        Theme.of(context).textTheme.labelSmall),
                                labelPadding:
                                    EdgeInsets.only(left: 2.0, right: 2.0),
                              ),
                              Chip(
                                avatar: Icon(LucideIcons.trophy),
                                label: Text('${playerStats.trophies}',
                                    style:
                                        Theme.of(context).textTheme.labelSmall),
                                labelPadding:
                                    EdgeInsets.only(left: 2.0, right: 2.0),
                              ),
                              
                              Chip(
                                avatar: Icon(LucideIcons.chevronUp),
                                label: Text('${playerStats.donations}',
                                    style:
                                        Theme.of(context).textTheme.labelSmall),
                                labelPadding:
                                    EdgeInsets.only(left: 2.0, right: 2.0),
                              ),
                              Chip(
                                avatar: Icon(LucideIcons.chevronDown),
                                label: Text('${playerStats.donationsReceived}',
                                    style:
                                        Theme.of(context).textTheme.labelSmall),
                                labelPadding:
                                    EdgeInsets.only(left: 2.0, right: 2.0),
                              ),
                              Chip(
                                avatar: Icon(LucideIcons.chevronsUpDown),
                                label: Text(
                                    '${(playerStats.donations / (playerStats.donationsReceived == 0 ? 1 : playerStats.donationsReceived))}',
                                    style:
                                        Theme.of(context).textTheme.labelSmall),
                                labelPadding:
                                    EdgeInsets.only(left: 2.0, right: 2.0),
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
