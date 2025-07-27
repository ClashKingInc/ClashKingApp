import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/common/widgets/loading/skeleton_loading.dart';
import 'package:clashkingapp/features/player/presentation/war_stats/widgets/th_heatmap_chart.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/models/player_war_stats.dart';
import 'package:clashkingapp/features/player/models/war_stats_filter.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/presentation/war_stats/player_war_attacks_tab.dart';
import 'package:clashkingapp/features/player/presentation/war_stats/player_war_stats_tab.dart';
import 'package:clashkingapp/features/player/presentation/war_stats/player_war_stats_header.dart';
import 'package:clashkingapp/features/player/presentation/war_stats/war_stats_filter_dialog.dart';
import 'package:clashkingapp/features/player/services/player_war_export_service.dart';
import 'package:open_filex/open_filex.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';
import 'package:provider/provider.dart';

class PlayerWarStatsScreen extends StatefulWidget {
  final Player player;

  const PlayerWarStatsScreen({super.key, required this.player});

  @override
  State<PlayerWarStatsScreen> createState() => _PlayerWarStatsScreenState();
}

class _PlayerWarStatsScreenState extends State<PlayerWarStatsScreen> {
  bool isCWLChecked = true;
  bool isRandomChecked = true;
  bool isFriendlyChecked = true;
  WarStatsFilter _currentFilter = WarStatsFilter.defaultFilter();
  PlayerWarStats? _filteredWarStats;
  bool _isLoadingFiltered = false;
  bool _hasAppliedFilters = false;

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

