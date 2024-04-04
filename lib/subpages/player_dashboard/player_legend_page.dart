import 'package:flutter/material.dart';
import 'package:clashkingapp/api/player_account_info.dart';
import 'dart:ui';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';
import 'package:intl/intl.dart';
import 'package:clashkingapp/data/troop_data.dart';
import 'package:clashkingapp/api/player_legend.dart';

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
  Map<String, dynamic> dynamicLegendData = {};
  late Future<List<dynamic>> seasonLegendData;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    selectedDate = DateTime.now();
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
                          ? buildLegendHistoryStats(seasonLegendData)
                          : Center(child: Text('No data available')),
                    ),
                  )
                ],
              )
            ]))));
  }

  // Header of the page
  Stack buildHeader(BuildContext context, Map<String, dynamic> dynamicLegendData) {
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
      }
      else if (attacksList.isNotEmpty) {
        Map<String, dynamic> lastAttack = attacksList.last;
        currentTrophies = lastAttack['trophies'].toString();
        Map<String, dynamic> firstAttack = attacksList.first;
        firstTrophies = (firstAttack['trophies'] - firstAttack['change'])
            .toString();
      }
      else if (defensesList.isNotEmpty) {
        Map<String, dynamic> lastDefense = defensesList.last;
        currentTrophies = lastDefense['trophies'].toString();
        Map<String, dynamic> firstDefense = defensesList.first;
        firstTrophies = (firstDefense['trophies'] + firstDefense['change'])
            .toString();
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
            height : 30,
            child: IconButton(
              icon: Icon(Icons.arrow_back,
                  color: Theme.of(context).colorScheme.onBackground, size : 16),
              onPressed: decrementDate,
            ),
          ),
          Text(
            DateFormat('dd MMMM yyyy').format(selectedDate),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          SizedBox(
            width: 30,
            height : 30,
            child: IconButton(
              icon: Icon(Icons.arrow_forward,
                  color: Theme.of(context).colorScheme.onBackground, size : 16),
              onPressed: incrementDate,
            ),
          ),
        ],
      ),
      if (legendEntries.isEmpty)
      Column(children: [
        SizedBox(height: 16),
        Card(child:Padding(padding: EdgeInsets.all(16), child:
        Text('Nothing to see here !'))),
        SizedBox(height: 16),
        Image.network(
          'https://clashkingfiles.b-cdn.net/stickers/Villager_HV_Villager_7.png',
          height: 350,
          width: 200,
        )])
      else
        ...legendEntries
    ]);
  }

  Widget _buildOffenseSection(
      String title, List<dynamic> list, BuildContext context) {
    int sum = list
        .whereType<Map>()
        .map((item) => item['change'])
        .reduce((value, element) => value + element);
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
}

/*
return Card(
                child: ListTile(
                  leading: SizedBox(
                            height: 100,
                            width: 100,
                            child: Stack(
                              children: <Widget>[
                                Image.network(
                                  "https://clashkingfiles.b-cdn.net/icons/Icon_HV_League_Legend_3.png",
                                ),
                                Positioned(
                                  right: 30,
                                  top: 32,
                                  child: Text(
                                    "${item['season']}",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall!
                                        .copyWith(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Season: ${item['season']}'),
                      Text('Trophies: ${item['trophies']}'),
                      Text('Attack Wins: ${item['attackWins']}'),
                      Text('Defense Wins: ${item['defenseWins']}'),
                      Text('Rank: ${item['rank']}'),
                      Text('Clan: ${item['clan']['name']}'),
                    ],
                  ),
                ),
              );
            }).toList(),
          );*/
