import 'package:flutter/material.dart';
import 'package:clashkingapp/classes/profile/profile_info.dart';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';
import 'package:intl/intl.dart';
import 'package:clashkingapp/classes/profile/legend/legend_league.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legend_header.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legend_used_gear_card.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legend_trophies_start_end_card.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legend_offense_defense_card.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legend_history_card.dart';
import 'package:clashkingapp/classes/profile/legend/legend_functions.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  DateTime selectedMonth = DateTime.now()
      .toUtc()
      .subtract(Duration(hours: 5)); // Change month in history tab
  late PlayerLegendData legendData;
  late Future<List<dynamic>> seasonLegendData;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    selectedDate = DateTime.now().toUtc().subtract(Duration(hours: 5));
    selectedMonth = findCurrentSeasonMonth(
        DateTime.now().toUtc().subtract(Duration(hours: 5)));
    legendData = widget.playerLegendData;
    seasonLegendData =
        PlayerLegendSeasonsService.fetchSeasonsData(widget.playerStats.tag);
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
              LegendHeaderCard(widget: widget, legendData: legendData),
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
                  legendData.legendData.isNotEmpty
                      ? buildLegendTab(legendData)
                      : Center(
                          child: Text(
                              AppLocalizations.of(context)?.noDataAvailable ??
                                  'No data available')),
                  legendData.legendData.isNotEmpty
                      ? buildChartsStats(legendData, seasonLegendData)
                      : Center(
                          child: Text(
                              AppLocalizations.of(context)?.noDataAvailable ??
                                  'No data available')),
                  legendData.legendData.isNotEmpty
                      ? buildHistoryTab(seasonLegendData)
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
    List<Widget> legendEntries = [];

    String date = DateFormat('yyyy-MM-dd').format(selectedDate);

    if (playerLegendData.legendData.containsKey(date)) {
      LegendDay details = playerLegendData.legendData[date]!;

      String startTrophies = '0';
      String currentTrophies = "0";

      List<dynamic> attacksList =
          details.newAttacks.isNotEmpty ? details.newAttacks : details.attacks;
      List<dynamic> defensesList = details.newDefenses.isNotEmpty
          ? details.newDefenses
          : details.defenses;

      if (attacksList.isNotEmpty && defensesList.isNotEmpty) {
        var lastAttack = attacksList.last as Attack;
        var lastDefense = defensesList.last as Defense;
        currentTrophies = (lastAttack.time > lastDefense.time
            ? lastAttack.trophies.toString()
            : lastDefense.trophies.toString());

        var firstAttack = attacksList.first as Attack;
        var firstDefense = defensesList.first as Defense;
        startTrophies = (firstAttack.time < firstDefense.time
            ? (firstAttack.trophies - firstAttack.change).toString()
            : (firstDefense.trophies + firstDefense.change).toString());
      } else if (attacksList.isNotEmpty) {
        var lastAttack = attacksList.last as Attack;
        currentTrophies = lastAttack.trophies.toString();
        var firstAttack = attacksList.first as Attack;
        startTrophies = (firstAttack.trophies - firstAttack.change).toString();
      } else if (defensesList.isNotEmpty) {
        var lastDefense = defensesList.last as Defense;
        currentTrophies = lastDefense.trophies.toString();
        var firstDefense = defensesList.first as Defense;
        startTrophies =
            (firstDefense.trophies + firstDefense.change).toString();
      }

      Map<String, dynamic> attacksStats = calculateStats(attacksList);
      Map<String, dynamic> defensesStats = calculateStats(defensesList);

      legendEntries.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
          child: Column(
            children: [
              LegendTrophiesStartEndCard(
                  context: context,
                  startTrophies: startTrophies,
                  currentTrophies: currentTrophies),
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
                          list: attacksList,
                          context: context,
                          stats: attacksStats,
                          plusMinus: "+",
                          icon:
                              "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Sword.png"),
                    ),
                    Expanded(
                      child: LegendOffenseDefenseCard(
                          title: AppLocalizations.of(context)?.defenses ??
                              "Defenses",
                          list: defensesList,
                          context: context,
                          stats: defensesStats,
                          plusMinus: "-",
                          icon:
                              "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Shield_Arrow.png"),
                    ),
                  ],
                ),
              ),
              if (attacksList.isNotEmpty)
                LegendUsedGearCard(context: context, gearCounts: details.gearCount, heroes: widget.playerStats.heroes, gears: widget.playerStats.equipments),
            ],
          ),
        ),
      );
    }

    return Column(children: <Widget>[
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
      if (legendEntries.isEmpty)
        Column(children: [
          Card(
              margin: EdgeInsets.only(bottom: 8, left: 16, right: 16),
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(AppLocalizations.of(context)?.noDataAvailable ??
                      'No data available'))),
          SizedBox(height: 10),
          CachedNetworkImage(
            imageUrl:
                'https://clashkingfiles.b-cdn.net/stickers/Villager_HV_Villager_7.png',
            height: 350,
            width: 200,
          )
        ])
      else
        ...legendEntries
    ]);
  }

  Widget buildHistoryTab(Future<List<dynamic>> data) {
    return FutureBuilder<List<dynamic>>(
      future: data,
      builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: EdgeInsets.only(top: 200),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          List<dynamic> data = snapshot.data!;
          if (data.isEmpty) {
            return Center(
                child: Text(AppLocalizations.of(context)?.noDataAvailable ??
                    'No data available'));
          } else {
            return LegendHistoryCard(data: data);
          }
        }
      },
    );
  }

  Widget buildChartsStats(PlayerLegendData playerLegendData,
      Future<List<dynamic>> seasonLegendData) {
    return Column(children: [
      SizedBox(height: 10),
      buildTrophiesByMonthChart(playerLegendData.legendData),
      buildLegendHistoryChart(seasonLegendData)
    ]);
  }

  Widget buildTrophiesByMonthChart(Map<String, LegendDay> legendData) {
    Map<String, Map<String, String>> seasonTrophies = {};

    legendData.forEach((date, details) {
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
      String season = findSeasonStartDate(dateObj).toString();
      String day = DateFormat('dd').format(dateObj);

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
    String seasonKey = lastDayPreviousMonth.toString();

    Map<String, String> seasonData = seasonTrophies[seasonKey] ?? {};

    List<FlSpot> spots = convertToContinuousScale(seasonData, seasonStart);

    if (spots.isNotEmpty) {
      double minY = spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
      double maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
      double minX = spots.first.x;
      double maxX = spots.first.x + spots.length.toDouble() - 1;

      double rangeY = (maxY - minY) / 10;
      if (rangeY == 0) rangeY = 1;
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
                          interval: 3, // Display a label every 3 days
                          getTitlesWidget: (double value, TitleMeta meta) {
                            DateTime labelDate =
                                seasonStart.add(Duration(days: value.toInt()));
                            return Text(DateFormat('dd').format(labelDate),
                                style: TextStyle(fontSize: 10));
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: rangeY + 1,
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
                        spots: spots,
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
                    minX: minX,
                    maxX: maxX,
                    minY: minY,
                    maxY: maxY,
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
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
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
                    Text(
                      DateFormat('MMMM yyyy').format(selectedMonth),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
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

  Widget buildLegendHistoryChart(Future<List<dynamic>> seasonLegendData) {
    return FutureBuilder<List<dynamic>>(
      future: seasonLegendData,
      builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: EdgeInsets.only(top: 200),
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          List<dynamic> data = snapshot.data ?? [];
          if (data.isEmpty) {
            return SizedBox.shrink();
          } else {
            List<FlSpot> spots = data.map((item) {
              double y = item['trophies'].toDouble();
              double x = DateTime.parse(item['season'] + '-01')
                  .millisecondsSinceEpoch
                  .toDouble();
              return FlSpot(x, y); // Use the timestamp as x value
            }).toList();

            // Sort by the timestamp in ascending order (from the earliest date to the latest)
            spots.sort((a, b) => a.x.compareTo(b.x));

            if (spots.isNotEmpty) {
              // Calculate minY and maxY for dynamic scaling
              double minY =
                  spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
              double maxY =
                  spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
              minY = (minY / 10).floorToDouble() * 10;
              maxY = (maxY / 10).ceilToDouble() * 10;

              double minX = spots.first.x;
              double maxX = spots.last.x;
              double rangeY = (maxY - minY) / 10;
              if (rangeY == 0) rangeY = 1;

              return SizedBox(
                width: double.infinity,
                height: 500,
                child: Card(
                  margin:
                      EdgeInsets.only(top: 8, bottom: 8, left: 16, right: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
                    child: Column(children: [
                      Text(
                          AppLocalizations.of(context)?.eosTrophies ??
                              "EOS Trophies",
                          style: Theme.of(context).textTheme.bodyMedium),
                      SizedBox(height: 16),
                      Expanded(
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawHorizontalLine: true,
                              horizontalInterval: 30,
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  getTitlesWidget: (value, meta) {
                                    DateTime date =
                                        DateTime.fromMillisecondsSinceEpoch(
                                            value.toInt());
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 10.0),
                                      child: Text(
                                        DateFormat('M/yy').format(date),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  interval: rangeY + 1,
                                  getTitlesWidget:
                                      (double value, TitleMeta meta) {
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
                                spots: spots,
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
                            minX: minX,
                            maxX: maxX,
                            minY: minY,
                            maxY: maxY,
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
                    ]),
                  ),
                ),
              );
            } else {
              return SizedBox(
                width: double.infinity,
                height: 500,
                child: Card(
                  margin:
                      EdgeInsets.only(top: 8, bottom: 8, left: 16, right: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 10.0, right: 20.0, top: 20.0, bottom: 10.0),
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
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    size: 16),
                                onPressed: decrementMonth,
                              ),
                            ),
                            Text(
                              DateFormat('MMMM yyyy').format(selectedMonth),
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            SizedBox(
                              width: 30,
                              height: 30,
                              child: IconButton(
                                icon: Icon(Icons.arrow_forward,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
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
      },
    );
  }
}
