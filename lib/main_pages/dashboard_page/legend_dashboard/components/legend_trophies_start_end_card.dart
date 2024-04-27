import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
            Text(AppLocalizations.of(context)?.started ?? "Started", style: Theme.of(context).textTheme.titleSmall),
            Text(startTrophies, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        Image.network(
          "https://clashkingfiles.b-cdn.net/icons/Icon_HV_League_Legend_3_Border.png",
          width: 80,
        ),
        Column(children: [
          Text(AppLocalizations.of(context)?.ended ?? "Ended", style: Theme.of(context).textTheme.titleSmall),
          Text(currentTrophies, style: Theme.of(context).textTheme.titleMedium),
        ]),
      ]),
    );
  }
}

