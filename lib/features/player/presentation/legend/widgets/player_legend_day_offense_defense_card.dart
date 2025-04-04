import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LegendOffenseDefenseCard extends StatelessWidget {
  const LegendOffenseDefenseCard({
    super.key,
    required this.title,
    required this.list,
    required this.context,
    required this.totalCount,
    required this.totalTrophies,
    required this.plusMinus,
    required this.icon,
  });

  final String title;
  final List<int> list;
  final BuildContext context;
  final int totalCount;
  final int totalTrophies;
  final String plusMinus;
  final String icon;

  @override
  Widget build(BuildContext context) {
    double average = list.isEmpty ? 0 : totalTrophies / totalCount;
    int remaining = 8 - totalCount;
    int bestPossible = totalTrophies.abs() + (remaining * 40);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  Text(' ($plusMinus$totalTrophies)',
                      style: Theme.of(context).textTheme.labelLarge),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 180,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: list.map((change) {
                      return Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                                imageUrl: icon,
                                width: 20,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$plusMinus$change',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context)?.statistics ?? "Statistics",
                  style: Theme.of(context).textTheme.bodyLarge),
              Text(
                  "${AppLocalizations.of(context)?.total ?? "Total"} : $totalCount/8",
                  style: Theme.of(context).textTheme.bodySmall),
              Text(
                  '${AppLocalizations.of(context)?.average ?? "Average"} : ${average.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.bodySmall),
              Text(
                  '${AppLocalizations.of(context)?.remaining ?? "Remaining"} : $remaining',
                  style: Theme.of(context).textTheme.bodySmall),
              Text(
                  '${plusMinus == "-" ? AppLocalizations.of(context)?.worst ?? "Worst" : AppLocalizations.of(context)?.best ?? "Best"} : $bestPossible',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}