import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/models/player_war_stats.dart';
import 'package:clashkingapp/features/player/models/war_stats_filter.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/presentation/war_stats/player_war_attacks_tab.dart';
import 'package:clashkingapp/features/player/presentation/war_stats/player_war_stats_tab.dart';
import 'package:clashkingapp/features/player/presentation/war_stats/player_war_stats_header.dart';
import 'package:clashkingapp/features/player/presentation/war_stats/war_stats_filter_dialog.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
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
              hasActiveFilters: _hasAppliedFilters,
            ),
            _isLoadingFiltered
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _displayedWarStats != null
                    ? Column(
                        children: [
                          if (_hasAppliedFilters)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12.0),
                              margin: const EdgeInsets.symmetric(horizontal: 16.0),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.filter_alt,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _currentFilter.getFilterSummary(),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                    onPressed: _clearFilters,
                                  ),
                                ],
                              ),
                            ),
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
                            ],
                            children: [
                              WarStatsView(
                                warStats: _displayedWarStats,
                                filterTypes: _getSelectedTypes(),
                                currentSeasonDate: DateTime.now(),
                                warDataLimit: 0,
                              ),
                              PlayerWarAttacksTab(
                                wars: _filteredWars,
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
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => WarStatsFilterDialog(
        initialFilter: _currentFilter,
        onApply: _applyFilter,
      ),
    );
  }

  void _applyFilter(WarStatsFilter filter) async {
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
    } catch (e) {
      setState(() {
        _isLoadingFiltered = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load filtered data: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _currentFilter = WarStatsFilter.defaultFilter();
      _filteredWarStats = null;
      _hasAppliedFilters = false;
    });
  }
}
