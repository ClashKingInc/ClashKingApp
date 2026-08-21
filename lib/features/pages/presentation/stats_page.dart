import 'dart:math' as math;

import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/empty_state.dart';
import 'package:clashkingapp/common/widgets/header_widgets.dart';
import 'package:clashkingapp/common/widgets/info_profile_tabs.dart';
import 'package:clashkingapp/common/widgets/liquid_glass.dart';
import 'package:clashkingapp/common/widgets/loading/skeleton_loading.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/search_sort_bar.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:clashkingapp/features/stats/models/stats_models.dart';
import 'package:clashkingapp/features/stats/presentation/stats_provider.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/l10n/game_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'side_page_components.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key, this.provider});

  final StatsProvider? provider;

  @override
  Widget build(BuildContext context) {
    final injected = provider;
    if (injected == null) return const _StatsPageContent();
    return ChangeNotifierProvider.value(
      value: injected,
      child: const _StatsPageContent(),
    );
  }
}

class _StatsPageContent extends StatefulWidget {
  const _StatsPageContent();

  @override
  State<_StatsPageContent> createState() => _StatsPageContentState();
}

class _StatsPageContentState extends State<_StatsPageContent> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<StatsProvider>().ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StatsProvider>();
    final sections = _sectionsFor(provider.audience);
    final selectedIndex = sections
        .indexOf(provider.section)
        .clamp(0, sections.length - 1);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: InfoProfileTabScaffold(
        header: _StatsHeader(provider: provider),
        selectedIndex: selectedIndex,
        alwaysScrollable:
            provider.audience == StatsAudience.battle &&
            MediaQuery.sizeOf(context).width < 600,
        onTabSelected: (index) => provider.selectSection(sections[index]),
        tabs: [
          for (final section in sections)
            InfoProfileTabData(
              label: _sectionLabel(AppLocalizations.of(context)!, section),
              imageUrl: _sectionImage(section),
            ),
        ],
        body: AnimatedSwitcher(
          duration: CKMotion.durationOf(context, CKMotion.fast),
          switchInCurve: CKMotion.standardCurve,
          switchOutCurve: CKMotion.standardCurve,
          child: KeyedSubtree(
            key: ValueKey(provider.section),
            child: switch (provider.section) {
              StatsSection.overview => const _OverviewSection(),
              StatsSection.players => const _PlayersSection(),
              StatsSection.clans => const _ClansSection(),
              StatsSection.armies => const _ArmiesSection(),
              StatsSection.items => const _ItemsSection(),
              StatsSection.war => const _WarSection(),
              StatsSection.cwl => const _CwlSection(),
              StatsSection.ranked => const _RankedSection(),
            },
          ),
        ),
      ),
    );
  }
}

const _battleSections = [
  StatsSection.ranked,
  StatsSection.armies,
  StatsSection.items,
  StatsSection.war,
  StatsSection.cwl,
];

const _worldSections = [
  StatsSection.overview,
  StatsSection.players,
  StatsSection.clans,
];

List<StatsSection> _sectionsFor(StatsAudience audience) =>
    audience == StatsAudience.battle ? _battleSections : _worldSections;

String _sectionLabel(AppLocalizations loc, StatsSection section) =>
    switch (section) {
      StatsSection.overview => loc.statsOverview,
      StatsSection.players => loc.statsPlayers,
      StatsSection.clans => loc.statsClans,
      StatsSection.armies => loc.statsArmies,
      StatsSection.items => loc.statsItems,
      StatsSection.war => loc.statsWar,
      StatsSection.cwl => loc.statsCwl,
      StatsSection.ranked => loc.statsMeta,
    };

String _sectionImage(StatsSection section) => switch (section) {
  StatsSection.ranked => ImageAssets.hitrate,
  StatsSection.armies => ImageAssets.getTroopImage('Super Bowler'),
  StatsSection.items => ImageAssets.getGearImage('Eternal Tome'),
  StatsSection.war => ImageAssets.war,
  StatsSection.cwl => ImageAssets.getWarLeagueImage('Champion League I'),
  StatsSection.overview => ImageAssets.darkModeLogo,
  StatsSection.players => ImageAssets.townHall(18),
  StatsSection.clans => ImageAssets.clanCastle,
};

String _sectionBackground(StatsSection section) => switch (section) {
  StatsSection.overview => ImageAssets.homeBaseBackground,
  StatsSection.players ||
  StatsSection.ranked => ImageAssets.legendPageBackground,
  StatsSection.clans => ImageAssets.clanPageBackground,
  StatsSection.armies => ImageAssets.playerWarStatsPageBackground,
  StatsSection.items => ImageAssets.playerAchievementPageBackground,
  StatsSection.war => ImageAssets.warPageBackground,
  StatsSection.cwl => ImageAssets.cwlPageBackground,
};

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({required this.provider});

  final StatsProvider provider;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final scaledBody = MediaQuery.textScalerOf(context).scale(14);
    final textScaleAllowance = math.max(0, scaledBody - 14) * 5;
    final height = MediaQuery.paddingOf(context).top + 246 + textScaleAllowance;
    return Stack(
      children: [
        Positioned.fill(
          child: InfoHeroBackdrop(
            imageUrl: _sectionBackground(provider.section),
            height: height,
          ),
        ),
        SizedBox(
          height: height,
          child: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          HeaderIconButton(
                            icon: Icons.arrow_back_rounded,
                            iconColor: Colors.white,
                            tooltip: MaterialLocalizations.of(
                              context,
                            ).backButtonTooltip,
                            onTap: () => Navigator.of(context).pop(),
                            showBackground: false,
                          ),
                          const Spacer(),
                          HeaderIconButton(
                            icon: Icons.refresh_rounded,
                            iconColor: Colors.white,
                            tooltip: loc.sideRefresh,
                            onTap: provider.refresh,
                            showBackground: false,
                          ),
                        ],
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            MobileWebImage(
                              imageUrl: _sectionImage(provider.section),
                              width: 60,
                              height: 60,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              loc.sideStatsTitle,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _sectionLabel(loc, provider.section),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: AppGlassSegmentedControl<StatsAudience>(
                          height: 44,
                          values: StatsAudience.values,
                          labels: [loc.statsBattle, loc.statsWorld],
                          selected: provider.audience,
                          foregroundColor: Colors.white,
                          onChanged: provider.selectAudience,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BattleContextBar extends StatelessWidget {
  const _BattleContextBar({
    required this.provider,
    required this.filterSummary,
    required this.onFilters,
  });

  final StatsProvider provider;
  final String filterSummary;
  final VoidCallback onFilters;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final dateSummary = _statsDateSummary(context, provider.dates);
    return Row(
      children: [
        Expanded(
          child: Semantics(
            label: '$dateSummary, $filterSummary',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dateSummary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  filterSummary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        _ContextIconButton(
          icon: Icons.tune_rounded,
          tooltip: loc.generalFilters,
          onTap: onFilters,
        ),
      ],
    );
  }
}

class _ContextIconButton extends StatelessWidget {
  const _ContextIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: 44,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.chip),
            onTap: onTap,
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: AppOpacity.fillMuted,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(
                      alpha: AppOpacity.borderStrong,
                    ),
                  ),
                ),
                child: Icon(icon, size: 18, color: colorScheme.onSurface),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _statsDateSummary(BuildContext context, StatsDateFilter dates) {
  final formatter = DateFormat.MMMd(Localizations.localeOf(context).toString());
  return '${formatter.format(dates.start)} - ${formatter.format(dates.end)} · '
      '${AppLocalizations.of(context)!.statsIndexDays(dates.inclusiveDays)}';
}

StatsDateFilter _defaultStatsDates() {
  final now = DateTime.now();
  final end = DateTime(now.year, now.month, now.day);
  return StatsDateFilter(
    start: end.subtract(const Duration(days: 29)),
    end: end,
  );
}

Future<DateTimeRange?> _pickStatsDateRange(
  BuildContext context,
  StatsDateFilter dates,
) async {
  final today = DateTime.now();
  final result = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2024),
    lastDate: DateTime(today.year, today.month, today.day),
    initialDateRange: DateTimeRange(start: dates.start, end: dates.end),
    helpText: AppLocalizations.of(context)!.statsDateRangeHint,
  );
  if (result == null || !context.mounted) return null;
  if (StatsDateFilter(start: result.start, end: result.end).inclusiveDays >
      90) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.statsDateRangeTooLong),
      ),
    );
    return null;
  }
  return result;
}

