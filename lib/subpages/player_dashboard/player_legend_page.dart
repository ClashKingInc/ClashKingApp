import 'package:flutter/material.dart';
import 'package:clashkingapp/api/player_account_info.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';
import 'package:intl/intl.dart';
import 'package:clashkingapp/data/troop_data.dart';

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

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
            child: Column(children: [
      buildHeader(context),
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
              title: widget.legendData["legends"].isNotEmpty
                  ? buildLegendStats(widget.legendData)
                  : Center(child: Text('No data available')),
            ),
          ),
          Container(
            color: Theme.of(context).colorScheme.tertiary,
            constraints: BoxConstraints.expand(
                width: double.infinity, height: double.infinity),
            child: ListTile(title: buildLegendStats(widget.legendData)),
          )
        ],
      )
    ])));
  }

  Stack buildHeader(BuildContext context) {
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
                          "${widget.legendData['name']}",
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                  ),
                        ),
                        Text("${widget.legendData['tag']}",
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
                                                "https://clashkingfiles.b-cdn.net/country-flags/${widget.legendData['rankings']['country_code']!.toLowerCase() ?? 'uk'}.png")),
                                        label: Text(
                                          widget.legendData['rankings']
                                                      ['country_name'] ==
                                                  null
                                              ? 'No Country'
                                              : '${widget.legendData['rankings']['country_name']}',
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
                                                "https://clashkingfiles.b-cdn.net/country-flags/${widget.legendData['rankings']['country_code']!.toLowerCase() ?? 'uk'}.png")),
                                        label: Text(
                                          widget.legendData['rankings']
                                                      ['local_rank'] ==
                                                  null
                                              ? 'No rank'
                                              : '${widget.legendData['rankings']['local_rank']}',
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
                                            widget.legendData['rankings']
                                                        ['local_rank'] ==
                                                    null
                                                ? 'No rank'
                                                : '${widget.legendData['rankings']['local_rank']}',
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
                        Text("Current",
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

    return Column(children: legendEntries);
  }

  Widget _buildOffenseSection(
      String title, List<dynamic> list, BuildContext context) {
    int sum = list
        .whereType<Map>()
        .map((item) => item['change'])
        .reduce((value, element) => value + element);
    int count = list.whereType<Map>().length;
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
          Text('Average: $average',
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
    int sum = list
        .whereType<Map>()
        .map((item) => item['change'])
        .reduce((value, element) => value + element);
    int count = list.whereType<Map>().length;
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
          Text('Average: $average',
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

  Widget buildLegendHistoryStats(Map<String, dynamic> data) {
    List<Widget> cards = [];

    data.forEach((date, details) {
      List<Widget> attacks = details['attacks'] != null
          ? (details['attacks'] as List)
              .map((attack) => ListTile(
                    leading: Icon(LucideIcons.sword,
                        color: Colors.red), // Replace with appropriate icon
                    title: Text('+${attack.toString()}'),
                    subtitle: Text('unknown'), // Replace with actual time
                  ))
              .toList()
          : [Text('No attacks')];

      List<Widget> defenses = details['defenses'] != null
          ? (details['defenses'] as List)
              .map((defense) => ListTile(
                    leading: Icon(Icons.shield,
                        color: Colors.green), // Replace with appropriate icon
                    title: Text(defense.toString()),
                    subtitle: Text('unknown'), // Replace with actual time
                  ))
              .toList()
          : [Text('No defenses')];

      cards.add(
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Offense',
                          style: Theme.of(context).textTheme.titleMedium),
                      ...attacks,
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Defense',
                          style: Theme.of(context).textTheme.titleMedium),
                      ...defenses,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });

    return ListView(
      children: cards,
    );
  }
}