  Future<void> _refreshData() async {
    try {
      // If we have active filters, re-apply them
      if (_hasAppliedFilters) {
        await _applyFilters(_currentFilter);
      }
      
      setState(() {
        // Update the widget's player data would require parent state management
        // For now, we'll just refresh the filtered data
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data refreshed successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getFilterSummary() {
    if (!(_currentFilter.hasActiveFilters())) {
      return AppLocalizations.of(context)!.filtersNoneApplied;
    }
    return _currentFilter.getFilterSummary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
            PlayerWarStatsHeader(
              name: widget.player.name,
              tag: widget.player.tag,
              picture: ImageAssets.townHall(widget.player.townHallLevel),
              isCWLChecked: isCWLChecked,
              isRandomChecked: isRandomChecked,
              isFriendlyChecked: isFriendlyChecked,
              onCWLChanged: () {
                setState(() => isCWLChecked = !isCWLChecked);
              },
              onRandomChanged: () {
                setState(() => isRandomChecked = !isRandomChecked);
              },
              onFriendlyChanged: () {
                setState(() => isFriendlyChecked = !isFriendlyChecked);
              },
              onBack: () => Navigator.of(context).pop(),
              onFilter: _showFilterDialog,
              onExport: _showExportDialog,
              hasActiveFilters: _currentFilter.hasActiveFilters(),
            ),
            _isLoadingFiltered
                ? Column(
                    children: [
                      const SizedBox(height: 16),
                      // Skeleton loading for stat cards
                      Row(
                        children: [
                          Expanded(child: const StatCardSkeleton()),
                          const SizedBox(width: 8),
                          Expanded(child: const StatCardSkeleton()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Skeleton loading for attack cards
                      ...List.generate(3, (index) => const WarStatsSkeletonCard()),
                    ],
                  )
                : _hasAppliedFilters && _filteredWarStats == null
                    ? _buildNoFilteredResultsWidget()
                    : _displayedWarStats != null
                        ? Column(
                            children: [
                              ScrollableTab(
                            tabBarDecoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                            ),
                            labelColor: Theme.of(context).colorScheme.onSurface,
                            labelPadding: EdgeInsets.zero,
                            labelStyle: Theme.of(context).textTheme.bodyLarge,
                            unselectedLabelColor:
                                Theme.of(context).colorScheme.onSurface,
                            onTap: (value) {
                              setState(() {});
                            },
                            tabs: [
                              Tab(text: AppLocalizations.of(context)!.generalStats),
                              Tab(text: AppLocalizations.of(context)!.generalDetails),
                              Tab(text: AppLocalizations.of(context)!.generalCharts),
                            ],
                            children: [
                              Column(
                                children: [
                                  // Filter bandeau under tabs
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12.0),
                                    margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(8.0),
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _hasAppliedFilters ? Icons.filter_alt : Icons.info_outline,
                                          size: 16,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _hasAppliedFilters 
                                                ? _getFilterSummary()
                                                : AppLocalizations.of(context)?.filtersShowingDefaultData(_currentFilter.limit) ?? 'Showing last ${_currentFilter.limit} wars (default)',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                        if (_hasAppliedFilters)
                                          IconButton(
                                            icon: Icon(
                                              Icons.close,
                                              size: 16,
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                            onPressed: _clearFilters,
                                          ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.tune,
                                            size: 16,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                          onPressed: _showFilterDialog,
                                        ),
                                      ],
                                    ),
                                  ),
                                  WarStatsView(
                                    warStats: _displayedWarStats,
                                    filterTypes: _getSelectedTypes(),
                                    currentSeasonDate: DateTime.now(),
                                    warDataLimit: 0,
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  // Filter bandeau under tabs
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12.0),
                                    margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(8.0),
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _hasAppliedFilters ? Icons.filter_alt : Icons.info_outline,
                                          size: 16,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _hasAppliedFilters 
                                                ? _getFilterSummary()
                                                : AppLocalizations.of(context)?.filtersShowingDefaultData(_currentFilter.limit) ?? 'Showing last ${_currentFilter.limit} wars (default)',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                        if (_hasAppliedFilters)
                                          IconButton(
                                            icon: Icon(
                                              Icons.close,
                                              size: 16,
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                            onPressed: _clearFilters,
                                          ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.tune,
                                            size: 16,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                          onPressed: _showFilterDialog,
                                        ),
                                      ],
                                    ),
                                  ),
                                  PlayerWarAttacksTab(
                                    wars: _filteredWars,
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  // Filter bandeau under tabs
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12.0),
                                    margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(8.0),
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _hasAppliedFilters ? Icons.filter_alt : Icons.info_outline,
                                          size: 16,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _hasAppliedFilters 
                                                ? _getFilterSummary()
                                                : AppLocalizations.of(context)?.filtersShowingDefaultData(_currentFilter.limit) ?? 'Showing last ${_currentFilter.limit} wars (default)',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                        if (_hasAppliedFilters)
                                          IconButton(
                                            icon: Icon(
                                              Icons.close,
                                              size: 16,
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                            onPressed: _clearFilters,
                                          ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.tune,
                                            size: 16,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                          onPressed: _showFilterDialog,
                                        ),
                                      ],
                                    ),
                                  ),
                                  _buildPerformanceChartsTab(),
                                ],
                              ),
                            ],
                          ),
                        ],
                      )
                    : Center(
                        child: Text(AppLocalizations.of(context)?.generalNoDataAvailable ??
                            'No data'),
                      ),
            ],
          ),
        ),
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
              child: Text(AppLocalizations.of(context)?.exportTitle ?? 'Export War Statistics'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)?.exportDialogDesc ?? 'This will download your war statistics as an Excel file with multiple sheets including overall stats, detailed attacks, and TH analysis.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            
            // Export info
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
            child: Text(AppLocalizations.of(context)?.generalCancel ?? 'Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _performExport();
            },
            icon: const Icon(Icons.download),
            label: Text(AppLocalizations.of(context)?.generalExport ?? 'Export'),
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

      setState(() {
        _filteredWarStats = filteredStats;
        _isLoadingFiltered = false;
      });
      
      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text('Filters applied successfully'),
              ],
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingFiltered = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to load filtered data: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
          ),
        );
      }
    }
  }

  void _applyFilter(WarStatsFilter filter) async {
    await _applyFilters(filter);
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
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Attack Performance Heatmap
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
          
          // Defense Performance Heatmap
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
      ),
    );
  }

  Widget _buildNoFilteredResultsWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Filter icon
            Icon(
              Icons.filter_alt_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            
            // Title
            Text(
              AppLocalizations.of(context)!.generalNoFilteredResults,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // Description
            Text(
              AppLocalizations.of(context)!.generalAdjustFilters,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Current filter summary
            if (_hasAppliedFilters) ...[
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
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
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Clear filters button
                ElevatedButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear),
                  label: Text(AppLocalizations.of(context)!.generalClearFilters),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Adjust filters button
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
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
      // Show loading snackbar
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
              Text(AppLocalizations.of(context)?.exportGenerating ?? 'Generating export...'),
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
      
      // Dismiss the loading snackbar before showing success
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showExportSuccess(file.path);
    } catch (e) {
      // Dismiss the loading snackbar before showing error
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
            Text(AppLocalizations.of(context)?.exportSuccess ?? 'Export successful!'),
            const SizedBox(height: 4),
            Text(
              'Saved to: $filePath',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: AppLocalizations.of(context)?.exportOpen ?? 'Open',
          textColor: Theme.of(context).colorScheme.primary,
          onPressed: () => OpenFilex.open(filePath),
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  void _showExportError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export failed: $error'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
