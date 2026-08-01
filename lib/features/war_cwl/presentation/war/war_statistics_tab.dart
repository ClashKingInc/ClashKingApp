import 'dart:math' as math;

import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/responsive_card_grid.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/war_cwl/data/war_functions.dart'
    show countStars;
import 'package:clashkingapp/features/war_cwl/models/war_clan.dart';
import 'package:clashkingapp/features/war_cwl/models/war_info.dart';
import 'package:clashkingapp/features/war_cwl/models/war_member.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war/widgets/war_calculator_card.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/common/widgets/empty_state.dart';
import 'package:flutter/foundation.dart';
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
    final isDesktopWeb = kIsWeb && MediaQuery.sizeOf(context).width >= 900;
    final statPanels = <Widget>[
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
                leftValue: '${clan.destructionPercentage.toStringAsFixed(2)}%',
                rightValue:
                    '${opponent.destructionPercentage.toStringAsFixed(2)}%',
                leftProgress: _safeRatio(clan.destructionPercentage, 100),
                rightProgress: _safeRatio(opponent.destructionPercentage, 100),
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
      if (_shouldShowWarAnalysis(warInfo))
        _WarSectionPanel(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: _WarAnalysis(
              title: loc.warStateOfTheWar,
              analysis: _warAnalysis(
                context,
                clan,
                opponent,
                maxAttacks,
                teamSize,
              ),
            ),
          ),
        ),
    ];

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
        if (isDesktopWeb)
          ResponsiveCardGrid(
            itemCount: statPanels.length,
            minItemWidth: 420,
            maxColumns: 2,
            spacing: 10,
            itemBuilder: (_, index) => statPanels[index],
          )
        else ...[
          for (var index = 0; index < statPanels.length; index++) ...[
            statPanels[index],
            if (index < statPanels.length - 1) const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }

  bool _shouldShowWarAnalysis(WarInfo warInfo) {
    return warInfo.state == 'inWar' || warInfo.state == 'warInWar';
  }

  _WarAnalysisResult _warAnalysis(
    BuildContext context,
    WarClan clan,
    WarClan opponent,
    int maxAttacks,
    int teamSize,
  ) {
    final loc = AppLocalizations.of(context)!;
    final copy = _WarAnalysisCopy(loc);
    final clanState = _WarSideState.fromWar(
      clan,
      target: opponent,
      maxAttacks: maxAttacks,
      maxStars: teamSize * 3,
    );
    final opponentState = _WarSideState.fromWar(
      opponent,
      target: clan,
      maxAttacks: maxAttacks,
      maxStars: teamSize * 3,
    );

    if (clan.stars == 0 &&
        opponent.stars == 0 &&
        clan.destructionPercentage == 0.0 &&
        opponent.destructionPercentage == 0.0) {
      return _WarAnalysisResult(
        status: _WarAnalysisStatus.waiting,
        headline: loc.warNotStarted,
        lines: [
          copy.remainingAttempts(clanState.remainingAttacks),
          copy.remainingAttempts(opponentState.remainingAttacks),
        ],
      );
    }

    if (clanState.isPerfect && opponentState.isPerfect) {
      return _WarAnalysisResult(
        status: _WarAnalysisStatus.locked,
        headline: loc.warPerfectDraw,
        lines: [copy.noBetterResult()],
      );
    }

    final tiedNow =
        clanState.currentScore.compareTo(opponentState.currentScore) == 0;
    if (tiedNow) {
      return _WarAnalysisResult(
        status: _WarAnalysisStatus.live,
        headline: copy.warStillOpen(),
        lines: [
          copy.currentDraw(),
          copy.remainingAttempts(clanState.remainingAttacks),
          copy.remainingAttempts(opponentState.remainingAttacks),
        ],
      );
    }

    final clanIsAhead = _isAhead(clan, opponent);
    final leader = clanIsAhead ? clan : opponent;
    final chaser = clanIsAhead ? opponent : clan;
    final leaderState = clanIsAhead ? clanState : opponentState;
    final chaserState = clanIsAhead ? opponentState : clanState;
    final targetMembers = clanIsAhead ? clan.members : opponent.members;
    final chaserCanWin = chaserState.canBeat(leaderState.currentScore);
    final chaserCanTie = chaserState.canTie(leaderState.currentScore);

    if (leaderState.isPerfect && !chaserState.isPerfect) {
      if (chaserCanTie) {
        return _drawOnlyAnalysis(
          copy: copy,
          leader: leader,
          chaser: chaser,
          chaserState: chaserState,
          targetMembers: targetMembers,
        );
      }

      return _advantageAnalysis(
        copy: copy,
        leader: leader,
        chaser: chaser,
        chaserState: chaserState,
        targetScore: leaderState.currentScore,
        targetMembers: targetMembers,
        chaserCanTie: false,
      );
    }

    if (chaserCanWin) {
      return _WarAnalysisResult(
        status: _WarAnalysisStatus.live,
        headline: copy.warStillOpen(),
        lines: [
          copy.currentLeader(leader.name),
          ..._objectiveLines(
            copy: copy,
            actor: chaser,
            actorState: chaserState,
            targetScore: leaderState.currentScore,
            targetMembers: targetMembers,
            allowWin: true,
          ),
        ],
      );
    }

    if (chaserCanTie) {
      return _drawOnlyAnalysis(
        copy: copy,
        leader: leader,
        chaser: chaser,
        chaserState: chaserState,
        targetMembers: targetMembers,
      );
    }

    return _advantageAnalysis(
      copy: copy,
      leader: leader,
      chaser: chaser,
      chaserState: chaserState,
      targetScore: leaderState.currentScore,
      targetMembers: targetMembers,
      chaserCanTie: false,
    );
  }

  _WarAnalysisResult _advantageAnalysis({
    required _WarAnalysisCopy copy,
    required WarClan leader,
    required WarClan chaser,
    required _WarSideState chaserState,
    required _WarScore targetScore,
    required List<WarMember> targetMembers,
    required bool chaserCanTie,
  }) {
    return _WarAnalysisResult(
      status: _WarAnalysisStatus.advantage,
      headline: copy.cannotLose(leader.name),
      lines: [
        if (chaserCanTie) copy.canStillTie(chaser.name),
        if (!chaserCanTie) copy.cannotCatchUp(chaser.name),
        ..._objectiveLines(
          copy: copy,
          actor: chaser,
          actorState: chaserState,
          targetScore: targetScore,
          targetMembers: targetMembers,
          allowWin: false,
        ),
      ],
    );
  }

  _WarAnalysisResult _drawOnlyAnalysis({
    required _WarAnalysisCopy copy,
    required WarClan leader,
    required WarClan chaser,
    required _WarSideState chaserState,
    required List<WarMember> targetMembers,
  }) {
    return _WarAnalysisResult(
      status: _WarAnalysisStatus.drawOnly,
      headline: copy.cannotLose(leader.name),
      lines: [
        copy.canStillTie(chaser.name),
        copy.objectivePerfectWar(),
        ..._perfectObjectiveLines(
          copy: copy,
          chaserState: chaserState,
          targetMembers: targetMembers,
        ),
      ],
    );
  }

  List<String> _perfectObjectiveLines({
    required _WarAnalysisCopy copy,
    required _WarSideState chaserState,
    required List<WarMember> targetMembers,
  }) {
    final lines = <String>[];
    final starsNeeded = (chaserState.maxStars - chaserState.currentScore.stars)
        .clamp(0, chaserState.maxStars)
        .toInt();
    final destructionNeeded = math.max(
      0.0,
      100.0 - chaserState.currentScore.destruction,
    );

    if (starsNeeded > 0) {
      lines.add(copy.starsOnUntripledBases(starsNeeded));
    }
    if (destructionNeeded > 0.004) {
      lines.add(copy.destructionPoints(copy.percentPoints(destructionNeeded)));
    }
    lines.add(copy.remainingAttempts(chaserState.remainingAttacks));
    lines.addAll(_opportunityLines(copy, targetMembers));
    return lines;
  }

  List<String> _objectiveLines({
    required _WarAnalysisCopy copy,
    required WarClan actor,
    required _WarSideState actorState,
    required _WarScore targetScore,
    required List<WarMember> targetMembers,
    required bool allowWin,
  }) {
    final lines = <String>[];
    final starsForWin = (targetScore.stars + 1 - actorState.currentScore.stars)
        .clamp(0, actorState.maxStars)
        .toInt();
    final starsForTie = (targetScore.stars - actorState.currentScore.stars)
        .clamp(0, actorState.maxStars)
        .toInt();
    final destructionForLead = math.max(
      0.0,
      targetScore.destruction - actorState.currentScore.destruction + 0.01,
    );

    if (allowWin && starsForWin > 0) {
      lines.add(copy.starsToWin(actor.name, starsForWin));
    } else if (starsForTie > 0) {
      lines.add(copy.starsToTie(actor.name, starsForTie));
    } else if (destructionForLead > 0.004) {
      lines.add(copy.destructionToLead(copy.percentPoints(destructionForLead)));
    }

    lines.add(copy.remainingAttempts(actorState.remainingAttacks));
    lines.addAll(_opportunityLines(copy, targetMembers));
    return lines;
  }

  List<String> _opportunityLines(
    _WarAnalysisCopy copy,
    List<WarMember> targetMembers,
  ) {
    final opportunities =
        targetMembers
            .where(
              (member) =>
                  member.bestOpponentAttack == null ||
                  member.bestOpponentAttack!.stars < 3 ||
                  member.bestOpponentAttack!.destructionPercentage < 100,
            )
            .toList()
          ..sort((a, b) {
            final aAttack = a.bestOpponentAttack;
            final bAttack = b.bestOpponentAttack;
            final starCompare = (bAttack?.stars ?? 0).compareTo(
              aAttack?.stars ?? 0,
            );
            if (starCompare != 0) return starCompare;
            final destructionCompare = (bAttack?.destructionPercentage ?? 0)
                .compareTo(aAttack?.destructionPercentage ?? 0);
            if (destructionCompare != 0) return destructionCompare;
            return a.mapPosition.compareTo(b.mapPosition);
          });

    return opportunities.take(2).map((member) {
      final attack = member.bestOpponentAttack;
      return copy.opportunity(
        member.mapPosition,
        attack?.stars ?? 0,
        attack?.destructionPercentage ?? 0,
      );
    }).toList();
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
  final _WarAnalysisResult analysis;

  const _WarAnalysis({required this.title, required this.analysis});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = switch (analysis.status) {
      _WarAnalysisStatus.live => StatColors.win,
      _WarAnalysisStatus.advantage => StatColors.win,
      _WarAnalysisStatus.drawOnly => StatColors.warStarGold,
      _WarAnalysisStatus.locked => colorScheme.onSurfaceVariant,
      _WarAnalysisStatus.waiting => colorScheme.primary,
    };
    final visibleLines = analysis.lines.take(5).toList(growable: false);

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
                    analysis.headline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (var index = 0; index < visibleLines.length; index++) ...[
                    Text(
                      visibleLines[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    if (index < visibleLines.length - 1)
                      const SizedBox(height: 3),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum _WarAnalysisStatus { live, advantage, drawOnly, locked, waiting }

class _WarAnalysisResult {
  final _WarAnalysisStatus status;
  final String headline;
  final List<String> lines;

  const _WarAnalysisResult({
    required this.status,
    required this.headline,
    required this.lines,
  });
}

class _WarScore {
  final int stars;
  final double destruction;

  const _WarScore({required this.stars, required this.destruction});

  int compareTo(_WarScore other) {
    if (stars != other.stars) return stars.compareTo(other.stars);
    return destruction.compareTo(other.destruction);
  }
}

class _WarSideState {
  final _WarScore currentScore;
  final _WarScore potentialScore;
  final int remainingAttacks;
  final int maxStars;

  const _WarSideState({
    required this.currentScore,
    required this.potentialScore,
    required this.remainingAttacks,
    required this.maxStars,
  });

  bool get isPerfect =>
      currentScore.stars >= maxStars && currentScore.destruction >= 100.0;

  bool canBeat(_WarScore target) => potentialScore.compareTo(target) > 0;

  bool canTie(_WarScore target) =>
      potentialScore.stars >= target.stars &&
      potentialScore.destruction + 0.0001 >= target.destruction;

  factory _WarSideState.fromWar(
    WarClan side, {
    required WarClan target,
    required int maxAttacks,
    required int maxStars,
  }) {
    final remainingAttacks = (maxAttacks - side.attacks)
        .clamp(0, maxAttacks)
        .toInt();
    return _WarSideState(
      currentScore: _WarScore(
        stars: side.stars,
        destruction: side.destructionPercentage,
      ),
      potentialScore: _potentialScore(side, target, remainingAttacks, maxStars),
      remainingAttacks: remainingAttacks,
      maxStars: maxStars,
    );
  }

  static _WarScore _potentialScore(
    WarClan side,
    WarClan target,
    int remainingAttacks,
    int maxStars,
  ) {
    if (remainingAttacks <= 0) {
      return _WarScore(
        stars: side.stars,
        destruction: side.destructionPercentage,
      );
    }

    if (target.members.isEmpty) {
      return _WarScore(
        stars: math.min(maxStars, side.stars + remainingAttacks * 3),
        destruction: 100,
      );
    }

    final baseCount = math.max(1, target.members.length);
    final improvements =
        target.members.map((member) {
          final attack = member.bestOpponentAttack;
          return _WarBaseImprovement(
            starGain: math.max(0, 3 - (attack?.stars ?? 0)),
            destructionGain:
                math.max(0, 100 - (attack?.destructionPercentage ?? 0)) /
                baseCount,
          );
        }).toList()..sort((a, b) {
          final starCompare = b.starGain.compareTo(a.starGain);
          if (starCompare != 0) return starCompare;
          return b.destructionGain.compareTo(a.destructionGain);
        });

    final selected = improvements.take(remainingAttacks);
    final potentialStars = selected.fold<int>(
      side.stars,
      (sum, improvement) => sum + improvement.starGain,
    );
    final potentialDestruction = selected.fold<double>(
      side.destructionPercentage,
      (sum, improvement) => sum + improvement.destructionGain,
    );

    return _WarScore(
      stars: math.min(maxStars, potentialStars),
      destruction: potentialDestruction.clamp(0.0, 100.0).toDouble(),
    );
  }
}

class _WarBaseImprovement {
  final int starGain;
  final double destructionGain;

  const _WarBaseImprovement({
    required this.starGain,
    required this.destructionGain,
  });
}

class _WarAnalysisCopy {
  final AppLocalizations loc;

  const _WarAnalysisCopy(this.loc);

  bool get _fr => loc.localeName.startsWith('fr');

  String warStillOpen() => _fr ? 'Guerre encore ouverte' : 'War still open';

  String currentLeader(String clan) =>
      _fr ? '$clan mène actuellement' : '$clan is currently ahead';

  String currentDraw() =>
      _fr ? 'Les deux clans sont à égalité' : 'Both clans are tied';

  String cannotLose(String clan) =>
      _fr ? '$clan ne peut plus perdre' : '$clan can no longer lose';

  String canStillTie(String clan) =>
      _fr ? '$clan peut encore égaliser' : '$clan can still tie';

  String cannotCatchUp(String clan) => loc.warCannotCatchUp(clan);

  String objectivePerfectWar() =>
      _fr ? 'Objectif: guerre parfaite' : 'Objective: perfect war';

  String starsOnUntripledBases(int stars) => _fr
      ? '+$stars ${_plural(stars, 'étoile', 'étoiles')} sur ${_plural(stars, 'une base non triplée', 'des bases non triplées')}'
      : '+$stars ${_plural(stars, 'star', 'stars')} on untripled bases';

  String starsToWin(String clan, int stars) => _fr
      ? '$clan doit gagner +$stars ${_plural(stars, 'étoile', 'étoiles')}'
      : '$clan needs +$stars ${_plural(stars, 'star', 'stars')} to take the lead';

  String starsToTie(String clan, int stars) => _fr
      ? '$clan doit gagner +$stars ${_plural(stars, 'étoile', 'étoiles')} pour égaliser'
      : '$clan needs +$stars ${_plural(stars, 'star', 'stars')} to tie';

  String destructionToLead(String points) => _fr
      ? '+$points pt de destruction pour passer devant'
      : '+$points destruction ${points == '1' ? 'point' : 'points'} to lead';

  String destructionPoints(String points) =>
      _fr ? '+$points pt de destruction' : '+$points destruction points';

  String remainingAttempts(int attacks) => _fr
      ? '$attacks ${_plural(attacks, 'tentative restante', 'tentatives restantes')}'
      : '$attacks ${_plural(attacks, 'attempt', 'attempts')} left';

  String opportunity(int mapPosition, int stars, int destruction) => _fr
      ? '#$mapPosition: déjà $stars ${_plural(stars, 'étoile', 'étoiles')}, $destruction%'
      : '#$mapPosition: currently $stars ${_plural(stars, 'star', 'stars')}, $destruction%';

  String noBetterResult() =>
      _fr ? 'Aucun meilleur résultat possible' : 'No better result is possible';

  String percentPoints(double value) {
    final text = value >= 10
        ? value.toStringAsFixed(1)
        : value.toStringAsFixed(2);
    return _fr ? text.replaceFirst('.', ',') : text;
  }

  String _plural(int count, String one, String many) => count == 1 ? one : many;
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
