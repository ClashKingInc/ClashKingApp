import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/features/player/models/player_equipment.dart';

class LegendUsedGearCard extends StatelessWidget {
  const LegendUsedGearCard({
    super.key,
    required this.context,
    required this.gears,
    required this.usageCount,
  });

  final BuildContext context;
  final List<PlayerEquipment> gears;
  final Map<String, int> usageCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context)?.heroesEquipments ?? "Heroes Equipments",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: gears.map((gear) {
                  final isMaxLevel = gear.level == gear.maxLevel;
                  final count = usageCount[gear.name] ?? 1;

                  return Column(
                    children: [
                      Stack(
                        children: [
                          CachedNetworkImage(
                            imageUrl: gear.imageUrl,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            right: 1,
                            bottom: 1,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: isMaxLevel ? const Color(0xFFD4AF37) : Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                gear.level.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text("x$count",
                          style: Theme.of(context).textTheme.labelSmall),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}