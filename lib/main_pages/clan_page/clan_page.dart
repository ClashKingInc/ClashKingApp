import 'package:clashkingapp/core/my_app.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/api/clan_info.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_info_page/clan_info_page.dart';
import 'package:clashkingapp/api/discord_user_info.dart';
import 'package:clashkingapp/main_pages/clan_page/component/clan_info_card.dart';
import 'package:provider/provider.dart';

class ClanInfoPage extends StatefulWidget {
  final ClanInfo clanInfo;
  final DiscordUser discordUser;

  ClanInfoPage({required this.clanInfo, required this.discordUser});

  @override
  ClanInfoPageState createState() => ClanInfoPageState();
}

class ClanInfoPageState extends State<ClanInfoPage>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: RefreshIndicator(
      onRefresh: () async {
        setState(() {
          final appState = Provider.of<MyAppState>(context, listen: false);
          appState.refreshData();
        });
      },
      child: ListView(
        children: <Widget>[
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClanInfoScreen(clanInfo: widget.clanInfo, discordUser: widget.discordUser.tags)
                ),
              );
            },
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              child: ClanInfoCard(clanInfo: widget.clanInfo)),
          ),
          // Add more cards as needed
        ],
      ),
    ));
  }
}
