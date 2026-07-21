import 'dart:math' as math;

import 'package:clashkingapp/common/widgets/header_widgets.dart';
import 'package:clashkingapp/common/widgets/info_profile_tabs.dart';
import 'package:clashkingapp/common/widgets/liquid_glass.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/stats/models/stats_models.dart';
import 'package:clashkingapp/features/stats/presentation/stats_provider.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(child: _StatsHeader(provider: provider)),
          SliverToBoxAdapter(
            child: InfoProfileTabs(
              selectedIndex: selectedIndex,
              alwaysScrollable: true,
              onTabSelected: (index) => provider.selectSection(sections[index]),
              tabs: [
                for (final section in sections)
                  InfoProfileTabData(
                    label: _sectionLabel(
                      AppLocalizations.of(context)!,
                      section,
                    ),
                    imageUrl: _sectionImage(section),
                  ),
              ],
            ),
          ),
        ],
        body: Column(
          children: [
            if (provider.audience == StatsAudience.battle)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _DateRangeControl(provider: provider),
              ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
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
          ],
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

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({required this.provider});

  final StatsProvider provider;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final height = MediaQuery.paddingOf(context).top + 246;
    return Stack(
      children: [
        Positioned.fill(
          child: InfoHeroBackdrop(
            imageUrl: ImageAssets.playerWarStatsPageBackground,
            height: height,
          ),
        ),
        SizedBox(
          height: height,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
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
                          width: 58,
                          height: 58,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          loc.sideStatsTitle,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        Text(
                          loc.statsHeaderSubtitle,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: LiquidGlassSegmentedControl<StatsAudience>(
                      height: 46,
                      values: StatsAudience.values,
                      labels: [loc.statsBattle, loc.statsWorld],
                      selected: provider.audience,
                      color: Colors.white,
                      onChanged: provider.selectAudience,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DateRangeControl extends StatelessWidget {
  const _DateRangeControl({required this.provider});

  final StatsProvider provider;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final formatter = DateFormat.MMMd(
      Localizations.localeOf(context).toString(),
    );
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.primaryContainer.withValues(alpha: 0.58),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _pick(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.date_range_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.statsDateRange,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${formatter.format(provider.dates.start)} – '
                      '${formatter.format(provider.dates.end)} '
                      '· ${loc.statsIndexDays(provider.dates.inclusiveDays)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                loc.statsDateRangeHint,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final today = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(today.year, today.month, today.day),
      initialDateRange: DateTimeRange(
        start: provider.dates.start,
        end: provider.dates.end,
      ),
      helpText: AppLocalizations.of(context)!.statsDateRangeHint,
    );
    if (result == null || !context.mounted) return;
    if (StatsDateFilter(start: result.start, end: result.end).inclusiveDays >
        90) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.statsDateRangeTooLong),
        ),
      );
      return;
    }
    await provider.setDates(result.start, result.end);
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
        padding: sidePagePadding,
        children: [
          if (prefix != null) ...[prefix!, const SizedBox(height: 12)],
          const SidePageLoadingRows(),
        ],
      );
    }
    if (state.status == StatsLoadStatus.error && state.data == null) {
      return ListView(
        padding: sidePagePadding,
        children: [
          if (prefix != null) ...[prefix!, const SizedBox(height: 12)],
          SidePageErrorPanel(
            message: loc.sideStatsLoadError,
            detail: ApiService.getErrorMessage(state.error),
            onRetry: provider.refresh,
          ),
        ],
      );
    }
    if (state.status == StatsLoadStatus.empty && state.data == null) {
      return ListView(
        padding: sidePagePadding,
        children: [
          if (prefix != null) ...[prefix!, const SizedBox(height: 12)],
          SidePageEmptyState(
            icon: Icons.query_stats_rounded,
            title: emptyTitle ?? loc.statsNoDataTitle,
            body: emptyBody ?? loc.statsNoDataBody,
          ),
        ],
      );
    }

    final data = state.data;
    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView(
        padding: sidePagePadding,
        children: [
          if (prefix != null) ...[prefix!, const SizedBox(height: 12)],
          if (state.isRefreshing) const LinearProgressIndicator(minHeight: 2),
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
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                avatar: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 18,
                ),
                label: Text(loc.statsUpdated),
              ),
            ),
          ],
        ],
      ),
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
            _PreviewPanel(
              title: loc.statsWarsOverTime,
              body: loc.statsWarsOverTimePreview,
              points: const [42, 51, 48, 62, 71, 69, 76, 84, 79, 91],
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
              color: const Color(0xFFFF9F43),
            ),
            const SizedBox(height: 12),
            _DistributionCard(
              title: loc.statsLeagueDistribution,
              subtitle: loc.statsTrackedPlayers,
              values: counts.leagueTiers,
              labelBuilder: _leagueTierLabel,
              color: const Color(0xFF8B5CF6),
            ),
            const SizedBox(height: 12),
            _DistributionCard(
              title: loc.statsBuilderHallDistribution,
              subtitle: loc.statsTrackedPlayers,
              values: counts.builderHalls,
              labelBuilder: (id) => 'BH${id ?? '?'}',
              color: const Color(0xFF38BDF8),
            ),
            const SizedBox(height: 12),
            _PreviewPanel(
              title: loc.statsEquipmentAdoption,
              body: loc.statsEquipmentAdoptionPreview,
              points: const [18, 31, 47, 63, 78, 69, 42],
            ),
            const SizedBox(height: 12),
            _PreviewPanel(
              title: loc.statsExperienceDistribution,
              body: loc.statsExperienceDistributionPreview,
              points: const [8, 19, 38, 72, 56, 29, 12],
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
              labelBuilder: (id) => _cwlLeagues[id] ?? '${id ?? '?'}',
              color: const Color(0xFFFF5D8F),
            ),
            const SizedBox(height: 12),
            _DistributionCard(
              title: loc.statsCapitalLeagueDistribution,
              subtitle: loc.statsTrackedClans,
              values: counts.capitalLeagues,
              labelBuilder: (id) => loc.statsLeagueId(id ?? 0),
              color: const Color(0xFF2DD4BF),
            ),
            const SizedBox(height: 12),
            _CountsSummaryCard(
              title: loc.statsTrackedLocations,
              value: counts.locations.where((item) => item.id != null).length,
              subtitle: loc.statsLocationCountHelp,
            ),
            const SizedBox(height: 12),
            _PreviewPanel(
              title: loc.statsCwlRosterSizes,
              body: loc.statsCwlRosterSizesPreview,
              points: const [64, 36],
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
    return BarChart(
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
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({
    required this.title,
    required this.body,
    required this.points,
  });

  final String title;
  final String body;
  final List<double> points;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _PreviewBadge(label: AppLocalizations.of(context)!.statsPreview),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 76,
            child: _MiniPreviewBars(values: points, color: scheme.primary),
          ),
        ],
      ),
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
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900),
    ),
  );
}

