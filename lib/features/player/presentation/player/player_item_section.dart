import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/features/player/models/player_item.dart';
import 'package:clashkingapp/features/player/models/player_super_troop.dart';
import 'package:clashkingapp/features/player/models/player_equipment.dart';
import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:clashkingapp/features/player/data/player_item_utils.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';

const String _resourceGold = '${ImageAssets.baseUrl}/resources/gold.webp';
const String _resourceElixir = '${ImageAssets.baseUrl}/resources/elixir.webp';
const String _resourceDarkElixir =
    '${ImageAssets.baseUrl}/resources/dark_elixir.webp';
const String _resourceBuilderGold =
    '${ImageAssets.baseUrl}/resources/builder_gold.webp';
const String _resourceBuilderElixir =
    '${ImageAssets.baseUrl}/resources/builder_elixir.webp';
const String _resourceShinyOre =
    '${ImageAssets.baseUrl}/resources/shiny_ore.webp';
const String _resourceGlowyOre =
    '${ImageAssets.baseUrl}/resources/glowy_ore.webp';
const String _resourceStarryOre =
    '${ImageAssets.baseUrl}/resources/starry_ore.webp';

class PlayerItemSection extends StatefulWidget {
  final String title;
  final List<PlayerItem> items;
  final int townHallLevel;
  final bool initiallyExpanded;

  const PlayerItemSection({
    super.key,
    required this.title,
    required this.items,
    required this.townHallLevel,
    this.initiallyExpanded = false,
  });

  @override
  State<PlayerItemSection> createState() => _PlayerItemSectionState();
}

class _PlayerItemSectionState extends State<PlayerItemSection> {
  late bool _expanded;

  List<PlayerItem> get items => widget.items;
  int get townHallLevel => widget.townHallLevel;
  String get title => widget.title;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final thPercentage = _calculateTHCompletionPercentage();
    final remainingSummary = _calculateRemainingSummary();
    final sortedItems = _expanded
        ? ([...items]..sort((a, b) {
            if (a.isUnlocked == b.isUnlocked) return 0;
            return a.isUnlocked ? -1 : 1;
          }))
        : const <PlayerItem>[];

