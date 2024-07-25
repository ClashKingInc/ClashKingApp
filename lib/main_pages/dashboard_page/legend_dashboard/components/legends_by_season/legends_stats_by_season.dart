import 'package:flutter/material.dart';
import 'package:clashkingapp/classes/profile/legend/legend_data.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    DateTime now = DateTime.now();

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
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Column(
                                children: [
                                  SizedBox(height: 2),
                                  Icon(
                                    Icons.calendar_today,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    size: 16,
                                  ),
                                  SizedBox(height: 6),
                                  CachedNetworkImage(
                                    imageUrl:
                                        widget.playerLegendData.legendIcon,
                                    width: 16,
                                  ),
                                ],
                              ),
                              SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (widget.selectedMonth.month == now.month &&
                                            widget.selectedMonth.year ==
                                                now.year)
                                        ? "${AppLocalizations.of(context)!.indexDays(widget.seasonData.seasonDuration)} (${AppLocalizations.of(context)!.dayIndex(widget.seasonData.totalDays)})"
                                        : AppLocalizations.of(context)!
                                            .indexDays(widget
                                                .seasonData.seasonDuration),
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    widget.seasonData.totalTrophies.toString(),
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
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
                                    "${widget.seasonData.totalAttacks.toString()}/${widget.seasonData.totalDays * 8}",
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  CachedNetworkImage(
                                    imageUrl:
                                        "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Trophy.png",
                                    width: 15,
                                    height: 15,
                                    fit: BoxFit.cover,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "${widget.seasonData.totalAttacksTrophies.toString()}/${320 * widget.seasonData.totalDays}",
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
                                    "${widget.seasonData.totalDefenses.toString()}/${widget.seasonData.totalDays * 8}",
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  CachedNetworkImage(
                                    imageUrl:
                                        "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Trophy.png",
                                    width: 15,
                                    height: 15,
                                    fit: BoxFit.cover,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "${widget.seasonData.totalDefensesTrophies.toString()}/${320 * widget.seasonData.totalDays}",
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
                      'https://clashkingfiles.b-cdn.net/stickers/Villager_HV_Villager_12.png',
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
