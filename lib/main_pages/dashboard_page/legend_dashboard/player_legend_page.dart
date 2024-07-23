import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legend_history_chart.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/classes/profile/profile_info.dart';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';
import 'package:intl/intl.dart';
import 'package:clashkingapp/classes/profile/legend/legend_data.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legend_header.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legend_used_gear_card.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legend_trophies_start_end_card.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legend_offense_defense_card.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legend_history_card.dart';
import 'package:clashkingapp/classes/profile/legend/legend_functions.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/classes/profile/legend/legend_attack.dart';
import 'package:clashkingapp/classes/profile/legend/legend_defense.dart';
import 'package:clashkingapp/classes/profile/legend/legend_day.dart';
import 'package:clashkingapp/classes/profile/legend/spot_data.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legend_monthly_chart.dart';

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
                  Tab(text: AppLocalizations.of(context)?.charts ?? "Charts"),
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
                          //buildTrophiesByMonthChart(),
                          LegendMonthlyChart(
                              playerLegendData: widget.playerLegendData),
                          LegendHistoryChart(
                              legendSeasons:
                                  widget.playerLegendData.legendSeasons)
                        ])
                      : Center(
                          child: Text(
                              AppLocalizations.of(context)?.noDataAvailable ??
                                  'No data available')),
                  widget.playerLegendData.legendData.isNotEmpty
                      ? LegendHistoryCard(
                          data: widget.playerLegendData.legendSeasons)
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

  Widget buildTrophiesByMonthChart() {
    Map<String, Map<String, String>> seasonTrophies = {};

    widget.playerStats.playerLegendData!.legendData.forEach((date, details) {
      String dailyTrophies = "0";

      List<Attack> attacksList = details.newAttacks.isNotEmpty
          ? details.newAttacks
          : details.attacks
              .map((value) =>
                  Attack(change: value, time: 0, trophies: 0, heroGear: []))
              .toList();

      List<Defense> defensesList = details.newDefenses.isNotEmpty
          ? details.newDefenses
          : details.defenses
              .map((value) => Defense(change: value, time: 0, trophies: 0))
              .toList();

      if (attacksList.isNotEmpty && defensesList.isNotEmpty) {
        var lastAttack = attacksList.last;
        var lastDefense = defensesList.last;
        dailyTrophies = (lastAttack.time > lastDefense.time
                ? lastAttack.trophies
                : lastDefense.trophies)
            .toString();
      } else if (attacksList.isNotEmpty) {
        var lastAttack = attacksList.last;
        dailyTrophies = lastAttack.trophies.toString();
      } else if (defensesList.isNotEmpty) {
        var lastDefense = defensesList.last;
        dailyTrophies = lastDefense.trophies.toString();
      }

      DateTime dateObj = DateTime.parse(date);
      String season =
          DateFormat('yyyy-MM-dd').format(findSeasonStartDate(dateObj));
      String day = DateFormat('MM-dd').format(dateObj);

      if (!seasonTrophies.containsKey(season)) {
        seasonTrophies[season] = {};
      }
      seasonTrophies[season]![day] = dailyTrophies;
    });

    DateTime firstDaySelectedMonth =
        DateTime(selectedMonth.year, selectedMonth.month, 1);
    DateTime lastDayPreviousMonth =
        firstDaySelectedMonth.subtract(Duration(days: 1));

    while (lastDayPreviousMonth.weekday != DateTime.monday) {
      lastDayPreviousMonth = lastDayPreviousMonth.subtract(Duration(days: 1));
    }

    DateTime seasonStart = lastDayPreviousMonth;
    String seasonKey = DateFormat('yyyy-MM-dd').format(seasonStart);

    Map<String, String> seasonData = seasonTrophies[seasonKey] ?? {};

    if (seasonData.isNotEmpty) {
      ChartData chartData =
          ChartData.fromSeasonTrophies(seasonData, seasonStart);

      print("spotsbuild ${chartData.spots}");
      print("minXbuild ${chartData.minX}");
      print("maxXbuild ${chartData.maxX}");

      return SizedBox(
        width: double.infinity,
        height: 500,
        child: Card(
          margin: EdgeInsets.only(top: 8, bottom: 8, left: 16, right: 16),
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.only(
                left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
            child: Column(children: [
              Text(
                  AppLocalizations.of(context)?.trophiesByMonth ??
                      "Trophies by Month",
                  style: Theme.of(context).textTheme.bodyMedium),
              SizedBox(height: 16),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      horizontalInterval: 20,
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 3, // Display a label every day
                          getTitlesWidget: (double value, TitleMeta meta) {
                            DateTime labelDate =
                                seasonStart.add(Duration(days: value.toInt()));
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(DateFormat('dd').format(labelDate),
                                  style: TextStyle(fontSize: 10)),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: chartData.rangeY + 1,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            return Text('${value.toInt()}');
                          },
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: chartData.spots,
                        color: Theme.of(context).colorScheme.primary,
                        isCurved: true,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.2),
                        ),
                      ),
                    ],
                    minX: chartData.minX,
                    maxX: chartData.maxX,
                    minY: chartData.minY,
                    maxY: chartData.maxY,
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (spot) => Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.8),
                      ),
                      touchCallback: (FlTouchEvent touchEvent,
                          LineTouchResponse? touchResponse) {},
                      handleBuiltInTouches: true,
                    ),
                  ),
                  duration: Duration(milliseconds: 250),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 16),
                      onPressed: decrementMonth,
                    ),
                  ),
                  Text(
                      DateFormat('MMMM yyyy',
                              Localizations.localeOf(context).languageCode)
                          .format(selectedMonth),
                      style: Theme.of(context).textTheme.labelLarge),
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: IconButton(
                      icon: Icon(Icons.arrow_forward,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 16),
                      onPressed: incrementMonth,
                    ),
                  ),
                ],
              ),
            ]),
          ),
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity,
        height: 500,
        child: Card(
          margin: EdgeInsets.only(top: 8, bottom: 8, left: 16, right: 16),
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.only(
                left: 10.0, right: 10.0, top: 20.0, bottom: 10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    AppLocalizations.of(context)?.noDataAvailable ??
                        'No data available',
                    style: Theme.of(context).textTheme.bodyMedium),
                CachedNetworkImage(
                  imageUrl:
                      'https://clashkingfiles.b-cdn.net/stickers/Villager_HV_Villager_12.png',
                  height: 300,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: 16),
                        onPressed: decrementMonth,
                      ),
                    ),
                    Text(DateFormat('MMMM yyyy').format(selectedMonth),
                        style: Theme.of(context).textTheme.labelLarge),
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: IconButton(
                        icon: Icon(Icons.arrow_forward,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: 16),
                        onPressed: incrementMonth,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
