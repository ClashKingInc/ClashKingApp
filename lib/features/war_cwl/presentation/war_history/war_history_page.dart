import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war_history/component/war_history_header.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war_history/component/war_log_history_stats_tab.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war_history/component/war_log_history_tab.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';

class WarHistoryScreen extends StatefulWidget {
  final Clan clan;

  WarHistoryScreen({super.key, required this.clan});

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
            WarHistoryHeader(clan: widget.clan),
            ScrollableTab(
              tabBarDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              ),
              labelColor: Theme.of(context).colorScheme.onSurface,
              labelPadding: EdgeInsets.zero,
              labelStyle: Theme.of(context).textTheme.bodyLarge,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
              tabs: [
                Tab(text: AppLocalizations.of(context)?.warLog ?? 'War Log'),
                Tab(
                    text: AppLocalizations.of(context)?.statistics ??
                        'Statistics'),
              ],
              children: [
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Column(
                    children: [
                      WarLogHistoryTab(clan: widget.clan),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Column(
                    children: [
                      WarLogHistoryStats(
                        clan: widget.clan,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
