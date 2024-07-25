import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legends_history/legend_eos_by_season_chart.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/classes/profile/profile_info.dart';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';
import 'package:intl/intl.dart';
import 'package:clashkingapp/classes/profile/legend/legend_data.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legend_header.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legends_by_day/legend_used_gear_card.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legends_by_day/legend_trophies_start_end_card.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legends_by_day/legend_offense_defense_card.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legends_history/legend_history_card.dart';
import 'package:clashkingapp/classes/profile/legend/legend_functions.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/classes/profile/legend/legend_day.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legends_by_season/legends_trophies_by_season_chart.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legends_by_season/legends_trophies_by_season_table.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legends_by_season/legends_stats_by_season.dart';

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
                      ? buildLegendTab(widget.playerLegendData)
                      : Center(
                          child: Text(
                              AppLocalizations.of(context)?.noDataAvailable ??
                                  'No data available')),
                  widget.playerLegendData.legendData.isNotEmpty
                      ? Column(children: [
                          SizedBox(height: 10),
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
                                  style:
                                      Theme.of(context).textTheme.labelLarge),
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
                          LegendsStatsBySeason(
                              playerLegendData: widget.playerLegendData,
                              selectedMonth: selectedMonth,
                              seasonData: seasonObject),
                          LegendsTrophiesBySeasonChart(
                            playerLegendData: widget.playerLegendData,
                            selectedMonth: selectedMonth,
                            seasonData: seasonObject,
                          ),
                          LegendsTrophiesBySeasonTable(
                            seasonObject: seasonObject,
                            playerLegendData: widget.playerLegendData,
                            selectedMonth: selectedMonth,
                            playerStats: widget.playerStats,
                          )
                        ])
                      : Center(
                          child: Text(
                              AppLocalizations.of(context)?.noDataAvailable ??
                                  'No data available')),
                  widget.playerLegendData.legendData.isNotEmpty
                      ? Column(
                          children: [
                            SizedBox(height: 10),
                            LegendEosBySeasonChart(
                                legendSeasons:
                                    widget.playerLegendData.legendSeasons),
                            LegendHistoryCard(
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

  Widget buildLegendTab(PlayerLegendData playerLegendData) {
    String date = DateFormat('yyyy-MM-dd').format(selectedDate);
    LegendDay? legendDay = playerLegendData.legendData[date];

    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(width: 16),
            IconButton(
              icon: Icon(Icons.calendar_today,
                  color: Theme.of(context).colorScheme.onSurface, size: 16),
              onPressed: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2018, 8),
                  lastDate: DateTime(2200),
                );
                if (picked != null && picked != selectedDate) {
                  setState(() {
                    selectedDate = picked;
                  });
                }
              },
            ),
            Spacer(),
            SizedBox(
              width: 30,
              height: 30,
              child: IconButton(
                icon: Icon(Icons.arrow_back,
                    color: Theme.of(context).colorScheme.onSurface, size: 16),
                onPressed: decrementDate,
              ),
            ),
            Text(
              DateFormat('dd MMMM yyyy',
                      Localizations.localeOf(context).languageCode)
                  .format(selectedDate),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            SizedBox(
              width: 30,
              height: 30,
              child: IconButton(
                icon: Icon(Icons.arrow_forward,
                    color: Theme.of(context).colorScheme.onSurface, size: 16),
                onPressed: incrementDate,
              ),
            ),
            SizedBox(width: 16)
          ],
        ),
        if (legendDay != null &&
            legendDay.attacksList.isNotEmpty &&
            legendDay.defensesList.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
            child: Column(
              children: [
                LegendTrophiesStartEndCard(
                    context: context,
                    startTrophies: legendDay.startTrophies.toString(),
                    currentTrophies: legendDay.currentTrophies),
                Container(
                  margin: EdgeInsets.only(top: 0, bottom: 0, left: 5, right: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: LegendOffenseDefenseCard(
                            title: AppLocalizations.of(context)?.attacks ??
                                "Attacks",
                            list: legendDay.attacksList,
                            context: context,
                            stats: legendDay.attacksStats,
                            plusMinus: "+",
                            icon:
                                "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Sword.png"),
                      ),
                      Expanded(
                        child: LegendOffenseDefenseCard(
                            title: AppLocalizations.of(context)?.defenses ??
                                "Defenses",
                            list: legendDay.defensesList,
                            context: context,
                            stats: legendDay.defensesStats,
                            plusMinus: "-",
                            icon:
                                "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Shield_Arrow.png"),
                      ),
                    ],
                  ),
                ),
                if (legendDay.attacksList.isNotEmpty)
                  LegendUsedGearCard(
                      context: context,
                      gearCounts: legendDay.gearCount,
                      heroes: widget.playerStats.heroes,
                      gears: widget.playerStats.equipments),
              ],
            ),
          )
        else
          Column(
            children: [
              Card(
                  margin: EdgeInsets.only(bottom: 8, left: 16, right: 16),
                  child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                          AppLocalizations.of(context)?.noDataAvailable ??
                              'No data available'))),
              SizedBox(height: 10),
              CachedNetworkImage(
                imageUrl:
                    'https://clashkingfiles.b-cdn.net/stickers/Villager_HV_Villager_7.png',
                height: 350,
                width: 200,
              )
            ],
          ),
      ],
    );
  }
}
