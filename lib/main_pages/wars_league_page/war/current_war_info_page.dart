import 'package:flutter/material.dart';
import 'package:clashkingapp/classes/clan/war_league/current_war_info.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
  bool filterAccountActive = false;
  String filterBy = "all";

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    subTabController = TabController(length: 2, vsync: this);

    for (var member in widget.currentWarInfo.clan.members) {
      playerTab.add(
        PlayerTab(
            member.tag, member.name, member.townhallLevel, member.mapPosition),
      );
    }

    for (var member in widget.currentWarInfo.opponent.members) {
      playerTab.add(
        PlayerTab(
            member.tag, member.name, member.townhallLevel, member.mapPosition),
      );
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
              labelPadding: EdgeInsets.zero,
              labelStyle: Theme.of(context).textTheme.bodyLarge,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
              onTap: (value) {},
              tabs: [
                Tab(
                    text: AppLocalizations.of(context)?.statistics ??
                        'Statistics'),
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
                  child:
                      buildTeamsTab(context, discordUser: widget.discordUser),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(
                  filterBy == "all"
                      ? LucideIcons.list
                      : filterBy == "rattacks"
                          ? LucideIcons.swords
                          : LucideIcons.shield,
                  color: Theme.of(context).colorScheme.tertiary),
              onPressed: () {
                setState(() {
                  switch (filterBy) {
                    case "all":
                      filterBy = "rattacks";
                      break;
                    case "rattacks":
                      filterBy = "rdefenses";
                      break;
                    default:
                      filterBy = "all";
                  }
                });
              },
              tooltip: 'Filter Remaining Attacks',
            ),
            Stack(
              children: [
                CustomSlidingSegmentedControl<int>(
                  initialValue: _currentSegment,
                  children: {
                    1: Text(AppLocalizations.of(context)?.myTeam ?? 'My team'),
                    2: Text(
                        AppLocalizations.of(context)?.enemiesTeam ?? 'Enemies'),
                  },
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.tertiary.withOpacity(0.5),
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
              ],
            ),
            IconButton(
              icon: Icon(
                Icons.link,
                color: filterAccountActive ? Colors.green : Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  filterAccountActive = !filterAccountActive;
                });
              },
              tooltip: 'Filter Active Users',
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
            filterAccountActive,
            filterBy),
      ],
    );
  }

  Widget buildMemberListView(List<WarMember> members, BuildContext context,
      List<String> discordUser, bool filterActive, String filterBy) {
    List<WarMember> displayedMembers = filterActive
        ? members.where((member) => discordUser.contains(member.tag)).toList()
        : List.from(members);

    displayedMembers.sort((a, b) => a.mapPosition.compareTo(b.mapPosition));

    List<WarMember> filterMembers;

    switch (filterBy) {
      case "rattacks":
      filterMembers = displayedMembers.where((member) => (member.attacks != null && member.attacks!.length < 2)).toList();
      break;
      case "rdefenses":
      filterMembers = displayedMembers.where((member) => (member.bestOpponentAttack != null && member.bestOpponentAttack!.stars < 3)).toList();
      break;
      default:
      filterMembers = displayedMembers;

    }

    return WarTeamCard(
      playerTab: playerTab,
      widget: widget,
      members: filterMembers,
      discordUser: discordUser,
      filterActive: filterActive,
    );
  }
}
