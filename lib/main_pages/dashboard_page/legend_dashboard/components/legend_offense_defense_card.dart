import 'package:flutter/material.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/legend_functions.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LegendOffenseDefenseCard extends StatelessWidget {
  const LegendOffenseDefenseCard(
      {super.key,
      required this.title,
      required this.list,
      required this.context,
      required this.stats,
      required this.plusMinus,
      required this.icon});

  final String title;
  final List<dynamic> list;
  final BuildContext context;
  final Map<String, dynamic> stats;
  final String plusMinus;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            Text(' ($plusMinus${stats["sum"]})',
                style: Theme.of(context).textTheme.labelLarge),
          ]),
          SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: Align(
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: list.map((item) {
                  if (item is Map) {
                    int change = item['change'];
                    int time = item['time'];
                    String timeAgo = convertToTimeAgo(time, context);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.network(
                              icon,
                              width: 20,
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
                      ],
                    );
                  } else {
                    return Text("$item");
                  }
                }).toList(),
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(AppLocalizations.of(context)?.statistics ?? "Statistics", style: Theme.of(context).textTheme.bodyLarge),
          Text("${AppLocalizations.of(context)?.total ?? "Total"} : ${stats["count"]}/8",
              style: Theme.of(context).textTheme.bodySmall),
          Text('${AppLocalizations.of(context)?.average ?? "Average"} : ${stats["average"].toStringAsFixed(1)}',
              style: Theme.of(context).textTheme.bodySmall),
          Text('${AppLocalizations.of(context)?.remaining ?? "Remaining"} : $plusMinus${stats["remaining"]}',
              style: Theme.of(context).textTheme.bodySmall),
          Text('${plusMinus == "-" ? AppLocalizations.of(context)?.worst ?? "Worst" :  AppLocalizations.of(context)?.best ??"Best"} : $plusMinus${stats["bestPossibleTrophies"]}',
            style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
    );
  }
}
