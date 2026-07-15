import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/utils/capital_raid_analytics.dart';
import 'package:clashkingapp/core/utils/raid_medal_predictor.dart';
import 'package:clashkingapp/features/clan/models/clan_capital_history.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Raid overview for the currently selected week: a single flat summary
/// panel (no nested Card) with the reward/loot headline and a
/// ClanSummaryChip row, matching the language already used by the clan
/// and CWL detail tabs instead of the page's old elevated Card stack.
class CapitalRaidsTab extends StatelessWidget {
  final CapitalHistoryItem raid;
  final int clanCapitalPoints;

  const CapitalRaidsTab({
    super.key,
    required this.raid,
    required this.clanCapitalPoints,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat('#,###', locale);
    final isOngoing = raid.state == 'ongoing';
    // The defensive-reward formula can dip below zero in edge cases (very
    // small housing space vs. heavy looting) — clamp for display, the
    // predictor itself stays a faithful, testable port of the source
    // algorithm.
    final estimatedReward =
        RaidMedalPredictor.predictOffensiveReward(raid.attackLog ?? []) +
        RaidMedalPredictor.predictDefensiveReward(raid.defenseLog ?? []);
    final totalReward = isOngoing
        ? (estimatedReward < 0 ? 0 : estimatedReward)
        : 6 * raid.offensiveReward + raid.defensiveReward;
    final projectedLoot = CapitalRaidAnalytics.projectedTotalLoot(raid);
    final trophyPrediction = isOngoing
        ? CapitalRaidAnalytics.predictTrophyChange(raid, clanCapitalPoints)
        : null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(
                  alpha: AppOpacity.border,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    MobileWebImage(
                      imageUrl: ImageAssets.raidMedal,
                      width: 34,
                      height: 34,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              formatter.format(totalReward),
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                  ),
                            ),
                          ),
                          if (isOngoing) ...[
                            const SizedBox(width: 6),
                            _EstimatedBadge(
                              tooltip: loc.capitalRaidEstimatedTooltip,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      loc.capitalRaidRewards,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _CapitalFullStatsGrid(
                  stats: [
                    _CapitalFullStat(
                      label: loc.raidsCompleted,
                      value: formatter.format(raid.raidsCompleted),
                      icon: Icon(
                        Icons.checklist_rounded,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                    ),
                    _CapitalFullStat(
                      label: loc.raidsDistrictsDestroyed,
                      value: formatter.format(raid.enemyDistrictsDestroyed),
                      icon: Icon(
                        Icons.domain_rounded,
                        size: 18,
                        color: StatColors.capitalDistrict,
                      ),
                    ),
                    _CapitalFullStat(
                      label: loc.warAttacksTitle,
                      value: formatter.format(raid.totalAttacks),
                      icon: Icon(
                        Icons.bolt_rounded,
                        size: 18,
                        color: StatColors.capitalAttack,
                      ),
                    ),
                    _CapitalFullStat(
                      label: loc.capitalRaidLoot,
                      value: formatter.format(raid.capitalTotalLoot),
                      icon: MobileWebImage(
                        imageUrl: ImageAssets.capitalGold,
                        width: 18,
                        height: 18,
                      ),
                    ),
                    if (projectedLoot != null)
                      _CapitalFullStat(
                        label: loc.capitalRaidProjectedLoot,
                        value: formatter.format(projectedLoot),
                        icon: Icon(
                          Icons.trending_up_rounded,
                          size: 18,
                          color: StatColors.capitalProjected,
                        ),
                      ),
                    if (trophyPrediction != null)
                      _CapitalFullStat(
                        label: loc.capitalRaidTrophyPrediction,
                        value:
                            '${formatter.format(trophyPrediction.predictedPoints)} '
                            '(${trophyPrediction.change >= 0 ? '+' : ''}${formatter.format(trophyPrediction.change)})',
                        tooltip: loc.capitalRaidTrophyPredictionTooltip,
                        icon: Icon(
                          trophyPrediction.change >= 0
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 18,
                          color: trophyPrediction.change >= 0
                              ? StatColors.win
                              : StatColors.loss,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CapitalFullStatsGrid extends StatelessWidget {
  final List<_CapitalFullStat> stats;

  const _CapitalFullStatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: stats.map((stat) => _CapitalFlatStat(stat: stat)).toList(),
    );
  }
}

class _CapitalFlatStat extends StatelessWidget {
  final _CapitalFullStat stat;

  const _CapitalFlatStat({required this.stat});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final child = SizedBox(
      width: 66,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(child: stat.icon),
          const SizedBox(height: 4),
          Text(
            stat.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stat.value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );

    return stat.tooltip == null
        ? child
        : Tooltip(message: stat.tooltip!, child: child);
  }
}

class _CapitalFullStat {
  final String label;
  final String value;
  final Widget icon;
  final String? tooltip;

  const _CapitalFullStat({
    required this.label,
    required this.value,
    required this.icon,
    this.tooltip,
  });
}

/// Flags a value as a client-side estimate (not yet published by
/// Supercell) rather than final data, so users don't mistake the
/// predicted medal count for the real end-of-raid reward.
class _EstimatedBadge extends StatelessWidget {
  final String tooltip;

  const _EstimatedBadge({required this.tooltip});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: colorScheme.tertiary.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: colorScheme.tertiary.withValues(alpha: 0.32),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_graph_rounded,
              size: 12,
              color: colorScheme.tertiary,
            ),
            const SizedBox(width: 3),
            Text(
              loc.capitalRaidEstimated,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.tertiary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
