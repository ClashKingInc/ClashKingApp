import 'package:clashkingapp/classes/account/accounts.dart';
import 'package:clashkingapp/main_pages/dashboard_page/dashboard_cards/to_do_card.dart';
import 'package:clashkingapp/classes/profile/profile_info.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/classes/account/user.dart';
import 'package:clashkingapp/main_pages/dashboard_page/dashboard_cards/creator_code_card.dart';
import 'package:clashkingapp/main_pages/dashboard_page/dashboard_cards/player_infos_card.dart';
import 'package:clashkingapp/main_pages/dashboard_page/dashboard_cards/player_legend_card.dart';
import 'package:clashkingapp/main_pages/dashboard_page/dashboard_cards/player_search_card.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/classes/profile/todo/to_do.dart';

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
  late Future<void> _initializeProfileFuture;
  late Future<void> _initializeLegendsFuture;
  late Future<void> _initializeToDoFuture;

  @override
  void initState() {
    super.initState();
    _initializeProfileFuture = _checkInitialization();
    _initializeLegendsFuture = _checkLegendsInitialization();
    _initializeToDoFuture = _checkToDoInitialization();
  }

  Future<void> _checkInitialization() async {
    while (!widget.playerStats.initialized) {
      await Future.delayed(Duration(milliseconds: 100));
    }
  }

  Future<void> _checkLegendsInitialization() async {
    while (!widget.playerStats.legendsInitialized) {
      await Future.delayed(Duration(milliseconds: 100));
      print("legend");
    }
  }

  Future<void> _checkToDoInitialization() async {
    while (!widget.accounts.isTodoInitialized) {
      await Future.delayed(Duration(milliseconds: 100));
      print("todo");
    }
  }

  Future<void> _refreshData() async {
    // Fetch the updated profile information
    widget.playerStats.initialized = false;
    widget.playerStats.legendsInitialized = false;
    widget.accounts.isTodoInitialized = false;
    final profileInfo =
        await ProfileInfoService().fetchProfileInfo(widget.playerStats.tag);

    PlayerDataService.fetchPlayerToDoData(
        widget.accounts.tags, widget.accounts);
    while (profileInfo!.initialized != true ||
        profileInfo.legendsInitialized != true ||
        widget.accounts.isTodoInitialized != true) {
      await Future.delayed(Duration(milliseconds: 100));
    }

    setState(() {
      // Update the player stats with the newly fetched data
      widget.playerStats.updateFrom(profileInfo);
      _initializeProfileFuture = _checkInitialization();
      _initializeLegendsFuture = _checkLegendsInitialization();
      _initializeToDoFuture = _checkToDoInitialization();
    });
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
          onRefresh: _refreshData,
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
              FutureBuilder<void>(
                future: _initializeProfileFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox.shrink();
                  } else if (snapshot.hasError) {
                    Sentry.captureException(snapshot.error);
                    return Center(
                      child: Text(
                        AppLocalizations.of(context)!.connectionErrorRelaunch,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    );
                  } else {
                    return Padding(
                      padding: EdgeInsets.only(left: 8.0, right: 8.0),
                      child: PlayerInfosCard(
                          playerStats: widget.playerStats,
                          discordUser: widget.discordUser.tags),
                    );
                  }
                },
              ),
              FutureBuilder<void>(
                future: _initializeLegendsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox.shrink();
                  } else if (snapshot.hasError) {
                    Sentry.captureException(snapshot.error);
                    return Center(
                      child: Text(
                        AppLocalizations.of(context)!.connectionErrorRelaunch,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    );
                  } else {
                    return Column(
                      children: [
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
                      ],
                    );
                  }
                },
              ),
              FutureBuilder<void>(
                future: _initializeToDoFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox.shrink();
                  } else if (snapshot.hasError) {
                    Sentry.captureException(snapshot.error);
                    return Center(
                      child: Text(
                        AppLocalizations.of(context)!.connectionErrorRelaunch,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    );
                  } else {
                    return Column(
                      children: [
                        // Legend Infos Card : Displayed only if data
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
