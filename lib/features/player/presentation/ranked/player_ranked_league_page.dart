import 'dart:async' show unawaited;

import 'package:clashkingapp/common/widgets/empty_state.dart';
import 'package:clashkingapp/common/widgets/info_profile_tabs.dart';
import 'package:clashkingapp/common/widgets/liquid_glass.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/navigation/page_dots_indicator.dart';
import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/models/player_ranked_league.dart';
import 'package:clashkingapp/features/player/presentation/player/player_page.dart';
import 'package:clashkingapp/features/player/presentation/ranked/player_ranked_league_header.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PlayerRankedLeagueScreen extends StatefulWidget {
  const PlayerRankedLeagueScreen({super.key, required this.player});

  final Player player;

  @override
  State<PlayerRankedLeagueScreen> createState() =>
      _PlayerRankedLeagueScreenState();
}

class _PlayerRankedLeagueScreenState extends State<PlayerRankedLeagueScreen> {
  int _selectedSeason = 0;
  int _selectedTab = 0;
  bool _showCurrentRanking = false;
  bool _showHistoryTable = false;
  RankedLeagueData? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch(forceRefresh: false);
  }

  // Keeps the last-loaded data mounted across a refresh instead of tearing
  // down the hero header/tabs — the RefreshIndicator already provides the
  // reload affordance, so a full-screen loading swap would just be a flash.
  // Same philosophy applies to opening the screen itself: show a warmed
  // cache instantly (no loading flash) and quietly revalidate in the
  // background, rather than forcing every open through a spinner.
  Future<void> _fetch({required bool forceRefresh}) async {
    try {
      final data = await context.read<PlayerService>().loadRankedLeagueData(
        widget.player.tag,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
    if (!forceRefresh) {
      // The cached value just shown may already be stale (attacks done,
      // rank moved since it was cached) — catch up silently instead of
      // leaving the user looking at outdated numbers all session.
      unawaited(_revalidate());
    }
  }

  Future<void> _revalidate() async {
    try {
      final fresh = await context.read<PlayerService>().loadRankedLeagueData(
        widget.player.tag,
        forceRefresh: true,
      );
      if (!mounted) return;
      setState(() => _data = fresh);
    } catch (_) {
      // Best-effort only; the initial fetch already surfaced any error.
    }
  }

  Future<void> _refresh() => _fetch(forceRefresh: true);

  void _selectTab(int index) {
    final clamped = index.clamp(0, 1);
    if (clamped == _selectedTab) return;
    setState(() => _selectedTab = clamped);
  }

  void _handleTabSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 240) return;
    if (velocity < 0) {
      _selectTab(_selectedTab + 1);
    } else {
      _selectTab(_selectedTab - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null) {
      if (_loading) {
        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.rankedLeagueTitle),
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.rankedLeagueTitle),
        ),
        body: AppEmptyState(
          title: AppLocalizations.of(context)!.generalNoDataAvailable,
          icon: Icons.cloud_off_rounded,
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
          stickerHeight: 180,
          stickerWidth: 150,
        ),
        floatingActionButton: FloatingActionButton.small(
          onPressed: _refresh,
          child: const Icon(Icons.refresh_rounded),
        ),
      );
    }

    final periods = _PeriodViewModel.fromData(data);
    final selectedSeason = _selectedSeason.clamp(0, periods.length - 1);
    final selectedPeriod = periods[selectedSeason];

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: _handleTabSwipe,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: RankedLeagueHeaderCard(
                  player: widget.player,
                  data: data,
                ),
              ),
              // Once the header/tabs scroll past the top of the viewport,
              // they'd otherwise render under the (transparent) status bar —
              // the header itself is meant to bleed under it, but the tab
              // labels and card content are not.
              SliverSafeArea(
                bottom: false,
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      InfoProfileTabs(
                        selectedIndex: _selectedTab,
                        onTabSelected: _selectTab,
                        tabs: [
                          InfoProfileTabData(
                            label: AppLocalizations.of(
                              context,
                            )!.clanRankingsSeason,
                            icon: Icons.calendar_month_rounded,
                          ),
                          InfoProfileTabData(
                            label: AppLocalizations.of(context)!.generalHistory,
                            icon: Icons.history_rounded,
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeOutCubic,
                          child: KeyedSubtree(
                            key: ValueKey(_selectedTab),
                            child: switch (_selectedTab) {
                              0 => _CurrentPeriodTab(
                                data: data,
                                period: selectedPeriod,
                                onOlderSeason:
                                    selectedSeason < periods.length - 1
                                    ? () => setState(
                                        () => _selectedSeason =
                                            selectedSeason + 1,
                                      )
                                    : null,
                                onNewerSeason: selectedSeason > 0
                                    ? () => setState(
                                        () => _selectedSeason =
                                            selectedSeason - 1,
                                      )
                                    : null,
                                showRanking: _showCurrentRanking,
                                onViewChanged: (showRanking) => setState(
                                  () => _showCurrentRanking = showRanking,
                                ),
                              ),
                              _ => _HistoryTab(
                                data: data,
                                showTable: _showHistoryTable,
                                onToggleView: () => setState(
                                  () => _showHistoryTable = !_showHistoryTable,
                                ),
                              ),
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodViewModel {
  const _PeriodViewModel({
    required this.seasonId,
    required this.startsAt,
    required this.trophies,
    required this.placement,
    required this.attackWins,
    required this.attackLosses,
    required this.attackStars,
    required this.defenseWins,
    required this.defenseLosses,
    required this.defenseStars,
    required this.maxBattles,
    required this.tier,
    required this.group,
    required this.isCurrent,
  });

  final int seasonId;
  final DateTime startsAt;
  final int trophies;
  final int placement;
  final int attackWins;
  final int attackLosses;
  final int attackStars;
  final int defenseWins;
  final int defenseLosses;
  final int defenseStars;
  final int maxBattles;
  final RankedLeagueTier? tier;
  final RankedLeagueGroup? group;
  final bool isCurrent;

  List<RankedLeagueBattle> get attacks => group?.attackLogs ?? const [];
  List<RankedLeagueBattle> get defenses => group?.defenseLogs ?? const [];
  bool get hasDetails => group != null;
  int get attackCount =>
      hasDetails ? attacks.length : attackWins + attackLosses;
  int get defenseCount =>
      hasDetails ? defenses.length : defenseWins + defenseLosses;

  static List<_PeriodViewModel> fromData(RankedLeagueData data) {
    final currentGroup = data.currentGroup;
    final member = data.currentMember;
    final currentSeasonId =
        currentGroup?.seasonId ??
        DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final periods = <_PeriodViewModel>[
      _PeriodViewModel(
        seasonId: currentSeasonId,
        startsAt: DateTime.fromMillisecondsSinceEpoch(
          currentSeasonId * 1000,
          isUtc: true,
        ),
        trophies: member?.leagueTrophies ?? data.trophies,
        placement: data.currentRank ?? 0,
        attackWins: member?.attackWinCount ?? 0,
        attackLosses: member?.attackLoseCount ?? 0,
        attackStars: (currentGroup?.attackLogs ?? const <RankedLeagueBattle>[])
            .fold<int>(0, (sum, battle) => sum + battle.stars),
        defenseWins: member?.defenseWinCount ?? 0,
        defenseLosses: member?.defenseLoseCount ?? 0,
        defenseStars:
            (currentGroup?.defenseLogs ?? const <RankedLeagueBattle>[])
                .fold<int>(0, (sum, battle) => sum + battle.stars),
        maxBattles: data.currentMaxBattles ?? 0,
        tier: data.currentTier,
        group: currentGroup,
        isCurrent: true,
      ),
    ];
    for (final entry in data.history) {
      if (entry.leagueSeasonId == currentSeasonId) continue;
      periods.add(
        _PeriodViewModel(
          seasonId: entry.leagueSeasonId,
          startsAt: entry.startsAt,
          trophies: entry.leagueTrophies,
          placement: entry.placement,
          attackWins: entry.attackWins,
          attackLosses: entry.attackLosses,
          attackStars: entry.attackStars,
          defenseWins: entry.defenseWins,
          defenseLosses: entry.defenseLosses,
          defenseStars: entry.defenseStars,
          maxBattles: entry.maxBattles,
          tier: data.tiers[entry.leagueTierId],
          group: data.groupForSeason(entry.leagueSeasonId),
          isCurrent: false,
        ),
      );
    }
    return periods;
  }
}

class _CurrentPeriodTab extends StatelessWidget {
  const _CurrentPeriodTab({
    required this.data,
    required this.period,
    required this.onOlderSeason,
    required this.onNewerSeason,
    required this.showRanking,
    required this.onViewChanged,
  });

  final RankedLeagueData data;
  final _PeriodViewModel period;
  final VoidCallback? onOlderSeason;
  final VoidCallback? onNewerSeason;
  final bool showRanking;
  final ValueChanged<bool> onViewChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LiquidGlassSegmentedControl<bool>(
          values: const [false, true],
          labels: [
            AppLocalizations.of(context)!.generalDetails,
            AppLocalizations.of(context)!.sideRankingsTitle,
          ],
          selected: showRanking,
          onChanged: onViewChanged,
          height: 44,
        ),
        const SizedBox(height: 12),
        _PeriodNavigator(
          period: period,
          onOlderSeason: onOlderSeason,
          onNewerSeason: onNewerSeason,
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: showRanking
              ? KeyedSubtree(
                  key: ValueKey('ranking-${period.seasonId}'),
                  child: _GroupRanking(
                    group: period.group,
                    playerTag: data.playerTag,
                  ),
                )
              : Column(
                  key: ValueKey('details-${period.seasonId}'),
                  children: [
                    _RankAndTrophiesCard(period: period),
                    const SizedBox(height: 8),
                    _OffenseDefenseCard(period: period),
                    const SizedBox(height: 8),
                    _UnavailableDataCard(
                      imageUrl: ImageAssets.shieldWithArrow,
                      title: AppLocalizations.of(context)!.gameHeroesEquipments,
                      body: AppLocalizations.of(
                        context,
                      )!.rankedLeagueEquipmentUnavailable,
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({
    required this.data,
    required this.showTable,
    required this.onToggleView,
  });

  final RankedLeagueData data;
  final bool showTable;
  final VoidCallback onToggleView;

  @override
  Widget build(BuildContext context) {
    final periods = _PeriodViewModel.fromData(
      data,
    ).where((period) => !period.isCurrent).toList();
    if (periods.isEmpty) {
      return AppEmptyState(
        title: AppLocalizations.of(context)!.generalNoDataAvailable,
        icon: Icons.history_toggle_off_rounded,
        padding: const EdgeInsets.all(16),
        stickerHeight: 180,
        stickerWidth: 150,
      );
    }
    final tierHighlights = _tierHighlights(periods);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          tooltip: showTable
              ? AppLocalizations.of(context)!.tooltipShowChart
              : AppLocalizations.of(context)!.tooltipShowTable,
          onPressed: onToggleView,
          icon: Icon(
            showTable ? Icons.show_chart_rounded : Icons.table_rows_rounded,
          ),
        ),
        _BestTierPager(highlights: tierHighlights),
        const SizedBox(height: 20),
        if (showTable)
          _EndOfPeriodList(periods: periods)
        else
          _HistoryChart(
            periods: periods,
            title: AppLocalizations.of(context)!.legendsEosTrophies,
          ),
      ],
    );
  }

  // A player can revisit the same league/tier across several different
  // periods, each with its own trophies/rank/attacks — so "best" is tracked
  // per category within a tier, not a single arbitrarily-chosen period.
  List<_TierHighlights> _tierHighlights(List<_PeriodViewModel> periods) {
    final byTier = <int, List<_PeriodViewModel>>{};
    for (final period in periods) {
      final tierId = period.tier?.id;
      if (tierId == null) continue;
      byTier.putIfAbsent(tierId, () => []).add(period);
    }

    // Higher tier IDs are always better, all the way up through Legend
    // League's top sub-tiers — unlike each tier's display name, which isn't
    // ordered consistently enough to sort by (e.g. "Legend League 1" outranks
    // every numbered tier despite its trailing digit being small).
    return byTier.values.map(_buildTierHighlights).toList()
      ..sort((a, b) => (b.tier?.id ?? 0).compareTo(a.tier?.id ?? 0));
  }

  _TierHighlights _buildTierHighlights(List<_PeriodViewModel> list) {
    final lastPeriod = list.reduce((a, b) => a.seasonId > b.seasonId ? a : b);
    final ranked = list.where((period) => period.placement > 0).toList();
    final bestRankPeriod = ranked.isEmpty
        ? null
        : ranked.reduce((a, b) => a.placement < b.placement ? a : b);
    final bestTrophiesPeriod = list.reduce(
      (a, b) => a.trophies > b.trophies ? a : b,
    );
    final mostAttacksPeriod = list.reduce(
      (a, b) => a.attackCount > b.attackCount ? a : b,
    );
    return _TierHighlights(
      tier: list.first.tier,
      lastPeriod: lastPeriod,
      bestRankPeriod: bestRankPeriod,
      bestTrophiesPeriod: bestTrophiesPeriod,
      mostAttacksPeriod: mostAttacksPeriod,
    );
  }
}

class _TierHighlights {
  const _TierHighlights({
    required this.tier,
    required this.lastPeriod,
    required this.bestRankPeriod,
    required this.bestTrophiesPeriod,
    required this.mostAttacksPeriod,
  });

  final RankedLeagueTier? tier;
  final _PeriodViewModel lastPeriod;
  final _PeriodViewModel? bestRankPeriod;
  final _PeriodViewModel bestTrophiesPeriod;
  final _PeriodViewModel mostAttacksPeriod;
}

/// Swipeable "one card per tier" carousel — same PageView + dot-pager
/// pattern as the home screen's to-do card (`HomeTodoCard`).
class _BestTierPager extends StatefulWidget {
  const _BestTierPager({required this.highlights});

  final List<_TierHighlights> highlights;

  @override
  State<_BestTierPager> createState() => _BestTierPagerState();
}

class _BestTierPagerState extends State<_BestTierPager> {
  late final PageController _controller;
  int _index = 0;

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

  void _showPage(int page) {
    final count = widget.highlights.length;
    if (count <= 0) return;
    final next = page % count;
    setState(() => _index = next);
    if (!_controller.hasClients) return;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final highlights = widget.highlights;
    if (highlights.isEmpty) {
      return _UnavailableDataCard(
        icon: Icons.workspace_premium_outlined,
        title: AppLocalizations.of(context)!.generalNoDataAvailable,
        body: AppLocalizations.of(context)!.rankedLeagueHistorySubtitle,
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (index) => setState(() => _index = index),
            itemCount: highlights.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _BestTierCard(
                highlights: highlights[index],
                isOverallBest: index == 0,
              ),
            ),
          ),
        ),
        if (highlights.length > 1) ...[
          const SizedBox(height: 10),
          Center(
            child: PageDotsIndicator(
              count: highlights.length,
              index: _index,
              onDotTap: _showPage,
            ),
          ),
        ],
      ],
    );
  }
}

class _BestTierCard extends StatelessWidget {
  const _BestTierCard({required this.highlights, required this.isOverallBest});

  final _TierHighlights highlights;
  final bool isOverallBest;

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFFFD75E);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;
    // A player can revisit the same tier across several periods, each with
    // its own record — so this mirrors the old Legend highlights card
    // (2x2 grid of Last Season / Best Rank / Best Trophies / Most Attacks)
    // but scoped to one tier per swipeable page, since Ranked has many
    // tiers where Legend only ever had the one league.
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOverallBest
            ? gold.withValues(alpha: isDark ? 0.16 : 0.12)
            : Theme.of(context).cardTheme.color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isOverallBest
              ? gold.withValues(alpha: 0.7)
              : colorScheme.outlineVariant.withValues(
                  alpha: AppOpacity.borderStrong,
                ),
          width: isOverallBest ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox.square(
                dimension: 32,
                child: highlights.tier?.largeIconUrl.isNotEmpty == true
                    ? MobileWebImage(imageUrl: highlights.tier!.largeIconUrl)
                    : const Icon(Icons.military_tech_rounded),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  highlights.tier?.name ?? '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (isOverallBest)
                const Icon(Icons.emoji_events_rounded, color: gold, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _TierCategoryInfo(
                  title: loc.rankedLeagueLastPeriod,
                  period: highlights.lastPeriod,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TierCategoryInfo(
                  title: loc.rankedLeagueBestGroupRank,
                  period: highlights.bestRankPeriod,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _TierCategoryInfo(
                  title: loc.legendsBestTrophies,
                  period: highlights.bestTrophiesPeriod,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TierCategoryInfo(
                  title: loc.legendsMostAttacks,
                  period: highlights.mostAttacksPeriod,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One quadrant of the 2x2 highlights grid — mirrors the old Legend
/// `buildSeasonInfo` helper: category label, date, then compact stat rows.
class _TierCategoryInfo extends StatelessWidget {
  const _TierCategoryInfo({required this.title, required this.period});

  final String title;
  final _PeriodViewModel? period;

  @override
  Widget build(BuildContext context) {
    final period = this.period;
    if (period == null) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          DateFormat.yMMMd(locale).format(period.startsAt.toLocal()),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        _CategoryStatRow(
          imageUrl: ImageAssets.trophies,
          value: NumberFormat('#,###', locale).format(period.trophies),
        ),
        const SizedBox(height: 2),
        _CategoryStatRow(
          icon: Icons.leaderboard_rounded,
          value: period.placement > 0 ? '#${period.placement}' : '-',
        ),
        const SizedBox(height: 2),
        _CategoryStatRow(
          imageUrl: ImageAssets.sword,
          value: '${period.attackCount}',
        ),
      ],
    );
  }
}

class _CategoryStatRow extends StatelessWidget {
  const _CategoryStatRow({this.imageUrl, this.icon, required this.value});

  final String? imageUrl;
  final IconData? icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (imageUrl != null)
          MobileWebImage(imageUrl: imageUrl!, width: 16, height: 16)
        else
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        const SizedBox(width: 4),
        Text(value, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class _PeriodNavigator extends StatelessWidget {
  const _PeriodNavigator({
    required this.period,
    required this.onOlderSeason,
    required this.onNewerSeason,
  });

  final _PeriodViewModel period;
  final VoidCallback? onOlderSeason;
  final VoidCallback? onNewerSeason;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final end = period.startsAt.add(const Duration(days: 7));
    final dateRange =
        '${DateFormat.MMMd(locale).format(period.startsAt.toLocal())} - '
        '${DateFormat.MMMd(locale).format(end.toLocal())}';
    return Row(
      children: [
        IconButton(
          tooltip: MaterialLocalizations.of(context).previousPageTooltip,
          onPressed: onOlderSeason,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                period.isCurrent
                    ? AppLocalizations.of(context)!.rankedLeagueCurrentPeriod
                    : AppLocalizations.of(context)!.clanRankingsSeason,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                dateRange,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: MaterialLocalizations.of(context).nextPageTooltip,
          onPressed: onNewerSeason,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _RankAndTrophiesCard extends StatelessWidget {
  const _RankAndTrophiesCard({required this.period});

  final _PeriodViewModel period;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    return _SurfaceCard(
      child: Row(
        children: [
          Expanded(
            child: _LargeMetric(
              label: AppLocalizations.of(context)!.rankedLeagueGroupRank,
              value: period.placement > 0
                  ? '#${formatter.format(period.placement)}'
                  : '-',
            ),
          ),
          SizedBox.square(
            dimension: 82,
            child: period.tier?.largeIconUrl.isNotEmpty == true
                ? MobileWebImage(imageUrl: period.tier!.largeIconUrl)
                : const Icon(Icons.military_tech_rounded, size: 54),
          ),
          Expanded(
            child: _LargeMetric(
              label: AppLocalizations.of(context)!.rankedLeagueTrophies,
              value: formatter.format(period.trophies),
            ),
          ),
        ],
      ),
    );
  }
}

class _LargeMetric extends StatelessWidget {
  const _LargeMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _OffenseDefenseCard extends StatefulWidget {
  const _OffenseDefenseCard({required this.period});

  final _PeriodViewModel period;

  @override
  State<_OffenseDefenseCard> createState() => _OffenseDefenseCardState();
}

// Matches the two side-by-side cards to the same height by measuring both
// after they've laid out naturally, then locking them to the taller one.
// Deliberately avoids IntrinsicHeight: forcing this subtree through Flutter's
// intrinsic-dimension protocol triggered a render failure on-device (blank
// screen, no error box) with the Impeller/Vulkan backend — this two-pass
// "measure then constrain" approach only uses normal layout passes.
class _OffenseDefenseCardState extends State<_OffenseDefenseCard> {
  final _attackKey = GlobalKey();
  final _defenseKey = GlobalKey();
  double? _matchedHeight;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(covariant _OffenseDefenseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period.seasonId != widget.period.seasonId) {
      setState(() => _matchedHeight = null);
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    }
  }

  void _measure() {
    if (!mounted) return;
    final attackHeight = _attackKey.currentContext?.size?.height;
    final defenseHeight = _defenseKey.currentContext?.size?.height;
    if (attackHeight == null || defenseHeight == null) return;
    final maxHeight = attackHeight > defenseHeight
        ? attackHeight
        : defenseHeight;
    if (_matchedHeight != maxHeight) {
      setState(() => _matchedHeight = maxHeight);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SizedBox(
            height: _matchedHeight,
            child: _SurfaceCard(
              key: _attackKey,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: _BattleSide(
                title: AppLocalizations.of(context)!.rankedLeagueAttacks,
                battles: widget.period.attacks,
                count: widget.period.attackCount,
                maxBattles: widget.period.maxBattles,
                imageUrl: ImageAssets.sword,
                isDefense: false,
                hasDetails: widget.period.hasDetails,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: _matchedHeight,
            child: _SurfaceCard(
              key: _defenseKey,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: _BattleSide(
                title: AppLocalizations.of(context)!.rankedLeagueDefenses,
                battles: widget.period.defenses,
                count: widget.period.defenseCount,
                maxBattles: widget.period.maxBattles,
                imageUrl: ImageAssets.shieldWithArrow,
                isDefense: true,
                hasDetails: widget.period.hasDetails,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BattleSide extends StatelessWidget {
  const _BattleSide({
    required this.title,
    required this.battles,
    required this.count,
    required this.maxBattles,
    required this.imageUrl,
    required this.isDefense,
    required this.hasDetails,
  });

  final String title;
  final List<RankedLeagueBattle> battles;
  final int count;
  final int maxBattles;
  final String imageUrl;
  final bool isDefense;

  /// Whether the group's battle logs are available at all for this period
  /// (false for older periods the official API never exposed logs for).
  /// Distinct from `battles.isEmpty`, which can also just mean "hasn't
  /// fought yet this period" — that case gets placeholder slots instead.
  final bool hasDetails;

  @override
  Widget build(BuildContext context) {
    final total = battles.fold<int>(0, (sum, battle) => sum + battle.trophies);
    final average = battles.isEmpty ? null : total / battles.length;
    final sign = isDefense ? '-' : '+';
    final remaining = maxBattles > 0
        ? (maxBattles - count).clamp(0, maxBattles)
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      // Two groups with spaceBetween (not Expanded/IntrinsicHeight) so the
      // footer sticks to the bottom once the parent gives this a matched
      // height, while staying safe when the parent height is still
      // unconstrained during the first, natural-size measurement pass.
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MobileWebImage(imageUrl: imageUrl, width: 22, height: 22),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  if (battles.isNotEmpty)
                    _TrophyDeltaSuperscript(
                      value: '$sign${total.abs()}',
                      isDefense: isDefense,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _AverageRow(average: average, sign: sign, isDefense: isDefense),
              const SizedBox(height: 8),
              _BattleRowsSection(
                hasDetails: hasDetails,
                battles: battles,
                remaining: remaining ?? 0,
                isDefense: isDefense,
              ),
            ],
          ),
          Column(
            children: [
              const SizedBox(height: 14),
              const Divider(),
              _StatLine(
                label: AppLocalizations.of(context)!.rankedLeagueBattles,
                value: maxBattles > 0 ? '$count / $maxBattles' : '$count',
              ),
              _StatLine(
                label: AppLocalizations.of(context)!.rankedLeagueAverage,
                value: average?.toStringAsFixed(1) ?? '-',
                isPlaceholder: average == null,
              ),
              _StatLine(
                label: AppLocalizations.of(context)!.rankedLeagueRemaining,
                value: remaining?.toString() ?? '-',
                isPlaceholder: remaining == null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrophyDeltaSuperscript extends StatelessWidget {
  const _TrophyDeltaSuperscript({required this.value, required this.isDefense});

  final String value;
  final bool isDefense;

  @override
  Widget build(BuildContext context) {
    final color = isDefense ? StatColors.loss : StatColors.win;
    return Transform.translate(
      offset: const Offset(0, -4),
      child: Padding(
        padding: const EdgeInsets.only(left: 1),
        child: Text(
          '($value)',
          maxLines: 1,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _AverageRow extends StatelessWidget {
  const _AverageRow({
    required this.average,
    required this.sign,
    required this.isDefense,
  });

  final double? average;
  final String sign;
  final bool isDefense;

  @override
  Widget build(BuildContext context) {
    final hasAverage = average != null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Opacity(
          opacity: hasAverage ? 1 : 0.45,
          child: const _LegendAverageIcon(),
        ),
        const SizedBox(width: 4),
        Text(
          hasAverage ? '$sign${average!.abs().toStringAsFixed(1)}' : '-',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: hasAverage
                ? (isDefense ? StatColors.loss : StatColors.win)
                : Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.56),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _BattleRowsSection extends StatelessWidget {
  const _BattleRowsSection({
    required this.hasDetails,
    required this.battles,
    required this.remaining,
    required this.isDefense,
  });

  final bool hasDetails;
  final List<RankedLeagueBattle> battles;
  final int remaining;
  final bool isDefense;

  @override
  Widget build(BuildContext context) {
    if (!hasDetails) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Text(
          AppLocalizations.of(context)!.rankedLeagueBattleDetailsUnavailable,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return Column(
      children: [
        for (final battle in battles)
          _BattleLine(battle: battle, isDefense: isDefense),
        for (var i = 0; i < remaining; i++)
          _EmptyBattleLine(isDefense: isDefense),
      ],
    );
  }
}

class _LegendAverageIcon extends StatelessWidget {
  const _LegendAverageIcon();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      alignment: Alignment.topCenter,
      children: [
        MobileWebImage(
          imageUrl: ImageAssets.trophies,
          width: 16,
          height: 16,
          fit: BoxFit.cover,
        ),
        MobileWebImage(
          imageUrl: ImageAssets.builderBaseStar,
          width: 8,
          height: 8,
          fit: BoxFit.cover,
        ),
      ],
    );
  }
}

class _BattleLine extends StatelessWidget {
  const _BattleLine({required this.battle, required this.isDefense});

  final RankedLeagueBattle battle;
  final bool isDefense;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final signedTrophies = '${isDefense ? '-' : '+'}${battle.trophies.abs()}';
    final time = battle.creationTime == null
        ? null
        : '${DateFormat.E(locale).format(battle.creationTime!.toLocal())} '
              '${DateFormat.Hm(locale).format(battle.creationTime!.toLocal())}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: MobileWebImage(
              imageUrl: isDefense
                  ? ImageAssets.shieldWithArrow
                  : ImageAssets.sword,
              width: 20,
              height: 20,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            // Fixed two-line shape (stats row, then date row) instead of a
            // Wrap that only breaks once content overflows — otherwise the
            // date sits beside the stats on short (placeholder) rows but
            // below them on longer (real) rows, an inconsistent look.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _BattleStars(stars: battle.stars),
                        const SizedBox(width: 6),
                        _FixedPercentText(
                          value:
                              '${battle.destructionPercentage.toStringAsFixed(0)}%',
                          reservedValue: '100%',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 1),
                        _TrophyDeltaSuperscript(
                          value: signedTrophies,
                          isDefense: isDefense,
                        ),
                      ],
                    ),
                  ),
                ),
                if (time != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    time,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBattleLine extends StatelessWidget {
  const _EmptyBattleLine({required this.isDefense});

  final bool isDefense;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.56);
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Opacity(
              opacity: 0.4,
              child: MobileWebImage(
                imageUrl: isDefense
                    ? ImageAssets.shieldWithArrow
                    : ImageAssets.sword,
                width: 20,
                height: 20,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            // Same fixed two-line shape as _BattleLine (stats row, then date
            // row) so empty and real rows line up identically regardless of
            // how much either one's text happens to fill the width.
            child: Opacity(
              opacity: 0.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _BattleStars(stars: 0),
                          const SizedBox(width: 6),
                          _FixedPercentText(
                            value: '-%',
                            reservedValue: '100%',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(color: muted),
                          ),
                          const SizedBox(width: 1),
                          Text(
                            '(-)',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: muted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: muted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FixedPercentText extends StatelessWidget {
  const _FixedPercentText({
    required this.value,
    required this.reservedValue,
    this.style,
  });

  final String value;
  final String reservedValue;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    final effectiveStyle = DefaultTextStyle.of(context).style.merge(style);
    final painter = TextPainter(
      text: TextSpan(text: reservedValue, style: effectiveStyle),
      textDirection: direction,
      maxLines: 1,
    )..layout();

    return SizedBox(
      width: painter.width,
      child: Text(value, maxLines: 1, textAlign: TextAlign.right, style: style),
    );
  }
}

class _BattleStars extends StatelessWidget {
  const _BattleStars({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (index) => Opacity(
          opacity: index < stars ? 1 : 0.28,
          child: const MobileWebImage(
            imageUrl: ImageAssets.builderBaseStar,
            width: 14,
            height: 14,
          ),
        ),
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({
    required this.label,
    required this.value,
    this.isPlaceholder = false,
  });

  final String label;
  final String value;

  /// Dims the value to match the placeholder battle rows above, instead of
  /// rendering a "-" with full-strength text as if it were real data.
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    final muted = isPlaceholder
        ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.56)
        : null;
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: muted),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w800, color: muted),
          ),
        ],
      ),
    );
  }
}

class _UnavailableDataCard extends StatelessWidget {
  const _UnavailableDataCard({
    required this.title,
    required this.body,
    this.icon,
    this.imageUrl,
  });

  final IconData? icon;
  final String? imageUrl;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (imageUrl?.isNotEmpty == true)
                MobileWebImage(imageUrl: imageUrl!, width: 20, height: 20)
              else
                Icon(icon ?? Icons.info_outline_rounded, size: 18),
              const SizedBox(width: 8),
              Text(title, style: CKTypography.of(context, CKTextRole.rowTitle)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _HistoryChart extends StatelessWidget {
  const _HistoryChart({required this.periods, required this.title});

  final List<_PeriodViewModel> periods;
  final String title;

  @override
  Widget build(BuildContext context) {
    final ordered = [...periods]
      ..sort((a, b) => a.seasonId.compareTo(b.seasonId));
    final values = ordered.map((period) => period.trophies).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minY = ((minValue / 100).floor() * 100 - 100)
        .clamp(0, 100000)
        .toDouble();
    final maxY = ((maxValue / 100).ceil() * 100 + 100).toDouble();
    final locale = Localizations.localeOf(context).toString();
    final spots = ordered.indexed
        .map(
          (entry) => FlSpot(entry.$1.toDouble(), entry.$2.trophies.toDouble()),
        )
        .toList();
    // Cap the number of bottom-axis labels so dates stay legible instead of
    // overlapping once a player has accumulated many historical periods.
    final labelInterval = spots.length <= 6
        ? 1.0
        : (spots.length / 6).ceil().toDouble();
    return _ChartShell(
      title: title,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (spots.length - 1).clamp(1, spots.length).toDouble(),
          minY: minY,
          maxY: maxY,
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          titlesData: _chartTitles(
            context,
            spots.length,
            labelInterval,
            (index) =>
                DateFormat.Md(locale).format(ordered[index].startsAt.toLocal()),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index < 0 || index >= ordered.length) return null;
                final period = ordered[index];
                final dateLabel = DateFormat.yMMMd(
                  locale,
                ).format(period.startsAt.toLocal());
                return LineTooltipItem(
                  '${NumberFormat.decimalPattern(locale).format(period.trophies)}\n$dateLabel',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [_lineData(context, spots)],
        ),
      ),
    );
  }
}

FlTitlesData _chartTitles(
  BuildContext context,
  int count,
  double interval,
  String Function(int) label,
) {
  return FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 44,
        getTitlesWidget: (value, meta) => Text(
          NumberFormat.compact().format(value),
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 34,
        interval: interval,
        getTitlesWidget: (value, meta) {
          final index = value.toInt();
          if (index < 0 || index >= count) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(
              label(index),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          );
        },
      ),
    ),
  );
}

LineChartBarData _lineData(BuildContext context, List<FlSpot> spots) {
  return LineChartBarData(
    spots: spots,
    isCurved: false,
    barWidth: 2,
    color: Theme.of(context).colorScheme.primary,
    dotData: const FlDotData(show: true),
    belowBarData: BarAreaData(
      show: true,
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
    ),
  );
}

class _EndOfPeriodList extends StatelessWidget {
  const _EndOfPeriodList({required this.periods});

  final List<_PeriodViewModel> periods;

  @override
  Widget build(BuildContext context) {
    if (periods.isEmpty) {
      return _UnavailableDataCard(
        icon: Icons.workspace_premium_outlined,
        title: AppLocalizations.of(context)!.generalNoDataAvailable,
        body: AppLocalizations.of(context)!.rankedLeagueHistorySubtitle,
      );
    }
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (final period in periods)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ?? colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.chip),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(
                    alpha: AppOpacity.borderStrong,
                  ),
                ),
              ),
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: 44,
                    child: period.tier?.largeIconUrl.isNotEmpty == true
                        ? MobileWebImage(imageUrl: period.tier!.largeIconUrl)
                        : const Icon(Icons.military_tech_rounded),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _EndPeriodDetails(period: period)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _EndPeriodDetails extends StatelessWidget {
  const _EndPeriodDetails({required this.period});

  final _PeriodViewModel period;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          period.tier?.name ??
              DateFormat.yMMMMd(locale).format(period.startsAt.toLocal()),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (period.tier != null) ...[
          const SizedBox(height: 1),
          Text(
            DateFormat.yMMMMd(locale).format(period.startsAt.toLocal()),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _DataChip(
              imageUrl: ImageAssets.trophies,
              value: '${period.trophies}',
            ),
            _DataChip(
              icon: Icons.leaderboard_rounded,
              value: period.placement > 0 ? '#${period.placement}' : '-',
            ),
            _DataChip(
              imageUrl: ImageAssets.sword,
              value: '${period.attackCount} (${period.attackStars}★)',
            ),
            _DataChip(
              imageUrl: ImageAssets.shieldWithArrow,
              value: '${period.defenseCount} (${period.defenseStars}★)',
            ),
          ],
        ),
      ],
    );
  }
}

class _DataChip extends StatelessWidget {
  const _DataChip({this.imageUrl, this.icon, required this.value});

  final String? imageUrl;
  final IconData? icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    // Faithful copy of clan_members.dart's _MemberMiniStat — the trailing
    // chip clan rows use inside a flat card, as opposed to _RankedQuickChip
    // which is a different recipe meant to float over a hero image.
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageUrl?.isNotEmpty == true)
            MobileWebImage(imageUrl: imageUrl!, width: 18, height: 18)
          else
            Icon(icon ?? Icons.info_outline_rounded, size: 18),
          const SizedBox(width: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupRanking extends StatefulWidget {
  const _GroupRanking({required this.group, required this.playerTag});

  final RankedLeagueGroup? group;
  final String playerTag;

  @override
  State<_GroupRanking> createState() => _GroupRankingState();
}

class _GroupRankingState extends State<_GroupRanking> {
  final _highlightedKey = GlobalKey();

  void _scrollToPlayer() {
    final targetContext = _highlightedKey.currentContext;
    if (targetContext == null) return;
    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: 0.5,
    );
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    if (group == null || group.members.isEmpty) {
      return _UnavailableDataCard(
        icon: Icons.leaderboard_rounded,
        title: AppLocalizations.of(context)!.rankedLeagueGroupRanking,
        body: AppLocalizations.of(context)!.rankedLeagueNoGroup,
      );
    }

    final hasPlayer = group.members.any(
      (member) => member.playerTag == widget.playerTag,
    );

    return Column(
      children: [
        if (hasPlayer) ...[
          Align(
            alignment: Alignment.centerRight,
            child: _JumpToPlayerButton(onTap: _scrollToPlayer),
          ),
          const SizedBox(height: 8),
        ],
        for (final entry in group.members.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _RankingRow(
              key: entry.$2.playerTag == widget.playerTag
                  ? _highlightedKey
                  : null,
              rank: entry.$1 + 1,
              member: entry.$2,
              highlighted: entry.$2.playerTag == widget.playerTag,
            ),
          ),
      ],
    );
  }
}

class _JumpToPlayerButton extends StatelessWidget {
  const _JumpToPlayerButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        splashFactory: NoSplash.splashFactory,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.32),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.my_location_rounded,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context)!.rankedLeagueJumpToMyRank,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary,
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

class _RankingRow extends StatelessWidget {
  const _RankingRow({
    super.key,
    required this.rank,
    required this.member,
    required this.highlighted,
  });

  final int rank;
  final RankedLeagueMember member;
  final bool highlighted;

  static const _medalColors = {
    1: Color(0xFFFFD54F),
    2: Color(0xFFC7C9CC),
    3: Color(0xFFCE8946),
  };

  Future<void> _openProfile(BuildContext context) async {
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      useRootNavigator: false,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final selectedPlayer = await context
          .read<PlayerService>()
          .getPlayerAndClanData(member.playerTag);
      navigator.pop();
      navigator.push(
        MaterialPageRoute(
          builder: (context) => PlayerScreen(selectedPlayer: selectedPlayer),
        ),
      );
    } catch (e) {
      navigator.pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.generalRefreshFailed(e.toString()),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final medalColor = _medalColors[rank];
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.chip),
        splashFactory: NoSplash.splashFactory,
        onTap: () => _openProfile(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: highlighted
                ? Colors.green.withValues(alpha: 0.14)
                : Theme.of(context).cardTheme.color ?? colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(
              color: highlighted
                  ? Colors.green.withValues(alpha: 0.7)
                  : colorScheme.outlineVariant.withValues(
                      alpha: AppOpacity.border,
                    ),
              width: highlighted ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: medalColor != null
                    ? Icon(
                        Icons.emoji_events_rounded,
                        color: medalColor,
                        size: 22,
                      )
                    : Text(
                        '#$rank',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: highlighted
                                  ? Colors.green
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      member.playerName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      member.clanName.isNotEmpty
                          ? member.clanName
                          : member.playerTag,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MobileWebImage(
                    imageUrl: ImageAssets.trophies,
                    width: 18,
                    height: 18,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    NumberFormat(
                      '#,###',
                      Localizations.localeOf(context).toString(),
                    ).format(member.leagueTrophies),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartShell extends StatelessWidget {
  const _ChartShell({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: SizedBox(
        height: 390,
        child: Column(
          children: [
            Text(
              title,
              style: CKTypography.of(context, CKTextRole.sectionTitle),
            ),
            const SizedBox(height: 16),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(
            alpha: AppOpacity.borderStrong,
          ),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}
