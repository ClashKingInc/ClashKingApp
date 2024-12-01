import 'package:clashkingapp/classes/profile/legend/legend_day.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/classes/profile/legend/legend_functions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/classes/profile/legend/legend_attack.dart';
import 'package:clashkingapp/classes/profile/legend/legend_defense.dart';

class LegendOffenseDefense extends StatelessWidget {
  const LegendOffenseDefense({
    super.key,
    required this.title,
    required this.list,
    required this.context,
    required this.stats,
    required this.plusMinus,
    required this.icon,
  });

  final String title;
  final List<dynamic> list;
  final BuildContext context;
  final LegendDayStats stats;
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
            Text(' ($plusMinus${stats.sum})',
                style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
        SizedBox(height: 8),
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
            SizedBox(width: 4),
            Text("$plusMinus${stats.average.toStringAsFixed(1)}",
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        SizedBox(height: 8),
        SizedBox(
          child: Align(
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: list.map((item) {
                if (item is Attack || item is Defense) {
                  int change = item.change;
                  int time = item.time;
                  String timeAgo = convertToTimeAgo(time, context);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: CachedNetworkImage(
                                imageUrl: icon,
                                width: 20,
                              ),
                            ),
                            SizedBox(width: 4),
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
                } else {
                  return Text("$item");
                }
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
