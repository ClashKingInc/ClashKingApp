
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
              child: () {
              switch (currentWarInfo.state) {
                case 'accessDenied':
                  return _privateWarLog();
                case 'notInWar':
                  return _notInWarState();
                case 'preparation':
                  return _preparationState();
                case 'inWar':
                  return _inWarState();
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

  Widget _privateWarLog() {
    return Center(child: Text('Access denied'));
  }
  
  Widget _notInWarState() {
    return 
    Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Column (
          children: <Widget>[
            SizedBox(
              width: 90, // Maximum width
              height: 90, // Maximum height
              child: Image.network(currentWarInfo.clan.badgeUrls.large, fit: BoxFit.cover),
            ),
            Center(child: Text('${currentWarInfo.clan.name} is not inWar.')),
            Center(child: Text('Contact leader or co-leader to start a war.')),
          ],
        ),
      ],
    );
  }
  
  Widget _preparationState() {
    DateTime now = DateTime.now();
    Duration difference = currentWarInfo.startTime.difference(now);

    String hours = difference.inHours.toString().padLeft(2, '0');
    String minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');

    return
    Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Column (
          children: <Widget>[
            SizedBox(
              width: 85, // Maximum width
              height: 85, // Maximum height
              child: Image.network(currentWarInfo.clan.badgeUrls.large, fit: BoxFit.cover),
            ),
            Center(child: Text(currentWarInfo.clan.name)),
          ],
        ),
        Column(
          children: <Widget>[
            Center(child: Text('Preparation phase')),
            Center(child: Text('Starting in $hours:$minutes')),
          ],
        ),
        Column (
          children: <Widget>[
         SizedBox(
              width: 85, // Maximum width
              height: 85, // Maximum height
              child: Image.network(currentWarInfo.opponent.badgeUrls.large, fit: BoxFit.cover),
            ),
            Center(child: Text(currentWarInfo.opponent.name)),
          ],
        ),
      ],
    );
  }
  
  Widget _inWarState() {
    DateTime now = DateTime.now();
    Duration difference = currentWarInfo.endTime.difference(now);

    String hours = difference.inHours.toString().padLeft(2, '0');
    String minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');

    return 
    Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Column (
          children: <Widget>[
            SizedBox(
              width: 85, // Maximum width
              height: 85, // Maximum height
              child: Image.network(currentWarInfo.clan.badgeUrls.large, fit: BoxFit.cover),
            ),
            Center(child: Text(currentWarInfo.clan.name)),
          ],
        ),
        Column(
          children: <Widget>[
            Center(child: Text('$hours:$minutes', style: TextStyle(fontWeight: FontWeight.bold))),
            Center(child: Text('${currentWarInfo.clan.stars.toString().padRight(2, ' ')} - ${currentWarInfo.opponent.stars.toString().padRight(2, ' ')} ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20))),
            Center(child: Text('${currentWarInfo.clan.destructionPercentage.toStringAsFixed(2).padLeft(5, '0')}%    ${currentWarInfo.opponent.destructionPercentage.toStringAsFixed(2).padLeft(5, ' ')}%')),
            Center(child: Text(' ')),
          ],
        ),
        Column (
          children: <Widget>[
         SizedBox(
              width: 85, // Maximum width
              height: 85, // Maximum height
              child: Image.network(currentWarInfo.opponent.badgeUrls.large, fit: BoxFit.cover),
            ),
            Center(child: Text(currentWarInfo.opponent.name)),
          ],
        ),
      ],
    );
  }
}
