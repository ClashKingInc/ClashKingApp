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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

const bool _showTodoMockups = false;
const double _homePagerDesktopBreakpoint = 900;

bool _usesDesktopHomePager(BuildContext context) =>
    kIsWeb && MediaQuery.sizeOf(context).width >= _homePagerDesktopBreakpoint;

void _animateHomePagerTo(
  BuildContext context,
  PageController controller,
  int page,
) {
  if (!controller.hasClients) return;
  if (CKMotion.animationsDisabled(context)) {
    controller.jumpToPage(page);
    return;
  }
  controller.animateToPage(
    page,
    duration: CKMotion.fast,
    curve: CKMotion.standardCurve,
  );
}

class HomeEventBanner extends StatefulWidget {
  const HomeEventBanner({super.key});

  @override
  State<HomeEventBanner> createState() => _HomeEventBannerState();
}

class _HomeEventBannerState extends State<HomeEventBanner> {
  late final PageController _controller;
  late final AnnouncementService _announcementService;
  late final Future<List<AppAnnouncement>> _announcementsFuture;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _announcementService = AnnouncementService();
    _announcementsFuture = _announcementService.getActiveAnnouncements();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _index = 0;

  void _showBannerPage(int count, int page) {
    if (count <= 0) return;
    final next = page % count;
    setState(() => _index = next);
    _animateHomePagerTo(context, _controller, next);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;

    return FutureBuilder<List<AppAnnouncement>>(
      future: _announcementsFuture,
      builder: (context, snapshot) {
        final items = _BannerItem.build(
          loc: loc,
          isDark: isDark,
          announcements: snapshot.data ?? const [],
        );

        final useDesktopPager = _usesDesktopHomePager(context);
        if (useDesktopPager) {
          final featured = items.firstWhere(
            (item) => item.sortKey == null && item.announcement == null,
            orElse: () => items.first,
          );
          final eventItems = items
              .where((item) => !identical(item, featured))
              .toList(growable: false);
          return _HomeEventsDesktopGrid(featured: featured, items: eventItems);
        }

        final pageView = SizedBox(
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
        );

        return Column(
          children: [
            pageView,
            const SizedBox(height: 8),
            if (useDesktopPager && items.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _PageDots(
                    count: items.length,
                    index: _index,
                    onDotTap: (index) => _showBannerPage(items.length, index),
                  ),
                  const SizedBox(width: 12),
                  _PagerArrowButton(
                    icon: Icons.chevron_left_rounded,
                    tooltip: 'Previous card',
                    onPressed: () => _showBannerPage(
                      items.length,
                      (_index - 1 + items.length) % items.length,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _PagerArrowButton(
                    icon: Icons.chevron_right_rounded,
                    tooltip: 'Next card',
                    onPressed: () => _showBannerPage(
                      items.length,
                      (_index + 1) % items.length,
                    ),
                  ),
                ],
              )
            else
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

  void _showTodoPage(int count, int page) {
    if (count <= 0) return;
    final next = page % count;
    setState(() => _index = next);
    _animateHomePagerTo(context, _controller, next);
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
    final useDesktopPager = _usesDesktopHomePager(context);

    if (useDesktopPager) {
      return _HomeTodoDesktopGrid(
        itemCount: itemCount,
        hasSummaryPage: hasSummaryPage,
        itemHeight: height,
        itemBuilder: (context, index) => _buildTodoPanel(
          context,
          index,
          mockups,
          hasSummaryPage,
          summaries,
          warCwlService,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (index) => setState(() => _index = index),
            itemCount: itemCount,
            itemBuilder: (context, index) => _buildTodoPanel(
              context,
              index,
              mockups,
              hasSummaryPage,
              summaries,
              warCwlService,
            ),
          ),
        ),
        if (itemCount > 1) ...[
          const SizedBox(height: 10),
          if (useDesktopPager)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _PageDots(
                  count: itemCount,
                  index: _index,
                  onDotTap: (index) => _showTodoPage(itemCount, index),
                ),
                const SizedBox(width: 12),
                _PagerArrowButton(
                  icon: Icons.chevron_left_rounded,
                  tooltip: 'Previous card',
                  onPressed: () => _showTodoPage(
                    itemCount,
                    (_index - 1 + itemCount) % itemCount,
                  ),
                ),
                const SizedBox(width: 6),
                _PagerArrowButton(
                  icon: Icons.chevron_right_rounded,
                  tooltip: 'Next card',
                  onPressed: () =>
                      _showTodoPage(itemCount, (_index + 1) % itemCount),
                ),
              ],
            )
          else
            Center(
              child: _PageDots(count: itemCount, index: _index),
            ),
        ],
      ],
    );
  }

  Widget _buildTodoPanel(
    BuildContext context,
    int index,
    List<_TodoPreview> mockups,
    bool hasSummaryPage,
    List<_TodoSummary> summaries,
    WarCwlService? warCwlService,
  ) {
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

class _HomeTodoDesktopGrid extends StatelessWidget {
  const _HomeTodoDesktopGrid({
    required this.itemCount,
    required this.hasSummaryPage,
    required this.itemHeight,
    required this.itemBuilder,
  });

  final int itemCount;
  final bool hasSummaryPage;
  final double itemHeight;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    const gap = 12.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final firstGridIndex = hasSummaryPage ? 1 : 0;
        final gridCount = itemCount - firstGridIndex;
        final columns = constraints.maxWidth >= 1240 && gridCount >= 3
            ? 3
            : constraints.maxWidth >= 760 && gridCount >= 2
            ? 2
            : 1;
        final cardWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        final children = <Widget>[
          if (hasSummaryPage)
            SizedBox(
              height: itemHeight,
              width: constraints.maxWidth,
              child: itemBuilder(context, 0),
            ),
          if (hasSummaryPage && gridCount > 0) const SizedBox(height: gap),
          if (gridCount > 0)
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var index = firstGridIndex; index < itemCount; index++)
                  SizedBox(
                    width: cardWidth,
                    height: itemHeight,
                    child: itemBuilder(context, index),
                  ),
              ],
            ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        );
      },
    );
  }
}

