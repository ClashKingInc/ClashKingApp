import 'dart:async';

import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/home_metric_pill.dart';
import 'package:clashkingapp/common/widgets/indicators/progress_ring_painter.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/bookmark_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/models/player_timer.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/presentation/player/player_page.dart';
import 'package:clashkingapp/features/war_cwl/models/war_member_presence.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/l10n/game_localizations.dart';
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
    final metrics = _TodoCardMetric.build(context, player, member);
    final openTasks = metrics.where((metric) => !metric.done).length;
    final statusColor = openTasks == 0 ? StatColors.win : colorScheme.primary;
    final bookmarked = context.watch<BookmarkService>().isPlayerBookmarked(
      player.tag,
    );

    return Card(
      margin: EdgeInsets.zero,
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
              if (metrics.isEmpty)
                _QuietState(color: statusColor)
              else
                CKMetricChipGrid(
                  spacing: HomeMetricPill.gap,
                  chips: metrics
                      .map((metric) => _TodoMetricPill(metric: metric))
                      .toList(growable: false),
                ),
              _PlayerTimerCountdowns(
                key: ValueKey(player.tag.trim().toUpperCase()),
                playerTag: player.tag,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerTimerCountdowns extends StatefulWidget {
  const _PlayerTimerCountdowns({super.key, required this.playerTag});

  final String playerTag;

  @override
  State<_PlayerTimerCountdowns> createState() => _PlayerTimerCountdownsState();
}

class _PlayerTimerCountdownsState extends State<_PlayerTimerCountdowns> {
  late Future<PlayerTimers> _load;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _load = context.read<PlayerService>().loadPlayerTimers(widget.playerTag);
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PlayerTimers>(
      future: _load,
      builder: (context, snapshot) {
        final now = DateTime.now().toUtc();
        final timers =
            (snapshot.data?.items ?? const <PlayerTimer>[])
                .where((timer) => timer.expiresAt.isAfter(now))
                .toList(growable: false)
              ..sort((a, b) => a.expiresAt.compareTo(b.expiresAt));
        if (timers.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final timer in timers) _TimerChip(timer: timer, now: now),
            ],
          ),
        );
      },
    );
  }
}

class _TimerChip extends StatelessWidget {
  const _TimerChip({required this.timer, required this.now});

  final PlayerTimer timer;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final label = switch (timer.type) {
      PlayerTimerType.war => loc.todoWarAttacks,
      PlayerTimerType.cwl => loc.todoCwlAttacks,
      PlayerTimerType.capital => loc.gameClanCapital,
    };
    final image = switch (timer.type) {
      PlayerTimerType.war => ImageAssets.war,
      PlayerTimerType.cwl => ImageAssets.cwlSwordsNoBorder,
      PlayerTimerType.capital => ImageAssets.capitalThickSwords,
    };
    final remaining = _formatTimerRemaining(
      loc,
      timer.expiresAt.difference(now),
    );
    return HomeMetricPill(
      label: label,
      value: loc.todoEventEndsIn(remaining),
      progress: 0,
      imageUrl: image,
      fallbackIcon: Icons.timer_outlined,
      semanticLabel: '$label: ${loc.todoEventEndsIn(remaining)}',
    );
  }
}

String _formatTimerRemaining(AppLocalizations loc, Duration duration) {
  final positive = duration.isNegative ? Duration.zero : duration;
  if (positive.inDays > 0) {
    return loc.timeDurationShort(
      'daysHours',
      positive.inDays,
      positive.inHours.remainder(24),
    );
  }
  if (positive.inHours > 0) {
    return loc.timeDurationShort(
      'hoursMinutes',
      positive.inHours,
      positive.inMinutes.remainder(60),
    );
  }
  return loc.timeDurationShort('minutes', positive.inMinutes, 0);
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
        painter: ProgressRingPainter(
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

class _TodoMetricPill extends StatelessWidget {
  final _TodoCardMetric metric;

  const _TodoMetricPill({required this.metric});

  @override
  Widget build(BuildContext context) {
    return HomeMetricPill(
      label: metric.label,
      value: metric.value,
      progress: metric.progress,
      imageUrl: metric.imageUrl,
      fallbackIcon: metric.fallbackIcon,
      semanticLabel: '${metric.label}: ${metric.value}',
    );
  }
}

class _TodoCardMetric {
  const _TodoCardMetric({
    required this.label,
    required this.value,
    required this.imageUrl,
    required this.progress,
    required this.fallbackIcon,
    required this.done,
  });

  final String label;
  final String value;
  final String imageUrl;
  final double progress;
  final IconData fallbackIcon;

  final bool done;

  static List<_TodoCardMetric> build(
    BuildContext context,
    Player player,
    WarMemberPresence member,
  ) {
    final loc = AppLocalizations.of(context)!;
    final metrics = player
        .getTodoProgressMetrics(memberCwl: member)
        .map(
          (metric) => _TodoCardMetric.fromProgressMetric(metric, loc, player),
        )
        .toList(growable: false);

    metrics.sort((a, b) {
      if (a.done != b.done) return a.done ? 1 : -1;
      return a.label.compareTo(b.label);
    });
    return metrics;
  }

  factory _TodoCardMetric.fromProgressMetric(
    TodoProgressMetric metric,
    AppLocalizations loc,
    Player player,
  ) {
    return _TodoCardMetric(
      label: _displayLabel(metric.label, loc),
      value: '${metric.done}/${metric.total}',
      progress: metric.progressRatio,
      done: metric.label == 'clan_games'
          ? player.clanGamesRatio >= 1
          : metric.progressRatio >= 1,
      imageUrl: switch (metric.label) {
        'legend_attacks' => ImageAssets.legendBlazonNoPadding,
        'war_attacks' => ImageAssets.war,
        'cwl_attacks' => ImageAssets.cwlSwordsNoBorder,
        'clan_games' => ImageAssets.clanGamesMedals,
        _ => ImageAssets.iconGoldPass,
      },
      fallbackIcon: switch (metric.label) {
        'legend_attacks' => Icons.shield_rounded,
        'war_attacks' => Icons.local_fire_department_rounded,
        'cwl_attacks' => Icons.military_tech_rounded,
        'clan_games' => Icons.emoji_events_rounded,
        _ => Icons.confirmation_number_rounded,
      },
    );
  }

  static String _displayLabel(String label, AppLocalizations loc) {
    return switch (label) {
      'legend_attacks' => loc.todoLegendAttacks,
      'war_attacks' => loc.todoWarAttacks,
      'cwl_attacks' => loc.todoCwlAttacks,
      'clan_games' => loc.gameName(
        'TID_CLAN_TAG_CLAN_GAMES',
        loc.gameClanGames,
      ),
      'season_pass' => loc.gameSeasonPassShort,
      _ => label,
    };
  }
}
