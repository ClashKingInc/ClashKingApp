import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/clan/models/clan_war_stats.dart';
import 'package:clashkingapp/features/clan/models/clan_war_stats_filter.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/player/models/player_war_stats.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war_stats/clan_war_log.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war_stats/war_stats_players.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war_stats/clan_war_stats_filter_dialog.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/features/player/presentation/war_stats/player_war_stats_header.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';
import 'package:provider/provider.dart';

class ClanWarStatsScreen extends StatefulWidget {
  final Clan clan;

  const ClanWarStatsScreen({super.key, required this.clan});

  @override
  State<ClanWarStatsScreen> createState() => _ClanWarStatsScreenState();
}

class _ClanWarStatsScreenState extends State<ClanWarStatsScreen> {
  bool isCWLChecked = true;
  bool isRandomChecked = true;
  bool isFriendlyChecked = true;
  String _sortBy = "Three Stars Attacks";
  List<PlayerWarStats> filteredPlayers = [];
  ClanWarStatsFilter _currentFilter = ClanWarStatsFilter.defaultFilter();
  ClanWarStats? _filteredClanWarStats;
  bool _isLoadingFiltered = false;
  bool _hasAppliedFilters = false;

  // Track selected Town Hall levels for members and enemies
  Map<int, bool> memberThSelection = {
    for (int i = 1; i <= GameDataService.getMaxTownHallLevel(); i++) i: false
  };
  Map<int, bool> enemyThSelection = {
    for (int i = 1; i <= GameDataService.getMaxTownHallLevel(); i++) i: false
  };

  bool equalThSelected = false;
  bool showUppedTownHall = true;
  List<int> attackerThFilter = [];
  List<int> defenderThFilter = [];

  @override
  void initState() {
    super.initState();
    filteredPlayers = widget.clan.clanWarStats?.players ?? [];
  }

  ClanWarStats? get _displayedClanWarStats {
    return (_hasAppliedFilters && _filteredClanWarStats != null)
        ? _filteredClanWarStats!
        : widget.clan.clanWarStats;
  }

  List<String> _getSelectedTypes() {
    final List<String> selected = [];
    if (isCWLChecked) selected.add("cwl");
    if (isRandomChecked) selected.add("random");
    if (isFriendlyChecked) selected.add("friendly");
    return selected;
  }

  void _resetFilters() {
    setState(() {
      isCWLChecked = true;
      isRandomChecked = true;
      isFriendlyChecked = true;

      memberThSelection = {
        for (int i = 6; i <= GameDataService.getMaxTownHallLevel(); i++)
          i: false
      };
      enemyThSelection = {
        for (int i = 6; i <= GameDataService.getMaxTownHallLevel(); i++)
          i: false
      };
      equalThSelected = false;
      showUppedTownHall = true;

      // Reset to original data or current filtered data
      filteredPlayers = _displayedClanWarStats?.players ?? [];
    });
  }

  void _updateSortBy(String newValue) {
    setState(() {
      _sortBy = newValue;
      _sortMembers();
    });
  }

