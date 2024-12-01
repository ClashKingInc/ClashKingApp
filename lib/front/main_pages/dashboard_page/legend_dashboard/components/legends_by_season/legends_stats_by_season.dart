import 'package:clashkingapp/front/main_pages/wars_league_page/war/war_functions.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/classes/profile/legend/legend_data.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/classes/profile/legend/legends_season_trophies.dart';
import 'package:intl/intl.dart';

class LegendsStatsBySeason extends StatefulWidget {
  final PlayerLegendData playerLegendData;
  final DateTime selectedMonth;
  final SeasonTrophies seasonData;

  LegendsStatsBySeason(
      {required this.playerLegendData,
      required this.selectedMonth,
      required this.seasonData});

  @override
  LegendsStatsBySeasonState createState() => LegendsStatsBySeasonState();
}

class LegendsStatsBySeasonState extends State<LegendsStatsBySeason> {
  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    if (widget.seasonData.seasonLegendDays.isNotEmpty) {
      return SizedBox(
        width: double.infinity,
        child: Card(
          margin: EdgeInsets.only(top: 4, bottom: 4, left: 16, right: 16),
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Text(
                  AppLocalizations.of(context)!.seasonStats,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  "(${DateFormat.yMMMd(locale).format(widget.seasonData.seasonStart)} - ${DateFormat.yMMMd(locale).format(widget.seasonData.seasonEnd)})",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timer,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      (widget.seasonData.totalDays <
                              widget.seasonData.seasonDuration)
                          ? "${AppLocalizations.of(context)!.indexDays(widget.seasonData.seasonDuration)} (${AppLocalizations.of(context)!.dayIndex(widget.seasonData.totalDays)})"
                          : AppLocalizations.of(context)!
                              .indexDays(widget.seasonData.seasonDuration),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CachedNetworkImage(
                                imageUrl: widget.playerLegendData.legendIcon,
                                width: 40,
                              ),
                              SizedBox(width: 4),
                              Text(
                                NumberFormat(
                                        '#,###',
                                        Localizations.localeOf(context)
                                            .toString())
                                    .format(widget.seasonData.totalTrophies),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppLocalizations.of(context)!.attacks,
                                  style: Theme.of(context).textTheme.bodyLarge),
                              Row(
                                children: [
                                  CachedNetworkImage(
                                    imageUrl:
                                        widget.playerLegendData.attackIcon,
                                    width: 15,
                                    height: 15,
                                    fit: BoxFit.cover,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "${NumberFormat('#,###', Localizations.localeOf(context).toString()).format(widget.seasonData.totalAttacks)}/${NumberFormat('#,###', Localizations.localeOf(context).toString()).format(widget.seasonData.daysInLegend * 8)}",
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  CachedNetworkImage(
                                    imageUrl:
                                        "https://assets.clashk.ing/icons/Icon_HV_Trophy.png",
                                    width: 15,
                                    height: 15,
                                    fit: BoxFit.cover,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "${NumberFormat('#,###', Localizations.localeOf(context).toString()).format(widget.seasonData.totalAttacksTrophies)}/${NumberFormat('#,###', Localizations.localeOf(context).toString()).format(320 * widget.seasonData.daysInLegend)}",
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Stack(
                                    alignment: Alignment.topCenter,
                                    children: [
                                      CachedNetworkImage(
                                        imageUrl:
                                            "https://assets.clashk.ing/icons/Icon_HV_Trophy.png",
                                        width: 16,
                                        height: 16,
                                        fit: BoxFit.cover,
                                      ),
                                      CachedNetworkImage(
                                        imageUrl:
                                            "https://assets.clashk.ing/icons/Icon_BB_Star.png",
                                        width: 8,
                                        height: 8,
                                        fit: BoxFit.cover,
                                      )
                                    ],
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "${widget.seasonData.averageAttacksTrophies}",
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  ...generateStars(3, 20),
                                  SizedBox(width: 4),
                                  Text(
                                    "${widget.seasonData.percentageThreeStarsAttacks.toStringAsFixed(1)}%",
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  ...generateStars(2, 20),
                                  SizedBox(width: 4),
                                  Text(
                                    "${widget.seasonData.percentageTwoStarsAttacks.toStringAsFixed(1)}%",
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  ...generateStars(1, 20),
                                  SizedBox(width: 4),
                                  Text(
                                    "${widget.seasonData.percentageOneStarsAttacks.toStringAsFixed(1)}%",
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  ...generateStars(0, 20),
                                  SizedBox(width: 4),
                                  Text(
                                    "${widget.seasonData.percentageNoStarsAttacks.toStringAsFixed(1)}%",
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppLocalizations.of(context)!.defenses,
                                  style: Theme.of(context).textTheme.bodyLarge),
                              Row(
                                children: [
                                  CachedNetworkImage(
                                    imageUrl:
                                        widget.playerLegendData.defenseIcon,
                                    width: 15,
                                    height: 15,
                                    fit: BoxFit.cover,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "${NumberFormat('#,###', Localizations.localeOf(context).toString()).format(widget.seasonData.totalDefenses)}/${NumberFormat('#,###', Localizations.localeOf(context).toString()).format(widget.seasonData.daysInLegend * 8)}",
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  CachedNetworkImage(
                                    imageUrl:
                                        "https://assets.clashk.ing/icons/Icon_HV_Trophy.png",
                                    width: 15,
                                    height: 15,
                                    fit: BoxFit.cover,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "${NumberFormat('#,###', Localizations.localeOf(context).toString()).format(widget.seasonData.totalDefensesTrophies)}/${NumberFormat('#,###', Localizations.localeOf(context).toString()).format(320 * widget.seasonData.daysInLegend)}",
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Stack(
                                    alignment: Alignment.topCenter,
                                    children: [
                                      CachedNetworkImage(
                                        imageUrl:
                                            "https://assets.clashk.ing/icons/Icon_HV_Trophy.png",
                                        width: 16,
                                        height: 16,
                                        fit: BoxFit.cover,
                                      ),
                                      CachedNetworkImage(
                                        imageUrl:
                                            "https://assets.clashk.ing/icons/Icon_BB_Star.png",
                                        width: 8,
                                        height: 8,
                                        fit: BoxFit.cover,
                                      )
                                    ],
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "${widget.seasonData.averageDefensesTrophies}",
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  ...generateStars(3, 20),
                                  SizedBox(width: 4),
                                  Text(
                                    "${widget.seasonData.percentageThreeStarsDefenses.toStringAsFixed(1)}%",
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  ...generateStars(2, 20),
                                  SizedBox(width: 4),
                                  Text(
                                    "${widget.seasonData.percentageTwoStarsDefenses.toStringAsFixed(1)}%",
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  ...generateStars(1, 20),
                                  SizedBox(width: 4),
                                  Text(
                                    "${widget.seasonData.percentageOneStarsDefenses.toStringAsFixed(1)}%",
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  ...generateStars(0, 20),
                                  SizedBox(width: 4),
                                  Text(
                                    "${widget.seasonData.percentageNoStarsDefenses.toStringAsFixed(1)}%",
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity,
        height: 500,
        child: Card(
          margin: EdgeInsets.only(top: 8, bottom: 8, left: 16, right: 16),
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.only(
                left: 10.0, right: 10.0, top: 20.0, bottom: 10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    AppLocalizations.of(context)?.noDataAvailable ??
                        'No data available',
                    style: Theme.of(context).textTheme.bodyMedium),
                CachedNetworkImage(
                  imageUrl:
                      'https://assets.clashk.ing/stickers/Villager_HV_Villager_12.png',
                  height: 300,
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
