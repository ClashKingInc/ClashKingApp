import 'package:flutter/material.dart';
import 'package:clashkingapp/api/current_war_info.dart';
import 'package:clashkingapp/subpages/war_league/current_war_info_page.dart';

class CurrentWarInfoPage extends StatelessWidget {
  final CurrentWarInfo currentWarInfo;

  CurrentWarInfoPage({required this.currentWarInfo});

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
              child: CurrentWarInfoCard(currentWarInfo: currentWarInfo),
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

class CurrentWarInfoCard extends StatelessWidget {
  const CurrentWarInfoCard({
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
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image.network(currentWarInfo.clan.badgeUrls.small),
                  Text(' VS '),
                  Image.network(currentWarInfo.opponent.badgeUrls.small),
                ],
              ),
            ),
            Center(child: Text('${currentWarInfo.clan.name} VS ${currentWarInfo.opponent.name}',
                style: TextStyle(fontSize: 18))),
          ],
        ),
      ),
    );
  }
}