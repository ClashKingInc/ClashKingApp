import 'package:flutter/material.dart';

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
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        Column(
          children: [
            Text("Started", style: Theme.of(context).textTheme.titleSmall),
            Text(startTrophies, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        Image.network(
          "https://clashkingfiles.b-cdn.net/icons/Icon_HV_League_Legend_3_Border.png",
          width: 80,
        ),
        Column(children: [
          Text("Ended", style: Theme.of(context).textTheme.titleSmall),
          Text(currentTrophies, style: Theme.of(context).textTheme.titleMedium),
        ]),
      ]),
    );
  }
}

