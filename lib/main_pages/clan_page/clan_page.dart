import 'package:clashkingapp/core/my_app_state.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/api/clan_info.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_info_clan/clan_info_page.dart';
import 'package:clashkingapp/api/user_info.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_cards/clan_info_card.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_cards/clan_search_card.dart';

class ClanInfoPage extends StatefulWidget {
  final ClanInfo? clanInfo;
  final User user;

  ClanInfoPage({required this.clanInfo, required this.user});

  @override
  ClanInfoPageState createState() => ClanInfoPageState();
}

class ClanInfoPageState extends State<ClanInfoPage>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    print("clanInfo : ${widget.clanInfo}");
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              final appState = Provider.of<MyAppState>(context, listen: false);
              appState.refreshData();
            });
          },
          child: ListView(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: ClanSearch(discordUser: widget.user.tags),
              ),
              if (widget.clanInfo != null)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ClanInfoScreen(
                              clanInfo: widget.clanInfo!,
                              discordUser: widget.user.tags)),
                    );
                  },
                  child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.0),
                      child: ClanInfoCard(clanInfo: widget.clanInfo!)),
                )
              else
                Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.0),
                    child: Card(
                        child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text("No clan")))),
              // Add more cards as needed
            ],
          ),
        ),
      ),
    );
  }
}
