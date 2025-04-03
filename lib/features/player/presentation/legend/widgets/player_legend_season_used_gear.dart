import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/features/player/models/player_equipment.dart';

class PlayerLegendSeasonUsedGear extends StatelessWidget {
  const PlayerLegendSeasonUsedGear({
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
    final localizations = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(localizations?.heroesEquipments ?? "Heroes Equipments",
              style: Theme.of(context).textTheme.bodyMedium),
          SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: gears.map((gear) {
              final isMaxLevel = gear.level == gear.maxLevel;
              final count = usageCount[gear.name] ?? 1;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl: gear.imageUrl,
                        width: 35,
                        height: 35,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        right: 1,
                        bottom: 1,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isMaxLevel
                                ? const Color(0xFFD4AF37)
                                : Colors.black.withValues(alpha : 0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            gear.level.toString(),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Colors.white,
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
    );
  }
}
