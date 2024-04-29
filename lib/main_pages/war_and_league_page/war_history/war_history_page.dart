import 'package:flutter/material.dart';
//import 'package:clashkingapp/api/current_war_info.dart';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_history/component/war_history_header.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_in_war_and_league/component/war_statistics_card.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_in_war_and_league/component/war_events_card.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_in_war_and_league/component/war_team_card.dart';

class WarHistoryScreen extends StatefulWidget {
  final String clanTag;
  final List<String> discordUser;
  final List<dynamic> warHistoryData;

  WarHistoryScreen({super.key, required this.clanTag, required this.discordUser, required this.warHistoryData});

  @override
  WarHistoryScreenState createState() => WarHistoryScreenState();
}

class WarHistoryScreenState extends State<WarHistoryScreen>
    with TickerProviderStateMixin {
  late TabController tabController;
  late TabController subTabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    subTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            WarHistoryHeader(
              warHistoryData: widget.warHistoryData,
              discordUser: widget.discordUser,
            ),
            ScrollableTab(
              tabBarDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              ),
              labelColor: Theme.of(context).colorScheme.onBackground,
              unselectedLabelColor: Theme.of(context).colorScheme.onBackground,
              onTap: (value) {
                print('Tab $value selected');
              },
              tabs: [
                Tab(text: 'War'),
                Tab(text: 'League'),
              ], 
              children: [
                Column(
                  children: widget.warHistoryData.map<Widget>((war) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text('Clan Name: ${war["clan"]["name"]}'),
                        Text('Score: ${war["clan"]["stars"]}'),
                      ],
                    );
                  }).toList(),
                ),
                Text('data'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
      
        
          