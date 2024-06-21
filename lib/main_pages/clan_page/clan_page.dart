import 'package:clashkingapp/main_pages/clan_page/clan_cards/clan_join_leave_card.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/classes/clan/clan_info.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_info_clan/clan_info_page.dart';
import 'package:clashkingapp/classes/account/user.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_cards/clan_info_card.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_cards/clan_search_card.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_cards/no_clan_card.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_join_leave/clan_join_leave.dart';

class ClanInfoPage extends StatefulWidget {
  final Clan? clanInfo;
  final User user;

  ClanInfoPage({required this.clanInfo, required this.user});

  @override
  ClanInfoPageState createState() => ClanInfoPageState();
}

class ClanInfoPageState extends State<ClanInfoPage>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: RefreshIndicator(
          backgroundColor: Theme.of(context).colorScheme.surface,
          onRefresh: () async {
            setState(() {});
          },
          child: ListView(
            children: <Widget>[
              SizedBox(height: 4),
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
                            discordUser: widget.user.tags),
                      ),
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: ClanInfoCard(clanInfo: widget.clanInfo!),
                  ),
                )
              else
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Card(
                    child: NoClanCard(),
                  ),
                ),
              SizedBox(height: 4),
              if (widget.clanInfo != null)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClanJoinLeaveScreen(
                            user: widget.user.tags, clanInfo: widget.clanInfo!),
                      ),
                    );
                  },
                  child: ClanJoinLeaveCard(
                    discordUser: widget.user.tags,
                    clanInfo: widget.clanInfo!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
