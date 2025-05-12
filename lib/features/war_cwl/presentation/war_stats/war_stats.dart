import 'package:clashkingapp/common/widgets/inputs/filter_dropdown.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/functions/war_functions.dart';
import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/player/models/player_war_stats.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/features/player/presentation/war_stats/war_stats_header.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';

// Repair missedAttacks, instead of byEnnemyTH, add 15v17 etc
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
            return SingleChildScrollView(
              child: AlertDialog(
                title: Text(AppLocalizations.of(context)!.filters,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(AppLocalizations.of(context)!.selectMembersThLevel,
                        style: Theme.of(context).textTheme.bodyMedium),
                    Wrap(
                      spacing: 0.0,
                      children: memberThSelection.keys.map((thLevel) {
                        return FilterChip(
                          showCheckmark: false,
                          selectedColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.7),
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
                      spacing: 5.0,
                      children: enemyThSelection.keys.map((thLevel) {
                        return FilterChip(
                          showCheckmark: false,
                          selectedColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.7),
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
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    showUppedTownHall ? LucideIcons.eyeOff : LucideIcons.eye,
                    size: 20,
                  ),
                  tooltip:
                      AppLocalizations.of(context)!.toggleTownHallVisibility,
                  onPressed: toggleTownHallVisibility,
                ),
                FilterDropdown(
                  sortBy: _sortBy,
                  updateSortBy: _updateSortBy,
                  sortByOptions: {
                    AppLocalizations.of(context)!.threeStars:
                        "Three Stars Attacks",
                    AppLocalizations.of(context)!.twoStars: "Two Stars Attacks",
                    AppLocalizations.of(context)!.oneStar: "One Star Attacks",
                    AppLocalizations.of(context)!.zeroStar: "No Star Attacks",
                    AppLocalizations.of(context)!.averageDestruction:
                        "Average Destruction",
                    AppLocalizations.of(context)!.averageStars: "Average Stars",
                    AppLocalizations.of(context)!.warParticipation:
                        "War Participation",
                    AppLocalizations.of(context)!.missedAttacks:
                        "Missed Attacks",
                  },
                ),
                IconButton(
                  icon: Icon(LucideIcons.listRestart),
                  onPressed: () {
                    _resetFilters();
                  },
                  tooltip: AppLocalizations.of(context)!.reset,
                ),
              ],
            ),
            if (filteredPlayers.isNotEmpty)
              ...filteredPlayers.map(
                (member) {
                  final memberWarStats =
                      member.getStatsForTypes(_getSelectedTypes());

                  final starsCount = showUppedTownHall
                  ? memberWarStats.starsCount
                  : memberWarStats.getStarsCountAgainstTh(member.townhallLevel);

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    MobileWebImage(
                                      imageUrl: ImageAssets.townHall(
                                          member.townhallLevel),
                                      height: 50,
                                    ),
                                    SizedBox(width: 16),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(member.name),
                                        Text(member.tag),
                                      ],
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Row(
                                      children: [
                                        Text(memberWarStats.totalAttacks
                                            .toString()),
                                        SizedBox(width: 8),
                                        MobileWebImage(
                                            imageUrl: ImageAssets.warClan,
                                            height: 16,
                                            width: 16),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(memberWarStats.missedAttacks
                                            .toString()),
                                        SizedBox(width: 8),
                                        MobileWebImage(
                                            imageUrl: ImageAssets.brokenSword,
                                            height: 16,
                                            width: 16),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.percent, size: 16),
                                        Icon(Icons.star, size: 16),
                                      ],
                                    ),
                                    Text(memberWarStats.averageDestruction
                                        .toStringAsFixed(2)),
                                    Text(memberWarStats.averageStars
                                        .toStringAsFixed(2)),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Row(
                                      children: [...generateStars(0, 16)],
                                    ),
                                    Text(
                                      "${((starsCount["0"] ?? 0) / memberWarStats.totalAttacks * 100).toStringAsFixed(2)}%",
                                    ),
                                    Text(
                                        "${starsCount["0"]}/${memberWarStats.totalAttacks}"),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Row(
                                      children: [...generateStars(1, 16)],
                                    ),
                                    Text(
                                      "${((starsCount["1"] ?? 0) / memberWarStats.totalAttacks * 100).toStringAsFixed(2)}%",
                                    ),
                                    Text(
                                        "${starsCount["1"]}/${memberWarStats.totalAttacks}"),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Row(
                                      children: [...generateStars(2, 16)],
                                    ),
                                    Text(
                                      "${((starsCount["2"] ?? 0) / memberWarStats.totalAttacks * 100).toStringAsFixed(2)}%",
                                    ),
                                    Text(
                                        "${starsCount["2"]}/${memberWarStats.totalAttacks}"),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Row(
                                      children: [...generateStars(3, 16)],
                                    ),
                                    Text(
                                      "${((starsCount["3"] ?? 0) / memberWarStats.totalAttacks * 100).toStringAsFixed(2)}%",
                                    ),
                                    Text(
                                        "${starsCount["3"]}/${memberWarStats.totalAttacks}"),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  
}
