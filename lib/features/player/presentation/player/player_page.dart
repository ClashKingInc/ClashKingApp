import 'package:clashkingapp/features/player/presentation/player/player_super_troop_section.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';
import 'package:clashkingapp/features/player/presentation/player/player_header.dart';
import 'package:clashkingapp/features/player/presentation/player/player_item_section.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';

class PlayerScreen extends StatefulWidget {
  final Player selectedPlayer;

  const PlayerScreen({super.key, required this.selectedPlayer});

  @override
  PlayerScreenState createState() => PlayerScreenState();
}

class PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  int selectedTab = 0;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("Selected player: ${widget.selectedPlayer.tag}");
    return Scaffold(
      body: SingleChildScrollView(
        child: SingleChildScrollView(
          child: Column(
            children: [
              PlayerInfoHeader(selectedTab: selectedTab, player: widget.selectedPlayer),
              ScrollableTab(
                labelColor: Theme.of(context).colorScheme.onSurface,
                unselectedLabelColor:
                    Theme.of(context).colorScheme.onSurface.withValues(alpha : 0.6),
                tabBarDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                ),
                onTap: (index) {
                  setState(() {
                    selectedTab = index;
                  });
                },
                tabs: [
                  Tab(
                      text: AppLocalizations.of(context)?.homeBase ??
                          'Home Base'),
                  Tab(
                      text: AppLocalizations.of(context)?.builderBase ??
                          'Builder Base'),
                ],
                children: [
                  _buildPlayerContent(widget.selectedPlayer),
                  _buildBuilderContent(widget.selectedPlayer),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerContent(Player player) {
    return Column(
      children: [
        SizedBox(height: 10),
        PlayerSuperTroopSection(superTroops: player.superTroops),
        PlayerItemSection(
            title: AppLocalizations.of(context)!.heroes, items: player.heroes),
        PlayerItemSection(
            title: AppLocalizations.of(context)!.equipment,
            items: player.equipments),
        PlayerItemSection(
            title: AppLocalizations.of(context)!.troops, items: player.troops),
        PlayerItemSection(
            title: AppLocalizations.of(context)!.spells, items: player.spells),
        PlayerItemSection(
            title: AppLocalizations.of(context)!.siegeMachines,
            items: player.siegeMachines),
        PlayerItemSection(
            title: AppLocalizations.of(context)!.pets, items: player.pets),
        SizedBox(height: 10),
      ],
    );
  }

  Widget _buildBuilderContent(Player player) {
    return Column(
      children: [
        SizedBox(height: 10),
        PlayerItemSection(
            title: AppLocalizations.of(context)!.heroes,
            items: player.bbHeroes),
        PlayerItemSection(
            title: AppLocalizations.of(context)!.troops,
            items: player.bbTroops),
        SizedBox(height: 10),
      ],
    );
  }
}
