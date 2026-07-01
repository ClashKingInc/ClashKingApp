import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/functions/functions.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/presentation/to_do/player_to_do_page.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:clashkingapp/features/war_cwl/models/war_member_presence.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

const bool _showTodoMockups = true;

class HomeEventBanner extends StatefulWidget {
  const HomeEventBanner({super.key});

  @override
  State<HomeEventBanner> createState() => _HomeEventBannerState();
}

class _HomeEventBannerState extends State<HomeEventBanner> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _BannerItem.build();

    return SizedBox(
      height: 64,
      child: PageView.builder(
        controller: _controller,
        itemCount: items.length,
        itemBuilder: (context, index) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _BannerTile(
              key: ValueKey(items[index].title),
              item: items[index],
            ),
          );
        },
      ),
    );
  }
}

class HomeTodoCard extends StatefulWidget {
  const HomeTodoCard({
    super.key,
    required this.players,
    required this.allPlayers,
  });

  final List<Player> players;
  final List<Player> allPlayers;

  @override
  State<HomeTodoCard> createState() => _HomeTodoCardState();
}

class _HomeTodoCardState extends State<HomeTodoCard> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void didUpdateWidget(covariant HomeTodoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.players.length && widget.players.isNotEmpty) {
      _index = widget.players.length - 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final warCwlService = _showTodoMockups
        ? null
        : context.watch<WarCwlService>();
    final compact = MediaQuery.sizeOf(context).width < 360;
    final height = compact ? 392.0 : 258.0;
    final mockups = _TodoPreview.mockups;
    final itemCount = _showTodoMockups ? mockups.length : widget.players.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (index) => setState(() => _index = index),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (_showTodoMockups) {
                return _TodoPreviewPanel(
                  preview: mockups[index],
                  compact: compact,
                );
              }

              final player = widget.players[index];
              final presence = _memberPresence(player, warCwlService!);
              final summary = _TodoSummary.fromPlayer(player, presence);

              return _AccountTodoPanel(
                player: player,
                summary: summary,
                compact: compact,
                onTap: () => _openTodo(context, warCwlService),
              );
            },
          ),
        ),
        if (itemCount > 1) ...[
          const SizedBox(height: 10),
          Center(
            child: _PageDots(count: itemCount, index: _index),
          ),
        ],
      ],
    );
  }

  WarMemberPresence _memberPresence(
    Player player,
    WarCwlService warCwlService,
  ) {
    if (player.clan == null || player.clan!.tag.isEmpty) {
      return WarMemberPresence.empty();
    }
    return warCwlService
            .getWarCwlByTag(player.clan!.tag)
            ?.getMemberPresence(player.tag, player.clan!.tag) ??
        WarMemberPresence.empty();
  }

  void _openTodo(BuildContext context, WarCwlService warCwlService) {
    final accounts = widget.allPlayers.isNotEmpty
        ? widget.allPlayers
        : widget.players;
    final memberPresenceMap = <String, WarMemberPresence>{};
    for (final player in accounts) {
      if (player.clan != null && player.clan!.tag.isNotEmpty) {
        final warCwl = warCwlService.getWarCwlByTag(player.clan!.tag);
        if (warCwl != null) {
          memberPresenceMap[player.tag] = warCwl.getMemberPresence(
            player.tag,
            player.clan!.tag,
          );
        }
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerToDoScreen(
          players: accounts,
          memberPresenceMap: memberPresenceMap,
        ),
      ),
    );
  }
}

class _TodoPreviewPanel extends StatelessWidget {
  const _TodoPreviewPanel({required this.preview, required this.compact});

