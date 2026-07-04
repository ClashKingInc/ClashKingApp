import 'dart:async';

import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/loading/skeleton_loading.dart';
import 'package:clashkingapp/common/widgets/native_liquid_glass.dart';
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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// War stats as a profile tab — content only, no hero header (the outer
/// [PlayerScreen] already shows name/tag/back button) and a segmented
/// control instead of a nested tab bar for Stats/Details/Charts.
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
  bool _warTypesExpanded = false;

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
          child: NativeLiquidGlassSegmentedControl<int>(
            values: const [0, 1, 2],
            labels: [loc.generalStats, loc.generalDetails, loc.generalCharts],
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
                    1 => PlayerWarAttacksTab(wars: _filteredWars),
                    _ => _buildPerformanceChartsTab(),
                  },
                ),
              )
            : Center(child: Text(loc.generalNoDataAvailable)),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildFilterBanner() {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                _hasAppliedFilters ? Icons.filter_alt : Icons.info_outline,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _hasAppliedFilters
                      ? _getFilterSummary()
                      : AppLocalizations.of(context)?.filtersShowingDefaultData(
                              _currentFilter.limit,
                            ) ??
                            'Showing last ${_currentFilter.limit} wars (default)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurface),
                ),
              ),
              if (_hasAppliedFilters)
                IconButton(
                  tooltip: loc.generalClearFilters,
                  icon: Icon(
                    Icons.close,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onPressed: _clearFilters,
                ),
              IconButton(
                tooltip: loc.generalFilters,
                icon: Icon(Icons.tune, size: 16, color: colorScheme.onSurface),
                onPressed: _showFilterDialog,
              ),
              IconButton(
                tooltip: loc.generalExport,
                icon: Icon(
                  Icons.download_outlined,
                  size: 16,
                  color: colorScheme.onSurface,
                ),
                onPressed: _showExportDialog,
              ),
              IconButton(
                tooltip: _warTypesExpanded
                    ? loc.generalCollapse
                    : loc.generalExpand,
                onPressed: () =>
                    setState(() => _warTypesExpanded = !_warTypesExpanded),
                icon: AnimatedRotation(
                  turns: _warTypesExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 18,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          ClipRect(
            child: AnimatedSize(
              alignment: Alignment.topCenter,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: _warTypesExpanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          _WarTypeChip(
                            label: 'CWL',
                            selected: isCWLChecked,
                            onTap: () =>
                                setState(() => isCWLChecked = !isCWLChecked),
                          ),
                          const SizedBox(width: 8),
                          _WarTypeChip(
                            label: loc.warFiltersRandom,
                            selected: isRandomChecked,
                            onTap: () => setState(
                              () => isRandomChecked = !isRandomChecked,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _WarTypeChip(
                            label: loc.warFiltersFriendly,
                            selected: isFriendlyChecked,
                            onTap: () => setState(
                              () => isFriendlyChecked = !isFriendlyChecked,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity, height: 0),
            ),
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
      return const Center(child: Text('No data available'));
    }

    final selectedTypes = _getSelectedTypes();
    final stats = _displayedWarStats!.getStatsForTypes(selectedTypes);

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: THHeatmapChart(
              attackStats: stats.byEnemyTownhall,
              defenseStats: stats.byEnemyTownhallDef,
              playerThLevel: widget.player.townHallLevel,
              showDefense: false,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: THHeatmapChart(
              attackStats: stats.byEnemyTownhall,
              defenseStats: stats.byEnemyTownhallDef,
              playerThLevel: widget.player.townHallLevel,
              showDefense: true,
            ),
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

/// Small selectable glass pill matching the MetricChip/StatTile/
/// FilterDropdown family - tinted when selected instead of the stock
/// Material FilterChip look, which clashed with the rest of the app.
class _WarTypeChip extends StatelessWidget {
  const _WarTypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tint = colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.chip),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? tint.withValues(alpha: 0.16)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(
              color: selected
                  ? tint.withValues(alpha: 0.5)
                  : colorScheme.outlineVariant.withValues(alpha: 0.32),
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
