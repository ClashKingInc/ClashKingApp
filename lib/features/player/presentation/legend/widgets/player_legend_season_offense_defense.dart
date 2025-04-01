import 'package:clashkingapp/features/player/models/player_legend_attack.dart';
import 'package:clashkingapp/features/player/models/player_legend_stats.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PlayerLegendOffenseDefense extends StatelessWidget {
  const PlayerLegendOffenseDefense({
    super.key,
    required this.title,
    required this.list,
    required this.context,
    required this.sum,
    required this.average,
    required this.plusMinus,
    required this.icon,
  });

  final String title;
  final List<PlayerLegendAttack> list;
  final BuildContext context;
  final int sum;
  final double average;
  final String plusMinus;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
            Text(' ($plusMinus$sum)',
                style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
            const SizedBox(width: 4),
            Text("$plusMinus${average.toStringAsFixed(1)}",
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          child: Align(
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: list.map((attack) {
                final int change = attack.change;
                final int time = attack.time;
                final String timeAgo = PlayerLegendStats.convertToTimeAgo(time, context);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: CachedNetworkImage(
                              imageUrl: icon,
                              width: 20,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$plusMinus$change',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            " ($timeAgo)",
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
