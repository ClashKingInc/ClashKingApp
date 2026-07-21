import 'dart:math' as math;

import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/stats/models/stats_models.dart';
import 'package:clashkingapp/features/stats/presentation/stats_provider.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
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
    final loc = AppLocalizations.of(context)!;
    final provider = context.watch<StatsProvider>();
    return SidePageScaffold(
      title: loc.sideStatsTitle,
      subtitle: loc.sideStatsSubtitle,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                SidePageHorizontalSelector<StatsSection>(
                  values: StatsSection.values,
                  selected: provider.section,
                  labelBuilder: (section) => _sectionLabel(loc, section),
                  onSelected: provider.selectSection,
                ),
                const SizedBox(height: 10),
                _DateRangeControl(provider: provider),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: KeyedSubtree(
                key: ValueKey(provider.section),
                child: switch (provider.section) {
                  StatsSection.overview => const _OverviewSection(),
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
    );
  }
}

String _sectionLabel(AppLocalizations loc, StatsSection section) =>
    switch (section) {
      StatsSection.overview => loc.statsOverview,
      StatsSection.armies => loc.statsArmies,
      StatsSection.items => loc.statsItems,
      StatsSection.war => loc.statsWar,
      StatsSection.cwl => loc.statsCwl,
      StatsSection.ranked => loc.statsRanked,
    };

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
  });

  final StatsSection section;
  final Widget Function(Object data) builder;
  final String? emptyTitle;
  final String? emptyBody;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StatsProvider>();
    final state = provider.stateFor(section);
    final loc = AppLocalizations.of(context)!;

    if (state.status == StatsLoadStatus.loading && state.data == null) {
      return ListView(
        padding: sidePagePadding,
        children: const [SidePageLoadingRows()],
      );
    }
    if (state.status == StatsLoadStatus.error && state.data == null) {
      return ListView(
        padding: sidePagePadding,
        children: [
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
            const SizedBox(height: 20),
            _MetricsCard(title: loc.statsRanked, metrics: overview.ranked),
            const SizedBox(height: 12),
            _MetricsCard(title: loc.statsWar, metrics: overview.war),
            const SizedBox(height: 12),
            _MetricsCard(title: loc.statsCwl, metrics: overview.cwl),
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
                children: filtered
                    .map((army) => _ArmyCard(army: army))
                    .toList(),
              );
            },
          ),
        ),
      ],
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
              loc.generalFilters,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: controls,
        ),
        Expanded(
          child: _SectionFrame(
            section: section,
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
          ),
        ),
      ],
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
                  value: rates[index].clamp(0, 100) / 100,
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
    return Semantics(
      label:
          '${AppLocalizations.of(context)!.statsDailyTrend}: '
          '${points.length}',
      child: SizedBox(
        height: 92,
        width: double.infinity,
        child: CustomPaint(
          painter: _TrendPainter(
            values: points.map((point) => point.threeStarRate).toList(),
            color: Theme.of(context).colorScheme.primary,
            gridColor: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter({
    required this.values,
    required this.color,
    required this.gridColor,
  });

  final List<double> values;
  final Color color;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = gridColor.withValues(alpha: 0.5);
    for (var i = 0; i <= 2; i++) {
      final y = size.height * i / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (values.isEmpty) return;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1 ? 0.0 : size.width * i / (values.length - 1);
      final y = size.height * (1 - values[i].clamp(0, 100) / 100);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
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
        IconButton.filledTonal(
          tooltip: AppLocalizations.of(context)!.generalFilters,
          onPressed: onFilter,
          icon: const Icon(Icons.tune_rounded),
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
  final normalized = value.abs() <= 1 && value != 0 ? value * 100 : value;
  return '${normalized.toStringAsFixed(normalized >= 10 ? 1 : 2)}%';
}

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
