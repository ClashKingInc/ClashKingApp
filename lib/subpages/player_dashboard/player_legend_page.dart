import 'package:flutter/material.dart';
import 'package:clashkingapp/api/player_account_info.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';
import 'package:intl/intl.dart';
import 'package:clashkingapp/data/troop_data.dart';

class LegendScreen extends StatefulWidget {
  final PlayerAccountInfo playerStats;

  LegendScreen({Key? key, required this.playerStats}) : super(key: key);

  @override
  LegendScreenState createState() => LegendScreenState();
}

class LegendScreenState extends State<LegendScreen>
    with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> legendData;
  late TabController tabController;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    legendData = fetchLegendData();
    tabController = TabController(length: 2, vsync: this);
    selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> fetchLegendData() async {
    final response = await http.get(Uri.parse(
        'https://api.clashking.xyz/player/${widget.playerStats.tag.substring(1)}/legends'));
    if (response.statusCode == 200) {
      print(response.body);
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load legend data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
            child: Column(children: [
      Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          SizedBox(
            height: 190,
            width: double.infinity,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
              child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.3), // Adjust opacity as needed
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
            top: 20,
            left: 10,
            right: 10, // Add right positioning for better alignment
            child: FutureBuilder<Map<String, dynamic>>(
              future: legendData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (snapshot.hasData) {
                    return Center(
                      child: Container(
                        padding: EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Image.network(
                                  "https://clashkingfiles.b-cdn.net/icons/Icon_HV_League_Legend_3.png",
                                  width: 120, // Adjust the size as needed
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${snapshot.data!['name']}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: Colors.white,
                                            ),
                                      ),
                                      Wrap(
                                        spacing:
                                            4, // gap between adjacent chips
                                        runSpacing: 4, // gap between lines
                                        children: <Widget>[
                                          Chip(
                                            label: Text(
                                                '${snapshot.data!['tag']}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall),
                                            backgroundColor: Colors.transparent,
                                          ),
                                          Chip(
                                            avatar: CircleAvatar(
                                              backgroundColor: Colors
                                                  .transparent, // Set to a suitable color for your design.
                                              child: Image.network(
                                                      "https://clashkingfiles.b-cdn.net/country-flags/${snapshot.data?['rankings']['country_code']!.toLowerCase() ?? 'uk'}.png")
                                             // Using Container() as a fallback
                                            ),
                                            label: Text(
                                                '${snapshot.data!['rankings']['country_name'] ?? 'Unknown Country'}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall),
                                            backgroundColor: Colors.transparent,
                                          ),
                                          Chip(
                                            label: Text(
                                                '${snapshot.data!['rankings']['local_rank']}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall),
                                            backgroundColor: Colors.transparent,
                                          ),
                                          Chip(
                                            label: Text(
                                                '${snapshot.data!['rankings']['global_rank']}',
                                                style: TextStyle(
                                                    color: Colors.black)),
                                            backgroundColor:
                                                Colors.white.withOpacity(0.5),
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
                    );
                  }
                }
                return Center(child: CircularProgressIndicator());
              },
            ),
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
      ),
      ScrollableTab(
        labelColor: Colors.black,
        onTap: (value) {
          print('Tab $value selected');
          setState(() {});
        },
        tabs: [
          Tab(text: "By Day"),
          Tab(text: "History"),
        ],
        children: [
          Container(
            color: Theme.of(context).colorScheme.tertiary,
            child: ListTile(
              title: FutureBuilder<Map<String, dynamic>>(
                future: legendData,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (snapshot.hasData) {
                      return buildLegendStats(snapshot.data!);
                    }
                  }
                  return Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ),
          Container(
              color: Theme.of(context).colorScheme.tertiary,
              constraints: BoxConstraints.expand(
                  width: double.infinity, height: double.infinity),
              child: ListTile(
                title: FutureBuilder<Map<String, dynamic>>(
                  future: legendData,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (snapshot.hasData) {
                        return buildLegendHistoryStats(snapshot.data!);
                      }
                    }
                    return Center(child: CircularProgressIndicator());
                  },
                ),
              ))
        ],
      )
    ])));
  }

  Widget buildLegendStats(Map<String, dynamic> data) {
    List<Widget> legendEntries = [];
    Map<String, dynamic> legends = data['legends'];

    if (legends != null) {
      String date = DateFormat('yyyy-MM-dd').format(selectedDate);

      if (legends.containsKey(date)) {
        Map<String, dynamic> details = legends[date];

        if (details != null) {
          List<dynamic> attacksList = details.containsKey('new_attacks')
              ? details['new_attacks']
              : details['attacks'] ?? [];
          List<dynamic> defensesList = details.containsKey('new_defenses')
              ? details['new_defenses']
              : details['defenses'] ?? [];

          legendEntries.add(
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  // Row with date and navigation buttons as before
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildOffenseSection(
                            "Offense", attacksList, context),
                      ),
                      Expanded(
                        child: _buildDefenseSection(
                            "Defense", defensesList, context),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      _buildGearSection("Hero Gear", attacksList),
                    ],
                  ),
                  /*"rankings": {
    "tag": "#8GLYGGJQ",
    "country_code": "FR",
    "country_name": "France",
    "local_rank": null,
    "global_rank": 269224,
    "builder_global_rank": null,
    "builder_local_rank": null
  },*/

                  Card(
                      child: Column(children: [
                    Text('Ranking',
                        style: Theme.of(context).textTheme.titleMedium),
                    Text('Rank: ${data['rankings']}'),
                  ]))
                ],
              ),
            ),
          );
        }
      }
    } else {
      print('Legends data is not available');
    }

    return Column(children: legendEntries);
  }

  Widget _buildOffenseSection(
      String title, List<dynamic> list, BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            ...list.map((item) {
              if (item is Map) {
                int change = item['change'];
                int time = item['time'];
                List<dynamic> heroGear = item['hero_gear'] ?? [];
                String timeAgo = _convertToTimeAgo(time);

                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Image.network(
                            "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Attacks_No_Shield.png",
                            width: 20),
                        SizedBox(width: 4),
                        Text('+$change',
                            style: Theme.of(context).textTheme.bodyMedium),
                        Text(" ($timeAgo)",
                            style: Theme.of(context).textTheme.labelSmall),
                      ]),
                    ]);
              } else {
                return Text("$item");
              }
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDefenseSection(
      String title, List<dynamic> list, BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            ...list.map((item) {
              if (item is Map) {
                int change = item['change'];
                int time = item['time'];
                List<dynamic> heroGear = item['hero_gear'] ?? [];
                String timeAgo = _convertToTimeAgo(time);

                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Image.network(
                            "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Shield_Arrow.png",
                            width: 20),
                        SizedBox(width: 4),
                        Text('+$change',
                            style: Theme.of(context).textTheme.bodyMedium),
                        Text(" ($timeAgo)",
                            style: Theme.of(context).textTheme.labelSmall),
                      ]),
                    ]);
              } else {
                return Text("$item");
              }
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildGearSection(String title, List<dynamic> list) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            ...list.map((item) {
              if (item is Map) {
                List<dynamic> heroGear = item['hero_gear'] ?? [];
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (heroGear.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                        ),
                      Row(
                        children: [
                          ...heroGear.map((gear) {
                            var gearData = troopUrlsAndTypes[gear['name']];
                            return gearData != null
                                ? Image.network(
                                    gearData['url'] ??
                                        "https://clashkingfiles.b-cdn.net/clashkinglogo.png",
                                    width: 24)
                                : Text(
                                    "- ${gear['name']} Lvl: ${gear['level']}",
                                    style:
                                        Theme.of(context).textTheme.bodyText2);
                          }).toList(),
                        ],
                      )
                    ]);
              } else {
                return Text("$item");
              }
            }).toList(),
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
                    subtitle:
                        Text('il y a 21 heures'), // Replace with actual time
                  ))
              .toList()
          : [Text('No attacks')];

      List<Widget> defenses = details['defenses'] != null
          ? (details['defenses'] as List)
              .map((defense) => ListTile(
                    leading: Icon(Icons.shield,
                        color: Colors.green), // Replace with appropriate icon
                    title: Text('${defense.toString()}'),
                    subtitle:
                        Text('il y a 21 heures'), // Replace with actual time
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
                          style: Theme.of(context).textTheme.headline6),
                      ...attacks,
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Defense',
                          style: Theme.of(context).textTheme.headline6),
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
