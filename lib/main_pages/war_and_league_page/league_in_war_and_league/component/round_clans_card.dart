import 'package:flutter/material.dart';
import 'package:clashkingapp/api/current_war_info.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_in_war_and_league/current_war_info_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RoundClanCard extends StatelessWidget {
  final CurrentWarInfo warLeagueInfo;
  final List<String> discordUser;

  const RoundClanCard({
    super.key,
    required this.warLeagueInfo,
    required this.discordUser,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CurrentWarInfoScreen(currentWarInfo: warLeagueInfo, discordUser: discordUser),
            ),
          );
        },
        child: Card(
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0, top: 8.0, bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 50,
                              width: 50,
                              child: CachedNetworkImage(imageUrl: 
                                  warLeagueInfo.clan.badgeUrls.small),
                            ),
                            Column(
                              children: [
                                Row(children: [
                                  SizedBox(
                                    child: CachedNetworkImage(imageUrl: 
                                      "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Sword.png",
                                      width: 12,
                                      height: 12,
                                    ),
                                  ),
                                  Text(
                                      "${warLeagueInfo.clan.attacks}/${warLeagueInfo.teamSize.toString()}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium),
                                ]),
                                Row(children: [
                                  SizedBox(
                                    child: CachedNetworkImage(imageUrl: 
                                      "https://clashkingfiles.b-cdn.net/icons/Icon_DC_Hitrate.png",
                                      width: 12,
                                      height: 12,
                                    ),
                                  ),
                                  Text(
                                      " ${warLeagueInfo.clan.destructionPercentage.toStringAsFixed(2)}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium),
                                ]),
                              ],
                            ),
                          ]),
                      Text(
                        warLeagueInfo.clan.name,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                                                  warLeagueInfo
                                                      .opponent.stars &&
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
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
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
                ),
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Column(
                            children: [
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                        "${warLeagueInfo.opponent.attacks}/${warLeagueInfo.teamSize.toString()}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium),
                                    SizedBox(
                                      child: CachedNetworkImage(imageUrl: 
                                        "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Sword.png",
                                        width: 12,
                                        height: 12,
                                      ),
                                    ),
                                  ]),
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                        "${warLeagueInfo.opponent.destructionPercentage.toStringAsFixed(2)} ",
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium),
                                    SizedBox(
                                      child: CachedNetworkImage(imageUrl: 
                                        "https://clashkingfiles.b-cdn.net/icons/Icon_DC_Hitrate.png",
                                        width: 12,
                                        height: 12,
                                      ),
                                    ),
                                  ])
                            ],
                          ),
                          SizedBox(
                            height: 50,
                            width: 50,
                            child: CachedNetworkImage(imageUrl: 
                                warLeagueInfo.opponent.badgeUrls.small),
                          ),
                        ],
                      ),
                      Text(
                        warLeagueInfo.opponent.name,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
