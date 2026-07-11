import 'dart:math' as math;

import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/functions/functions.dart';
import 'package:clashkingapp/features/pages/data/announcement_service.dart';
import 'package:clashkingapp/features/pages/data/announcement_story_cache_service.dart';
import 'package:clashkingapp/features/pages/models/app_announcement.dart';
import 'package:clashkingapp/features/pages/presentation/announcement_webview_page.dart';
import 'package:clashkingapp/features/pages/presentation/announcement_story_dialog.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/presentation/to_do/player_to_do_page.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:clashkingapp/features/war_cwl/models/war_member_presence.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

const bool _showTodoMockups = false;

class HomeEventBanner extends StatefulWidget {
  const HomeEventBanner({super.key});

  @override
  State<HomeEventBanner> createState() => _HomeEventBannerState();
}

class _HomeEventBannerState extends State<HomeEventBanner> {
  late final PageController _controller;
  late final AnnouncementService _announcementService;
  late final Future<AppAnnouncement?> _announcementFuture;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _announcementService = AnnouncementService();
    _announcementFuture = _announcementService.getActiveAnnouncement();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;

    return FutureBuilder<AppAnnouncement?>(
      future: _announcementFuture,
      builder: (context, snapshot) {
        final items = _BannerItem.build(
          loc: loc,
          isDark: isDark,
          announcement: snapshot.data,
        );

        return Column(
          children: [
            SizedBox(
              height: 64,
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) => setState(() => _index = index),
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
            ),
            const SizedBox(height: 8),
            _PageDots(count: items.length, index: _index),
          ],
        );
      },
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
    final loc = AppLocalizations.of(context)!;
    final warCwlService = _showTodoMockups
        ? null
        : context.watch<WarCwlService>();
    final mockups = _TodoPreview.mockups(loc);
    // A combined "all accounts" page leads when several accounts are pinned.
    final hasSummaryPage = !_showTodoMockups && widget.players.length > 1;
    final itemCount = _showTodoMockups
        ? mockups.length
        : widget.players.length + (hasSummaryPage ? 1 : 0);

