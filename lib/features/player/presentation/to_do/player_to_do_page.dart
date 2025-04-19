import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/presentation/to_do/widget/player_to_do_body.dart';
import 'package:clashkingapp/features/player/presentation/to_do/widget/player_to_do_header.dart';
import 'package:clashkingapp/features/war_cwl/models/war_member_presence.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';

class PlayerToDoScreen extends StatefulWidget {
  final List<Player> players;
  final Map<String, WarMemberPresence> memberPresenceMap;

  PlayerToDoScreen(
      {super.key, required this.players, required this.memberPresenceMap});

  @override
  PlayerToDoScreenState createState() => PlayerToDoScreenState();
}

class PlayerToDoScreenState extends State<PlayerToDoScreen>
    with SingleTickerProviderStateMixin {
  String currentFilter = 'all';

  void updateFilter(String newFilter) {
    setState(() {
      currentFilter = newFilter;
    });
  }

  @override
  Widget build(BuildContext context) {
    Map<String, String> filterOptions = {
      AppLocalizations.of(context)!.all: 'all',
      //'byEvent': 'byEvent',
    };

    final activePlayers = widget.players
        .where((player) => player.lastOnline
            .isAfter(DateTime.now().subtract(const Duration(days: 14))))
        .toList();

    final inactivePlayers = widget.players
        .where((player) => player.lastOnline
            .isBefore(DateTime.now().subtract(const Duration(days: 14))))
        .toList();

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            PlayerToDoHeader(
              players: activePlayers,
              memberPresenceMap: widget.memberPresenceMap,
            ),
            ScrollableTab(
                tabBarDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                ),
                labelColor: Theme.of(context).colorScheme.onSurface,
                labelPadding: EdgeInsets.zero,
                labelStyle: Theme.of(context).textTheme.bodyLarge,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
                onTap: (value) {
                  setState(() {});
                },
                tabs: [
                  Tab(text: AppLocalizations.of(context)!.activeAccounts),
                  Tab(text: AppLocalizations.of(context)!.inactiveAccounts),
                ],
                children: [
                  PlayerToDoBody(
                    players: activePlayers,
                    memberPresenceMap: widget.memberPresenceMap,
                    filterOptions: filterOptions,
                    active: true,
                  ),
                  PlayerToDoBody(
                    players: inactivePlayers,
                    memberPresenceMap: widget.memberPresenceMap,
                    filterOptions: filterOptions,
                    active: false,
                  ),
                ]),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
