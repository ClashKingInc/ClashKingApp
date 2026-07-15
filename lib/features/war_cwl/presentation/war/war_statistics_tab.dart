import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/war_cwl/data/war_functions.dart'
    show countStars;
import 'package:clashkingapp/features/war_cwl/models/war_clan.dart';
import 'package:clashkingapp/features/war_cwl/models/war_info.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war/widgets/war_calculator_card.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/common/widgets/empty_state.dart';
import 'package:flutter/material.dart';

class WarStatisticsTab extends StatefulWidget {
  const WarStatisticsTab({super.key, required this.warInfo});

  final WarInfo warInfo;

  @override
  State<WarStatisticsTab> createState() => _WarStatisticsTabState();
}

class _WarStatisticsTabState extends State<WarStatisticsTab> {
  bool _showCalculator = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final warInfo = widget.warInfo;
    final clan = warInfo.clan;
    final opponent = warInfo.opponent;

    if (clan == null || opponent == null) {
      return _WarSectionPanel(
        child: AppEmptyState(
          title: loc.generalNoDataAvailable,
          icon: Icons.history_toggle_off_rounded,
          padding: const EdgeInsets.all(16),
        ),
      );
    }

    final teamSize = warInfo.teamSize ?? 15;
    final attacksPerPlayer = warInfo.effectiveAttacksPerMember;
    final maxStars = teamSize * 3;
    final maxAttacks = teamSize * attacksPerPlayer;
    final clanStarCounts = countStars(clan.members);
    final opponentStarCounts = countStars(opponent.members);

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: _CalculatorActionButton(
            label: loc.warCalculatorFast,
            selected: _showCalculator,
            onTap: () {
              setState(() => _showCalculator = !_showCalculator);
            },
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _showCalculator
              ? Padding(
                  key: const ValueKey('war-calculator'),
                  padding: const EdgeInsets.only(top: 10),
                  child: WarCalculatorCard(
                    warInfo: warInfo,
                    initiallyExpanded: true,
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('war-calculator-empty')),
        ),
        const SizedBox(height: 10),
        _WarSectionPanel(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionHeader(label: loc.navigationStatistics),
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
        if (_shouldShowWarAnalysis(warInfo)) ...[
          const SizedBox(height: 10),
          _WarSectionPanel(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: _WarAnalysis(
                title: loc.warStateOfTheWar,
                scenario: _warScenario(
                  context,
                  clan,
                  opponent,
                  maxAttacks,
                  teamSize,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  bool _shouldShowWarAnalysis(WarInfo warInfo) {
    return warInfo.state == 'inWar' || warInfo.state == 'warInWar';
  }

  _WarScenario _warScenario(
    BuildContext context,
    WarClan clan,
    WarClan opponent,
    int maxAttacks,
    int teamSize,
  ) {
    final loc = AppLocalizations.of(context)!;
    final clanIsAhead = _isAhead(clan, opponent);
    final actor = clanIsAhead ? opponent : clan;
    final target = clanIsAhead ? clan : opponent;
    final attacksLeft = (maxAttacks - actor.attacks).clamp(0, maxAttacks);
    final starsToTie = (target.stars - actor.stars).clamp(0, maxAttacks * 3);
    final targetDestructionTotal = target.destructionPercentage * teamSize;
    final actorDestructionTotal = actor.destructionPercentage * teamSize;
    final percentToLead =
        (targetDestructionTotal - actorDestructionTotal + 0.01).clamp(
          0.0,
          teamSize * 100.0,
        );

    if (clan.stars == 0 &&
        opponent.stars == 0 &&
        clan.destructionPercentage == 0.0 &&
        opponent.destructionPercentage == 0.0) {
      return _WarScenario(
        label: loc.warAnalysisToWin,
        clanName: clan.name,
        attacksLeft: attacksLeft,
        starsPerAttack: 0,
        percentPerAttack: 0,
        impossible: false,
        lossRisk: false,
        waiting: true,
      );
    }

    var requiredStars = starsToTie.toDouble();
    var requiredPercent = percentToLead.toDouble();
    final perAttackStars = attacksLeft == 0
        ? requiredStars
        : requiredStars / attacksLeft;
    final perAttackPercent = attacksLeft == 0
        ? requiredPercent
        : requiredPercent / attacksLeft;

    if (perAttackStars > 3 || perAttackPercent > 100) {
      final starsToOutscore = (target.stars - actor.stars + 1).clamp(
        0,
        maxAttacks * 3,
      );
      final starsToOutscorePerAttack = attacksLeft == 0
          ? starsToOutscore.toDouble()
          : starsToOutscore / attacksLeft;
      if (starsToOutscorePerAttack <= 3) {
        requiredStars = starsToOutscore.toDouble();
        requiredPercent = 0;
      }
    }

    final starsPerAttack = attacksLeft == 0
        ? requiredStars
        : requiredStars / attacksLeft;
    final percentPerAttack = attacksLeft == 0
        ? requiredPercent
        : requiredPercent / attacksLeft;

    return _WarScenario(
      label: clanIsAhead ? loc.warAnalysisToLose : loc.warAnalysisToWin,
      clanName: actor.name,
      attacksLeft: attacksLeft,
      starsPerAttack: starsPerAttack,
      percentPerAttack: percentPerAttack,
      impossible:
          attacksLeft == 0 || starsPerAttack > 3 || percentPerAttack > 100,
      lossRisk: clanIsAhead,
    );
  }

  bool _isAhead(WarClan clan, WarClan opponent) {
    if (clan.stars != opponent.stars) return clan.stars > opponent.stars;
    return clan.destructionPercentage > opponent.destructionPercentage;
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

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return _SectionTitle(label: label);
  }
}

class _WarAnalysis extends StatelessWidget {
  final String title;
  final _WarScenario scenario;

  const _WarAnalysis({required this.title, required this.scenario});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = scenario.impossible
        ? StatColors.loss
        : scenario.lossRisk
        ? StatColors.warStarGold
        : StatColors.win;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            MobileWebImage(imageUrl: ImageAssets.war, width: 22, height: 22),
            const SizedBox(width: 8),
            Expanded(child: _SectionTitle(label: title)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              width: 4,
              height: 44,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${scenario.label}: ${scenario.clanName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    scenario.text(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WarScenario {
  final String label;
  final String clanName;
  final int attacksLeft;
  final double starsPerAttack;
  final double percentPerAttack;
  final bool impossible;
  final bool lossRisk;
  final bool waiting;

  const _WarScenario({
    required this.label,
    required this.clanName,
    required this.attacksLeft,
    required this.starsPerAttack,
    required this.percentPerAttack,
    required this.impossible,
    required this.lossRisk,
    this.waiting = false,
  });

  String text(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    if (waiting) return loc.warNotStarted;
    if (attacksLeft == 0) return loc.warAnalysisNoAttacksLeft;

    final stars = _formatStars(starsPerAttack);
    final percent = percentPerAttack.ceil().clamp(0, 999).toString();
    if (impossible) {
      return loc.warAnalysisImpossibleScenario(attacksLeft, stars, percent);
    }
    return loc.warAnalysisScenario(attacksLeft, stars, percent);
  }

  String _formatStars(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}

class _CalculatorActionButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CalculatorActionButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).width < 360;

    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: SizedBox(
            height: 44,
            width: compact ? 44 : 176,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: selected
                    ? colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.86,
                      )
                    : colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.55),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 12),
                child: Row(
                  mainAxisAlignment: compact
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!compact) ...[
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Icon(
                      Icons.calculate_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ComparisonMetric extends StatelessWidget {
  static const double _centerWidth = 78;

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
          SizedBox(
            width: _centerWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                    heightFactor: 1,
                    child: SizedBox.expand(child: ColoredBox(color: color)),
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
