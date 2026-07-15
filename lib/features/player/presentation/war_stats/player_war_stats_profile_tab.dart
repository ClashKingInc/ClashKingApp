import 'dart:async';

import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/loading/skeleton_loading.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/liquid_glass.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/utils/file_opener.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/models/player_war_stats.dart';
import 'package:clashkingapp/features/player/models/war_stats_filter.dart';
import 'package:clashkingapp/features/player/presentation/war_stats/player_war_attacks_tab.dart';
import 'package:clashkingapp/features/player/presentation/war_stats/player_war_stats_tab.dart';
import 'package:clashkingapp/features/player/presentation/war_stats/war_stats_filter_dialog.dart';
import 'package:clashkingapp/features/player/presentation/war_stats/widgets/th_heatmap_chart.dart';
import 'package:clashkingapp/features/player/services/player_war_export_service.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/common/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// War stats as a profile tab — content only, no hero header (the outer
/// [PlayerScreen] already shows name/tag/back button) and a single segmented
/// control for Stats/Attacks/Defenses/Charts.
class PlayerWarStatsProfileTab extends StatefulWidget {
  final Player player;

  const PlayerWarStatsProfileTab({super.key, required this.player});

  @override
  State<PlayerWarStatsProfileTab> createState() =>
      _PlayerWarStatsProfileTabState();
}

class _PlayerWarStatsProfileTabState extends State<PlayerWarStatsProfileTab> {
  bool isCWLChecked = true;
  bool isRandomChecked = true;
  bool isFriendlyChecked = true;
  WarStatsFilter _currentFilter = WarStatsFilter.defaultFilter();
  PlayerWarStats? _filteredWarStats;
  bool _isLoadingFiltered = false;
  bool _hasAppliedFilters = false;
  int _section = 0;

  List<String> _getSelectedTypes() {
    final List<String> selected = [];
    if (isCWLChecked) selected.add("cwl");
    if (isRandomChecked) selected.add("random");
    if (isFriendlyChecked) selected.add("friendly");

    // If all types are selected, return empty list to use 'all' data
    // This ensures consistency between "no filters" and "all filters selected"
    if (selected.length == 3) {
      return [];
    }

    return selected;
  }

  List<PlayerWarStatsData> get _filteredWars {
    final wars = (_hasAppliedFilters && _filteredWarStats != null)
        ? _filteredWarStats!.wars
        : widget.player.warStats?.wars;

    if (wars == null) return [];

    return wars.where((war) {
      final type = war.warDetails.warType?.toLowerCase();
      return (isCWLChecked && type == "cwl") ||
          (isRandomChecked && type == "random") ||
          (isFriendlyChecked && type == "friendly");
    }).toList();
  }

  PlayerWarStats? get _displayedWarStats {
    return (_hasAppliedFilters && _filteredWarStats != null)
        ? _filteredWarStats!
        : widget.player.warStats;
  }

