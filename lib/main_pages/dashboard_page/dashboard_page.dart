import 'package:clashkingapp/api/player_account_info.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/core/my_app.dart';
import 'package:clashkingapp/api/discord_user_info.dart';
import 'package:clashkingapp/components/app_bar.dart';
import 'package:clashkingapp/main_pages/dashboard_page/dashboard_cards/creator_code_card.dart';
import 'package:clashkingapp/main_pages/dashboard_page/dashboard_cards/player_infos_card.dart';
import 'package:clashkingapp/main_pages/dashboard_page/dashboard_cards/player_legend_card.dart';
import 'package:clashkingapp/api/player_legend.dart';
import 'package:provider/provider.dart';

class DashboardPage extends StatefulWidget {
  final PlayerAccountInfo playerStats;
  final DiscordUser user;

  DashboardPage({required this.playerStats, required this.user});

  @override
  DashboardPageState createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> legendData;

  @override
  void initState() {
    super.initState();
    legendData = PlayerLegendService.fetchLegendData(widget.playerStats.tag);
  }

  @override
  void didUpdateWidget(DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playerStats.tag != oldWidget.playerStats.tag) {
      legendData = PlayerLegendService.fetchLegendData(widget.playerStats.tag);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(user: widget.user),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            final appState = Provider.of<MyAppState>(context, listen: false);
              appState.refreshData();
            legendData = legendData = PlayerLegendService.fetchLegendData(widget.playerStats.tag);
          });
        },
        child: ListView(
          children: <Widget>[
            // Creator Code Card
            Padding(
              padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              child: CreatorCodeCard(),
            ),
            // Player Infos Card
            Padding(
              padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              child: PlayerInfosCard(playerStats: widget.playerStats),
            ),
            // Legend Infos Card : Displayed only if data 
            Padding(
              padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              child: FutureBuilder<Map<String, dynamic>>(
                future: legendData,
                builder: (BuildContext context,
                    AsyncSnapshot<Map<String, dynamic>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                      return SizedBox.shrink();
                  } else if (snapshot.hasError) {
                    return Text(
                        'Error: ${snapshot.error}'); // Show error if something went wrong
                  } else {
                    if (!snapshot.data!['legends'].isEmpty) {
                      return PlayerLegendCard(
                          playerStats: widget.playerStats,
                          legendData:
                              snapshot.data!); // Build PlayerLegendCard with data
                    }
                    else{
                      return SizedBox.shrink();
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}



