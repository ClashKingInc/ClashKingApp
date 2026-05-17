import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/features/player/models/player_item.dart';
import 'package:clashkingapp/features/player/models/player_super_troop.dart';
import 'package:clashkingapp/features/player/models/player_equipment.dart';
import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/player/data/player_item_utils.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:shimmer/shimmer.dart';

class PlayerItemSection extends StatelessWidget {
  final String title;
  final List<PlayerItem> items;
  final int townHallLevel;

  const PlayerItemSection({
    super.key,
    required this.title,
    required this.items,
    required this.townHallLevel,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final completionPercentage = _calculateCompletionPercentage();
    final thPercentage = _calculateTHCompletionPercentage();

    final sortedItems = [...items]..sort((a, b) {
        if (a.isUnlocked == b.isUnlocked) return 0;
        return a.isUnlocked ? -1 : 1; // unlocked en premier
      });

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
                        text: '${_formatPercentage(completionPercentage)}%',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (townHallLevel > 0) ...[
                        TextSpan(
                          text: ' (',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: CachedNetworkImage(
                            imageUrl: ImageAssets.townHall(townHallLevel),
                            width: 16,
                            height: 16,
                          ),
                        ),
                        TextSpan(
                          text: ' ${_formatPercentage(thPercentage)}%)',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sortedItems
                    .map((item) => _buildItemTile(context, item))
                    .toList(),
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

  double _calculateTHCompletionPercentage() {
    int totalPossible = 0;
    int totalAchieved = 0;
    for (final item in items) {
      final thMax = maxLevelForTH(item.meta, townHallLevel);
      if (thMax <= 0) continue;
      totalPossible += thMax;
      totalAchieved += item.level > thMax ? thMax : item.level;
    }
    if (totalPossible == 0) return 0;
    return (totalAchieved / totalPossible) * 100;
  }

  String _formatPercentage(double pct) {
    return pct % 1 == 0
        ? pct.toInt().toString()
        : pct.toStringAsFixed(2);
  }

  Widget _buildItemTile(BuildContext context, PlayerItem item) {
    final isMax = item.level == item.maxLevel;
    final isLocked = !item.isUnlocked;
    final thMaxLevel = maxLevelForTH(item.meta, townHallLevel);
    final isTHMax = thMaxLevel > 0 && item.level >= thMaxLevel && !isMax;

    // Determine border color
    final borderColor = isLocked || item.level == 0
        ? Colors.grey
        : isMax
            ? const Color(0xFFD4AF37) // Gold if overall max
            : isTHMax
                ? const Color(0xFFCD7F32) // Bronze if TH max
                : Theme.of(context).colorScheme.onSurface;

    // Background color for unlocked PlayerEquipment
    Color? backgroundColor;
    if (item is PlayerEquipment && item.isUnlocked) {
      backgroundColor = item.rarity == '2' ? Colors.purple : Colors.blue;
    }

    // Final background depending on locked status
    final containerBackground = isLocked ? Colors.grey[850] : backgroundColor;

    return GestureDetector(
      onTap: () => _showItemDialog(context, item),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(6),
          color: containerBackground,
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: ColorFiltered(
                colorFilter: isLocked || item.level == 0
                    ? const ColorFilter.mode(
                        Colors.grey,
                        BlendMode.saturation,
                      )
                    : const ColorFilter.mode(
                        Colors.transparent,
                        BlendMode.multiply,
                      ),
                child: MobileWebImage(
                  imageUrl: item.imageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            if (item is! PlayerSuperTroop && !isLocked && item.level > 0)
              Positioned(
                right: 1,
                bottom: 1,
                child: Container(
                  height: 16,
                  width: 20,
                  decoration: BoxDecoration(
                    color: (isMax || isTHMax) ? Colors.transparent : Colors.black,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Stack(
                    children: [
                      if (isMax)
                        Shimmer.fromColors(
                          baseColor: const Color(0xFFD4AF37),
                          highlightColor:
                              const Color(0xFFD4AF37).withAlpha(180),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        )
                      else if (isTHMax)
                        Shimmer.fromColors(
                          baseColor: const Color(0xFFCD7F32),
                          highlightColor:
                              const Color(0xFFCD7F32).withAlpha(180),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFCD7F32),
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
    final isEquipment = item is PlayerEquipment;
    final l10n = AppLocalizations.of(context)!;
    final meta = item.meta;
    final description = meta != null
        ? GameDataService.localizedInfoForItem(meta)
        : null;
    final localizedName = meta != null
        ? GameDataService.localizedNameForItem(meta)
        : item.name;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CachedNetworkImage(
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                      imageUrl: item.imageUrl,
                      width: 80,
                      height: 80,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      localizedName,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isSuperTroop
                          ? (item.superTroopIsActive
                              ? l10n.generalActive
                              : l10n.generalInactive)
                          : l10n.gameLevel(item.level, item.maxLevel),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (description != null && description.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1),
                      ),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withAlpha(200),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (meta != null && !isSuperTroop) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1),
                      ),
                      if (isEquipment) ...[
                        if (meta['hero'] != null)
                          _buildStatRow(
                            context,
                            icon: Icons.person,
                            label: l10n.gameItemHero,
                            value: meta['hero'].toString(),
                          ),
                        if (meta['rarity_label'] != null)
                          _buildRarityRow(context, l10n, meta),
                      ] else ...[
                        if (meta['housing_space'] != null)
                          _buildStatRow(
                            context,
                            icon: Icons.home_outlined,
                            label: l10n.gameItemHousingSpace,
                            value: meta['housing_space'].toString(),
                          ),
                        if (meta['attack_speed'] != null)
                          _buildStatRow(
                            context,
                            icon: Icons.speed_outlined,
                            label: l10n.gameItemAttackSpeed,
                            value:
                                '${((meta['attack_speed'] as num) / 1000).toStringAsFixed(1)}s',
                          ),
                        if (meta['attack_range'] != null)
                          _buildStatRow(
                            context,
                            icon: Icons.my_location_outlined,
                            label: l10n.gameItemAttackRange,
                            value: meta['attack_range'].toString(),
                          ),
                        if (meta['movement_speed'] != null)
                          _buildStatRow(
                            context,
                            icon: Icons.directions_run_outlined,
                            label: l10n.gameItemMovementSpeed,
                            value: meta['movement_speed'].toString(),
                          ),
                        if (meta['upgrade_resource'] != null)
                          _buildStatRow(
                            context,
                            icon: Icons.water_drop_outlined,
                            label: l10n.gameItemUpgradeResource,
                            value: meta['upgrade_resource'].toString(),
                          ),
                      ],
                    ],
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.generalOk),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRarityRow(
    BuildContext context,
    AppLocalizations l10n,
    Map<String, dynamic> meta,
  ) {
    final rarityLabel = meta['rarity_label']?.toString() ?? '';
    final isEpic = meta['rarity']?.toString() == '2';
    final color = isEpic ? Colors.purple : Colors.blue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(Icons.diamond_outlined,
              size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.gameItemRarity,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withAlpha(40),
              border: Border.all(color: color, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              rarityLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