class _StatsPageGutter extends StatelessWidget {
  const _StatsPageGutter({required this.child, required this.padding});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        key: const ValueKey('stats-content-bound'),
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _SectionFrame extends StatelessWidget {
  const _SectionFrame({
    required this.section,
    required this.builder,
    this.emptyTitle,
    this.emptyBody,
    this.prefix,
  });

  final StatsSection section;
  final Widget Function(Object data) builder;
  final String? emptyTitle;
  final String? emptyBody;
  final Widget? prefix;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StatsProvider>();
    final state = provider.stateFor(section);
    final loc = AppLocalizations.of(context)!;

    if (state.status == StatsLoadStatus.loading && state.data == null) {
      return ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 28),
        children: [
          _StatsPageGutter(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                if (prefix != null) ...[prefix!, const SizedBox(height: 12)],
                _StatsSectionSkeleton(section: section),
              ],
            ),
          ),
        ],
      );
    }
    if (state.status == StatsLoadStatus.error && state.data == null) {
      return ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 28),
        children: [
          _StatsPageGutter(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                if (prefix != null) ...[prefix!, const SizedBox(height: 12)],
                AppEmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: loc.sideStatsLoadError,
                  body: ApiService.getErrorMessage(state.error),
                  actionLabel: loc.generalRetry,
                  onAction: provider.refresh,
                  padding: EdgeInsets.zero,
                  showSticker: false,
                ),
              ],
            ),
          ),
        ],
      );
    }
    if (state.status == StatsLoadStatus.empty) {
      return ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 28),
        children: [
          _StatsPageGutter(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                if (prefix != null) ...[prefix!, const SizedBox(height: 12)],
                AppEmptyState(
                  icon: Icons.query_stats_rounded,
                  title: emptyTitle ?? loc.statsNoDataTitle,
                  body: emptyBody ?? loc.statsNoDataBody,
                ),
              ],
            ),
          ),
        ],
      );
    }

    final data = state.data;
    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 28),
        children: [
          _StatsPageGutter(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                if (prefix != null) ...[prefix!, const SizedBox(height: 12)],
                if (state.isRefreshing)
                  const LinearProgressIndicator(minHeight: 2),
                if (state.error != null && data != null) ...[
                  _InlineNotice(
                    icon: Icons.cloud_off_rounded,
                    text: ApiService.getErrorMessage(state.error),
                    error: true,
                  ),
                  const SizedBox(height: 10),
                ],
                if (data != null) builder(data),
                if (state.updatedAt != null) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _FreshDataChip(label: loc.statsUpdated),
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

class _StatsSectionSkeleton extends StatelessWidget {
  const _StatsSectionSkeleton({required this.section});

  final StatsSection section;

  @override
  Widget build(BuildContext context) {
    final panels = switch (section) {
      StatsSection.overview => const [
        _StatsMetricGridSkeleton(),
        SizedBox(height: 12),
        _StatsChartSkeleton(height: 112),
      ],
      StatsSection.players || StatsSection.clans => const [
        _StatsChartSkeleton(),
        _StatsChartSkeleton(),
        _StatsChartSkeleton(),
      ],
      StatsSection.armies => const [
        _StatsChartSkeleton(height: 250),
        _StatsResultSkeleton(),
        _StatsResultSkeleton(),
      ],
      StatsSection.items => const [
        _StatsResultSkeleton(),
        _StatsResultSkeleton(),
      ],
      StatsSection.ranked || StatsSection.war || StatsSection.cwl => const [
        _StatsMetricsSkeleton(),
        _StatsChartSkeleton(height: 176),
      ],
    };

    return Semantics(
      label: AppLocalizations.of(context)!.generalLoading,
      excludeSemantics: true,
      child: Column(
        key: const ValueKey('stats-loading-skeleton'),
        children: panels,
      ),
    );
  }
}

class _StatsMetricGridSkeleton extends StatelessWidget {
  const _StatsMetricGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 650 ? 4 : 2;
        final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(
            8,
            (_) => SizedBox(
              width: width,
              child: const _StatsSkeletonSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(width: 84, height: 10),
                    SizedBox(height: 10),
                    SkeletonLoader(width: 64, height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatsChartSkeleton extends StatelessWidget {
  const _StatsChartSkeleton({this.height = 224});

  final double height;

  @override
  Widget build(BuildContext context) {
    return _StatsSkeletonSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader(width: 172, height: 18),
          const SizedBox(height: 8),
          const SkeletonLoader(width: 230, height: 11),
          const SizedBox(height: 18),
          SkeletonLoader(width: double.infinity, height: height - 71),
        ],
      ),
    );
  }
}

class _StatsMetricsSkeleton extends StatelessWidget {
  const _StatsMetricsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const _StatsSkeletonSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(width: 156, height: 18),
          SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SkeletonLoader(width: 116, height: 44),
              SkeletonLoader(width: 132, height: 44),
              SkeletonLoader(width: 124, height: 44),
            ],
          ),
          SizedBox(height: 14),
          SkeletonLoader(width: double.infinity, height: 64),
        ],
      ),
    );
  }
}

class _StatsResultSkeleton extends StatelessWidget {
  const _StatsResultSkeleton();

