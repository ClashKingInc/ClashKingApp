import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/common/widgets/buttons/info_button.dart';
import 'package:clashkingapp/common/widgets/header_widgets.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/functions/functions.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/war_cwl/models/war_member_presence.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class PlayerToDoHeader extends StatelessWidget {
  final List<Player> players;
  final Map<String, WarMemberPresence> memberPresenceMap;

  const PlayerToDoHeader({
    super.key,
    required this.players,
    required this.memberPresenceMap,
  });

  @override
  Widget build(BuildContext context) {
    final summary = _TodoHeaderSummary.fromPlayers(players, memberPresenceMap);
    final imageHeight = MediaQuery.of(context).padding.top + 500;

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: imageHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.50),
                  BlendMode.darken,
                ),
                child: CachedNetworkImage(
                  imageUrl: ImageAssets.homeBaseBackground,
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                  errorWidget: (context, url, error) =>
                      ColoredBox(color: Theme.of(context).colorScheme.surface),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.36),
                      Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.64),
                      Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.92),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _TodoHeaderActions(
                onInfoTap: () =>
                    _showExplanation(context, AppLocalizations.of(context)!),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _TodoIdentity(summary: summary),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 11, bottom: 8),
              child: _TodoStatsPanel(summary: summary),
            ),
          ],
        ),
      ],
    );
  }

  void _showExplanation(BuildContext context, AppLocalizations loc) {
    showInfoPopup(
      context,
      TextSpan(
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        children: [
          TextSpan(text: "${loc.todoExplanationIntro}\n\n"),
          TextSpan(
            text: "${loc.todoExplanationLegendsTitle}\n",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: "${loc.todoExplanationLegends}\n\n"),
          TextSpan(
            text: "${loc.todoExplanationRaidsTitle}\n",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: "${loc.todoExplanationRaids}\n\n"),
          TextSpan(
            text: "${loc.todoExplanationClanWarsTitle}\n",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: "${loc.todoExplanationClanWars}\n\n"),
          TextSpan(
            text: "${loc.todoExplanationCwlTitle}\n",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: "${loc.todoExplanationCwl}\n\n"),
          TextSpan(
            text: "${loc.todoExplanationPassAndGamesTitle}\n",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: "${loc.todoExplanationPassAndGames}\n\n"),
          TextSpan(text: loc.todoExplanationConclusion),
        ],
      ),
      loc.todoExplanationTitle,
    );
  }
}

class _TodoHeaderActions extends StatelessWidget {
  final VoidCallback onInfoTap;

  const _TodoHeaderActions({required this.onInfoTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HeaderIconButton(
          icon: Icons.arrow_back_rounded,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onTap: () => Navigator.of(context).pop(),
          showBackground: false,
        ),
        const Spacer(),
        HeaderIconButton(
          icon: Icons.info_outline_rounded,
          tooltip: AppLocalizations.of(context)!.todoExplanationTitle,
          onTap: onInfoTap,
          showBackground: false,
        ),
      ],
    );
  }
}

class _TodoIdentity extends StatelessWidget {
  final _TodoHeaderSummary summary;