class _MiniPreviewBars extends StatelessWidget {
  const _MiniPreviewBars({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.fold<double>(1, math.max);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final value in values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: FractionallySizedBox(
                heightFactor: value / maxValue,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.72),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
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

class _ArmiesSection extends StatefulWidget {
  const _ArmiesSection();

  @override
  State<_ArmiesSection> createState() => _ArmiesSectionState();
}

class _ArmiesSectionState extends State<_ArmiesSection> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: _SearchAndFilter(
            hint: loc.statsSearchArmies,
            onChanged: (value) => setState(() => query = value),
            onFilter: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => ChangeNotifierProvider.value(
                value: context.read<StatsProvider>(),
                child: const _ArmyFiltersSheet(),
              ),
            ),
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
                return SidePageEmptyState(
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
          SizedBox(
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
                        '$core\n${_percent(spot.x)} usage · ${_percent(spot.y)} 3★',
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
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
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
                            borderRadius: BorderRadius.circular(99),
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

class _ArmyFiltersSheet extends StatefulWidget {
  const _ArmyFiltersSheet();

  @override
  State<_ArmyFiltersSheet> createState() => _ArmyFiltersSheetState();
}

class _ArmyFiltersSheetState extends State<_ArmyFiltersSheet> {
  late int? townHall;
  late int? leagueTier;
  late int minimumSample;
  late String sortBy;
  late List<StatsItemQuantityFilter> include;
  late final TextEditingController excludeController;
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
    include = [...provider.armiesInclude];
    excludeController = TextEditingController(
      text: provider.armiesExclude.join(', '),
    );
  }

  @override
  void dispose() {
    itemController.dispose();
    minController.dispose();
    maxController.dispose();
    excludeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          10,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              loc.statsCustomLens,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              loc.statsCustomLensBody,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
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
            const SizedBox(height: 10),
            TextFormField(
              initialValue: '$minimumSample',
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: loc.statsMinimumSample),
              onChanged: (value) => minimumSample = int.tryParse(value) ?? 100,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: sortBy,
              decoration: InputDecoration(labelText: loc.statsSortBy),
              items:
                  {
                        'usage_rate': loc.statsUsage,
                        'three_star_rate': loc.statsThreeStarRate,
                        'average_stars': loc.statsAverageStars,
                        'average_destruction': loc.statsAverageDestruction,
                      }.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(),
              onChanged: (value) => sortBy = value ?? sortBy,
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
                    decoration: InputDecoration(labelText: loc.statsItemId),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: minController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: loc.generalMinimum),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: maxController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: loc.generalMaximum),
                  ),
                ),
                IconButton(
                  onPressed: _addInclude,
                  icon: const Icon(Icons.add_circle_rounded),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: excludeController,
              decoration: InputDecoration(
                labelText: loc.statsExcludeItems,
                hintText: 'u_1, u_2',
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _apply,
              icon: const Icon(Icons.tune_rounded),
              label: Text(loc.statsApplyFilters),
            ),
          ],
        ),
      ),
    );
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

  void _apply() {
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
    provider.load(StatsSection.armies, force: true);
  }
}

