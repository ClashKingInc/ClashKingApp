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
              child: Text(currentWarInfo.state),
            ),
            Center(
              child: () {
              switch (currentWarInfo.state) {
                case 'accessDenied':
                  return _buildState1();
                case 'notInWar':
                  return _buildState2();
                case 'preparation':
                  return _buildState3();
                case 'inWar':
                  return _buildState4();
                default:
                  return Text('Clan state unknown');
              }
            }(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildState1() {
    return Center(child: Text('Access denied'));
  }
  
  Widget _buildState2() {
    return Center(child: Text('Not in war'));
  }
  
  Widget _buildState3() {
    return Center(child: Text('Preparation'));
  }
  
  Widget _buildState4() {
    return 
    Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
      
        Column (
          children: <Widget>[
            SizedBox(
              width: 80, // Maximum width
              height: 80, // Maximum height
              child: Image.network(currentWarInfo.clan.badgeUrls.large, fit: BoxFit.cover),
            ),
            Center(child: Text(currentWarInfo.clan.name)),
          ],
        ),
        Column(
          children: <Widget>[
            Center(child: Text('${currentWarInfo.clan.stars} - ${currentWarInfo.opponent.stars} ')),
            Center(child: Text('${currentWarInfo.clan.destructionPercentage.toStringAsFixed(2)} % - ${currentWarInfo.opponent.destructionPercentage.toStringAsFixed(2)} %')),
          ],
        ),
        Column (
          children: <Widget>[
         SizedBox(
              width: 80, // Maximum width
              height: 80, // Maximum height
              child: Image.network(currentWarInfo.opponent.badgeUrls.large, fit: BoxFit.cover),
            ),
            Center(child: Text(currentWarInfo.opponent.name)),
          ],
        ),
      ],
    );
  }
}
