import 'package:flutter/material.dart';
import 'package:clashkingapp/api/player_account_info.dart';
import 'dart:ui';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';
import 'package:intl/intl.dart';
import 'package:clashkingapp/data/troop_data.dart';
import 'package:clashkingapp/api/player_legend.dart';
import 'package:fl_chart/fl_chart.dart';

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
  DateTime selectedDate = DateTime.now();
  DateTime selectedMonth = DateTime.now();
  Map<String, dynamic> dynamicLegendData = {};
  late Future<List<dynamic>> seasonLegendData;

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
              buildHeader(context, dynamicLegendData),
              ScrollableTab(
                labelColor: Colors.black,
                onTap: (value) {
                  print('Tab $value selected');
                  setState(() {});
                },
                tabs: [
                  Tab(text: "Today"),
                  Tab(text: "Charts"),
                  Tab(text: "History"),
                ],
                children: [
                  Container(
                    color: Theme.of(context).colorScheme.tertiary,
                    child: ListTile(
                      title: dynamicLegendData["legends"].isNotEmpty
                          ? buildLegendStats(dynamicLegendData)
                          : Center(child: Text('No data available')),
                    ),
                  ),
                  Container(
                    color: Theme.of(context).colorScheme.tertiary,
                    child: ListTile(
                      title: dynamicLegendData["legends"].isNotEmpty
                          ? buildChartsStats(
                              dynamicLegendData, seasonLegendData)
                          : Center(child: Text('No data available')),
                    ),
                  ),
                  Container(
                    color: Theme.of(context).colorScheme.tertiary,
                    child: ListTile(
                      title: dynamicLegendData["legends"].isNotEmpty
                          ? buildLegendHistoryStats(seasonLegendData)
                          : Center(child: Text('No data available')),
                    ),
                  )
                ],
              )
            ]))));
  }

  // Header of the page
  Stack buildHeader(
      BuildContext context, Map<String, dynamic> dynamicLegendData) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: <Widget>[
        SizedBox(
          height: 220,
          width: double.infinity,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
            child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.7),
                  BlendMode.darken,
                ),
                child: Image.network(
                  "https://clashkingfiles.b-cdn.net/landscape/legend-landscape.png",
                  width: double.infinity,
                  fit: BoxFit.cover,
                )),
          ),
        ),
        Positioned(
          top: 0,
          bottom: 0,
          left: 10,
          right: 10,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Center(
                  child: Container(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Text(
                          "${dynamicLegendData['name']}",
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                  ),
                        ),
                        Text("${dynamicLegendData['tag']}",
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: Colors.grey,
                                )),
                        SizedBox(height: 16),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                "https://clashkingfiles.b-cdn.net/icons/Icon_HV_League_Legend_3_Border.png",
                                width: 60,
                              ),
                              Text(widget.currentTrophies,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontSize: 32,
                                      )),
                              SizedBox(width: 8),
                              Column(children: [
                                Text(
                                  "(${widget.diffTrophies >= 0 ? '+' : ''}${widget.diffTrophies.toString()})",
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                          color: widget.diffTrophies >= 0
                                              ? Colors.green
                                              : Colors.red),
                                ),
                                SizedBox(height: 32),
                              ]),
                            ]),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                children: [
                                  Wrap(
                                    spacing: 16,
                                    runSpacing: 0,
                                    children: <Widget>[
                                      Chip(
                                        avatar: CircleAvatar(
                                            backgroundColor: Colors.transparent,
                                            child: Image.network(
                                                "https://clashkingfiles.b-cdn.net/country-flags/${dynamicLegendData['rankings']['country_code']!.toLowerCase() ?? 'uk'}.png")),
                                        label: Text(
                                          dynamicLegendData['rankings']
                                                      ['country_name'] ==
                                                  null
                                              ? 'No Country'
                                              : '${dynamicLegendData['rankings']['country_name']}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(color: Colors.white),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          side: BorderSide(
                                              color: Colors.white,
                                              width:
                                                  1), // Customize border color and width
                                        ),
                                      ),
                                      Chip(
                                        avatar: CircleAvatar(
                                            backgroundColor: Colors.transparent,
                                            child: Image.network(
                                                "https://clashkingfiles.b-cdn.net/country-flags/${dynamicLegendData['rankings']['country_code']!.toLowerCase() ?? 'uk'}.png")),
                                        label: Text(
                                          dynamicLegendData['rankings']
                                                      ['local_rank'] ==
                                                  null
                                              ? 'No rank'
                                              : '${dynamicLegendData['rankings']['local_rank']}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(color: Colors.white),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          side: BorderSide(
                                              color: Colors.white,
                                              width:
                                                  1), // Customize border color and width
                                        ),
                                      ),
                                      Chip(
                                        avatar: CircleAvatar(
                                            backgroundColor: Colors
                                                .transparent, // Set to a suitable color for your design.
                                            child: Image.network(
                                                "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Planet.png")
                                            // Using Container() as a fallback
                                            ),
                                        label: Text(
                                            dynamicLegendData['rankings']
                                                        ['local_rank'] ==
                                                    null
                                                ? 'No rank'
                                                : '${dynamicLegendData['rankings']['local_rank']}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(
                                                    color: Colors.white)),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          side: BorderSide(
                                              color: Colors.white,
                                              width:
                                                  1), // Customize border color and width
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
        ),
        Positioned(
          top: 20,
          left: 10,
          child: IconButton(
            icon: Icon(Icons.arrow_back,
                color: Theme.of(context).colorScheme.onPrimary, size: 32),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }

  Widget buildLegendStats(Map<String, dynamic> data) {
    List<Widget> legendEntries = [];
    Map<String, dynamic> legends = data['legends'];

    String date = DateFormat('yyyy-MM-dd').format(selectedDate);

    if (legends.containsKey(date)) {
      Map<String, dynamic> details = legends[date];

      String firstTrophies = '0';
      String currentTrophies = "0";

      List<dynamic> attacksList = details.containsKey('new_attacks')
          ? details['new_attacks']
          : details['attacks'] ?? [];
      List<dynamic> defensesList = details.containsKey('new_defenses')
          ? details['new_defenses']
          : details['defenses'] ?? [];

      if (attacksList.isNotEmpty && defensesList.isNotEmpty) {
        Map<String, dynamic> lastAttack = attacksList.last;
        Map<String, dynamic> lastDefense = defensesList.last;
        currentTrophies = (lastAttack['time'] > lastDefense['time']
                ? lastAttack['trophies'].toString()
                : lastDefense['trophies'])
            .toString();
        Map<String, dynamic> firstAttack = attacksList.first;
        Map<String, dynamic> firstDefense = defensesList.first;
        firstTrophies = (firstAttack['time'] < firstDefense['time']
                ? (firstAttack['trophies'] - firstAttack['change'])
                : (firstDefense['trophies']) + firstDefense['change'])
            .toString();
      } else if (attacksList.isNotEmpty) {
        Map<String, dynamic> lastAttack = attacksList.last;
        currentTrophies = lastAttack['trophies'].toString();
        Map<String, dynamic> firstAttack = attacksList.first;
        firstTrophies =
            (firstAttack['trophies'] - firstAttack['change']).toString();
      } else if (defensesList.isNotEmpty) {
        Map<String, dynamic> lastDefense = defensesList.last;
        currentTrophies = lastDefense['trophies'].toString();
        Map<String, dynamic> firstDefense = defensesList.first;
        firstTrophies =
            (firstDefense['trophies'] + firstDefense['change']).toString();
      }

      legendEntries.add(
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Card(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text("Started",
                              style: Theme.of(context).textTheme.titleSmall),
                          Text(firstTrophies,
                              style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                      Image.network(
                        "https://clashkingfiles.b-cdn.net/icons/Icon_HV_League_Legend_3_Border.png",
                        width: 80,
                      ),
                      Column(children: [
                        Text("Ended",
                            style: Theme.of(context).textTheme.titleSmall),
                        Text(currentTrophies,
                            style: Theme.of(context).textTheme.titleMedium),
                      ]),
                    ]),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child:
                        _buildOffenseSection("Offense", attacksList, context),
                  ),
                  Expanded(
                    child:
                        _buildDefenseSection("Defense", defensesList, context),
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

  Widget _buildOffenseSection(
      String title, List<dynamic> list, BuildContext context) {
    int sum = 0;
    if (list.isNotEmpty) {
      sum = list
          .whereType<Map>()
          .map((item) => item['change'])
          .reduce((value, element) => value + element);
    }
    int count = list.whereType<Map>().length +
        list.whereType<Map>().where((item) => item['change'] > 40).length;
    double average = sum / count;
    int remaining = 320 - count * 40;
    int bestPossibleTrophies = remaining + sum;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            Text(' (+$sum)', style: Theme.of(context).textTheme.labelLarge),
          ]),
          SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: Align(
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: list.map((item) {
                  if (item is Map) {
                    int change = item['change'];
                    int time = item['time'];
                    String timeAgo = _convertToTimeAgo(time);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.network(
                              "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Sword.png",
                              width: 20,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '+$change',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              " ($timeAgo)",
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ],
                    );
                  } else {
                    return Text("$item");
                  }
                }).toList(),
              ),
            ),
          ),
          SizedBox(height: 8),
          Text("Statistics", style: Theme.of(context).textTheme.bodyLarge),
          Text("Total: $count/8", style: Theme.of(context).textTheme.bodySmall),
          Text('Average: ${average.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall),
          Text('Remaining: +$remaining',
              style: Theme.of(context).textTheme.bodySmall),
          Text('Best : +$bestPossibleTrophies',
              style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
    );
  }

  Widget _buildDefenseSection(
      String title, List<dynamic> list, BuildContext context) {
    int sum = 0;
    if (list.isNotEmpty) {
      sum = list
          .whereType<Map>()
          .map((item) => item['change'])
          .reduce((value, element) => value + element);
    }
    int count = list.whereType<Map>().length +
        list.whereType<Map>().where((item) => item['change'] > 40).length;
    double average = sum / count;
    int remaining = 320 - count * 40;
    int bestPossibleTrophies = remaining + sum;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            Text(' (-$sum)', style: Theme.of(context).textTheme.labelLarge),
          ]),
          SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: Align(
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: list.map((item) {
                  if (item is Map) {
                    int change = item['change'];
                    int time = item['time'];
                    String timeAgo = _convertToTimeAgo(time);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.network(
                              "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Shield_Arrow.png",
                              width: 20,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '-$change',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              " ($timeAgo)",
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ],
                    );
                  } else {
                    return Text("$item");
                  }
                }).toList(),
              ),
            ),
          ),
          SizedBox(height: 8),
          Text("Statistics", style: Theme.of(context).textTheme.bodyLarge),
          Text("Total: $count/8", style: Theme.of(context).textTheme.bodySmall),
          Text('Average: ${average.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall),
          Text('Remaining: -$remaining',
              style: Theme.of(context).textTheme.bodySmall),
          Text('Worst : -$bestPossibleTrophies',
              style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
    );
  }

  Widget _buildGearSection(String title, List<dynamic> list) {
    Map<String, int> itemCounts = {};

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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                ...itemCounts.entries.map((entry) {
                  var gearData = troopUrlsAndTypes[entry.key];
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text("${entry.value}",
                          style: Theme.of(context).textTheme.bodyMedium),
                      gearData != null
                          ? Image.network(
                              gearData['url'] ??
                                  "https://clashkingfiles.b-cdn.net/clashkinglogo.png",
                              width: 24)
                          : Text("- ${entry.key}"),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _convertToTimeAgo(int timestamp) {
    DateTime now = DateTime.now();
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    Duration diff = now.difference(date);

    if (diff.inDays >= 1) {
      return '${diff.inDays} day${diff.inDays == 1 ? "" : "s"} ago';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours} hour${diff.inHours == 1 ? "" : "s"} ago';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes} minute${diff.inMinutes == 1 ? "" : "s"} ago';
    } else {
      return 'Just now';
    }
  }

  Widget buildLegendHistoryStats(Future<List<dynamic>> data) {
    return FutureBuilder<List<dynamic>>(
      future: data,
      builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          List<dynamic> data = snapshot.data!;
          return Column(
            children: data.map((item) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Column(
                            children: <Widget>[
                              SizedBox(
                                height: 90,
                                width: 80,
                                child: Stack(
                                  children: <Widget>[
                                    Center(
                                      child: Image.network(
                                        "https://clashkingfiles.b-cdn.net/icons/Icon_HV_League_Legend_3_No_Padding.png",
                                        height: 80,
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment(0, -0.1),
                                      child: Text(
                                        DateFormat('MMMM\nyyyy').format(
                                          DateTime(
                                            int.parse(
                                                item['season'].split('-')[0]),
                                            int.parse(
                                                item['season'].split('-')[1]),
                                          ),
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium!
                                            .copyWith(color: Colors.white),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text("${item['clan']['name']}",
                                  style:
                                      Theme.of(context).textTheme.labelMedium),
                            ],
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 4.0,
                                  runSpacing: 0.0,
                                  children: <Widget>[
                                    Chip(
                                        avatar: CircleAvatar(
                                            backgroundColor: Colors.transparent,
                                            child: Image.network(
                                                "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Trophy_Best.png")),
                                        label: Text('${item['trophies']}')),
                                    Chip(
                                        avatar: CircleAvatar(
                                            backgroundColor: Colors.transparent,
                                            child: Image.network(
                                                "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Planet.png")),
                                        label: Text('${item['rank']}')),
                                    Chip(
                                        avatar: CircleAvatar(
                                            backgroundColor: Colors.transparent,
                                            child: Image.network(
                                                "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Sword.png")),
                                        label: Text('${item['attackWins']}')),
                                    Chip(
                                        avatar: CircleAvatar(
                                            backgroundColor: Colors.transparent,
                                            child: Image.network(
                                                "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Shield.png")),
                                        label: Text('${item['defenseWins']}')),
                                  ],
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
            }).toList(),
          );
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