  final _TodoPreview preview;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.32),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, compact ? 16 : 18, 18, 18),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PreviewHeader(preview: preview),
                    const SizedBox(height: 18),
                    Center(
                      child: _TodoRing(summary: preview.summary, size: 150),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: _MetricBars(metrics: preview.summary.metrics),
                    ),
                  ],
                )
              : Row(
                  children: [
                    SizedBox(
                      width: 144,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PreviewHeader(preview: preview),
                          const Spacer(),
                          _TodoRing(summary: preview.summary, size: 128),
                          const Spacer(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            preview.status,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: _MetricBars(
                              metrics: preview.summary.metrics,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _AccountTodoPanel extends StatelessWidget {
  const _AccountTodoPanel({
    required this.player,
    required this.summary,
    required this.compact,
    required this.onTap,
  });

  final Player player;
  final _TodoSummary summary;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.32),
              ),
            ),
            padding: EdgeInsets.fromLTRB(18, compact ? 16 : 18, 18, 18),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AccountHeader(player: player),
                      const SizedBox(height: 18),
                      Center(child: _TodoRing(summary: summary, size: 150)),
                      const SizedBox(height: 18),
                      Expanded(child: _MetricBars(metrics: summary.metrics)),
                    ],
                  )
                : Row(
                    children: [
                      SizedBox(
                        width: 144,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _AccountHeader(player: player),
                            const Spacer(),
                            _TodoRing(summary: summary, size: 128),
                            const Spacer(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    summary.lastActiveText(context),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 22,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: _MetricBars(metrics: summary.metrics),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        SizedBox.square(
          dimension: 34,
          child: CachedNetworkImage(
            imageUrl: player.townHallPic,
            fit: BoxFit.contain,
            errorWidget: (context, url, error) => DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${player.townHallLevel}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                player.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'TH${player.townHallLevel}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreviewHeader extends StatelessWidget {
  const _PreviewHeader({required this.preview});

  final _TodoPreview preview;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        SizedBox.square(
          dimension: 34,
          child: CachedNetworkImage(
            imageUrl: preview.avatarUrl,
            fit: BoxFit.contain,
            errorWidget: (context, url, error) => DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.person_rounded,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                preview.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                preview.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TodoRing extends StatelessWidget {
  const _TodoRing({required this.summary, required this.size});

  final _TodoSummary summary;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final percent = (summary.ratio * 100).round();

    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _RingPainter(
          value: summary.ratio,
          color: summary.isDone ? Colors.green : colorScheme.primary,
          trackColor: colorScheme.surfaceContainerHighest,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percent%',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: size * 0.26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${summary.done}/${summary.total}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricBars extends StatelessWidget {
  const _MetricBars({required this.metrics});

  final List<_TodoMetric> metrics;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) {
      return const Center(child: _CaughtUp());
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      itemCount: metrics.length,
      separatorBuilder: (context, index) => const SizedBox(height: 9),
      itemBuilder: (context, index) {
        return _MetricBar(metric: metrics[index]);
      },
    );
  }
}

class _MetricBar extends StatelessWidget {
  const _MetricBar({required this.metric});

  final _TodoMetric metric;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final done = metric.done >= metric.total;
    final fillColor = done ? Colors.green : metric.color;

    return SizedBox(
      height: 46,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fillColor.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(18),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: metric.ratio,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: fillColor.withValues(alpha: 0.24),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 11),
                child: Row(
                  children: [
                    _MetricIcon(metric: metric),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            metric.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          Text(
                            metric.detail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${metric.done}/${metric.total}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 18,
                        color: fillColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricIcon extends StatelessWidget {
  const _MetricIcon({required this.metric});

  final _TodoMetric metric;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
        shape: BoxShape.circle,
      ),
      child: SizedBox.square(
        dimension: 30,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: CachedNetworkImage(
            imageUrl: metric.imageUrl,
            fit: BoxFit.contain,
            errorWidget: (context, url, error) =>
                Icon(metric.fallbackIcon, size: 18, color: metric.color),
          ),
        ),
      ),
    );
  }
}

class _CaughtUp extends StatelessWidget {
  const _CaughtUp();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded, color: Colors.green, size: 30),
        const SizedBox(height: 8),
        Text(
          'Caught up',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (dotIndex) {
        final selected = dotIndex == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: selected ? 18 : 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.onSurface
                : colorScheme.onSurface.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _BannerTile extends StatelessWidget {
  const _BannerTile({super.key, required this.item});

  final _BannerItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: '${item.title}, ${item.subtitle}',
      child: Row(
        children: [
          SizedBox.square(
            dimension: 48,
            child: CachedNetworkImage(
              imageUrl: item.imageUrl,
              fit: BoxFit.contain,
              errorWidget: (context, url, error) =>
                  Icon(item.fallbackIcon, color: item.color, size: 30),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
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

class _TodoSummary {
  const _TodoSummary({
    required this.metrics,
    required this.done,
    required this.total,
    this.player,
  });

  final List<_TodoMetric> metrics;
  final int done;
  final int total;
  final Player? player;

  bool get isDone => done >= total;
  double get ratio => total == 0 ? 1 : (done / total).clamp(0.0, 1.0);

  String lastActiveText(BuildContext context) {
    final player = this.player;
    if (player == null) {
      return 'Preview account';
    }
    if (player.lastOnline == DateTime.utc(1970, 1, 1)) {
      return 'Last active unavailable';
    }
    return 'Active ${player.getLastOnlineText(context)}';
  }

  factory _TodoSummary.fromMetrics(List<_TodoMetric> metrics) {
    var done = 0;
    var total = 0;
    for (final metric in metrics) {
      done += metric.done.clamp(0, metric.total);
      total += metric.total;
    }
    return _TodoSummary(metrics: metrics, done: done, total: total);
  }

  factory _TodoSummary.fromPlayer(Player player, WarMemberPresence memberCwl) {
    final metrics = <_TodoMetric>[];

    if (player.league == 'Legend League' &&
        player.currentLegendSeason?.currentDay != null) {
      final done = player.currentLegendSeason?.currentDay?.totalAttacks ?? 0;
      metrics.add(
        _TodoMetric(
          label: 'Legend attacks',
          detail: '${math.max(8 - done, 0)} left today',
          done: done,
          total: 8,
          imageUrl: ImageAssets.legendBlazonNoPadding,
          color: const Color(0xFF4E7DF2),
          fallbackIcon: Icons.shield_rounded,
        ),
      );
    }

    final warData = player.warData;
    if (warData != null &&
        warData.state == 'inWar' &&
        !_isSameWarAsCwl(player)) {
      final total = warData.attacksPerMember ?? 1;
      final done = warData.getAttacksDoneByPlayer(player.tag, player.clanTag);
      metrics.add(
        _TodoMetric(
          label: 'War attacks',
          detail: '${math.max(total - done, 0)} left',
          done: done,
          total: total,
          imageUrl: ImageAssets.war,
          color: const Color(0xFFE35D4F),
          fallbackIcon: Icons.local_fire_department_rounded,
        ),
      );
    }

    final cwlWarInfo = player.clan?.warCwl?.warInfo;
    if (cwlWarInfo != null &&
        cwlWarInfo.state == 'inWar' &&
        cwlWarInfo.isPlayerInWar(player.tag, player.clanTag)) {
      final total = cwlWarInfo.attacksPerMember ?? 1;
      final done = cwlWarInfo.getAttacksDoneByPlayer(
        player.tag,
        player.clanTag,
      );
      metrics.add(
        _TodoMetric(
          label: 'CWL attacks',
          detail: '${math.max(total - done, 0)} left this round',
          done: done,
          total: total,
          imageUrl: ImageAssets.cwlSwordsNoBorder,
          color: const Color(0xFF8D63D9),
          fallbackIcon: Icons.military_tech_rounded,
        ),
      );
    } else if (isInTimeFrameForCwl() && memberCwl.attacksAvailable > 0) {
      metrics.add(
        _TodoMetric(
          label: 'CWL attacks',
          detail:
              '${math.max(memberCwl.attacksAvailable - memberCwl.attacksDone, 0)} left this week',
          done: memberCwl.attacksDone,
          total: memberCwl.attacksAvailable,
          imageUrl: ImageAssets.cwlSwordsNoBorder,
          color: const Color(0xFF8D63D9),
          fallbackIcon: Icons.military_tech_rounded,
        ),
      );
    }

    if (isInTimeFrameForClanGames()) {
      metrics.add(
        _TodoMetric(
          label: 'Clan Games',
          detail:
              '${NumberFormat.compact().format(player.clanGamesPointLeft)} points left',
          done: player.currentClanGamesPoints,
          total: 4000,
          imageUrl: ImageAssets.clanGamesMedals,
          color: const Color(0xFF14A37F),
          fallbackIcon: Icons.emoji_events_rounded,
        ),
      );
    }

    if (isInTimeFrameForRaid()) {
      final raids = player.raids;
      metrics.add(
        _TodoMetric(
          label: 'Raid attacks',
          detail:
              '${math.max((raids?.attackLimit ?? 5) - (raids?.attackDone ?? 0), 0)} left',
          done: raids?.attackDone ?? 0,
          total: raids?.attackLimit ?? 5,
          imageUrl: ImageAssets.raidAttacks,
          color: const Color(0xFF2A9FD6),
          fallbackIcon: Icons.fort_rounded,
        ),
      );
    }

    var done = 0;
    var total = 0;
    for (final metric in metrics) {
      done += metric.done.clamp(0, metric.total);
      total += metric.total;
    }

    return _TodoSummary(
      metrics: metrics,
      done: done,
      total: total,
      player: player,
    );
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

class _TodoMetric {
  const _TodoMetric({
    required this.label,
    required this.detail,
    required this.done,
    required this.total,
    required this.imageUrl,
    required this.color,
    required this.fallbackIcon,
  });

  final String label;
  final String detail;
  final int done;
  final int total;
  final String imageUrl;
  final Color color;
  final IconData fallbackIcon;

  double get ratio => total == 0 ? 1 : (done / total).clamp(0.0, 1.0);
}

class _TodoPreview {
  const _TodoPreview({
    required this.name,
    required this.subtitle,
    required this.status,
    required this.avatarUrl,
    required this.summary,
  });

  final String name;
  final String subtitle;
  final String status;
  final String avatarUrl;
  final _TodoSummary summary;

  static List<_TodoPreview> get mockups => [
    _TodoPreview(
      name: 'Maxed Main',
      subtitle: 'TH17 · everything active',
      status: 'Active now · full daily checklist',
      avatarUrl: ImageAssets.townHall(17),
      summary: _TodoSummary.fromMetrics([
        _TodoMetric(
          label: 'Legend attacks',
          detail: '5 left today',
          done: 3,
          total: 8,
          imageUrl: ImageAssets.legendBlazonNoPadding,
          color: const Color(0xFF4E7DF2),
          fallbackIcon: Icons.shield_rounded,
        ),
        _TodoMetric(
          label: 'War attacks',
          detail: '1 left',
          done: 1,
          total: 2,
          imageUrl: ImageAssets.war,
          color: const Color(0xFFE35D4F),
          fallbackIcon: Icons.local_fire_department_rounded,
        ),
        _TodoMetric(
          label: 'CWL attacks',
          detail: '1 left this round',
          done: 0,
          total: 1,
          imageUrl: ImageAssets.cwlSwordsNoBorder,
          color: const Color(0xFF8D63D9),
          fallbackIcon: Icons.military_tech_rounded,
        ),
        _TodoMetric(
          label: 'Clan Games',
          detail: '2.7K points left',
          done: 1300,
          total: 4000,
          imageUrl: ImageAssets.clanGamesMedals,
          color: const Color(0xFF14A37F),
          fallbackIcon: Icons.emoji_events_rounded,
        ),
        _TodoMetric(
          label: 'Raid attacks',
          detail: '4 left',
          done: 2,
          total: 6,
          imageUrl: ImageAssets.raidAttacks,
          color: const Color(0xFF2A9FD6),
          fallbackIcon: Icons.fort_rounded,
        ),
        _TodoMetric(
          label: 'Season Pass',
          detail: '850 points left',
          done: 1750,
          total: 2600,
          imageUrl: ImageAssets.iconGoldPass,
          color: const Color(0xFFE8A524),
          fallbackIcon: Icons.confirmation_number_rounded,
        ),
      ]),
    ),
    _TodoPreview(
      name: 'War Alt',
      subtitle: 'TH15 · war focused',
      status: 'Active 18m ago · war and raids need attention',
      avatarUrl: ImageAssets.townHall(15),
      summary: _TodoSummary.fromMetrics([
        _TodoMetric(
          label: 'War attacks',
          detail: '2 left',
          done: 0,
          total: 2,
          imageUrl: ImageAssets.warClan,
          color: const Color(0xFFE35D4F),
          fallbackIcon: Icons.local_fire_department_rounded,
        ),
        _TodoMetric(
          label: 'Clan Games',
          detail: '900 points left',
          done: 3100,
          total: 4000,
          imageUrl: ImageAssets.clanGamesMedals,
          color: const Color(0xFF14A37F),
          fallbackIcon: Icons.emoji_events_rounded,
        ),
        _TodoMetric(
          label: 'Raid attacks',
          detail: '1 left',
          done: 5,
          total: 6,
          imageUrl: ImageAssets.raidAttacks,
          color: const Color(0xFF2A9FD6),
          fallbackIcon: Icons.fort_rounded,
        ),
      ]),
    ),
    _TodoPreview(
      name: 'Legend Push',
      subtitle: 'TH16 · daily attacks',
      status: 'Active 1h ago · legends and pass progress',
      avatarUrl: ImageAssets.townHall(16),
      summary: _TodoSummary.fromMetrics([
        _TodoMetric(
          label: 'Legend attacks',
          detail: '2 left today',
          done: 6,
          total: 8,
          imageUrl: ImageAssets.legendBlazonNoPadding,
          color: const Color(0xFF4E7DF2),
          fallbackIcon: Icons.shield_rounded,
        ),
        _TodoMetric(
          label: 'Season Pass',
          detail: 'on pace',
          done: 2200,
          total: 2600,
          imageUrl: ImageAssets.iconGoldPass,
          color: const Color(0xFFE8A524),
          fallbackIcon: Icons.confirmation_number_rounded,
        ),
      ]),
    ),
    _TodoPreview(
      name: 'Caught Up',
      subtitle: 'TH14 · no open tasks',
      status: 'Active today · no action needed',
      avatarUrl: ImageAssets.townHall(14),
      summary: _TodoSummary.fromMetrics([]),
    ),
  ];
}

class _BannerItem {
  const _BannerItem({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.fallbackIcon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String imageUrl;
  final IconData fallbackIcon;
  final Color color;

  static List<_BannerItem> build() {
    final now = DateTime.now().toUtc();
    return [
      const _BannerItem(
        title: 'Use code ClashKing',
        subtitle: 'Support the project in the Supercell Store',
        imageUrl: ImageAssets.lightModeLogo,
        fallbackIcon: Icons.local_offer_rounded,
        color: Color(0xFFD90709),
      ),
      _eventItem(
        now: now,
        title: 'Clan Games',
        imageUrl: ImageAssets.clanGamesMedals,
        fallbackIcon: Icons.emoji_events_rounded,
        color: const Color(0xFF14A37F),
        window: _monthlyWindow(now, 22, 8, 28, 8),
      ),
      _eventItem(
        now: now,
        title: 'CWL',
        imageUrl: ImageAssets.cwlSwordsNoBorder,
        fallbackIcon: Icons.military_tech_rounded,
        color: const Color(0xFF8D63D9),
        window: _monthlyWindow(now, 1, 0, 13, 0),
      ),
      _eventItem(
        now: now,
        title: 'Season ends',
        imageUrl: ImageAssets.iconGoldPass,
        fallbackIcon: Icons.hourglass_bottom_rounded,
        color: const Color(0xFFE8A524),
        window: _seasonWindow(now),
      ),
      _eventItem(
        now: now,
        title: 'League reset',
        imageUrl: ImageAssets.legendBlazonNoPadding,
        fallbackIcon: Icons.leaderboard_rounded,
        color: const Color(0xFF4E7DF2),
        window: _seasonWindow(now),
      ),
      _eventItem(
        now: now,
        title: 'Raid Weekend',
        imageUrl: ImageAssets.raidAttacks,
        fallbackIcon: Icons.fort_rounded,
        color: const Color(0xFF2A9FD6),
        window: _raidWindow(now),
      ),
    ];
  }

  static _BannerItem _eventItem({
    required DateTime now,
    required String title,
    required String imageUrl,
    required IconData fallbackIcon,
    required Color color,
    required ({DateTime start, DateTime end}) window,
  }) {
    final active = !now.isBefore(window.start) && now.isBefore(window.end);
    final target = active ? window.end : window.start;
    return _BannerItem(
      title: title,
      imageUrl: imageUrl,
      fallbackIcon: fallbackIcon,
      color: color,
      subtitle:
          '${active ? 'Ends' : 'Starts'} in ${_formatRemaining(target.difference(now))}',
    );
  }

  static ({DateTime start, DateTime end}) _monthlyWindow(
    DateTime now,
    int startDay,
    int startHour,
    int endDay,
    int endHour,
  ) {
    var start = DateTime.utc(now.year, now.month, startDay, startHour);
    var end = DateTime.utc(now.year, now.month, endDay, endHour);
    if (!now.isBefore(end)) {
      start = DateTime.utc(now.year, now.month + 1, startDay, startHour);
      end = DateTime.utc(now.year, now.month + 1, endDay, endHour);
    }
    return (start: start, end: end);
  }

  static ({DateTime start, DateTime end}) _seasonWindow(DateTime now) {
    DateTime seasonEnd(int year, int month) {
      final lastMonday = findLastMondayOfMonth(year, month);
      return DateTime.utc(lastMonday.year, lastMonday.month, lastMonday.day, 5);
    }

    var end = seasonEnd(now.year, now.month);
    if (!now.isBefore(end)) {
      end = seasonEnd(now.year, now.month + 1);
    }
    final start = DateTime.utc(now.year, now.month, 1);
    return (start: start, end: end);
  }

  static ({DateTime start, DateTime end}) _raidWindow(DateTime now) {
    final daysUntilFriday = (DateTime.friday - now.weekday) % 7;
    var start = DateTime.utc(now.year, now.month, now.day + daysUntilFriday, 7);
    if (now.weekday == DateTime.friday && now.hour >= 7) {
      start = DateTime.utc(now.year, now.month, now.day, 7);
    }
    var end = start.add(const Duration(days: 3));
    if (!now.isBefore(end)) {
      start = start.add(const Duration(days: 7));
      end = start.add(const Duration(days: 3));
    }
    return (start: start, end: end);
  }

  static String _formatRemaining(Duration duration) {
    final positive = duration.isNegative ? Duration.zero : duration;
    if (positive.inDays > 0) {
      final hours = positive.inHours.remainder(24);
      return '${positive.inDays}d ${hours}h';
    }
    if (positive.inHours > 0) {
      final minutes = positive.inMinutes.remainder(60);
      return '${positive.inHours}h ${minutes}m';
    }
    return '${positive.inMinutes}m';
  }
}
