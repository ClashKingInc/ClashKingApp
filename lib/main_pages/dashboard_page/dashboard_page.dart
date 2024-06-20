import 'package:clashkingapp/classes/profile/profile_info.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/core/my_app_state.dart';
import 'package:clashkingapp/classes/user.dart';
import 'package:clashkingapp/main_pages/dashboard_page/dashboard_cards/creator_code_card.dart';
import 'package:clashkingapp/main_pages/dashboard_page/dashboard_cards/player_infos_card.dart';
import 'package:clashkingapp/main_pages/dashboard_page/dashboard_cards/player_legend_card.dart';
import 'package:clashkingapp/main_pages/dashboard_page/dashboard_cards/player_search_card.dart';
import 'package:clashkingapp/classes/profile/legend_league.dart';
import 'package:provider/provider.dart';

class DashboardPage extends StatefulWidget {
  final ProfileInfo playerStats;
  final User discordUser;

  DashboardPage({required this.playerStats, required this.discordUser});

  @override
  DashboardPageState createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late Future<PlayerLegendData> legendData;

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
            setState(() {
              final appState = Provider.of<MyAppState>(context, listen: false);
              appState.refreshData();
            });
          },
          child: ListView(
            children: <Widget>[
              // Creator Code Card
              Padding(
                padding: EdgeInsets.only(top: 4.0, left: 8.0, right: 8.0),
                child: CreatorCodeCard(),
              ),
              Padding(
                padding: EdgeInsets.only(left: 8.0, right: 8.0),
                child: PlayerSearchCard(discordUser: widget.discordUser.tags),
              ),
              // Player Infos Card
              Padding(
                padding: EdgeInsets.only(left: 8.0, right: 8.0),
                child: PlayerInfosCard(
                    playerStats: widget.playerStats,
                    discordUser: widget.discordUser.tags),
              ),
              // Legend Infos Card : Displayed only if data
              if (widget.playerStats.playerLegendData != null)
                Padding(
                  padding: EdgeInsets.only(left: 8.0, right: 8.0),
                  child: PlayerLegendCard(
                    playerStats: widget.playerStats,
                    playerLegendData: widget.playerStats.playerLegendData!,
                  ),
                ),
              /*Padding(
                padding: EdgeInsets.only(left: 8.0, right: 8.0, bottom: 4),
                child: ToDoCard(discordUser: widget.discordUser.tags, playerStats: widget.playerStats),
              ),*/
            ],
          ),
        ),
      ),
    );
  }
}
