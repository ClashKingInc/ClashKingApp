import 'dart:ui';
import 'package:clashkingapp/api/to_do.dart';
import 'package:clashkingapp/components/filter_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clashkingapp/api/player_account_info.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/main_pages/dashboard_page/player_dashboard/components/player_info_header_card.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_info_clan/clan_info_page.dart';
import 'package:clashkingapp/api/clan_info.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/player_legend_page.dart';
import 'package:clashkingapp/api/player_legend.dart';

class ToDoScreen extends StatefulWidget {
  final PlayerAccountInfo playerStats;
  final List<String> tags;
  final bool isInTimeFrame;
  final PlayerToDoData data;

  ToDoScreen({super.key, required this.playerStats, required this.tags, required this.isInTimeFrame, required this.data});

  @override
  ToDoScreenState createState() => ToDoScreenState();
}

class ToDoScreenState extends State<ToDoScreen>
    with SingleTickerProviderStateMixin {
  String currentFilter = 'all';
  String backgroundImageUrl = 'https://clashkingfiles.b-cdn.net/landscape/Villager_HV_Builder_19.png';

  @override
  void initState() {
    super.initState();
  }

  void updateFilter(String newFilter) {
    setState(() {
      currentFilter = newFilter;
    });
  }

  Widget filterContent() {
    switch (currentFilter) {
      case 'all':
        return _contentForAll();
      case 'byEvent':
        return _contentForByEvent();
      default:
        return _contentForTag(currentFilter);
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, String> filterOptions = {
      AppLocalizations.of(context)!.all: 'all',
      'byEvent': 'byEvent',
    };

    for (String tag in widget.tags) {
      filterOptions[tag] = tag;
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: <Widget>[
                Container(
                  height: 220,
                  width: double.infinity,
                  color: Colors.black.withOpacity(0.3),
                ),
                SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0),
                        BlendMode.darken,
                      ),
                      child: CachedNetworkImage(
                        imageUrl: backgroundImageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 130,
                  child: Text(
                    AppLocalizations.of(context)?.toDoList ?? 'To Do List',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
                  ),
                ),
                Positioned(
                  top: 30,
                  left: 10,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 32),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            FilterDropdown(
              sortBy: currentFilter,
              updateSortBy: updateFilter,
              sortByOptions: filterOptions,
            ),
            filterContent(),
          ],
        ),
      ),
    );     
  }

  Widget _contentForAll() {
    List<Widget> cards = [];

    for (var tag in widget.tags) {
      for (var playerData in widget.data.items.where((item) => item.playerTag == tag)) {
        cards.add(
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(playerData.playerTag),
                        Text('Last Active: ${DateFormat('dd/MM/yy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(playerData.lastActive * 1000))}'),
                        if (widget.isInTimeFrame)
                          if (playerData.raids.attackLimit == 0)
                            Text('Raids: 0/5')
                          else  
                            Text('Raids: ${playerData.raids.attacksDone}/${playerData.raids.attackLimit}'),
                        if (playerData.cwl.attackLimit != 0)
                          Text('CWL: ${playerData.cwl.attacksDone}/${playerData.cwl.attackLimit}'),
                      ],
                    ),
                    SizedBox(width: 8),
                  ],
                ),
              ),
            ),
        );
      }
    }

    return Column(
      children: cards,
    );
  }

  Widget _contentForByEvent() {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 8, right: 8, bottom: 16), 
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text('Afficher par événement')
          ),
        ),
      ),
    );
  }

  Widget _contentForTag(String tag) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 8, right: 8, bottom: 16), 
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Center(
              child: Text('Afficher pour le tag: $tag'),
            ),
          ),
        ),
      ),  
    );
  }
}