  @override
  Widget build(BuildContext context) {
    return const _StatsSkeletonSurface(
      child: Row(
        children: [
          SkeletonLoader(width: 48, height: 48),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(width: 180, height: 15),
                SizedBox(height: 9),
                SkeletonLoader(width: 126, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSkeletonSurface extends StatelessWidget {
  const _StatsSkeletonSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CKSectionPanel(child: child),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection();

  @override
  Widget build(BuildContext context) {
    return _SectionFrame(
      section: StatsSection.overview,
      builder: (data) {
        final overview = data as StatsOverviewResponse;
        final loc = AppLocalizations.of(context)!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SidePageSectionHeader(title: loc.statsGlobalCounts),
            _CountsGrid(counts: overview.counts),
            const SizedBox(height: 12),
            _UnavailableDataPanel(
              title: loc.statsWarsOverTime,
              body: loc.generalComingSoon,
            ),
          ],
        );
      },
    );
  }
}

class _CountsGrid extends StatelessWidget {
  const _CountsGrid({required this.counts});

  final StatsGlobalCounts counts;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final values = <(String, int)>[
      (loc.statsPlayers, counts.playerCount),
      (loc.statsClans, counts.clanCount),
      (loc.statsPlayersInWar, counts.playersInWar),
      (loc.statsClansInWar, counts.clansInWar),
      (loc.statsPlayersInLegends, counts.playersInLegends),
      (loc.statsWarsStored, counts.warsStored),
      (loc.statsJoinLeaves, counts.totalJoinLeaves),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 650 ? 4 : 2;
        final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: values
              .map(
                (entry) => SizedBox(
                  width: width,
                  child: SidePageMetricPanel(
                    label: entry.$1,
                    value: _compact(entry.$2),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _PlayersSection extends StatelessWidget {
  const _PlayersSection();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return _SectionFrame(
      section: StatsSection.players,
      builder: (data) {
        final counts = data as StatsPlayerCountsResponse;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DistributionCard(
              title: loc.statsTownHallDistribution,
              subtitle: loc.statsTrackedPlayers,
              values: counts.townHalls,
              labelBuilder: (id) => 'TH${id ?? '?'}',
              color: StatColors.capitalProjected,
            ),
            const SizedBox(height: 12),
            _DistributionCard(
              title: loc.statsLeagueDistribution,
              subtitle: loc.statsTrackedPlayers,
              values: counts.leagueTiers,
              labelBuilder: _leagueTierLabel,
              color: StatColors.capitalTrophy,
            ),
            const SizedBox(height: 12),
            _DistributionCard(
              title: loc.statsBuilderHallDistribution,
              subtitle: loc.statsTrackedPlayers,
              values: counts.builderHalls,
              labelBuilder: (id) => 'BH${id ?? '?'}',
              color: StatColors.capitalAttack,
            ),
            const SizedBox(height: 12),
            _UnavailableDataPanel(
              title: loc.statsEquipmentAdoption,
              body: loc.generalComingSoon,
            ),
            const SizedBox(height: 12),
            _UnavailableDataPanel(
              title: loc.statsExperienceDistribution,
              body: loc.generalComingSoon,
            ),
          ],
        );
      },
    );
  }
}

class _ClansSection extends StatelessWidget {
  const _ClansSection();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cwlLeagues = _localizedCwlLeagues(context);
    return _SectionFrame(
      section: StatsSection.clans,
      builder: (data) {
        final counts = data as StatsClanCountsResponse;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DistributionCard(
              title: loc.statsCwlLeagueDistribution,
              subtitle: loc.statsTrackedClans,
              values: counts.cwlLeagues,
              labelBuilder: (id) => cwlLeagues[id] ?? '${id ?? '?'}',
              color: StatColors.loss,
            ),
            const SizedBox(height: 12),
            _DistributionCard(
              title: loc.statsCapitalLeagueDistribution,
              subtitle: loc.statsTrackedClans,
              values: counts.capitalLeagues,
              labelBuilder: (id) => loc.statsLeagueId(id ?? 0),
              color: StatColors.capitalDistrict,
            ),
            const SizedBox(height: 12),
            _CountsSummaryCard(
              title: loc.statsTrackedLocations,
              value: counts.locations.where((item) => item.id != null).length,
              subtitle: loc.statsLocationCountHelp,
            ),
            const SizedBox(height: 12),
            _UnavailableDataPanel(
              title: loc.statsCwlRosterSizes,
              body: loc.generalComingSoon,
            ),
          ],
        );
      },
    );
  }
}

class _DistributionCard extends StatelessWidget {
  const _DistributionCard({
    required this.title,
    required this.subtitle,
    required this.values,
    required this.labelBuilder,
    required this.color,
  });

  final String title;
  final String subtitle;
  final List<StatsGroupedCount> values;
  final String Function(int? id) labelBuilder;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final sorted = [...values]
      ..sort((left, right) => (left.id ?? -1).compareTo(right.id ?? -1));
    final visible = sorted.length > 18
        ? sorted.sublist(sorted.length - 18)
        : sorted;
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 190,
            child: _CountBarChart(
              values: visible,
              labels: visible.map((item) => labelBuilder(item.id)).toList(),
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBarChart extends StatelessWidget {
  const _CountBarChart({
    required this.values,
    required this.labels,
    required this.color,
  });

  final List<StatsGroupedCount> values;
  final List<String> labels;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxCount = values.fold<int>(
      1,
      (current, item) => math.max(current, item.count),
    );
    final semanticSummary = [
      for (var index = 0; index < values.length; index++)
        '${labels[index]}: ${values[index].count}',
    ].join(', ');
    return Semantics(
      label: semanticSummary,
      excludeSemantics: true,
      child: BarChart(
        BarChartData(
          maxY: maxCount * 1.12,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: scheme.outlineVariant.withValues(alpha: 0.28),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => scheme.inverseSurface,
              getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                  BarTooltipItem(
                    '${labels[groupIndex]}\n${_compact(rod.toY.toInt())}',
                    TextStyle(
                      color: scheme.onInverseSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                getTitlesWidget: (value, meta) => Text(
                  _compact(value.toInt()),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  final step = labels.length > 9 ? 2 : 1;
                  if (index % step != 0 && index != labels.length - 1) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Text(
                      labels[index],
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var index = 0; index < values.length; index++)
              BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: values[index].count.toDouble(),
                    width: values.length > 12 ? 8 : 14,
                    color: color,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(5),
                    ),
                  ),
                ],
              ),
          ],
        ),
        duration: CKMotion.durationOf(context, CKMotion.slow),
        curve: CKMotion.standardCurve,
      ),
    );
  }
}

class _UnavailableDataPanel extends StatelessWidget {
  const _UnavailableDataPanel({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.insights_rounded,
      title: title,
      body: body,
      padding: EdgeInsets.zero,
      showSticker: false,
    );
  }
}

class _CountsSummaryCard extends StatelessWidget {
  const _CountsSummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final int value;
  final String subtitle;

  @override
  Widget build(BuildContext context) => _SurfaceCard(
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Text(
          NumberFormat.decimalPattern().format(value),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

class _PreviewBadge extends StatelessWidget {
  const _PreviewBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onTertiaryContainer,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _ArmiesSection extends StatefulWidget {
  const _ArmiesSection();

  @override
  State<_ArmiesSection> createState() => _ArmiesSectionState();
}

class _ArmiesSectionState extends State<_ArmiesSection> {
  final searchController = TextEditingController();
  String query = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final provider = context.watch<StatsProvider>();
    return Column(
      children: [
        _StatsPageGutter(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Column(
            children: [
              _BattleContextBar(
                provider: provider,
                filterSummary:
                    '${_townHallSummary(loc, provider.armiesTownHall)} · '
                    '${loc.statsMinimumSample} ${provider.armiesMinimumSample}',
                onFilters: () => showDialog<void>(
                  context: context,
                  builder: (_) => ChangeNotifierProvider.value(
                    value: context.read<StatsProvider>(),
                    child: const _ArmyFiltersDialog(),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _SearchAndFilter(
                controller: searchController,
                query: query,
                hint: loc.statsSearchArmies,
                onChanged: (value) => setState(() => query = value),
              ),
            ],
          ),
        ),
        Expanded(
          child: _SectionFrame(
            section: StatsSection.armies,
            builder: (data) {
              final response = data as StatsArmiesResponse;
              final filtered = response.items.where((army) {
                if (query.trim().isEmpty) return true;
                final needle = query.toLowerCase();
                return army.armyShareCode.toLowerCase().contains(needle) ||
                    army.armyCounts.keys.any(
                      (item) => item.toLowerCase().contains(needle),
                    );
              }).toList();
              if (filtered.isEmpty) {
                return AppEmptyState(
                  icon: Icons.search_off_rounded,
                  title: loc.statsNoDataTitle,
                  body: loc.generalNoFilteredResults,
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _ArmyStrategyPanel(),
                  const SizedBox(height: 12),
                  _ArmyMetaChart(armies: filtered),
                  const SizedBox(height: 12),
                  SidePageSectionHeader(title: loc.statsExactLoadouts),
                  ...filtered.map((army) => _ArmyCard(army: army)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ArmyStrategyPanel extends StatelessWidget {
  const _ArmyStrategyPanel();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final examples = [
      (
        loc.statsQueenCharge,
        loc.statsQueenChargeRule,
        ImageAssets.getHeroImage('Archer Queen'),
      ),
      (
        loc.statsSuperBowlerCore,
        loc.statsSuperBowlerRule,
        ImageAssets.getTroopImage('Super Bowler'),
      ),
      (
        loc.statsRootRiderCore,
        loc.statsRootRiderRule,
        ImageAssets.getTroopImage('Root Rider'),
      ),
    ];
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  loc.statsStrategyLenses,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _PreviewBadge(label: loc.statsPreview),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            loc.statsStrategyLensesBody,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          for (final example in examples)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                children: [
                  MobileWebImage(imageUrl: example.$3, width: 36, height: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          example.$1,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          example.$2,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          _InlineNotice(
            icon: Icons.hub_outlined,
            text: loc.statsPatternDiscoveryBody,
          ),
        ],
      ),
    );
  }
}

class _ArmyMetaChart extends StatelessWidget {
  const _ArmyMetaChart({required this.armies});

  final List<StatsArmyResult> armies;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final visible = armies.take(30).toList(growable: false);
    final semanticSummary = visible
        .take(5)
        .map((army) {
          final core = army.armyCounts.entries
              .take(2)
              .map((entry) => '${entry.value}× ${entry.key}')
              .join(', ');
          return '$core, ${loc.statsUsage}: '
              '${_percent(army.metrics.usageRate ?? 0)}, '
              '${loc.statsThreeStarRate}: '
              '${_percent(army.metrics.threeStarRate)}';
        })
        .join('; ');
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.statsUsageVsThreeStar,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(
            loc.statsTapPointForLoadout,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          Semantics(
            label: '${loc.statsUsageVsThreeStar}. $semanticSummary',
            excludeSemantics: true,
            child: SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: math.max(
                    1,
                    visible
                            .map(
                              (army) =>
                                  _asPercentValue(army.metrics.usageRate ?? 0),
                            )
                            .fold<double>(0, math.max) *
                        1.12,
                  ),
                  minY: 0,
                  maxY: 100,
                  gridData: FlGridData(
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: scheme.outlineVariant.withValues(alpha: 0.28),
                    ),
                    getDrawingVerticalLine: (_) => FlLine(
                      color: scheme.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: Text(loc.statsThreeStarRate),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}%',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: Text(loc.statsUsage),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => scheme.inverseSurface,
                      getTooltipItems: (spots) => spots.map((spot) {
                        final army = visible[spot.barIndex];
                        final core = army.armyCounts.entries
                            .take(2)
                            .map((entry) => '${entry.value}× ${entry.key}')
                            .join(' · ');
                        return LineTooltipItem(
                          '$core\n${_percent(spot.x)} ${loc.statsUsage} · '
                          '${_percent(spot.y)} ${loc.statsThreeStarRate}',
                          TextStyle(
                            color: scheme.onInverseSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  lineBarsData: [
                    for (final army in visible)
                      LineChartBarData(
                        spots: [
                          FlSpot(
                            _asPercentValue(army.metrics.usageRate ?? 0),
                            _asPercentValue(army.metrics.threeStarRate),
                          ),
                        ],
                        color: Colors.transparent,
                        barWidth: 0,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) =>
                              FlDotCirclePainter(
                                radius: 5,
                                color: scheme.primary,
                                strokeWidth: 2,
                                strokeColor: scheme.surface,
                              ),
                        ),
                      ),
                  ],
                ),
                duration: CKMotion.durationOf(context, CKMotion.slow),
                curve: CKMotion.standardCurve,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArmyCard extends StatelessWidget {
  const _ArmyCard({required this.army});

  final StatsArmyResult army;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final composition = army.armyCounts.entries
        .map((entry) => '${entry.value}× ${entry.key}')
        .join('  ·  ');
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (army.armyCounts.isNotEmpty) ...[
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: math.min(army.armyCounts.length, 8),
                separatorBuilder: (_, _) => const SizedBox(width: 5),
                itemBuilder: (context, index) {
                  final entry = army.armyCounts.entries.elementAt(index);
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      MobileWebImage(
                        imageUrl: ImageAssets.getTroopImage(entry.key),
                        width: 40,
                        height: 40,
                      ),
                      Positioned(
                        right: -2,
                        bottom: -1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.inverseSurface,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            '${entry.value}',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onInverseSurface,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 9),
          ],
          Text(
            loc.statsExactComposition,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          Text(composition.isEmpty ? army.armyItems.join(' · ') : composition),
          if (army.armyShareCode.isNotEmpty) ...[
            const SizedBox(height: 5),
            SelectableText(
              '${loc.statsArmyShareCode}: ${army.armyShareCode}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
          const SizedBox(height: 12),
          _MetricsContent(metrics: army.metrics),
        ],
      ),
    );
  }
}

class _ArmyFiltersDialog extends StatefulWidget {
  const _ArmyFiltersDialog();

  @override
  State<_ArmyFiltersDialog> createState() => _ArmyFiltersDialogState();
}

class _ArmyFiltersDialogState extends State<_ArmyFiltersDialog> {
  late int? townHall;
  late int? leagueTier;
  late int minimumSample;
  late String sortBy;
  late StatsDateFilter dates;
  late List<StatsItemQuantityFilter> include;
  late final TextEditingController excludeController;
  late final TextEditingController minimumSampleController;
  final itemController = TextEditingController();
  final minController = TextEditingController();
  final maxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<StatsProvider>();
    townHall = provider.armiesTownHall;
    leagueTier = provider.armiesLeagueTier;
    minimumSample = provider.armiesMinimumSample;
    sortBy = provider.armiesSortBy;
    dates = provider.dates;
    include = [...provider.armiesInclude];
    excludeController = TextEditingController(
      text: provider.armiesExclude.join(', '),
    );
    minimumSampleController = TextEditingController(text: '$minimumSample');
  }

  @override
  void dispose() {
    itemController.dispose();
    minController.dispose();
    maxController.dispose();
    excludeController.dispose();
    minimumSampleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final sortLabels = <String, String>{
      'usage_rate': loc.statsUsage,
      'three_star_rate': loc.statsThreeStarRate,
      'average_stars': loc.statsAverageStars,
      'average_destruction': loc.statsAverageDestruction,
    };
    return _StatsFilterDialog(
      dates: dates,
      onDatesChanged: (value) => setState(() => dates = value),
      onReset: _reset,
      onApply: _apply,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatsFilterSection(
            title: loc.filtersTownHall,
            icon: Icons.other_houses_rounded,
            summary:
                '${_townHallSummary(loc, townHall)} · '
                '${leagueTier == null ? '${loc.statsLeagueTier}: ${loc.generalAll}' : _leagueTierSummary(loc, leagueTier!)}',
            child: Column(
              children: [
                _TownHallField(
                  value: townHall,
                  onChanged: (v) => setState(() => townHall = v),
                ),
                const SizedBox(height: 10),
                _LeagueTierField(
                  optional: true,
                  value: leagueTier,
                  onChanged: (v) => setState(() => leagueTier = v),
                ),
              ],
            ),
          ),
          _StatsFilterSection(
            title: loc.filtersPerformance,
            icon: Icons.query_stats_rounded,
            summary:
                '${loc.statsMinimumSample}: $minimumSample · '
                '${sortLabels[sortBy]}',
            child: Column(
              children: [
                TextField(
                  controller: minimumSampleController,
                  keyboardType: TextInputType.number,
                  decoration: _statsFilterInputDecoration(
                    label: loc.statsMinimumSample,
                  ),
                  onChanged: (value) => setState(
                    () => minimumSample = int.tryParse(value) ?? 100,
                  ),
                ),
                const SizedBox(height: 10),
                _CompactMenuField<String>(
                  label: loc.statsSortBy,
                  icon: Icons.sort_rounded,
                  value: sortBy,
                  options: sortLabels,
                  onChanged: (value) => setState(() => sortBy = value),
                ),
              ],
            ),
          ),
          _StatsFilterSection(
            title: loc.filtersAdvanced,
            icon: Icons.settings_rounded,
            summary: '${loc.statsItems}: ${include.length}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InlineNotice(
                  icon: Icons.query_stats_outlined,
                  text: loc.statsCustomLensBody,
                ),
                const SizedBox(height: 16),
                Text(loc.statsIncludeItems),
                const SizedBox(height: 6),
                ...include.map(
                  (filter) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(filter.item),
                    subtitle: Text(
                      '${filter.minQuantity ?? 1}–${filter.maxQuantity ?? '∞'}',
                    ),
                    trailing: IconButton(
                      tooltip: loc.presetsDelete,
                      onPressed: () => setState(() => include.remove(filter)),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: itemController,
                        decoration: _statsFilterInputDecoration(
                          label: loc.statsItemId,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: minController,
                        keyboardType: TextInputType.number,
                        decoration: _statsFilterInputDecoration(
                          label: loc.generalMinimum,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: maxController,
                        keyboardType: TextInputType.number,
                        decoration: _statsFilterInputDecoration(
                          label: loc.generalMaximum,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: loc.statsAddItem,
                      onPressed: _addInclude,
                      icon: const Icon(Icons.add_circle_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: excludeController,
                  decoration: _statsFilterInputDecoration(
                    label: loc.statsExcludeItems,
                    hint: 'u_1, u_2',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _reset() {
    setState(() {
      townHall = null;
      leagueTier = null;
      minimumSample = 100;
      sortBy = 'usage_rate';
      dates = _defaultStatsDates();
      include = [];
      minimumSampleController.text = '100';
      excludeController.clear();
      itemController.clear();
      minController.clear();
      maxController.clear();
    });
  }

  void _addInclude() {
    final item = itemController.text.trim();
    if (item.isEmpty) return;
    setState(() {
      include.add(
        StatsItemQuantityFilter(
          item: item,
          minQuantity: int.tryParse(minController.text),
          maxQuantity: int.tryParse(maxController.text),
        ),
      );
      itemController.clear();
      minController.clear();
      maxController.clear();
    });
  }

  Future<void> _apply() async {
    final provider = context.read<StatsProvider>();
    provider.updateArmiesFilters(
      townHall: townHall,
      leagueTier: leagueTier,
      clearTownHall: townHall == null,
      clearLeagueTier: leagueTier == null,
      minimumSample: math.max(1, minimumSample),
      sortBy: sortBy,
      include: include,
      exclude: excludeController.text
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(),
    );
    Navigator.pop(context);
    await provider.setDates(dates.start, dates.end);
  }
}

class _ItemsSection extends StatefulWidget {
  const _ItemsSection();

  @override
  State<_ItemsSection> createState() => _ItemsSectionState();
}

class _ItemsSectionState extends State<_ItemsSection> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final provider = context.watch<StatsProvider>();
    final hasItemSelectors = provider.itemSelectors.isNotEmpty;
    return Column(
      children: [
        _StatsPageGutter(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Column(
            children: [
              _BattleContextBar(
                provider: provider,
                filterSummary:
                    '${_townHallSummary(loc, provider.itemsTownHall)} · '
                    '${provider.itemsLeagueTier == null ? '${loc.statsLeagueTier}: ${loc.generalAll}' : _leagueTierSummary(loc, provider.itemsLeagueTier!)} · '
                    '${loc.statsItems}: ${provider.itemSelectors.length}',
                onFilters: _showItemFilters,
              ),
            ],
          ),
        ),
        Expanded(
          child: _SectionFrame(
            section: StatsSection.items,
            emptyTitle: hasItemSelectors ? null : loc.statsAddItemsTitle,
            emptyBody: hasItemSelectors ? null : loc.statsAddItemsBody,
            builder: (data) {
              final response = data as StatsItemsResponse;
              return Column(
                children: response.items
                    .map((item) => _ItemResultCard(item: item))
                    .toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showItemFilters() async {
    final provider = context.read<StatsProvider>();
    final result = await showDialog<_ItemFiltersResult>(
      context: context,
      builder: (_) => _ItemsFilterDialog(
        initialTownHall: provider.itemsTownHall,
        initialLeagueTier: provider.itemsLeagueTier,
        initialSelectors: provider.itemSelectors,
        initialDates: provider.dates,
      ),
    );
    if (result == null || !mounted) return;
    provider.updateItemFilters(
      townHall: result.townHall,
      leagueTier: result.leagueTier,
      clearTownHall: result.townHall == null,
      clearLeagueTier: result.leagueTier == null,
    );
    provider.setItemSelectors(result.selectors);
    await provider.setDates(result.dates.start, result.dates.end);
  }
}

class _ItemFiltersResult {
  const _ItemFiltersResult({
    required this.townHall,
    required this.leagueTier,
    required this.selectors,
    required this.dates,
  });

  final int? townHall;
  final int? leagueTier;
  final List<StatsItemSelector> selectors;
  final StatsDateFilter dates;
}

class _ItemsFilterDialog extends StatefulWidget {
  const _ItemsFilterDialog({
    required this.initialTownHall,
    required this.initialLeagueTier,
    required this.initialSelectors,
    required this.initialDates,
  });

  final int? initialTownHall;
  final int? initialLeagueTier;
  final List<StatsItemSelector> initialSelectors;
  final StatsDateFilter initialDates;

  @override
  State<_ItemsFilterDialog> createState() => _ItemsFilterDialogState();
}

class _ItemsFilterDialogState extends State<_ItemsFilterDialog> {
  final itemController = TextEditingController();
  late int? townHall;
  late int? leagueTier;
  late StatsItemType type;
  String? hero;
  late List<StatsItemSelector> selectors;
  late StatsDateFilter dates;

  @override
  void initState() {
    super.initState();
    townHall = widget.initialTownHall;
    leagueTier = widget.initialLeagueTier;
    type = StatsItemType.troop;
    selectors = [...widget.initialSelectors];
    dates = widget.initialDates;
  }

  @override
  void dispose() {
    itemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return _StatsFilterDialog(
      dates: dates,
      onDatesChanged: (value) => setState(() => dates = value),
      onApply: _apply,
      onReset: _reset,
      child: Column(
        children: [_buildTownHallSection(loc), _buildItemsSection(loc)],
      ),
    );
  }

  Widget _buildTownHallSection(AppLocalizations loc) {
    final leagueSummary = leagueTier == null
        ? '${loc.statsLeagueTier}: ${loc.generalAll}'
        : _leagueTierSummary(loc, leagueTier!);
    return _StatsFilterSection(
      title: loc.filtersTownHall,
      icon: Icons.other_houses_rounded,
      summary: '${_townHallSummary(loc, townHall)} · $leagueSummary',
      child: Column(
        children: [
          _TownHallField(
            value: townHall,
            onChanged: (value) => setState(() => townHall = value),
          ),
          const SizedBox(height: 10),
          _LeagueTierField(
            optional: true,
            value: leagueTier,
            onChanged: (value) => setState(() => leagueTier = value),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(AppLocalizations loc) {
    return _StatsFilterSection(
      title: loc.statsItems,
      icon: Icons.category_outlined,
      summary: '${_itemTypeLabel(loc, type)} · ${selectors.length}',
      child: Column(
        children: [
          _InlineNotice(
            icon: Icons.info_outline_rounded,
            text: '${loc.statsNoLevels} ${loc.statsRankedCompositionOnly}',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: itemController,
            onChanged: (_) => setState(() {}),
            decoration: _statsFilterInputDecoration(
              label: loc.statsItemId,
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 10),
          _buildItemTypeField(loc),
          if (type == StatsItemType.equipment) ...[
            const SizedBox(height: 10),
            _buildHeroField(loc),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _canAddItem ? _addItem : null,
              icon: const Icon(Icons.add_rounded),
              label: Text(loc.statsAddItem),
            ),
          ),
          if (selectors.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildSelectorChips(),
          ],
        ],
      ),
    );
  }

  Widget _buildItemTypeField(AppLocalizations loc) {
    return _CompactMenuField<StatsItemType>(
      label: loc.statsItemType,
      icon: Icons.category_outlined,
      value: type,
      options: {
        for (final value in StatsItemType.values)
          value: _itemTypeLabel(loc, value),
      },
      onChanged: (value) => setState(() {
        type = value;
        if (type != StatsItemType.equipment) hero = null;
      }),
    );
  }

  Widget _buildHeroField(AppLocalizations loc) {
    return _CompactMenuField<String?>(
      label: loc.statsOwningHero,
      icon: Icons.person_outline_rounded,
      value: hero,
      options: {
        null: loc.statsOwningHero,
        for (final value in StatsItemSelector.validEquipmentHeroes)
          value: value,
      },
      onChanged: (value) => setState(() => hero = value),
    );
  }

  Widget _buildSelectorChips() {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: selectors
            .map(
              (item) => _StatsActiveFilterChip(
                label: item.hero == null
                    ? item.item
                    : '${item.item} · ${item.hero}',
                onDeleted: () => _removeItem(item),
              ),
            )
            .toList(),
      ),
    );
  }

  bool get _canAddItem =>
      itemController.text.trim().isNotEmpty &&
      (type != StatsItemType.equipment || hero != null);

  void _addItem() {
    setState(() {
      selectors = [
        ...selectors,
        StatsItemSelector(
          item: itemController.text.trim(),
          type: type,
          hero: hero,
        ),
      ];
      itemController.clear();
    });
  }

  void _removeItem(StatsItemSelector item) {
    setState(() => selectors = [...selectors]..remove(item));
  }

  void _reset() {
    setState(() {
      townHall = null;
      leagueTier = null;
      type = StatsItemType.troop;
      hero = null;
      selectors = [];
      dates = _defaultStatsDates();
      itemController.clear();
    });
  }

  void _apply() {
    Navigator.pop(
      context,
      _ItemFiltersResult(
        townHall: townHall,
        leagueTier: leagueTier,
        selectors: selectors,
        dates: dates,
      ),
    );
  }
}

class _ItemResultCard extends StatelessWidget {
  const _ItemResultCard({required this.item});

  final StatsItemResult item;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.item,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _PreviewBadge(label: item.type),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricPill(
                label: loc.statsUsage,
                value: _compact(item.useCount),
              ),
              if (item.compositionShare != null)
                _MetricPill(
                  label: loc.statsCompositionShare,
                  value: _percent(item.compositionShare!),
                ),
              if (item.hero != null)
                _MetricPill(label: loc.statsOwningHero, value: item.hero!),
            ],
          ),
          Divider(
            height: 22,
            color: scheme.outlineVariant.withValues(alpha: AppOpacity.border),
          ),
          _MetricsContent(metrics: item.metrics),
        ],
      ),
    );
  }
}

class _WarSection extends StatefulWidget {
  const _WarSection();

  @override
  State<_WarSection> createState() => _WarSectionState();
}

class _WarSectionState extends State<_WarSection> {
  int? townHall;
  int? opponentTownHall;
  bool equalTownHalls = true;

  @override
  void initState() {
    super.initState();
    final provider = context.read<StatsProvider>();
    townHall = provider.warTownHall;
    opponentTownHall = provider.warOpponentTownHall;
    equalTownHalls = provider.warEqualTownHalls;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final provider = context.watch<StatsProvider>();
    return _PerformancePage(
      section: StatsSection.war,
      controls: _BattleContextBar(
        provider: provider,
        filterSummary:
            '${_townHallSummary(loc, townHall)} · '
            '${equalTownHalls ? loc.statsEqualTownHalls : _townHallSummary(loc, opponentTownHall)}',
        onFilters: _showFilters,
      ),
    );
  }

  Future<void> _showFilters() async {
    var draftTownHall = townHall;
    var draftOpponent = opponentTownHall;
    var draftEqual = equalTownHalls;
    var draftDates = context.read<StatsProvider>().dates;
    final apply = await showDialog<bool>(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => _StatsFilterDialog(
          dates: draftDates,
          onDatesChanged: (value) => setSheetState(() => draftDates = value),
          onApply: () => Navigator.pop(sheetContext, true),
          onReset: () => setSheetState(() {
            draftTownHall = null;
            draftOpponent = null;
            draftEqual = true;
            draftDates = _defaultStatsDates();
          }),
          child: Column(
            children: [
              _StatsFilterSection(
                title: AppLocalizations.of(context)!.filtersWarSettings,
                icon: Icons.shield_outlined,
                summary:
                    '${_townHallSummary(AppLocalizations.of(context)!, draftTownHall)} · '
                    '${draftEqual ? AppLocalizations.of(context)!.statsEqualTownHalls : _townHallSummary(AppLocalizations.of(context)!, draftOpponent)}',
                child: Column(
                  children: [
                    _InlineNotice(
                      icon: Icons.shield_outlined,
                      text: AppLocalizations.of(context)!.statsRegularWarOnly,
                    ),
                    const SizedBox(height: 16),
                    _TownHallPair(
                      townHall: draftTownHall,
                      opponentTownHall: draftOpponent,
                      opponentEnabled: !draftEqual,
                      onTownHall: (value) =>
                          setSheetState(() => draftTownHall = value),
                      onOpponent: (value) =>
                          setSheetState(() => draftOpponent = value),
                    ),
                    _StatsFilterCheckbox(
                      label: AppLocalizations.of(context)!.statsEqualTownHalls,
                      value: draftEqual,
                      onChanged: (value) =>
                          setSheetState(() => draftEqual = value),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (apply != true || !mounted) return;
    setState(() {
      townHall = draftTownHall;
      opponentTownHall = draftOpponent;
      equalTownHalls = draftEqual;
    });
    await _apply(draftDates);
  }

  Future<void> _apply(StatsDateFilter dates) async {
    final provider = context.read<StatsProvider>();
    provider.updateWarFilters(
      townHall: townHall,
      opponentTownHall: opponentTownHall,
      equalTownHalls: equalTownHalls,
      clearTownHall: townHall == null,
      clearOpponentTownHall: opponentTownHall == null,
    );
    await provider.setDates(dates.start, dates.end);
  }
}

class _CwlSection extends StatefulWidget {
  const _CwlSection();

  @override
  State<_CwlSection> createState() => _CwlSectionState();
}

class _CwlSectionState extends State<_CwlSection> {
  int? townHall;
  int? opponentTownHall;
  bool equalTownHalls = true;
  int? leagueId;
  late final TextEditingController seasonsController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<StatsProvider>();
    townHall = provider.cwlTownHall;
    opponentTownHall = provider.cwlOpponentTownHall;
    equalTownHalls = provider.cwlEqualTownHalls;
    leagueId = provider.cwlLeagueId;
    seasonsController = TextEditingController(
      text: provider.cwlSeasons.join(', '),
    );
  }

  @override
  void dispose() {
    seasonsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final provider = context.watch<StatsProvider>();
    final cwlLeagues = _localizedCwlLeagues(context);
    return _PerformancePage(
      section: StatsSection.cwl,
      controls: _BattleContextBar(
        provider: provider,
        filterSummary:
            '${_townHallSummary(loc, townHall)} · '
            '${leagueId == null ? loc.statsAllCwlLeagues : cwlLeagues[leagueId]}',
        onFilters: _showFilters,
      ),
    );
  }

  Future<void> _showFilters() async {
    var draftTownHall = townHall;
    var draftOpponent = opponentTownHall;
    var draftEqual = equalTownHalls;
    var draftLeague = leagueId;
    var draftDates = context.read<StatsProvider>().dates;
    final draftSeasons = TextEditingController(text: seasonsController.text);
    final apply = await showDialog<bool>(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => _StatsFilterDialog(
          dates: draftDates,
          onDatesChanged: (value) => setSheetState(() => draftDates = value),
          onApply: () => Navigator.pop(sheetContext, true),
          onReset: () => setSheetState(() {
            draftTownHall = null;
            draftOpponent = null;
            draftEqual = true;
            draftLeague = null;
            draftSeasons.clear();
            draftDates = _defaultStatsDates();
          }),
          child: Column(
            children: [
              _StatsFilterSection(
                title: AppLocalizations.of(context)!.filtersWarSettings,
                icon: Icons.military_tech_outlined,
                summary:
                    '${_townHallSummary(AppLocalizations.of(context)!, draftTownHall)} · '
                    '${draftEqual ? AppLocalizations.of(context)!.statsEqualTownHalls : _townHallSummary(AppLocalizations.of(context)!, draftOpponent)}',
                child: Column(
                  children: [
                    _TownHallPair(
                      townHall: draftTownHall,
                      opponentTownHall: draftOpponent,
                      opponentEnabled: !draftEqual,
                      onTownHall: (value) =>
                          setSheetState(() => draftTownHall = value),
                      onOpponent: (value) =>
                          setSheetState(() => draftOpponent = value),
                    ),
                    _StatsFilterCheckbox(
                      label: AppLocalizations.of(context)!.statsEqualTownHalls,
                      value: draftEqual,
                      onChanged: (value) =>
                          setSheetState(() => draftEqual = value),
                    ),
                  ],
                ),
              ),
              _StatsFilterSection(
                title: AppLocalizations.of(context)!.statsCwlLeague,
                icon: Icons.emoji_events_outlined,
                summary: draftLeague == null
                    ? AppLocalizations.of(context)!.statsAllCwlLeagues
                    : _localizedCwlLeagues(context)[draftLeague]!,
                child: Column(
                  children: [
                    _CompactMenuField<int?>(
                      label: AppLocalizations.of(context)!.statsCwlLeague,
                      icon: Icons.emoji_events_outlined,
                      value: draftLeague,
                      options: {
                        null: AppLocalizations.of(context)!.statsAllCwlLeagues,
                        ..._localizedCwlLeagues(context),
                      },
                      onChanged: (value) =>
                          setSheetState(() => draftLeague = value),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: draftSeasons,
                      decoration: _statsFilterInputDecoration(
                        label: AppLocalizations.of(context)!.statsCwlSeasons,
                        hint: AppLocalizations.of(context)!.statsCwlSeasonsHint,
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
    if (apply != true || !mounted) {
      draftSeasons.dispose();
      return;
    }
    setState(() {
      townHall = draftTownHall;
      opponentTownHall = draftOpponent;
      equalTownHalls = draftEqual;
      leagueId = draftLeague;
      seasonsController.text = draftSeasons.text;
    });
    draftSeasons.dispose();
    await _apply(draftDates);
  }

  Future<void> _apply(StatsDateFilter dates) async {
    final provider = context.read<StatsProvider>();
    provider.updateCwlFilters(
      townHall: townHall,
      opponentTownHall: opponentTownHall,
      equalTownHalls: equalTownHalls,
      leagueId: leagueId,
      clearTownHall: townHall == null,
      clearOpponentTownHall: opponentTownHall == null,
      clearLeague: leagueId == null,
      seasons: seasonsController.text
          .split(',')
          .map((value) => value.trim())
          .where((value) => RegExp(r'^\d{4}-\d{2}$').hasMatch(value))
          .toList(),
    );
    await provider.setDates(dates.start, dates.end);
  }
}

class _RankedSection extends StatefulWidget {
  const _RankedSection();

  @override
  State<_RankedSection> createState() => _RankedSectionState();
}

class _RankedSectionState extends State<_RankedSection> {
  late int townHall;
  late int leagueTier;

  @override
  void initState() {
    super.initState();
    final provider = context.read<StatsProvider>();
    townHall = provider.rankedTownHall;
    leagueTier = provider.rankedLeagueTier;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final provider = context.watch<StatsProvider>();
    return _PerformancePage(
      section: StatsSection.ranked,
      controls: _BattleContextBar(
        provider: provider,
        filterSummary: 'TH$townHall · ${_leagueTierSummary(loc, leagueTier)}',
        onFilters: _showFilters,
      ),
    );
  }

  Future<void> _showFilters() async {
    var draftTownHall = townHall;
    var draftLeagueTier = leagueTier;
    var draftDates = context.read<StatsProvider>().dates;
    final apply = await showDialog<bool>(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => _StatsFilterDialog(
          dates: draftDates,
          onDatesChanged: (value) => setSheetState(() => draftDates = value),
          onApply: () => Navigator.pop(sheetContext, true),
          onReset: () => setSheetState(() {
            draftTownHall = 18;
            draftLeagueTier = 1;
            draftDates = _defaultStatsDates();
          }),
          child: Column(
            children: [
              _StatsFilterSection(
                title: AppLocalizations.of(context)!.filtersPerformance,
                icon: Icons.workspace_premium_outlined,
                summary:
                    'TH$draftTownHall · ${_leagueTierSummary(AppLocalizations.of(context)!, draftLeagueTier)}',
                child: Column(
                  children: [
                    _InlineNotice(
                      icon: Icons.workspace_premium_outlined,
                      text: AppLocalizations.of(context)!.statsRankedRequired,
                    ),
                    const SizedBox(height: 16),
                    _TownHallField(
                      allowAll: false,
                      value: draftTownHall,
                      onChanged: (value) => setSheetState(
                        () => draftTownHall = value ?? draftTownHall,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _LeagueTierField(
                      value: draftLeagueTier,
                      onChanged: (value) => setSheetState(
                        () => draftLeagueTier = value ?? draftLeagueTier,
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
    if (apply != true || !mounted) return;
    setState(() {
      townHall = draftTownHall;
      leagueTier = draftLeagueTier;
    });
    final provider = context.read<StatsProvider>();
    provider.updateRankedFilters(townHall: townHall, leagueTier: leagueTier);
    await provider.setDates(draftDates.start, draftDates.end);
  }
}

class _PerformancePage extends StatelessWidget {
  const _PerformancePage({required this.section, required this.controls});

  final StatsSection section;
  final Widget controls;

  @override
  Widget build(BuildContext context) {
    return _SectionFrame(
      section: section,
      prefix: controls,
      builder: (data) {
        final response = data as StatsPerformanceResponse;
        final loc = AppLocalizations.of(context)!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetricsCard(
              title: loc.statsPerformance,
              metrics: response.metrics,
            ),
            if (response.breakdowns.isNotEmpty) ...[
              const SizedBox(height: 18),
              SidePageSectionHeader(title: loc.statsSeasonBreakdown),
              ...response.breakdowns.map(
                (breakdown) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MetricsCard(
                    title: breakdown.key,
                    metrics: breakdown.metrics,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _MetricsCard extends StatelessWidget {
  const _MetricsCard({required this.title, required this.metrics});

  final String title;
  final StatsMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          _MetricsContent(metrics: metrics),
        ],
      ),
    );
  }
}

class _MetricsContent extends StatelessWidget {
  const _MetricsContent({required this.metrics});

  final StatsMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MetricPill(
              label: loc.statsSamples,
              value: _compact(metrics.sampleSize),
              icon: Icons.dataset_outlined,
            ),
            if (metrics.usageRate != null)
              _MetricPill(
                label: loc.statsUsage,
                value: _percent(metrics.usageRate!),
                icon: Icons.pie_chart_outline_rounded,
              ),
            _MetricPill(
              label: loc.statsAverageStars,
              value: metrics.averageStars.toStringAsFixed(2),
              icon: Icons.star_rounded,
              accentColor: StatColors.warStarGold,
            ),
            _MetricPill(
              label: loc.statsAverageDestruction,
              value: _percent(metrics.averageDestruction),
              icon: Icons.percent_rounded,
              accentColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(loc.statsStarRates, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        _StarRates(metrics: metrics),
        if (metrics.daily.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            loc.statsDailyTrend,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          _TrendChart(points: metrics.daily),
        ],
      ],
    );
  }
}

class _StarRates extends StatelessWidget {
  const _StarRates({required this.metrics});

  final StatsMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rates = [
      metrics.zeroStarRate,
      metrics.oneStarRate,
      metrics.twoStarRate,
      metrics.threeStarRate,
    ];
    final colors = [
      scheme.onSurfaceVariant,
      StatColors.loss,
      StatColors.tie,
      StatColors.win,
    ];
    return Column(
      children: List.generate(
        4,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 34,
                child: Text(
                  '$index★',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Expanded(
                child: LinearProgressIndicator(
                  value: _asPercentValue(rates[index]).clamp(0, 100) / 100,
                  minHeight: 9,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  color: colors[index],
                  backgroundColor: scheme.surfaceContainerHighest.withValues(
                    alpha: 0.42,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(minWidth: 58, minHeight: 30),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.34),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: colors[index].withValues(alpha: 0.44),
                  ),
                ),
                child: Text(
                  _percent(rates[index]),
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w900,
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

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.points});

  final List<StatsDailyPoint> points;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final spots = [
      for (var index = 0; index < points.length; index++)
        FlSpot(index.toDouble(), _asPercentValue(points[index].threeStarRate)),
    ];
    final first = points.first;
    final last = points.last;
    return Semantics(
      label:
          '${AppLocalizations.of(context)!.statsDailyTrend}: '
          '${first.date}, ${_percent(first.threeStarRate)}; '
          '${last.date}, ${_percent(last.threeStarRate)}',
      excludeSemantics: true,
      child: SizedBox(
        height: 150,
        width: double.infinity,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: math.max(1.0, (points.length - 1).toDouble()),
            minY: 0,
            maxY: 100,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: scheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 34,
                  interval: 25,
                  getTitlesWidget: (value, meta) => Text(
                    '${value.toInt()}%',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: math.max(1, (points.length / 4).floor()).toDouble(),
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= points.length) {
                      return const SizedBox.shrink();
                    }
                    final date = DateTime.tryParse(points[index].date);
                    return Text(
                      date == null ? '' : DateFormat.Md().format(date),
                      style: Theme.of(context).textTheme.labelSmall,
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => scheme.inverseSurface,
                getTooltipItems: (spots) => spots
                    .map(
                      (spot) => LineTooltipItem(
                        '${points[spot.x.toInt()].date}\n${_percent(spot.y)}',
                        TextStyle(
                          color: scheme.onInverseSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.28,
                color: scheme.primary,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(show: points.length <= 14),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      scheme.primary.withValues(alpha: 0.28),
                      scheme.primary.withValues(alpha: 0.01),
                    ],
                  ),
                ),
              ),
            ],
          ),
          duration: CKMotion.durationOf(context, CKMotion.slow),
          curve: CKMotion.standardCurve,
        ),
      ),
    );
  }
}

class _SearchAndFilter extends StatelessWidget {
  const _SearchAndFilter({
    required this.controller,
    required this.query,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String query;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppSearchField(
            controller: controller,
            query: query,
            hintText: hint,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _TownHallPair extends StatelessWidget {
  const _TownHallPair({
    required this.townHall,
    required this.opponentTownHall,
    required this.opponentEnabled,
    required this.onTownHall,
    required this.onOpponent,
  });

  final int? townHall;
  final int? opponentTownHall;
  final bool opponentEnabled;
  final ValueChanged<int?> onTownHall;
  final ValueChanged<int?> onOpponent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final own = _TownHallField(value: townHall, onChanged: onTownHall);
        final opponent = IgnorePointer(
          ignoring: !opponentEnabled,
          child: Opacity(
            opacity: opponentEnabled ? 1 : 0.5,
            child: _TownHallField(
              opponent: true,
              value: opponentTownHall,
              onChanged: onOpponent,
            ),
          ),
        );
        if (constraints.maxWidth < 430) {
          return Column(children: [own, const SizedBox(height: 10), opponent]);
        }
        return Row(
          children: [
            Expanded(child: own),
            const SizedBox(width: 10),
            Expanded(child: opponent),
          ],
        );
      },
    );
  }
}

class _StatsFilterCheckbox extends StatelessWidget {
  const _StatsFilterCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Checkbox(value: value, onChanged: (next) => onChanged(next ?? false)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _statsFilterInputDecoration({
  required String label,
  String? hint,
  Widget? prefixIcon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: prefixIcon,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  );
}

class _TownHallField extends StatelessWidget {
  const _TownHallField({
    required this.value,
    required this.onChanged,
    this.allowAll = true,
    this.opponent = false,
  });

  final int? value;
  final ValueChanged<int?> onChanged;
  final bool allowAll;
  final bool opponent;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return _CompactMenuField<int?>(
      label: opponent ? loc.statsOpponentTownHall : loc.statsTownHall,
      icon: opponent ? Icons.gps_fixed_rounded : Icons.other_houses_rounded,
      value: value,
      options: {
        if (allowAll) null: loc.statsAllTownHalls,
        for (final townHall in List.generate(12, (index) => 18 - index))
          townHall: 'TH$townHall',
      },
      onChanged: onChanged,
    );
  }
}

class _LeagueTierField extends StatelessWidget {
  const _LeagueTierField({
    required this.value,
    required this.onChanged,
    this.optional = false,
  });

  final int? value;
  final ValueChanged<int?> onChanged;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return _CompactMenuField<int?>(
      label: loc.statsLeagueTier,
      icon: Icons.workspace_premium_outlined,
      value: value,
      options: {
        if (optional) null: loc.generalAll,
        for (final tier in List.generate(10, (index) => index + 1))
          tier: tier == 1
              ? loc.statsLegendLeagueOne
              : '${loc.statsLeagueTier} $tier',
      },
      onChanged: onChanged,
    );
  }
}

class _CompactMenuField<T> extends StatelessWidget {
  const _CompactMenuField({
    required this.label,
    required this.icon,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entries = options.entries.toList(growable: false);
    final selectedIndex = entries.indexWhere((entry) => entry.key == value);
    final selectedLabel = selectedIndex >= 0
        ? entries[selectedIndex].value
        : value.toString();
    return PopupMenuButton<int>(
      initialValue: selectedIndex >= 0 ? selectedIndex : null,
      onSelected: (index) => onChanged(entries[index].key),
      color: scheme.surface,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.chip),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: AppOpacity.border),
        ),
      ),
      itemBuilder: (context) => [
        for (var index = 0; index < entries.length; index++)
          PopupMenuItem<int>(
            value: index,
            height: 44,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    entries[index].value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (entries[index].key == value)
                  Icon(Icons.check_rounded, size: 18, color: scheme.primary),
              ],
            ),
          ),
      ],
      child: _CompactFilterTile(label: label, value: selectedLabel, icon: icon),
    );
  }
}

class _CompactFilterTile extends StatelessWidget {
  const _CompactFilterTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_drop_down,
            color: scheme.onSurface.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }
}

class _StatsFilterDialog extends StatelessWidget {
  const _StatsFilterDialog({
    required this.child,
    required this.onApply,
    required this.onReset,
    required this.dates,
    required this.onDatesChanged,
  });

  final Widget child;
  final VoidCallback onApply;
  final VoidCallback onReset;
  final StatsDateFilter dates;
  final ValueChanged<StatsDateFilter> onDatesChanged;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Container(
        width: MediaQuery.sizeOf(context).width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
          maxWidth: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: scheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.tune, color: scheme.primary, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    loc.generalFilters,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: scheme.onSurface),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.flash_on, size: 16, color: scheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          loc.filtersQuickFilters,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: _StatsPresetChip(
                        label: loc.filtersLast30Days,
                        icon: Icons.schedule,
                        selected: dates.inclusiveDays == 30,
                        onTap: () => onDatesChanged(_defaultStatsDates()),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _StatsFilterSection(
                      title: loc.filtersTimeFilters,
                      icon: Icons.schedule,
                      summary: _statsDateSummary(context, dates),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                        onTap: () async {
                          final range = await _pickStatsDateRange(
                            context,
                            dates,
                          );
                          if (range != null) {
                            onDatesChanged(
                              StatsDateFilter(
                                start: range.start,
                                end: range.end,
                              ),
                            );
                          }
                        },
                        child: _CompactFilterTile(
                          label: loc.filtersDateRange,
                          value: _statsDateSummary(context, dates),
                          icon: Icons.date_range_rounded,
                        ),
                      ),
                    ),
                    child,
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border(
                  top: BorderSide(color: scheme.outline.withValues(alpha: 0.2)),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: onReset,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: Text(loc.generalReset),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(loc.generalCancel),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: onApply,
                        icon: const Icon(Icons.check, size: 18),
                        label: Text(loc.generalApply),
                      ),
                    ],
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

class _StatsFilterSection extends StatefulWidget {
  const _StatsFilterSection({
    required this.title,
    required this.icon,
    required this.summary,
    required this.child,
  });

  final String title;
  final IconData icon;
  final String summary;
  final Widget child;

  @override
  State<_StatsFilterSection> createState() => _StatsFilterSectionState();
}

class _StatsPresetChip extends StatelessWidget {
  const _StatsPresetChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? scheme.primary : scheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? scheme.onPrimary : scheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected ? scheme.onPrimary : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsActiveFilterChip extends StatelessWidget {
  const _StatsActiveFilterChip({required this.label, required this.onDeleted});

  final String label;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSecondaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 3),
          InkWell(
            onTap: onDeleted,
            child: Icon(
              Icons.close,
              size: 12,
              color: scheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsFilterSectionState extends State<_StatsFilterSection> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.control),
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => expanded = !expanded);
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(widget.icon, size: 20, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (!expanded) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.summary,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: CKMotion.durationOf(
                        context,
                        const Duration(milliseconds: 200),
                      ),
                      child: Icon(Icons.expand_more, color: scheme.primary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: CKMotion.durationOf(
              context,
              const Duration(milliseconds: 300),
            ),
            curve: Curves.easeInOut,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: widget.child,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: CKSectionPanel(child: child),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    this.icon,
    this.accentColor,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = accentColor ?? scheme.onSurfaceVariant;
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.fromLTRB(8, 6, 11, 6),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.34),
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(
            color: scheme.outlineVariant.withValues(
              alpha: AppOpacity.borderStrong,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: 28,
                  child: Icon(icon, size: 16, color: accent),
                ),
              ),
              const SizedBox(width: 7),
            ],
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 154),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
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

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({
    required this.icon,
    required this.text,
    this.error = false,
  });

  final IconData icon;
  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = error ? scheme.error : scheme.primary;
    final foreground = error ? scheme.onErrorContainer : scheme.onSurface;
    final fill = error
        ? scheme.errorContainer.withValues(alpha: 0.8)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.8);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FreshDataChip extends StatelessWidget {
  const _FreshDataChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: scheme.primary.withValues(alpha: AppOpacity.borderStrong),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 17,
            color: scheme.primary,
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

String _townHallSummary(AppLocalizations loc, int? townHall) =>
    townHall == null ? loc.statsAllTownHalls : 'TH$townHall';

String _leagueTierSummary(AppLocalizations loc, int leagueTier) =>
    leagueTier == 1
    ? loc.statsLegendLeagueOne
    : '${loc.statsLeagueTier} $leagueTier';

String _percent(double value) {
  final normalized = _asPercentValue(value);
  return '${normalized.toStringAsFixed(normalized >= 10 ? 1 : 2)}%';
}

double _asPercentValue(double value) =>
    value.abs() <= 1 && value != 0 ? value * 100 : value;

String _leagueTierLabel(int? id) => switch (id) {
  105000036 => 'LL1',
  105000035 => 'LL2',
  105000034 => 'LL3',
  final value? when value >= 105000010 => 'L${value - 105000010}',
  final value? => '$value',
  null => '—',
};

String _compact(int value) => NumberFormat.compact().format(value);

String _itemTypeLabel(AppLocalizations loc, StatsItemType type) =>
    switch (type) {
      StatsItemType.troop => loc.statsTroop,
      StatsItemType.spell => loc.statsSpell,
      StatsItemType.hero => loc.statsHero,
      StatsItemType.pet => loc.statsPet,
      StatsItemType.equipment => loc.statsEquipment,
    };

const _cwlLeagueNamesByApiId = <int, String>{
  48000000: 'Bronze League III',
  48000001: 'Bronze League II',
  48000002: 'Bronze League I',
  48000003: 'Silver League III',
  48000004: 'Silver League II',
  48000005: 'Silver League I',
  48000006: 'Gold League III',
  48000007: 'Gold League II',
  48000008: 'Gold League I',
  48000009: 'Crystal League III',
  48000010: 'Crystal League II',
  48000011: 'Crystal League I',
  48000012: 'Master League III',
  48000013: 'Master League II',
  48000014: 'Master League I',
  48000015: 'Champion League III',
  48000016: 'Champion League II',
  48000017: 'Champion League I',
};

Map<int, String> _localizedCwlLeagues(BuildContext context) {
  final loc = AppLocalizations.of(context)!;
  final staticLeagues = GameDataService.warLeagueData['leagues'];
  final fallbacks = <int, String>{
    48000000: '${loc.statsLeagueBronze} III',
    48000001: '${loc.statsLeagueBronze} II',
    48000002: '${loc.statsLeagueBronze} I',
    48000003: '${loc.statsLeagueSilver} III',
    48000004: '${loc.statsLeagueSilver} II',
    48000005: '${loc.statsLeagueSilver} I',
    48000006: '${loc.statsLeagueGold} III',
    48000007: '${loc.statsLeagueGold} II',
    48000008: '${loc.statsLeagueGold} I',
    48000009: '${loc.statsLeagueCrystal} III',
    48000010: '${loc.statsLeagueCrystal} II',
    48000011: '${loc.statsLeagueCrystal} I',
    48000012: '${loc.statsLeagueMaster} III',
    48000013: '${loc.statsLeagueMaster} II',
    48000014: '${loc.statsLeagueMaster} I',
    48000015: '${loc.statsLeagueChampion} III',
    48000016: '${loc.statsLeagueChampion} II',
    48000017: '${loc.statsLeagueChampion} I',
  };

  return {
    for (final entry in _cwlLeagueNamesByApiId.entries)
      entry.key: loc.gameItemName(
        staticLeagues is Map && staticLeagues[entry.value] is Map
            ? Map<String, dynamic>.from(staticLeagues[entry.value] as Map)
            : null,
        fallbacks[entry.key]!,
      ),
  };
}
