import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/features/player/models/player_super_troop.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';

class PlayerSuperTroopSection extends StatelessWidget {
  final List<PlayerSuperTroop> superTroops;

  const PlayerSuperTroopSection({super.key, required this.superTroops});

  @override
  Widget build(BuildContext context) {
    final activeTroops =
        superTroops.where((t) => t.superTroopIsActive).toList();

    if (activeTroops.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                AppLocalizations.of(context)!.activeSuperTroops,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: activeTroops
                    .map((troop) => ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
                            placeholder: (context, url) =>
                                CircularProgressIndicator(),
                            errorWidget: (context, url, error) =>
                                Icon(Icons.error),
                            imageUrl: troop.imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
