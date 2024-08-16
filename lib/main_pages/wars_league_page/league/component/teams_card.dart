import 'package:flutter/material.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_info_clan/clan_info_page.dart';
import 'package:clashkingapp/classes/clan/war_league/current_league_info.dart';
import 'package:clashkingapp/classes/clan/clan_info.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TeamsCard extends StatelessWidget {
  const TeamsCard({
    super.key,
    required this.currentLeagueInfo,
    required this.clanTag,
    required this.discordUser,
    required this.sortBy,
  });

  final CurrentLeagueInfo currentLeagueInfo;
  final String clanTag;
  final List<String> discordUser;
  final String sortBy;

  @override
  Widget build(BuildContext context) {
    // Sort the clans based on the selected criteria
    List<ClanLeagueDetails> sortedClans = List.from(currentLeagueInfo.clans);
    currentLeagueInfo.sortClans(sortedClans, sortBy);

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
                            Theme.of(context).scaffoldBackgroundColor,
                        body: FutureBuilder<Clan>(
                          future: ClanService().fetchClanAndWarInfo(clan.tag),
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
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      SizedBox(width: 16),
                                      SizedBox(
                                        width: 20,
                                        child: Text(
                                          "${sortedClans.indexOf(clan) + 1}.",
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                      ),
                                      SizedBox(width: 20),
                                      Expanded(
                                        child: Row(
                                          children: [
                                            CachedNetworkImage(
                                              imageUrl: clan.badgeUrls.small,
                                              width: 40,
                                              height: 40,
                                            ),
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
                                      ),
                                      SizedBox(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                    "  ${clan.stars}"),
                                                SizedBox(
                                                  child: CachedNetworkImage(
                                                    imageUrl:
                                                        "https://assets.clashk.ing/icons/Icon_BB_Star.png",
                                                    width: 20,
                                                    height: 20,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              "${clan.destructionPercentage.toStringAsFixed(0)}%",
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 20),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    children: townHallLevelCounts.entries
                                        .map((entry) {
                                      return Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Wrap(
                                          children: [
                                            CachedNetworkImage(
                                              imageUrl:
                                                  'https://assets.clashk.ing/home-base/town-hall-pics/town-hall-${entry.key}.png',
                                              width: 20,
                                            ),
                                            SizedBox(width: 5),
                                            Text(
                                              'x${entry.value}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
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
                ));
          }).toList(),
        ),
        SizedBox(height: 10),
      ],
    );
  }
}