    // Every page's summary, in page order — reused by the item builder and
    // to size the card to its content (tallest page wins).
    final summaries = _showTodoMockups
        ? mockups.map((mockup) => mockup.summary).toList(growable: false)
        : <_TodoSummary>[
            if (hasSummaryPage)
              _TodoSummary.fromPlayers(
                widget.players,
                (player) => _memberPresence(player, warCwlService!),
                loc,
              ),
            ...widget.players.map(
              (player) => _TodoSummary.fromPlayer(
                player,
                _memberPresence(player, warCwlService!),
                loc,
              ),
            ),
          ];
    final maxRows = summaries.fold<int>(
      0,
      (acc, summary) => math.max(acc, (summary.metrics.length + 1) ~/ 2),
    );
    // Panel chrome: padding + border + header row + status row + gaps.
    final barsHeight = maxRows == 0
        ? 64.0
        : maxRows * 38.0 + (maxRows - 1) * 7.0;
    final height = 116.0 + barsHeight;

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
                return _TodoPreviewPanel(preview: mockups[index]);
              }

              if (hasSummaryPage && index == 0) {
                return _AllAccountsPanel(
                  accountCount: widget.players.length,
                  summary: summaries[index],
                  onTap: () => _openTodo(context, warCwlService!),
                );
              }

              final player = widget.players[index - (hasSummaryPage ? 1 : 0)];

              return _AccountTodoPanel(
                player: player,
                summary: summaries[index],
                onTap: () => _openTodo(context, warCwlService!),
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
  const _TodoPreviewPanel({required this.preview});

  final _TodoPreview preview;

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
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _PreviewHeader(preview: preview)),
                  _TodoRing(summary: preview.summary, size: 46),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                preview.status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _MetricBars(metrics: preview.summary.metrics),
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
    required this.onTap,
  });

  final Player player;
  final _TodoSummary summary;
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
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _AccountHeader(player: player)),
                    _TodoRing(summary: summary, size: 46),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        summary.lastActiveText(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
                const SizedBox(height: 10),
                _MetricBars(metrics: summary.metrics),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Leading page when several accounts are pinned: combined progress and
/// per-category totals across all of them.
class _AllAccountsPanel extends StatelessWidget {
  const _AllAccountsPanel({
    required this.accountCount,
    required this.summary,
    required this.onTap,
  });

  final int accountCount;
  final _TodoSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final header = Row(
      children: [
        SizedBox.square(
          dimension: 30,
          child: MobileWebImage(
            imageUrl: ImageAssets.iconBuilderPotion,
            fit: BoxFit.contain,
            errorWidget: (context, url, error) => Icon(
              Icons.checklist_rounded,
              size: 24,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.todoAllAccounts,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              Text(
                AppLocalizations.of(context)!.todoAccountsNumber(accountCount),
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
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: header),
                    _TodoRing(summary: summary, size: 46),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.of(
                          context,
                        )!.todoCombinedAcrossAccounts,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
                const SizedBox(height: 10),
                _MetricBars(metrics: summary.metrics),
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
          dimension: 30,
          child: MobileWebImage(
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
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w900),
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
          dimension: 30,
          child: MobileWebImage(
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
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w900),
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
    // Below this size the done/total line no longer fits inside the ring.
    final showCounts = size >= 80;

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
              if (showCounts) ...[
                const SizedBox(height: 2),
                Text(
                  '${summary.done}/${summary.total}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
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
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Center(child: _CaughtUp()),
      );
    }

    // Two metrics per row; a metric alone on its row spans the full width.
    final rows = <Widget>[];
    for (var i = 0; i < metrics.length; i += 2) {
      if (i + 1 < metrics.length) {
        rows.add(
          Row(
            children: [
              Expanded(child: _MetricBar(metric: metrics[i])),
              const SizedBox(width: 7),
              Expanded(child: _MetricBar(metric: metrics[i + 1])),
            ],
          ),
        );
      } else {
        rows.add(_MetricBar(metric: metrics[i]));
      }
    }

    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 7),
          rows[i],
        ],
      ],
    );
  }
}

class _MetricBar extends StatelessWidget {
  const _MetricBar({required this.metric});

  final _TodoMetric metric;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final done = metric.done >= metric.total;
    final fillColor = done ? Colors.green : metric.color;

    return SizedBox(
      height: 38,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fillColor.withValues(alpha: isDark ? 0.28 : 0.34),
          borderRadius: BorderRadius.circular(14),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: metric.ratio,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: fillColor.withValues(alpha: isDark ? 0.38 : 0.48),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9),
                child: Row(
                  children: [
                    _MetricIcon(metric: metric),
                    const SizedBox(width: 7),
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
        dimension: 26,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: MobileWebImage(
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
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      AppLocalizations.of(context)!.todoAllCaughtUpForNow,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w800,
      ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sourceHsl = HSLColor.fromColor(item.color);
    final accentColor = isDark
        ? sourceHsl
              .withSaturation(math.max(sourceHsl.saturation, 0.78))
              .withLightness(math.max(sourceHsl.lightness, 0.56))
              .toColor()
        : item.color;
    final hasStory = item.announcement?.storyUrl?.isNotEmpty ?? false;
    final hasArticle =
        hasStory ||
        item.html != null ||
        (item.htmlUrl != null && item.htmlUrl!.trim().isNotEmpty);
    final onTap = !hasArticle
        ? null
        : () async {
            if (hasStory) {
              final announcement = item.announcement!;
              final storyFilePath = await AnnouncementStoryCacheService()
                  .prepare(announcement);
              if (!context.mounted || storyFilePath == null) {
                return;
              }
              await showAnnouncementStoryDialog(
                context,
                announcement: announcement,
                preparedFilePath: storyFilePath,
              );
              return;
            }
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AnnouncementWebViewPage(
                  title: item.title,
                  html: item.html,
                  url: item.htmlUrl,
                ),
              ),
            );
          };

    return Semantics(
      button: onTap != null,
      label: '${item.title}, ${item.subtitle}',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: Material(
          color: accentColor.withValues(alpha: isDark ? 0.22 : 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: accentColor.withValues(alpha: isDark ? 0.42 : 0.24),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.72),
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox.square(
                      dimension: 40,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: MobileWebImage(
                          imageUrl: item.imageUrl,
                          fit: BoxFit.contain,
                          errorWidget: (context, url, error) => Icon(
                            item.fallbackIcon,
                            color: accentColor,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle,
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
                  if (onTap != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
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
    final loc = AppLocalizations.of(context)!;
    final player = this.player;
    if (player == null) {
      return loc.todoPreviewAccount;
    }
    if (player.lastOnline == DateTime.utc(1970, 1, 1)) {
      return loc.todoLastActiveUnavailable;
    }
    return loc.todoActiveRelative(player.getLastOnlineText(context));
  }

  factory _TodoSummary.fromMetrics(List<_TodoMetric> metrics) {
    final (done, total) = _averagedProgress(metrics);
    return _TodoSummary(metrics: metrics, done: done, total: total);
  }

  /// Metrics mix wildly different scales (a couple of war/CWL attacks vs.
  /// tens of thousands of season-pass points) — summing raw done/total
  /// would let one huge-denominator metric swamp the rest, making the
  /// overall percentage look stuck near 0% even when every attack-based
  /// metric is fully done. Average each metric's own ratio instead, and
  /// store it as done/(count*100) so the existing int-based ratio/isDone
  /// getters keep working unchanged.
  static (int, int) _averagedProgress(List<_TodoMetric> metrics) {
    if (metrics.isEmpty) return (0, 0);
    final totalDone = metrics.fold<double>(
      0,
      (sum, metric) => sum + metric.progressDone.clamp(0, metric.progressTotal),
    );
    final total = metrics.fold<double>(
      0,
      (sum, metric) => sum + metric.progressTotal,
    );
    return ((totalDone * 100).round(), (total * 100).round());
  }

  factory _TodoSummary.fromPlayer(
    Player player,
    WarMemberPresence memberCwl,
    AppLocalizations loc,
  ) {
    final metrics = player
        .getTodoProgressMetrics(memberCwl: memberCwl)
        .map((metric) => _TodoMetric.fromProgressMetric(metric, loc))
        .toList(growable: false);

    final (done, total) = _averagedProgress(metrics);

    return _TodoSummary(
      metrics: metrics,
      done: done,
      total: total,
      player: player,
    );
  }

  /// Aggregates every pinned account into one summary: metrics with the
  /// same label are merged by summing done/total across accounts.
  factory _TodoSummary.fromPlayers(
    List<Player> players,
    WarMemberPresence Function(Player) presenceOf,
    AppLocalizations loc,
  ) {
    final merged = <String, _TodoMetric>{};
    final order = <String>[];

    for (final player in players) {
      final playerMetrics = player
          .getTodoProgressMetrics(memberCwl: presenceOf(player))
          .map((metric) => _TodoMetric.fromProgressMetric(metric, loc));
      for (final metric in playerMetrics) {
        final label = metric.label;
        final existing = merged[label];
        if (existing == null) {
          merged[label] = _TodoMetric(
            label: label,
            detail: metric.detail,
            done: metric.done,
            total: metric.total,
            progressDone: metric.progressDone,
            progressTotal: metric.progressTotal,
            imageUrl: metric.imageUrl,
            color: metric.color,
            fallbackIcon: metric.fallbackIcon,
          );
          order.add(label);
        } else {
          merged[label] = _TodoMetric(
            label: label,
            detail: '',
            done: existing.done + metric.done.clamp(0, metric.total),
            total: existing.total + metric.total,
            progressDone:
                existing.progressDone +
                metric.progressDone.clamp(0, metric.progressTotal),
            progressTotal: existing.progressTotal + metric.progressTotal,
            imageUrl: existing.imageUrl,
            color: existing.color,
            fallbackIcon: existing.fallbackIcon,
          );
        }
      }
    }

    final metrics = order
        .map((label) {
          final metric = merged[label]!;
          final left = math.max(metric.total - metric.done, 0);
          final detail = left == 0
              ? loc.todoCompleteLower
              : metric.total > 50
              ? loc.todoPointsLeftShort(NumberFormat.compact().format(left))
              : loc.todoItemsLeftShort(left);
          return _TodoMetric(
            label: metric.label,
            detail: detail,
            done: metric.done,
            total: metric.total,
            progressDone: metric.progressDone,
            progressTotal: metric.progressTotal,
            imageUrl: metric.imageUrl,
            color: metric.color,
            fallbackIcon: metric.fallbackIcon,
          );
        })
        .toList(growable: false);

    return _TodoSummary.fromMetrics(metrics);
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
    num? progressDone,
    num? progressTotal,
  }) : progressDone = progressDone ?? done,
       progressTotal = progressTotal ?? total;

  final String label;
  final String detail;
  final int done;
  final int total;
  final num progressDone;
  final num progressTotal;
  final String imageUrl;
  final Color color;
  final IconData fallbackIcon;

  factory _TodoMetric.fromProgressMetric(
    TodoProgressMetric metric,
    AppLocalizations loc,
  ) {
    final left = math.max(metric.total - metric.done, 0);
    return _TodoMetric(
      label: _todoMetricDisplayLabel(metric.label, loc),
      detail: metric.label == 'season_pass' || metric.label == 'clan_games'
          ? (left == 0
                ? loc.todoCompleteLower
                : loc.todoPointsLeftShort(NumberFormat.compact().format(left)))
          : left == 0
          ? loc.todoCompleteLower
          : loc.todoItemsLeftShort(left),
      done: metric.done,
      total: metric.total,
      progressDone: metric.progressDone.toDouble(),
      progressTotal: metric.progressTotal.toDouble(),
      imageUrl: switch (metric.label) {
        'legend_attacks' => ImageAssets.legendBlazonNoPadding,
        'war_attacks' => ImageAssets.war,
        'cwl_attacks' => ImageAssets.cwlSwordsNoBorder,
        'clan_games' => ImageAssets.clanGamesMedals,
        'raid_attacks' => ImageAssets.raidAttacks,
        _ => ImageAssets.iconGoldPass,
      },
      color: switch (metric.label) {
        'legend_attacks' => CKColors.legendBlue,
        'war_attacks' => CKColors.lossRed,
        'cwl_attacks' => CKColors.capitalPurple,
        'clan_games' => CKColors.donationGreen,
        'raid_attacks' => CKColors.builderBlue,
        _ => CKColors.warGold,
      },
      fallbackIcon: switch (metric.label) {
        'legend_attacks' => Icons.shield_rounded,
        'war_attacks' => Icons.local_fire_department_rounded,
        'cwl_attacks' => Icons.military_tech_rounded,
        'clan_games' => Icons.emoji_events_rounded,
        'raid_attacks' => Icons.fort_rounded,
        _ => Icons.confirmation_number_rounded,
      },
    );
  }

  double get ratio =>
      progressTotal == 0 ? 1 : (progressDone / progressTotal).clamp(0.0, 1.0);
}

String _todoMetricDisplayLabel(String label, AppLocalizations loc) {
  return switch (label) {
    'legend_attacks' => loc.todoLegendAttacks,
    'war_attacks' => loc.todoWarAttacks,
    'cwl_attacks' => loc.todoCwlAttacks,
    'clan_games' => loc.gameClanGames,
    'raid_attacks' => loc.todoRaidAttacks,
    'season_pass' => loc.gameSeasonPassShort,
    _ => label,
  };
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

  static List<_TodoPreview> mockups(AppLocalizations loc) => [
    _TodoPreview(
      name: loc.todoMockMaxedMainName,
      subtitle: loc.todoMockMaxedMainSubtitle,
      status: loc.todoMockMaxedMainStatus,
      avatarUrl: ImageAssets.townHall(17),
      summary: _TodoSummary.fromMetrics([
        _TodoMetric(
          label: loc.todoLegendAttacks,
          detail: loc.todoMockLegend5Left,
          done: 3,
          total: 8,
          imageUrl: ImageAssets.legendBlazonNoPadding,
          color: CKColors.legendBlue,
          fallbackIcon: Icons.shield_rounded,
        ),
        _TodoMetric(
          label: loc.todoWarAttacks,
          detail: loc.todoMockRaid1Left,
          done: 1,
          total: 2,
          imageUrl: ImageAssets.war,
          color: CKColors.lossRed,
          fallbackIcon: Icons.local_fire_department_rounded,
        ),
        _TodoMetric(
          label: loc.todoCwlAttacks,
          detail: loc.todoMockCwl1LeftRound,
          done: 0,
          total: 1,
          imageUrl: ImageAssets.cwlSwordsNoBorder,
          color: CKColors.capitalPurple,
          fallbackIcon: Icons.military_tech_rounded,
        ),
        _TodoMetric(
          label: loc.gameClanGames,
          detail: loc.todoMockClanGames2700Left,
          done: 1300,
          total: 4000,
          imageUrl: ImageAssets.clanGamesMedals,
          color: CKColors.donationGreen,
          fallbackIcon: Icons.emoji_events_rounded,
        ),
        _TodoMetric(
          label: loc.todoRaidAttacks,
          detail: loc.todoMockRaid4Left,
          done: 2,
          total: 6,
          imageUrl: ImageAssets.raidAttacks,
          color: CKColors.builderBlue,
          fallbackIcon: Icons.fort_rounded,
        ),
        _TodoMetric(
          label: loc.gameSeasonPassShort,
          detail: loc.todoMockPass850Left,
          done: 1750,
          total: 2600,
          imageUrl: ImageAssets.iconGoldPass,
          color: CKColors.warGold,
          fallbackIcon: Icons.confirmation_number_rounded,
        ),
      ]),
    ),
    _TodoPreview(
      name: loc.todoMockWarAltName,
      subtitle: loc.todoMockWarAltSubtitle,
      status: loc.todoMockWarAltStatus,
      avatarUrl: ImageAssets.townHall(15),
      summary: _TodoSummary.fromMetrics([
        _TodoMetric(
          label: loc.todoWarAttacks,
          detail: loc.todoMockWar2Left,
          done: 0,
          total: 2,
          imageUrl: ImageAssets.warClan,
          color: CKColors.lossRed,
          fallbackIcon: Icons.local_fire_department_rounded,
        ),
        _TodoMetric(
          label: loc.gameClanGames,
          detail: loc.todoMockClanGames900Left,
          done: 3100,
          total: 4000,
          imageUrl: ImageAssets.clanGamesMedals,
          color: CKColors.donationGreen,
          fallbackIcon: Icons.emoji_events_rounded,
        ),
        _TodoMetric(
          label: loc.todoRaidAttacks,
          detail: loc.todoMockRaid1Left,
          done: 5,
          total: 6,
          imageUrl: ImageAssets.raidAttacks,
          color: CKColors.builderBlue,
          fallbackIcon: Icons.fort_rounded,
        ),
      ]),
    ),
    _TodoPreview(
      name: loc.todoMockLegendPushName,
      subtitle: loc.todoMockLegendPushSubtitle,
      status: loc.todoMockLegendPushStatus,
      avatarUrl: ImageAssets.townHall(16),
      summary: _TodoSummary.fromMetrics([
        _TodoMetric(
          label: loc.todoLegendAttacks,
          detail: loc.todoMockLegend2Left,
          done: 6,
          total: 8,
          imageUrl: ImageAssets.legendBlazonNoPadding,
          color: CKColors.legendBlue,
          fallbackIcon: Icons.shield_rounded,
        ),
        _TodoMetric(
          label: loc.gameSeasonPassShort,
          detail: loc.todoMockOnPace,
          done: 2200,
          total: 2600,
          imageUrl: ImageAssets.iconGoldPass,
          color: CKColors.warGold,
          fallbackIcon: Icons.confirmation_number_rounded,
        ),
      ]),
    ),
    _TodoPreview(
      name: loc.todoMockCaughtUpName,
      subtitle: loc.todoMockCaughtUpSubtitle,
      status: loc.todoMockCaughtUpStatus,
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
    this.sortKey,
    this.announcement,
    this.html,
    this.htmlUrl,
  });

  final String title;
  final String subtitle;
  final String imageUrl;
  final IconData fallbackIcon;
  final Color color;
  final AppAnnouncement? announcement;
  final String? html;
  final String? htmlUrl;

  /// The event's next relevant moment: its end when active, its start
  /// otherwise. Null for non-event tiles (promo).
  final DateTime? sortKey;

  static List<_BannerItem> build({
    required AppLocalizations loc,
    required bool isDark,
    AppAnnouncement? announcement,
  }) {
    final now = DateTime.now().toUtc();
    final events = [
      _eventItem(
        now: now,
        title: loc.todoEventClanGames,
        imageUrl: ImageAssets.clanGamesMedals,
        fallbackIcon: Icons.emoji_events_rounded,
        color: CKColors.donationGreen,
        window: _monthlyWindow(now, 22, 8, 28, 8),
        loc: loc,
      ),
      _eventItem(
        now: now,
        title: loc.todoEventCwl,
        imageUrl: ImageAssets.cwlSwordsNoBorder,
        fallbackIcon: Icons.military_tech_rounded,
        color: CKColors.capitalPurple,
        window: _monthlyWindow(now, 1, 0, 13, 0),
        loc: loc,
      ),
      _eventItem(
        now: now,
        title: loc.todoEventSeasonEnds,
        imageUrl: ImageAssets.iconGoldPass,
        fallbackIcon: Icons.hourglass_bottom_rounded,
        color: CKColors.warGold,
        window: _seasonWindow(now),
        loc: loc,
      ),
      _eventItem(
        now: now,
        title: loc.todoEventLeagueReset,
        imageUrl: ImageAssets.legendBlazonNoPadding,
        fallbackIcon: Icons.leaderboard_rounded,
        color: CKColors.legendBlue,
        window: _seasonWindow(now),
        loc: loc,
      ),
      _eventItem(
        now: now,
        title: loc.todoEventRaidWeekend,
        imageUrl: ImageAssets.raidAttacks,
        fallbackIcon: Icons.fort_rounded,
        color: CKColors.builderBlue,
        window: _raidWindow(now),
        loc: loc,
      ),
    ]..sort((a, b) => a.sortKey!.compareTo(b.sortKey!));

    final featuredStory = AppAnnouncement.animeFury;

    return [
      if (announcement != null) _announcementItem(announcement, loc),
      if (announcement?.id != featuredStory.id)
        _announcementItem(featuredStory, loc),
      if (announcement == null)
        _BannerItem(
          title: loc.todoMagicDispatch,
          subtitle: loc.todoMagicDispatchDescription,
          imageUrl: ImageAssets.builderWave,
          fallbackIcon: Icons.auto_awesome_rounded,
          color: CKColors.primaryRed,
        ),
      _BannerItem(
        title: loc.todoUseCodeClashKing,
        subtitle: loc.todoUseCodeClashKingDescription,
        imageUrl: isDark ? ImageAssets.darkModeLogo : ImageAssets.lightModeLogo,
        fallbackIcon: Icons.local_offer_rounded,
        color: CKColors.primaryRed,
      ),
      ...events,
    ];
  }

  static _BannerItem _announcementItem(
    AppAnnouncement announcement,
    AppLocalizations loc,
  ) {
    final isAnimeFury = announcement.id == AppAnnouncement.animeFury.id;
    return _BannerItem(
      title: isAnimeFury ? loc.announcementAnimeFuryTitle : announcement.title,
      subtitle: isAnimeFury
          ? loc.announcementAnimeFurySubtitle
          : announcement.subtitle,
      imageUrl: announcement.bannerImageUrl ?? ImageAssets.builderWave,
      fallbackIcon: Icons.auto_awesome_rounded,
      color: CKColors.primaryRed,
      announcement: announcement,
      html: announcement.body,
      htmlUrl: announcement.htmlUrl,
      sortKey: announcement.startsAt,
    );
  }

  static _BannerItem _eventItem({
    required DateTime now,
    required String title,
    required String imageUrl,
    required IconData fallbackIcon,
    required Color color,
    required ({DateTime start, DateTime end}) window,
    required AppLocalizations loc,
  }) {
    final active = !now.isBefore(window.start) && now.isBefore(window.end);
    final target = active ? window.end : window.start;
    return _BannerItem(
      title: title,
      imageUrl: imageUrl,
      fallbackIcon: fallbackIcon,
      color: color,
      sortKey: target,
      subtitle: active
          ? loc.todoEventEndsIn(_formatRemaining(target.difference(now)))
          : loc.todoEventStartsIn(_formatRemaining(target.difference(now))),
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