  String _getFilterSummary() {
    if (!(_currentFilter.hasActiveFilters())) {
      return AppLocalizations.of(context)!.filtersNoneApplied;
    }
    return _currentFilter.getFilterSummary(context);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Column(
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LiquidGlassSegmentedControl<int>(
            values: const [0, 1, 2, 3],
            labels: [
              loc.generalStats,
              loc.warAttacksTitle,
              loc.warDefensesTitle,
              loc.generalCharts,
            ],
            selected: _section,
            onChanged: (value) => setState(() => _section = value),
            height: 44,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildFilterBanner(),
        ),
        const SizedBox(height: 8),
        _isLoadingFiltered
            ? Column(
                children: [
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: const StatCardSkeleton()),
                      const SizedBox(width: 8),
                      Expanded(child: const StatCardSkeleton()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(3, (index) => const WarStatsSkeletonCard()),
                ],
              )
            : _hasAppliedFilters && _filteredWarStats == null
            ? _buildNoFilteredResultsWidget()
            : _displayedWarStats != null
            ? AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                child: KeyedSubtree(
                  key: ValueKey(_section),
                  child: switch (_section) {
                    0 => WarStatsView(
                      warStats: _displayedWarStats,
                      filterTypes: _getSelectedTypes(),
                      currentSeasonDate: DateTime.now(),
                      warDataLimit: 0,
                    ),
                    1 => PlayerWarAttacksTab(
                      wars: _filteredWars,
                      stats: _displayedWarStats!.getStatsForTypes(
                        _getSelectedTypes(),
                      ),
                      type: "attacks",
                    ),
                    2 => PlayerWarAttacksTab(
                      wars: _filteredWars,
                      stats: _displayedWarStats!.getStatsForTypes(
                        _getSelectedTypes(),
                      ),
                      type: "defenses",
                    ),
                    _ => _buildPerformanceChartsTab(),
                  },
                ),
              )
            : AppEmptyState(
                title: loc.generalNoDataAvailable,
                icon: Icons.history_toggle_off_rounded,
              ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildFilterBanner() {
    final loc = AppLocalizations.of(context)!;

    return _WarStatsFilterBar(
      chips: [
        _WarTypeChip(
          label: loc.cwlTitle,
          imageUrl: ImageAssets.cwlSwordsNoBorder,
          selected: isCWLChecked,
          onTap: () => setState(() => isCWLChecked = !isCWLChecked),
        ),
        _WarTypeChip(
          label: loc.warFiltersRandom,
          icon: Icons.shuffle_rounded,
          selected: isRandomChecked,
          onTap: () => setState(() => isRandomChecked = !isRandomChecked),
        ),
        _WarTypeChip(
          label: loc.warFiltersFriendly,
          icon: Icons.handshake_rounded,
          selected: isFriendlyChecked,
          onTap: () => setState(() => isFriendlyChecked = !isFriendlyChecked),
        ),
      ],
      middle: _FilterSummaryText(
        icon: _hasAppliedFilters ? Icons.filter_alt : Icons.info_outline,
        text: _hasAppliedFilters
            ? _getFilterSummary()
            : AppLocalizations.of(
                    context,
                  )?.filtersShowingDefaultData(_currentFilter.limit) ??
                  'Showing last ${_currentFilter.limit} wars (default)',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_hasAppliedFilters) ...[
            _IconPillButton(
              icon: Icons.close,
              tooltip: loc.generalClearFilters,
              onTap: _clearFilters,
            ),
            const SizedBox(width: 8),
          ],
          _IconPillButton(
            icon: Icons.tune,
            tooltip: loc.generalFilters,
            onTap: _showFilterDialog,
          ),
          const SizedBox(width: 8),
          _IconPillButton(
            icon: Icons.download_outlined,
            tooltip: loc.generalExport,
            onTap: _showExportDialog,
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => WarStatsFilterDialog(
        initialFilter: _currentFilter,
        onApply: _applyFilter,
        warStats: widget.player.warStats,
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.download_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)?.exportTitle ??
                    'Export War Statistics',
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)?.exportDialogDesc ??
                  'This will download your war statistics as an Excel file with multiple sheets including overall stats, detailed attacks, and TH analysis.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Player', widget.player.name),
                  _buildInfoRow('Format', 'Excel (.xlsx)'),
                  _buildInfoRow('Includes', 'Stats, attacks, TH analysis'),
                  if (_hasAppliedFilters)
                    _buildInfoRow('Filters', _getFilterSummary()),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)?.generalCancel ?? 'Cancel',
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _performExport();
            },
            icon: const Icon(Icons.download),
            label: Text(
              AppLocalizations.of(context)?.generalExport ?? 'Export',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _applyFilters(WarStatsFilter filter) async {
    setState(() {
      _currentFilter = filter;
      _isLoadingFiltered = true;
      _hasAppliedFilters = true;
    });

    try {
      final playerService = Provider.of<PlayerService>(context, listen: false);
      final filteredStats = await playerService.loadPlayerWarStatsWithFilter(
        widget.player.tag,
        filter,
      );

      if (!mounted) return;
      setState(() {
        _filteredWarStats = filteredStats;
        _isLoadingFiltered = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingFiltered = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(
                        context,
                      )?.warStatsFilterFailed(e.toString()) ??
                      'Failed to load filtered data: $e',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        ),
      );
    }
  }

  void _applyFilter(WarStatsFilter filter) {
    unawaited(_applyFilters(filter));
  }

  void _clearFilters() {
    setState(() {
      _currentFilter = WarStatsFilter.defaultFilter();
      _filteredWarStats = null;
      _hasAppliedFilters = false;
    });
  }

  Widget _buildPerformanceChartsTab() {
    if (_displayedWarStats == null) {
      return AppEmptyState(
        title: AppLocalizations.of(context)!.generalNoDataAvailable,
        icon: Icons.history_toggle_off_rounded,
      );
    }

    final selectedTypes = _getSelectedTypes();
    final stats = _displayedWarStats!.getStatsForTypes(selectedTypes);
    final loc = AppLocalizations.of(context)!;

    return Column(
      children: [
        _WarChartsGuide(
          hints: [
            _WarChartHint(
              icon: Icons.grid_on_rounded,
              label: loc.chartsRowsYourTh,
            ),
            _WarChartHint(icon: Icons.star_rounded, label: loc.warStarsAverage),
          ],
        ),
        _WarChartSection(
          title: loc.warAttacksTitle,
          subtitle: loc.chartsAttackPerformance,
          child: THHeatmapChart(
            attackStats: stats.byEnemyTownhall,
            defenseStats: stats.byEnemyTownhallDef,
            playerThLevel: widget.player.townHallLevel,
            showDefense: false,
          ),
        ),
        _WarChartSection(
          title: loc.warDefensesTitle,
          subtitle: loc.chartsDefensePerformance,
          child: THHeatmapChart(
            attackStats: stats.byEnemyTownhall,
            defenseStats: stats.byEnemyTownhallDef,
            playerThLevel: widget.player.townHallLevel,
            showDefense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildNoFilteredResultsWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_alt_off,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.generalNoFilteredResults,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.8),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.generalAdjustFilters,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_hasAppliedFilters) ...[
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_alt,
                      size: 16,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _getFilterSummary(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear),
                  label: Text(
                    AppLocalizations.of(context)!.generalClearFilters,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _showFilterDialog,
                  icon: const Icon(Icons.tune),
                  label: Text(AppLocalizations.of(context)!.generalFilters),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performExport() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onInverseSurface,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)?.exportGenerating ??
                    'Generating export...',
              ),
            ],
          ),
          duration: const Duration(seconds: 30),
        ),
      );

      final file = await PlayerWarExportService.exportWarStats(
        playerTag: widget.player.tag,
        filter: _hasAppliedFilters ? _currentFilter : null,
        playerName: widget.player.name,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showExportSuccess(file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showExportError(e.toString());
    }
  }

  void _showExportSuccess(String filePath) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)?.exportSuccess ??
                  'Export successful!',
            ),
            const SizedBox(height: 4),
            Text(
              'Saved to: $filePath',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: AppLocalizations.of(context)?.generalOpen ?? 'Open',
          textColor: Theme.of(context).colorScheme.primary,
          onPressed: () => openLocalFile(filePath),
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  void _showExportError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)?.warStatsExportFailed(error) ??
              'Export failed: $error',
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

