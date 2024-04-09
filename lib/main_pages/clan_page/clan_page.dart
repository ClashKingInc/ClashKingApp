import 'package:flutter/material.dart';
import 'package:clashkingapp/api/clan_info.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_info_page.dart';
import 'package:clashkingapp/components/app_bar.dart';
import 'package:clashkingapp/api/discord_user_info.dart';

class ClanInfoPage extends StatelessWidget {
  final ClanInfo clanInfo;
  final DiscordUser user;

  ClanInfoPage({required this.clanInfo, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(user: user),
      body: ListView(
        children: <Widget>[
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ClanInfoScreen(clanInfo: clanInfo)),
              );
            },
            child: ClanInfoCard(clanInfo: clanInfo),
          ),
          // Add more cards as needed
        ],
      ),
    );
  }
}

class ClanInfoCard extends StatelessWidget {
  const ClanInfoCard({
    super.key,
    required this.clanInfo,
  });

  final ClanInfo clanInfo;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Name: ${clanInfo.name}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Tag: ${clanInfo.tag}',
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Clan level: ${clanInfo.clanLevel}',
                style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}