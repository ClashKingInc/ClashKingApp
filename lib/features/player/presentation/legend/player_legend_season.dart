import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/models/player_legend_season.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:clashkingapp/core/functions/war_functions.dart';

class LegendSeason extends StatelessWidget {
  final Player player;
  final PlayerLegendSeason? season;

  const LegendSeason(
      {super.key, required this.player, required this.season});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();

    if (season != null && season!.days.isNotEmpty) {
      return SizedBox(
        width: double.infinity,
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Text(AppLocalizations.of(context)!.seasonStats,
                    style: Theme.of(context).textTheme.titleMedium),
                Text(
                  "(${DateFormat.yMMMd(locale).format(season!.start)} - ${DateFormat.yMMMd(locale).format(season!.end)})",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 16),
                    const SizedBox(width: 8),
                    Text(
                      season!.dayOfSeason < season!.duration
                          ? "${AppLocalizations.of(context)!.indexDays(season!.duration)} (${AppLocalizations.of(context)!.dayIndex(season!.dayOfSeason)})"
                          : "${season!.daysInLegend}/${AppLocalizations.of(context)!.indexDays(season!.duration)}",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                            imageUrl: ImageAssets.legendBlazon,
                            width: 40,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            NumberFormat('#,###', locale)
                                .format(season!.endTrophies),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatsBlock(
                            context,
                            title: AppLocalizations.of(context)!.attacks,
                            count: season!.totalAttacks,
                            trophies: season!.trophiesGainedTotal,
                            average: season!.avgGainedPerAttack,
                            attacksPossible: season!.totalPossible,
                            trophiesPossible: season!.gainedLostPossible,
                            percentages:
                                season!.attackStarsDistributionPercentages,
                            attacksdefs: season!.attackStarsDistribution,
                            icon: ImageAssets.sword,
                          ),
                          _buildStatsBlock(
                            context,
                            title: AppLocalizations.of(context)!.defenses,
                            count: season!.totalDefenses,
                            trophies: season!.trophiesLostTotal,
                            average: season!.avgLostPerDefense,
                            attacksPossible: season!.totalPossible,
                            trophiesPossible: season!.gainedLostPossible,
                            percentages:
                                season!.defenseStarsDistributionPercentages,
                            attacksdefs: season!.defenseStarsDistribution,
                            icon: ImageAssets.shieldWithArrow,
                          ),
                        ],
                      )
                    ],
                  ),
                )
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
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    AppLocalizations.of(context)?.noDataAvailable ??
                        'No data available',
                    style: Theme.of(context).textTheme.bodyMedium),
                CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
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

  Widget _buildStatsBlock(BuildContext context,
      {required String title,
      required int count,
      required int trophies,
      required double average,
      required Map<int, double> percentages,
      required Map<int, int> attacksdefs,
      required int attacksPossible,
      required int trophiesPossible,
      required String icon}) {
    final locale = Localizations.localeOf(context).toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.bodyLarge),
        Row(
          children: [
            CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),imageUrl: icon, width: 15, height: 15),
            const SizedBox(width: 4),
            Text(
                "${NumberFormat('#,###', locale).format(count)}/$attacksPossible",
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        Row(
          children: [
            CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
              imageUrl: ImageAssets.trophies,
              width: 15,
              height: 15,
              fit: BoxFit.cover,
            ),
            const SizedBox(width: 4),
            Text(
                "${NumberFormat('#,###', locale).format(trophies)}/$trophiesPossible",
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        Row(
          children: [
            Stack(
              alignment: Alignment.topCenter,
              children: [
                CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                  imageUrl: ImageAssets.trophies,
                  width: 16,
                  height: 16,
                  fit: BoxFit.cover,
                ),
                CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                  imageUrl: ImageAssets.builderBaseStar,
                  width: 8,
                  height: 8,
                  fit: BoxFit.cover,
                )
              ],
            ),
            const SizedBox(width: 4),
            Text(average.toStringAsFixed(1),
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 16),
        for (int star = 3; star >= 0; star--)
          Row(
            children: [
              ...generateStars(star, 20),
              const SizedBox(width: 4),
              Text("${percentages[star]?.toStringAsFixed(1) ?? '0.0'}% (${attacksdefs[star] ?? 0})",
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          )
      ],
    );
  }
}
