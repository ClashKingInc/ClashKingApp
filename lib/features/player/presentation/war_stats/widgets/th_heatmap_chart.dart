import 'package:flutter/material.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/icons/build_stars.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/player/models/player_enemy_townhall_stats.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';

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
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          showDefense 
            ? AppLocalizations.of(context)!.chartsDefensePerformance 
            : AppLocalizations.of(context)!.chartsAttackPerformance,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppLocalizations.of(context)!.chartsRowsYourTh,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        
        // Heatmap grid
        Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              // Header row
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 40), // Space for row labels
                    ...opponentThLevels.map((th) => Expanded(
                      child: Center(
                        child: MobileWebImage(
                          imageUrl: ImageAssets.townHall(th),
                          width: 24,
                          height: 24,
                        ),
                      ),
                    )),
                  ],
                ),
              ),
              
              // Data rows - player TH is always on rows
              ...playerThLevels.map((playerTh) => _buildRow(context, playerTh, opponentThLevels, stats)),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Legend
        _buildLegend(context),
      ],
    );
  }

  Widget _buildRow(BuildContext context, int rowTh, List<int> columnThLevels, Map<String, EnemyTownhallStats> stats) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          // Row label
          SizedBox(
            width: 40,
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
            
            return Expanded(
              child: Container(
                margin: const EdgeInsets.all(2),
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: stat != null ? _getPerformanceColor(stat.averageStars) : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (stat != null) Transform.scale(
                        scale: 0.7,
                        child: buildStarsIcon(3), // Always show 3 stars
                      ),
                      Text(
                        stat?.averageStars.toStringAsFixed(1) ?? AppLocalizations.of(context)!.chartsNoData,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: stat != null ? _getPerformanceColor(stat.averageStars) : Colors.grey[600],
                          fontSize: 8,
                        ),
                      ),
                      if (stat != null)
                        Text(
                          '(${stat.count})',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontSize: 6,
                          ),
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

  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(context, AppLocalizations.of(context)!.generalPoor, Colors.red[600]!),
        const SizedBox(width: 16),
        _buildLegendItem(context, AppLocalizations.of(context)!.generalAverage, Colors.orange[600]!),
        const SizedBox(width: 16),
        _buildLegendItem(context, AppLocalizations.of(context)!.chartsGood, Colors.amber[600]!),
        const SizedBox(width: 16),
        _buildLegendItem(context, AppLocalizations.of(context)!.chartsExcellent, Colors.green[600]!),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Color _getPerformanceColor(double stars) {
    // Use consistent color logic for both attacks and defenses in heatmap
    // Higher stars = better performance (green), lower stars = worse performance (red)
    if (stars >= 2.5) return Colors.green[600]!;
    if (stars >= 2.0) return Colors.amber[600]!;
    if (stars >= 1.0) return Colors.orange[600]!;
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
      final fallbackThs = List.generate(maxTh - minTh + 1, (index) => minTh + index);
      return (fallbackThs, fallbackThs);
    }
    
    // Use actual TH levels from data, sorted
    final playerThsList = playerThs.toList()..sort();
    final opponentThsList = opponentThs.toList()..sort();
    
    return (playerThsList, opponentThsList);
  }
}