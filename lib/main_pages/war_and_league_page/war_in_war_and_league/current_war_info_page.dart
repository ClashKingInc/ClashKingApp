import 'package:flutter/material.dart';
import 'package:clashkingapp/api/current_war_info.dart';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_in_war_and_league/component/war_header.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_in_war_and_league/component/war_statistics_card.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_in_war_and_league/component/war_events_card.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_in_war_and_league/component/war_team_card.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_in_war_and_league/component/war_calculator_card.dart';

class PlayerTab {
  String tag;
  String name;
  int townhallLevel;
  int mapPosition;

  PlayerTab(this.tag, this.name, this.townhallLevel, this.mapPosition);
}

class CurrentWarInfoScreen extends StatefulWidget {
  final CurrentWarInfo currentWarInfo;

  CurrentWarInfoScreen({super.key, required this.currentWarInfo});

  @override
  CurrentWarInfoScreenState createState() => CurrentWarInfoScreenState();
}

class CurrentWarInfoScreenState extends State<CurrentWarInfoScreen>
    with TickerProviderStateMixin {
  late TabController tabController;
  late TabController subTabController;
  List<PlayerTab> playerTab = [];
  int _currentSegment = 1;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    subTabController = TabController(length: 2, vsync: this);

    for (var member in widget.currentWarInfo.clan.members) {
      playerTab.add(PlayerTab(
          member.tag, member.name, member.townhallLevel, member.mapPosition));
    }

    for (var member in widget.currentWarInfo.opponent.members) {
      playerTab.add(PlayerTab(
          member.tag, member.name, member.townhallLevel, member.mapPosition));
    }
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
            child: Column(children: [
      WarHeader(widget: widget),
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
            Tab(text: AppLocalizations.of(context)?.statistics ?? 'Statistics'),
            Tab(text: AppLocalizations.of(context)?.events ?? 'Events'),
            Tab(text: AppLocalizations.of(context)?.team ?? 'Teams')
          ],
          children: [
            Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  children: [
                    WarStatisticsCard(currentWarInfo: widget.currentWarInfo),
                    SizedBox(height: 10),
                    WarCalculatorCard(teamSize: widget.currentWarInfo.teamSize)
                  ]
                )
            ),
            WarEventsCard(currentWarInfo: widget.currentWarInfo,  playerTab: playerTab),
            Padding(padding: EdgeInsets.all(8), child: buildTeamsTab(context)),
          ])
    ])));
  }

  Widget buildTeamsTab(BuildContext context) {
    return Column(
      children: [
        CustomSlidingSegmentedControl<int>(
          initialValue: _currentSegment,
          children: {
            1: Text(AppLocalizations.of(context)?.myTeam ?? 'My team'),
            2: Text(AppLocalizations.of(context)?.enemiesTeam ?? 'Enemies'),
          },
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          thumbDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.3),
                blurRadius: 4.0,
                spreadRadius: 1.0,
                offset: Offset(
                  0.0,
                  2.0,
                ),
              ),
            ],
          ),
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInToLinear,
          onValueChanged: (v) {
            setState(() {
              _currentSegment = v;
            });
          },
        ),
        SizedBox(height: 20),
        _currentSegment == 1
            ? buildMemberListView(widget.currentWarInfo.clan.members, context)
            : buildMemberListView(
                widget.currentWarInfo.opponent.members, context),
      ],
    );
  }

  Widget buildMemberListView(List<WarMember> members, BuildContext context) {
    return WarTeamCard(playerTab: playerTab, widget: widget, members: members);
  }
}