class _ItemsSection extends StatefulWidget {
  const _ItemsSection();

  @override
  State<_ItemsSection> createState() => _ItemsSectionState();
}

class _ItemsSectionState extends State<_ItemsSection> {
  final itemController = TextEditingController();
  StatsItemType type = StatsItemType.troop;
  String? hero;

  @override
  void dispose() {
    itemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final provider = context.watch<StatsProvider>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: _SurfaceCard(
            child: Column(
              children: [
                _InlineNotice(
                  icon: Icons.info_outline_rounded,
                  text:
                      '${loc.statsNoLevels} ${loc.statsRankedCompositionOnly}',
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: itemController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: loc.statsItemId,
                    prefixIcon: const Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<StatsItemType>(
                        initialValue: type,
                        decoration: InputDecoration(
                          labelText: loc.statsItemType,
                        ),
                        items: StatsItemType.values
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(_itemTypeLabel(loc, value)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() {
                          type = value ?? type;
                          if (type != StatsItemType.equipment) hero = null;
                        }),
                      ),
                    ),
                    if (type == StatsItemType.equipment) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: hero,
                          decoration: InputDecoration(
                            labelText: loc.statsOwningHero,
                          ),
                          items: StatsItemSelector.validEquipmentHeroes
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(
                                    value,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setState(() => hero = value),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _canAdd ? _add : null,
                        icon: const Icon(Icons.add_rounded),
                        label: Text(loc.statsAddItem),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      tooltip: loc.generalFilters,
                      onPressed: () => _showItemFilters(context),
                      icon: const Icon(Icons.tune_rounded),
                    ),
                  ],
                ),
                if (provider.itemSelectors.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: provider.itemSelectors
                        .map(
                          (item) => InputChip(
                            label: Text(
                              item.hero == null
                                  ? item.item
                                  : '${item.item} · ${item.hero}',
                            ),
                            onDeleted: () {
                              provider.setItemSelectors(
                                [...provider.itemSelectors]..remove(item),
                              );
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: () =>
                        provider.load(StatsSection.items, force: true),
                    icon: const Icon(Icons.query_stats_rounded),
                    label: Text(loc.statsAnalyzeItems),
                  ),
                ],
              ],
            ),
          ),
        ),
        Expanded(
          child: _SectionFrame(
            section: StatsSection.items,
            emptyTitle: loc.statsAddItemsTitle,
            emptyBody: loc.statsAddItemsBody,
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

  bool get _canAdd =>
      itemController.text.trim().isNotEmpty &&
      (type != StatsItemType.equipment || hero != null);

  void _add() {
    final provider = context.read<StatsProvider>();
    provider.setItemSelectors([
      ...provider.itemSelectors,
      StatsItemSelector(
        item: itemController.text.trim(),
        type: type,
        hero: hero,
      ),
    ]);
    itemController.clear();
    setState(() {});
  }

  Future<void> _showItemFilters(BuildContext context) async {
    final provider = context.read<StatsProvider>();
    var townHall = provider.itemsTownHall;
    var tier = provider.itemsLeagueTier;
    final apply = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TownHallField(
                  value: townHall,
                  onChanged: (value) => setSheetState(() => townHall = value),
                ),
                const SizedBox(height: 10),
                _LeagueTierField(
                  optional: true,
                  value: tier,
                  onChanged: (value) => setSheetState(() => tier = value),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(AppLocalizations.of(context)!.statsApplyFilters),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (apply == true) {
      provider.updateItemFilters(
        townHall: townHall,
        leagueTier: tier,
        clearTownHall: townHall == null,
        clearLeagueTier: tier == null,
      );
    }
  }
}

class _ItemResultCard extends StatelessWidget {
  const _ItemResultCard({required this.item});

  final StatsItemResult item;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
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
              Chip(label: Text(item.type)),
            ],
          ),
          if (item.hero != null) Text('${loc.statsOwningHero}: ${item.hero}'),
          Text('${loc.statsUsage}: ${_compact(item.useCount)}'),
          if (item.compositionShare != null)
            Text(
              '${loc.statsCompositionShare}: '
              '${_percent(item.compositionShare!)}',
            ),
          const SizedBox(height: 10),
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
    return _PerformancePage(
      section: StatsSection.war,
      controls: _SurfaceCard(
        child: Column(
          children: [
            _InlineNotice(
              icon: Icons.shield_outlined,
              text: loc.statsRegularWarOnly,
            ),
            const SizedBox(height: 10),
            _TownHallPair(
              townHall: townHall,
              opponentTownHall: opponentTownHall,
              opponentEnabled: !equalTownHalls,
              onTownHall: (value) => setState(() => townHall = value),
              onOpponent: (value) => setState(() => opponentTownHall = value),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(loc.statsEqualTownHalls),
              value: equalTownHalls,
              onChanged: (value) => setState(() => equalTownHalls = value),
            ),
            FilledButton(onPressed: _apply, child: Text(loc.statsApplyFilters)),
          ],
        ),
      ),
    );
  }

