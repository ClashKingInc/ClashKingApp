import 'package:clashkingapp/api/player_account_info.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/subpages/player_dashboard/player_info_page.dart';
import 'package:clashkingapp/api/discord_user_info.dart';
import 'package:clashkingapp/components/app_bar.dart';

class DashboardPage extends StatelessWidget {
  final PlayerAccountInfo playerStats;
  final DiscordUser user;

  DashboardPage({required this.playerStats, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                'Use creator Code ClashKing',
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
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text('TH : ${playerStats.townHallLevel}'),
                                    Text('TR : ${playerStats.trophies}'),
                                    Text(
                                        'BH : ${playerStats.builderHallLevel}'),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text('D : ${playerStats.donations}'),
                                    Text(
                                        'DR : ${playerStats.donationsReceived}'),
                                    Text(
                                        'R : ${(playerStats.donations / playerStats.donationsReceived).toStringAsFixed(2)}'),
                                  ],
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
