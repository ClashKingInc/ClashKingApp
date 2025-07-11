import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/clan/presentation/join_leave/clan_join_leave_events.dart';
import 'package:clashkingapp/features/clan/presentation/join_leave/clan_join_leave_header.dart';
import 'package:clashkingapp/features/clan/presentation/join_leave/clan_join_leave_stats.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';

class ClanJoinLeaveScreen extends StatefulWidget {
  final Clan clanInfo;

  ClanJoinLeaveScreen({super.key, required this.clanInfo});

  @override
  ClanJoinLeaveScreenState createState() => ClanJoinLeaveScreenState();
}

class ClanJoinLeaveScreenState extends State<ClanJoinLeaveScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  int selectedTab = 0;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                color: Theme.of(context).colorScheme.surface,
                child: ClanJoinLeaveHeader(clanInfo: widget.clanInfo),
              ),
              ScrollableTab(
                labelColor: Theme.of(context).colorScheme.onSurface,
                unselectedLabelColor: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
                tabBarDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                ),
                onTap: (index) {
                  setState(() {
                    selectedTab = index;
                  });
                },
                tabs: [
                  Tab(text: AppLocalizations.of(context)!.generalStats),
                  Tab(text: AppLocalizations.of(context)!.warEventsTitle),
                ],
                children: [
                  ClanJoinLeaveStats(joinLeaveClan: widget.clanInfo.joinLeave),
                  ClanJoinLeaveEvents(joinLeaveClan: widget.clanInfo.joinLeave),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
