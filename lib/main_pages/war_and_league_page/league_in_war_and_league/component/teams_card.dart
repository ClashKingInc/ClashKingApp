import 'package:flutter/material.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_info_page.dart';
import 'package:clashkingapp/api/current_league_info.dart';
import 'package:clashkingapp/api/clan_info.dart';

class TeamsCard extends StatelessWidget {
  const TeamsCard({
    super.key,
    required this.sortedClans,
    required this.totalByClan,
  });

  final List<ClanLeagueDetails> sortedClans;
  final Map<String, Map<String, dynamic>> totalByClan;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: sortedClans.map((clan) {
            var townHallLevelCounts = <int, int>{};

            for (var member in clan.members) {
              final townHallLevel = member.townHallLevel;
              townHallLevelCounts[townHallLevel] =
                  (townHallLevelCounts[townHallLevel] ?? 0) + 1;
            }

            var sortedEntries = townHallLevelCounts.entries.toList()
              ..sort((a, b) => b.key.compareTo(a.key));

            townHallLevelCounts = Map.fromEntries(sortedEntries);

            return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                        backgroundColor:
                            Theme.of(context).colorScheme.background,
                        body: FutureBuilder<ClanInfo>(
                          future: ClanService().fetchClanInfo(clan.tag),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            } else {
                              return ClanInfoScreen(clanInfo: snapshot.data!);
                            }
                          },
                        ),
                      ),
                    ),
                  );
                },
                child: Stack(children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            fit: FlexFit.tight,
                            flex: 8,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.network(clan.badgeUrls.small,
                                        width: 40, height: 40),
                                    SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(clan.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium),
                                        Text(clan.tag,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  children:
                                      townHallLevelCounts.entries.map((entry) {
                                    return Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Wrap(
                                        children: [
                                          Image.network(
                                            'https://clashkingfiles.b-cdn.net/home-base/town-hall-pics/town-hall-${entry.key}.png',
                                            width: 20,
                                          ),
                                          SizedBox(width: 5),
                                          Text('x${entry.value}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            fit: FlexFit.tight,
                            flex: 2,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Column(children: [
                                      SizedBox(height: 6),
                                      Row(children: [
                                        Text(
                                            "${totalByClan[clan.tag]?['stars'] ?? 0}"),
                                        SizedBox(
                                          child: Image.network(
                                            "https://clashkingfiles.b-cdn.net/icons/Icon_BB_Star.png",
                                            width: 20,
                                            height: 20,
                                          ),
                                        ),
                                      ]),
                                      SizedBox(height: 8),
                                      Text(
                                        "${totalByClan[clan.tag]?['percentage'].toStringAsFixed(0) ?? 0.0}%",
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .tertiary),
                                      ),
                                    ])
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                      top: 10,
                      left: 20,
                      child: Text("${sortedClans.indexOf(clan) + 1}.",
                          style: Theme.of(context).textTheme.titleMedium))
                ]));
          }).toList(),
        ),
      ],
    );
  }
}
