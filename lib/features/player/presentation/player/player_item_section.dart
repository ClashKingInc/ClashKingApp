import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/features/player/models/player_item.dart';
import 'package:clashkingapp/features/player/models/player_super_troop.dart';
import 'package:clashkingapp/features/player/models/player_equipment.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:shimmer/shimmer.dart';

class PlayerItemSection extends StatelessWidget {
  final String title;
  final List<PlayerItem> items;

  const PlayerItemSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final completionPercentage = _calculateCompletionPercentage();

    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.titleMedium,
                  children: [
                    TextSpan(text: title),
                    if (items[0] is! PlayerSuperTroop) ...[
                      const TextSpan(text: ' | '),
                      TextSpan(
                        text: completionPercentage % 1 == 0
                            ? '${completionPercentage.toInt()}%'
                            : '${completionPercentage.toStringAsFixed(2)}%',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    items.map((item) => _buildItemTile(context, item)).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateCompletionPercentage() {
    final totalPossible =
        items.fold<int>(0, (sum, item) => sum + item.maxLevel);
    if (totalPossible == 0) return 0;
    final totalAchieved = items.fold<int>(0, (sum, item) => sum + item.level);
    return (totalAchieved / totalPossible) * 100;
  }

  Widget _buildItemTile(BuildContext context, PlayerItem item) {
    final isMax = item.level == item.maxLevel;

    // Determine border color
    final borderColor = isMax
        ? const Color(0xFFD4AF37) // Gold if max
        : Theme.of(context).colorScheme.onSurface;

    // Determine background color for equipment rarity
    Color? backgroundColor;
    if (item is PlayerEquipment) {
      backgroundColor = item.rarity == '2' ? Colors.purple : Colors.blue;
    }

    return GestureDetector(
      onTap: () => _showItemDialog(context, item),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(6),
          color: backgroundColor,
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: MobileWebImage(
                imageUrl: item.imageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
            if (item is! PlayerSuperTroop) // No level tag for super troop
              Positioned(
                right: 1,
                bottom: 1,
                child: Container(
                  height: 16,
                  width: 20,
                  decoration: BoxDecoration(
                    color: isMax ? Colors.transparent : Colors.black,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Stack(
                    children: [
                      if (isMax)
                        Shimmer.fromColors(
                          baseColor: const Color(0xFFD4AF37),
                          highlightColor:
                              const Color(0xFFD4AF37).withValues(alpha: 0.7),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          item.level.toString(),
                          style:
                              Theme.of(context).textTheme.labelMedium!.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showItemDialog(BuildContext context, PlayerItem item) {
    final isSuperTroop = item is PlayerSuperTroop;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CachedNetworkImage(
                  errorWidget: (context, url, error) => Icon(Icons.error),
                  imageUrl: item.imageUrl,
                  width: 80,
                  height: 80,
                ),
                const SizedBox(height: 12),
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  isSuperTroop
                      ? (item.superTroopIsActive
                          ? AppLocalizations.of(context)!.active
                          : AppLocalizations.of(context)!.inactive)
                      : AppLocalizations.of(context)
                              ?.level(item.level, item.maxLevel) ??
                          "Level: ${item.level}/${item.maxLevel}",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
