import 'package:clashkingapp/api/player_account_info.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/subpages/player_dashboard/player_info_page.dart';
import 'package:clashkingapp/api/discord_user_info.dart';
import 'package:clashkingapp/components/app_bar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:clashkingapp/subpages/player_dashboard/player_legend_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class DashboardPage extends StatefulWidget {
  final PlayerAccountInfo playerStats;
  final DiscordUser user;

  DashboardPage({required this.playerStats, required this.user});

  @override
  DashboardPageState createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> legendData;

  @override
  void initState() {
    super.initState();
    legendData = fetchLegendData();
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
    print(legendData);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.tertiary,
      appBar: CustomAppBar(user: widget.user),
      body: ListView(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: CreatorCodeCard(),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: PlayerStatsCard(playerStats: widget.playerStats),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: FutureBuilder<Map<String, dynamic>>(
              future: legendData,
              builder: (BuildContext context,
                  AsyncSnapshot<Map<String, dynamic>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Card(
                      child: Center(
                          child:
                              CircularProgressIndicator())); // Show a loading spinner while waiting
                } else if (snapshot.hasError) {
                  return Text(
                      'Error: ${snapshot.error}'); // Show error if something went wrong
                } else {
                  return PlayerLegendCard(
                      playerStats: widget.playerStats,
                      legendData:
                          snapshot.data!); // Build PlayerLegendCard with data
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CreatorCodeCard extends StatelessWidget {
  const CreatorCodeCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        // Padding right and left
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.center, // Adjust vertical alignment here
          children: <Widget>[
            Image.asset('assets/icons/Crown.png',
                width: 80, height: 80), // Specify your desired width and height
            SizedBox(width: 16), // Add space between the image and text
            Expanded(
              // Use Expanded to ensure text takes up the remaining space
              child: Text(
                AppLocalizations.of(context)?.creatorCode ??
                    'Creator Code : ClashKing',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlayerStatsCard extends StatelessWidget {
  const PlayerStatsCard({
    super.key,
    required this.playerStats,
  });

  final PlayerAccountInfo playerStats;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StatsScreen(playerStats: playerStats),
          ),
        );
      },
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.labelLarge ?? TextStyle(),
        child: Card(
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
                          height: 100,
                          width: 100,
                          child: Image.network(playerStats.townHallPic),
                        ),
                        Text(
                          playerStats.name,
                          style: (Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)) ??
                              TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          playerStats.tag,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 4.0, // gap between adjacent chips
                            runSpacing: 0.0, // gap between lines
                            children: <Widget>[
                              Chip(
                                avatar: CircleAvatar(
                                  backgroundColor: Colors
                                      .transparent, // Set to a suitable color for your design.
                                  child: Image.network(
                                      playerStats.clan.badgeUrls.small),
                                ),
                                labelPadding:
                                    EdgeInsets.only(left: 2.0, right: 2.0),
                                label: Text(
                                  playerStats.clan.name,
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                              Chip(
                                avatar: CircleAvatar(
                                  backgroundColor: Colors
                                      .transparent, // Set to a suitable color for your design.
                                  child: playerStats.warPreference == 'in'
                                      ? Image.network(
                                          "https://clashkingfiles.b-cdn.net/icons/Icon_HV_In.png")
                                      : Image.network(
                                          'https://clashkingfiles.b-cdn.net/icons/Icon_HV_Out.png'),
                                ),
                                labelPadding:
                                    EdgeInsets.only(left: 2.0, right: 2.0),
                                label: Text(
                                  playerStats.warPreference.toString(),
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                              Chip(
                                avatar: CircleAvatar(
                                  backgroundColor: Colors
                                      .transparent, // Set to a suitable color for your design.
                                  child: Image.network(playerStats.townHallPic),
                                ),
                                label: Text('${playerStats.townHallLevel}',
                                    style:
                                        Theme.of(context).textTheme.labelLarge),
                                labelPadding: EdgeInsets.zero,
                              ),
                              Chip(
                                avatar: CircleAvatar(
                                  backgroundColor: Colors
                                      .transparent, // Set to a suitable color for your design.
                                  child: Image.network(
                                      "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Trophy.png"),
                                ),
                                label: Text('${playerStats.trophies}',
                                    style:
                                        Theme.of(context).textTheme.labelLarge),
                                labelPadding: EdgeInsets.zero,
                              ),
                              Chip(
                                avatar: Icon(LucideIcons.chevronsUpDown,
                                    color: Color.fromARGB(255, 0, 136, 255)),
                                labelPadding: EdgeInsets.zero,
                                label: Text(
                                  (playerStats.donations /
                                          (playerStats.donationsReceived == 0
                                              ? 1
                                              : playerStats.donationsReceived))
                                      .toStringAsFixed(2),
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                              Chip(
                                avatar: CircleAvatar(
                                  backgroundColor: Colors
                                      .transparent, // Set to a suitable color for your design.
                                  child:
                                      Image.network(playerStats.builderHallPic),
                                ),
                                label: Text('${playerStats.builderHallLevel}',
                                    style:
                                        Theme.of(context).textTheme.labelLarge),
                                labelPadding: EdgeInsets.zero,
                              ),
                              Chip(
                                avatar: CircleAvatar(
                                  backgroundColor: Colors
                                      .transparent, // Set to a suitable color for your design.
                                  child: Image.network(
                                      "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Trophy.png"),
                                ),
                                label: Text(
                                    '${playerStats.builderBaseTrophies}',
                                    style:
                                        Theme.of(context).textTheme.labelLarge),
                                labelPadding: EdgeInsets.zero,
                              ),
                              Chip(
                                avatar: CircleAvatar(
                                  backgroundColor: Colors
                                      .transparent, // Set to a suitable color for your design.
                                  child: Image.network(
                                      "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Attack_Star.png"),
                                ),
                                labelPadding:
                                    EdgeInsets.only(left: 2.0, right: 2.0),
                                label: Text(
                                  '${playerStats.warStars}',
                                  style: Theme.of(context).textTheme.labelLarge,
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
      ),
    );
  }
}

class PlayerLegendCard extends StatelessWidget {
  const PlayerLegendCard({
    super.key,
    required this.playerStats,
    required this.legendData,
  });

  final PlayerAccountInfo playerStats;
  final Map<String, dynamic> legendData;

  @override
  Widget build(BuildContext context) {
    DateTime selectedDate = DateTime.now();
    String date = DateFormat('yyyy-MM-dd').format(selectedDate);
    Map<String, dynamic> details = legendData['legends'][date];
    String firstTrophies = '0';
    String currentTrophies = "0";
    int diffTrophies = 0;
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
      diffTrophies = int.parse(currentTrophies) - int.parse(firstTrophies);
    }
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LegendScreen(
                playerStats: playerStats,
                legendData: legendData,
                diffTrophies: diffTrophies,
                currentTrophies: currentTrophies,
                firstTrophies: firstTrophies,
                attacksList: attacksList,
                defensesList: defensesList),
          ),
        );
      },
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.labelLarge ?? TextStyle(),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        Text(
                          "Legend League",
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        SizedBox(
                          height: 100,
                          width: 100,
                          child: Image.network(
                              "https://clashkingfiles.b-cdn.net/icons/Icon_HV_League_Legend_3.png"),
                        ),
                      ],
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 4.0, // gap between adjacent chips
                            runSpacing: 0.0, // gap between lines
                            children: <Widget>[
                              Text(currentTrophies,
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              Column(children: [
                                Text(
                                  "(${diffTrophies >= 0 ? '+' : ''}${diffTrophies.toString()})",
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                          color: diffTrophies >= 0
                                              ? Colors.green
                                              : Colors.red),
                                ),
                                SizedBox(height: 32),
                              ]),
                              Chip(
                                avatar: CircleAvatar(
                                    backgroundColor: Colors.transparent,
                                    child: Image.network(
                                        "https://clashkingfiles.b-cdn.net/country-flags/${legendData['rankings']['country_code']!.toLowerCase() ?? 'uk'}.png")),
                                label: Text(
                                  legendData['rankings']['local_rank'] == null
                                      ? 'No Rank'
                                      : '${legendData['rankings']['local_rank']}',
                                  style:
                                      Theme.of(context).textTheme.labelMedium,
                                ),
                              ),
                              Chip(
                                avatar: CircleAvatar(
                                    backgroundColor: Colors.transparent,
                                    child: Image.network(
                                        "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Planet.png")),
                                label: Text(
                                  legendData['rankings']['global_rank'] == null
                                      ? 'No Rank'
                                      : '${legendData['rankings']['global_rank']}',
                                  style:
                                      Theme.of(context).textTheme.labelMedium,
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
      ),
    );
  }
}
