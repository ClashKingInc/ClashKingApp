import 'package:flutter/material.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/features/player/models/player_super_troop.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';

class PlayerSuperTroopSection extends StatelessWidget {
  final List<PlayerSuperTroop> superTroops;
  final EdgeInsetsGeometry margin;

  const PlayerSuperTroopSection({
    super.key,
    required this.superTroops,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
  });

  @override
  Widget build(BuildContext context) {
    final activeTroops = superTroops
        .where((t) => t.superTroopIsActive)
        .toList();

    if (activeTroops.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          color:
              Theme.of(context).cardTheme.color ??
              Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.32),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            children: [
              Text(
                AppLocalizations.of(context)!.gameActiveSuperTroops,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: activeTroops
                    .map(
                      (troop) => ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: MobileWebImage(
                          placeholder: (context, url) =>
                              CircularProgressIndicator(),
                          errorWidget: (context, url, error) =>
                              Icon(Icons.error),
                          imageUrl: troop.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
