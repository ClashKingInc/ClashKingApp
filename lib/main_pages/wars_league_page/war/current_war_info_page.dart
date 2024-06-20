import 'package:flutter/material.dart';
import 'package:clashkingapp/classes/clan/war_league/current_war_info.dart';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war/component/war_header.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war/component/war_statistics_card.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war/component/war_events_card.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war/component/war_team_card.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war/component/war_calculator_card.dart';

class PlayerTab {
  String tag;
  String name;
  int townhallLevel;
  int mapPosition;

  PlayerTab(this.tag, this.name, this.townhallLevel, this.mapPosition);
}

class CurrentWarInfoScreen extends StatefulWidget {
  final CurrentWarInfo currentWarInfo;
  final List<String> discordUser;

  CurrentWarInfoScreen(
      {super.key, required this.currentWarInfo, required this.discordUser});

  @override
  CurrentWarInfoScreenState createState() => CurrentWarInfoScreenState();
}

class CurrentWarInfoScreenState extends State<CurrentWarInfoScreen>
    with TickerProviderStateMixin {
  late TabController tabController;
  late TabController subTabController;
  List<PlayerTab> playerTab = [];
  int _currentSegment = 1;
  bool filterActive = false;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    subTabController = TabController(length: 2, vsync: this);

    for (var member in widget.currentWarInfo.clan.members) {
      playerTab.add(PlayerTab(member.tag, member.name, member.townhallLevel, member.mapPosition),);
    }

    for (var member in widget.currentWarInfo.opponent.members) {
      playerTab.add(PlayerTab(member.tag, member.name, member.townhallLevel, member.mapPosition),);
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
        child: Column(
          children: [
            WarHeader(widget: widget),
            ScrollableTab(
              tabBarDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              ),
              labelColor: Theme.of(context).colorScheme.onSurface,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
              onTap: (value) {},
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
                      WarCalculatorCard(currentWarInfo: widget.currentWarInfo)
                    ],
                  ),
                ),
                WarEventsCard(
                  currentWarInfo: widget.currentWarInfo,
                  playerTab: playerTab,
                  discordUser: widget.discordUser,
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: buildTeamsTab(context,
                  discordUser: widget.discordUser),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTeamsTab(BuildContext context, {List<String>? discordUser}) {
    return Column(
      children: [
        Stack(
          children: [
            Center(
              child: CustomSlidingSegmentedControl<int>(
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
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4.0,
                      spreadRadius: 1.0,
                      offset: Offset(0.0, 2.0),
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
            ),
            Positioned(
              top: -4,
              right: 12,
              child: IconButton(
                icon: Icon(
                  Icons.link,
                  color: filterActive ? Colors.green : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    filterActive = !filterActive;
                  });
                },
                tooltip: 'Filter Active Users',
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        buildMemberListView(
          _currentSegment == 1
            ? widget.currentWarInfo.clan.members
            : widget.currentWarInfo.opponent.members,
          context,
          widget.discordUser,
          filterActive,
        ),
      ],
    );
  }

  Widget buildMemberListView(List<WarMember> members, BuildContext context, List<String> discordUser, bool filterActive) {
    List<WarMember> displayedMembers = filterActive
      ? members.where((member) => discordUser.contains(member.tag)).toList()
      : List.from(members);

    displayedMembers.sort((a, b) => a.mapPosition.compareTo(b.mapPosition));

    return WarTeamCard(
      playerTab: playerTab,
      widget: widget,
      members: displayedMembers,
      discordUser: discordUser,
      filterActive: filterActive,
    );
  }
}
