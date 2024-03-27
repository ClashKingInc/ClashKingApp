import 'package:flutter/material.dart';
import 'package:clashkingapp/api/current_war_info.dart';

class CurrentWarInfoScreen extends StatelessWidget {
  final CurrentWarInfo currentWarInfo;

  CurrentWarInfoScreen({Key? key, required this.currentWarInfo}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Current War Info'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('Tag1: ${currentWarInfo.clan.tag}'),
            subtitle: Text('Tag2: ${currentWarInfo.opponent.tag}'),
          ),
        ],
      ),
    );
  }
}


/*
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Clan Info'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Row(
              children: <Widget>[
                Image.network(currentWarInfo.clan.badgeUrls.small),
                Text(' VS '),
                Image.network(currentWarInfo.opponent.badgeUrls.small),
              ],
            ),
            title: Center(child: Text('${currentWarInfo.clan.name} VS ${currentWarInfo.opponent.name}')),
            subtitle: Text('${currentWarInfo.clan.tag} __ ${currentWarInfo.opponent.tag}'),
          ),
        ],
      ),
    );
  }
}*/