import 'package:flutter/material.dart';
import 'package:clashkingapp/api/player_account_info.dart';
import 'package:clashkingapp/subpages/player_dashboard/player_legend_page.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
    if (!legendData['legends'].containsKey(date)) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LegendScreen(
                  playerStats: playerStats,
                  legendData: legendData,
                  diffTrophies: 0,
                  currentTrophies: playerStats.trophies.toString(),
                  firstTrophies: "0",
                  attacksList: [],
                  defensesList: []),
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
                      Center(
                        child: Text("No Legend Data Found for today",
                            style: Theme.of(context).textTheme.labelLarge),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
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
                            child: Stack(
                              children: <Widget>[
                                Image.network(
                                  "https://clashkingfiles.b-cdn.net/icons/Icon_HV_League_Legend_3.png",
                                ),
                                Positioned(
                                  right: 30,
                                  top: 32,
                                  child: Text(
                                    currentTrophies,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall!
                                        .copyWith(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                              spacing: 4.0, // gap between adjacent chips
                              runSpacing: 0.0, // gap between lines
                              children: <Widget>[
                                Chip(
                                    avatar: CircleAvatar(
                                        backgroundColor: Colors.transparent,
                                        child: Image.network(
                                            "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Start_Flag.png")),
                                    label: Text(firstTrophies,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium)),
                                Chip(
                                  avatar: Icon(
                                    diffTrophies > 0
                                        ? LucideIcons.chevronUp
                                        : LucideIcons.chevronDown,
                                    color: diffTrophies > 0
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                  label: Text(
                                    "${diffTrophies >= 0 ? '+' : ''}${diffTrophies.toString()}",
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                            color: diffTrophies >= 0
                                                ? Colors.green
                                                : Colors.red),
                                  ),
                                ),
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
                                    legendData['rankings']['global_rank'] ==
                                            null
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
}
