import 'package:clashkingapp/api/player_info.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/subpages/player_dashboard/player_stats_page.dart';
import 'package:clashkingapp/api/user_data.dart';
import 'package:clashkingapp/components/app_bar.dart';

class DashboardPage extends StatelessWidget {
  final PlayerStats playerStats;
  final DiscordUser user;

  DashboardPage({required this.playerStats, required this.user});

  @override
  Widget build(BuildContext context) {
    // Your dashboard page implementation
    return Scaffold(
      appBar: CustomAppBar(user: user),
      body: ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CreatorCodeCard(),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        StatsScreen(playerStats: playerStats)),
              );
            },
            child: PlayerStatsCard(playerStats: playerStats),
          ),
          // Add more cards as needed
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

  final PlayerStats playerStats;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: Theme.of(context).textTheme.labelSmall ?? TextStyle(),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: <Widget>[
              SizedBox(
                height: 100,
                width: 100,
                child: Image.network(playerStats.townHallPic),
              ),
              SizedBox(width: 8), // Add some spacing between the image and the text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('${playerStats.tag}'),
                    Text('Townhall: ${playerStats.townHallLevel}'),
                    Text('Trophies: ${playerStats.trophies}'),
                    Text('Builder Hall: ${playerStats.builderHallLevel}'),
                    Text('Donations: ${playerStats.donations}'),
                  ],
                ),
              ),
              SizedBox(width: 8), // Add some spacing between the columns
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Donations Received: ${playerStats.donationsReceived}'),
                    Text('Donations ratio: ${(playerStats.donations / playerStats.donationsReceived).toStringAsFixed(2)}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}