class _TodoPreviewPanel extends StatelessWidget {
  const _TodoPreviewPanel({required this.preview});

  final _TodoPreview preview;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = _usesDesktopHomePager(context);
    final ringSize = isDesktop ? 54.0 : 46.0;

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
            mainAxisAlignment: isDesktop
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _PreviewHeader(preview: preview)),
                  _TodoRing(summary: preview.summary, size: ringSize),
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
    final isDesktop = _usesDesktopHomePager(context);
    final ringSize = isDesktop ? 54.0 : 46.0;

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
              mainAxisAlignment: isDesktop
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _AccountHeader(player: player)),
                    _TodoRing(summary: summary, size: ringSize),
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
    final isDesktop = _usesDesktopHomePager(context);
    final iconSize = isDesktop ? 42.0 : 30.0;
    final ringSize = isDesktop ? 54.0 : 46.0;

    final header = Row(
      children: [
        SizedBox.square(
          dimension: iconSize,
          child: MobileWebImage(
            imageUrl: ImageAssets.iconBuilderPotion,
            fit: BoxFit.contain,
            errorWidget: (context, url, error) => Icon(
              Icons.checklist_rounded,
              size: isDesktop ? 30 : 24,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        SizedBox(width: isDesktop ? 12 : 10),
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
              mainAxisAlignment: isDesktop
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: header),
                    _TodoRing(summary: summary, size: ringSize),
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
    final isDesktop = _usesDesktopHomePager(context);
    final iconSize = isDesktop ? 42.0 : 30.0;

    return Row(
      children: [
        SizedBox.square(
          dimension: iconSize,
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
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: isDesktop ? 14 : null,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: isDesktop ? 12 : 10),
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
    final isDesktop = _usesDesktopHomePager(context);
    final iconSize = isDesktop ? 42.0 : 30.0;

    return Row(
      children: [
        SizedBox.square(
          dimension: iconSize,
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
                  size: isDesktop ? 24 : 18,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: isDesktop ? 12 : 10),
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
  const _PageDots({required this.count, required this.index, this.onDotTap});

  final int count;
  final int index;
  final ValueChanged<int>? onDotTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (dotIndex) {
        final selected = dotIndex == index;
        final dot = AnimatedContainer(
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

        if (onDotTap == null) return dot;
        return Tooltip(
          message: 'Card ${dotIndex + 1}',
          child: InkResponse(
            radius: 14,
            onTap: () => onDotTap!(dotIndex),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 8),
              child: dot,
            ),
          ),
        );
      }),
    );
  }
}

class _PagerArrowButton extends StatelessWidget {
  const _PagerArrowButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 34,
            child: Icon(icon, size: 22, color: colorScheme.onSurface),
          ),
        ),
      ),
    );
  }
}

Color _bannerAccentColor(BuildContext context, _BannerItem item) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final sourceHsl = HSLColor.fromColor(item.color);
  return isDark
      ? sourceHsl
            .withSaturation(math.max(sourceHsl.saturation, 0.78))
            .withLightness(math.max(sourceHsl.lightness, 0.56))
            .toColor()
      : item.color;
}