  void _apply() {
    final provider = context.read<StatsProvider>();
    provider.updateWarFilters(
      townHall: townHall,
      opponentTownHall: opponentTownHall,
      equalTownHalls: equalTownHalls,
      clearTownHall: townHall == null,
      clearOpponentTownHall: opponentTownHall == null,
    );
    provider.load(StatsSection.war, force: true);
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
    return _PerformancePage(
      section: StatsSection.cwl,
      controls: _SurfaceCard(
        child: Column(
          children: [
            _TownHallPair(
              townHall: townHall,
              opponentTownHall: opponentTownHall,
              opponentEnabled: !equalTownHalls,
              onTownHall: (value) => setState(() => townHall = value),
              onOpponent: (value) => setState(() => opponentTownHall = value),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(loc.statsEqualTownHalls),
              value: equalTownHalls,
              onChanged: (value) => setState(() => equalTownHalls = value),
            ),
            DropdownButtonFormField<int?>(
              initialValue: leagueId,
              decoration: InputDecoration(labelText: loc.statsCwlLeague),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(loc.statsAllCwlLeagues),
                ),
                ..._cwlLeagues.entries.map(
                  (entry) => DropdownMenuItem<int?>(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => leagueId = value),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: seasonsController,
              decoration: InputDecoration(
                labelText: loc.statsCwlSeasons,
                hintText: loc.statsCwlSeasonsHint,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _apply, child: Text(loc.statsApplyFilters)),
          ],
        ),
      ),
    );
  }

  void _apply() {
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
    provider.load(StatsSection.cwl, force: true);
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
    return _PerformancePage(
      section: StatsSection.ranked,
      controls: _SurfaceCard(
        child: Column(
          children: [
            _InlineNotice(
              icon: Icons.workspace_premium_outlined,
              text: loc.statsRankedRequired,
            ),
            const SizedBox(height: 10),
            _TownHallField(
              allowAll: false,
              value: townHall,
              onChanged: (value) => setState(() => townHall = value ?? 18),
            ),
            const SizedBox(height: 10),
            _LeagueTierField(
              value: leagueTier,
              onChanged: (value) => setState(() => leagueTier = value ?? 1),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                final provider = context.read<StatsProvider>();
                provider.updateRankedFilters(
                  townHall: townHall,
                  leagueTier: leagueTier,
                );
                provider.load(StatsSection.ranked, force: true);
              },
              child: Text(loc.statsApplyFilters),
            ),
          ],
        ),
      ),
    );
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
            ),
            if (metrics.usageRate != null)
              _MetricPill(
                label: loc.statsUsage,
                value: _percent(metrics.usageRate!),
              ),
            _MetricPill(
              label: loc.statsAverageStars,
              value: metrics.averageStars.toStringAsFixed(2),
            ),
            _MetricPill(
              label: loc.statsAverageDestruction,
              value: _percent(metrics.averageDestruction),
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
    final rates = [
      metrics.zeroStarRate,
      metrics.oneStarRate,
      metrics.twoStarRate,
      metrics.threeStarRate,
    ];
    final colors = [Colors.grey, Colors.orange, Colors.blue, Colors.green];
    return Column(
      children: List.generate(
        4,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              SizedBox(width: 28, child: Text('$index★')),
              Expanded(
                child: LinearProgressIndicator(
                  value: _asPercentValue(rates[index]).clamp(0, 100) / 100,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(99),
                  color: colors[index],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 52,
                child: Text(_percent(rates[index]), textAlign: TextAlign.end),
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
    return Semantics(
      label:
          '${AppLocalizations.of(context)!.statsDailyTrend}: '
          '${points.length}',
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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        ),
      ),
    );
  }
}

class _SearchAndFilter extends StatelessWidget {
  const _SearchAndFilter({
    required this.hint,
    required this.onChanged,
    required this.onFilter,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.tonalIcon(
          onPressed: onFilter,
          icon: const Icon(Icons.tune_rounded),
          label: Text(AppLocalizations.of(context)!.statsCustomLens),
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
    return DropdownButtonFormField<int?>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: opponent ? loc.statsOpponentTownHall : loc.statsTownHall,
      ),
      items: [
        if (allowAll)
          DropdownMenuItem<int?>(
            value: null,
            child: Text(loc.statsAllTownHalls),
          ),
        ...List.generate(12, (index) => 18 - index).map(
          (value) =>
              DropdownMenuItem<int?>(value: value, child: Text('TH$value')),
        ),
      ],
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
    return DropdownButtonFormField<int?>(
      initialValue: value,
      decoration: InputDecoration(labelText: loc.statsLeagueTier),
      items: [
        if (optional)
          DropdownMenuItem<int?>(value: null, child: Text(loc.generalAll)),
        ...List.generate(10, (index) => index + 1).map(
          (tier) => DropdownMenuItem<int?>(
            value: tier,
            child: Text(
              tier == 1
                  ? loc.statsLegendLeagueOne
                  : '${loc.statsLeagueTier} $tier',
            ),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.36),
        ),
      ),
      child: child,
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label  $value',
        style: const TextStyle(fontWeight: FontWeight.w800),
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
    final color = error ? scheme.errorContainer : scheme.secondaryContainer;
    final foreground = error
        ? scheme.onErrorContainer
        : scheme.onSecondaryContainer;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: foreground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: foreground)),
          ),
        ],
      ),
    );
  }
}

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

const _cwlLeagues = <int, String>{
  48000000: 'Bronze III',
  48000001: 'Bronze II',
  48000002: 'Bronze I',
  48000003: 'Silver III',
  48000004: 'Silver II',
  48000005: 'Silver I',
  48000006: 'Gold III',
  48000007: 'Gold II',
  48000008: 'Gold I',
  48000009: 'Crystal III',
  48000010: 'Crystal II',
  48000011: 'Crystal I',
  48000012: 'Master III',
  48000013: 'Master II',
  48000014: 'Master I',
  48000015: 'Champion III',
  48000016: 'Champion II',
  48000017: 'Champion I',
};