  void _sortMembers() {
    final List<String> selectedTypes = _getSelectedTypes();

    final playersByTag = {
      for (var player in filteredPlayers) player.tag: player
    };

    filteredPlayers = _displayedClanWarStats?.players
            .where((member) => playersByTag.containsKey(member.tag))
            .toList() ??
        [];

    switch (_sortBy) {
      case "Average Destruction":
        filteredPlayers.sort((a, b) {
          final statB = playersByTag[b.tag]!
              .getStatsForTypes(selectedTypes)
              .averageDestruction;
          final statA = playersByTag[a.tag]!
              .getStatsForTypes(selectedTypes)
              .averageDestruction;
          return statB.compareTo(statA);
        });
        break;
      case "Average Stars":
        filteredPlayers.sort((a, b) {
          final statB =
              playersByTag[b.tag]!.getStatsForTypes(selectedTypes).averageStars;
          final statA =
              playersByTag[a.tag]!.getStatsForTypes(selectedTypes).averageStars;
          return statB.compareTo(statA);
        });
        break;
      case "No Star Attacks":
        filteredPlayers.sort((a, b) {
          final statB = playersByTag[b.tag]!
                  .getStatsForTypes(selectedTypes)
                  .starsCount["0"] ??
              0;
          final statA = playersByTag[a.tag]!
                  .getStatsForTypes(selectedTypes)
                  .starsCount["0"] ??
              0;
          return statB.compareTo(statA);
        });
        break;
      case "One Star Attacks":
        filteredPlayers.sort((a, b) {
          final statB = playersByTag[b.tag]!
                  .getStatsForTypes(selectedTypes)
                  .starsCount["1"] ??
              0;
          final statA = playersByTag[a.tag]!
                  .getStatsForTypes(selectedTypes)
                  .starsCount["1"] ??
              0;
          return statB.compareTo(statA);
        });
        break;
      case "Two Stars Attacks":
        filteredPlayers.sort((a, b) {
          final statB = playersByTag[b.tag]!
                  .getStatsForTypes(selectedTypes)
                  .starsCount["2"] ??
              0;
          final statA = playersByTag[a.tag]!
                  .getStatsForTypes(selectedTypes)
                  .starsCount["2"] ??
              0;
          return statB.compareTo(statA);
        });
        break;
      case "Three Stars Attacks":
        filteredPlayers.sort((a, b) {
          final statB = playersByTag[b.tag]!
                  .getStatsForTypes(selectedTypes)
                  .starsCount["3"] ??
              0;
          final statA = playersByTag[a.tag]!
                  .getStatsForTypes(selectedTypes)
                  .starsCount["3"] ??
              0;
          return statB.compareTo(statA);
        });
        break;
      case "War Participation":
        filteredPlayers.sort((a, b) {
          final statB =
              playersByTag[b.tag]!.getStatsForTypes(selectedTypes).warsCounts;
          final statA =
              playersByTag[a.tag]!.getStatsForTypes(selectedTypes).warsCounts;
          return statB.compareTo(statA);
        });
        break;
      case "Missed Attacks":
        filteredPlayers.sort((a, b) {
          final statB = playersByTag[b.tag]!
              .getStatsForTypes(selectedTypes)
              .missedAttacks;
          final statA = playersByTag[a.tag]!
              .getStatsForTypes(selectedTypes)
              .missedAttacks;
          return statB.compareTo(statA);
        });
        break;
      default:
        break;
    }
  }

