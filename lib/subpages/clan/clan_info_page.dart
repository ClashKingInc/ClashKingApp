import 'package:flutter/material.dart';
import 'package:clashkingapp/api/clan_info.dart';

class ClanInfoScreen extends StatelessWidget {
  final ClanInfo clanInfo;

  ClanInfoScreen({super.key, required this.clanInfo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Clan Info')),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('Name: ${clanInfo.name}'),
            subtitle: Text('Tag: ${clanInfo.tag}'),
          ),
          ListTile(
            title: Text('Type: ${clanInfo.type}'),
          ),
          ListTile(
            title: Text('Description: ${clanInfo.description}'),
          ),
          ListTile(
            title: Text('Level of the clan: ${clanInfo.clanLevel}'),
          ),
          ExpansionTile(
            title: Text('War stats'),
              children: <Widget>[
                ListTile(
                  title: Text('War wins: ${clanInfo.warWins}'),
                ),
                ListTile(
                  title: Text('War ties: ${clanInfo.warTies}'),
                ),
                ListTile(
                  title: Text('War losses: ${clanInfo.warLosses}'),
                ),
              ],
          ),
        ],
      ),
    );
  }
}
