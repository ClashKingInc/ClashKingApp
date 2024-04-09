import 'package:flutter/material.dart';
import 'package:clashkingapp/api/player_account_info.dart';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';
import 'package:intl/intl.dart';
import 'package:clashkingapp/api/player_legend.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legend_header_card.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legend_used_gear_card.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legend_trophies_start_end_card.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legend_offense_defense_card.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legend_history_card.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/legend_functions.dart';

class LegendScreen extends StatefulWidget {
  final PlayerAccountInfo playerStats;
  final Map<String, dynamic> legendData;
  final int diffTrophies;
  final String currentTrophies;
  final String firstTrophies;
  final List<dynamic> attacksList;
  final List<dynamic> defensesList;

  LegendScreen(
      {super.key,
      required this.playerStats,
      required this.legendData,
      required this.diffTrophies,
      required this.currentTrophies,
      required this.firstTrophies,
      required this.attacksList,
      required this.defensesList});

  @override
  LegendScreenState createState() => LegendScreenState();
}

class LegendScreenState extends State<LegendScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  DateTime selectedDate = DateTime.now(); // Change date in legend tab
  DateTime selectedMonth = DateTime.now(); // Change month in history tab
  Map<String, dynamic> dynamicLegendData =
      {}; // Legend days details (result of API fetchLegendData))
  late Future<List<dynamic>> seasonLegendData; // List of EOS trophies

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    selectedDate = DateTime.now();
    selectedMonth = DateTime.now();
    dynamicLegendData = widget.legendData;
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
            onRefresh: () {
              return PlayerLegendService.fetchLegendData(widget.playerStats.tag)
                  .then((data) {
                setState(() {
                  dynamicLegendData = data;
                });
              });
            },
            child: SingleChildScrollView(
                child: Column(children: [
              LegendHeaderCard(
                  widget: widget, dynamicLegendData: dynamicLegendData),
              ScrollableTab(
                tabBarDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              ),
                labelColor: Theme.of(context).colorScheme.onBackground,
                unselectedLabelColor:
                    Theme.of(context).colorScheme.onBackground,
                onTap: (value) {
                  setState(() {});
                },
                tabs: [
                  Tab(
                      text:
                          "By day"), // Show Attacks, Defenses and Gear for the selected day
                  Tab(
                      text:
                          "Charts"), // Show charts of Trophies by month and EOS history
                  Tab(text: "History"), // Show EOS history
                ],
                children: [
                  ListTile(
                    title: dynamicLegendData["legends"].isNotEmpty
                        ? buildLegendTab(dynamicLegendData)
                        : Center(child: Text('No data available')),
                  ),
                  ListTile(
                    title: dynamicLegendData["legends"].isNotEmpty
                        ? buildChartsStats(dynamicLegendData, seasonLegendData)
                        : Center(child: Text('No data available')),
                  ),
                  ListTile(
                    title: dynamicLegendData["legends"].isNotEmpty
                        ? buildHistoryTab(seasonLegendData)
                        : Center(child: Text('No data available')),
                  ),
                ],
              )
            ]))));
  }

  Widget buildLegendTab(Map<String, dynamic> data) {
    List<Widget> legendEntries =
        []; // List of widgets to display in the legend tab
    Map<String, dynamic> legends =
        data['legends']; // Legend days details (attacks, defenses, gears)

    String date = DateFormat('yyyy-MM-dd').format(selectedDate);

    if (legends.containsKey(date)) {
      Map<String, dynamic> details = legends[
          date]; // Details of the selected day (attacks, defenses, gears)

      String startTrophies = '0';
      String currentTrophies = "0";

      // Extract the attacks and defenses list. The JSON structure has changed over time
      // so we need to check if the new_attacks and new_defenses keys are present
      // otherwise we fallback to the attacks and defenses keys (old structure)
      List<dynamic> attacksList = details.containsKey('new_attacks')
          ? details['new_attacks']
          : details['attacks'] ?? [];
      List<dynamic> defensesList = details.containsKey('new_defenses')
          ? details['new_defenses']
          : details['defenses'] ?? [];

      // Calculate the trophies at the beginning of day and at the end or current time if day not over
      // Adapt depending on if the day has attacks, defenses or both
      if (attacksList.isNotEmpty && defensesList.isNotEmpty) {
        Map<String, dynamic> lastAttack = attacksList.last;
        Map<String, dynamic> lastDefense = defensesList.last;
        currentTrophies = (lastAttack['time'] > lastDefense['time']
                ? lastAttack['trophies'].toString()
                : lastDefense['trophies'])
            .toString();
        Map<String, dynamic> firstAttack = attacksList.first;
        Map<String, dynamic> firstDefense = defensesList.first;
        startTrophies = (firstAttack['time'] < firstDefense['time']
                ? (firstAttack['trophies'] - firstAttack['change'])
                : (firstDefense['trophies']) + firstDefense['change'])
            .toString();
      } else if (attacksList.isNotEmpty) {
        Map<String, dynamic> lastAttack = attacksList.last;
        currentTrophies = lastAttack['trophies'].toString();
        Map<String, dynamic> firstAttack = attacksList.first;
        startTrophies =
            (firstAttack['trophies'] - firstAttack['change']).toString();
      } else if (defensesList.isNotEmpty) {
        Map<String, dynamic> lastDefense = defensesList.last;
        currentTrophies = lastDefense['trophies'].toString();
        Map<String, dynamic> firstDefense = defensesList.first;
        startTrophies =
            (firstDefense['trophies'] + firstDefense['change']).toString();
      }

      Map<String, dynamic> attacksStats = calculateStats(attacksList);
      Map<String, dynamic> defensesStats = calculateStats(defensesList);

      legendEntries.add(
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Display the first card with start and end trophies of the day
              LegendTrophiesStartEndCard(
                  context: context,
                  startTrophies: startTrophies,
                  currentTrophies: currentTrophies),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: LegendOffenseDefenseCard(
                        title: "Offense",
                        list: attacksList,
                        context: context,
                        stats: attacksStats,
                        plusMinus: "+",
                        icon:
                            "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Sword.png"),
                  ),
                  Expanded(
                    child: LegendOffenseDefenseCard(
                        title: "Defense",
                        list: defensesList,
                        context: context,
                        stats: defensesStats,
                        plusMinus: "-",
                        icon:
                            "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Shield_Arrow.png"),
                  ),
                ],
              ),
              _buildGearSection("Heroes Gears", attacksList),
            ],
          ),
        ),
      );
    }

    return Column(children: <Widget>[
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: IconButton(
              icon: Icon(Icons.arrow_back,
                  color: Theme.of(context).colorScheme.onBackground, size: 16),
              onPressed: decrementDate,
            ),
          ),
          Text(
            DateFormat('dd MMMM yyyy').format(selectedDate),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          SizedBox(
            width: 30,
            height: 30,
            child: IconButton(
              icon: Icon(Icons.arrow_forward,
                  color: Theme.of(context).colorScheme.onBackground, size: 16),
              onPressed: incrementDate,
            ),
          ),
        ],
      ),
      if (legendEntries.isEmpty)
        Column(children: [
          SizedBox(height: 16),
          Card(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Nothing to see here !'))),
          SizedBox(height: 16),
          Image.network(
            'https://clashkingfiles.b-cdn.net/stickers/Villager_HV_Villager_7.png',
            height: 350,
            width: 200,
          )
        ])
      else
        ...legendEntries
    ]);
  }

  Widget _buildGearSection(String title, List<dynamic> list) {
    Map<String, int> itemCounts = {};

    // Count the number of time each gear was used (attacks only)
    for (var item in list) {
      if (item is Map) {
        List<dynamic> heroGear = item['hero_gear'] ?? [];
        for (var gear in heroGear) {
          String gearName = gear['name'];
          if (itemCounts.containsKey(gearName)) {
            if (itemCounts.containsKey(gearName)) {
              itemCounts.update(gearName, (value) => value + 1,
                  ifAbsent: () => 1);
            } else {
              itemCounts[gearName] = 1;
            }
          } else {
            itemCounts[gearName] = 1;
          }
        }
      }
    }

    return LegendUsedGearCard(context: context, itemCounts: itemCounts);
  }

  Widget buildHistoryTab(Future<List<dynamic>> data) {
    return FutureBuilder<List<dynamic>>(
      future: data,
      builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          List<dynamic> data = snapshot.data!;
          return LegendHistoryCard(data: data);
        }
      },
    );
  }

  Widget buildChartsStats(
      Map<String, dynamic> legendData, Future<List<dynamic>> seasonLegendData) {
    return Column(children: [
      buildTrophiesByMonthChart(legendData),
      buildLegendHistoryChart(seasonLegendData)
    ]);
  }

  Widget buildTrophiesByMonthChart(Map<String, dynamic> legendData) {
    Map<String, Map<String, String>> monthlyTrophies = {};
    Map<String, dynamic> legends = legendData['legends'];

    legends.forEach((date, details) {
      String currentTrophies = "0";
      List<dynamic> attacksList = details['new_attacks'] ?? [];
      List<dynamic> defensesList = details['new_defenses'] ?? [];

      if (attacksList.isNotEmpty && defensesList.isNotEmpty) {
        var lastAttack = attacksList.last;
        var lastDefense = defensesList.last;
        currentTrophies = (lastAttack['time'] > lastDefense['time']
                ? lastAttack['trophies']
                : lastDefense['trophies'])
            .toString();
      } else if (attacksList.isNotEmpty) {
        var lastAttack = attacksList.last;
        currentTrophies = lastAttack['trophies'].toString();
      } else if (defensesList.isNotEmpty) {
        var lastDefense = defensesList.last;
        currentTrophies = lastDefense['trophies'].toString();
      }

      String month = DateFormat('yyyy-MM').format(DateTime.parse(date));
      String day = DateFormat('dd').format(DateTime.parse(date));

      if (!monthlyTrophies.containsKey(month)) {
        monthlyTrophies[month] = {};
      }
      monthlyTrophies[month]![day] = currentTrophies;
    });

    // Extract the data for the given month
    String month = DateFormat('yyyy-MM').format(selectedMonth);
    Map<String, String> monthData = monthlyTrophies[month] ?? {};

    // Convert the data to a format that the chart can use
    List<FlSpot> spots = monthData.entries.map((entry) {
      return FlSpot(double.parse(entry.key), double.parse(entry.value));
    }).toList();

    // Sort the spots based on the day to ensure the graph is in order
    spots.sort((a, b) => a.x.compareTo(b.x));

    if (spots.isNotEmpty) {
      // Calculate minY and maxY for dynamic scaling
      double minY = spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
      double maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
      minY = (minY / 10).floorToDouble() * 10;
      maxY = (maxY / 10).ceilToDouble() * 10;
      double minX = spots.map((spot) => spot.x).reduce((a, b) => a < b ? a : b);
      double maxX = spots.map((spot) => spot.x).reduce((a, b) => a > b ? a : b);

      double rangeY = (maxY - minY) / 10;
      if (rangeY == 0) rangeY = 1;

      return SizedBox(
        width: double.infinity,
        height: 500,
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.only(
                left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
            child: Column(children: [
              Text("Trophies by month",
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
                          interval: 5,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Text('${value.toInt()}'),
                            );
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
                          color: Theme.of(context).colorScheme.secondary,
                          width: 1),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        color: Theme.of(context).colorScheme.secondary,
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
                          color: Theme.of(context).colorScheme.onBackground,
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
                          color: Theme.of(context).colorScheme.onBackground,
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
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.only(
                left: 10.0, right: 20.0, top: 20.0, bottom: 10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("No data for this Month",
                    style: Theme.of(context).textTheme.bodyMedium),
                Image.network(
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
                            color: Theme.of(context).colorScheme.onBackground,
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
                            color: Theme.of(context).colorScheme.onBackground,
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
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          List<dynamic> data = snapshot.data ?? [];
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
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
                  child: Column(children: [
                    Text("EOS Trophies",
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
                                color: Theme.of(context).colorScheme.secondary,
                                width: 1),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              color: Theme.of(context).colorScheme.secondary,
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
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 10.0, right: 20.0, top: 20.0, bottom: 10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("No data for this Month",
                          style: Theme.of(context).textTheme.bodyMedium),
                      Image.network(
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
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground,
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
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground,
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
      },
    );
  }
}
