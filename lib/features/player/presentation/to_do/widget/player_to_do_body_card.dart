import 'dart:math' as math;

import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/functions/functions.dart';
import 'package:clashkingapp/core/services/bookmark_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/presentation/player/player_page.dart';
import 'package:clashkingapp/features/war_cwl/models/war_member_presence.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PlayerToDoBodyCard extends StatelessWidget {
  final Player player;
  final WarMemberPresence member;

  const PlayerToDoBodyCard({
    super.key,
    required this.player,
    required this.member,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ratio = player.getTodoProgressRatio(memberCwl: member);
    final percent = (ratio * 100).round();
    final tasks = _TodoTask.build(context, player, member);
    final openTasks = tasks.where((task) => !task.done).length;
    final statusColor = openTasks == 0 ? StatColors.win : colorScheme.primary;
    final bookmarked = context.watch<BookmarkService>().isPlayerBookmarked(
      player.tag,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerScreen(selectedPlayer: player),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _TownHallBadge(player: player, bookmarked: bookmarked),
                  const SizedBox(width: 12),
                  Expanded(child: _PlayerIdentity(player: player)),
                  const SizedBox(width: 10),
                  _TodoProgressRing(
                    ratio: ratio,
                    percent: percent,
                    color: statusColor,
                    size: 54,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (tasks.isEmpty)
                _QuietState(color: statusColor)
              else
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: tasks
                      .map((task) => _TaskPill(task: task))
                      .toList(growable: false),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TownHallBadge extends StatelessWidget {
  final Player player;
  final bool bookmarked;

  const _TownHallBadge({required this.player, required this.bookmarked});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 66,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              SizedBox.square(
                dimension: 62,
                child: MobileWebImage(imageUrl: player.townHallPic),
              ),
            ],
          ),
          if (bookmarked)
            Positioned(
              right: -1,
              top: 42,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Icon(
                    Icons.bookmark_rounded,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlayerIdentity extends StatelessWidget {
  final Player player;

  const _PlayerIdentity({required this.player});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                player.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        Text(
          player.tag,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        _LastActiveText(player: player),
      ],
    );
  }
}

class _LastActiveText extends StatelessWidget {
  final Player player;

  const _LastActiveText({required this.player});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    final label = player.lastOnline == DateTime.utc(1970, 1, 1)
        ? loc.playerNotTracked
        : player.getLastOnlineText(context);

    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _TodoProgressRing extends StatelessWidget {
  final double ratio;
  final int percent;
  final Color color;
  final double size;

  const _TodoProgressRing({
    required this.ratio,
    required this.percent,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _RingPainter(
          value: ratio,
          color: color,
          trackColor: colorScheme.surfaceContainerHighest,
        ),
        child: Center(
          child: Text(
            '$percent%',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: size * 0.26,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.value,
    required this.color,
    required this.trackColor,
  });

  final double value;
  final Color color;
  final Color trackColor;

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
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}

class _QuietState extends StatelessWidget {
  final Color color;

  const _QuietState({required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.24 : 0.30),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.todoPointsLeftDescriptionNoPoints(
                  AppLocalizations.of(context)!.todoTitle,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskPill extends StatelessWidget {
  final _TodoTask task;

  const _TaskPill({required this.task});

  @override
  Widget build(BuildContext context) {
    final color = task.done ? StatColors.win : task.color;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.26 : 0.32),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(7, 6, 10, 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.72),
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: 27,
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: MobileWebImage(imageUrl: task.imageUrl),
                ),
              ),
            ),
            const SizedBox(width: 7),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 118),
                  child: Text(
                    task.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  task.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TodoTask {
  const _TodoTask({
    required this.label,
    required this.value,
    required this.imageUrl,
    required this.color,
    required this.done,
  });

  final String label;
  final String value;
  final String imageUrl;
  final Color color;
  final bool done;

  static List<_TodoTask> build(
    BuildContext context,
    Player player,
    WarMemberPresence member,
  ) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final compact = NumberFormat.compact(locale: locale);
    final tasks = <_TodoTask>[];

    if (player.league == 'Legend League' &&
        player.currentLegendSeason?.currentDay != null) {
      final done = player.currentLegendSeason?.currentDay?.totalAttacks ?? 0;
      tasks.add(
        _TodoTask(
          label: loc.legendsTitle,
          value: '$done/8',
          imageUrl: ImageAssets.legendBlazonNoPadding,
          color: const Color(0xFF4E7DF2),
          done: done >= 8,
        ),
      );
    }

    final warData = player.warData;
    if (warData != null &&
        warData.state == 'inWar' &&
        !_isSameWarAsCwl(player)) {
      final total = warData.attacksPerMember ?? 0;
      final done = warData.getAttacksDoneByPlayer(player.tag, player.clanTag);
      tasks.add(
        _TodoTask(
          label: loc.warTitle,
          value: '$done/$total',
          imageUrl: ImageAssets.war,
          color: StatColors.loss,
          done: done >= total,
        ),
      );
    }

    final cwlWarInfo = player.clan?.warCwl?.warInfo;
    if (cwlWarInfo != null &&
        cwlWarInfo.state == 'inWar' &&
        cwlWarInfo.isPlayerInWar(player.tag, player.clanTag)) {
      final total = cwlWarInfo.attacksPerMember ?? 0;
      final done = cwlWarInfo.getAttacksDoneByPlayer(
        player.tag,
        player.clanTag,
      );
      tasks.add(
        _TodoTask(
          label: loc.cwlTitle,
          value: '$done/$total',
          imageUrl: ImageAssets.cwlSwordsNoBorder,
          color: const Color(0xFF8D63D9),
          done: done >= total,
        ),
      );
    } else if (isInTimeFrameForCwl() && member.attacksAvailable > 0) {
      tasks.add(
        _TodoTask(
          label: loc.cwlTitle,
          value: '${member.attacksDone}/${member.attacksAvailable}',
          imageUrl: ImageAssets.cwlSwordsNoBorder,
          color: const Color(0xFF8D63D9),
          done: member.attacksDone >= member.attacksAvailable,
        ),
      );
    }

    if (isInTimeFrameForClanGames()) {
      tasks.add(
        _TodoTask(
          label: loc.gameClanGames,
          value: compact.format(player.currentClanGamesPoints),
          imageUrl: ImageAssets.clanGamesMedals,
          color: StatColors.win,
          done: player.clanGamesRatio >= 1,
        ),
      );
    }

    if (isInTimeFrameForRaid()) {
      final done = player.raids?.attackDone ?? 0;
      final total = player.raids?.attackLimit ?? 5;
      tasks.add(
        _TodoTask(
          label: loc.raidsTitle,
          value: '$done/$total',
          imageUrl: ImageAssets.raidAttacks,
          color: const Color(0xFF2A9FD6),
          done: done >= total,
        ),
      );
    }

    tasks.add(
      _TodoTask(
        label: AppLocalizations.of(context)!.gameSeasonPassShort,
        value: compact.format(player.currentSeasonPoints),
        imageUrl: ImageAssets.iconGoldPass,
        color: StatColors.warStarGold,
        done: player.seasonPassRatio >= 1,
      ),
    );

    tasks.sort((a, b) {
      if (a.done != b.done) return a.done ? 1 : -1;
      return a.label.compareTo(b.label);
    });
    return tasks;
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
