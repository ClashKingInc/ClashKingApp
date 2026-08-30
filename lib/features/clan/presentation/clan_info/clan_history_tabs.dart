import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:clashkingapp/common/widgets/empty_state.dart';
import 'package:clashkingapp/common/widgets/loading/skeleton_loading.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/responsive_card_grid.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/clan/models/clan_history.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ClanLeaderboardHistoryTab extends StatefulWidget {
  const ClanLeaderboardHistoryTab({super.key, required this.clanTag});

  final String clanTag;

  @override
  State<ClanLeaderboardHistoryTab> createState() =>
      _ClanLeaderboardHistoryTabState();
}

class _ClanLeaderboardHistoryTabState extends State<ClanLeaderboardHistoryTab> {
  ClanLeaderboardType _type = ClanLeaderboardType.homeVillage;
  _LeaderboardChartMetric _metric = _LeaderboardChartMetric.rank;
  String? _selectedSeason;
  late Future<_LeaderboardViewData> _load;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    _load = _fetchHistory();
  }

  Future<_LeaderboardViewData> _fetchHistory() async {
    final service = context.read<ClanService>();
    final summary = await service.getClanLeaderboardHistorySummary(
      widget.clanTag,
      _type,
    );
    if (summary.seasons.isEmpty) {
      return _LeaderboardViewData(summary: summary);
    }

    final selectedIndex = summary.seasons.indexWhere(
      (season) => season.season == _selectedSeason,
    );
    final startIndex = selectedIndex < 0 ? 0 : selectedIndex;
    _selectedSeason = summary.seasons[startIndex].season;
    final selectedSummaries = _type == ClanLeaderboardType.clanCapital
        ? summary.seasons.skip(startIndex).take(3).toList(growable: false)
        : [summary.seasons[startIndex]];
    final histories = await Future.wait(
      selectedSummaries.map(
        (season) => service.getClanLeaderboardHistory(
          widget.clanTag,
          _type,
          after: season.after,
          before: season.before,
        ),
      ),
    );
    final entries = histories.expand((history) => history.items).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return _LeaderboardViewData(
      summary: summary,
      selectedSummaries: selectedSummaries,
      history: ClanLeaderboardHistory(items: entries),
    );
  }

  Future<void> _refresh() async {
    setState(_loadHistory);
    await _load;
  }

  void _selectType(ClanLeaderboardType type) {
    if (type == _type) return;
    setState(() {
      _type = type;
      _selectedSeason = null;
      _metric = _LeaderboardChartMetric.rank;
      _loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return _HistoryTabFrame<_LeaderboardViewData>(
      future: _load,
      onRefresh: _refresh,
      isEmpty: (data) => data.summary.seasons.isEmpty,
      content: (context, data) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CKSegmentedControl<ClanLeaderboardType>(
            values: ClanLeaderboardType.values,
            labels: [
              loc.gameBaseHome,
              loc.gameBaseBuilder,
              loc.gameClanCapital,
            ],
            selected: _type,
            onChanged: _selectType,
            density: CKControlDensity.compact,
          ),
          const SizedBox(height: CKSpacing.md),
          _SeasonPicker(
            value: _selectedSeason!,
            label: loc.clanRankingsSelectSeason,
            items: data.summary.seasons
                .map(
                  (season) => DropdownMenuItem(
                    value: season.season,
                    child: Text(
                      '${_seasonLabel(season.season, Localizations.localeOf(context).toString())} · ${loc.statsIndexDays(season.daysInTop200)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: (season) {
              if (season == null || season == _selectedSeason) return;
              setState(() {
                _selectedSeason = season;
                _loadHistory();
              });
            },
          ),
          const SizedBox(height: CKSpacing.md),
          _LeaderboardSummaryPanel(
            summaries: data.selectedSummaries,
            type: _type,
          ),
          const SizedBox(height: CKSpacing.md),
          CKSegmentedControl<_LeaderboardChartMetric>(
            values: _LeaderboardChartMetric.values,
            labels: [
              loc.cwlRankTitle,
              switch (_type) {
                ClanLeaderboardType.homeVillage => loc.clanPointsTitle,
                ClanLeaderboardType.builderBase => loc.clanBuilderBasePoints,
                ClanLeaderboardType.clanCapital => loc.clanCapitalPoints,
              },
            ],
            selected: _metric,
            onChanged: (metric) => setState(() => _metric = metric),
            density: CKControlDensity.compact,
          ),
          const SizedBox(height: CKSpacing.md),
          if (data.history.items.isEmpty)
            AppEmptyState(
              icon: Icons.show_chart_rounded,
              title: loc.generalNoDataAvailable,
              padding: EdgeInsets.zero,
            )
          else ...[
            _LeaderboardHistoryChart(
              entries: data.history.items,
              metric: _metric,
              type: _type,
            ),
            const SizedBox(height: CKSpacing.md),
            CKSectionPanel(
              padding: EdgeInsets.zero,
              child: ExpansionTile(
                title: Text(
                  loc.generalHistory,
                  style: CKTypography.of(context, CKTextRole.rowTitle),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(
                  CKSpacing.md,
                  0,
                  CKSpacing.md,
                  CKSpacing.md,
                ),
                children: [
                  for (
                    var index = 0;
                    index < data.history.items.length;
                    index++
                  ) ...[
                    if (index > 0) const Divider(height: CKSpacing.lg),
                    _LeaderboardHistoryRow(
                      entry: data.history.items[index],
                      type: _type,
                      framed: false,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ClanLegendHistoryTab extends StatefulWidget {
  const ClanLegendHistoryTab({super.key, required this.clanTag});

  final String clanTag;

  @override
  State<ClanLegendHistoryTab> createState() => _ClanLegendHistoryTabState();
}

class _ClanLegendHistoryTabState extends State<ClanLegendHistoryTab> {
  static const _topFinishes = '__top_finishes__';

  String? _selectedSeason;
  late Future<_LegendViewData> _load;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    _load = _fetchHistory();
  }

  Future<_LegendViewData> _fetchHistory() async {
    final service = context.read<ClanService>();
    final summary = await service.getClanLegendHistorySummary(widget.clanTag);
    if (summary.seasons.isEmpty) {
      return _LegendViewData(summary: summary, items: summary.topFinishes);
    }
    _selectedSeason ??= summary.seasons.first.season;
    if (_selectedSeason == _topFinishes) {
      return _LegendViewData(summary: summary, items: summary.topFinishes);
    }
    final season = summary.seasons.firstWhere(
      (item) => item.season == _selectedSeason,
      orElse: () => summary.seasons.first,
    );
    _selectedSeason = season.season;
    final history = await service.getClanLegendHistory(
      widget.clanTag,
      after: season.after,
      before: season.before,
    );
    return _LegendViewData(summary: summary, items: history.items);
  }

  Future<void> _refresh() async {
    setState(_loadHistory);
    await _load;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    return _HistoryTabFrame<_LegendViewData>(
      future: _load,
      onRefresh: _refresh,
      isEmpty: (data) => data.summary.seasons.isEmpty && data.items.isEmpty,
      content: (context, data) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SeasonPicker(
            value: _selectedSeason ?? _topFinishes,
            label: loc.clanRankingsSelectSeason,
            items: [
              DropdownMenuItem(
                value: _topFinishes,
                child: Text(loc.generalAllTime),
              ),
              for (final season in data.summary.seasons)
                DropdownMenuItem(
                  value: season.season,
                  child: Text(
                    '${_seasonLabel(season.season, locale)} · ${loc.searchTabPlayers}: ${season.playerCount}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (season) {
              if (season == null || season == _selectedSeason) return;
              setState(() {
                _selectedSeason = season;
                _loadHistory();
              });
            },
          ),
          const SizedBox(height: CKSpacing.md),
          ResponsiveCardGrid(
            itemCount: data.items.length,
            minItemWidth: 430,
            maxColumns: 2,
            spacing: CKSpacing.md,
            itemBuilder: (_, index) => _LegendHistoryRow(
              entry: data.items[index],
              showSeason: _selectedSeason == _topFinishes,
            ),
          ),
        ],
      ),
    );
  }
}

enum _LeaderboardChartMetric { rank, points }

class _LeaderboardViewData {
  const _LeaderboardViewData({
    required this.summary,
    this.selectedSummaries = const [],
    this.history = const ClanLeaderboardHistory(items: []),
  });

  final ClanLeaderboardHistorySummary summary;
  final List<ClanLeaderboardSeasonSummary> selectedSummaries;
  final ClanLeaderboardHistory history;
}

class _LegendViewData {
  const _LegendViewData({required this.summary, required this.items});

  final ClanLegendHistorySummary summary;
  final List<ClanLegendHistoryEntry> items;
}

class ClanRecordsTab extends StatefulWidget {
  const ClanRecordsTab({
    super.key,
    required this.clanTag,
    required this.clanBadgeUrl,
  });

  final String clanTag;
  final String clanBadgeUrl;

  @override
  State<ClanRecordsTab> createState() => _ClanRecordsTabState();
}

class _ClanRecordsTabState extends State<ClanRecordsTab> {
  _ProfileHistoryFilter _filter = _ProfileHistoryFilter.all;
  late Future<_RecordsHistoryViewData> _load;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _load = _fetchData();
  }

  Future<_RecordsHistoryViewData> _fetchData() async {
    final service = context.read<ClanService>();
    final results = await Future.wait<Object>([
      service.getClanRecords(widget.clanTag),
      service.getClanProfileHistory(widget.clanTag),
    ]);
    return _RecordsHistoryViewData(
      records: results[0] as ClanRecords,
      history: results[1] as ClanProfileHistory,
    );
  }

  Future<void> _refresh() async {
    setState(_loadData);
    await _load;
  }

  @override
  Widget build(BuildContext context) {
    return _HistoryTabFrame<_RecordsHistoryViewData>(
      future: _load,
      onRefresh: _refresh,
      isEmpty: (data) => data.records.isEmpty && data.history.items.isEmpty,
      content: (context, data) {
        final recordItems = <Widget>[
          if (data.records.clanPoints case final record?)
            _RecordPanel(
              label: AppLocalizations.of(context)!.clanPointsTitle,
              record: record,
              imageUrl: ImageAssets.bestTrophies,
              accent: CKColors.legendBlue,
            ),
          if (data.records.warWinStreak case final record?)
            _RecordPanel(
              label: AppLocalizations.of(context)!.rankingsWinStreak,
              record: record,
              imageUrl: ImageAssets.war,
              accent: CKColors.warGold,
            ),
        ];
        final historyItems = data.history.items
            .where((change) {
              return switch (_filter) {
                _ProfileHistoryFilter.all => true,
                _ProfileHistoryFilter.description =>
                  change.type == ClanProfileChangeType.description,
                _ProfileHistoryFilter.clanLevel =>
                  change.type == ClanProfileChangeType.clanLevel,
              };
            })
            .toList(growable: false);
        final loc = AppLocalizations.of(context)!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (recordItems.isNotEmpty)
              ResponsiveCardGrid(
                itemCount: recordItems.length,
                minItemWidth: 360,
                maxColumns: 2,
                spacing: CKSpacing.md,
                itemBuilder: (_, index) => recordItems[index],
              ),
            if (recordItems.isNotEmpty && data.history.items.isNotEmpty)
              const SizedBox(height: CKSpacing.xl),
            if (data.history.items.isNotEmpty) ...[
              CKSegmentedControl<_ProfileHistoryFilter>(
                values: _ProfileHistoryFilter.values,
                labels: [
                  loc.generalAll,
                  loc.clanProfileDescriptionChanged,
                  loc.clanProfileLevelChanged,
                ],
                selected: _filter,
                onChanged: (filter) => setState(() => _filter = filter),
                density: CKControlDensity.compact,
              ),
              const SizedBox(height: CKSpacing.md),
              if (historyItems.isEmpty)
                AppEmptyState(
                  icon: Icons.history_toggle_off_rounded,
                  title: loc.generalNoDataAvailable,
                  padding: EdgeInsets.zero,
                )
              else
                ResponsiveCardGrid(
                  itemCount: historyItems.length,
                  minItemWidth: 430,
                  maxColumns: 2,
                  spacing: CKSpacing.md,
                  itemBuilder: (_, index) => _ProfileChangeRow(
                    change: historyItems[index],
                    clanBadgeUrl: widget.clanBadgeUrl,
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

enum _ProfileHistoryFilter { all, description, clanLevel }

class _RecordsHistoryViewData {
  const _RecordsHistoryViewData({required this.records, required this.history});

  final ClanRecords records;
  final ClanProfileHistory history;
}

class _HistoryTabFrame<T> extends StatelessWidget {
  const _HistoryTabFrame({
    required this.future,
    required this.onRefresh,
    required this.isEmpty,
    required this.content,
  });

  final Future<T> future;
  final Future<void> Function() onRefresh;
  final bool Function(T data) isEmpty;
  final Widget Function(BuildContext context, T data) content;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = 16 + MediaQuery.paddingOf(context).bottom;
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return ListView(
            primary: true,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
            children: const [SkeletonList(itemCount: 5)],
          );
        }

        final loc = AppLocalizations.of(context)!;
        if (snapshot.hasError || snapshot.data == null) {
          return ListView(
            primary: true,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              AppEmptyState(
                icon: Icons.cloud_off_rounded,
                title: loc.generalError,
                body: loc.generalTryAgain,
                actionLabel: loc.generalRetry,
                onAction: onRefresh,
              ),
            ],
          );
        }

        final data = snapshot.data as T;
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            primary: true,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 10, 16, bottomPadding),
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: isEmpty(data)
                      ? AppEmptyState(
                          icon: Icons.history_toggle_off_rounded,
                          title: loc.generalNoDataAvailable,
                          padding: EdgeInsets.zero,
                        )
                      : content(context, data),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SeasonPicker extends StatelessWidget {
  const _SeasonPicker({
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final String label;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      menuMaxHeight: 360,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_month_rounded),
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}

class _LeaderboardSummaryPanel extends StatelessWidget {
  const _LeaderboardSummaryPanel({required this.summaries, required this.type});

  final List<ClanLeaderboardSeasonSummary> summaries;
  final ClanLeaderboardType type;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final number = NumberFormat.decimalPattern(locale);
    final days = summaries.fold<int>(
      0,
      (total, season) => total + season.daysInTop200,
    );
    final ranks = summaries
        .map((season) => season.bestRank)
        .where((rank) => rank > 0);
    final bestRank = ranks.isEmpty
        ? 0
        : ranks.reduce((left, right) => left < right ? left : right);
    final peakPoints = summaries.fold<int>(
      0,
      (peak, season) => season.peakPoints > peak ? season.peakPoints : peak,
    );
    final pointsLabel = switch (type) {
      ClanLeaderboardType.homeVillage => loc.clanPointsTitle,
      ClanLeaderboardType.builderBase => loc.clanBuilderBasePoints,
      ClanLeaderboardType.clanCapital => loc.clanCapitalPoints,
    };

    return CKSectionPanel(
      child: Row(
        children: [
          Expanded(
            child: _IconMetric(
              icon: Icons.calendar_today_rounded,
              label: loc.generalHistory,
              value: loc.statsIndexDays(days),
            ),
          ),
          const SizedBox(width: CKSpacing.sm),
          Expanded(
            child: _IconMetric(
              icon: Icons.leaderboard_rounded,
              label: loc.legendsBestRank,
              value: bestRank == 0 ? '—' : '#${number.format(bestRank)}',
            ),
          ),
          const SizedBox(width: CKSpacing.sm),
          Expanded(
            child: _ImageMetric(
              imageUrl: _pointsImage(type),
              label: pointsLabel,
              value: number.format(peakPoints),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardHistoryChart extends StatelessWidget {
  const _LeaderboardHistoryChart({
    required this.entries,
    required this.metric,
    required this.type,
  });

  final List<ClanLeaderboardHistoryEntry> entries;
  final _LeaderboardChartMetric metric;
  final ClanLeaderboardType type;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final number = NumberFormat.compact(locale: locale);
    final spots = <FlSpot>[
      for (var index = 0; index < entries.length; index++)
        FlSpot(
          index.toDouble(),
          metric == _LeaderboardChartMetric.rank
              ? -entries[index].rank.toDouble()
              : entries[index].points.toDouble(),
        ),
    ];
    final accent = switch (type) {
      ClanLeaderboardType.homeVillage => CKColors.legendBlue,
      ClanLeaderboardType.builderBase => CKColors.builderBlue,
      ClanLeaderboardType.clanCapital => CKColors.capitalOrange,
    };

    return CKSectionPanel(
      child: SizedBox(
        height: 250,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: (entries.length - 1).clamp(1, entries.length).toDouble(),
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: scheme.outlineVariant.withValues(alpha: 0.24),
                strokeWidth: 1,
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
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 46,
                  getTitlesWidget: (value, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(
                      metric == _LeaderboardChartMetric.rank
                          ? number.format(-value)
                          : number.format(value),
                      style: CKTypography.of(
                        context,
                        CKTextRole.compactLabel,
                      ).copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: entries.length <= 4
                      ? 1
                      : (entries.length / 4).ceilToDouble(),
                  getTitlesWidget: (value, meta) {
                    final index = value.round();
                    if (index < 0 || index >= entries.length) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        DateFormat.MMMd(locale).format(entries[index].date),
                        style: CKTypography.of(
                          context,
                          CKTextRole.compactLabel,
                        ).copyWith(color: scheme.onSurfaceVariant),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => scheme.surfaceContainerHighest,
                getTooltipItems: (spots) => spots
                    .map((spot) {
                      final entry = entries[spot.x.round()];
                      final value = metric == _LeaderboardChartMetric.rank
                          ? '#${NumberFormat.decimalPattern(locale).format(entry.rank)}'
                          : NumberFormat.decimalPattern(
                              locale,
                            ).format(entry.points);
                      return LineTooltipItem(
                        '${DateFormat.yMMMd(locale).format(entry.date)}\n$value',
                        CKTypography.of(
                          context,
                          CKTextRole.metadata,
                        ).copyWith(color: scheme.onSurface),
                      );
                    })
                    .toList(growable: false),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                color: accent,
                barWidth: 3,
                isCurved: entries.length > 3,
                curveSmoothness: 0.22,
                dotData: FlDotData(show: entries.length <= 36),
                belowBarData: BarAreaData(
                  show: true,
                  color: accent.withValues(alpha: 0.10),
                ),
              ),
            ],
          ),
          duration: CKMotion.durationOf(context, CKMotion.standard),
          curve: CKMotion.standardCurve,
        ),
      ),
    );
  }
}

class _LeaderboardHistoryRow extends StatelessWidget {
  const _LeaderboardHistoryRow({
    required this.entry,
    required this.type,
    this.framed = true,
  });

  final ClanLeaderboardHistoryEntry entry;
  final ClanLeaderboardType type;
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final number = NumberFormat.decimalPattern(locale);
    final pointsLabel = switch (type) {
      ClanLeaderboardType.homeVillage => loc.clanPointsTitle,
      ClanLeaderboardType.builderBase => loc.clanBuilderBasePoints,
      ClanLeaderboardType.clanCapital => loc.clanCapitalPoints,
    };
    final semantics = [
      DateFormat.yMMMd(locale).format(entry.date),
      '${loc.cwlRankTitle}: ${number.format(entry.rank)}',
      '$pointsLabel: ${number.format(entry.points)}',
      '${loc.clanMembers}: ${number.format(entry.members)}',
    ].join('. ');

    final content = Semantics(
      label: semantics,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat.yMMMd(locale).format(entry.date),
                  style: CKTypography.of(context, CKTextRole.rowTitle),
                ),
              ),
              _InlineMetric(
                icon: Icons.leaderboard_rounded,
                value: '#${number.format(entry.rank)}',
              ),
            ],
          ),
          const SizedBox(height: CKSpacing.md),
          Row(
            children: [
              Expanded(
                child: _ImageMetric(
                  imageUrl: _pointsImage(type),
                  label: pointsLabel,
                  value: number.format(entry.points),
                ),
              ),
              const SizedBox(width: CKSpacing.md),
              Expanded(
                child: _IconMetric(
                  icon: Icons.groups_rounded,
                  label: loc.clanMembers,
                  value: number.format(entry.members),
                ),
              ),
            ],
          ),
          if (entry.location?.name case final String locationName
              when locationName.isNotEmpty) ...[
            const SizedBox(height: CKSpacing.md),
            Text(
              locationName,
              style: CKTypography.of(
                context,
                CKTextRole.metadata,
              ).copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
    return framed ? CKSectionPanel(child: content) : content;
  }
}

class _LegendHistoryRow extends StatelessWidget {
  const _LegendHistoryRow({required this.entry, this.showSeason = true});

  final ClanLegendHistoryEntry entry;
  final bool showSeason;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final number = NumberFormat.decimalPattern(locale);
    return CKSectionPanel(
      child: Semantics(
        label:
            '${entry.name}, ${entry.tag}. ${loc.clanRankingsSeason}: '
            '${_seasonLabel(entry.season, locale)}. ${loc.gameTrophies}: '
            '${number.format(entry.trophies)}. ${loc.cwlRankTitle}: '
            '${number.format(entry.rank)}',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SizedBox.square(
                  dimension: 42,
                  child: MobileWebImage(imageUrl: ImageAssets.legendBlazon),
                ),
                const SizedBox(width: CKSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CKTypography.of(context, CKTextRole.rowTitle),
                      ),
                      const SizedBox(height: CKSpacing.xs),
                      Text(
                        showSeason
                            ? '${entry.tag} · ${_seasonLabel(entry.season, locale)}'
                            : entry.tag,
                        style: CKTypography.of(context, CKTextRole.metadata)
                            .copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                _InlineMetric(
                  icon: Icons.leaderboard_rounded,
                  value: '#${number.format(entry.rank)}',
                ),
              ],
            ),
            const SizedBox(height: CKSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _ImageMetric(
                    imageUrl: ImageAssets.trophies,
                    label: loc.gameTrophies,
                    value: number.format(entry.trophies),
                  ),
                ),
                const SizedBox(width: CKSpacing.sm),
                Expanded(
                  child: _ImageMetric(
                    imageUrl: ImageAssets.attacks,
                    label: loc.warAttacksTitle,
                    value: number.format(entry.attackWins),
                  ),
                ),
                const SizedBox(width: CKSpacing.sm),
                Expanded(
                  child: _ImageMetric(
                    imageUrl: ImageAssets.shield,
                    label: loc.warDefensesTitle,
                    value: number.format(entry.defenseWins),
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

class _RecordPanel extends StatelessWidget {
  const _RecordPanel({
    required this.label,
    required this.record,
    required this.imageUrl,
    required this.accent,
  });

  final String label;
  final ClanRecord record;
  final String imageUrl;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final value = NumberFormat.decimalPattern(locale).format(record.value);
    final date = DateFormat.yMMMd(
      locale,
    ).add_jm().format(record.time.toLocal());
    return CKSectionPanel(
      child: Semantics(
        label: '$label: $value. $date',
        excludeSemantics: true,
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: 52,
                child: Padding(
                  padding: const EdgeInsets.all(CKSpacing.md),
                  child: MobileWebImage(imageUrl: imageUrl),
                ),
              ),
            ),
            const SizedBox(width: CKSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: CKTypography.of(context, CKTextRole.metadata)
                        .copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: CKSpacing.xs),
                  Text(
                    value,
                    style: CKTypography.of(context, CKTextRole.screenTitle),
                  ),
                  const SizedBox(height: CKSpacing.xs),
                  Text(
                    date,
                    style: CKTypography.of(context, CKTextRole.metadata)
                        .copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class _ProfileChangeRow extends StatefulWidget {
  const _ProfileChangeRow({required this.change, required this.clanBadgeUrl});

  final ClanProfileChange change;
  final String clanBadgeUrl;

  @override
  State<_ProfileChangeRow> createState() => _ProfileChangeRowState();
}

class _ProfileChangeRowState extends State<_ProfileChangeRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final change = widget.change;
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final title = switch (change.type) {
      ClanProfileChangeType.clanLevel => loc.clanProfileLevelChanged,
      ClanProfileChangeType.description => loc.clanProfileDescriptionChanged,
      ClanProfileChangeType.unknown => loc.clanProfileHistoryTab,
    };
    final previous = change.previous?.toString() ?? loc.generalNotSet;
    final current = change.current?.toString() ?? loc.generalNotSet;
    return CKSectionPanel(
      child: Semantics(
        label: '$title. $previous. $current',
        excludeSemantics: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (change.type == ClanProfileChangeType.clanLevel)
              SizedBox.square(
                dimension: 48,
                child: MobileWebImage(
                  imageUrl: widget.clanBadgeUrl,
                  errorWidget: (_, _, _) => const Icon(Icons.shield_rounded),
                ),
              )
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.36),
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: 44,
                  child: Icon(
                    Icons.notes_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(width: CKSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: CKTypography.of(context, CKTextRole.rowTitle),
                  ),
                  const SizedBox(height: CKSpacing.xs),
                  Text(
                    DateFormat.yMMMd(
                      locale,
                    ).add_jm().format(change.time.toLocal()),
                    style: CKTypography.of(context, CKTextRole.metadata)
                        .copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: CKSpacing.md),
                  if (change.type == ClanProfileChangeType.clanLevel)
                    Row(
                      children: [
                        Text(
                          previous,
                          style:
                              CKTypography.of(
                                context,
                                CKTextRole.screenTitle,
                              ).copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: CKSpacing.sm,
                          ),
                          child: Icon(Icons.arrow_forward_rounded, size: 20),
                        ),
                        Text(
                          current,
                          style: CKTypography.of(
                            context,
                            CKTextRole.screenTitle,
                          ).copyWith(color: CKColors.warGold),
                        ),
                      ],
                    )
                  else ...[
                    _DescriptionDiff(
                      previous: previous,
                      current: current,
                      expanded: _expanded,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        tooltip: _expanded
                            ? loc.generalCollapse
                            : loc.generalExpand,
                        onPressed: () => setState(() => _expanded = !_expanded),
                        icon: Icon(
                          _expanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DescriptionDiff extends StatelessWidget {
  const _DescriptionDiff({
    required this.previous,
    required this.current,
    required this.expanded,
  });

  final String previous;
  final String current;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final diff = _TextDifference.between(previous, current);
    final base = CKTypography.of(context, CKTextRole.body);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            style: base.copyWith(color: scheme.onSurfaceVariant),
            children: [
              TextSpan(text: diff.prefix),
              TextSpan(
                text: diff.removed,
                style: base.copyWith(
                  color: CKColors.lossRed,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              TextSpan(text: diff.suffix),
            ],
          ),
          maxLines: expanded ? null : 3,
          overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        const SizedBox(height: CKSpacing.sm),
        Text.rich(
          TextSpan(
            style: base,
            children: [
              TextSpan(text: diff.prefix),
              TextSpan(
                text: diff.added,
                style: base.copyWith(
                  color: CKColors.donationGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(text: diff.suffix),
            ],
          ),
          maxLines: expanded ? null : 3,
          overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _TextDifference {
  const _TextDifference({
    required this.prefix,
    required this.removed,
    required this.added,
    required this.suffix,
  });

  final String prefix;
  final String removed;
  final String added;
  final String suffix;

  factory _TextDifference.between(String previous, String current) {
    var prefixLength = 0;
    final shortest = previous.length < current.length
        ? previous.length
        : current.length;
    while (prefixLength < shortest &&
        previous.codeUnitAt(prefixLength) == current.codeUnitAt(prefixLength)) {
      prefixLength++;
    }

    var suffixLength = 0;
    while (suffixLength < shortest - prefixLength &&
        previous.codeUnitAt(previous.length - suffixLength - 1) ==
            current.codeUnitAt(current.length - suffixLength - 1)) {
      suffixLength++;
    }
    final previousEnd = previous.length - suffixLength;
    final currentEnd = current.length - suffixLength;
    return _TextDifference(
      prefix: previous.substring(0, prefixLength),
      removed: previous.substring(prefixLength, previousEnd),
      added: current.substring(prefixLength, currentEnd),
      suffix: previous.substring(previousEnd),
    );
  }
}

class _InlineMetric extends StatelessWidget {
  const _InlineMetric({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: CKSpacing.xs),
        Text(value, style: CKTypography.of(context, CKTextRole.rowTitle)),
      ],
    );
  }
}

class _ImageMetric extends StatelessWidget {
  const _ImageMetric({
    required this.imageUrl,
    required this.label,
    required this.value,
  });

  final String imageUrl;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _Metric(
      leading: MobileWebImage(imageUrl: imageUrl, width: 24, height: 24),
      label: label,
      value: value,
    );
  }
}

class _IconMetric extends StatelessWidget {
  const _IconMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _Metric(
      leading: Icon(
        icon,
        size: 22,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      label: label,
      value: value,
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.leading,
    required this.label,
    required this.value,
  });

  final Widget leading;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox.square(dimension: 28, child: Center(child: leading)),
        const SizedBox(width: CKSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CKTypography.of(context, CKTextRole.compactLabel)
                    .copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CKTypography.of(context, CKTextRole.rowTitle),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _pointsImage(ClanLeaderboardType type) => switch (type) {
  ClanLeaderboardType.homeVillage => ImageAssets.trophies,
  ClanLeaderboardType.builderBase => ImageAssets.builderBaseTrophy,
  ClanLeaderboardType.clanCapital => ImageAssets.capitalTrophy,
};

String _seasonLabel(String season, String locale) {
  final normalized = season.startsWith('v2-') ? season.substring(3) : season;
  final parsed = DateTime.tryParse(
    normalized.length == 7 ? '$normalized-01' : normalized,
  );
  if (parsed == null) return season;
  return DateFormat.yMMMM(locale).format(parsed);
}