  void showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.generalFilters,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                        AppLocalizations.of(context)!
                            .warOpponentSelectMembersThLevel,
                        style: Theme.of(context).textTheme.bodyMedium),
                    Wrap(
                      spacing: 4.0,
                      children: memberThSelection.keys.map((thLevel) {
                        return FilterChip(
                          showCheckmark: false,
                          selectedColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withAlpha(150),
                          labelPadding: EdgeInsets.all(0),
                          label: MobileWebImage(
                              imageUrl: ImageAssets.townHall(thLevel),
                              height: 24),
                          selected: memberThSelection[thLevel]!,
                          onSelected: (bool selected) {
                            setState(() {
                              memberThSelection[thLevel] = selected;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 10),
                    Text(
                        AppLocalizations.of(context)!
                            .warOpponentSelectOpponentsThLevel,
                        style: Theme.of(context).textTheme.bodyMedium),
                    Wrap(
                      spacing: 4.0,
                      children: enemyThSelection.keys.map((thLevel) {
                        return FilterChip(
                          showCheckmark: false,
                          selectedColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withAlpha(150),
                          labelPadding: EdgeInsets.all(0),
                          label: MobileWebImage(
                              imageUrl: ImageAssets.townHall(thLevel),
                              height: 24),
                          selected: enemyThSelection[thLevel]!,
                          onSelected: (bool selected) {
                            setState(() {
                              enemyThSelection[thLevel] = selected;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 10),
                    CheckboxListTile(
                      title: Text(
                          AppLocalizations.of(context)!.warOpponentEqualThLevel,
                          style: Theme.of(context).textTheme.bodyMedium),
                      value: equalThSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          equalThSelected = value ?? false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(AppLocalizations.of(context)!.generalCancel),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text(AppLocalizations.of(context)!.generalApply),
                  onPressed: () {
                    final newAttackerThFilter = memberThSelection.entries
                        .where((entry) => entry.value)
                        .map((entry) => entry.key)
                        .toList();
                    final newDefenderThFilter = enemyThSelection.entries
                        .where((entry) => entry.value)
                        .map((entry) => entry.key)
                        .toList();

                    updateThFilters(
                      newAttackerThFilter,
                      newDefenderThFilter,
                    );

                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAdvancedFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => ClanWarStatsFilterDialog(
        initialFilter: _currentFilter,
        onApply: _applyAdvancedFilter,
      ),
    );
  }

  void _applyAdvancedFilter(ClanWarStatsFilter filter) async {
    setState(() {
      _currentFilter = filter;
      _isLoadingFiltered = true;
      _hasAppliedFilters = true;
    });

    try {
      final clanService = Provider.of<ClanService>(context, listen: false);
      final filteredStats = await clanService.loadClanWarStatsWithFilter(
        widget.clan.tag,
        filter,
      );

      setState(() {
        _filteredClanWarStats = filteredStats;
        _isLoadingFiltered = false;
        if (filteredStats != null) {
          filteredPlayers = filteredStats.players;
        }
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

  void _clearAdvancedFilters() {
    setState(() {
      _currentFilter = ClanWarStatsFilter.defaultFilter();
      _filteredClanWarStats = null;
      _hasAppliedFilters = false;
      filteredPlayers = widget.clan.clanWarStats?.players ?? [];
    });
  }

  void toggleTownHallVisibility() {
    setState(() {
      showUppedTownHall = !showUppedTownHall;
    });
  }

  void updateThFilters(List<int> attackerThFilter, List<int> defenderThFilter) {
    setState(() {
      this.attackerThFilter = attackerThFilter;
      this.defenderThFilter = defenderThFilter;
    });
  }

  String _getFilterSummary() {
    if (!_currentFilter.hasActiveFilters()) {
      return AppLocalizations.of(context)!.filtersNoneApplied;
    }
    return _currentFilter.getFilterSummary();
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            PlayerWarStatsHeader(
              name: widget.clan.name,
              tag: widget.clan.clanWarStats?.clanTag ?? '',
              picture: widget.clan.badgeUrls.small,
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
              onFilter: () => _showAdvancedFilterDialog(),
              hasActiveFilters: _currentFilter.hasActiveFilters(),
              onExport: () {
                // TODO: Implement clan war stats export
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(AppLocalizations.of(context)!
                          .exportClanWarStatsComingSoon)),
                );
              },
            ),
            _isLoadingFiltered
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Column(
                    children: [
                      if (_hasAppliedFilters)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12.0),
                          margin: const EdgeInsets.symmetric(horizontal: 16.0),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.filter_alt,
                                size: 16,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _getFilterSummary(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                      ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                                onPressed: _clearAdvancedFilters,
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
                        tabs: [
                          Tab(
                              text: AppLocalizations.of(context)?.warLog ??
                                  'War Log'),
                          Tab(
                              text: AppLocalizations.of(context)
                                      ?.navigationStatistics ??
                                  'Statistics'),
                        ],
                        children: [
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Column(
                              children: [
                                ClanWarLog(
                                  clan: widget.clan,
                                  selectedTypes: _getSelectedTypes(),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Column(
                              children: [
                                ClanWarStatsPlayers(
                                  clan: widget.clan,
                                  showUppedTownHall: showUppedTownHall,
                                  sortBy: _sortBy,
                                  selectedTypes: _getSelectedTypes(),
                                  filteredPlayers: filteredPlayers,
                                  allPlayers: _displayedClanWarStats?.players
                                          .map((player) => player.tag)
                                          .toList() ??
                                      [],
                                  toggleTownHallVisibility:
                                      toggleTownHallVisibility,
                                  updateSortBy: _updateSortBy,
                                  resetFilters: _resetFilters,
                                  attackerThFilter: attackerThFilter,
                                  defenderThFilter: defenderThFilter,
                                  equalThSelected: equalThSelected,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
