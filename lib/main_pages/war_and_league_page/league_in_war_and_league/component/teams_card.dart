
import 'package:flutter/material.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_info_page/clan_info_page.dart';
import 'package:clashkingapp/api/current_league_info.dart';
import 'package:clashkingapp/api/clan_info.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TeamsCard extends StatelessWidget {
  const TeamsCard({
    super.key,
    required this.sortedClans,
    required this.totalByClan,
    required this.clanTag,
    required this.discordUser,
  });

  final List<ClanLeagueDetails> sortedClans;
  final Map<String, Map<String, dynamic>> totalByClan;
  final String clanTag;
  final List<String> discordUser;

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
                              return ClanInfoScreen(clanInfo: snapshot.data!, discordUser: []);
                            }
                          },
                        ),
                      ),
                    ),
                  );
                },
                child: Stack(
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        side: clan.tag == clanTag
                            ? BorderSide(color: Colors.green, width: 2)
                            : BorderSide.none,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "${sortedClans.indexOf(clan) + 1}.",
                                        style: Theme.of(context).textTheme.titleMedium
                                      ),
                                      SizedBox(width: 50),
                                      CachedNetworkImage(imageUrl: clan.badgeUrls.small,
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
                                      SizedBox(width: 40),
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            children: [
                                              Text("  ${totalByClan[clan.tag]?['stars'] ?? 0}"),
                                              SizedBox(
                                                child: CachedNetworkImage(
                                                  imageUrl: "https://clashkingfiles.b-cdn.net/icons/Icon_BB_Star.png",
                                                  width: 20,
                                                  height: 20,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            "${totalByClan[clan.tag]?['percentage'].toStringAsFixed(0) ?? 0.0}%",
                                          ),
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
                                            CachedNetworkImage(imageUrl: 
                                              'https://clashkingfiles.b-cdn.net/home-base/town-hall-pics/town-hall-${entry.key}.png',
                                              width: 20,
                                            ),
                                            SizedBox(width: 5),
                                            Text('x${entry.value}',
                                              style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          ).toList(),
        ),
        SizedBox(height: 10),
      ],
    );
  }
}