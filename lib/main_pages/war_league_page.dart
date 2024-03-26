import 'package:flutter/material.dart';

class WarLeaguePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('War & League'),
      ),
      body: Center(
        child: Text('Welcome to the War & League Page!'),
      ),
    );
  }
}

/*
import 'package:flutter/material.dart';
import 'package:clashkingapp/api/war_info.dart';
import 'package:clashkingapp/subpages/war_league/current_war_info_page.dart';

class WarLeaguePage extends StatelessWidget {
  final CurrentWarInfo currentWarInfo;

  WarLeaguePage({required this.currentWarInfo});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Center(child: Text('War & League')),
          bottom: TabBar(
            tabs: [
              Tab(text: 'War'),
              Tab(text: 'CWL'),
            ],
          ),
        ),
        body: 
        Column(
          children: <Widget>[
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CurrentWarInfoScreen(currentWarInfo: currentWarInfo)),
                );
              },
              child: CurrentWarCard(currentWarInfo: currentWarInfo),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  Center(child: Text('No war currently')),
                  Center(child: Text('No CWL currently')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CurrentWarCard extends StatelessWidget {
  const CurrentWarCard({
    super.key,
    required this.currentWarInfo,
  });

  final CurrentWarInfo currentWarInfo;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Image.network(currentWarInfo.clan.badgeUrls.small),
                Text(' VS '),
                Image.network(currentWarInfo.opponent.badgeUrls.small),
              ],
            ),
            Center(child: Text('${currentWarInfo.clan.name} VS ${currentWarInfo.opponent.name}',
                style: TextStyle(fontSize: 18))),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
*/