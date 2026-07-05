import 'package:flutter/material.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/player/models/player_enemy_townhall_stats.dart';

/// A heatmap chart showing performance against different TH levels
class THHeatmapChart extends StatelessWidget {
  final Map<String, EnemyTownhallStats> attackStats;
  final Map<String, EnemyTownhallStats> defenseStats;
  final int playerThLevel;
  final bool showDefense;

  const THHeatmapChart({
    super.key,
    required this.attackStats,
    required this.defenseStats,
    required this.playerThLevel,
    this.showDefense = false,
  });

  @override
  Widget build(BuildContext context) {
    final stats = showDefense ? defenseStats : attackStats;
    final (playerThLevels, opponentThLevels) = _getRelevantThLevels();
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RepaintBoundary(
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.18,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.32),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.28,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 42,
                        child: Text(
                          'TH',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      ...opponentThLevels.map(
                        (th) => Expanded(
                          child: Center(
                            child: MobileWebImage(
                              imageUrl: ImageAssets.townHall(th),
                              width: 24,
                              height: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                ...playerThLevels.map(
                  (playerTh) =>
                      _buildRow(context, playerTh, opponentThLevels, stats),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(
    BuildContext context,
    int rowTh,
    List<int> columnThLevels,
    Map<String, EnemyTownhallStats> stats,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.24),
          ),
        ),
      ),
      child: Row(
        children: [
          // Row label
          SizedBox(
            width: 42,
            child: Center(
              child: MobileWebImage(
                imageUrl: ImageAssets.townHall(rowTh),
                width: 24,
                height: 24,
              ),
            ),
          ),

          // Cells
          ...columnThLevels.map((colTh) {
            // For attacks: rowTh = myTh, colTh = opponentTh -> key = myTh vs opponentTh
            // For defenses: rowTh = myTh, colTh = opponentTh -> key = opponentTh vs myTh
            final key = showDefense ? '${colTh}vs$rowTh' : '${rowTh}vs$colTh';
            final stat = stats[key];
            final performanceColor = stat != null
                ? _getPerformanceColor(stat.averageStars)
                : colorScheme.outlineVariant;

            return Expanded(
              child: Container(
                margin: const EdgeInsets.all(2),
                constraints: const BoxConstraints(minHeight: 48),
                decoration: BoxDecoration(
                  color: stat != null
                      ? performanceColor.withValues(alpha: 0.13)
                      : colorScheme.surface.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: stat != null
                        ? performanceColor.withValues(alpha: 0.42)
                        : colorScheme.outlineVariant.withValues(alpha: 0.24),
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (stat != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              stat.averageStars.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: performanceColor,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                  ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.star_rounded,
                              size: 11,
                              color: performanceColor,
                            ),
                          ],
                        )
                      else
                        Text(
                          '-',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      if (stat != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MobileWebImage(
                              imageUrl: ImageAssets.sword,
                              width: 10,
                              height: 10,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              stat.count.toString(),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                    height: 1.15,
                                  ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getPerformanceColor(double stars) {
    final performance = showDefense ? 3.0 - stars : stars;
    if (performance >= 2.5) return Colors.green[600]!;
    if (performance >= 2.0) return Colors.amber[600]!;
    if (performance >= 1.0) return Colors.orange[600]!;
    return Colors.red[600]!;
  }

  (List<int>, List<int>) _getRelevantThLevels() {
    final stats = showDefense ? defenseStats : attackStats;

    // Extract player TH levels and opponent TH levels separately
    final Set<int> playerThs = {};
    final Set<int> opponentThs = {};

    for (final key in stats.keys) {
      final stat = stats[key];
      if (stat != null && stat.count > 0) {
        final parts = key.split('vs');
        if (parts.length == 2) {
          final attacker = int.tryParse(parts[0]);
          final defender = int.tryParse(parts[1]);
          if (attacker != null && defender != null) {
            if (showDefense) {
              // For defense: attacker = opponent, defender = player
              opponentThs.add(attacker);
              playerThs.add(defender);
            } else {
              // For attack: attacker = player, defender = opponent
              playerThs.add(attacker);
              opponentThs.add(defender);
            }
          }
        }
      }
    }

    // If no data, fall back to player TH level range
    if (playerThs.isEmpty && opponentThs.isEmpty) {
      final minTh = (playerThLevel - 2).clamp(1, 17);
      final maxTh = (playerThLevel + 2).clamp(1, 17);
      final fallbackThs = List.generate(
        maxTh - minTh + 1,
        (index) => minTh + index,
      );
      return (fallbackThs, fallbackThs);
    }

    // Use actual TH levels from data, sorted
    final playerThsList = playerThs.toList()..sort();
    final opponentThsList = opponentThs.toList()..sort();

    return (playerThsList, opponentThsList);
  }
}
