import 'package:flutter/material.dart';
import 'package:clashkingapp/api/clan_info.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_info_page.dart';
import 'package:clashkingapp/components/app_bar.dart';
import 'package:clashkingapp/api/discord_user_info.dart';
import 'package:clashkingapp/main_pages/clan_page/component/clan_info_card.dart';

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
                MaterialPageRoute(
                    builder: (context) => ClanInfoScreen(clanInfo: clanInfo)),
              );
            },
            child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                child: ClanInfoCard(clanInfo: clanInfo)),
          ),
          // Add more cards as needed
        ],
      ),
    );
  }
}
