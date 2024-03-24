import 'package:clash_king_app/api/player_stats.dart';
import 'package:flutter/material.dart';
import 'package:clash_king_app/dashboard/player_stats_page.dart';

class DashboardPage extends StatelessWidget {
  final PlayerStats playerStats;

  DashboardPage({required this.playerStats});

  @override
  Widget build(BuildContext context) {
    // Your dashboard page implementation
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      body: ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              child: Padding(
                // Padding right and left
                padding:
                    const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment
                      .center, // Adjust vertical alignment here
                  children: <Widget>[
                    Image.asset('assets/icons/Crown.png',
                        width: 80,
                        height: 80), // Specify your desired width and height
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
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StatsScreen(playerStats: playerStats)),
              );
            },
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Name: ${playerStats.name}',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Tag: ${playerStats.tag}',
                        style: TextStyle(fontSize: 18)),
                    SizedBox(height: 8),
                    Text('Townhall: ${playerStats.townHallLevel}',
                        style: TextStyle(fontSize: 18)),
                    SizedBox(height: 8),
                    Text('Trophies: ${playerStats.trophies}',
                        style: TextStyle(fontSize: 18)),
                    SizedBox(height: 8),
                    Text('Builder Hall: ${playerStats.builderHallLevel}',
                        style: TextStyle(fontSize: 18)),
                    SizedBox(height: 8),
                    Text('Donations: ${playerStats.donations}',
                        style: TextStyle(fontSize: 18)),
                    SizedBox(height: 8),
                    Text('Donations Received: ${playerStats.donationsReceived}',
                        style: TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            ),
          ),
          // Add more cards as needed
        ],
      ),
    );
  }
}
