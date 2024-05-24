import 'package:clashkingapp/api/player_account_info.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/core/my_app_state.dart';
import 'package:clashkingapp/api/user_info.dart';
import 'package:clashkingapp/main_pages/dashboard_page/dashboard_cards/creator_code_card.dart';
import 'package:clashkingapp/main_pages/dashboard_page/dashboard_cards/player_infos_card.dart';
import 'package:clashkingapp/main_pages/dashboard_page/dashboard_cards/player_legend_card.dart';
import 'package:clashkingapp/main_pages/dashboard_page/dashboard_cards/player_search_card.dart';
import 'package:clashkingapp/api/player_legend.dart';
import 'package:provider/provider.dart';

class DashboardPage extends StatefulWidget {
  final PlayerAccountInfo playerStats;
  final User discordUser;

  DashboardPage({required this.playerStats, required this.discordUser});

  @override
  DashboardPageState createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late Future<PlayerLegendData> legendData;

  @override
  void initState() {
    super.initState();
    PlayerLegendService playerLegendService = PlayerLegendService();
    legendData = playerLegendService.fetchLegendData(widget.playerStats.tag);
  }

  @override
  void didUpdateWidget(DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playerStats.tag != oldWidget.playerStats.tag) {
      PlayerLegendService playerLegendService = PlayerLegendService();
      legendData = playerLegendService.fetchLegendData(widget.playerStats.tag);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              PlayerLegendService playerLegendService = PlayerLegendService();
              legendData =
                  playerLegendService.fetchLegendData(widget.playerStats.tag);
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
              Padding(
                padding: EdgeInsets.only(left: 8.0, right: 8.0),
                child: FutureBuilder<PlayerLegendData>(
                  future: legendData,
                  builder: (BuildContext context,
                      AsyncSnapshot<PlayerLegendData> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SizedBox.shrink();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      if (snapshot.data!.legendData.isNotEmpty) {
                        return PlayerLegendCard(
                            playerStats: widget.playerStats,
                            playerLegendData: snapshot.data!);
                      } else {
                        return SizedBox.shrink();
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
