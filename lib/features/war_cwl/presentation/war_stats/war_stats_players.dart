// Fichier : war_stats_page.dart
import 'package:clashkingapp/common/widgets/inputs/filter_dropdown.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/functions/war_functions.dart';
import 'package:clashkingapp/features/player/models/player_war_stats.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/presentation/player/player_page.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ClanWarStatsPlayers extends StatelessWidget {
  final Clan clan;
  final bool showUppedTownHall;
  final String sortBy;
  final List<int> attackerThFilter;
  final List<int> defenderThFilter;
  final List<String> selectedTypes;
  final List<PlayerWarStats> filteredPlayers;
  final List<String> allPlayers;
  final VoidCallback toggleTownHallVisibility;
  final Function(String) updateSortBy;
  final Function() resetFilters;
  final bool equalThSelected;

  const ClanWarStatsPlayers(
      {super.key,
      required this.clan,
      required this.showUppedTownHall,
      required this.sortBy,
      required this.selectedTypes,
      required this.filteredPlayers,
      required this.toggleTownHallVisibility,
      required this.updateSortBy,
      required this.resetFilters,
      required this.attackerThFilter,
      required this.defenderThFilter,
      required this.equalThSelected,
      required this.allPlayers});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(
                showUppedTownHall ? LucideIcons.eyeOff : LucideIcons.eye,
                size: 20,
              ),
              tooltip:
                  AppLocalizations.of(context)!.warVisibilityToggleTownHall,
              onPressed: toggleTownHallVisibility,
            ),
            FilterDropdown(
              sortBy: sortBy,
              updateSortBy: updateSortBy,
              sortByOptions: {
                AppLocalizations.of(context)!.warStarsThree:
                    "Three Stars Attacks",
                AppLocalizations.of(context)!.warStarsTwo: "Two Stars Attacks",
                AppLocalizations.of(context)!.warStarsOne: "One Star Attacks",
                AppLocalizations.of(context)!.warStarsZero: "No Star Attacks",
                AppLocalizations.of(context)!.warDestructionAverage:
                    "Average Destruction",
                AppLocalizations.of(context)!.warStarsAverage: "Average Stars",
                AppLocalizations.of(context)!.warParticipation:
                    "War Participation",
                AppLocalizations.of(context)!.warAttacksMissed:
                    "Missed Attacks",
              },
            ),
            IconButton(
              icon: Icon(LucideIcons.listRestart),
              onPressed: () {
                resetFilters();
              },
              tooltip: AppLocalizations.of(context)!.generalReset,
            ),
          ],
        ),
        if (filteredPlayers.isNotEmpty)
          ...filteredPlayers.map(
            (member) {
              final memberWarStats = member.getStatsForTypes(
                selectedTypes,
                attackerThFilter: attackerThFilter,
                defenderThFilter: defenderThFilter,
                equalThSelected: equalThSelected,
              );

              final starsCount = showUppedTownHall
                  ? memberWarStats.starsCount
                  : (memberWarStats
                      .getStarsCountAgainstTh(member.townhallLevel));

              final totalAttacks = starsCount.values.fold<int>(
                0,
                (previousValue, element) => previousValue + element,
              );

              if (totalAttacks == 0) {
                return SizedBox.shrink();
              }

              return GestureDetector(
                onTap: () async {
                  final navigator = Navigator.of(context);
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                  );
                  try {
                    final player =
                        await PlayerService().getPlayerAndClanData(member.tag);
                    navigator.pop();
                    navigator.push(
                      MaterialPageRoute(
                        builder: (_) => PlayerScreen(selectedPlayer: player),
                      ),
                    );
                  } catch (e) {
                    if (context.mounted) {
                      navigator.pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to load player data')),
                      );
                    }
                  }
                },
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
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                    Text(totalAttacks.toString()),
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
                                  "${((starsCount["0"] ?? 0) / totalAttacks * 100).toStringAsFixed(2)}%",
                                ),
                                Text("${starsCount["0"]}/$totalAttacks"),
                              ],
                            ),
                            Column(
                              children: [
                                Row(
                                  children: [...generateStars(1, 16)],
                                ),
                                Text(
                                  "${((starsCount["1"] ?? 0) / totalAttacks * 100).toStringAsFixed(2)}%",
                                ),
                                Text("${starsCount["1"]}/$totalAttacks"),
                              ],
                            ),
                            Column(
                              children: [
                                Row(
                                  children: [...generateStars(2, 16)],
                                ),
                                Text(
                                  "${((starsCount["2"] ?? 0) / totalAttacks * 100).toStringAsFixed(2)}%",
                                ),
                                Text("${starsCount["2"]}/$totalAttacks"),
                              ],
                            ),
                            Column(
                              children: [
                                Row(
                                  children: [...generateStars(3, 16)],
                                ),
                                Text(
                                  "${((starsCount["3"] ?? 0) / totalAttacks * 100).toStringAsFixed(2)}%",
                                ),
                                Text("${starsCount["3"]}/$totalAttacks"),
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
    );
  }
}