class _WarChartSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _WarChartSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color:
            Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _WarChartsGuide extends StatelessWidget {
  final List<_WarChartHint> hints;

  const _WarChartsGuide({required this.hints});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: hints
                .map((hint) => _WarChartHintChip(hint: hint))
                .toList(),
          ),
          const SizedBox(height: 8),
          _WarChartLegend(
            items: [
              _WarChartLegendItem(
                label: loc.generalPoor,
                color: Colors.red[600]!,
              ),
              _WarChartLegendItem(
                label: loc.generalAverage,
                color: Colors.orange[600]!,
              ),
              _WarChartLegendItem(
                label: loc.chartsGood,
                color: Colors.amber[600]!,
              ),
              _WarChartLegendItem(
                label: loc.chartsExcellent,
                color: Colors.green[600]!,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WarChartHint {
  final IconData icon;
  final String label;

  const _WarChartHint({required this.icon, required this.label});
}

class _WarChartHintChip extends StatelessWidget {
  final _WarChartHint hint;

  const _WarChartHintChip({required this.hint});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(hint.icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            hint.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _WarChartLegend extends StatelessWidget {
  final List<_WarChartLegendItem> items;

  const _WarChartLegend({required this.items});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WarChartScaleRow(
            icon: Icons.trending_up_rounded,
            title: loc.warAttacksTitle,
            startStars: 0,
            startLabel: loc.generalPoor,
            endStars: 3,
            endLabel: loc.chartsExcellent,
            items: items,
          ),
          const SizedBox(height: 10),
          _WarChartScaleRow(
            icon: Icons.trending_down_rounded,
            title: loc.warDefensesTitle,
            startStars: 3,
            startLabel: loc.generalPoor,
            endStars: 0,
            endLabel: loc.chartsExcellent,
            items: items,
          ),
        ],
      ),
    );
  }
}

class _WarChartLegendItem {
  final String label;
  final Color color;

  const _WarChartLegendItem({required this.label, required this.color});
}

class _WarChartScaleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final int startStars;
  final String startLabel;
  final int endStars;
  final String endLabel;
  final List<_WarChartLegendItem> items;

  const _WarChartScaleRow({
    required this.icon,
    required this.title,
    required this.startStars,
    required this.startLabel,
    required this.endStars,
    required this.endLabel,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.24),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 13, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 5),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${AppLocalizations.of(context)!.warStarsAverage}: $startStars-$endStars',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Row(
            children: items
                .map(
                  (item) =>
                      Expanded(child: Container(height: 8, color: item.color)),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            _WarChartScaleEndpoint(stars: startStars, label: startLabel),
            _WarChartScaleEndpoint(
              stars: endStars,
              label: endLabel,
              alignEnd: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _WarChartScaleEndpoint extends StatelessWidget {
  final int stars;
  final String label;
  final bool alignEnd;

  const _WarChartScaleEndpoint({
    required this.stars,
    required this.label,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Row(
        mainAxisAlignment: alignEnd
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            stars.toString(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(width: 2),
          Icon(Icons.star_rounded, size: 11, color: colorScheme.primary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarStatsFilterBar extends StatefulWidget {
  final List<Widget> chips;
  final Widget middle;
  final Widget trailing;

  const _WarStatsFilterBar({
    required this.chips,
    required this.middle,
    required this.trailing,
  });

  @override
  State<_WarStatsFilterBar> createState() => _WarStatsFilterBarState();
}

class _WarStatsFilterBarState extends State<_WarStatsFilterBar> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.chip),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Container(
                    height: 40,
                    width: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _expanded
                          ? colorScheme.primary.withValues(alpha: 0.14)
                          : colorScheme.surfaceContainerHighest.withValues(
                              alpha: 0.45,
                            ),
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                      border: Border.all(
                        color: _expanded
                            ? colorScheme.primary.withValues(alpha: 0.4)
                            : colorScheme.outlineVariant.withValues(
                                alpha: 0.32,
                              ),
                      ),
                    ),
                    child: Icon(
                      Icons.filter_list_rounded,
                      size: 18,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Align(alignment: Alignment.center, child: widget.middle),
              ),
              widget.trailing,
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topLeft,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.chips,
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _FilterSummaryText extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FilterSummaryText({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconPillButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconPillButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          onTap: onTap,
          child: Container(
            height: 40,
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.45,
              ),
              borderRadius: BorderRadius.circular(AppRadius.chip),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.32),
              ),
            ),
            child: Icon(icon, size: 18, color: colorScheme.onSurface),
          ),
        ),
      ),
    );
  }
}

/// Same compact war-type chip visual recipe as the clan War Log filters.
class _WarTypeChip extends StatelessWidget {
  const _WarTypeChip({
    required this.label,
    this.icon,
    this.imageUrl,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final String? imageUrl;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.primary;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        splashFactory: NoSplash.splashFactory,
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.16)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.42)
                  : colorScheme.outlineVariant.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imageUrl != null) ...[
                MobileWebImage(imageUrl: imageUrl!, height: 15, width: 15),
                const SizedBox(width: 5),
              ] else if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: selected ? accent : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
