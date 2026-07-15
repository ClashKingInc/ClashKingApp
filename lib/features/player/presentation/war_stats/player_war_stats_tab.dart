import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/features/player/presentation/war_stats/widgets/enhanced_stat_card.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/player/models/player_enemy_townhall_stats.dart';
import 'package:clashkingapp/features/player/models/player_war_stats.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';

class WarStatsView extends StatelessWidget {
  final PlayerWarStats? warStats;
  final List<String> filterTypes;
  final DateTime currentSeasonDate;
  final int warDataLimit;

  const WarStatsView({
    super.key,
    this.warStats,
    required this.filterTypes,
    required this.currentSeasonDate,
    required this.warDataLimit,
  });

  /// Groups the [EnemyTownhallStats] by defender town hall level
  Map<String, List<EnemyTownhallStats>> groupByDefenderTh(
    Map<String, EnemyTownhallStats> data,
  ) {
    final Map<String, List<EnemyTownhallStats>> grouped = {};
    for (final entry in data.entries) {
      final parts = entry.key.split("vs");
      if (parts.length != 2) continue;
      final defenderTh = parts[1];
      grouped.putIfAbsent(defenderTh, () => []).add(entry.value);
    }
    return grouped;
  }

  /// Merges a list of [EnemyTownhallStats] into a single [EnemyTownhallStats]
  EnemyTownhallStats mergeStats(List<EnemyTownhallStats> statList) {
    double totalStars = 0;
    double totalDestruction = 0;
    int totalCount = 0;
    final Map<String, int> mergedStarsCount = {'0': 0, '1': 0, '2': 0, '3': 0};

    for (final stat in statList) {
      final count = stat.count;
      final stars = stat.averageStars;
      final destruction = stat.averageDestruction;
      totalStars += stars * count;
      totalDestruction += destruction * count;
      totalCount += count;

      // Merge star counts
      for (final entry in stat.starsCount.entries) {
        mergedStarsCount[entry.key] =
            (mergedStarsCount[entry.key] ?? 0) + entry.value;
      }
    }

    return EnemyTownhallStats(
      averageStars: totalCount > 0 ? totalStars / totalCount : 0.0,
      averageDestruction: totalCount > 0 ? totalDestruction / totalCount : 0.0,
      count: totalCount,
      starsCount: mergedStarsCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = warStats?.getStatsForTypes(filterTypes);

    final Locale userLocale = Localizations.localeOf(context);

    final groupedAttackStats = groupByDefenderTh(stats!.byEnemyTownhall);
    final groupedDefenseStats = groupByDefenderTh(stats.byEnemyTownhallDef);

    // Get all unique TH levels from both attack and defense data
    final allThLevels = <String>{};
    allThLevels.addAll(groupedAttackStats.keys);
    allThLevels.addAll(groupedDefenseStats.keys);

    final sortedEntries =
        allThLevels
            .map(
              (thLevel) => MapEntry(thLevel, groupedAttackStats[thLevel] ?? []),
            )
            .toList()
          ..sort((a, b) => int.parse(b.key).compareTo(int.parse(a.key)));

    return Column(
      children: <Widget>[
        _WarStatsCollapsibleSection(
          title: AppLocalizations.of(context)!.statsAllTownHalls,
          initiallyExpanded: true,
          attackCount: stats.totalAttacks,
          defenseCount: stats.totalDefenses,
          subtitle: _buildFilterSubtitle(context, userLocale),
          childBuilder: (context) => _buildStatRows(context, stats),
        ),
        ...sortedEntries.map((entry) {
          final thLevel = entry.key;
          final attackStats = entry.value.isNotEmpty
              ? mergeStats(entry.value)
              : null;
          final defenseStats = groupedDefenseStats[thLevel] != null
              ? mergeStats(groupedDefenseStats[thLevel]!)
              : null;

          final defTh = int.tryParse(thLevel);

          return _WarStatsCollapsibleSection(
            title: AppLocalizations.of(
              context,
            )!.gameTownHallLevelNumber(defTh ?? 1),
            imageUrl: ImageAssets.townHall(defTh ?? 1),
            attackCount: attackStats?.count ?? 0,
            defenseCount: defenseStats?.count ?? 0,
            childBuilder: (context) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: attackStats != null
                        ? EnhancedStatCard(
                            title: AppLocalizations.of(
                              context,
                            )!.warAttacksTitle,
                            stars: attackStats.averageStars,
                            destruction: attackStats.averageDestruction,
                            count: attackStats.count,
                            isAttack: true,
                            starsBreakdown: attackStats.starsCount,
                          )
                        : _EmptyWarStatsCard(
                            label: AppLocalizations.of(context)!.warAttacksNone,
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: defenseStats != null
                        ? EnhancedStatCard(
                            title: AppLocalizations.of(
                              context,
                            )!.warDefensesTitle,
                            stars: defenseStats.averageStars,
                            destruction: defenseStats.averageDestruction,
                            count: defenseStats.count,
                            isAttack: false,
                            starsBreakdown: defenseStats.starsCount,
                          )
                        : _EmptyWarStatsCard(
                            label: AppLocalizations.of(
                              context,
                            )!.warDefensesNone,
                          ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  String? _buildFilterSubtitle(BuildContext context, Locale userLocale) {
    if (filterTypes.contains("dateRange")) {
      final formattedStartDate = DateFormat.yMd(
        userLocale.toString(),
      ).format(DateTime.fromMillisecondsSinceEpoch(1000));
      final formattedEndDate = DateFormat.yMd(
        userLocale.toString(),
      ).format(DateTime.fromMillisecondsSinceEpoch(1000));
      return "$formattedStartDate - $formattedEndDate";
    }
    if (filterTypes.contains("lastXWars")) {
      return AppLocalizations.of(context)!.warFiltersLastXwars(warDataLimit);
    }
    if (filterTypes.contains("season")) {
      return AppLocalizations.of(context)!.statsSeasonDate(
        DateFormat.yMMMM(userLocale.toString()).format(currentSeasonDate),
      );
    }
    return null;
  }

  Widget _buildStatRows(BuildContext context, PlayerWarTypeStats stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: EnhancedStatCard(
              title: AppLocalizations.of(context)!.warAttacksTitle,
              stars: stats.averageStars,
              destruction: stats.averageDestruction,
              count: stats.totalAttacks,
              missed: stats.missedAttacks > 0 ? stats.missedAttacks : null,
              isAttack: true,
              starsBreakdown: stats.starsCount,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: EnhancedStatCard(
              title: AppLocalizations.of(context)!.warDefensesTitle,
              stars: stats.averageStarsDef,
              destruction: stats.averageDestructionDef,
              count: stats.totalDefenses,
              missed: stats.missedDefenses > 0 ? stats.missedDefenses : null,
              isAttack: false,
              starsBreakdown: stats.starsCountDef,
            ),
          ),
        ],
      ),
    );
  }
}

class _WarStatsCollapsibleSection extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final int attackCount;
  final int defenseCount;
  final WidgetBuilder childBuilder;
  final bool initiallyExpanded;

  const _WarStatsCollapsibleSection({
    required this.title,
    required this.childBuilder,
    required this.attackCount,
    required this.defenseCount,
    this.subtitle,
    this.imageUrl,
    this.initiallyExpanded = false,
  });

  @override
  State<_WarStatsCollapsibleSection> createState() =>
      _WarStatsCollapsibleSectionState();
}

class _WarStatsCollapsibleSectionState
    extends State<_WarStatsCollapsibleSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color:
              Theme.of(context).cardTheme.color ??
              Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.32),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
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
                          color: colorScheme.onSurface.withValues(alpha: 0.72),
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (widget.imageUrl != null) ...[
                        MobileWebImage(
                          imageUrl: widget.imageUrl!,
                          width: 30,
                          height: 30,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (widget.subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _WarSectionSummary(
                        attackCount: widget.attackCount,
                        defenseCount: widget.defenseCount,
                      ),
                    ],
                  ),
                ),
              ),
              if (_expanded) ...[
                const SizedBox(height: 12),
                RepaintBoundary(child: widget.childBuilder(context)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WarSectionSummary extends StatelessWidget {
  final int attackCount;
  final int defenseCount;

  const _WarSectionSummary({
    required this.attackCount,
    required this.defenseCount,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.end,
      children: [
        _WarSummaryPill(
          imageUrl: ImageAssets.sword,
          value: attackCount,
          tooltip: AppLocalizations.of(context)!.warAttacksTitle,
        ),
        _WarSummaryPill(
          imageUrl: ImageAssets.shield,
          value: defenseCount,
          tooltip: AppLocalizations.of(context)!.warDefensesTitle,
        ),
      ],
    );
  }
}

class _WarSummaryPill extends StatelessWidget {
  final String imageUrl;
  final int value;
  final String tooltip;

  const _WarSummaryPill({
    required this.imageUrl,
    required this.value,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MobileWebImage(imageUrl: imageUrl, width: 15, height: 15),
            const SizedBox(width: 4),
            Text(
              value.toString(),
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyWarStatsCard extends StatelessWidget {
  final String label;

  const _EmptyWarStatsCard({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
