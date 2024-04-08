import 'package:flutter/material.dart';
import 'package:clashkingapp/api/wars_league_info.dart';

class WarLeagueInfoScreen extends StatelessWidget {
  final WarLeagueInfo warLeagueInfo;

  WarLeagueInfoScreen({required this.warLeagueInfo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('War League Info'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Clan Name: ${warLeagueInfo.clan.name}'),
            Text('Clan Tag: ${warLeagueInfo.clan.tag}'),
            Text('Clan Stars: ${warLeagueInfo.clan.stars}'),
            Text('Clan Destruction Percentage: ${warLeagueInfo.clan.destructionPercentage}'),
            // Add more Text widgets for other properties of warLeagueInfo...
          ],
        ),
      ),
    );
  }
}