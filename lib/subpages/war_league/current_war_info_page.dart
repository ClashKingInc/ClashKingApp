import 'package:flutter/material.dart';
import 'package:clashkingapp/api/current_war_info.dart';

class CurrentWarInfoScreen extends StatelessWidget {
  final CurrentWarInfo currentWarInfo;

  CurrentWarInfoScreen({Key? key, required this.currentWarInfo}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Current War Info'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Statistics'),
              Tab(text: 'Events'),
              Tab(text: 'Roster'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Remplacez les widgets Text par le contenu de chaque onglet
            ListView(
              children: [
                Text('First line of content for Statistics'),
                Text('Second line of content for Statistics'),
                Text('Third line of content for Statistics'),
                // Ajoutez autant de widgets Text que vous le souhaitez
              ],
            ),
            ListView(
              children: [
                Text('First line of content for Statistics'),
                Text('Second line of content for Statistics'),
                Text('Third line of content for Statistics'),
                // Ajoutez autant de widgets Text que vous le souhaitez
              ],
            ),
            ListView(
              children: [
                Text('First line of content for Statistics'),
                Text('Second line of content for Statistics'),
                Text('Third line of content for Statistics'),
                // Ajoutez autant de widgets Text que vous le souhaitez
              ],
            ),
          ],
        ),
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