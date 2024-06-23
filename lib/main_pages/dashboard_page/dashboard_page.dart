import 'package:clashkingapp/classes/account/accounts.dart';

import 'package:clashkingapp/main_pages/dashboard_page/dashboard_cards/to_do_card.dart';
import 'package:clashkingapp/classes/profile/profile_info.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/core/my_app_state.dart';
import 'package:clashkingapp/classes/account/user.dart';
import 'package:clashkingapp/main_pages/dashboard_page/dashboard_cards/creator_code_card.dart';
import 'package:clashkingapp/main_pages/dashboard_page/dashboard_cards/player_infos_card.dart';
import 'package:clashkingapp/main_pages/dashboard_page/dashboard_cards/player_legend_card.dart';
import 'package:clashkingapp/main_pages/dashboard_page/dashboard_cards/player_search_card.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class DashboardPage extends StatefulWidget {
  final ProfileInfo playerStats;
  final User discordUser;
  final Accounts accounts;

  DashboardPage(
      {required this.playerStats,
      required this.discordUser,
      required this.accounts});

  @override
  DashboardPageState createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late Future<void> _initializeFuture;

  @override
  void initState() {
    super.initState();
    _initializeFuture = _checkInitialization();
  }

  Future<void> _checkInitialization() async {
    while (!widget.playerStats.initialized) {
      await Future.delayed(Duration(milliseconds: 100));
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
          backgroundColor: Theme.of(context).colorScheme.surface,
          onRefresh: () async {
            setState(() {
              final appState = Provider.of<MyAppState>(context, listen: false);
              appState.refreshData();
            });
          },
          child: ListView(
            children: <Widget>[
              // Player Infos Card
              // Creator Code Card
              Padding(
                padding: EdgeInsets.only(top: 4.0, left: 8.0, right: 8.0),
                child: CreatorCodeCard(),
              ),
              Padding(
                padding: EdgeInsets.only(left: 8.0, right: 8.0),
                child: PlayerSearchCard(discordUser: widget.discordUser.tags),
              ),
              FutureBuilder<void>(
                future: _initializeFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox.shrink();
                  } else if (snapshot.hasError) {
                    Sentry.captureException(snapshot.error);
                    return Center(
                      child: Text(
                        'Error loading data. Check your internet connection.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    );
                  } else {
                    return Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 8.0, right: 8.0),
                          child: PlayerInfosCard(
                              playerStats: widget.playerStats,
                              discordUser: widget.discordUser.tags),
                        ),
                        // Legend Infos Card : Displayed only if data
                        if (widget.playerStats.playerLegendData != null &&
                            widget.playerStats.playerLegendData!.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(left: 8.0, right: 8.0),
                            child: PlayerLegendCard(
                              playerStats: widget.playerStats,
                              playerLegendData:
                                  widget.playerStats.playerLegendData!,
                            ),
                          ),
                        Padding(
                          padding:
                              EdgeInsets.only(left: 8.0, right: 8.0, bottom: 4),
                          child: ToDoCard(
                              tags: widget.discordUser.tags,
                              playerStats: widget.playerStats,
                              accounts: widget.accounts),
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
