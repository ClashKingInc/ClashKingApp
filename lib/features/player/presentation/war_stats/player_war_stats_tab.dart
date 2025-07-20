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
      Map<String, EnemyTownhallStats> data) {
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
        mergedStarsCount[entry.key] = (mergedStarsCount[entry.key] ?? 0) + entry.value;
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
    String formattedStartDate = DateFormat.yMd(userLocale.toString())
        .format(DateTime.fromMillisecondsSinceEpoch(1000));
    String formattedEndDate = DateFormat.yMd(userLocale.toString())
        .format(DateTime.fromMillisecondsSinceEpoch(1000));


    final groupedAttackStats = groupByDefenderTh(stats!.byEnemyTownhall);
    final groupedDefenseStats = groupByDefenderTh(stats.byEnemyTownhallDef);

    // Get all unique TH levels from both attack and defense data
    final allThLevels = <String>{};
    allThLevels.addAll(groupedAttackStats.keys);
    allThLevels.addAll(groupedDefenseStats.keys);
    
    final sortedEntries = allThLevels.map((thLevel) => MapEntry(thLevel, groupedAttackStats[thLevel] ?? [])).toList()
      ..sort((a, b) => int.parse(b.key).compareTo(int.parse(a.key)));

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(AppLocalizations.of(context)!.statsAllTownHalls,
                      style: Theme.of(context).textTheme.titleSmall),
                  if (filterTypes.contains("dateRange"))
                    Text("($formattedStartDate - $formattedEndDate)",
                        style: Theme.of(context).textTheme.bodyMedium),
                  if (filterTypes.contains("lastXWars"))
                    Text(AppLocalizations.of(context)!.warFiltersLastXwars(warDataLimit),
                        style: Theme.of(context).textTheme.bodyMedium),
                  if (filterTypes.contains("season"))
                    Text(
                        AppLocalizations.of(context)!.statsSeasonDate(
                            DateFormat.yMMMM(userLocale.toString())
                                .format(currentSeasonDate)),
                        style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  _buildStatRows(context, stats),
                ],
              ),
            ),
          ),
        ),
        ...sortedEntries.map((entry) {
          final thLevel = entry.key;
          final attackStats = entry.value.isNotEmpty ? mergeStats(entry.value) : null;
          final defenseStats = groupedDefenseStats[thLevel] != null
              ? mergeStats(groupedDefenseStats[thLevel]!)
              : null;

          final defTh = int.tryParse(thLevel);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        MobileWebImage(
                          imageUrl: ImageAssets.townHall(defTh ?? 1),
                          width: 30,
                          height: 30,
                        ),
                        SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!
                            .gameTownHallLevelNumber(defTh ?? 1)),
                      ],
                    ),
                    SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: attackStats != null
                                ? EnhancedStatCard(
                                    title: AppLocalizations.of(context)!.warAttacksTitle,
                                    stars: attackStats.averageStars,
                                    destruction: attackStats.averageDestruction,
                                    count: attackStats.count,
                                    isAttack: true,
                                    starsBreakdown: attackStats.starsCount,
                                  )
                                : Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey[300]!.withValues(alpha: 0.3)),
                                    ),
                                    child: Center(
                                      child: Text(
                                        AppLocalizations.of(context)!.warAttacksNone,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: defenseStats != null
                                ? EnhancedStatCard(
                                    title: AppLocalizations.of(context)!.warDefensesTitle,
                                    stars: defenseStats.averageStars,
                                    destruction: defenseStats.averageDestruction,
                                    count: defenseStats.count,
                                    isAttack: false,
                                    starsBreakdown: defenseStats.starsCount,
                                  )
                                : Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey[300]!.withValues(alpha: 0.3)),
                                    ),
                                    child: Center(
                                      child: Text(
                                        AppLocalizations.of(context)!.warDefensesNone,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
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
