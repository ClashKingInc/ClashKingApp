import 'package:flutter/material.dart';
import 'package:clashkingapp/api/current_war_info.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_in_war_and_league/current_war_info_page.dart';

class RoundClanCard extends StatelessWidget {
  final CurrentWarInfo warLeagueInfo;

  const RoundClanCard({
    super.key,
    required this.warLeagueInfo,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CurrentWarInfoScreen(currentWarInfo: warLeagueInfo),
            ),
          );
        },
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start, // Add this line
              children: [
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 40,
                        width: 40,
                        child:
                            Image.network(warLeagueInfo.clan.badgeUrls.small),
                      ),
                      Text(
                        warLeagueInfo.clan.name,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              child: Image.network(
                                "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Sword.png",
                                width: 15,
                                height: 15,
                              ),
                            ),
                            Text(
                                "${warLeagueInfo.clan.attacks}/${warLeagueInfo.teamSize.toString()}",
                                style: Theme.of(context).textTheme.labelLarge),
                          ]),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              child: Image.network(
                                "https://clashkingfiles.b-cdn.net/icons/Icon_DC_Hitrate.png",
                                width: 15,
                                height: 15,
                              ),
                            ),
                            Text(
                                " ${warLeagueInfo.clan.destructionPercentage.toStringAsFixed(2)}",
                                style: Theme.of(context).textTheme.labelMedium),
                          ]),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          "${warLeagueInfo.clan.stars}",
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: warLeagueInfo.clan.stars >
                                            warLeagueInfo.opponent.stars ||
                                        (warLeagueInfo.clan.stars ==
                                                warLeagueInfo.opponent.stars &&
                                            warLeagueInfo.clan
                                                    .destructionPercentage >
                                                warLeagueInfo.opponent
                                                    .destructionPercentage)
                                    ? Colors.green
                                    : null,
                              ),
                        ),
                        Text(" - "),
                        Text(
                          "${warLeagueInfo.opponent.stars}",
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: warLeagueInfo.opponent.stars >
                                                warLeagueInfo.clan.stars ||
                                            (warLeagueInfo.opponent.stars ==
                                                    warLeagueInfo.clan.stars &&
                                                warLeagueInfo.opponent
                                                        .destructionPercentage >
                                                    warLeagueInfo.clan
                                                        .destructionPercentage)
                                        ? Colors.green
                                        : null,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 40,
                        width: 40,
                        child: Image.network(
                            warLeagueInfo.opponent.badgeUrls.small),
                      ),
                      Text(
                        warLeagueInfo.opponent.name,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              child: Image.network(
                                "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Sword.png",
                                width: 15,
                                height: 15,
                              ),
                            ),
                            Text(
                                "${warLeagueInfo.opponent.attacks}/${warLeagueInfo.teamSize.toString()}",
                                style: Theme.of(context).textTheme.labelLarge),
                          ]),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              child: Image.network(
                                "https://clashkingfiles.b-cdn.net/icons/Icon_DC_Hitrate.png",
                                width: 15,
                                height: 15,
                              ),
                            ),
                            Text(
                                " ${warLeagueInfo.opponent.destructionPercentage.toStringAsFixed(2)}",
                                style: Theme.of(context).textTheme.labelMedium),
                          ])
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
