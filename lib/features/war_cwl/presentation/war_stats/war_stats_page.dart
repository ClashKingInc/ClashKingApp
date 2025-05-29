import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/player/models/player_war_stats.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war_stats/clan_war_log.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war_stats/war_stats_players.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/features/player/presentation/war_stats/player_war_stats_header.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';

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

      filteredPlayers = widget.clan.clanWarStats?.players ?? [];
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

    filteredPlayers = widget.clan.clanWarStats?.players
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
              title: Text(AppLocalizations.of(context)!.filters,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(AppLocalizations.of(context)!.selectMembersThLevel,
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
                    Text(AppLocalizations.of(context)!.selectOpponentsThLevel,
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
                      title: Text(AppLocalizations.of(context)!.equalThLevel,
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
                  child: Text(AppLocalizations.of(context)!.cancel),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text(AppLocalizations.of(context)!.apply),
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

  void toggleTownHallVisibility() {
    setState(() {
      showUppedTownHall = !showUppedTownHall;
    });
  }

  void updateThFilters(attackerThFilter, defenderThFilter) {
    setState(() {
      this.attackerThFilter = attackerThFilter;
      this.defenderThFilter = defenderThFilter;
    });
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
              onFilter: () => showFilterDialog(),
            ),
            ScrollableTab(
              tabBarDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              ),
              labelColor: Theme.of(context).colorScheme.onSurface,
              labelPadding: EdgeInsets.zero,
              labelStyle: Theme.of(context).textTheme.bodyLarge,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
              tabs: [
                Tab(text: AppLocalizations.of(context)?.warLog ?? 'War Log'),
                Tab(
                    text: AppLocalizations.of(context)?.statistics ??
                        'Statistics'),
              ],
              children: [
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Column(
                    children: [
                      ClanWarLog(clan: widget.clan, selectedTypes: _getSelectedTypes(),),
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
                        allPlayers: widget.clan.clanWarStats?.players
                                .map((player) => player.tag)
                                .toList() ??
                            [],
                        toggleTownHallVisibility: toggleTownHallVisibility,
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
      ),
    );
  }
}
