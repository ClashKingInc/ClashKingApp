import 'package:flutter/material.dart';
import 'package:clashkingapp/api/player_stats.dart';


class StatsScreen extends StatelessWidget {
  final PlayerStats playerStats;

  StatsScreen({Key? key, required this.playerStats}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Player Stats'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('Name: ${playerStats.name}'),
            subtitle: Text('Tag: ${playerStats.tag}'),
          ),
          ListTile(
            title: Text('Town Hall Level: ${playerStats.townHallLevel}'),
          ),
          ListTile(
            title: Text('Trophies: ${playerStats.trophies}'),
          ),
          ExpansionTile(
            title: Text('Heroes'),
            children: playerStats.heroes.map((hero) => ListTile(
              title: Text(hero.name),
              subtitle: Text('Level: ${hero.level} / ${hero.maxLevel}'),
            )).toList(),
          ),
          ExpansionTile(
            title: Text('Troops'),
            children: playerStats.troops.map((troop) => ListTile(
              title: Text(troop.name),
              subtitle: Text('Level: ${troop.level} / ${troop.maxLevel} - ${troop.village} Village'),
            )).toList(),
          ),
          // Add more fields as necessary
        ],
      ),
    );
  }
}
