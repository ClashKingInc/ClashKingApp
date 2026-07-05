import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/war_cwl/data/war_functions.dart'
    show countStars;
import 'package:clashkingapp/features/war_cwl/models/war_clan.dart';
import 'package:clashkingapp/features/war_cwl/models/war_info.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class WarStatisticsTab extends StatelessWidget {
  const WarStatisticsTab({super.key, required this.warInfo});

  final WarInfo warInfo;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final clan = warInfo.clan;
    final opponent = warInfo.opponent;

    if (clan == null || opponent == null) {
      return _WarSectionPanel(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(child: Text(loc.generalNoDataAvailable)),
        ),
      );
    }

    final teamSize = warInfo.teamSize ?? 15;
    final attacksPerPlayer = warInfo.effectiveAttacksPerMember;
    final maxStars = teamSize * 3;
    final maxAttacks = teamSize * attacksPerPlayer;
    final clanStarCounts = countStars(clan.members);
    final opponentStarCounts = countStars(opponent.members);
    final insight = _warInsight(context, clan, opponent, maxAttacks);

    return Column(
      children: [
        _WarInsightPanel(insight: insight),
        const SizedBox(height: 10),
        _WarSectionPanel(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionTitle(label: loc.navigationStatistics),
                const SizedBox(height: 12),
                _ComparisonMetric(
                  label: loc.warStarsTitle,
                  leftValue: '${clan.stars}/$maxStars',
                  rightValue: '${opponent.stars}/$maxStars',
                  leftProgress: _safeRatio(clan.stars, maxStars),
                  rightProgress: _safeRatio(opponent.stars, maxStars),
                  iconUrl: ImageAssets.attackStar,
                  leftColor: _leaderColor(
                    clan.stars.toDouble(),
                    opponent.stars.toDouble(),
                  ),
                  rightColor: _leaderColor(
                    opponent.stars.toDouble(),
                    clan.stars.toDouble(),
                  ),
                ),
                const SizedBox(height: 14),
                _ComparisonMetric(
                  label: loc.warDestructionRate,
                  leftValue:
                      '${clan.destructionPercentage.toStringAsFixed(2)}%',
                  rightValue:
                      '${opponent.destructionPercentage.toStringAsFixed(2)}%',
                  leftProgress: _safeRatio(clan.destructionPercentage, 100),
                  rightProgress: _safeRatio(
                    opponent.destructionPercentage,
                    100,
                  ),
                  icon: Icons.percent_rounded,
                  leftColor: _leaderColor(
                    clan.destructionPercentage,
                    opponent.destructionPercentage,
                  ),
                  rightColor: _leaderColor(
                    opponent.destructionPercentage,
                    clan.destructionPercentage,
                  ),
                ),
                const SizedBox(height: 14),
                _ComparisonMetric(
                  label: loc.warAttacksTitle,
                  leftValue: '${clan.attacks}/$maxAttacks',
                  rightValue: '${opponent.attacks}/$maxAttacks',
                  leftProgress: _safeRatio(clan.attacks, maxAttacks),
                  rightProgress: _safeRatio(opponent.attacks, maxAttacks),
                  iconUrl: ImageAssets.sword,
                  leftColor: StatColors.win,
                  rightColor: StatColors.loss,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        _WarSectionPanel(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionTitle(label: loc.warStarsNumber),
                const SizedBox(height: 12),
                _StarsBreakdown(
                  clan: clan,
                  opponent: opponent,
                  clanCounts: clanStarCounts,
                  opponentCounts: opponentStarCounts,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  _WarInsight _warInsight(
    BuildContext context,
    WarClan clan,
    WarClan opponent,
    int maxAttacks,
  ) {
    final loc = AppLocalizations.of(context)!;
    final clanRemainingAttacks = (maxAttacks - clan.attacks).clamp(
      0,
      maxAttacks,
    );
    final opponentRemainingAttacks = (maxAttacks - opponent.attacks).clamp(
      0,
      maxAttacks,
    );
    final status = switch (warInfo.state) {
      'preparation' || 'preparationDay' => loc.warPreparation,
      'warEnded' => loc.warEnded,
      'inWar' || 'warInWar' => loc.warOngoing,
      _ => loc.warStateOfTheWar,
    };
    final strategy = _warStrategy(
      context,
      clan,
      opponent,
      maxAttacks,
      clanRemainingAttacks.toInt(),
      opponentRemainingAttacks.toInt(),
    );

    return _WarInsight(
      status: status,
      message: strategy.message,
      color: strategy.color,
      stats: strategy.stats,
    );
  }

  _WarStrategy _warStrategy(
    BuildContext context,
    WarClan clan,
    WarClan opponent,
    int maxAttacks,
    int clanRemainingAttacks,
    int opponentRemainingAttacks,
  ) {
    final loc = AppLocalizations.of(context)!;
    final isPreparation =
        warInfo.state == 'preparation' || warInfo.state == 'preparationDay';
    final teamSize = warInfo.teamSize ?? 15;
    final ourMaxStars = clan.stars + (clanRemainingAttacks * 3);
    final theirMaxStars = opponent.stars + (opponentRemainingAttacks * 3);
    final percentGapForUsValue = _percentGapToPass(
      opponent.destructionPercentage,
      clan.destructionPercentage,
    );
    final percentGapForThemValue = _percentGapToPass(
      clan.destructionPercentage,
      opponent.destructionPercentage,
    );
    final percentGapForUs = _formatPercent(percentGapForUsValue);
    final percentGapForThem = _formatPercent(percentGapForThemValue);

    if (isPreparation ||
        (clan.stars == 0 &&
            opponent.stars == 0 &&
            clan.destructionPercentage == 0.0 &&
            opponent.destructionPercentage == 0.0)) {
      return _WarStrategy(
        message:
            'Plan phase: $maxAttacks attacks available. Save cleanups for the end and scout risky top bases first.',
        color: StatColors.warStarGold,
        stats: [
          _InsightStat(
            label: 'Available',
            value: '$maxAttacks',
            imageUrl: ImageAssets.sword,
          ),
          _InsightStat(
            label: 'Perfect score',
            value: '${(warInfo.teamSize ?? 15) * 3}',
            imageUrl: ImageAssets.attackStar,
          ),
        ],
      );
    }

    if (warInfo.state == 'warEnded') {
      final clanWon =
          clan.stars > opponent.stars ||
          (clan.stars == opponent.stars &&
              clan.destructionPercentage > opponent.destructionPercentage);
      final isDraw =
          clan.stars == opponent.stars &&
          clan.destructionPercentage == opponent.destructionPercentage;
      return _WarStrategy(
        message: _warStatus(context, clan, opponent),
        color: isDraw
            ? StatColors.warStarGold
            : clanWon
            ? StatColors.win
            : StatColors.loss,
        stats: [
          _InsightStat(
            label: loc.warStarsTitle,
            value: _signedInt(clan.stars - opponent.stars),
            imageUrl: ImageAssets.attackStar,
          ),
          _InsightStat(
            label: loc.warDestructionRate,
            value: _signedPercent(
              clan.destructionPercentage - opponent.destructionPercentage,
            ),
            icon: Icons.percent_rounded,
          ),
        ],
      );
    }

    if (clan.stars < opponent.stars) {
      final starsToLead = opponent.stars - clan.stars + 1;
      final starsToTie = opponent.stars - clan.stars;
      final canLead = starsToLead <= clanRemainingAttacks * 3;
      final canTie = starsToTie <= clanRemainingAttacks * 3;
      final targetStars = canLead ? starsToLead : starsToTie;
      final perAttackPlan = _perAttackPlan(
        starsNeeded: targetStars,
        destructionGap: canLead ? 0 : percentGapForUsValue,
        attacksLeft: clanRemainingAttacks,
        teamSize: teamSize,
      );
      final opponentCanExtend = theirMaxStars > clan.stars;
      final message = canLead
          ? 'Still winnable: ${clan.name} needs +$starsToLead stars to lead. That is $perAttackPlan per remaining attack.'
          : canTie
          ? 'Win by stars is out of reach right now. Tie with +$starsToTie stars, then pass destruction by $percentGapForUs%. That is $perAttackPlan per remaining attack.'
          : 'No realistic star path left: max possible is $ourMaxStars stars against ${opponent.stars}. Focus cleanup and missed attacks.';

      return _WarStrategy(
        message: message,
        color: canLead || canTie ? StatColors.warStarGold : StatColors.loss,
        stats: [
          _InsightStat(
            label: canLead ? 'to lead' : 'to tie',
            value: '+${canLead ? starsToLead : starsToTie}',
            imageUrl: ImageAssets.attackStar,
          ),
          _InsightStat(
            label: 'per attack',
            value: perAttackPlan,
            icon: Icons.speed_rounded,
          ),
          _InsightStat(
            label: opponentCanExtend ? 'enemy can extend' : 'enemy capped',
            value: '$clanRemainingAttacks vs $opponentRemainingAttacks',
            imageUrl: ImageAssets.sword,
          ),
        ],
      );
    }

    if (clan.stars > opponent.stars) {
      final starsToLead = clan.stars - opponent.stars + 1;
      final starsToTie = clan.stars - opponent.stars;
      final opponentCanLead = starsToLead <= opponentRemainingAttacks * 3;
      final opponentCanTie = starsToTie <= opponentRemainingAttacks * 3;
      final starsToLock = (theirMaxStars - clan.stars + 1).clamp(
        0,
        clanRemainingAttacks * 3,
      );
      final lockValue = starsToLock == 0 ? 'locked' : '+$starsToLock';
      final lockPerAttack = _perAttackPlan(
        starsNeeded: starsToLock,
        destructionGap: 0,
        attacksLeft: clanRemainingAttacks,
        teamSize: teamSize,
      );
      final enemyTiePlan = _perAttackPlan(
        starsNeeded: starsToTie,
        destructionGap: percentGapForThemValue,
        attacksLeft: opponentRemainingAttacks,
        teamSize: teamSize,
      );
      final message = opponentCanLead
          ? 'Not safe yet: ${opponent.name} can still pass with +$starsToLead stars. Lock by adding $lockValue stars, about $lockPerAttack per remaining attack.'
          : opponentCanTie
          ? 'Lead is fragile: ${opponent.name} can tie stars with +$starsToTie and needs $percentGapForThem% destruction, about $enemyTiePlan per remaining attack.'
          : 'Star lead is safe: ${opponent.name} cannot catch the current score with remaining attacks.';

      return _WarStrategy(
        message: message,
        color: opponentCanLead || opponentCanTie
            ? StatColors.warStarGold
            : StatColors.win,
        stats: [
          _InsightStat(
            label: 'enemy needs',
            value: '+${opponentCanLead ? starsToLead : starsToTie}',
            imageUrl: ImageAssets.attackStar,
          ),
          _InsightStat(
            label: starsToLock == 0 ? 'secure' : 'per attack',
            value: starsToLock == 0 ? lockValue : lockPerAttack,
            imageUrl: null,
            icon: starsToLock == 0 ? Icons.shield_rounded : Icons.speed_rounded,
          ),
          _InsightStat(
            label: loc.warAttacksTitle,
            value: '$clanRemainingAttacks vs $opponentRemainingAttacks',
            imageUrl: ImageAssets.sword,
          ),
        ],
      );
    }

    final clanBehindOnDestruction =
        clan.destructionPercentage < opponent.destructionPercentage;
    final exactDraw =
        clan.destructionPercentage == opponent.destructionPercentage;
    final message = exactDraw
        ? 'Dead even: next star takes the lead. If stars stay tied, destruction decides it.'
        : clanBehindOnDestruction
        ? 'Tied on stars but behind on destruction. Gain +$percentGapForUs% or one extra star to take control, about ${_destructionPerAttack(percentGapForUsValue, clanRemainingAttacks, teamSize)} per remaining attack.'
        : 'Tied on stars with destruction advantage. Opponent needs +$percentGapForThem% or one extra star to pass, about ${_destructionPerAttack(percentGapForThemValue, opponentRemainingAttacks, teamSize)} per remaining attack.';
    final threatValue = exactDraw
        ? 'next star'
        : clanBehindOnDestruction
        ? '+$percentGapForUs%'
        : '+$percentGapForThem%';
    final perAttackValue = exactDraw
        ? _perAttackPlan(
            starsNeeded: 1,
            destructionGap: 0,
            attacksLeft: clanRemainingAttacks,
            teamSize: teamSize,
          )
        : clanBehindOnDestruction
        ? _destructionPerAttack(
            percentGapForUsValue,
            clanRemainingAttacks,
            teamSize,
          )
        : _destructionPerAttack(
            percentGapForThemValue,
            opponentRemainingAttacks,
            teamSize,
          );

    return _WarStrategy(
      message: message,
      color: StatColors.warStarGold,
      stats: [
        _InsightStat(
          label: 'swing',
          value: '+1',
          imageUrl: ImageAssets.attackStar,
        ),
        _InsightStat(
          label: exactDraw
              ? loc.warStarsTitle
              : clanBehindOnDestruction
              ? 'we need'
              : 'enemy needs',
          value: threatValue,
          icon: Icons.percent_rounded,
        ),
        _InsightStat(
          label: 'per attack',
          value: perAttackValue,
          icon: Icons.speed_rounded,
        ),
      ],
    );
  }

  String _warStatus(BuildContext context, WarClan clan, WarClan opponent) {
    final loc = AppLocalizations.of(context)!;
    final attacksPerPlayer = warInfo.effectiveAttacksPerMember;
    final teamSize = warInfo.teamSize ?? 15;
    final maxAttacks = attacksPerPlayer * teamSize;

    if (clan.stars == 0 &&
        opponent.stars == 0 &&
        clan.destructionPercentage == 0.0 &&
        opponent.destructionPercentage == 0.0) {
      return loc.warNotStarted;
    }

    if (warInfo.state == 'warEnded') {
      if (clan.stars > opponent.stars) return loc.warWonByStars(clan.name);
      if (opponent.stars > clan.stars) return loc.warLostByStars(clan.name);
      if (clan.destructionPercentage > opponent.destructionPercentage) {
        return loc.warWonByDestruction(clan.name);
      }
      if (opponent.destructionPercentage > clan.destructionPercentage) {
        return loc.warLostByDestruction(clan.name);
      }
      return loc.warPerfectDraw;
    }

    final clanRemainingAttacks = maxAttacks - clan.attacks;
    final opponentRemainingAttacks = maxAttacks - opponent.attacks;
    final clanMaxPossibleStars = clan.stars + (clanRemainingAttacks * 3);
    final opponentMaxPossibleStars =
        opponent.stars + (opponentRemainingAttacks * 3);

    if (clan.stars < opponent.stars) {
      final starsNeeded = opponent.stars - clan.stars + 1;
      final starsToTie = opponent.stars - clan.stars;

      if (starsNeeded > clanMaxPossibleStars - clan.stars) {
        if (starsToTie <= clanMaxPossibleStars - clan.stars) {
          return loc.warCanTieNeedsStars(clan.name, starsToTie);
        }
        return loc.warCannotCatchUp(clan.name);
      }

      return loc.warStarsNeededToTakeTheLead(
        clan.name,
        starsNeeded,
        starsToTie,
        (opponent.destructionPercentage - clan.destructionPercentage + 0.01)
            .toStringAsFixed(2),
      );
    }

    if (clan.stars > opponent.stars) {
      final starsNeeded = clan.stars - opponent.stars + 1;
      final starsToTie = clan.stars - opponent.stars;

      if (starsNeeded > opponentMaxPossibleStars - opponent.stars) {
        if (starsToTie <= opponentMaxPossibleStars - opponent.stars) {
          return loc.warCanTieNeedsStars(opponent.name, starsToTie);
        }
        return loc.warCannotCatchUp(opponent.name);
      }

      return loc.warStarsNeededToTakeTheLead(
        opponent.name,
        starsNeeded,
        starsToTie,
        (clan.destructionPercentage - opponent.destructionPercentage + 0.01)
            .toStringAsFixed(2),
      );
    }

    if (clan.destructionPercentage > opponent.destructionPercentage) {
      return loc.warStarsAndPercentNeededToTakeTheLead(
        opponent.name,
        (clan.destructionPercentage - opponent.destructionPercentage + 0.01)
            .toStringAsFixed(2),
      );
    }

    if (clan.destructionPercentage < opponent.destructionPercentage) {
      return loc.warStarsAndPercentNeededToTakeTheLead(
        clan.name,
        (opponent.destructionPercentage - clan.destructionPercentage + 0.01)
            .toStringAsFixed(2),
      );
    }

    return loc.warClanDraw;
  }
}

class _WarInsight {
  final String status;
  final String message;
  final Color color;
  final List<_InsightStat> stats;

  const _WarInsight({
    required this.status,
    required this.message,
    required this.color,
    required this.stats,
  });
}

class _WarStrategy {
  final String message;
  final Color color;
  final List<_InsightStat> stats;

  const _WarStrategy({
    required this.message,
    required this.color,
    required this.stats,
  });
}

class _InsightStat {
  final String label;
  final String value;
  final String? imageUrl;
  final IconData? icon;

  const _InsightStat({
    required this.label,
    required this.value,
    this.imageUrl,
    this.icon,
  });
}

class _WarInsightPanel extends StatelessWidget {
  final _WarInsight insight;

  const _WarInsightPanel({required this.insight});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: insight.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: insight.color.withValues(alpha: 0.26)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.76),
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: 34,
                child: Icon(
                  Icons.auto_graph_rounded,
                  size: 18,
                  color: insight.color,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.status,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    insight.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 7,
                    children: insight.stats
                        .map((stat) => _InsightStatView(stat: stat))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightStatView extends StatelessWidget {
  final _InsightStat stat;

  const _InsightStatView({required this.stat});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (stat.imageUrl != null)
          MobileWebImage(imageUrl: stat.imageUrl!, width: 16, height: 16)
        else
          Icon(stat.icon, size: 15, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          stat.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          stat.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _WarSectionPanel extends StatelessWidget {
  final Widget child;

  const _WarSectionPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;

  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _ComparisonMetric extends StatelessWidget {
  final String label;
  final String leftValue;
  final String rightValue;
  final double leftProgress;
  final double rightProgress;
  final Color leftColor;
  final Color rightColor;
  final String? iconUrl;
  final IconData? icon;

  const _ComparisonMetric({
    required this.label,
    required this.leftValue,
    required this.rightValue,
    required this.leftProgress,
    required this.rightProgress,
    required this.leftColor,
    required this.rightColor,
    this.iconUrl,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: _ProgressSide(
              value: leftValue,
              progress: leftProgress,
              color: leftColor,
              alignRight: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                SizedBox.square(
                  dimension: 30,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: iconUrl != null
                        ? MobileWebImage(imageUrl: iconUrl!)
                        : Icon(icon, size: 18, color: StatColors.warStarGold),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _ProgressSide(
              value: rightValue,
              progress: rightProgress,
              color: rightColor,
              alignRight: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressSide extends StatelessWidget {
  final String value;
  final double progress;
  final Color color;
  final bool alignRight;

  const _ProgressSide({
    required this.value,
    required this.progress,
    required this.color,
    required this.alignRight,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            width: double.infinity,
            height: 7,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.42),
                  ),
                ),
                Align(
                  alignment: alignRight
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: ColoredBox(color: color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StarsBreakdown extends StatelessWidget {
  final WarClan clan;
  final WarClan opponent;
  final Map<int, int> clanCounts;
  final Map<int, int> opponentCounts;

  const _StarsBreakdown({
    required this.clan,
    required this.opponent,
    required this.clanCounts,
    required this.opponentCounts,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BreakdownHeader(left: clan.name, right: opponent.name),
        const SizedBox(height: 6),
        for (final stars in const [3, 2, 1, 0]) ...[
          if (stars != 3) const SizedBox(height: 8),
          _BreakdownRow(
            stars: stars,
            left: clanCounts[stars] ?? 0,
            right: opponentCounts[stars] ?? 0,
          ),
        ],
      ],
    );
  }
}

class _BreakdownHeader extends StatelessWidget {
  final String left;
  final String right;

  const _BreakdownHeader({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );
    return Row(
      children: [
        Expanded(
          child: Text(
            left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        const SizedBox(width: 78),
        Expanded(
          child: Text(
            right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: style,
          ),
        ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final int stars;
  final int left;
  final int right;

  const _BreakdownRow({
    required this.stars,
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$left',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              return Opacity(
                opacity: index < stars ? 1 : 0.22,
                child: MobileWebImage(
                  imageUrl: ImageAssets.attackStar,
                  width: 18,
                  height: 18,
                ),
              );
            }),
          ),
          Expanded(
            child: Text(
              '$right',
              textAlign: TextAlign.end,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

double _safeRatio(num value, num max) {
  if (max <= 0) return 0;
  return (value / max).clamp(0.0, 1.0).toDouble();
}

Color _leaderColor(double value, double other) {
  if (value > other) return StatColors.win;
  if (value < other) return StatColors.loss;
  return StatColors.warStarGold;
}

double _percentGapToPass(double target, double current) {
  return (target - current + 0.01).clamp(0.01, 100.0).toDouble();
}

String _formatPercent(double value) {
  return value.toStringAsFixed(value >= 10 ? 1 : 2);
}

String _perAttackPlan({
  required int starsNeeded,
  required double destructionGap,
  required int attacksLeft,
  required int teamSize,
}) {
  if (attacksLeft <= 0) return 'no attacks';

  final parts = <String>[];
  if (starsNeeded > 0) {
    parts.add('${_decimalUp(starsNeeded / attacksLeft)}★');
  }
  if (destructionGap > 0) {
    parts.add(_destructionPerAttack(destructionGap, attacksLeft, teamSize));
  }
  return parts.isEmpty ? 'covered' : parts.join(' · ');
}

String _destructionPerAttack(
  double destructionGap,
  int attacksLeft,
  int teamSize,
) {
  if (attacksLeft <= 0) return 'no attacks';
  final totalBaseDestruction = destructionGap * teamSize;
  return '${_decimalUp(totalBaseDestruction / attacksLeft)}% dmg';
}

String _decimalUp(double value) {
  final tenths = (value * 10).ceil();
  final whole = tenths ~/ 10;
  final decimal = tenths % 10;
  return decimal == 0 ? '$whole' : '$whole.$decimal';
}

String _signedInt(int value) {
  if (value > 0) return '+$value';
  return value.toString();
}

String _signedPercent(double value) {
  if (value > 0) return '+${value.toStringAsFixed(2)}%';
  return '${value.toStringAsFixed(2)}%';
}