  const _TodoIdentity({required this.summary});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth.clamp(0.0, 360.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                MobileWebImage(
                  imageUrl: ImageAssets.iconBuilderPotion,
                  width: 64,
                  height: 64,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.todoTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          height: 1.02,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        loc.todoAccountsNumber(summary.totalAccounts),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.62),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.05,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TodoStatsPanel extends StatelessWidget {
  final _TodoHeaderSummary summary;

  const _TodoStatsPanel({required this.summary});

  @override
  Widget build(BuildContext context) {
    final percent = (summary.progressRatio * 100).round();
    final loc = AppLocalizations.of(context)!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _TodoProgressSummaryTile(summary: summary, percent: percent),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _TodoChipRows(
            children: [
              if (summary.legendTotal > 0)
                _TodoQuickChip(
                  value: '${summary.legendDone}/${summary.legendTotal}',
                  imageUrl: ImageAssets.legendBlazonNoPadding,
                  tooltip: loc.legendsTitle,
                ),
              if (summary.warTotal > 0)
                _TodoQuickChip(
                  value: '${summary.warDone}/${summary.warTotal}',
                  imageUrl: ImageAssets.war,
                  tooltip: loc.warTitle,
                ),
              if (summary.cwlTotal > 0)
                _TodoQuickChip(
                  value: '${summary.cwlDone}/${summary.cwlTotal}',
                  imageUrl: ImageAssets.cwlSwordsNoBorder,
                  tooltip: loc.cwlTitle,
                ),
              if (summary.raidTotal > 0)
                _TodoQuickChip(
                  value: '${summary.raidDone}/${summary.raidTotal}',
                  imageUrl: ImageAssets.raidAttacks,
                  tooltip: loc.raidsTitle,
                ),
              if (summary.clanGamesTotal > 0)
                _TodoQuickChip(
                  value: summary.compactValue(
                    context,
                    summary.clanGamesDone,
                    summary.clanGamesTotal,
                  ),
                  imageUrl: ImageAssets.clanGamesMedals,
                  tooltip: loc.gameClanGames,
                ),
              _TodoQuickChip(
                value: summary.compactValue(
                  context,
                  summary.seasonDone,
                  summary.seasonTotal,
                ),
                imageUrl: ImageAssets.iconGoldPass,
                tooltip: loc.gameSeasonPass,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TodoProgressSummaryTile extends StatelessWidget {
  final _TodoHeaderSummary summary;
  final int percent;

  const _TodoProgressSummaryTile({
    required this.summary,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    final color = summary.openTasks == 0 ? Colors.green : colorScheme.primary;
    final completedTasks = summary.totalTasks - summary.openTasks;

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _HeaderProgressRing(
            ratio: summary.progressRatio,
            percent: percent,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  summary.openTasks == 0
                      ? loc.generalCompleted
                      : '${summary.openTasks} ${loc.generalRemaining}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$completedTasks/${summary.totalTasks} ${loc.generalCompleted} · ${loc.todoAccountsNumber(summary.totalAccounts)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderProgressRing extends StatelessWidget {
  final double ratio;
  final int percent;
  final Color color;

  const _HeaderProgressRing({
    required this.ratio,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const size = 52.0;

    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _HeaderRingPainter(
          value: ratio,
          color: color,
          trackColor: colorScheme.surfaceContainerHighest,
        ),
        child: Center(
          child: Text(
            '$percent%',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderRingPainter extends CustomPainter {
  final double value;
  final Color color;
  final Color trackColor;

  const _HeaderRingPainter({
    required this.value,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.15;
    final rect =
        Offset(strokeWidth / 2, strokeWidth / 2) &
        Size(size.width - strokeWidth, size.height - strokeWidth);
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, trackPaint);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value.clamp(0, 1),
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HeaderRingPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}

class _TodoChipRows extends StatelessWidget {
  final List<_TodoQuickChip> children;

  const _TodoChipRows({required this.children});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 7,
      runSpacing: 7,
      children: children,
    );
  }
}

class _TodoQuickChip extends StatelessWidget {
  final String value;
  final String? imageUrl;
  final String tooltip;

  const _TodoQuickChip({
    required this.value,
    this.imageUrl,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = colorScheme.onSurface;

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imageUrl != null && imageUrl!.isNotEmpty)
              MobileWebImage(imageUrl: imageUrl!, width: 19, height: 19)
            else
              Icon(Icons.info_rounded, size: 19, color: foreground),
            const SizedBox(width: 5),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 132),
              child: Text(
                value,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodoHeaderSummary {
  const _TodoHeaderSummary({
    required this.totalAccounts,
    required this.openTasks,
    required this.completedTasks,
    required this.progressRatio,
    required this.legendDone,
    required this.legendTotal,
    required this.warDone,
    required this.warTotal,
    required this.cwlDone,
    required this.cwlTotal,
    required this.raidDone,
    required this.raidTotal,
    required this.clanGamesDone,
    required this.clanGamesTotal,
    required this.seasonDone,
    required this.seasonTotal,
  });

  final int totalAccounts;
  final int openTasks;
  final int completedTasks;
  final double progressRatio;
  final int legendDone;
  final int legendTotal;
  final int warDone;
  final int warTotal;
  final int cwlDone;
  final int cwlTotal;
  final int raidDone;
  final int raidTotal;
  final int clanGamesDone;
  final int clanGamesTotal;
  final int seasonDone;
  final int seasonTotal;

  int get totalTasks => openTasks + completedTasks;

  factory _TodoHeaderSummary.fromPlayers(
    List<Player> players,
    Map<String, WarMemberPresence> presenceMap,
  ) {
    final now = DateTime.now();
    final activeThreshold = now.subtract(const Duration(days: 14));
    var legendDone = 0;
    var legendTotal = 0;
    var warDone = 0;
    var warTotal = 0;
    var cwlDone = 0;
    var cwlTotal = 0;
    var raidDone = 0;
    var raidTotal = 0;
    var clanGamesDone = 0;
    var clanGamesTotal = 0;
    var seasonDone = 0;
    var seasonTotal = 0;
    var openTasks = 0;
    var completedTasks = 0;
    final progressMetrics = <String, TodoProgressMetric>{};
    final progressMetricOrder = <String>[];

    for (final player in players) {
      final isActive = player.lastOnline.isAfter(activeThreshold);
      if (!isActive) {
        continue;
      }

      final presence = presenceMap[player.tag] ?? WarMemberPresence.empty();
      var playerOpenTasks = 0;

      for (final metric in _progressMetricsForPlayer(player, presence)) {
        final existing = progressMetrics[metric.label];
        if (existing == null) {
          progressMetrics[metric.label] = metric;
          progressMetricOrder.add(metric.label);
        } else {
          progressMetrics[metric.label] = TodoProgressMetric(
            label: metric.label,
            done: existing.done + metric.done.clamp(0, metric.total),
            total: existing.total + metric.total,
            progressDone:
                existing.progressDone +
                metric.progressDone.clamp(0, metric.progressTotal),
            progressTotal: existing.progressTotal + metric.progressTotal,
          );
        }
      }

      seasonDone += player.currentSeasonPoints;
      seasonTotal += requiredSeasonPassPoints;
      if (player.seasonPassRatio < 1) {
        playerOpenTasks++;
      } else {
        completedTasks++;
      }

      if (player.league == 'Legend League' &&
          player.currentLegendSeason?.currentDay != null) {
        final done = player.currentLegendSeason?.currentDay?.totalAttacks ?? 0;
        legendDone += done;
        legendTotal += 8;
        if (done < 8) {
          playerOpenTasks++;
        } else {
          completedTasks++;
        }
      }

      final warData = player.warData;
      if (warData != null &&
          warData.state == 'inWar' &&
          !_isSameWarAsCwl(player)) {
        final total = warData.attacksPerMember ?? 0;
        final done = warData.getAttacksDoneByPlayer(player.tag, player.clanTag);
        if (total > 0) {
          warDone += done;
          warTotal += total;
          if (done < total) {
            playerOpenTasks++;
          } else {
            completedTasks++;
          }
        }
      }

      if (presence.attacksAvailable > 0) {
        cwlDone += presence.attacksDone;
        cwlTotal += presence.attacksAvailable;
        if (presence.attacksDone < presence.attacksAvailable) {
          playerOpenTasks++;
        } else {
          completedTasks++;
        }
      }

      if (isInTimeFrameForRaid()) {
        final done = player.raids?.attackDone ?? 0;
        final total = player.raids?.attackLimit ?? 5;
        raidDone += done;
        raidTotal += total;
        if (done < total) {
          playerOpenTasks++;
        } else {
          completedTasks++;
        }
      }

      if (isInTimeFrameForClanGames()) {
        clanGamesDone += player.currentClanGamesPoints;
        clanGamesTotal += requiredClanGamesPoints;
        if (player.clanGamesRatio < 1) {
          playerOpenTasks++;
        } else {
          completedTasks++;
        }
      }

      openTasks += playerOpenTasks;
    }

    return _TodoHeaderSummary(
      totalAccounts: players.length,
      openTasks: openTasks,
      completedTasks: completedTasks,
      progressRatio: _progressRatioFromMetrics(
        progressMetricOrder,
        progressMetrics,
      ),
      legendDone: legendDone,
      legendTotal: legendTotal,
      warDone: warDone,
      warTotal: warTotal,
      cwlDone: cwlDone,
      cwlTotal: cwlTotal,
      raidDone: raidDone,
      raidTotal: raidTotal,
      clanGamesDone: clanGamesDone,
      clanGamesTotal: clanGamesTotal,
      seasonDone: seasonDone,
      seasonTotal: seasonTotal,
    );
  }

  String compactValue(BuildContext context, int done, int total) {
    final locale = Localizations.localeOf(context).toString();
    final compact = NumberFormat.compact(locale: locale);
    if (total >= 1000) {
      return '${compact.format(done)}/${compact.format(total)}';
    }
    return '$done/$total';
  }

  static double _progressRatioFromMetrics(
    List<String> order,
    Map<String, TodoProgressMetric> metrics,
  ) {
    if (order.isEmpty) return 1.0;
    final totalDone = order.fold<double>(
      0,
      (sum, label) =>
          sum +
          metrics[label]!.progressDone.clamp(0, metrics[label]!.progressTotal),
    );
    final total = order.fold<double>(
      0,
      (sum, label) => sum + metrics[label]!.progressTotal,
    );
    if (total == 0) return 1.0;
    return (totalDone / total).clamp(0.0, 1.0);
  }

  static List<TodoProgressMetric> _progressMetricsForPlayer(
    Player player,
    WarMemberPresence presence,
  ) {
    return player.getTodoProgressMetrics(memberCwl: presence);
  }

  static bool _isSameWarAsCwl(Player player) {
    if (player.warData == null || player.clan?.warCwl?.warInfo == null) {
      return false;
    }

    final regularWar = player.warData!;
    final cwlWar = player.clan!.warCwl!.warInfo;
    return (regularWar.clan?.tag == cwlWar.clan?.tag &&
            regularWar.opponent?.tag == cwlWar.opponent?.tag) ||
        (regularWar.clan?.tag == cwlWar.opponent?.tag &&
            regularWar.opponent?.tag == cwlWar.clan?.tag);
  }
}
