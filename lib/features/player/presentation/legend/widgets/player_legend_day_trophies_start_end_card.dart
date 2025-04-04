import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class LegendTrophiesStartEndCard extends StatelessWidget {
  const LegendTrophiesStartEndCard({
    super.key,
    required this.context,
    required this.startTrophies,
    required this.currentTrophies,
  });

  final BuildContext context;
  final String startTrophies;
  final String currentTrophies;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(left: 8, right: 8, bottom: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        Column(
          children: [
            Text(AppLocalizations.of(context)?.started ?? "Started",
                style: Theme.of(context).textTheme.titleSmall),
            Text(
                NumberFormat(
                        '#,###', Localizations.localeOf(context).toString())
                    .format(int.parse(startTrophies)),
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
          imageUrl:
              "https://assets.clashk.ing/icons/Icon_HV_League_Legend_3_Border.png",
          width: 80,
        ),
        Column(children: [
          Text(AppLocalizations.of(context)?.ended ?? "Ended",
              style: Theme.of(context).textTheme.titleSmall),
          Text(
              NumberFormat('#,###', Localizations.localeOf(context).toString())
                  .format(int.parse(currentTrophies)),
              style: Theme.of(context).textTheme.titleMedium),
        ]),
      ]),
    );
  }
}
