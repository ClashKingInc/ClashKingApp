import 'package:clashkingapp/common/widgets/summary_chips.dart';
import 'package:clashkingapp/features/player/models/player_war_stats.dart';
import 'package:clashkingapp/features/player/presentation/war_stats/player_war_attacks_card.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';

class PlayerWarAttacksTab extends StatelessWidget {
  final List<PlayerWarStatsData> wars;
  final PlayerWarTypeStats stats;
  final String type;

  const PlayerWarAttacksTab({
    super.key,
    required this.wars,
    required this.stats,
    required this.type,
  });

  bool get _isAttack => type == "attacks";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _WarStatsCompactSummary(
            count: _isAttack ? stats.totalAttacks : stats.totalDefenses,
            averageStars: _isAttack
                ? stats.averageStars
                : stats.averageStarsDef,
            destruction: _isAttack
                ? stats.averageDestruction
                : stats.averageDestructionDef,
            missed: _isAttack ? stats.missedAttacks : stats.missedDefenses,
          ),
        ),
        const SizedBox(height: 8),
        PlayerWarAttacksCard(wars: wars, type: type),
      ],
    );
  }
}

class _WarStatsCompactSummary extends StatelessWidget {
  final int count;
  final double averageStars;
  final double destruction;
  final int missed;

  const _WarStatsCompactSummary({
    required this.count,
    required this.averageStars,
    required this.destruction,
    required this.missed,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final missedColor = missed > 0
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    return ClanSummaryChips(
      padding: EdgeInsets.zero,
      children: [
        ClanSummaryChip(
          label: loc.generalTotal,
          value: count.toString(),
          icon: Icons.format_list_numbered_rounded,
        ),
        ClanSummaryChip(
          label: loc.warStarsAverage,
          value: averageStars.toStringAsFixed(2),
          icon: Icons.star_rounded,
        ),
        ClanSummaryChip(
          label: loc.warDestructionTitle,
          value: '${destruction.toStringAsFixed(1)}%',
          icon: Icons.percent_rounded,
        ),
        ClanSummaryChip(
          label: loc.warAttacksMissedShort,
          value: missed.toString(),
          icon: Icons.warning_amber_rounded,
          color: missedColor,
          selected: missed > 0,
        ),
      ],
    );
  }
}
