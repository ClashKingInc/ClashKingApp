import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/classes/data/troops_data_manager.dart';

class LegendUsedGearCard extends StatelessWidget {
  const LegendUsedGearCard({
    super.key,
    required this.context,
    required this.itemCounts,
  });

  final BuildContext context;
  final Map<String, int> itemCounts;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(AppLocalizations.of(context)?.heroesEquipments ?? "Heroes Equipments",
                style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 10),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  ...itemCounts.entries.map((entry) {
                    var gearData = TroopDataManager().troopUrlsAndTypes[entry.key];
                    return SizedBox(
                      width: MediaQuery.of(context).size.width / 5 - 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text("${entry.value}",
                            style: Theme.of(context).textTheme.bodyMedium),
                          gearData != null
                            ? CachedNetworkImage(imageUrl: 
                              gearData['url'] ??
                                "https://clashkingfiles.b-cdn.net/clashkinglogo.png",
                              width: 24)
                            : Text("- ${entry.key}"),
                        ],
                      ),
                    );
                  }),
                ],
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