    return SizedBox(
      width: double.infinity,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ??
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      AnimatedRotation(
                        turns: _expanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 160),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 22,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.72),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (items[0] is! PlayerSuperTroop)
                        _TownHallMaxBadge(
                          percentage: thPercentage,
                          formattedPercentage: _formatPercentage(thPercentage),
                          summary: remainingSummary,
                          townHallLevel: townHallLevel,
                        ),
                    ],
                  ),
                ),
              ),
              if (_expanded) ...[
                const SizedBox(height: 12),
                Center(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: sortedItems
                        .map((item) => _buildItemTile(context, item))
                        .toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemTile(BuildContext context, PlayerItem item) {
    final isLocked = !item.isUnlocked;
    final thMaxLevel = maxLevelForTH(item.meta, townHallLevel);
    final isTHMax = thMaxLevel > 0 && item.level >= thMaxLevel;
    final isHighlightedMax = isTHMax;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color borderColor;
    if (isLocked || item.level == 0) {
      borderColor = Colors.grey;
    } else if (isHighlightedMax) {
      borderColor = const Color(0xFFFFD75E);
    } else {
      borderColor = isDark
          ? Colors.white.withValues(alpha: 0.88)
          : Colors.black87;
    }

    Color? backgroundColor;
    if (item is PlayerEquipment && item.isUnlocked) {
      backgroundColor = item.rarity == '2' ? Colors.purple : Colors.blue;
    }

    final containerBackground = isLocked ? Colors.grey[850] : backgroundColor;

    return GestureDetector(
      onTap: () => _showItemDialog(context, item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          border: Border.all(
            color: borderColor,
            width: isHighlightedMax ? 2.5 : 2,
          ),
          borderRadius: BorderRadius.circular(8),
          color: containerBackground,
          boxShadow: isHighlightedMax
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD75E).withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: ColorFiltered(
                colorFilter: isLocked || item.level == 0
                    ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                    : const ColorFilter.mode(
                        Colors.transparent,
                        BlendMode.multiply,
                      ),
                child: MobileWebImage(
                  imageUrl: item.imageUrl,
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            if (item is! PlayerSuperTroop && !isLocked && item.level > 0)
              Positioned(
                right: 1,
                bottom: 1,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 24),
                  height: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isHighlightedMax
                        ? const Color(0xFFFFD75E)
                        : Colors.black.withValues(alpha: 0.86),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      item.level.toString(),
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        fontWeight: FontWeight.w900,
                        color: isHighlightedMax ? Colors.black : Colors.white,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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

  _RemainingSummary _calculateRemainingSummary() {
    final costs = <String, num>{};
    var totalSeconds = 0;

    for (final item in items) {
      final meta = item.meta;
      final thMax = maxLevelForTH(meta, townHallLevel);
      if (meta == null || thMax <= 0 || item.level >= thMax) continue;

      final firstUpgradeLevel = item.level <= 0 ? 1 : item.level;
      for (var level = firstUpgradeLevel; level < thMax; level++) {
        final stats = _findLevelStats(meta, level);
        if (stats == null) continue;

        final upgradeTime = (stats['upgrade_time'] as num?)?.toInt() ?? 0;
        totalSeconds += upgradeTime;

        final upgradeCost = stats['upgrade_cost'];
        if (upgradeCost is Map) {
          for (final entry in upgradeCost.entries) {
            final amount = entry.value is num ? entry.value as num : 0;
            if (amount <= 0) continue;
            final key = _normalizeResource(entry.key.toString());
            costs[key] = (costs[key] ?? 0) + amount;
          }
        } else {
          final amount = upgradeCost is num ? upgradeCost : 0;
          if (amount <= 0) continue;
          final key = _normalizeResource(
            meta['upgrade_resource']?.toString() ?? 'resource',
          );
          costs[key] = (costs[key] ?? 0) + amount;
        }
      }
    }

    final resources =
        costs.entries
            .map((entry) => _ResourceAmount(entry.key, entry.value))
            .where((resource) => resource.amount > 0)
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));

    return _RemainingSummary(seconds: totalSeconds, resources: resources);
  }

  String _formatPercentage(double pct) {
    return pct % 1 == 0 ? pct.toInt().toString() : pct.toStringAsFixed(2);
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
    final thMaxLevel = maxLevelForTH(meta, townHallLevel);
    final availableMaxLevel = thMaxLevel > 0 ? thMaxLevel : item.maxLevel;
    final nextUpgradeStats = (item.level > 0 && item.level < availableMaxLevel)
        ? currentLevelStats
        : null;
    final currentDps = (currentLevelStats?['dps'] as num?)?.toInt() ?? 0;
    final currentHp = (currentLevelStats?['hitpoints'] as num?)?.toInt() ?? 0;
    final currentHeal =
        (currentLevelStats?['heal_on_activation'] as num?)?.toInt() ?? 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(200),
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
                    if (nextUpgradeStats != null) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1),
                      ),
                      _buildUpgradeCostRow(
                        context,
                        meta!,
                        nextUpgradeStats,
                        l10n,
                      ),
                      if ((nextUpgradeStats['upgrade_time'] as num? ?? 0) > 0)
                        _buildStatRow(
                          context,
                          icon: Icons.timer_outlined,
                          label: l10n.gameItemUpgradeTime,
                          value: _formatUpgradeTime(
                            (nextUpgradeStats['upgrade_time'] as num).toInt(),
                          ),
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
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
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
          Icon(
            Icons.diamond_outlined,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
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
          Icon(
            Icons.gps_fixed_outlined,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
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
                _buildTargetChip(
                  context,
                  l10n.gameItemTargetsGround,
                  Colors.green,
                ),
              if (isAir)
                _buildTargetChip(context, l10n.gameItemTargetsAir, Colors.blue),
              if (isFlying)
                _buildTargetChip(
                  context,
                  l10n.gameItemFlying,
                  Colors.lightBlue,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTargetChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildUpgradeCostRow(
    BuildContext context,
    Map<String, dynamic> meta,
    Map<String, dynamic> upgradeStats,
    AppLocalizations l10n,
  ) {
    final resources = _resourcesFromUpgradeCost(meta, upgradeStats);
    if (resources.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.upgrade_outlined,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.gameItemUpgradeCost,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Flexible(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var index = 0; index < resources.length; index++) ...[
                      if (index > 0) const SizedBox(width: 5),
                      _ResourceCostChip(
                        resource: resources[index],
                        compact: true,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_ResourceAmount> _resourcesFromUpgradeCost(
    Map<String, dynamic> meta,
    Map<String, dynamic> upgradeStats,
  ) {
    final costs = <String, num>{};
    final upgradeCost = upgradeStats['upgrade_cost'];

    if (upgradeCost is Map) {
      for (final entry in upgradeCost.entries) {
        final amount = entry.value is num ? entry.value as num : 0;
        if (amount <= 0) continue;
        final key = _normalizeResource(entry.key.toString());
        costs[key] = (costs[key] ?? 0) + amount;
      }
    } else {
      final amount = upgradeCost is num ? upgradeCost : 0;
      if (amount > 0) {
        final key = _normalizeResource(
          meta['upgrade_resource']?.toString() ?? 'resource',
        );
        costs[key] = (costs[key] ?? 0) + amount;
      }
    }

    return costs.entries
        .map((entry) => _ResourceAmount(entry.key, entry.value))
        .where((resource) => resource.amount > 0)
        .toList()
      ..sort(
        (a, b) =>
            _resourceSortWeight(a.key).compareTo(_resourceSortWeight(b.key)),
      );
  }

  int _resourceSortWeight(String key) {
    if (key.contains('gold') && !key.contains('builder')) return 0;
    if (key.contains('elixir') && !key.contains('dark')) return 1;
    if (key.contains('dark')) return 2;
    if (key.contains('builder') && key.contains('gold')) return 3;
    if (key.contains('builder') && key.contains('elixir')) return 4;
    if (key.contains('shiny')) return 5;
    if (key.contains('glowy')) return 6;
    if (key.contains('starry')) return 7;
    return 99;
  }

  static Map<String, dynamic>? _findLevelStats(
    Map<String, dynamic>? meta,
    int level,
  ) {
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

  static String _normalizeResource(String value) {
    return value.trim().toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
  }
}

class _TownHallMaxBadge extends StatelessWidget {
  final double percentage;
  final String formattedPercentage;
  final _RemainingSummary summary;
  final int townHallLevel;

  const _TownHallMaxBadge({
    required this.percentage,
    required this.formattedPercentage,
    required this.summary,
    required this.townHallLevel,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = percentage >= 100;
    const gold = Color(0xFFFFD75E);

    return Tooltip(
      message: 'Tap for remaining upgrade cost and time',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => _showRemainingSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: isComplete
                  ? gold.withValues(alpha: 0.14)
                  : Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.55,
                    ),
            ),
            child: Text(
              '$formattedPercentage%',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: isComplete
                    ? gold
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showRemainingSheet(BuildContext context) {
    final isComplete = percentage >= 100;

    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 420,
              maxHeight: MediaQuery.of(context).size.height * 0.72,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '$formattedPercentage% Maxed for TH$townHallLevel',
                            maxLines: 1,
                            softWrap: false,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).closeButtonTooltip,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (isComplete)
                    Text(
                      'This section is maxed for TH$townHallLevel.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  else ...[
                    const _PopupLabel(text: 'Time Remaining:'),
                    const SizedBox(height: 6),
                    _RemainingRow(
                      icon: Icons.schedule_rounded,
                      iconColor: Theme.of(context).colorScheme.primary,
                      value: _PlayerItemSectionState._formatUpgradeTime(
                        summary.seconds,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _PopupLabel(text: 'Resources:'),
                    const SizedBox(height: 6),
                    if (summary.resources.isEmpty)
                      Text(
                        'No resource data',
                        style: Theme.of(context).textTheme.bodyMedium,
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: summary.resources
                            .map(
                              (resource) =>
                                  _ResourceCostChip(resource: resource),
                            )
                            .toList(),
                      ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RemainingSummary {
  final int seconds;
  final List<_ResourceAmount> resources;

  const _RemainingSummary({required this.seconds, required this.resources});
}

class _PopupLabel extends StatelessWidget {
  final String text;

  const _PopupLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
    );
  }
}

class _ResourceAmount {
  final String key;
  final num amount;

  const _ResourceAmount(this.key, this.amount);
}

class _RemainingRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;

  const _RemainingRow({
    required this.icon,
    required this.iconColor,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Text(
          value.isEmpty ? 'No time data' : value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _ResourceCostChip extends StatelessWidget {
  final _ResourceAmount resource;
  final bool compact;

  const _ResourceCostChip({required this.resource, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final visual = _ResourceVisual.forKey(resource.key);

    return Tooltip(
      message: visual.label,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : 9,
          vertical: compact ? 5 : 7,
        ),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MobileWebImage(
              imageUrl: visual.imageUrl,
              width: compact ? 17 : 20,
              height: compact ? 17 : 20,
            ),
            SizedBox(width: compact ? 4 : 6),
            Text(
              _PlayerItemSectionState._formatLargeNumber(resource.amount),
              style:
                  (compact
                          ? Theme.of(context).textTheme.labelMedium
                          : Theme.of(context).textTheme.labelLarge)
                      ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResourceVisual {
  final String label;
  final String imageUrl;

  const _ResourceVisual({required this.label, required this.imageUrl});

  factory _ResourceVisual.forKey(String key) {
    if (key.contains('dark')) {
      return const _ResourceVisual(
        label: 'Dark Elixir',
        imageUrl: _resourceDarkElixir,
      );
    }
    if (key.contains('builder') && key.contains('elixir')) {
      return const _ResourceVisual(
        label: 'Builder Elixir',
        imageUrl: _resourceBuilderElixir,
      );
    }
    if (key.contains('builder') && key.contains('gold')) {
      return const _ResourceVisual(
        label: 'Builder Gold',
        imageUrl: _resourceBuilderGold,
      );
    }
    if (key.contains('elixir')) {
      return const _ResourceVisual(label: 'Elixir', imageUrl: _resourceElixir);
    }
    if (key.contains('gold')) {
      return const _ResourceVisual(label: 'Gold', imageUrl: _resourceGold);
    }
    if (key.contains('glowy')) {
      return const _ResourceVisual(
        label: 'Glowy Ore',
        imageUrl: _resourceGlowyOre,
      );
    }
    if (key.contains('starry')) {
      return const _ResourceVisual(
        label: 'Starry Ore',
        imageUrl: _resourceStarryOre,
      );
    }
    if (key.contains('shiny')) {
      return const _ResourceVisual(
        label: 'Shiny Ore',
        imageUrl: _resourceShinyOre,
      );
    }
    return const _ResourceVisual(
      label: 'Resource',
      imageUrl: ImageAssets.defaultImage,
    );
  }
}
