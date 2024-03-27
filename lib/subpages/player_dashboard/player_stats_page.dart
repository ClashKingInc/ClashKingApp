import 'package:flutter/material.dart';
import 'package:clashkingapp/api/player_info.dart';

class StatsScreen extends StatefulWidget {
  final PlayerStats playerStats;

  StatsScreen({Key? key, required this.playerStats}) : super(key: key);

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String dropdownValue = 'Home Base';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Player Stats'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('Name: ${widget.playerStats.name}'),
            subtitle: Text('Tag: ${widget.playerStats.tag}'),
          ),
          ListTile(
            title: DropdownButton<String>(
              value: dropdownValue,
              onChanged: (String? newValue) {
                setState(() {
                  dropdownValue = newValue!;
                });
              },
              items: <String>['Home Base', 'Builder Base', 'Clan Capital']
                .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                })
                .toList(),
            ),
          ),
          if (dropdownValue == 'Home Base') ...[
            ListTile(
              title: Text('Town Hall Level: ${widget.playerStats.townHallLevel}'),
            ),
            ListTile(
              title: Text('Trophies: ${widget.playerStats.trophies}'),
            ),
            ExpansionTile(
              title: Text('Heroes'),
              children: widget.playerStats.heroes.where((hero) => hero.village == 'home').map((hero) => ListTile(
                title: Text(hero.name),
                subtitle: Text('Level: ${hero.level} / ${hero.maxLevel}'),
              )).toList(),
            ),
            ExpansionTile(
              title: Text('Troops'),
              children: widget.playerStats.troops.where((troop) => troop.village == 'home' && !troop.name.startsWith('Super')).map((troop) => ListTile(
                title: Text(troop.name),
                subtitle: Text('Level: ${troop.level} / ${troop.maxLevel} - ${troop.village}'),
              )).toList(),
            ),
            ExpansionTile(
              title: Text('Spells'),
              children: widget.playerStats.spells.map((spell) => ListTile(
                title: Text(spell.name),
                subtitle: Text('Level: ${spell.level} / ${spell.maxLevel} - ${spell.village}'),
              )).toList(),
            ),
          ]
          else if (dropdownValue == 'Builder Base') ...[
            ListTile(
              title: Text('Builder Hall Level: ${widget.playerStats.builderHallLevel}'),
            ),
            ListTile(
              title: Text('Builder Base Trophies: ${widget.playerStats.builderBaseTrophies}'),
            ),
            ExpansionTile(
              title: Text('Heroes'),
              children: widget.playerStats.heroes.where((hero) => hero.village == 'builderBase').map((hero) => ListTile(
                title: Text(hero.name),
                subtitle: Text('Level: ${hero.level} / ${hero.maxLevel}'),
              )).toList(),
            ),
            ExpansionTile(
              title: Text('Troops'),
              children: widget.playerStats.troops.where((troop) => troop.village == 'builderBase').map((troop) => ListTile(
                title: Text(troop.name),
                subtitle: Text('Level: ${troop.level} / ${troop.maxLevel} - ${troop.village}'),
              )).toList(),
            ),
          ]
          else ...[
            ListTile(title: Text('No data'),)
          ]
        ],
      ),
    );
  }
}