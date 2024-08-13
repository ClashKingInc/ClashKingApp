import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/classes/profile/profile_info.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war/war_functions.dart';
import 'package:clashkingapp/classes/profile/stats/player_war_stats.dart';
import 'package:intl/intl.dart';

class PlayerStatsScreen extends StatefulWidget {
  final ProfileInfo profileInfo;

  PlayerStatsScreen({
    super.key,
    required this.profileInfo,
  });

  @override
  PlayerStatsScreenState createState() => PlayerStatsScreenState();
}

class PlayerStatsScreenState extends State<PlayerStatsScreen>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<int> opponentThLevels =
        widget.profileInfo.warStats!.opponentTownhallLevels();
    List<TownhallAttackStats> thStatsList = [];
    for (int level in opponentThLevels) {
      thStatsList
          .add(widget.profileInfo.warStats!.getTownhallAttackStats(level));
    }

    final Locale userLocale = Localizations.localeOf(context);
    String formattedStartDate = DateFormat.yMd(userLocale.toString()).format(
        DateTime.fromMillisecondsSinceEpoch(widget.profileInfo.warStats!.timeStampsStart * 1000));
    String formattedEndDate = DateFormat.yMd(userLocale.toString()).format(
        DateTime.fromMillisecondsSinceEpoch(widget.profileInfo.warStats!.timeStampsEnd * 1000));

    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: 32),
          Text("From $formattedStartDate to $formattedEndDate", style: Theme.of(context).textTheme.titleSmall),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text("ALL TH", style: Theme.of(context).textTheme.titleSmall),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text(AppLocalizations.of(context)!.attacks),
                          SizedBox(height: 8),
                          Text(AppLocalizations.of(context)!.average),
                          Row(children: [
                            CachedNetworkImage(
                                imageUrl:
                                    "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Attack_Star.png",
                                width: 16,
                                height: 16,
                                fit: BoxFit.cover),
                            SizedBox(width: 8),
                            Text(widget.profileInfo.warStats!.averageStars
                                .toStringAsFixed(2))
                          ]),
                          Row(
                            children: [
                              CachedNetworkImage(
                                  imageUrl:
                                      "https://clashkingfiles.b-cdn.net/icons/Icon_DC_Hitrate.png",
                                  width: 16,
                                  height: 16,
                                  fit: BoxFit.cover),
                              SizedBox(width: 8),
                              Text(widget.profileInfo.warStats!
                                  .averageDestructionPercentage
                                  .toStringAsFixed(2))
                            ],
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              ...generateStars(3, 16),
                              SizedBox(width: 8),
                              Text(
                                  "${widget.profileInfo.warStats!.percentageOfStarsAttacks(3).toStringAsFixed(2)}%")
                            ],
                          ),
                          Row(
                            children: [
                              ...generateStars(2, 16),
                              SizedBox(width: 8),
                              Text(
                                  "${widget.profileInfo.warStats!.percentageOfStarsAttacks(2).toStringAsFixed(2)}%")
                            ],
                          ),
                          Row(
                            children: [
                              ...generateStars(1, 16),
                              SizedBox(width: 8),
                              Text(
                                  "${widget.profileInfo.warStats!.percentageOfStarsAttacks(1).toStringAsFixed(2)}%")
                            ],
                          ),
                          Row(
                            children: [
                              ...generateStars(0, 16),
                              SizedBox(width: 8),
                              Text(
                                  "${widget.profileInfo.warStats!.percentageOfStarsAttacks(0).toStringAsFixed(2)}%")
                            ],
                          ),
                        ],
                      ),
                      Column(children: [
                        Text(AppLocalizations.of(context)!.defenses),
                        SizedBox(height: 8),
                        Text(AppLocalizations.of(context)!.average),
                        Row(
                          children: [
                            CachedNetworkImage(
                                imageUrl:
                                    "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Attack_Star.png",
                                width: 16,
                                height: 16,
                                fit: BoxFit.cover),
                            SizedBox(width: 8),
                            Text(widget
                                .profileInfo.warStats!.averageDefenseStars
                                .toStringAsFixed(2)),
                          ],
                        ),
                        Row(
                          children: [
                            CachedNetworkImage(
                                imageUrl:
                                    "https://clashkingfiles.b-cdn.net/icons/Icon_DC_Hitrate.png",
                                width: 16,
                                height: 16,
                                fit: BoxFit.cover),
                            SizedBox(width: 8),
                            Text(widget.profileInfo.warStats!
                                .averageDefenseDestructionPercentage
                                .toStringAsFixed(2)),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            ...generateStars(3, 16),
                            SizedBox(width: 8),
                            Text(
                                "${widget.profileInfo.warStats!.percentageOfStarsDefenses(3).toStringAsFixed(2)}%"),
                          ],
                        ),
                        Row(
                          children: [
                            ...generateStars(2, 16),
                            SizedBox(width: 8),
                            Text(
                                "${widget.profileInfo.warStats!.percentageOfStarsDefenses(2).toStringAsFixed(2)}%"),
                          ],
                        ),
                        Row(
                          children: [
                            ...generateStars(1, 16),
                            SizedBox(width: 8),
                            Text(
                                "${widget.profileInfo.warStats!.percentageOfStarsDefenses(1).toStringAsFixed(2)}%"),
                          ],
                        ),
                        Row(
                          children: [
                            ...generateStars(0, 16),
                            SizedBox(width: 8),
                            Text(
                                "${widget.profileInfo.warStats!.percentageOfStarsDefenses(0).toStringAsFixed(2)}%"),
                          ],
                        ),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
          ),
          for (TownhallAttackStats thStats in thStatsList)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    CachedNetworkImage(
                      imageUrl: thStats.townHallImageUrl,
                      width: 70,
                      height: 70,
                    ),
                    Column(
                      children: [
                        Text(AppLocalizations.of(context)!.attacks),
                        Row(children: [
                            CachedNetworkImage(
                                imageUrl:
                                    "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Attack_Star.png",
                                width: 16,
                                height: 16,
                                fit: BoxFit.cover),
                            SizedBox(width: 8),
                            Text(thStats.averageStars
                                .toStringAsFixed(2))
                          ]),
                          Row(
                            children: [
                              CachedNetworkImage(
                                  imageUrl:
                                      "https://clashkingfiles.b-cdn.net/icons/Icon_DC_Hitrate.png",
                                  width: 16,
                                  height: 16,
                                  fit: BoxFit.cover),
                              SizedBox(width: 8),
                              Text(thStats
                                  .averageDestructionPercentage
                                  .toStringAsFixed(2))
                            ],
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              ...generateStars(3, 16),
                              SizedBox(width: 8),
                              Text(
                                  "${thStats.threeStars.toStringAsFixed(2)}%")
                            ],
                          ),
                          Row(
                            children: [
                              ...generateStars(2, 16),
                              SizedBox(width: 8),
                              Text(
                                  "${thStats.twoStars.toStringAsFixed(2)}%")
                            ],
                          ),
                          Row(
                            children: [
                              ...generateStars(1, 16),
                              SizedBox(width: 8),
                              Text(
                                  "${thStats.oneStar.toStringAsFixed(2)}%")
                            ],
                          ),
                          Row(
                            children: [
                              ...generateStars(0, 16),
                              SizedBox(width: 8),
                              Text(
                                  thStats.zeroStars.toString())
                            ],
                          ),
                        
                      ],
                    ),
                    Column(
                      children: [
                        Text(AppLocalizations.of(context)!.defenses),
                      ],
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
