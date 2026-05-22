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
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: CachedNetworkImage(
                          imageUrl: ImageAssets.townHall(townHallLevel),
                          width: 16,
                          height: 16,
                        ),
                      ),
                      TextSpan(
                        text: ' ${_formatPercentage(thPercentage)}%',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const TextSpan(text: ' | '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: CachedNetworkImage(
                          imageUrl: ImageAssets.townHall(
                              GameDataService.getMaxTownHallLevel()),
                          width: 16,
                          height: 16,
                        ),
                      ),
                      TextSpan(
                        text: ' ${_formatPercentage(completionPercentage)}%',
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
    final Color borderColor;
    if (isLocked || item.level == 0) {
      borderColor = Colors.grey;
    } else if (isMax) {
      borderColor = const Color(0xFFD4AF37); // Gold if overall max
    } else if (isTHMax) {
      borderColor = const Color(0xFFCD7F32); // Bronze if TH max
    } else {
      borderColor = Theme.of(context).colorScheme.onSurface;
    }

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

    // Level-based stats
    final effectiveLevel = item.level > 0 ? item.level : 1;
    final currentLevelStats = _findLevelStats(meta, effectiveLevel);
    final nextLevelStats = (item.level > 0 && item.level < item.maxLevel)
        ? _findLevelStats(meta, item.level + 1)
        : null;
    final currentDps = (currentLevelStats?['dps'] as num?)?.toInt() ?? 0;
    final currentHp = (currentLevelStats?['hitpoints'] as num?)?.toInt() ?? 0;
    final currentHeal =
        (currentLevelStats?['heal_on_activation'] as num?)?.toInt() ?? 0;

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
                      // Level-based stats
                      if (currentDps > 0)
                        _buildStatRow(
                          context,
                          icon: Icons.bolt_outlined,
                          label: l10n.gameItemDps,
                          value: currentDps.toString(),
                        ),
                      if (!isEquipment && currentHp > 0)
                        _buildStatRow(
                          context,
                          icon: Icons.favorite_border,
                          label: l10n.gameItemHitpoints,
                          value: currentHp.toString(),
                        ),
                      if (isEquipment && currentHeal > 0)
                        _buildStatRow(
                          context,
                          icon: Icons.healing,
                          label: l10n.gameItemHealOnActivation,
                          value: currentHeal.toString(),
                        ),
                      // Targeting (non-equipment only)
                      if (!isEquipment &&
                          (meta['is_air_targeting'] != null ||
                              meta['is_ground_targeting'] != null))
                        _buildTargetingRow(context, meta, l10n),
                    ],
                    if (nextLevelStats != null) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1),
                      ),
                      _buildUpgradeCostRow(
                          context, meta!, isEquipment, nextLevelStats, l10n),
                      if ((nextLevelStats['upgrade_time'] as num? ?? 0) > 0)
                        _buildStatRow(
                          context,
                          icon: Icons.timer_outlined,
                          label: l10n.gameItemUpgradeTime,
                          value: _formatUpgradeTime(
                              (nextLevelStats['upgrade_time'] as num).toInt()),
                        ),
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

  Widget _buildTargetingRow(
    BuildContext context,
    Map<String, dynamic> meta,
    AppLocalizations l10n,
  ) {
    final isGround = meta['is_ground_targeting'] == true;
    final isAir = meta['is_air_targeting'] == true;
    final isFlying = meta['is_flying'] == true;

    if (!isGround && !isAir && !isFlying) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(Icons.gps_fixed_outlined,
              size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.gameItemTargets,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Wrap(
            spacing: 4,
            children: [
              if (isGround)
                _buildTargetChip(context, l10n.gameItemTargetsGround,
                    Colors.green),
              if (isAir)
                _buildTargetChip(
                    context, l10n.gameItemTargetsAir, Colors.blue),
              if (isFlying)
                _buildTargetChip(
                    context, l10n.gameItemFlying, Colors.lightBlue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTargetChip(
      BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildUpgradeCostRow(
    BuildContext context,
    Map<String, dynamic> meta,
    bool isEquipment,
    Map<String, dynamic> nextLevelStats,
    AppLocalizations l10n,
  ) {
    final String costText;
    if (isEquipment) {
      final cost = nextLevelStats['upgrade_cost'];
      if (cost is Map) {
        final parts = <String>[];
        final shiny = (cost['shiny_ore'] as num? ?? 0).toInt();
        final glowy = (cost['glowy_ore'] as num? ?? 0).toInt();
        final starry = (cost['starry_ore'] as num? ?? 0).toInt();
        if (shiny > 0) parts.add('$shiny Shiny');
        if (glowy > 0) parts.add('$glowy Glowy');
        if (starry > 0) parts.add('$starry Starry');
        costText = parts.join(' · ');
      } else {
        costText = '';
      }
    } else {
      final cost = (nextLevelStats['upgrade_cost'] as num? ?? 0);
      if (cost <= 0) return const SizedBox.shrink();
      final resource = meta['upgrade_resource']?.toString() ?? '';
      costText = '${_formatLargeNumber(cost)} $resource'.trim();
    }

    if (costText.isEmpty) return const SizedBox.shrink();
    return _buildStatRow(
      context,
      icon: Icons.upgrade_outlined,
      label: l10n.gameItemUpgradeCost,
      value: costText,
    );
  }

  static Map<String, dynamic>? _findLevelStats(
      Map<String, dynamic>? meta, int level) {
    if (meta == null) return null;
    final levels = meta['levels'];
    if (levels is! List) return null;
    for (final entry in levels) {
      if (entry is Map && entry['level'] == level) {
        return Map<String, dynamic>.from(entry);
      }
    }
    return null;
  }

  static String _formatUpgradeTime(int seconds) {
    if (seconds <= 0) return '';
    final d = seconds ~/ 86400;
    final h = (seconds % 86400) ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (d > 0) return h > 0 ? '${d}d ${h}h' : '${d}d';
    if (h > 0) return m > 0 ? '${h}h ${m}m' : '${h}h';
    final s = seconds % 60;
    if (m > 0) return s > 0 ? '${m}m ${s}s' : '${m}m';
    return '${s}s';
  }

  static String _formatLargeNumber(num value) {
    if (value >= 1000000) {
      final formatted = (value / 1000000).toStringAsFixed(1);
      return '${formatted.endsWith('.0') ? formatted.replaceAll('.0', '') : formatted}M';
    }
    if (value >= 1000) {
      final formatted = (value / 1000).toStringAsFixed(1);
      return '${formatted.endsWith('.0') ? formatted.replaceAll('.0', '') : formatted}K';
    }
    return value.toInt().toString();
  }
}
