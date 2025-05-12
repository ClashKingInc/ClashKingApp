import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/models/player_war_stats.dart';
import 'package:clashkingapp/features/player/presentation/war_stats/player_war_attacks_tab.dart';
import 'package:clashkingapp/features/player/presentation/war_stats/player_war_stats_tab.dart';
import 'package:clashkingapp/features/player/presentation/war_stats/war_stats_header.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';

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

  List<String> _getSelectedTypes() {
  final List<String> selected = [];
  if (isCWLChecked) selected.add("cwl");
  if (isRandomChecked) selected.add("random");
  if (isFriendlyChecked) selected.add("friendly");
  return selected;
}


  List<PlayerWarStatsData> get _filteredWars {
    final wars = widget.player.warStats?.wars ?? [];

    return wars.where((war) {
      final type = war.warDetails.type.toLowerCase();
      return (isCWLChecked && type == "cwl") ||
          (isRandomChecked && type == "random") ||
          (isFriendlyChecked && type == "friendly");
    }).toList();
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
            ),
            widget.player.warStats != null
                ? ScrollableTab(
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
                      Tab(text: AppLocalizations.of(context)!.stats),
                      Tab(text: AppLocalizations.of(context)!.details),
                    ],
                    children: [
                      WarStatsView(
                        warStats: widget.player.warStats,
                        filterTypes: _getSelectedTypes(),
                        currentSeasonDate: DateTime.now(),
                        warDataLimit: 0,
                      ),
                      PlayerWarAttacksTab(
                        wars: _filteredWars,
                      ),
                    ],
                  )
                : Center(
                    child: Text(AppLocalizations.of(context)?.noDataAvailable ??
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
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.filters ?? 'Filters'),
        content:
            Text(AppLocalizations.of(context)?.comingSoon ?? 'Coming soon...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)?.ok ?? 'OK'),
          )
        ],
      ),
    );
  }
}