VoidCallback? _bannerItemOnTap(BuildContext context, _BannerItem item) {
  final hasStory = item.announcement?.storyUrl?.isNotEmpty ?? false;
  final hasArticle =
      hasStory ||
      item.html != null ||
      (item.htmlUrl != null && item.htmlUrl!.trim().isNotEmpty);
  if (!hasArticle) return null;

  return () async {
    if (hasStory) {
      final announcement = item.announcement!;
      final storyFilePath = await AnnouncementStoryCacheService().prepare(
        announcement,
      );
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
}

class _HomeEventsDesktopGrid extends StatelessWidget {
  const _HomeEventsDesktopGrid({required this.featured, required this.items});

  final _BannerItem featured;
  final List<_BannerItem> items;

  @override
  Widget build(BuildContext context) {
    const gap = 8.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 920
            ? math.min(items.length, 5)
            : constraints.maxWidth >= 620
            ? math.min(items.length, 3)
            : math.min(items.length, 2);
        final cardWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HomeFeaturedBannerCard(item: featured),
            if (items.isNotEmpty) ...[
              const SizedBox(height: gap),
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final item in items.take(8))
                    SizedBox(
                      width: cardWidth,
                      height: 62,
                      child: _HomeEventGridCard(item: item),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _HomeFeaturedBannerCard extends StatelessWidget {
  const _HomeFeaturedBannerCard({required this.item});

  final _BannerItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = _bannerAccentColor(context, item);
    final onTap = _bannerItemOnTap(context, item);

    return Semantics(
      button: onTap != null,
      label: '${item.title}, ${item.subtitle}',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            height: 94,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isDark ? 0.22 : 0.12),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: accentColor.withValues(alpha: isDark ? 0.62 : 0.44),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.76),
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox.square(
                      dimension: 58,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: MobileWebImage(
                          imageUrl: item.imageUrl,
                          fit: BoxFit.contain,
                          errorWidget: (context, url, error) => Icon(
                            item.fallbackIcon,
                            color: accentColor,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 17,
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

class _HomeEventGridCard extends StatelessWidget {
  const _HomeEventGridCard({required this.item});

  final _BannerItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = _bannerAccentColor(context, item);
    final onTap = _bannerItemOnTap(context, item);

    return Semantics(
      button: onTap != null,
      label: '${item.title}, ${item.subtitle}',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: item.highlighted
                  ? CKColors.warGold.withValues(alpha: isDark ? 0.18 : 0.10)
                  : colorScheme.surface.withValues(alpha: isDark ? 0.74 : 0.92),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: accentColor.withValues(
                  alpha: item.highlighted
                      ? (isDark ? 0.58 : 0.46)
                      : (isDark ? 0.32 : 0.20),
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: accentColor.withValues(
                        alpha: isDark ? 0.20 : 0.12,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox.square(
                      dimension: 34,
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: MobileWebImage(
                          imageUrl: item.imageUrl,
                          fit: BoxFit.contain,
                          errorWidget: (context, url, error) => Icon(
                            item.fallbackIcon,
                            color: accentColor,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 5),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
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

class _BannerTile extends StatefulWidget {
  const _BannerTile({super.key, required this.item});

  final _BannerItem item;

  @override
  State<_BannerTile> createState() => _BannerTileState();
}

class _BannerTileState extends State<_BannerTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.item.highlighted && !CKMotion.animationsDisabled(context)) {
      if (!_shimmerController.isAnimating) {
        _shimmerController.repeat();
      }
    } else {
      _shimmerController
        ..stop()
        ..value = 0.5;
    }
  }

  @override
  void didUpdateWidget(covariant _BannerTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.highlighted != oldWidget.item.highlighted) {
      if (widget.item.highlighted && !CKMotion.animationsDisabled(context)) {
        _shimmerController.repeat();
      } else {
        _shimmerController
          ..stop()
          ..value = 0.5;
      }
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
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
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: accentColor.withValues(
                alpha: item.highlighted
                    ? (isDark ? 0.72 : 0.58)
                    : (isDark ? 0.42 : 0.24),
              ),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) {
              final progress = _shimmerController.value;
              final background = accentColor.withValues(
                alpha: isDark ? 0.22 : 0.12,
              );
              return Ink(
                decoration: BoxDecoration(
                  color: item.highlighted ? null : background,
                  gradient: item.highlighted
                      ? LinearGradient(
                          begin: Alignment(-2.4 + (progress * 4.8), -0.35),
                          end: Alignment(-0.4 + (progress * 4.8), 0.35),
                          colors: [
                            CKColors.warGold.withValues(
                              alpha: isDark ? 0.18 : 0.10,
                            ),
                            const Color(
                              0xFFFFE7A0,
                            ).withValues(alpha: isDark ? 0.42 : 0.32),
                            CKColors.warGold.withValues(
                              alpha: isDark ? 0.18 : 0.10,
                            ),
                          ],
                        )
                      : null,
                ),
                child: child,
              );
            },
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
    this.highlighted = false,
  });

  final String title;
  final String subtitle;
  final String imageUrl;
  final IconData fallbackIcon;
  final Color color;
  final AppAnnouncement? announcement;
  final String? html;
  final String? htmlUrl;
  final bool highlighted;

  /// The event's next relevant moment: its end when active, its start
  /// otherwise. Null for non-event tiles (promo).
  final DateTime? sortKey;

  static List<_BannerItem> build({
    required AppLocalizations loc,
    required bool isDark,
    List<AppAnnouncement> announcements = const [],
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

    return [
      ...announcements.map(
        (announcement) => _announcementItem(announcement, loc),
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
    return _BannerItem(
      title: announcement.title,
      subtitle: announcement.subtitle,
      imageUrl: announcement.bannerImageUrl ?? ImageAssets.builderWave,
      fallbackIcon: Icons.auto_awesome_rounded,
      color: CKColors.warGold,
      highlighted: true,
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
