import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legends_history/legend_eos_by_season_chart.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/classes/profile/profile_info.dart';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';
import 'package:intl/intl.dart';
import 'package:clashkingapp/classes/profile/legend/legend_data.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legend_header.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legends_history/legend_history_card.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legends_history/legends_stats_history_card.dart';
import 'package:clashkingapp/classes/profile/legend/legend_functions.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legends_by_season/legends_trophies_by_season_chart.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legends_by_season/legends_trophies_by_season_table.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legends_by_season/legends_stats_by_season.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legends_by_day/legend_by_day_tab.dart';

class LegendScreen extends StatefulWidget {
  final ProfileInfo playerStats;
  final PlayerLegendData playerLegendData;

  LegendScreen(
      {super.key, required this.playerStats, required this.playerLegendData});

  @override
  LegendScreenState createState() => LegendScreenState();
}

class LegendScreenState extends State<LegendScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  DateTime selectedDate = DateTime.now().toUtc().subtract(Duration(hours: 5));
  DateTime selectedMonth = DateTime.now().toUtc().subtract(Duration(hours: 5));
  bool showBySeasonTable = false;
  bool showHistoryTable = false;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    selectedDate = DateTime.now().toUtc().subtract(Duration(hours: 5));
    selectedMonth = findCurrentSeasonMonth(
        DateTime.now().toUtc().subtract(Duration(hours: 5)));
    print(selectedMonth);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  void incrementDate() {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: 1));
    });
  }

  void decrementDate() {
    setState(() {
      selectedDate = selectedDate.subtract(Duration(days: 1));
    });
  }

  void incrementMonth() {
    setState(() {
      if (selectedMonth.month == 12) {
        selectedMonth = DateTime(selectedMonth.year + 1, 1, selectedMonth.day);
      } else {
        selectedMonth = DateTime(
            selectedMonth.year, selectedMonth.month + 1, selectedMonth.day);
      }
    });
  }

  void decrementMonth() {
    setState(() {
      if (selectedMonth.month == 1) {
        selectedMonth = DateTime(selectedMonth.year - 1, 12, selectedMonth.day);
      } else {
        selectedMonth = DateTime(
            selectedMonth.year, selectedMonth.month - 1, selectedMonth.day);
      }
    });
  }

  void toggleBySeasonView() {
    setState(() {
      showBySeasonTable = !showBySeasonTable;
    });
  }

  void toggleHistoryView() {
    setState(() {
      showHistoryTable = !showHistoryTable;
    });
  }

  @override
  Widget build(BuildContext context) {
    SeasonTrophies seasonObject =
        widget.playerLegendData.getTrophiesBySeason(selectedMonth);
    return Scaffold(
      body: RefreshIndicator(
        backgroundColor: Theme.of(context).colorScheme.surface,
        onRefresh: () {
          return Future.value();
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              LegendHeaderCard(
                  widget: widget, legendData: widget.playerLegendData),
              ScrollableTab(
                tabBarDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                ),
                labelColor: Theme.of(context).colorScheme.onSurface,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
                onTap: (value) {
                  setState(() {});
                },
                tabs: [
                  Tab(text: AppLocalizations.of(context)?.byDay ?? "By Day"),
                  Tab(
                      text: AppLocalizations.of(context)?.bySeason ??
                          "By season"),
                  Tab(text: AppLocalizations.of(context)?.history ?? "History"),
                ],
                children: [
                  widget.playerLegendData.legendData.isNotEmpty
                      ? LegendByDayTab(
                          playerLegendData: widget.playerLegendData,
                          playerStats: widget.playerStats)
                      : Center(
                          child: Text(
                              AppLocalizations.of(context)?.noDataAvailable ??
                                  'No data available')),
                  widget.playerLegendData.legendData.isNotEmpty
                      ? Column(children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(width: 16),
                                  IconButton(
                                    icon: Icon(
                                      showBySeasonTable
                                          ? Icons.bar_chart
                                          : Icons.table_chart,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      size: 24,
                                    ),
                                    onPressed: toggleBySeasonView,
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: IconButton(
                                      icon: Icon(Icons.arrow_back,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                          size: 16),
                                      onPressed: decrementMonth,
                                    ),
                                  ),
                                  Text(
                                      DateFormat(
                                              'MMMM yyyy',
                                              Localizations.localeOf(context)
                                                  .languageCode)
                                          .format(selectedMonth),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge),
                                  SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: IconButton(
                                      icon: Icon(Icons.arrow_forward,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                          size: 16),
                                      onPressed: incrementMonth,
                                    ),
                                  ),
                                  SizedBox(width: 16)
                                ],
                              ),
                            ],
                          ),
                          LegendsStatsBySeason(
                              playerLegendData: widget.playerLegendData,
                              selectedMonth: selectedMonth,
                              seasonData: seasonObject),
                          showBySeasonTable
                              ? LegendsTrophiesBySeasonTable(
                                  seasonObject: seasonObject,
                                  playerLegendData: widget.playerLegendData,
                                  selectedMonth: selectedMonth,
                                  playerStats: widget.playerStats,
                                )
                              : LegendsTrophiesBySeasonChart(
                                  playerLegendData: widget.playerLegendData,
                                  selectedMonth: selectedMonth,
                                  seasonData: seasonObject,
                                ),
                        ])
                      : Center(
                          child: Text(
                              AppLocalizations.of(context)?.noDataAvailable ??
                                  'No data available')),
                  widget.playerLegendData.legendData.isNotEmpty
                      ? Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SizedBox(width: 16),
                                IconButton(
                                  icon: Icon(
                                    showBySeasonTable
                                        ? Icons.bar_chart
                                        : Icons.table_chart,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    size: 24,
                                  ),
                                  onPressed: toggleHistoryView,
                                ),
                              ],
                            ),
                            LegendStatsHistoryCard(
                                legendSeasons:
                                    widget.playerLegendData.legendSeasons),
                            showHistoryTable
                                ? LegendHistoryCard(
                                    legendSeasons:
                                        widget.playerLegendData.legendSeasons)
                                : LegendEosBySeasonChart(
                                    legendSeasons:
                                        widget.playerLegendData.legendSeasons),
                          ],
                        )
                      : Center(
                          child: Text(
                              AppLocalizations.of(context)?.noDataAvailable ??
                                  'No data available')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
