import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/collapsible_item_section.dart';
import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/features/player/models/player_item.dart';
import 'package:clashkingapp/features/player/models/player_super_troop.dart';
import 'package:clashkingapp/features/player/models/player_equipment.dart';
import 'package:clashkingapp/features/player/models/player_pet.dart';
import 'package:clashkingapp/features/player/models/player_siege_machine.dart';
import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:clashkingapp/features/player/data/player_item_utils.dart';
import 'package:clashkingapp/features/upgrade_tracker/models/upgrade_tracker_models.dart';
import 'package:clashkingapp/features/upgrade_tracker/presentation/upgrade_tracker_page.dart';
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
  late double _thPercentage;
  late _RemainingSummary _remainingSummary;
  late List<PlayerItem> _sortedItems;

  List<PlayerItem> get items => widget.items;
  int get townHallLevel => widget.townHallLevel;
  String get title => widget.title;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _recalculateSectionSummary();
  }

  @override
  void didUpdateWidget(covariant PlayerItemSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.items, widget.items) ||
        oldWidget.townHallLevel != widget.townHallLevel) {
      _recalculateSectionSummary();
    }
  }

  void _recalculateSectionSummary() {
    _thPercentage = _calculateTHCompletionPercentage();
    _remainingSummary = _calculateRemainingSummary();
    _sortedItems = [...items]
      ..sort((a, b) {
        if (a.isUnlocked == b.isUnlocked) return 0;
        return a.isUnlocked ? -1 : 1;
      });
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return CollapsibleItemSection(
      title: title,
      expanded: _expanded,
      onToggle: () => setState(() => _expanded = !_expanded),
      trailing: items[0] is PlayerSuperTroop
          ? null
          : _TownHallMaxBadge(
              percentage: _thPercentage,
              formattedPercentage: _formatPercentage(_thPercentage),
              summary: _remainingSummary,
              townHallLevel: townHallLevel,
            ),
      child: CompactItemGrid(
        itemCount: _sortedItems.length,
        itemBuilder: (context, index, size) =>
            _buildItemTile(context, _sortedItems[index], size),
      ),
    );
  }

  Widget _buildItemTile(BuildContext context, PlayerItem item, double size) {
    final isLocked = !item.isUnlocked;
    final thMaxLevel = maxLevelForItemAtTH(item, townHallLevel);
    final isTHMax = thMaxLevel > 0 && item.level >= thMaxLevel;
    final isGlobalMax = item.maxLevel > 0 && item.level >= item.maxLevel;
    final isHighlightedMax = isGlobalMax || isTHMax;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color borderColor;
    if (isLocked || item.level == 0) {
      borderColor = Colors.grey;
    } else if (isGlobalMax) {
      borderColor = const Color(0xFFFFD75E);
    } else if (isTHMax) {
      borderColor = const Color(0xFFCD7F32);
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
        width: size,
        height: size,
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
                    color: borderColor.withValues(alpha: 0.2),
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
                  width: size,
                  height: size,
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
                        ? borderColor
                        : Colors.black.withValues(alpha: 0.86),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      item.level.toString(),
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isGlobalMax ? Colors.black : Colors.white,
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
      final thMax = maxLevelForItemAtTH(item, townHallLevel);
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
      final thMax = maxLevelForItemAtTH(item, townHallLevel);
      final summary = calculateRemainingUpgradeSummary(
        item,
        targetLevel: thMax,
      );
      totalSeconds += summary.seconds;
      for (final resource in summary.resources) {
        costs[resource.key] = (costs[resource.key] ?? 0) + resource.amount;
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
    if (!isSuperTroop) {
      showUpgradeDetails(context, _upgradeDetailsItem(item));
      return;
    }
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
    final currentLevelStats = findLevelStats(meta, effectiveLevel);
    final thMaxLevel = maxLevelForItemAtTH(item, townHallLevel);
    final availableMaxLevel = thMaxLevel > 0 ? thMaxLevel : item.maxLevel;
    final nextUpgradeStats = (item.level > 0 && item.level < availableMaxLevel)
        ? currentLevelStats
        : null;
    final thRemainingSummary = calculateRemainingUpgradeSummary(
      item,
      targetLevel: availableMaxLevel,
    );
    final globalRemainingSummary = calculateRemainingUpgradeSummary(
      item,
      targetLevel: item.maxLevel,
    );
    final currentDps = (currentLevelStats?['dps'] as num?)?.toInt() ?? 0;
    final currentHp = (currentLevelStats?['hitpoints'] as num?)?.toInt() ?? 0;
    final currentHeal =
        (currentLevelStats?['heal_on_activation'] as num?)?.toInt() ?? 0;
    final accentColor = _itemAccentColor(context, item);
    var statsExpanded = false;

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final colorScheme = Theme.of(context).colorScheme;
            return Dialog(
              insetPadding: EdgeInsets.zero,
              backgroundColor: colorScheme.surface,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.9,
                ),
                child: SingleChildScrollView(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          accentColor.withValues(alpha: 0.16),
                          colorScheme.surface,
                          colorScheme.surface,
                        ],
                        stops: const [0, 0.34, 1],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildItemDialogHero(
                          context,
                          item: item,
                          title: localizedName,
                          subtitle: isSuperTroop
                              ? (item.superTroopIsActive
                                    ? l10n.generalActive
                                    : l10n.generalInactive)
                              : l10n.gameLevel(item.level, item.maxLevel),
                          accentColor: accentColor,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isSuperTroop &&
                                  description != null &&
                                  description.isNotEmpty) ...[
                                _buildDialogSection(
                                  context,
                                  title: l10n.gameItemOverview,
                                  icon: Icons.notes_rounded,
                                  child: Text(
                                    description,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                          height: 1.35,
                                          fontWeight: FontWeight.w500,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                              if (!isSuperTroop &&
                                  (nextUpgradeStats != null ||
                                      thRemainingSummary.levelsRemaining > 0 ||
                                      globalRemainingSummary.levelsRemaining >
                                          0)) ...[
                                _buildDialogSection(
                                  context,
                                  title: l10n.gameItemUpgradePlan,
                                  icon: Icons.route_rounded,
                                  prominent: true,
                                  accentColor: accentColor,
                                  child: _buildUpgradeHighlights(
                                    context,
                                    nextUpgradeStats: nextUpgradeStats,
                                    meta: meta,
                                    thSummary: thRemainingSummary,
                                    globalSummary: globalRemainingSummary,
                                    accentColor: accentColor,
                                    l10n: l10n,
                                  ),
                                ),
                              ],
                              if (isSuperTroop &&
                                  description != null &&
                                  description.isNotEmpty) ...[
                                _buildDialogSection(
                                  context,
                                  title: l10n.gameItemOverview,
                                  icon: Icons.notes_rounded,
                                  child: Text(
                                    description,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                          height: 1.35,
                                          fontWeight: FontWeight.w500,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                              if (meta != null && !isSuperTroop) ...[
                                _buildDialogSection(
                                  context,
                                  title: l10n.gameItemStats,
                                  icon: Icons.query_stats_rounded,
                                  collapsible: true,
                                  expanded: statsExpanded,
                                  onToggle: () => setDialogState(
                                    () => statsExpanded = !statsExpanded,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
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
                                            value: meta['housing_space']
                                                .toString(),
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
                                            value: meta['attack_range']
                                                .toString(),
                                          ),
                                        if (meta['movement_speed'] != null)
                                          _buildStatRow(
                                            context,
                                            icon: Icons.directions_run_outlined,
                                            label: l10n.gameItemMovementSpeed,
                                            value: meta['movement_speed']
                                                .toString(),
                                          ),
                                        if (meta['upgrade_resource'] != null)
                                          _buildStatRow(
                                            context,
                                            icon: Icons.water_drop_outlined,
                                            label: l10n.gameItemUpgradeResource,
                                            value: meta['upgrade_resource']
                                                .toString(),
                                          ),
                                      ],
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
                                      if (!isEquipment &&
                                          (meta['is_air_targeting'] != null ||
                                              meta['is_ground_targeting'] !=
                                                  null))
                                        _buildTargetingRow(context, meta, l10n),
                                    ],
                                  ),
                                ),
                              ],
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.tonal(
                                  style: FilledButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text(l10n.generalOk),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildItemDialogHero(
    BuildContext context, {
    required PlayerItem item,
    required String title,
    required String subtitle,
    required Color accentColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSuperTroop = item is PlayerSuperTroop;
    final statusColor = isSuperTroop && item.superTroopIsActive
        ? StatColors.win
        : accentColor;
    final progress = item.maxLevel <= 0
        ? 0.0
        : (item.level / item.maxLevel).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 88,
                height: 88,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: colorScheme.surface.withValues(alpha: 0.70),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.42),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.16),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: MobileWebImage(
                    imageUrl: item.imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _buildDialogPill(
                          context,
                          label: subtitle,
                          icon: isSuperTroop
                              ? Icons.bolt_rounded
                              : Icons.trending_up_rounded,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surface.withValues(alpha: 0.50),
                ),
              ),
            ],
          ),
          if (!isSuperTroop && item.maxLevel > 0) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                color: accentColor,
                backgroundColor: colorScheme.outlineVariant.withValues(
                  alpha: 0.24,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'Level ${item.level}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  'Max ${item.maxLevel}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDialogSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
    bool prominent = false,
    Color? accentColor,
    bool collapsible = false,
    bool expanded = true,
    VoidCallback? onToggle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveAccent = accentColor ?? colorScheme.primary;
    final headerColor = prominent ? effectiveAccent : colorScheme.primary;
    final titleStyle = prominent
        ? Theme.of(context).textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            height: 1,
          )
        : Theme.of(context).textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            height: 1,
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.30),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: collapsible ? onToggle : null,
            borderRadius: BorderRadius.circular(10),
            splashFactory: NoSplash.splashFactory,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: collapsible ? 4 : 0),
              child: Row(
                children: [
                  Icon(icon, size: prominent ? 19 : 17, color: headerColor),
                  const SizedBox(width: 7),
                  Expanded(child: Text(title, style: titleStyle)),
                  if (collapsible)
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 160),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (!collapsible || expanded) ...[const SizedBox(height: 10), child],
        ],
      ),
    );
  }

  Widget _buildDialogPill(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _itemAccentColor(BuildContext context, PlayerItem item) {
    if (item is PlayerEquipment) {
      return item.rarity == '2' ? Colors.purpleAccent : Colors.lightBlueAccent;
    }
    if (item is PlayerSuperTroop) {
      return item.superTroopIsActive ? StatColors.win : StatColors.tie;
    }

    final meta = item.meta;
    final resource = meta?['upgrade_resource']?.toString().toLowerCase() ?? '';
    if (resource.contains('dark')) return const Color(0xFFB46CFF);
    if (resource.contains('elixir')) return const Color(0xFFE260D4);
    if (resource.contains('gold')) return StatColors.warStarGold;
    if (meta?['is_air_targeting'] == true) return const Color(0xFF2A9FD6);
    return Theme.of(context).colorScheme.primary;
  }

  Widget _buildStatRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: colorScheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeHighlights(
    BuildContext context, {
    required Map<String, dynamic>? nextUpgradeStats,
    required Map<String, dynamic>? meta,
    required UpgradeRemainingSummary thSummary,
    required UpgradeRemainingSummary globalSummary,
    required Color accentColor,
    required AppLocalizations l10n,
  }) {
    final maxSummary =
        globalSummary.levelsRemaining > 0 &&
            globalSummary.targetLevel != thSummary.targetLevel
        ? globalSummary
        : thSummary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useColumns = constraints.maxWidth >= 300;
        final children = [
          _UpgradeFlatPanel(
            title: l10n.gameItemNextUpgrade,
            child: _buildNextUpgradeFlatStats(
              context,
              nextUpgradeStats: nextUpgradeStats,
              meta: meta,
              l10n: l10n,
            ),
          ),
          _UpgradeFlatPanel(
            title: maxSummary == globalSummary
                ? l10n.gameItemRemainingToGlobalMax
                : l10n.gameItemRemainingToTownHallMax,
            child: _buildRemainingFlatStats(
              context,
              summary: maxSummary,
              l10n: l10n,
            ),
          ),
        ];

        if (!useColumns) {
          return Column(
            children: [children[0], const SizedBox(height: 14), children[1]],
          );
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: children[0]),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.34),
                ),
              ),
              Expanded(child: children[1]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNextUpgradeFlatStats(
    BuildContext context, {
    required Map<String, dynamic>? nextUpgradeStats,
    required Map<String, dynamic>? meta,
    required AppLocalizations l10n,
  }) {
    if (nextUpgradeStats == null || meta == null) {
      return _UpgradeFlatStatWrap(
        children: [
          _UpgradeFlatStat(
            label: l10n.generalUnknown,
            value: l10n.gameItemUpgradeDataUnavailable,
            icon: const Icon(Icons.info_outline_rounded, size: 18),
          ),
        ],
      );
    }

    final resources = _resourcesFromUpgradeCost(meta, nextUpgradeStats);
    final upgradeTime =
        (nextUpgradeStats['upgrade_time'] as num?)?.toInt() ?? 0;

    return _UpgradeFlatStatWrap(
      children: [
        if (upgradeTime > 0)
          _UpgradeFlatStat(
            label: l10n.gameItemUpgradeTime,
            value: _formatUpgradeTime(upgradeTime),
            icon: const Icon(Icons.schedule_rounded, size: 18),
          ),
        if (resources.isEmpty)
          _UpgradeFlatStat(
            label: l10n.gameItemUpgradeCost,
            value: l10n.generalUnknown,
            icon: const Icon(Icons.paid_outlined, size: 18),
          )
        else
          for (final resource in resources.take(2))
            _UpgradeFlatStat(
              label: _ResourceVisual.forKey(resource.key).localizedLabel(l10n),
              value: _formatLargeNumber(resource.amount),
              icon: MobileWebImage(
                imageUrl: _ResourceVisual.forKey(resource.key).imageUrl,
                width: 18,
                height: 18,
              ),
            ),
      ],
    );
  }

  Widget _buildRemainingFlatStats(
    BuildContext context, {
    required UpgradeRemainingSummary summary,
    required AppLocalizations l10n,
  }) {
    final hasUpgradeData = summary.seconds > 0 || summary.resources.isNotEmpty;

    return _UpgradeFlatStatWrap(
      children: [
        _UpgradeFlatStat(
          label: l10n.gameItemLevels,
          value: summary.levelsRemaining.toString(),
          icon: const MobileWebImage(
            imageUrl: ImageAssets.xp,
            width: 16,
            height: 16,
          ),
        ),
        if (hasUpgradeData) ...[
          if (summary.seconds > 0)
            _UpgradeFlatStat(
              label: l10n.gameItemUpgradeTime,
              value: _formatUpgradeTime(summary.seconds),
              icon: const Icon(Icons.schedule_rounded, size: 18),
            ),
          for (final resource in summary.resources.take(2))
            _UpgradeFlatStat(
              label: _ResourceVisual.forKey(resource.key).localizedLabel(l10n),
              value: _formatLargeNumber(resource.amount),
              icon: MobileWebImage(
                imageUrl: _ResourceVisual.forKey(resource.key).imageUrl,
                width: 18,
                height: 18,
              ),
            ),
        ] else
          _UpgradeFlatStat(
            label: l10n.generalUnknown,
            value: l10n.gameItemUpgradeDataUnavailable,
            icon: const Icon(Icons.info_outline_rounded, size: 18),
          ),
      ],
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
                fontWeight: FontWeight.w600,
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

UpgradeTrackerItem _upgradeDetailsItem(PlayerItem item) {
  final meta = item.meta;
  final category = switch (item) {
    PlayerEquipment() => UpgradeCategory.equipment,
    PlayerPet() => UpgradeCategory.pets,
    PlayerSiegeMachine() => UpgradeCategory.sieges,
    _ => switch (item.type) {
      'hero' => UpgradeCategory.heroes,
      'spell' => UpgradeCategory.spells,
      'builderBase' => UpgradeCategory.troops,
      _ => UpgradeCategory.troops,
    },
  };
  final queue = switch (category) {
    UpgradeCategory.pets => UpgradeQueue.pets,
    UpgradeCategory.troops ||
    UpgradeCategory.darkTroops ||
    UpgradeCategory.spells ||
    UpgradeCategory.sieges => UpgradeQueue.laboratory,
    _ => UpgradeQueue.builders,
  };
  final rawLevels = meta?['levels'];
  final levels = rawLevels is List
      ? rawLevels.whereType<Map>().map(Map<String, dynamic>.from).toList()
      : const <Map<String, dynamic>>[];
  final byLevel = <int, Map<String, dynamic>>{};
  for (final level in levels) {
    final value = int.tryParse('${level['level']}');
    if (value != null) byLevel[value] = level;
  }
  final steps = <UpgradeStep>[];
  for (var target = item.level + 1; target <= item.maxLevel; target++) {
    final stats = byLevel[target - 1];
    if (stats == null) continue;
    steps.add(
      UpgradeStep(
        targetLevel: target,
        costs: _upgradeDetailsCosts(
          stats['upgrade_cost'],
          meta?['upgrade_resource']?.toString(),
        ),
        seconds: (stats['upgrade_time'] as num?)?.toInt() ?? 0,
      ),
    );
  }
  final builderBase =
      item.type == 'builderBase' ||
      meta?['village']?.toString().toLowerCase().contains('builder') == true;
  return UpgradeTrackerItem(
    id: (meta?['_id'] as num?)?.toInt() ?? item.name.hashCode,
    name: item.name,
    imageUrl: item.imageUrl,
    village: builderBase ? UpgradeVillage.builderBase : UpgradeVillage.home,
    category: category,
    queue: queue,
    currentLevel: item.level,
    targetLevel: item.maxLevel,
    count: 1,
    steps: steps,
    completedUpgradeSeconds: 0,
    totalUpgradeSeconds: steps.fold(0, (total, step) => total + step.seconds),
    meta: meta,
  );
}

List<UpgradeCost> _upgradeDetailsCosts(dynamic value, String? fallback) {
  if (value is Map) {
    return value.entries
        .where((entry) => entry.value is num && (entry.value as num) > 0)
        .map(
          (entry) => UpgradeCost(
            _normalizeUpgradeDetailsResource(entry.key.toString()),
            entry.value as num,
          ),
        )
        .toList(growable: false);
  }
  if (value is num && value > 0) {
    return [
      UpgradeCost(_normalizeUpgradeDetailsResource(fallback ?? ''), value),
    ];
  }
  return const [];
}

String _normalizeUpgradeDetailsResource(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
    .replaceAll(RegExp(r'^_+|_+$'), '');

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
  Widget build(BuildContext context) => SectionProgressBadge(
    progress: percentage / 100,
    onTap: () => _showRemainingSheet(context),
  );

  void _showRemainingSheet(BuildContext context) {
    final isComplete = percentage >= 100;

    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 420,
            maxHeight: MediaQuery.sizeOf(context).height * 0.72,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
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
                              ?.copyWith(fontWeight: FontWeight.w600),
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
                            (resource) => _ResourceCostChip(resource: resource),
                          )
                          .toList(),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
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
      ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
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
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _UpgradeFlatPanel extends StatelessWidget {
  final String title;
  final Widget child;

  const _UpgradeFlatPanel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _UpgradeFlatStatWrap extends StatelessWidget {
  final List<Widget> children;

  const _UpgradeFlatStatWrap({required this.children});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: children,
    );
  }
}

class _UpgradeFlatStat extends StatelessWidget {
  final String label;
  final String value;
  final Widget icon;

  const _UpgradeFlatStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 56,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconTheme(
            data: IconThemeData(color: colorScheme.onSurfaceVariant, size: 16),
            child: Center(child: icon),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourceCostChip extends StatelessWidget {
  final _ResourceAmount resource;

  const _ResourceCostChip({required this.resource});

  @override
  Widget build(BuildContext context) {
    final visual = _ResourceVisual.forKey(resource.key);

    return Tooltip(
      message: visual.localizedLabel(AppLocalizations.of(context)!),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MobileWebImage(imageUrl: visual.imageUrl, width: 20, height: 20),
            const SizedBox(width: 6),
            Text(
              _PlayerItemSectionState._formatLargeNumber(resource.amount),
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResourceVisual {
  final String labelKey;
  final String imageUrl;

  const _ResourceVisual({required this.labelKey, required this.imageUrl});

  String localizedLabel(AppLocalizations l10n) {
    switch (labelKey) {
      case 'darkElixir':
        return l10n.resourceDarkElixir;
      case 'builderElixir':
        return l10n.resourceBuilderElixir;
      case 'builderGold':
        return l10n.resourceBuilderGold;
      case 'elixir':
        return l10n.resourceElixir;
      case 'gold':
        return l10n.resourceGold;
      case 'glowyOre':
        return l10n.resourceGlowyOre;
      case 'starryOre':
        return l10n.resourceStarryOre;
      case 'shinyOre':
        return l10n.resourceShinyOre;
      default:
        return l10n.resourceGeneric;
    }
  }

  factory _ResourceVisual.forKey(String key) {
    if (key.contains('dark')) {
      return const _ResourceVisual(
        labelKey: 'darkElixir',
        imageUrl: _resourceDarkElixir,
      );
    }
    if (key.contains('builder') && key.contains('elixir')) {
      return const _ResourceVisual(
        labelKey: 'builderElixir',
        imageUrl: _resourceBuilderElixir,
      );
    }
    if (key.contains('builder') && key.contains('gold')) {
      return const _ResourceVisual(
        labelKey: 'builderGold',
        imageUrl: _resourceBuilderGold,
      );
    }
    if (key.contains('elixir')) {
      return const _ResourceVisual(
        labelKey: 'elixir',
        imageUrl: _resourceElixir,
      );
    }
    if (key.contains('gold')) {
      return const _ResourceVisual(labelKey: 'gold', imageUrl: _resourceGold);
    }
    if (key.contains('glowy')) {
      return const _ResourceVisual(
        labelKey: 'glowyOre',
        imageUrl: _resourceGlowyOre,
      );
    }
    if (key.contains('starry')) {
      return const _ResourceVisual(
        labelKey: 'starryOre',
        imageUrl: _resourceStarryOre,
      );
    }
    if (key.contains('shiny')) {
      return const _ResourceVisual(
        labelKey: 'shinyOre',
        imageUrl: _resourceShinyOre,
      );
    }
    return const _ResourceVisual(
      labelKey: 'generic',
      imageUrl: ImageAssets.defaultImage,
    );
  }
}
